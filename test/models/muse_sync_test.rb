require "test_helper"

class MuseSyncTest < ActiveSupport::TestCase
  test "payload includes every log with enum values as strings" do
    payload = MuseSync.new(url: "https://example.test", token: "t").payload

    assert_equal DailyFoodLog.count, payload[:logs].size

    lunch = daily_food_logs(:today_lunch)
    entry = payload[:logs].find { |log| log[:id] == lunch.id }
    assert_equal(
      {
        id: lunch.id,
        date: "2026-04-01",
        meal_type: "lunch",
        food_name: "カレーライス",
        calories: 840,
        protein_g: lunch.protein_g,
        food_group: "main",
        comment: lunch.comment
      },
      entry
    )
  end

  test "requires url and token" do
    assert_raises(ArgumentError) { MuseSync.new(url: "", token: "t") }
    assert_raises(ArgumentError) { MuseSync.new(url: "https://example.test", token: nil) }
  end
end
