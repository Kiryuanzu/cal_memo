class CreateFoods < ActiveRecord::Migration[8.1]
  def change
    create_table :foods do |t|
      t.string :name, null: false
      t.integer :calories, null: false
      t.integer :category, null: false

      t.timestamps
    end

    add_index :foods, [ :category, :name ], unique: true
  end
end
