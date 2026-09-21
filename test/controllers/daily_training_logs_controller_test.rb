require "test_helper"

class DailyTrainingLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.local(2026, 9, 19, 10)
  end

  teardown do
    travel_back
  end

  test "shows today's logs with body parts and grouped input" do
    get daily_training_logs_url

    assert_response :success
    assert_select "h1", "筋トレ記録"
    assert_select "#daily-logs-section" do
      assert_select "h3", text: "スクワット"
      assert_select "h3", text: "プランク"
      assert_select "h3", text: "ジム・肩", count: 0
      assert_select "summary span", text: "10回 × 3セット"
      assert_select "summary span", text: "30秒 × 3セット"
      assert_select "summary span", text: /下半身 · 家トレ/
    end
    assert_select 'optgroup[label="家トレ"] option', count: 3
    assert_select 'optgroup[label="ジム"] option', count: 1
    assert_select "#training-home button", count: 3
    assert_select "#training-gym button", count: 1
    assert_select "#input-section details:not([open])", count: 1
    assert_select 'input[name="daily_training_log[trained_on]"][value="2026-09-19"]'
    assert_select "a[href=?]", root_path(date: "2026-09-19"), text: "食事・カロリー"
  end

  test "shows only selected date and preserves it in date navigation" do
    get daily_training_logs_url(date: "2026-09-18")

    assert_response :success
    assert_select "#daily-logs-section h3", count: 1, text: "ジム・肩"
    assert_select 'input[name="daily_training_log[trained_on]"][value="2026-09-18"]'
    assert_select "a[href=?]", daily_training_logs_path(date: "2026-09-17"), text: "前の日"
    assert_select "a[href=?]", daily_training_logs_path(date: "2026-09-19"), text: "次の日"
  end

  test "invalid browsing date falls back to today" do
    get daily_training_logs_url(date: "invalid")
    assert_response :success
    assert_select 'input[name="date"][value="2026-09-19"]'
  end

  test "shows an empty day" do
    get daily_training_logs_url(date: "2026-09-20")
    assert_select "#daily-logs-section", text: /この日の筋トレ記録はまだありません/
  end

  test "creates a log without navigation and appends it through Turbo" do
    get daily_training_logs_url(date: "2026-09-17")

    button_form = css_select("#training-gym form").first
    assert_equal daily_training_logs_path(date: "2026-09-17"), button_form["action"]
    assert_equal "post", button_form["method"]
    assert_equal "ジム・肩", button_form.at_css("button").text.strip
    assert_nil button_form.at_css('input[type="number"], select')
    button_params = button_form.css('input[type="hidden"]').to_h { |input| [ input["name"], input["value"] ] }

    assert_difference "DailyTrainingLog.count" do
      post button_form["action"], params: button_params, as: :turbo_stream
    end

    assert_response :success
    assert_nil response.headers["Location"]
    assert_select 'turbo-stream[action="append"][target="training-log-list"]'
    assert_select 'turbo-stream[action="replace"][target="training-summary"]'
    assert_select 'turbo-stream[action="remove"][target="training-empty-state"]'
    assert_select 'turbo-stream[action="remove"][target="training-input-errors"]'
    assert_select 'turbo-stream[target="input-section"]', count: 0
    log = DailyTrainingLog.order(:id).last
    assert_nil log.sets
    assert_nil log.reps
    assert_nil log.weight_kg
    assert_nil log.duration_seconds
    assert_select 'turbo-stream[target="training-log-list"] h3', "ジム・肩"
  end

  test "creates detailed log through Turbo and uses form date" do
    assert_difference "DailyTrainingLog.count" do
      post daily_training_logs_url(date: "2026-09-19"), params: {
        daily_training_log: {
          training_exercise_id: training_exercises(:curl).id,
          trained_on: "2026-09-16", sets: 3, reps: 10, weight_kg: "5.25", duration_seconds: 30
        }
      }, as: :turbo_stream
    end

    assert_redirected_to daily_training_logs_url(date: "2026-09-16", anchor: "input-section")
    log = DailyTrainingLog.order(:id).last
    assert_equal [ 3, 10, BigDecimal("5.25"), 30 ], [ log.sets, log.reps, log.weight_kg, log.duration_seconds ]
  end

  test "invalid details retain inputs and show Japanese errors" do
    assert_no_difference "DailyTrainingLog.count" do
      post daily_training_logs_url, params: {
        daily_training_log: {
          training_exercise_id: training_exercises(:squat).id,
          trained_on: "2026-09-18", sets: -1, reps: 10
        }
      }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_select "#input-section details[open]", count: 1
    assert_select '[role="alert"]', text: /セット数 は0より大きい値で入力してください/
    assert_select 'input[name="daily_training_log[trained_on]"][value="2026-09-18"]'
    assert_select 'input[name="daily_training_log[reps]"][value="10"]'
    assert_select "option[selected][value=?]", training_exercises(:squat).id.to_s
  end

  test "failed registration for another day keeps the visible day in button forms" do
    post daily_training_logs_url(date: "2026-09-19"), params: {
      daily_training_log: { training_exercise_id: training_exercises(:squat).id, trained_on: "2026-09-18", sets: -1 }
    }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select "#training-home form[action=?]", daily_training_logs_path(date: "2026-09-19")
    assert_select '#training-home input[name="daily_training_log[trained_on]"][value="2026-09-19"]'
    assert_select 'details input[name="daily_training_log[trained_on]"][value="2026-09-18"]'
    assert_select 'turbo-stream[target="training-summary"]', count: 0
  end

  test "missing and invalid dates are rejected rather than saved as today" do
    [ "", "invalid", "2026-02-30" ].each do |date|
      assert_no_difference "DailyTrainingLog.count" do
        post daily_training_logs_url, params: {
          daily_training_log: { training_exercise_id: training_exercises(:squat).id, trained_on: date }
        }
      end
      assert_response :unprocessable_entity
      assert_select '[role="alert"]', text: /日付 に有効な日付を入力してください/
    end
  end

  test "missing or nonexistent exercise shows a validation error" do
    [ "", TrainingExercise.maximum(:id) + 1 ].each do |exercise_id|
      assert_no_difference "DailyTrainingLog.count" do
        post daily_training_logs_url, params: {
          daily_training_log: { training_exercise_id: exercise_id, trained_on: "2026-09-19" }
        }
      end
      assert_response :unprocessable_entity
      assert_select '[role="alert"]', text: /筋トレ種目 を選択してください/
    end
  end

  test "existing pages link to the training screen outside the food Turbo frame" do
    get root_url(date: "2026-09-18")
    assert_select 'a[href=?][data-turbo-frame="_top"]', daily_training_logs_path(date: "2026-09-18"), text: "筋トレ"

    [ foods_url, balance_url ].each do |url|
      get url
      assert_select "a[href=?]", daily_training_logs_path, text: "筋トレ"
    end
  end

  test "empty exercise catalog hides registration and explains the state" do
    DailyTrainingLog.delete_all
    TrainingExercise.delete_all

    get daily_training_logs_url

    assert_response :success
    assert_select "p", "選択できる筋トレ種目がまだありません。"
    assert_select 'input[type="submit"][value="筋トレを記録"]', count: 0
  end

  test "each recorded log has a collapsed detail form with unique labels" do
    get daily_training_logs_url(date: "2026-09-19")

    [ daily_training_logs(:squat), daily_training_logs(:plank) ].each do |log|
      assert_select "#daily_training_log_#{log.id}:not([open])" do
        assert_select "summary h3", log.training_exercise.name
        assert_select "form[action=?]", daily_training_log_path(log) do
          assert_select 'input[name="_method"][value="patch"]'
          %w[sets reps weight_kg duration_seconds].each do |attribute|
            field_id = "daily_training_log_#{log.id}_daily_training_log_#{attribute}"
            assert_select "label[for=?]", field_id
            assert_select "input[id=?]", field_id
          end
        end
      end
    end
    ids = css_select("[id]").map { |element| element["id"] }
    assert_equal ids.uniq, ids
  end

  test "updates only the chosen log details without creating a new record" do
    log = daily_training_logs(:squat)
    other_log = log.dup.tap(&:save!)

    assert_no_difference "DailyTrainingLog.count" do
      patch daily_training_log_url(log), params: {
        daily_training_log: {
          sets: 4, reps: 12, weight_kg: "5.25", duration_seconds: 30,
          trained_on: "2026-09-18", training_exercise_id: training_exercises(:curl).id
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_nil response.headers["Location"]
    assert_select 'turbo-stream[action="replace"][target=?]', "daily_training_log_#{log.id}"
    assert_select "#daily_training_log_#{log.id}[open]"
    assert_select 'turbo-stream[target="training-summary"], turbo-stream[target="training-log-list"]', count: 0
    assert_equal [ 4, 12, BigDecimal("5.25"), 30 ], log.reload.attributes.values_at("sets", "reps", "weight_kg", "duration_seconds")
    assert_equal Date.new(2026, 9, 19), log.trained_on
    assert_equal training_exercises(:squat), log.training_exercise
    assert_equal [ 3, 10, nil, nil ], other_log.reload.attributes.values_at("sets", "reps", "weight_kg", "duration_seconds")
    assert_select "#daily_training_log_#{log.id} summary", text: /12回 \/ 30秒 × 4セット \/ 5.25kg/
  end

  test "detail fields can be cleared without deleting the log" do
    log = daily_training_logs(:squat)

    assert_no_difference "DailyTrainingLog.count" do
      patch daily_training_log_url(log), params: {
        daily_training_log: { sets: "", reps: "", weight_kg: "", duration_seconds: "" }
      }
    end

    assert_response :see_other
    assert_equal [ nil, nil, nil, nil ], log.reload.attributes.values_at("sets", "reps", "weight_kg", "duration_seconds")
  end

  test "invalid update preserves the record and opens only the affected form" do
    log = daily_training_logs(:squat)

    patch daily_training_log_url(log), params: {
      daily_training_log: { sets: -1, reps: 12, weight_kg: "5.25" }
    }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_equal [ 3, 10, nil ], log.reload.attributes.values_at("sets", "reps", "weight_kg")
    assert_select 'turbo-stream[action="replace"][target=?]', "daily_training_log_#{log.id}"
    assert_select "details[open]", count: 1
    assert_select "#daily_training_log_#{log.id}[open]" do
      assert_select '[role="alert"]', text: /セット数 は0より大きい値で入力してください/
      assert_select 'input[name="daily_training_log[sets]"][value="-1"]'
      assert_select 'input[name="daily_training_log[reps]"][value="12"]'
      assert_select 'input[name="daily_training_log[weight_kg]"][value="5.25"]'
    end
    assert_select "#input-section details[open]", count: 0
  end
end
