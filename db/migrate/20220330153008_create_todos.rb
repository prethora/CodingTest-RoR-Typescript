class CreateTodos < ActiveRecord::Migration[6.1]
  def change
    create_table :todos do |t|
      t.string :title
      t.boolean :checked, :default => false
      t.references :todo_list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
