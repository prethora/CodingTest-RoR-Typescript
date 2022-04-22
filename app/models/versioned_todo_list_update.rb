# Models the return value of the TodoList#versioned_todos_update method
class VersionedTodoListUpdate
  include ActiveModel::Serialization
  attr_reader :todo_list_id,:version,:actions_before,:uid_resolution

  def initialize(todo_list,actions_before,uid_resolution)
    @todo_list_id = todo_list.id
    @version = todo_list.version
    @actions_before = actions_before
    @uid_resolution = uid_resolution;
  end

  def self.model_name
    :versioned_todo_list_update
  end
end