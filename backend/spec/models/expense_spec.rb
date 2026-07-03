RSpec.describe Expense, type: :model do
  let(:category) { Category.create!(name: "Food") }

  it "is valid with valid attributes" do
    expense = Expense.new(description: "Lunch", amount: 10.00, category: category, date: Date.today)
    expect(expense).to be_valid
  end

  it "is invalid without a description" do
    expense = Expense.new(description: "", amount: 10.00, category: category, date: Date.today)
    expect(expense).not_to be_valid
    expect(expense.errors[:description]).to include("can't be blank")
  end

  it "is invalid with a zero amount" do
    expense = Expense.new(description: "Lunch", amount: 0, category: category, date: Date.today)
    expect(expense).not_to be_valid
  end

  it "is invalid with a negative amount" do
    expense = Expense.new(description: "Lunch", amount: -5, category: category, date: Date.today)
    expect(expense).not_to be_valid
  end

  it "is invalid without a date" do
    expense = Expense.new(description: "Lunch", amount: 10.00, category: category, date: nil)
    expect(expense).not_to be_valid
  end
end
