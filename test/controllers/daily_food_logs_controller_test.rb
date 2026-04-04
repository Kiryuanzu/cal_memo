require "test_helper"

class DailyFoodLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.local(2026, 4, 1, 10, 0, 0)
    @daily_food_log = daily_food_logs(:today_breakfast)
  end

  teardown do
    travel_back
  end

  test "should get index" do
    get root_url

    assert_response :success
    assert_match "カロリー計算メモ帳", @response.body
    assert_match "トースト", @response.body
    assert_match "1,060 kcal", @response.body
  end

  test "should create daily food log from selected food" do
    assert_difference("DailyFoodLog.count") do
      post daily_food_logs_url, params: {
        tab: "day",
        daily_food_log: {
          food_id: foods(:snack_latte).id,
          meal_type: "snack",
          eaten_on: "2026-04-01"
        }
      }
    end

    log = DailyFoodLog.find_by!(
      food: foods(:snack_latte),
      meal_type: :snack,
      eaten_on: Date.new(2026, 4, 1)
    )

    assert_equal "カフェラテ", log.food_name
    assert_equal 130, log.calories
    assert_redirected_to root_url(date: "2026-04-01", tab: "day")
  end

  test "should show manual calorie form for eating out" do
    get root_url(date: "2026-04-01", tab: "day")

    assert_response :success
    assert_match "外食", @response.body
    assert_match 'name="daily_food_log[calories]"', @response.body
    assert_match 'data-controller="manual-calorie-form"', @response.body
    assert_match 'turbo:submit-end-&gt;manual-calorie-form#submitEnd', @response.body
  end

  test "should create daily food log from eating out with manual calories" do
    assert_difference("DailyFoodLog.count") do
      post daily_food_logs_url, params: {
        tab: "day",
        daily_food_log: {
          food_id: foods(:lunch_eating_out).id,
          meal_type: "lunch",
          eaten_on: "2026-04-01",
          calories: "1234"
        }
      }
    end

    log = DailyFoodLog.find_by!(
      food: foods(:lunch_eating_out),
      meal_type: :lunch,
      eaten_on: Date.new(2026, 4, 1),
      calories: 1234
    )

    assert_equal "外食", log.food_name
    assert_redirected_to root_url(date: "2026-04-01", tab: "day")
  end

  test "should close manual calorie form after successful turbo stream create" do
    post daily_food_logs_url,
      params: {
        tab: "day",
        daily_food_log: {
          food_id: foods(:lunch_eating_out).id,
          meal_type: "lunch",
          eaten_on: "2026-04-01",
          calories: "1234"
        }
      },
      as: :turbo_stream

    assert_response :success
    assert_no_match 'data-manual-calorie-form-open-value="true"', @response.body
  end

  test "should require calories for eating out" do
    assert_no_difference("DailyFoodLog.count") do
      post daily_food_logs_url, params: {
        tab: "day",
        daily_food_log: {
          food_id: foods(:lunch_eating_out).id,
          meal_type: "lunch",
          eaten_on: "2026-04-01",
          calories: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "カロリーを入力して登録します。", @response.body
    assert_match 'name="daily_food_log[calories]"', @response.body
  end

  test "should keep manual calorie form open after invalid turbo stream create" do
    post daily_food_logs_url,
      params: {
        tab: "day",
        daily_food_log: {
          food_id: foods(:lunch_eating_out).id,
          meal_type: "lunch",
          eaten_on: "2026-04-01",
          calories: ""
        }
      },
      as: :turbo_stream

    assert_response :unprocessable_entity
    assert_match 'data-manual-calorie-form-open-value="true"', @response.body
  end

  test "should reject mismatched food category" do
    assert_no_difference("DailyFoodLog.count") do
      post daily_food_logs_url, params: {
        tab: "day",
        daily_food_log: {
          food_id: foods(:snack_latte).id,
          meal_type: "breakfast",
          eaten_on: "2026-04-01"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "朝には登録できません", @response.body
  end

  test "should destroy daily food log" do
    assert_difference("DailyFoodLog.count", -1) do
      delete daily_food_log_url(@daily_food_log), params: { date: "2026-04-01", tab: "day" }
    end

    assert_redirected_to root_url(date: "2026-04-01", tab: "day")
  end

  test "shows monthly summary from latest month" do
    DailyFoodLog.create!(
      food: foods(:lunch_curry),
      food_name: "カレーライス",
      calories: 840,
      eaten_on: Date.new(2026, 2, 10),
      meal_type: :lunch
    )

    get root_url(tab: "month", date: "2026-04-01")

    assert_response :success
    assert_operator @response.body.index("2026/4"), :<, @response.body.index("2026/3")
    assert_operator @response.body.index("2026/3"), :<, @response.body.index("2026/2")
  end
end
