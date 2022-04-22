class CreateTodoLists < ActiveRecord::Migration[6.1]
  def change
    create_table :todo_lists do |t|
      t.string :title, null: false
      t.integer :version, null: false, :default => 0
      t.bigint :nil_todo_id
      t.bigint :tmp_todo_id
      t.bigint :last_todo_id

      t.timestamps
    end
  end
end