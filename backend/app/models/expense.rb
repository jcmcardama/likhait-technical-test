class Expense < ApplicationRecord
  belongs_to :category

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
end
