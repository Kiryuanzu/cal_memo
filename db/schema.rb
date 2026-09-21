# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_19_000100) do
  create_table "daily_food_logs", force: :cascade do |t|
    t.integer "calories", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.date "eaten_on", null: false
    t.integer "food_group", default: 0, null: false
    t.integer "food_id", null: false
    t.string "food_name", null: false
    t.integer "meal_type", null: false
    t.integer "protein_g", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["eaten_on", "food_group"], name: "index_daily_food_logs_on_eaten_on_and_food_group"
    t.index ["eaten_on", "meal_type"], name: "index_daily_food_logs_on_eaten_on_and_meal_type"
    t.index ["eaten_on"], name: "index_daily_food_logs_on_eaten_on"
    t.index ["food_id"], name: "index_daily_food_logs_on_food_id"
  end

  create_table "daily_training_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.integer "reps"
    t.integer "sets"
    t.date "trained_on", null: false
    t.integer "training_exercise_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight_kg", precision: 6, scale: 2
    t.index ["trained_on"], name: "index_daily_training_logs_on_trained_on"
    t.index ["training_exercise_id"], name: "index_daily_training_logs_on_training_exercise_id"
  end

  create_table "foods", force: :cascade do |t|
    t.integer "calories", null: false
    t.integer "category", null: false
    t.datetime "created_at", null: false
    t.integer "food_group", default: 0, null: false
    t.boolean "manual_calories_enabled", default: false, null: false
    t.string "name", null: false
    t.integer "protein_g", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["category", "name"], name: "index_foods_on_category_and_name", unique: true
  end

  create_table "training_exercises", force: :cascade do |t|
    t.integer "body_part", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "training_type", null: false
    t.datetime "updated_at", null: false
    t.index ["training_type", "name"], name: "index_training_exercises_on_training_type_and_name", unique: true
  end

  add_foreign_key "daily_food_logs", "foods"
  add_foreign_key "daily_training_logs", "training_exercises"
end
