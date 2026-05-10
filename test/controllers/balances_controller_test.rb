require "test_helper"

class BalancesControllerTest < ActionDispatch::IntegrationTest
  test "renders balance page with default range" do
    get balance_path

    assert_response :success
    assert_select "h1", "食生活バランス"
  end

  test "honors range parameter when allowed" do
    get balance_path(range: 7)

    assert_response :success
    assert_select "h1", "食生活バランス"
  end

  test "falls back to default when range is invalid" do
    get balance_path(range: 999)

    assert_response :success
  end

  test "lists stale foods grouped by food_group" do
    food = foods(:breakfast_banana)
    DailyFoodLog.create!(
      food: food,
      meal_type: :breakfast,
      eaten_on: 60.days.ago.to_date
    )

    get balance_path

    assert_response :success
    assert_select "section", text: /最近食べていない食材/
    assert_select "li", text: /バナナ/
  end
end
