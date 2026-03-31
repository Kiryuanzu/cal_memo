class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.string :name, null: false
      t.integer :calories, null: false
      t.datetime :eaten_at, null: false
      t.text :note

      t.timestamps
    end

    add_index :entries, :eaten_at
  end
end
