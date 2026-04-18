class AddCommentToDailyFoodLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :daily_food_logs, :comment, :text
  end
end
