class CreateDailyTrainingLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_training_logs do |t|
      t.references :training_exercise, null: false, foreign_key: true
      t.date :trained_on, null: false
      t.integer :sets
      t.integer :reps
      t.decimal :weight_kg, precision: 6, scale: 2
      t.integer :duration_seconds

      t.timestamps
    end

    add_index :daily_training_logs, :trained_on
  end
end
