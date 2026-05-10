class AddFoodGroupToFoodsAndDailyFoodLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :foods, :food_group, :integer, null: false, default: 0
    add_column :daily_food_logs, :food_group, :integer, null: false, default: 0
    add_index :daily_food_logs, [ :eaten_on, :food_group ]
  end
end
