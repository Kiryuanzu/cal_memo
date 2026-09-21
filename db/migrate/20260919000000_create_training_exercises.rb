class CreateTrainingExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :training_exercises do |t|
      t.string :name, null: false
      t.integer :body_part, null: false
      t.integer :training_type, null: false

      t.timestamps
    end

    add_index :training_exercises, [ :training_type, :name ], unique: true
  end
end
