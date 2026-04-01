require "test_helper"

class DailyFoodLogTest < ActiveSupport::TestCase
  test "copies food snapshot on create" do
    log = DailyFoodLog.create!(
      food: foods(:breakfast_banana),
      meal_type: :breakfast,
      eaten_on: Date.new(2026, 4, 1)
    )

    assert_equal "バナナ", log.food_name
    assert_equal 86, log.calories
  end

  test "is invalid when meal type does not match food category" do
    log = DailyFoodLog.new(
      food: foods(:snack_latte),
      meal_type: :breakfast,
      eaten_on: Date.new(2026, 4, 1)
    )

    assert_not log.valid?
    assert_includes log.errors[:food], "朝には登録できません"
  end

  test "builds natural language summary" do
    logs = [ daily_food_logs(:today_breakfast), daily_food_logs(:today_lunch) ]

    text = DailyFoodLog.natural_language_for(Date.new(2026, 4, 1), logs)

    assert_includes text, "2026年4月1日"
    assert_includes text, "朝はトースト(220kcal)"
    assert_includes text, "昼はカレーライス(840kcal)"
    assert_includes text, "合計1060kcal"
  end
end
