class DailyTrainingLog < ApplicationRecord
  belongs_to :training_exercise

  validates :trained_on, presence: true
  validates :sets, :reps, :duration_seconds,
    numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :weight_kg,
    numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :for_date, ->(date) { where(trained_on: date) }

  def self.body_parts_by_date(range)
    training_types_by_date(range).transform_values(&:keys)
  end

  def self.training_types_by_date(range)
    pairs = TrainingExercise.joins(:daily_training_logs)
      .where(daily_training_logs: { trained_on: range })
      .distinct.pluck("daily_training_logs.trained_on", :body_part, :training_type)

    pairs.each_with_object({}) do |(date, body_part, training_type), result|
      result[date] ||= {}
      result[date][body_part] ||= []
      result[date][body_part] << training_type
    end
  end
end
