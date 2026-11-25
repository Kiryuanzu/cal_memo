require "test_helper"

class TrainingDeletionsControllerTest < ActionDispatch::IntegrationTest
  test "cards have confirmation buttons for their own records" do
    get daily_training_logs_url(date: "2026-09-19", tab: "week")

    log = daily_training_logs(:squat)
    assert_select "#item_daily_training_log_#{log.id}" do
      assert_select "form[data-turbo-confirm=?]", "2026/9/19のスクワットの記録を削除しますか？" do
        assert_select "[action=?]", daily_training_log_path(log, tab: "week")
        assert_select 'input[name="_method"][value="delete"]'
        assert_select "button", "削除"
      end
    end
  end

  test "deleting one duplicate preserves the other record and body part day count" do
    log = daily_training_logs(:squat)
    duplicate = log.dup.tap(&:save!)

    assert_difference "DailyTrainingLog.count", -1 do
      delete daily_training_log_url(log, tab: "week"), as: :turbo_stream
    end

    assert_response :success
    assert_nil response.headers["Location"]
    assert_not DailyTrainingLog.exists?(log.id)
    assert DailyTrainingLog.exists?(duplicate.id)
    assert TrainingExercise.exists?(log.training_exercise_id)
    assert_select 'turbo-stream[action="remove"][target=?]', "item_daily_training_log_#{log.id}"
    assert_select 'turbo-stream[target="training-log-list"]', count: 0
    assert_select 'turbo-stream[target="training-empty-message"]', count: 0
    assert_select "#training-days-lower_body dd", "1日"
    assert_select '#training-summary a[aria-current="page"]', "週"
  end

  test "deletion updates body part counts and clears consecutive indicators" do
    log = daily_training_logs(:plank)
    %w[2026-09-18 2026-09-20].each do |date|
      DailyTrainingLog.create!(training_exercise: log.training_exercise, trained_on: date)
    end

    delete daily_training_log_url(log, tab: "month"), as: :turbo_stream

    assert_response :success
    assert_select "#training-days-core dd", "2日"
    assert_select '#previous-training [data-body-part="core"]', text: /2日連続/, count: 0
    assert_select 'tr[data-date="2026-09-20"] td[data-body-part="core"]', text: /2日連続/, count: 0
    assert_select "#training-days", text: /筋トレ実施 3 \/ 30日/
  end

  test "deleting the last record shows the empty state without navigation" do
    log = daily_training_logs(:previous_day)

    delete daily_training_log_url(log), as: :turbo_stream

    assert_response :success
    assert_nil response.headers["Location"]
    assert_select 'turbo-stream[action="update"][target="training-empty-message"] #training-empty-state', text: /この日の筋トレ記録はまだありません/
    assert_select "#training-days", text: /筋トレ実施 0 \/ 1日/
    assert_select "#training-days-shoulder dd", "0日"
  end

  test "HTML deletion returns to the actual record date and selected period" do
    log = daily_training_logs(:previous_day)

    assert_difference "DailyTrainingLog.count", -1 do
      delete daily_training_log_url(log, date: "2026-09-19", tab: "month")
    end

    assert_redirected_to daily_training_logs_url(date: "2026-09-18", tab: "month", anchor: "daily-logs-section")
    follow_redirect!
    assert_select "#training-empty-state"
  end

  test "a missing record returns not found without deleting anything" do
    assert_no_difference "DailyTrainingLog.count" do
      delete daily_training_log_url(DailyTrainingLog.maximum(:id) + 1), as: :turbo_stream
    end

    assert_response :not_found
  end
end
