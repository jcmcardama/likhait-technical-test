require 'rails_helper'

RSpec.describe Category, type: :model do
  it "is valid with valid attributes" do
    category = Category.new(name: "Food")
    expect(category).to be_valid
  end

  it "is invalid without a name" do
    category = Category.new(name: "")
    expect(category).not_to be_valid
    expect(category.errors[:name]).to include("can't be blank")
  end
end
