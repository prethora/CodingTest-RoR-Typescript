FactoryBot.define do
  factory :todo_list do
    title { "My List" }
      transient do
        todo_count { 0 }
        todo_title_prefix { "Some Task " }
        todo_checked_indexes { [] }
      end
      after(:create) do |todo_list,evaluator|
        previous = todo_list.nil_todo
        version = 0
        index = -1
        evaluator.todo_count.times do 
          index+= 1
          title = "#{evaluator.todo_title_prefix}#{index}"
          previous_id = previous.id
          previous_id = nil if previous_id==todo_list.nil_todo.id
          checked = evaluator.todo_checked_indexes.include? index
          previous = create(:todo,todo_list: todo_list,title: title,checked: checked,previous: previous)
          version+= 1
          create(:todo_action,todo_list: todo_list,todo: previous,kind: "insert",title: title,previous_id: previous_id,version: version)
          if checked
            version+= 1
            create(:todo_action,todo_list: todo_list,todo: previous,kind: "check",version: version)
          end
        end
        todo_list.update!(version: version,last_todo_id: previous.id) if version>0
      end

    # trait :with_todos do
    #   transient do
    #     todo_count { 3 }
    #     todo_title { "Some Task" }
    #   end
    #   after(:create) do |todo_list,evaluator|
    #     previous = todo_list.nil_todo
    #     evaluator.todo_count.times do 
    #       previous = create(:todo,todo_list: todo_list,title: evaluator.todo_title,previous: previous)  
    #     end
    #   end
    # end

    # trait :with_todos_and_actions do
    #   version { 5 }
    #   transient do
    #     todo_title_prefix { "Some Task " }
    #   end

    #   after(:create) do |todo_list,evaluator|        
    #     previous = create(:todo,checked: true,todo_list: todo_list,title: "#{evaluator.todo_title_prefix}1",previous: todo_list.nil_todo)
    #     previous = create(:todo,checked: true,todo_list: todo_list,title: "#{evaluator.todo_title_prefix}2",previous: previous)
    #     previous = create(:todo,checked: true,todo_list: todo_list,title: "#{evaluator.todo_title_prefix}3",previous: previous)
    #     create(:todo,checked: false,todo_list: todo_list,title: "#{evaluator.todo_title_prefix}4",previous: previous)
    #     todos = todo_list.todos
    #     create(:todo_action,todo_list: todo_list,todo: todos[0],kind: "check",version: 1)
    #     create(:todo_action,todo_list: todo_list,todo: todos[1],kind: "check",version: 2)
    #     create(:todo_action,todo_list: todo_list,todo: todos[2],kind: "check",version: 3)
    #     create(:todo_action,todo_list: todo_list,todo: todos[1],kind: "uncheck",version: 4)
    #     create(:todo_action,todo_list: todo_list,todo: todos[1],kind: "check",version: 5)
    #   end
    # end
  end
end