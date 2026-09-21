require "test_helper"

class TrainingSeedsTest < ActiveSupport::TestCase
  test "seeds load both catalogs and preserve IDs when rerun" do
    capture_io { load Rails.root.join("db/seeds.rb") }
    exercise_ids = TrainingExercise.order(:id).pluck(:id)
    food_ids = Food.order(:id).pluck(:id)

    capture_io { load Rails.root.join("db/seeds.rb") }

    assert_equal exercise_ids, TrainingExercise.order(:id).pluck(:id)
    assert_equal food_ids, Food.order(:id).pluck(:id)
    assert_equal 8, TrainingExercise.count
    assert_equal 4, TrainingExercise.home.count
    assert_equal 4, TrainingExercise.gym.count
    assert_equal "core", TrainingExercise.find_by!(name: "サイドベント").body_part
    assert_equal "lower_body", TrainingExercise.find_by!(name: "スクワット").body_part
    assert_equal "chest_arms", TrainingExercise.find_by!(name: "ダンベルカール").body_part
    assert_equal "shoulder", TrainingExercise.find_by!(name: "ジム・肩").body_part
    assert Food.exists?(name: "茄子の煮浸し")
    assert daily_training_logs(:squat).reload.training_exercise.present?
  end
end
