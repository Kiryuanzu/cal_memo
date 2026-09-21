require "test_helper"

class DailyTrainingLogTest < ActiveSupport::TestCase
  setup do
    @log = DailyTrainingLog.new(training_exercise: training_exercises(:squat), trained_on: "2026-09-19")
  end

  test "only date and exercise are required" do
    @log.save!
    @log.reload

    assert_nil @log.sets
    assert_nil @log.reps
    assert_nil @log.weight_kg
    assert_nil @log.duration_seconds
  end

  test "requires a valid date and exercise" do
    @log.trained_on = "2026-02-30"
    @log.training_exercise = nil

    assert_not @log.valid?
    assert @log.errors[:trained_on].any?
    assert @log.errors[:training_exercise].any?
  end

  test "sets reps and duration must be positive integers when entered" do
    %i[sets reps duration_seconds].each do |attribute|
      [ 0, -1, 1.5, "abc" ].each do |value|
        @log.public_send("#{attribute}=", value)
        assert_not @log.valid?, "#{attribute}=#{value} must be invalid"
        assert @log.errors[attribute].any?
      end
      @log.public_send("#{attribute}=", nil)
    end
  end

  test "weight permits zero and fractional values but rejects negative or nonnumeric input" do
    [ 0, "5.25" ].each do |weight|
      @log.weight_kg = weight
      assert @log.valid?
    end

    @log.save!
    assert_equal BigDecimal("5.25"), @log.reload.weight_kg

    [ -1, "abc" ].each do |weight|
      @log.weight_kg = weight
      assert_not @log.valid?
    end
  end

  test "same exercise can be logged more than once on the same day" do
    assert_difference "DailyTrainingLog.count", 2 do
      2.times { DailyTrainingLog.create!(@log.attributes.except("id", "created_at", "updated_at")) }
    end
  end

  test "body part is read from the exercise without a snapshot" do
    @log.save!
    @log.training_exercise.update!(body_part: :core)

    assert_equal "core", @log.reload.training_exercise.body_part
    assert_not DailyTrainingLog.column_names.include?("body_part")
  end

  test "body part summary deduplicates exercises and training types on the same day" do
    gym_lower_body = TrainingExercise.create!(name: "ジム・下半身", body_part: :lower_body, training_type: :gym)
    2.times { @log.dup.save! }
    DailyTrainingLog.create!(training_exercise: gym_lower_body, trained_on: "2026-09-19")
    DailyTrainingLog.create!(training_exercise: gym_lower_body, trained_on: "2026-09-20")

    summary = DailyTrainingLog.body_parts_by_date(Date.new(2026, 9, 19)..Date.new(2026, 9, 20))

    assert_equal [ "core", "lower_body" ], summary.fetch(Date.new(2026, 9, 19)).sort
    assert_equal [ "lower_body" ], summary.fetch(Date.new(2026, 9, 20))
    assert_equal 2, summary.size
  end
end
