require 'rails_helper'

RSpec.describe TodoList, type: :model do
  let(:inexistant_todo_id) { 10000000001 }

  subject {
    build(:todo_list)
  }

  def add_uids(actions)
    actions.map { |action| action[:uid] = TodoAction.generate_uid; action }
  end

  describe "Factory" do
    it "works as expected" do
      todo_count = 5
      title = "some list"
      todo_title_prefix = "title_"
      todo_checked_indexes = [2,4]
      todo_list = create(:todo_list,todo_count: todo_count,title: title,todo_title_prefix: todo_title_prefix,todo_checked_indexes: todo_checked_indexes)
      result = todo_list.versioned_todos
      expect(result).to be_a VersionedTodoList
      expect(result.todo_list_id).to eql(todo_list.id) 
      expect(result.version).to eql(todo_count+todo_checked_indexes.length) 
      expect(result.title).to eql(title) 
      todos = result.todos 
      expect(todos.length).to eql(todo_count)
      todo_count.times do |index|        
        expect(todos[index].title).to eql("title_#{index}")
        expect(todos[index].checked).to eql(todo_checked_indexes.include?(index))
      end
      expect(todo_list.last_todo_id).to eql(todos[todo_count-1].id)

      created_actions = todo_list.actions.version_between_inclusive 1,todo_count+todo_checked_indexes.length
      expected_actions = []
      previous_id = nil
      version = 0
      todo_count.times do |index|
        version+= 1
        expected_actions << build(:todo_action,todo_list: todo_list,version: version,todo: todos[index],kind: "insert",title: "title_#{index}",previous_id: previous_id)
        if todo_checked_indexes.include? index
          version+= 1
          expected_actions << build(:todo_action,todo_list: todo_list,version: version,todo: todos[index],kind: "check")  
        end
        previous_id = todos[index].id
      end

      expect(created_actions).to be_critically_equivalent_to(expected_actions)
      expect(todo_list.version).to eql(todo_count+todo_checked_indexes.length)
    end
  end

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a title" do
      subject.title = nil
      expect(subject).to_not be_valid
    end    
  end

  describe "Associations" do
    it "creates and refers to a nil_todo and tmp_todo, and points last_todo to nil_todo" do
      subject.save!
      expect(subject.nil_todo).to_not be_nil
      expect(subject.nil_todo.todo_list.id).to eql(subject.id)
      expect(subject.tmp_todo).to_not be_nil
      expect(subject.tmp_todo.todo_list.id).to eql(subject.id)
      expect(subject.last_todo).to_not be_nil
      expect(subject.last_todo.id).to eql(subject.nil_todo.id)
    end

    it "deletes dependent todos and actions on todo_list deletion" do
      list = create(:todo_list,version: 3)
      nil_todo = list.nil_todo
      tmp_todo = list.tmp_todo
      todos = [
        todo0=create(:todo,todo_list: list,checked: true),
        todo1=create(:todo,todo_list: list,checked: true,previous: todo0),
        create(:todo,todo_list: list,checked: true,previous: todo1)
      ]
      actions = [
        create(:todo_action,todo_list: list,todo: todos[0],kind: "check",version: 1),
        create(:todo_action,todo_list: list,todo: todos[1],kind: "check",version: 2),
        create(:todo_action,todo_list: list,todo: todos[2],kind: "check",version: 3)
      ]
      list.destroy
      
      expect(nil_todo.destroyed?)
      expect(tmp_todo.destroyed?)

      todos.each do |todo|
        expect(todo.destroyed?)
      end

      actions.each do |action|
        expect(action.destroyed?)
      end      
    end
  end

  describe "Methods" do
    describe "first_ordered_todo" do
      it "returns the first ordered todo if it exists, or nil if it does not" do
        subject.save!
        expect(subject.first_ordered_todo).to be_nil
        first_todo = create(:todo,todo_list: subject,previous: subject.nil_todo)
        expect(subject.first_ordered_todo).to_not be_nil
        expect(subject.first_ordered_todo.id).to eql(first_todo.id)
      end
    end

    describe "last_ordered_todo" do
      it "returns the last ordered todo if it exists, or nil if it does not" do
        subject.save!
        expect(subject.last_ordered_todo).to be_nil
        subject.versioned_todos_update subject.version,add_uids([
          {kind: "insert",title: "first todo",previous_id: 0}
        ])        
        first_todo = subject.versioned_todos.todos[0]
        expect(subject.last_ordered_todo).to_not be_nil
        expect(subject.last_ordered_todo.id).to eql(first_todo.id)
        subject.versioned_todos_update subject.version,add_uids([
          {kind: "insert",title: "next todo",previous_id: first_todo.id}
        ])        
        next_todo = subject.versioned_todos.todos[1]
        expect(subject.last_ordered_todo).to_not be_nil
        expect(subject.last_ordered_todo.id).to eql(next_todo.id)
      end
    end    

    describe "versioned_todos" do
      it "returns the current version and list of ordered todos" do
        title = "My Todo List"
        todo_count = 5
        todo_title = "Some Task"
        version = 4
        todo_list = create(:todo_list,version: version,title: title)
        previous = todo_list.nil_todo
        todo_count.times do |index|
          previous = create(:todo,todo_list: todo_list,title: "title_#{index}",previous: previous)
        end
        result = todo_list.versioned_todos
        expect(result).to be_a VersionedTodoList
        expect(result.todo_list_id).to eql(todo_list.id) 
        expect(result.version).to eql(version) 
        expect(result.title).to eql(title) 
        todos = result.todos 
        expect(todos.length).to eql(todo_count)
        expect(todos[0].title).to eql("title_0")
        expect(todos[1].title).to eql("title_1")                
        expect(todos[2].title).to eql("title_2") 
        expect(todos[3].title).to eql("title_3")          
        expect(todos[4].title).to eql("title_4")

        def connect(todos,from,to)
          todos[from].previous = todos[from].todo_list.tmp_todo if to==-2
          todos[from].previous = todos[from].todo_list.nil_todo if to==-1
          todos[from].previous = todos[to] if to>=0
          todos[from].save!
        end

        connect(todos,0,-2)
        connect(todos,4,-1)
        connect(todos,0,3)
        connect(todos,1,-2)
        connect(todos,3,4)
        connect(todos,1,2)
        connect(todos,0,-2)
        connect(todos,2,3)
        connect(todos,0,1)

        result = todo_list.versioned_todos
        todos = result.todos 
        expect(todos.length).to eql(todo_count)
        expect(todos[0].title).to eql("title_4")
        expect(todos[1].title).to eql("title_3")                
        expect(todos[2].title).to eql("title_2") 
        expect(todos[3].title).to eql("title_1")          
        expect(todos[4].title).to eql("title_0")
      end
    end

    describe "versioned_todos_update" do
      let(:list) { create(:todo_list,todo_title_prefix: "Some Task ",todo_count: 4,todo_checked_indexes: [0,1,2]) }

      it "raises an error if old_version is greater than the current version" do
        expect { list.versioned_todos_update 8 }.to raise_error(ArgumentError)
      end

      it "raises an error if at least one action does not have a valid uid" do
        todos = list.versioned_todos.todos        
        expect { list.versioned_todos_update 1,[{todo_id: todos[0].id,kind: "uncheck",uid: "psxEVpAl4Vh9"},{todo_id: todos[0].id,kind: "uncheck"}] }.to raise_error(ArgumentError)
      end

      it "raises an error if more than one action has the same uid" do
        todos = list.versioned_todos.todos
        expect { list.versioned_todos_update 1,[{todo_id: todos[0].id,kind: "uncheck",uid: "psxEVpAl4Vh9"},{todo_id: todos[0].id,kind: "uncheck",uid: "psxEVpAl4Vh9"}] }.to raise_error(ArgumentError)
      end

      it "returns the current version and the actions since the provided version" do
        result = list.versioned_todos_update 1        
        expect(result).to be_a VersionedTodoListUpdate

        expected_actions_before = list.actions.version_between_inclusive 2,7
        expect(result.version).to eql(7)
        expect(result.actions_before.length).to eql(expected_actions_before.length)
        result.actions_before.each_with_index do |record,index|
          expect(record.attributes).to eql(expected_actions_before[index].attributes)
        end
      end

      it "applies new_actions (of kind 'check' and 'uncheck'), creates the appropriate todo_actions, updates the version, and returns the new version and actions since the old_version" do
        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].checked).to eql(true)
        expect(todos[1].checked).to eql(true)
        expect(todos[2].checked).to eql(true)
        expect(todos[3].checked).to eql(false)

        expected_actions_before = list.actions.version_between_inclusive 4,7

        result = list.versioned_todos_update 3,add_uids([
          {todo_id: todos[0].id,kind: "uncheck"},
          {todo_id: todos[1].id,kind: "uncheck"},
          {todo_id: todos[2].id,kind: "uncheck"},
          {todo_id: todos[3].id,kind: "check"}
        ])

        expect(result).to be_a VersionedTodoListUpdate
        expect(result.version).to eql(11)

        expect(result.actions_before.length).to eql(expected_actions_before.length)
        result.actions_before.each_with_index do |record,index|
          expect(record.attributes).to eql(expected_actions_before[index].attributes)
        end

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].checked).to eql(false)
        expect(todos[1].checked).to eql(false)
        expect(todos[2].checked).to eql(false)
        expect(todos[3].checked).to eql(true)

        created_actions = list.actions.version_between_inclusive 8,11
        expected_actions = [
          build(:todo_action,todo_list: list,version: 8,todo: todos[0],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 9,todo: todos[1],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 10,todo: todos[2],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 11,todo: todos[3],kind: "check")
        ]

        expect(created_actions).to be_critically_equivalent_to(expected_actions)
        expect(list.reload.version).to eql(11)
      end

      it "applies new_actions (of kind 'insert'), creates the appropriate todo_actions, updates the version, and returns the new version" do
        deleted_todo = list.todos.create!(title: "deleted item",deleted: true)

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].title).to eql("Some Task 0")
        expect(todos[1].title).to eql("Some Task 1")
        expect(todos[2].title).to eql("Some Task 2")
        expect(todos[3].title).to eql("Some Task 3")

        result = list.versioned_todos_update 7,add_uids([
          {kind: "insert",title: "inserted title 1",previous_id: todos[3].id},
          {kind: "insert",title: "inserted title 2",previous_id: todos[1].id},
          {kind: "insert",title: "inserted title 3",previous_id: 0},
          {kind: "insert",title: "inserted title 4",previous_id: deleted_todo.id}
        ])

        expect(result).to be_a VersionedTodoListUpdate
        expect(result.version).to eql(11)

        expect(result.actions_before.length).to eql(0)

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(8)
        expect(todos[0].title).to eql("inserted title 3")
        expect(todos[1].title).to eql("Some Task 0")
        expect(todos[2].title).to eql("Some Task 1")
        expect(todos[3].title).to eql("inserted title 2")
        expect(todos[4].title).to eql("Some Task 2")
        expect(todos[5].title).to eql("Some Task 3")
        expect(todos[6].title).to eql("inserted title 1")
        expect(todos[7].title).to eql("inserted title 4")

        expect(list.last_todo.id).to eql(todos[7].id)

        created_actions = list.actions.version_between_inclusive 8,11
        expected_actions = [
          build(:todo_action,todo_list: list,version: 8,todo: todos[6],kind: "insert",title: "inserted title 1",previous: todos[5]),
          build(:todo_action,todo_list: list,version: 9,todo: todos[3],kind: "insert",title: "inserted title 2",previous: todos[2]),
          build(:todo_action,todo_list: list,version: 10,todo: todos[0],kind: "insert",title: "inserted title 3"),
          build(:todo_action,todo_list: list,version: 11,todo: todos[7],kind: "insert",title: "inserted title 4",previous: todos[6])
        ]

        expect(created_actions).to be_critically_equivalent_to(expected_actions)
        expect(list.reload.version).to eql(11)
      end

      it "applies new_actions (of kind 'edit'), creates the appropriate todo_actions, updates the version, and returns the new version" do
        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].title).to eql("Some Task 0")
        expect(todos[1].title).to eql("Some Task 1")
        expect(todos[2].title).to eql("Some Task 2")
        expect(todos[3].title).to eql("Some Task 3")

        result = list.versioned_todos_update 7,add_uids([
          {todo_id: todos[3].id,kind: "edit",title: "edited title 1"},
          {todo_id: todos[2].id,kind: "edit",title: "edited title 2"},
          {todo_id: todos[1].id,kind: "edit",title: "edited title 3"},
          {todo_id: todos[0].id,kind: "edit",title: "edited title 4"}
        ])

        expect(result).to be_a VersionedTodoListUpdate
        expect(result.version).to eql(11)

        expect(result.actions_before.length).to eql(0)

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].title).to eql("edited title 4")
        expect(todos[1].title).to eql("edited title 3")
        expect(todos[2].title).to eql("edited title 2")
        expect(todos[3].title).to eql("edited title 1")

        created_actions = list.actions.version_between_inclusive 8,11
        expected_actions = [
          build(:todo_action,todo_list: list,version: 8,todo: todos[3],kind: "edit",title: "edited title 1"),
          build(:todo_action,todo_list: list,version: 9,todo: todos[2],kind: "edit",title: "edited title 2"),
          build(:todo_action,todo_list: list,version: 10,todo: todos[1],kind: "edit",title: "edited title 3"),
          build(:todo_action,todo_list: list,version: 11,todo: todos[0],kind: "edit",title: "edited title 4")
        ]

        expect(created_actions).to be_critically_equivalent_to(expected_actions)
        expect(list.reload.version).to eql(11)
      end

      it "applies new_actions (of kind 'delete'), creates the appropriate todo_actions, updates the version, and returns the new version" do
        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)

        result = list.versioned_todos_update 7,add_uids([
          {todo_id: todos[3].id,kind: "delete"},
          {todo_id: todos[1].id,kind: "delete"}
        ])

        original_todos = todos

        expect(result).to be_a VersionedTodoListUpdate
        expect(result.version).to eql(9)

        expect(result.actions_before.length).to eql(0)

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(2)
        expect(todos[0].id).to eql(original_todos[0].id)
        expect(todos[1].id).to eql(original_todos[2].id)

        expect(list.last_todo.id).to eql(original_todos[2].id)

        created_actions = list.actions.version_between_inclusive 8,9
        expected_actions = [
          build(:todo_action,todo_list: list,version: 8,todo: original_todos[3],kind: "delete"),
          build(:todo_action,todo_list: list,version: 9,todo: original_todos[1],kind: "delete")
        ]

        expect(created_actions).to be_critically_equivalent_to(expected_actions)
        expect(list.reload.version).to eql(9)
      end

      it "applies new_actions (of kind 'move'), creates the appropriate todo_actions, updates the version, and returns the new version" do
        deleted_todo = list.todos.create!(title: "deleted item",deleted: true)

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].title).to eql("Some Task 0")
        expect(todos[1].title).to eql("Some Task 1")
        expect(todos[2].title).to eql("Some Task 2")
        expect(todos[3].title).to eql("Some Task 3")                

        result = list.versioned_todos_update 7,add_uids([
          {todo_id: todos[3].id,kind: "move",previous_id: 0},
          {todo_id: todos[2].id,kind: "move",previous_id: todos[3].id},
          {todo_id: todos[0].id,kind: "move",previous_id: deleted_todo.id},
        ])

        original_todos = todos

        expect(result).to be_a VersionedTodoListUpdate
        expect(result.version).to eql(10)

        expect(result.actions_before.length).to eql(0)

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].title).to eql("Some Task 3")
        expect(todos[1].title).to eql("Some Task 2")        
        expect(todos[2].title).to eql("Some Task 1")
        expect(todos[3].title).to eql("Some Task 0")

        expect(list.last_todo.id).to eql(todos[3].id)

        created_actions = list.actions.version_between_inclusive 8,10
        expected_actions = [
          build(:todo_action,todo_list: list,version: 8,todo: original_todos[3],kind: "move",previous: nil),
          build(:todo_action,todo_list: list,version: 9,todo: original_todos[2],kind: "move",previous: original_todos[3]),
          build(:todo_action,todo_list: list,version: 10,todo: original_todos[0],kind: "move",previous: original_todos[1])
        ]

        expect(created_actions).to be_critically_equivalent_to(expected_actions)
        expect(list.reload.version).to eql(10)
      end

      it "recognizes the uid of a previous action of kind 'insert' as a valid value for the todo_id or previous_id of a subsequent action, and returns a hash of uid to id for all inserted todos as the uid_resolution field of the result" do
        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].title).to eql("Some Task 0")
        expect(todos[1].title).to eql("Some Task 1")
        expect(todos[2].title).to eql("Some Task 2")
        expect(todos[3].title).to eql("Some Task 3")                

        result = list.versioned_todos_update 7,[
          {kind: "insert",title: "inserted title 1",previous_id: todos[3].id,uid: uid1=TodoAction.generate_uid},
          {kind: "insert",title: "inserted title 2",previous_id: uid1,uid: uid2=TodoAction.generate_uid},
          {kind: "insert",title: "inserted title 3",previous_id: uid2,uid: uid3=TodoAction.generate_uid},
          {todo_id: uid2,kind: "check",uid: TodoAction.generate_uid},
          {todo_id: uid3,kind: "edit",title: "edited title 3",uid: TodoAction.generate_uid},
          {todo_id: uid1,kind: "delete",uid: TodoAction.generate_uid},
          {todo_id: todos[0].id,kind: "move",previous_id: uid3,uid: TodoAction.generate_uid}
        ]

        expect(result).to be_a VersionedTodoListUpdate
        expect(result.version).to eql(14)

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(6)        
        i=0;   expect({title: todos[i].title,checked: todos[i].checked}).to eql({title: "Some Task 1",checked: true})
        i+= 1; expect({title: todos[i].title,checked: todos[i].checked}).to eql({title: "Some Task 2",checked: true})
        i+= 1; expect({title: todos[i].title,checked: todos[i].checked}).to eql({title: "Some Task 3",checked: false})
        i+= 1; expect({title: todos[i].title,checked: todos[i].checked}).to eql({title: "inserted title 2",checked: true})
        i+= 1; expect({title: todos[i].title,checked: todos[i].checked}).to eql({title: "edited title 3",checked: false})
        i+= 1; expect({title: todos[i].title,checked: todos[i].checked}).to eql({title: "Some Task 0",checked: true})

        expect(list.last_todo.id).to eql(todos[i].id)
        expect(result.uid_resolution).to eql({uid1 => todos[3].id-1,uid2 => todos[3].id,uid3 => todos[4].id})
      end

      it "ignores an action if its uid belongs to an existing action" do
        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].checked).to eql(true)
        expect(todos[1].checked).to eql(true)
        expect(todos[2].checked).to eql(true)
        expect(todos[3].checked).to eql(false)

        result = list.versioned_todos_update 7,[
          {todo_id: todos[0].id,kind: "uncheck",uid: uid=TodoAction.generate_uid},
          {todo_id: todos[1].id,kind: "uncheck",uid: TodoAction.generate_uid}
        ]

        expect(result.version).to eql(9)

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].checked).to eql(false)
        expect(todos[1].checked).to eql(false)
        expect(todos[2].checked).to eql(true)
        expect(todos[3].checked).to eql(false)

        result = list.versioned_todos_update 9,[
          {todo_id: todos[2].id,kind: "uncheck",uid: uid},
          {todo_id: todos[3].id,kind: "check",uid: TodoAction.generate_uid}
        ]

        expect(result.version).to eql(10)

        todos = list.versioned_todos.todos
        expect(todos.length).to eql(4)
        expect(todos[0].checked).to eql(false)
        expect(todos[1].checked).to eql(false)
        expect(todos[2].checked).to eql(true)
        expect(todos[3].checked).to eql(true)
      end

      it "updates the todo_list version, applies new_actions and appropriately creates them in the todo_actions table" do
        todos = list.versioned_todos.todos

        list.versioned_todos_update 7,add_uids([
          {todo_id: todos[0].id,kind: "uncheck"},
          {todo_id: todos[1].id,kind: "uncheck"},
          {todo_id: todos[2].id,kind: "uncheck"},
          {todo_id: todos[3].id,kind: "check"}
        ])

        created_actions = list.actions.version_between_inclusive 8,11
        expected_actions = [
          build(:todo_action,todo_list: list,version: 8,todo: todos[0],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 9,todo: todos[1],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 10,todo: todos[2],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 11,todo: todos[3],kind: "check")
        ]

        expect(created_actions).to be_critically_equivalent_to(expected_actions)
        expect(list.reload.version).to eql(11)
      end

      it "should ignore new_actions referring to non-existant todo records, that are invalid, or that have no effect" do
        todos = list.todos

        list.versioned_todos_update 7,add_uids([
          {todo_id: todos[0].id,kind: "check"}, # todo record is already checked, action has no effect
          {todo_id: todos[1].id,kind: "uncheck"},
          {todo_id: inexistant_todo_id,kind: "uncheck"}, # non-existant todo record
          {todo_id: todos[3].id,kind: "check"},
          {kind: "insert"}, # invalid action of kind 'insert'; no title set
          {kind: "insert",title: "some title"}, # invalid action of kind 'insert'; no previous_id set
          {kind: "insert",title: "some title", previous_id: inexistant_todo_id}, # invalid action of kind 'insert'; previous_id refers to non-existant todo
          {todo_id: todos[3].id, kind: "move", previous_id: todos[3].id} # moving a todo after itself, no effect
        ])

        created_actions = list.actions.version_between_inclusive 8,11
        expected_actions = [
          build(:todo_action,todo_list: list,version: 8,todo: todos[1],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 9,todo: todos[3],kind: "check")
        ]

        expect(created_actions).to be_critically_equivalent_to(expected_actions)
        expect(list.reload.version).to eql(9)
      end

      describe "Edge cases" do
        it "inserts properly into an empty list with previous_id referring to a deleted todo" do          
          todos = list.versioned_todos.todos
          expect(todos.length).to eql(4)
          expect(todos[0].title).to eql("Some Task 0")
          expect(todos[1].title).to eql("Some Task 1")
          expect(todos[2].title).to eql("Some Task 2")
          expect(todos[3].title).to eql("Some Task 3")
  
          result = list.versioned_todos_update 7,add_uids([
            {todo_id: todos[0].id,kind: "delete"},
            {todo_id: todos[1].id,kind: "delete"},
            {todo_id: todos[2].id,kind: "delete"},
            {todo_id: todos[3].id,kind: "delete"}
          ])

          original_todos = todos
  
          expect(result).to be_a VersionedTodoListUpdate
          expect(result.version).to eql(11)
  
          expect(result.actions_before.length).to eql(0)
  
          todos = list.versioned_todos.todos
          expect(todos.length).to eql(0)

          result = list.versioned_todos_update 11,add_uids([
            {kind: "insert",title: "inserted title", previous_id: original_todos[0].id}
          ])

          expect(result).to be_a VersionedTodoListUpdate
          expect(result.version).to eql(12)

          expect(result.actions_before.length).to eql(0)

          todos = list.versioned_todos.todos
          expect(todos.length).to eql(1)
          expect(todos[0].title).to eql("inserted title")

          created_actions = list.actions.version_between_inclusive 8,12
          expected_actions = [
            build(:todo_action,todo_list: list,version: 8,todo: original_todos[0],kind: "delete"),
            build(:todo_action,todo_list: list,version: 9,todo: original_todos[1],kind: "delete"),
            build(:todo_action,todo_list: list,version: 10,todo: original_todos[2],kind: "delete"),
            build(:todo_action,todo_list: list,version: 11,todo: original_todos[3],kind: "delete"),
            build(:todo_action,todo_list: list,version: 12,todo: todos[0],kind: "insert",title: "inserted title")
          ]
  
          expect(created_actions).to be_critically_equivalent_to(expected_actions)
          expect(list.reload.version).to eql(12)
        end

        it "does nothing in response to a move action with a previous_id referring to a deleted todo when the todo to move is already last in the ordered list" do          
          deleted_todo = list.todos.create!(title: "deleted item",deleted: true)

          todos = list.versioned_todos.todos
          expect(todos.length).to eql(4)
          expect(todos[0].title).to eql("Some Task 0")
          expect(todos[1].title).to eql("Some Task 1")
          expect(todos[2].title).to eql("Some Task 2")
          expect(todos[3].title).to eql("Some Task 3")
  
          result = list.versioned_todos_update 7,add_uids([
            {todo_id: todos[3].id,kind: "move",previous_id: deleted_todo.id},
          ])
    
          expect(result).to be_a VersionedTodoListUpdate
          expect(result.version).to eql(7)
  
          expect(result.actions_before.length).to eql(0)
  
          todos = list.versioned_todos.todos
          expect(todos.length).to eql(4)
          expect(todos[0].title).to eql("Some Task 0")
          expect(todos[1].title).to eql("Some Task 1")
          expect(todos[2].title).to eql("Some Task 2")
          expect(todos[3].title).to eql("Some Task 3")
        end
      end
    end
  end
end
