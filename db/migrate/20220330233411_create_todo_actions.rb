class CreateTodoActions < ActiveRecord::Migration[6.1]
  def change
    create_enum :todo_action_kind, %w(check uncheck insert delete edit move)

    create_table :todo_actions do |t|
      t.bigint :todo_list_id, null: false, foreign_key: true
      t.integer :version, null: false
      t.references :todo, null: false, foreign_key: true
      t.enum :kind, null: false, enum_type: :todo_action_kind
      t.string :title
      t.bigint :previous_id
      t.column :uid, "char(12)", null: false

      t.timestamps
    end

    add_index :todo_actions, [:todo_list_id, :version], unique: true
    add_index :todo_actions, [:uid], unique: true, using: :btree
  end
end