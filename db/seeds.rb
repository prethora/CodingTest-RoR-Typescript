# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

list = TodoList.create!(title: "2022 Wish List")
list.versioned_todos_update(0,[
  {kind: "insert",title: "Purpose",previous_id: 0,uid: uid0=TodoAction.generate_uid},
  {kind: "insert",title: "Peace",previous_id: uid0,uid: uid1=TodoAction.generate_uid},
  {todo_id: uid1,kind: "check",uid: TodoAction.generate_uid},
  {kind: "insert",title: "Motivation",previous_id: uid1,uid: uid2=TodoAction.generate_uid},
  {kind: "insert",title: "Health",previous_id: uid2,uid: TodoAction.generate_uid}
])