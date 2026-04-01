class CreateDailyFoodLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_food_logs do |t|
      t.references :food, null: false, foreign_key: true
      t.string :food_name, null: false
      t.integer :calories, null: false
      t.date :eaten_on, null: false
      t.integer :meal_type, null: false

      t.timestamps
    end

    add_index :daily_food_logs, :eaten_on
    add_index :daily_food_logs, [ :eaten_on, :meal_type ]
  end
end
