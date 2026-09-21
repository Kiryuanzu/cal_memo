require "test_helper"

class TrainingExerciseTest < ActiveSupport::TestCase
  test "requires a name and known enums" do
    exercise = TrainingExercise.new(name: "", body_part: "unknown", training_type: "unknown")

    assert_not exercise.valid?
    assert exercise.errors[:name].any?
    assert exercise.errors[:body_part].any?
    assert exercise.errors[:training_type].any?
    assert_not TrainingExercise.new(name: "種目").valid?
  end

  test "names are unique within each training type" do
    squat = training_exercises(:squat)
    duplicate = squat.dup
    assert_not duplicate.valid?

    duplicate.training_type = :gym
    assert duplicate.valid?
  end

  test "cannot delete an exercise with recorded logs" do
    assert_raises ActiveRecord::DeleteRestrictionError do
      training_exercises(:squat).destroy!
    end
  end
end
