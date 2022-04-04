require 'rails_helper'

RSpec.describe TodoList, type: :model do
  subject {
    build(:todo_list)
  }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a title" do
      subject.title = nil
      expect(subject).to_not be_valid
    end    
  end

  describe "Methods" do
    describe "versioned_todos" do
      it "returns the current version and list of todos" do
        title = "My Todo List"
        todo_count = 5
        todo_title = "Some Task"
        list = create(:todo_list,:with_todos,todo_count: todo_count,todo_title: todo_title,version: 4,title: title)
        result = list.versioned_todos
        expect(result).to be_a VersionedTodoList
        expect(result.todo_list_id).to eql(list.id) 
        expect(result.version).to eql(4) 
        expect(result.title).to eql(title) 
        expect(result.todos.length).to eql(todo_count)
        result.todos.each do |todo|
          expect(todo.title).to eql(todo_title) 
        end
      end
    end

    describe "versioned_todos_update" do
      let(:list) { create(:todo_list,:with_todos_and_actions) }

      it "raises an error if old_version is greater than the current version" do
        expect { list.versioned_todos_update 6 }.to raise_error(ArgumentError)
      end

      it "returns the current version and the actions since the provided version" do
        result = list.versioned_todos_update 1        
        expect(result).to be_a VersionedTodoListUpdate

        expected_actions_before = list.actions.version_between_inclusive 2,5
        expect(result.version).to eql(5)
        expect(result.actions_before.length).to eql(expected_actions_before.length)
        result.actions_before.each_with_index do |record,index|
          expect(record.attributes).to eql(expected_actions_before[index].attributes)
        end
      end

      it "applies new_actions and returns the new version and actions since the old_version" do
        todos = list.todos
        expect(todos[0].checked).to eql(true)
        expect(todos[1].checked).to eql(true)
        expect(todos[2].checked).to eql(true)
        expect(todos[3].checked).to eql(false)

        expected_actions_before = list.actions.version_between_inclusive 4,5

        result = list.versioned_todos_update 3,[
          {todo_id: todos[0].id,kind: "uncheck"},
          {todo_id: todos[1].id,kind: "uncheck"},
          {todo_id: todos[2].id,kind: "uncheck"},
          {todo_id: todos[3].id,kind: "check"}
        ]

        expect(result).to be_a VersionedTodoListUpdate
        expect(result.version).to eql(9)

        expect(result.actions_before.length).to eql(expected_actions_before.length)
        result.actions_before.each_with_index do |record,index|
          expect(record.attributes).to eql(expected_actions_before[index].attributes)
        end

        todos = list.todos
        expect(todos[0].checked).to eql(false)
        expect(todos[1].checked).to eql(false)
        expect(todos[2].checked).to eql(false)
        expect(todos[3].checked).to eql(true)
      end

      it "updates the todo_list version, applies new_actions and appropriately creates them in the todo_actions table" do
        todos = list.todos

        list.versioned_todos_update 5,[
          {todo_id: todos[0].id,kind: "uncheck"},
          {todo_id: todos[1].id,kind: "uncheck"},
          {todo_id: todos[2].id,kind: "uncheck"},
          {todo_id: todos[3].id,kind: "check"}
        ]

        created_actions = list.actions.version_between_inclusive 6,9
        expected_actions = [
          build(:todo_action,todo_list: list,version: 6,todo: todos[0],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 7,todo: todos[1],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 8,todo: todos[2],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 9,todo: todos[3],kind: "check")
        ]

        expect(created_actions).to be_critically_equivalent_to(expected_actions)
        expect(list.reload.version).to eql(9)
      end

      it "should ignore new_actions referring to non-existant todo records or having no effect" do
        todos = list.todos

        list.versioned_todos_update 5,[
          {todo_id: todos[0].id,kind: "check"}, # todo record is already checked, action has no effect
          {todo_id: todos[1].id,kind: "uncheck"},
          {todo_id: 100,kind: "uncheck"}, # non-existant todo record
          {todo_id: todos[3].id,kind: "check"}
        ]

        created_actions = list.actions.version_between_inclusive 6,9
        expected_actions = [
          build(:todo_action,todo_list: list,version: 6,todo: todos[1],kind: "uncheck"),
          build(:todo_action,todo_list: list,version: 7,todo: todos[3],kind: "check")
        ]

        expect(created_actions).to be_critically_equivalent_to(expected_actions)
        expect(list.reload.version).to eql(7)        
      end
    end
  end
end
