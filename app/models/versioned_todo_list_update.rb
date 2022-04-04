# Models the return value of the TodoList#versioned_todos_update method
class VersionedTodoListUpdate
  include ActiveModel::Serialization
  attr_reader :todo_list_id,:version,:actions_before

  def initialize(todo_list,actions_before)
    @todo_list_id = todo_list.id
    @version = todo_list.version
    @actions_before = actions_before
  end

  def self.model_name
    :versioned_todo_list_update
  end
end