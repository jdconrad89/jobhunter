# frozen_string_literal: true

require "rails_helper"

RSpec.describe Llm::Client do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("OPENAI_MODEL", "gpt-4o-mini").and_return("gpt-4o-mini")
    allow(ENV).to receive(:fetch).with("OPENAI_MAX_TOKENS", "1200").and_return("1200")
  end

  it "retries on HTTP 429 and eventually succeeds" do
    client = described_class.new
    openai = instance_double(OpenAI::Client)
    allow(OpenAI::Client).to receive(:new).and_return(openai)

    error = Faraday::TooManyRequestsError.new("rate limited")
    allow(error).to receive(:response).and_return(
      { headers: { "retry-after" => "0" }, body: { "error" => { "message" => "Rate limit" } } }
    )

    call_count = 0
    allow(openai).to receive(:chat) do
      call_count += 1
      raise error if call_count == 1

      { "choices" => [ { "message" => { "content" => '{"ok":true}' } } ] }
    end
    allow(client).to receive(:sleep)

    expect(client.chat(system: "sys", user: "user")).to eq('{"ok":true}')
    expect(call_count).to eq(2)
  end

  it "raises RateLimitError after exhausting retries" do
    client = described_class.new
    openai = instance_double(OpenAI::Client)
    allow(OpenAI::Client).to receive(:new).and_return(openai)

    error = Faraday::TooManyRequestsError.new("rate limited")
    allow(error).to receive(:response).and_return({ headers: {}, body: {} })
    allow(openai).to receive(:chat).and_raise(error)
    allow(client).to receive(:sleep)

    expect {
      client.chat(system: "sys", user: "user")
    }.to raise_error(Llm::Client::RateLimitError, /rate limit/i)
  end
end
