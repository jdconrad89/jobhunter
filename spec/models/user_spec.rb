require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with name, email, password, password_confirmation" do
    user = User.new(name: "A", email: "a@example.com", password: "password", password_confirmation: "password")
    expect(user).to be_valid
  end

  it "requires a name" do
    user = User.new(email: "a@example.com", password: "password", password_confirmation: "password")
    expect(user).not_to be_valid
    expect(user.errors[:name]).to be_present
  end

  it "requires a valid email format" do
    user = User.new(name: "A", email: "not-an-email", password: "password", password_confirmation: "password")
    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end

  it "enforces unique email" do
    create_user!(email: "dup@example.com")
    user = User.new(name: "B", email: "dup@example.com", password: "password", password_confirmation: "password")
    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end

  it "generates a unique api token digest" do
    user = create_user!(email: "token@example.com")
    raw_token = user.regenerate_api_token!
    expect(raw_token).to be_present
    expect(user.api_token_digest).to eq(User.digest_api_token(raw_token))
    expect(user.api_token_digest).not_to eq(raw_token)

    other = create_user!(email: "token2@example.com")
    other_raw = other.regenerate_api_token!
    expect(other.api_token_digest).not_to eq(user.api_token_digest)
    expect(User.authenticate_api_token(raw_token)).to eq(user)
    expect(User.authenticate_api_token(other_raw)).to eq(other)
    expect(User.authenticate_api_token("invalid")).to be_nil
  end
end
