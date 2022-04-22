# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_03_30_233411) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_enum :todo_action_kind, [
    "check",
    "uncheck",
    "insert",
    "delete",
    "edit",
    "move",
  ], force: :cascade

  create_table "todo_actions", force: :cascade do |t|
    t.bigint "todo_list_id", null: false
    t.integer "version", null: false
    t.bigint "todo_id", null: false
    t.enum "kind", null: false, enum_type: "todo_action_kind"
    t.string "title"
    t.bigint "previous_id"
    t.string "uid", limit: 12, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["todo_id"], name: "index_todo_actions_on_todo_id"
    t.index ["todo_list_id", "version"], name: "index_todo_actions_on_todo_list_id_and_version", unique: true
    t.index ["uid"], name: "index_todo_actions_on_uid", unique: true
  end

  create_table "todo_lists", force: :cascade do |t|
    t.string "title", null: false
    t.integer "version", default: 0, null: false
    t.bigint "nil_todo_id"
    t.bigint "tmp_todo_id"
    t.bigint "last_todo_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "todos", force: :cascade do |t|
    t.string "title", null: false
    t.boolean "checked", default: false, null: false
    t.bigint "todo_list_id", null: false
    t.bigint "previous_id"
    t.boolean "deleted", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["todo_list_id", "id"], name: "index_todos_on_todo_list_id_and_id"
    t.index ["todo_list_id", "previous_id"], name: "index_todos_on_todo_list_id_and_previous_id", unique: true
    t.index ["todo_list_id"], name: "index_todos_on_todo_list_id"
  end

  add_foreign_key "todo_actions", "todos"
  add_foreign_key "todos", "todo_lists"
  add_foreign_key "todos", "todos", column: "previous_id"
end
