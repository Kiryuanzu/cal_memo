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

      items = meal_logs.map { |log| format_log_item(log) }.join("、")
      "#{meal_label(meal_type)}は#{items}"
    end

    if parts.empty?
      "#{format_date(date)}はまだ何も食べていません。"
    else
      "#{format_date(date)}は、#{parts.join('。')}。合計#{logs.sum(&:calories)}kcalでした。"
    end
  end

  def self.natural_language_for_week(range, logs)
    logs_by_date = logs.group_by(&:eaten_on)
    days_with_logs = logs_by_date.keys.count
    total = logs.sum(&:calories)
    average = days_with_logs.zero? ? 0 : (total.to_f / days_with_logs).round

    header = "#{format_date(range.begin)}〜#{format_date(range.end)}の1週間の食事記録です。"
    daily_lines = range.to_a.map { |date| natural_language_for(date, logs_by_date.fetch(date, [])) }
    footer = "週合計は#{total}kcal、記録のある#{days_with_logs}日の1日平均は#{average}kcalでした。"

    [ header, *daily_lines, footer ].join("\n")
  end

  def self.format_date(date)
    "#{date.year}年#{date.month}月#{date.day}日"
  end

  def self.format_log_item(log)
    base = "#{log.food_name}(#{log.calories}kcal)"
    return base if log.comment.blank?

    "#{base}[#{log.comment.gsub(/\s+/, ' ').strip}]"
  end

  private
    def copy_food_snapshot
      return if food.blank?

      self.food_name = food.name
      self.calories = food.manual_calories_enabled? ? calories.presence : food.calories
    end

    def food_category_matches_meal_type
      return if food.blank? || meal_type.blank?
      return if food.category == Food.category_for_meal_type(meal_type)

      errors.add(:food, "#{self.class.meal_label(meal_type)}には登録できません")
    end
end
