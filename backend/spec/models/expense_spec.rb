require 'rails_helper'

RSpec.describe Expense, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:category) { Category.create!(name: "Food") }

  before { travel_to Time.zone.local(2026, 7, 4, 12, 0, 0) }
  after { travel_back }

  it "is valid with valid attributes" do
    expense = Expense.new(description: "Lunch", amount: 10.00, category: category, date: Date.current)
    expect(expense).to be_valid
  end

  it "is valid without a category" do
    expense = Expense.new(description: "Lunch", amount: 10.00, category: nil, date: Date.current)
    expect(expense).to be_valid
  end

  it "is invalid without a description" do
    expense = Expense.new(description: "", amount: 10.00, category: category, date: Date.current)
    expect(expense).not_to be_valid
    expect(expense.errors[:description]).to include("can't be blank")
  end

  it "is invalid with a zero amount" do
    expense = Expense.new(description: "Lunch", amount: 0, category: category, date: Date.current)
    expect(expense).not_to be_valid
  end

  it "is invalid with a negative amount" do
    expense = Expense.new(description: "Lunch", amount: -5, category: category, date: Date.current)
    expect(expense).not_to be_valid
  end

  it "is invalid without a date" do
    expense = Expense.new(description: "Lunch", amount: 10.00, category: category, date: nil)
    expect(expense).not_to be_valid
  end

  it "is invalid with a future date" do
    expense = Expense.new(description: "Lunch", amount: 10.00, category: category, date: Date.tomorrow)
    expect(expense).not_to be_valid
    expect(expense.errors[:date]).to include("cannot be in the future")
  end

  it "is valid with today's date" do
    expense = Expense.new(description: "Lunch", amount: 10.00, category: category, date: Date.current)
    expect(expense).to be_valid
  end

  it "is valid with a past date" do
    expense = Expense.new(description: "Lunch", amount: 10.00, category: category, date: Date.yesterday)
    expect(expense).to be_valid
  end
end
