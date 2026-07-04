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

  it "is invalid with a duplicate name" do
    Category.create!(name: "Food")
    duplicate = Category.new(name: "Food")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to include("has already been taken")
  end

  it "is invalid with a duplicate name in different casing" do
    Category.create!(name: "Food")
    duplicate = Category.new(name: "FOOD")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to include("has already been taken")
  end

  it "nullifies associated expenses instead of destroying them when deleted" do
    category = Category.create!(name: "Food")
    expense = Expense.create!(description: "Lunch", amount: 10.00, category: category, date: Date.current)

    category.destroy

    expect { expense.reload }.not_to raise_error
    expect(expense.category_id).to be_nil
  end
end
