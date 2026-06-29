# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  around do |example|
    original = Rack::Attack.enabled
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
    example.run
  ensure
    Rack::Attack.enabled = original
    Rack::Attack.cache.store.clear
  end

  it "throttles repeated login attempts from the same IP" do
    11.times do
      post login_path, params: { email: "nobody@example.com", password: "wrong" }
      break if response.status == 429
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(response.body).to include("Too many requests")
  end

  it "throttles repeated unauthenticated API requests from the same IP" do
    121.times do
      get api_job_posts_path
      break if response.status == 429
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(JSON.parse(response.body)).to eq("error" => "Too many requests")
  end
end
