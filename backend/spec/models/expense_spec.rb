require 'rails_helper'

RSpec.describe Expense, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:category) { Category.create!(name: "Food") }

  before do
    travel_to Time.zone.local(2026, 7, 4, 12, 0, 0)
  end

  after do
    travel_back
  end

  it "is invalid with a future date" do
    expense = Expense.new(
      description: "Lunch", amount: 10.00, category: category, date: Date.tomorrow
    )
    expect(expense).not_to be_valid
    expect(expense.errors[:date]).to include("cannot be in the future")
  end

  it "is valid with today's date" do
    expense = Expense.new(
      description: "Lunch", amount: 10.00, category: category, date: Date.current
    )
    expect(expense).to be_valid
  end

  it "is valid with a past date" do
    expense = Expense.new(
      description: "Lunch", amount: 10.00, category: category, date: Date.yesterday
    )
    expect(expense).to be_valid
  end
end
