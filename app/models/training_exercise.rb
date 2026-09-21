class TrainingExercise < ApplicationRecord
  BODY_PART_LABELS = {
    "shoulder" => "肩",
    "chest_arms" => "胸・上腕",
    "core" => "腹回り",
    "lower_body" => "下半身"
  }.freeze

  TRAINING_TYPE_LABELS = { "home" => "家トレ", "gym" => "ジム" }.freeze

  has_many :daily_training_logs, dependent: :restrict_with_exception

  enum :body_part, { shoulder: 0, chest_arms: 1, core: 2, lower_body: 3 }, validate: true
  enum :training_type, { gym: 0, home: 1 }, validate: true

  validates :name, presence: true, uniqueness: { scope: :training_type }

  scope :alphabetical, -> { order(:name) }

  def body_part_label
    BODY_PART_LABELS.fetch(body_part)
  end

  def training_type_label
    TRAINING_TYPE_LABELS.fetch(training_type)
  end
end
