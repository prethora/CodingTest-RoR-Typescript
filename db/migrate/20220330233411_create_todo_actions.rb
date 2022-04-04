class CreateTodoActions < ActiveRecord::Migration[6.1]
  def change
    create_enum :todo_action_kind, %w(check uncheck)

    create_table :todo_actions do |t|
      t.bigint :todo_list_id, null: false, foreign_key: true
      t.integer :version
      t.references :todo, null: false, foreign_key: true
      t.enum :kind, enum_type: :todo_action_kind

      t.timestamps
    end

    add_index :todo_actions, [:todo_list_id, :version], unique: true
  end
end