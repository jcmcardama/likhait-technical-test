require 'rails_helper'

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  describe "GET /api/expenses" do
    let!(:expense1) { Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: Date.current) }
    let!(:expense2) { Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: Date.current) }

    it "returns all expenses with category information" do
      get "/api/expenses"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it "returns null category for expenses with no category" do
      Expense.create!(description: "Misc", amount: 20.00, category: nil, date: Date.current)

      get "/api/expenses"

      json = JSON.parse(response.body)
      misc = json.find { |e| e["description"] == "Misc" }
      expect(misc["category"]).to be_nil
    end

    it "orders by expense date descending, tie-broken by created_at descending" do
      older_but_later_date = Expense.create!(
        description: "Groceries", amount: 75.00, category: food_category,
        date: Date.current - 1, created_at: 1.hour.ago
      )
      newer_but_earlier_date = Expense.create!(
        description: "Coffee", amount: 5.00, category: food_category,
        date: Date.current - 2, created_at: Time.current
      )

      get "/api/expenses"
      json = JSON.parse(response.body)
      ids_in_order = json.map { |e| e["id"] }

      expect(ids_in_order.index(older_but_later_date.id))
        .to be < ids_in_order.index(newer_but_earlier_date.id)
    end

    describe "with year/month filter" do
      it "filters by expense date, not created_at" do
        backdated = Expense.create!(
          description: "Backdated", amount: 30.00, category: food_category,
          date: 1.month.ago.to_date, created_at: Time.current
        )

        get "/api/expenses", params: { year: Date.current.year, month: Date.current.month }
        json = JSON.parse(response.body)

        expect(json.map { |e| e["id"] }).not_to include(backdated.id)
      end

      it "returns 422 for an invalid month" do
        get "/api/expenses", params: { year: Date.current.year, month: 13 }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for a non-numeric year" do
        get "/api/expenses", params: { year: "abc", month: 1 }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /api/expenses" do
    context "with valid parameters" do
      it "creates a new expense" do
        valid_params = {
          expense: {
            description: "Team Lunch", amount: 150.50,
            category_id: food_category.id, date: Date.current
          }
        }

        expect {
          post "/api/expenses", params: valid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["description"]).to eq("Team Lunch")
        expect(json["amount"]).to eq(150.5)
      end

      it "creates an expense without a category" do
        valid_params = {
          expense: { description: "Misc", amount: 20.00, date: Date.current }
        }

        expect {
          post "/api/expenses", params: valid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["category"]).to be_nil
      end
    end

    context "with invalid parameters" do
      it "rejects negative amounts" do
        invalid_params = {
          expense: { description: "Invalid", amount: -100.00, category_id: food_category.id, date: Date.current }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.not_to change(Expense, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects empty descriptions" do
        invalid_params = {
          expense: { description: "", amount: 100.00, category_id: food_category.id, date: Date.current }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.not_to change(Expense, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects a future date" do
        invalid_params = {
          expense: { description: "Future", amount: 50.00, category_id: food_category.id, date: Date.tomorrow }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.not_to change(Expense, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Date cannot be in the future")
      end
    end
  end

  describe "PUT /api/expenses/:id" do
    let!(:expense) { Expense.create!(description: "Lunch", amount: 10.00, category: food_category, date: Date.current) }

    it "updates the expense's category" do
      put "/api/expenses/#{expense.id}", params: { expense: { category_id: transport_category.id } }, as: :json

      expect(response).to have_http_status(:success)
      expect(expense.reload.category_id).to eq(transport_category.id)
    end

    it "clears the expense's category when category_id is set to null" do
      put "/api/expenses/#{expense.id}", params: { expense: { category_id: nil } }, as: :json

      expect(response).to have_http_status(:success)
      expect(expense.reload.category_id).to be_nil
    end

    it "rejects updating to a future date" do
      put "/api/expenses/#{expense.id}", params: { expense: { date: Date.tomorrow } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(expense.reload.date).to eq(Date.current)
    end

    it "returns 404 for a non-existent expense" do
      put "/api/expenses/999999", params: { expense: { description: "Whatever" } }, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/expenses/:id" do
    it "deletes an expense" do
      expense = Expense.create!(description: "Lunch", amount: 10.00, category: food_category, date: Date.current)

      expect {
        delete "/api/expenses/#{expense.id}"
      }.to change(Expense, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for a non-existent expense" do
      delete "/api/expenses/999999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
