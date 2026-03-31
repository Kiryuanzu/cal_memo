class Entry < ApplicationRecord
  before_validation :set_default_eaten_at, on: :create

  scope :recent, -> { order(eaten_at: :desc, created_at: :desc) }
  scope :eaten_on, ->(date) { where(eaten_at: date.all_day) }

  validates :name, presence: true
  validates :calories, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }
  validates :eaten_at, presence: true

  private
    def set_default_eaten_at
      self.eaten_at ||= Time.zone.now
    end
end
