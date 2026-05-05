require "rails_helper"

RSpec.describe Company, type: :model do
  it "requires a name" do
    company = Company.new
    expect(company).not_to be_valid
    expect(company.errors[:name]).to be_present
  end
end

