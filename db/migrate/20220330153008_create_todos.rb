class CreateTodos < ActiveRecord::Migration[6.1]
  def change
    create_table :todos do |t|
      t.string :title, null: false
      t.boolean :checked, null: false, :default => false
      t.references :todo_list, null: false, foreign_key: true
      t.references :previous, index: false, foreign_key: {to_table: :todos}
      t.boolean :deleted, null: false, :default => false

      t.timestamps
    end

    add_index :todos, [:todo_list_id, :previous_id], unique: true
    add_index :todos, [:todo_list_id, :id]
  end
end
