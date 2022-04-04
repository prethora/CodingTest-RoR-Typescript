FactoryBot.define do
  factory :todo_list do
    title { "My List" }

    trait :with_todos do
      transient do
        todo_count { 3 }
        todo_title { "Some Task" }
      end
      after(:create) do |todo_list,evaluator|
        create_list(:todo, evaluator.todo_count, todo_list: todo_list,title: evaluator.todo_title)
      end
    end

    trait :with_todos_and_actions do
      version { 5 }
      after(:create) do |todo_list|
        create(:todo,checked: true,todo_list: todo_list)
        create(:todo,checked: true,todo_list: todo_list)
        create(:todo,checked: true,todo_list: todo_list)
        create(:todo,checked: false,todo_list: todo_list)
        todos = todo_list.todos
        create(:todo_action,todo_list: todo_list,todo: todos[0],kind: "check",version: 1)
        create(:todo_action,todo_list: todo_list,todo: todos[1],kind: "check",version: 2)
        create(:todo_action,todo_list: todo_list,todo: todos[2],kind: "check",version: 3)
        create(:todo_action,todo_list: todo_list,todo: todos[1],kind: "uncheck",version: 4)
        create(:todo_action,todo_list: todo_list,todo: todos[1],kind: "check",version: 5)
      end
    end
  end
end