class DailyFoodLog < ApplicationRecord
  MEAL_LABELS = {
    "breakfast" => "朝",
    "lunch" => "昼",
    "dinner" => "夜",
    "snack" => "間食"
  }.freeze

  belongs_to :food

  enum :meal_type, { breakfast: 0, lunch: 1, dinner: 2, snack: 3 }, validate: true

  before_validation :copy_food_snapshot

  validates :eaten_on, presence: true
  validates :food_name, presence: true
  validates :calories, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }

  validate :food_category_matches_meal_type

  scope :for_date, ->(date) { where(eaten_on: date) }
  scope :within, ->(range) { where(eaten_on: range) }
  scope :chronological, -> { order(:eaten_on, :meal_type, :created_at) }

  def self.total_for(period)
    where(eaten_on: period).sum(:calories)
  end

  def self.meal_label(meal_type)
    MEAL_LABELS.fetch(meal_type.to_s)
  end

  def self.natural_language_for(date, logs)
    grouped_logs = logs.group_by(&:meal_type)

    parts = meal_types.keys.filter_map do |meal_type|
      meal_logs = grouped_logs.fetch(meal_type, [])
      next if meal_logs.empty?

      items = meal_logs.map { |log| "#{log.food_name}(#{log.calories}kcal)" }.join("、")
      "#{meal_label(meal_type)}は#{items}"
    end

    if parts.empty?
      "#{format_date(date)}はまだ何も食べていません。"
    else
      "#{format_date(date)}は、#{parts.join('。')}。合計#{logs.sum(&:calories)}kcalでした。"
    end
  end

  def self.format_date(date)
    "#{date.year}年#{date.month}月#{date.day}日"
  end

  private
    def copy_food_snapshot
      return if food.blank?

      self.food_name = food.name
      self.calories = food.calories
    end

    def food_category_matches_meal_type
      return if food.blank? || meal_type.blank?
      return if food.category == Food.category_for_meal_type(meal_type)

      errors.add(:food, "#{self.class.meal_label(meal_type)}には登録できません")
    end
end
