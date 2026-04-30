class Food < ApplicationRecord
  CATEGORY_FOR_MEAL_TYPE = {
    "breakfast" => "breakfast",
    "lunch" => "lunch_dinner",
    "dinner" => "lunch_dinner",
    "snack" => "snack"
  }.freeze

  has_many :daily_food_logs, dependent: :restrict_with_exception

  enum :category, { breakfast: 0, lunch_dinner: 1, snack: 2 }, validate: true

  validates :name, presence: true, uniqueness: { scope: :category }
  validates :calories, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }
  validates :protein_g, presence: true,
                        numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :alphabetical, -> { order(:name) }

  def self.available_for_meal_type(meal_type)
    counts = DailyFoodLog.group(:food_id).count
    where(category: category_for_meal_type(meal_type))
      .to_a
      .sort_by { |food| [ -counts.fetch(food.id, 0), food.name ] }
  end

  def self.category_for_meal_type(meal_type)
    CATEGORY_FOR_MEAL_TYPE.fetch(meal_type.to_s)
  end
end
