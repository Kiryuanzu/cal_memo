class DropEntries < ActiveRecord::Migration[8.1]
  def change
    drop_table :entries do |t|
      t.string :name, null: false
      t.integer :calories, null: false
      t.datetime :eaten_at, null: false
      t.text :note
      t.timestamps

      t.index :eaten_at
    end
  end
end
