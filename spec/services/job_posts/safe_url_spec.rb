# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPosts::SafeUrl do
  describe ".http_url" do
    it "accepts http and https URLs" do
      expect(described_class.http_url("https://example.com/jobs/1")).to eq("https://example.com/jobs/1")
      expect(described_class.http_url("http://example.com")).to eq("http://example.com")
    end

    it "rejects javascript and other schemes" do
      expect(described_class.http_url("javascript:alert(1)")).to be_nil
      expect(described_class.http_url("data:text/html,<script>alert(1)</script>")).to be_nil
      expect(described_class.http_url("ftp://example.com")).to be_nil
    end

    it "rejects blank and invalid URLs" do
      expect(described_class.http_url("")).to be_nil
      expect(described_class.http_url("not a url")).to be_nil
    end
  end
end
