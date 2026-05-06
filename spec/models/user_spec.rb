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
end
