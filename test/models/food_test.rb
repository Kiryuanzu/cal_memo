require "test_helper"

class FoodTest < ActiveSupport::TestCase
  test "is invalid when calories is zero" do
    food = Food.new(name: "水", calories: 0, category: :snack)

    assert_not food.valid?
    assert_includes food.errors[:calories], "must be greater than 0"
  end

  test "returns foods available for meal type" do
    assert_includes Food.available_for_meal_type(:breakfast), foods(:breakfast_toast)
    assert_includes Food.available_for_meal_type(:dinner), foods(:lunch_curry)
    assert_not_includes Food.available_for_meal_type(:breakfast), foods(:snack_latte)
  end
end
