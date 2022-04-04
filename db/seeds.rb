# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

todo_list = TodoList.create(title: "2022 Wish List",version: 1);
todo_list.todos.create(title: "Purpose")
peace_todo = todo_list.todos.create(title: "Peace", checked: true)
todo_list.todos.create(title: "Motivation")
todo_list.todos.create(title: "Health")
todo_list.actions.create(todo: peace_todo,version: 1,kind: "check")