require 'rails_helper'

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

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  describe "GET /api/expenses" do
    let!(:expense1) { Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: Date.today) }
    let!(:expense2) { Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: Date.today) }

    it "returns all expenses with category information" do
      get "/api/expenses"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it "orders by expense date descending, tie-broken by created_at descending" do
      older_but_later_date = Expense.create!(
        description: "Groceries", amount: 75.00, category: food_category,
        date: Date.today - 1, created_at: 1.hour.ago
      )
      newer_but_earlier_date = Expense.create!(
        description: "Coffee", amount: 5.00, category: food_category,
        date: Date.today - 2, created_at: Time.current
      )

      get "/api/expenses"
      json = JSON.parse(response.body)
      ids_in_order = json.map { |e| e["id"] }

      expect(ids_in_order.index(older_but_later_date.id))
        .to be < ids_in_order.index(newer_but_earlier_date.id)
    end

    it "breaks ties on the same date by most recently created first" do
      same_date = Date.today - 5
      first_created = Expense.create!(
        description: "First", amount: 10.00, category: food_category,
        date: same_date, created_at: 2.hours.ago
      )
      second_created = Expense.create!(
        description: "Second", amount: 20.00, category: food_category,
        date: same_date, created_at: 1.hour.ago
      )

      get "/api/expenses"
      json = JSON.parse(response.body)
      same_date_ids = json.select { |e| e["date"] == same_date.to_s }.map { |e| e["id"] }

      expect(same_date_ids.index(second_created.id))
        .to be < same_date_ids.index(first_created.id)
    end

    describe "with year/month filter" do
      it "filters by expense date, not created_at" do
        backdated = Expense.create!(
          description: "Backdated", amount: 30.00, category: food_category,
          date: 1.month.ago.to_date, created_at: Time.current
        )

        get "/api/expenses", params: { year: Date.today.year, month: Date.today.month }
        json = JSON.parse(response.body)

        expect(json.map { |e| e["id"] }).not_to include(backdated.id)
      end

      it "returns 422 for an invalid month" do
        get "/api/expenses", params: { year: Date.today.year, month: 13 }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end

      it "returns 422 for a non-numeric year" do
        get "/api/expenses", params: { year: "abc", month: 1 }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for year zero" do
        get "/api/expenses", params: { year: "0", month: 1 }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for a negative year" do
        get "/api/expenses", params: { year: "-5", month: 1 }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for a non-integer month" do
        get "/api/expenses", params: { year: Date.today.year, month: "1.5" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /api/expenses" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          expense: {
            description: "Team Lunch",
            amount: 150.50,
            category_id: food_category.id,
            date: Date.today
          }
        }
      end

      it "creates a new expense" do
        expect {
          post "/api/expenses", params: valid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["description"]).to eq("Team Lunch")
        expect(json["amount"]).to eq(150.5)
      end
    end

    context "with invalid parameters" do
      it "rejects negative amounts" do
        invalid_params = {
          expense: {
            description: "Invalid expense",
            amount: -100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.not_to change(Expense, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Amount must be greater than 0")
      end

      it "rejects empty descriptions" do
        invalid_params = {
          expense: {
            description: "",
            amount: 100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.not_to change(Expense, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Description can't be blank")
      end
    end
  end
end
