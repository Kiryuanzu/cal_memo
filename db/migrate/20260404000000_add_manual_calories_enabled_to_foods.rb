class AddManualCaloriesEnabledToFoods < ActiveRecord::Migration[8.1]
  def up
    add_column :foods, :manual_calories_enabled, :boolean, null: false, default: false

    execute <<~SQL.squish
      UPDATE foods
      SET manual_calories_enabled = TRUE
      WHERE name = '外食'
    SQL
  end

  def down
    remove_column :foods, :manual_calories_enabled
  end
end
