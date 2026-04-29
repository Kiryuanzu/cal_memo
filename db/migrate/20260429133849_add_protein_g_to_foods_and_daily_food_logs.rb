class AddProteinGToFoodsAndDailyFoodLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :foods, :protein_g, :integer, null: false, default: 0
    add_column :daily_food_logs, :protein_g, :integer, null: false, default: 0
  end
end
