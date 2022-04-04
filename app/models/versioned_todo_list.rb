# Models the return value of the TodoList#versioned_todos method
class VersionedTodoList
  include ActiveModel::Serialization
  attr_reader :todo_list_id,:version,:title,:todos

  def initialize(todo_list,todos)
    @todo_list_id = todo_list.id
    @version = todo_list.version
    @title = todo_list.title
    @todos = todos
  end

  def self.model_name
    :versioned_todo_list
  end

  def self.get(id)
    TodoList.find(id).versioned_todos()
  end

  def self.update(id,input)
    TodoList.find(id).versioned_todos_update(input[:old_version],input[:new_actions])
  end
end