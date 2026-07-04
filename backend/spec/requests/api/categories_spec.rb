require 'rails_helper'

RSpec.describe "Api::Categories", type: :request do
  describe "GET /api/categories" do
    let!(:food) { Category.create!(name: "Food") }
    let!(:transport) { Category.create!(name: "Transport") }
    let!(:supplies) { Category.create!(name: "Supplies") }

    it "returns all categories" do
      get "/api/categories"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
      expect(json.map { |c| c["name"] }).to include("Food", "Transport", "Supplies")
    end

    it "returns categories in alphabetical order" do
      get "/api/categories"

      json = JSON.parse(response.body)
      expect(json.map { |c| c["name"] }).to eq([ "Food", "Supplies", "Transport" ])
    end
  end

  describe "POST /api/categories" do
    context "with valid parameters" do
      it "creates a new category" do
        expect {
          post "/api/categories", params: { category: { name: "Entertainment" } }, as: :json
        }.to change(Category, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Entertainment")
      end
    end

    context "with invalid parameters" do
      it "rejects a blank name" do
        expect {
          post "/api/categories", params: { category: { name: "" } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects a duplicate name" do
        Category.create!(name: "Food")

        expect {
          post "/api/categories", params: { category: { name: "Food" } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT /api/categories/:id" do
    let!(:food) { Category.create!(name: "Food") }

    it "updates the category with valid parameters" do
      put "/api/categories/#{food.id}", params: { category: { name: "Groceries" } }, as: :json

      expect(response).to have_http_status(:success)
      expect(food.reload.name).to eq("Groceries")
    end

    it "rejects invalid parameters and does not change the record" do
      put "/api/categories/#{food.id}", params: { category: { name: "" } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(food.reload.name).to eq("Food")
    end

    it "returns 404 for a non-existent category" do
      put "/api/categories/999999", params: { category: { name: "Whatever" } }, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/categories/:id" do
    it "deletes a category with no expenses" do
      category = Category.create!(name: "Entertainment")

      expect {
        delete "/api/categories/#{category.id}"
      }.to change(Category, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "deletes the category and nullifies its expenses instead of destroying them" do
      category = Category.create!(name: "Food")
      expense = Expense.create!(description: "Lunch", amount: 10.00, category: category, date: Date.current)

      expect {
        delete "/api/categories/#{category.id}"
      }.not_to change(Expense, :count)

      expect(response).to have_http_status(:no_content)
      expect(expense.reload.category_id).to be_nil
    end

    it "returns 404 for a non-existent category" do
      delete "/api/categories/999999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
