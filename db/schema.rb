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

ActiveRecord::Schema[8.1].define(version: 2026_04_04_010000) do
  create_table "daily_food_logs", force: :cascade do |t|
    t.integer "calories", null: false
    t.datetime "created_at", null: false
    t.date "eaten_on", null: false
    t.integer "food_id", null: false
    t.string "food_name", null: false
    t.integer "meal_type", null: false
    t.datetime "updated_at", null: false
    t.index ["eaten_on", "meal_type"], name: "index_daily_food_logs_on_eaten_on_and_meal_type"
    t.index ["eaten_on"], name: "index_daily_food_logs_on_eaten_on"
    t.index ["food_id"], name: "index_daily_food_logs_on_food_id"
  end

  create_table "foods", force: :cascade do |t|
    t.integer "calories", null: false
    t.integer "category", null: false
    t.datetime "created_at", null: false
    t.boolean "manual_calories_enabled", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["category", "name"], name: "index_foods_on_category_and_name", unique: true
  end

  add_foreign_key "daily_food_logs", "foods"
end
