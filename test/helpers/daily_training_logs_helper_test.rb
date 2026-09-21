require "test_helper"

class DailyTrainingLogsHelperTest < ActionView::TestCase
  test "period navigation handles month ends leap years and year boundaries" do
    assert_equal Date.new(2024, 2, 29), training_period_date(Date.new(2024, 1, 31), "month", 1)
    assert_equal Date.new(2026, 2, 28), training_period_date(Date.new(2026, 3, 31), "month", -1)
    assert_equal Date.new(2027, 1, 31), training_period_date(Date.new(2026, 12, 31), "month", 1)
    assert_equal Date.new(2027, 1, 7), training_period_date(Date.new(2026, 12, 31), "week", 1)
  end

  test "formats repetitions duration and weight without requiring details" do
    assert_equal "10回 × 3セット", training_log_details(daily_training_logs(:squat))
    assert_equal "30秒 × 3セット", training_log_details(daily_training_logs(:plank))
    assert_equal "実施を記録", training_log_details(daily_training_logs(:previous_day))

    log = DailyTrainingLog.new(reps: 10, sets: 3, weight_kg: 5)
    assert_equal "10回 × 3セット / 5kg", training_log_details(log)
    log.weight_kg = 5.25
    assert_equal "10回 × 3セット / 5.25kg", training_log_details(log)
  end

  test "formats partial details and zero weight" do
    assert_equal "3セット", training_log_details(DailyTrainingLog.new(sets: 3))
    assert_equal "10回", training_log_details(DailyTrainingLog.new(reps: 10))
    assert_equal "30秒", training_log_details(DailyTrainingLog.new(duration_seconds: 30))
    assert_equal "0kg", training_log_details(DailyTrainingLog.new(weight_kg: 0))
  end
end
