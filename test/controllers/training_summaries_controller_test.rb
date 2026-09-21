require "test_helper"

class TrainingSummariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.local(2026, 9, 19, 10)
    gym_lower_body = TrainingExercise.create!(name: "ジム・下半身", body_part: :lower_body, training_type: :gym)
    DailyTrainingLog.create!(training_exercise: gym_lower_body, trained_on: "2026-09-19")
    2.times { record(:curl, "2026-09-19") }
  end

  teardown do
    travel_back
  end

  test "day summary shows all four body parts and counts a day only once" do
    get daily_training_logs_url(date: "2026-09-19")

    assert_response :success
    assert_select "#training-days", text: /筋トレ実施 1 \/ 1日/
    assert_counts(shoulder: 0, chest_arms: 1, core: 1, lower_body: 1)
    assert_select "#training-summary tbody tr", count: 1
    assert_select '#training-summary tbody span[aria-label="記録あり"]', count: 3
    assert_select '#training-summary tbody span[aria-label="記録なし"]', count: 1
  end

  test "week includes Monday and Sunday and excludes adjacent weeks" do
    record(:gym_shoulder, "2026-09-14")
    record(:plank, "2026-09-20")
    record(:curl, "2026-09-13")
    record(:curl, "2026-09-21")

    get daily_training_logs_url(date: "2026-09-19", tab: "week")

    assert_response :success
    assert_select "#training-summary h3", "2026/9/14〜2026/9/20"
    assert_select "#training-days", text: /筋トレ実施 4 \/ 7日/
    assert_counts(shoulder: 2, chest_arms: 1, core: 2, lower_body: 1)
    assert_select "#training-summary tbody tr", count: 7
    assert_select '#training-summary tr[data-date="2026-09-13"]', count: 0
    assert_select '#training-summary tr[data-date="2026-09-20"] span[aria-label="記録あり"]', count: 1
    assert_select "#training-summary a[href=?]", daily_training_logs_path(date: "2026-09-12", tab: "week", anchor: "training-summary"), text: "前の週"
    assert_select "#training-summary a[href=?]", daily_training_logs_path(date: "2026-09-26", tab: "week", anchor: "training-summary"), text: "次の週"
  end

  test "month includes first and last days and excludes neighboring months" do
    record(:plank, "2026-09-01")
    record(:gym_shoulder, "2026-09-30")
    record(:gym_shoulder, "2026-08-31")
    record(:gym_shoulder, "2026-10-01")

    get daily_training_logs_url(date: "2026-09-19", tab: "month")

    assert_response :success
    assert_select "#training-summary h3", "2026年9月"
    assert_select "#training-days", text: /筋トレ実施 4 \/ 30日/
    assert_counts(shoulder: 2, chest_arms: 1, core: 2, lower_body: 1)
    assert_select "#training-summary tbody tr", count: 30
    assert_select '#training-summary tr[data-date="2026-08-31"]', count: 0
    assert_select '#training-summary tr[data-date="2026-10-01"]', count: 0
  end

  test "empty leap month displays zero counts and all 29 dates" do
    get daily_training_logs_url(date: "2024-02-29", tab: "month")

    assert_response :success
    assert_select "#training-days", text: /筋トレ実施 0 \/ 29日/
    assert_counts(shoulder: 0, chest_arms: 0, core: 0, lower_body: 0)
    assert_select "#training-summary tbody tr", count: 29
    assert_select '#training-summary tbody span[aria-label="記録あり"]', count: 0
  end

  test "day links lead to daily records and invalid tabs fall back to day" do
    get daily_training_logs_url(date: "2026-09-19", tab: "week")
    assert_select "#training-summary a[href=?]", daily_training_logs_path(date: "2026-09-18", anchor: "daily-logs-section"), text: "9/18"

    get daily_training_logs_url(date: "2026-09-18", tab: "unknown")
    assert_select "#training-summary tbody tr", count: 1
    assert_select '#training-summary a[aria-current="page"]', text: "日"
    assert_select "#daily-logs-section h3", "ジム・肩"
  end

  test "period selection persists through date navigation registration and editing" do
    get daily_training_logs_url(date: "2026-09-19", tab: "week")
    assert_select 'input[name="tab"][value="week"]'
    assert_select "a[href=?]", daily_training_logs_path(date: "2026-09-18", tab: "week"), text: "前の日"
    assert_select "#training-home form[action=?]", daily_training_logs_path(tab: "week", date: "2026-09-19")

    post daily_training_logs_url(tab: "week"), params: {
      daily_training_log: { training_exercise_id: training_exercises(:plank).id, trained_on: "2026-09-19" }
    }
    assert_redirected_to daily_training_logs_url(date: "2026-09-19", tab: "week", anchor: "input-section")

    log = daily_training_logs(:squat)
    patch daily_training_log_url(log, tab: "month"), params: { daily_training_log: { sets: 4 } }
    assert_redirected_to daily_training_logs_url(date: "2026-09-19", tab: "month", anchor: "daily_training_log_#{log.id}")

    patch daily_training_log_url(log, tab: "month"), params: { daily_training_log: { sets: -1 } }
    assert_response :unprocessable_entity
    assert_select '#training-summary a[aria-current="page"]', text: "月"
    assert_select "#training-days", text: /筋トレ実施 2 \/ 30日/
    assert_select "#daily_training_log_#{log.id}[open] form[action=?]", daily_training_log_path(log, tab: "month")
  end

  private
    def record(exercise, date)
      DailyTrainingLog.create!(training_exercise: training_exercises(exercise), trained_on: date)
    end

    def assert_counts(expected)
      expected.each do |body_part, days|
        assert_select "#training-days-#{body_part} dd", "#{days}日"
      end
    end
end
