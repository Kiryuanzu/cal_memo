require "test_helper"

class TrainingPreviousDayTest < ActionDispatch::IntegrationTest
  test "home and gym on adjacent days do not count as consecutive in either direction" do
    gym_core = TrainingExercise.create!(name: "ジム・腹回り", body_part: :core, training_type: :gym)
    DailyTrainingLog.create!(training_exercise: gym_core, trained_on: "2026-09-18")
    DailyTrainingLog.create!(training_exercise: gym_core, trained_on: "2026-09-20")

    %w[2026-09-19 2026-09-20].each do |date|
      %w[day week month].each do |tab|
        get daily_training_logs_url(date: date, tab: tab)

        assert_response :success
        assert_select '#previous-training [data-body-part="core"]', text: /2日連続/, count: 0
        assert_select '#previous-training [data-body-part="core"].bg-amber-50', count: 0
        assert_select 'tr[data-date=?] td[data-body-part="core"]', date, text: /2日連続/, count: 0
      end
    end
  end

  test "both training types show separate consecutive labels without inflating day counts" do
    gym_core = TrainingExercise.create!(name: "ジム・腹回り", body_part: :core, training_type: :gym)
    side_bend = TrainingExercise.create!(name: "サイドベント", body_part: :core, training_type: :home)
    %w[2026-09-18 2026-09-19].each do |date|
      [ gym_core, side_bend ].each do |exercise|
        2.times { DailyTrainingLog.create!(training_exercise: exercise, trained_on: date) }
      end
    end

    get daily_training_logs_url(date: "2026-09-19", tab: "week")

    assert_select '#previous-training [data-body-part="core"]' do
      assert_select '[data-training-type="home"]', text: "家トレ 2日連続", count: 1
      assert_select '[data-training-type="gym"]', text: "ジム 2日連続", count: 1
    end
    assert_select 'tr[data-date="2026-09-19"] td[data-body-part="core"]' do
      assert_select '[data-training-type="home"]', text: "家トレ 2日連続", count: 1
      assert_select '[data-training-type="gym"]', text: "ジム 2日連続", count: 1
    end
    assert_select "#training-days-core dd", "2日"
    assert_select "#training-days", text: /筋トレ実施 2 \/ 7日/
  end

  test "only the matching type is marked when today has both types" do
    gym_core = TrainingExercise.create!(name: "ジム・腹回り", body_part: :core, training_type: :gym)
    %w[2026-09-18 2026-09-19].each do |date|
      DailyTrainingLog.create!(training_exercise: gym_core, trained_on: date)
    end

    get daily_training_logs_url(date: "2026-09-19")

    assert_select '#previous-training [data-body-part="core"] [data-training-type="gym"]', "ジム 2日連続"
    assert_select '#previous-training [data-body-part="core"] [data-training-type="home"]', count: 0
    assert_select 'tr[data-date="2026-09-19"] td[data-body-part="core"] [data-training-type="home"]', count: 0
  end

  test "shows previous day body parts and warns only for consecutive parts" do
    DailyTrainingLog.create!(training_exercise: training_exercises(:plank), trained_on: "2026-09-18")

    get daily_training_logs_url(date: "2026-09-19")

    assert_select '#previous-training [data-body-part="shoulder"] [data-day="previous"]', text: "●"
    assert_select '#previous-training [data-body-part="shoulder"]', text: /2日連続/, count: 0
    assert_select '#previous-training [data-body-part="core"]', text: /2日連続/
    assert_select '#previous-training [data-body-part="lower_body"] [data-day="previous"]', text: "—"
    assert_select '#training-summary tr[data-date="2026-09-19"] td[data-body-part="core"]', text: /2日連続/
    assert_select "#training-days", text: /筋トレ実施 1 \/ 1日/
  end

  test "week start compares with Sunday outside the period without counting it" do
    %w[2026-09-13 2026-09-14].each do |date|
      DailyTrainingLog.create!(training_exercise: training_exercises(:curl), trained_on: date)
    end

    get daily_training_logs_url(date: "2026-09-14", tab: "week")

    assert_select '#previous-training [data-body-part="chest_arms"]', text: /2日連続/
    assert_select '#training-summary tr[data-date="2026-09-14"] td[data-body-part="chest_arms"]', text: /2日連続/
    assert_select "#training-days-chest_arms dd", "1日"
    assert_select "#training-days", text: /筋トレ実施 3 \/ 7日/
  end

  test "month and year boundaries compare the prior month without counting it" do
    %w[2026-12-31 2027-01-01].each do |date|
      DailyTrainingLog.create!(training_exercise: training_exercises(:squat), trained_on: date)
    end

    get daily_training_logs_url(date: "2027-01-01", tab: "month")

    assert_select '#training-summary tr[data-date="2027-01-01"] td[data-body-part="lower_body"]', text: /2日連続/
    assert_select "#training-days-lower_body dd", "1日"
    assert_select "#training-days", text: /筋トレ実施 1 \/ 31日/
  end

  test "a gap does not count as consecutive training" do
    get daily_training_logs_url(date: "2026-09-21")

    assert_select "#previous-training", text: /前日の筋トレ記録はありません/
    assert_select "#previous-training [data-body-part]", text: /2日連続/, count: 0
    assert_select "#training-summary tbody td", text: /2日連続/, count: 0
  end

  test "consecutive training can be registered and updates the warning without navigation" do
    assert_difference "DailyTrainingLog.count" do
      post daily_training_logs_url(date: "2026-09-19", tab: "week"), params: {
        daily_training_log: { training_exercise_id: training_exercises(:gym_shoulder).id, trained_on: "2026-09-19" }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_nil response.headers["Location"]
    assert_select 'turbo-stream[target="training-summary"] #previous-training [data-body-part="shoulder"]', text: /ジム 2日連続/
    assert_select 'turbo-stream[action="append"][target="training-log-list"] h3', "ジム・肩"
    assert_select 'turbo-stream[target="page-top"], turbo-stream[target="input-section"]', count: 0
  end
end
