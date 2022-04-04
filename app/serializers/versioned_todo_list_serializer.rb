class VersionedTodoListSerializer < ActiveModel::Serializer
  attributes :todo_list_id,:version,:title,:todos
  has_many :todos, serializer: TodoSerializer
end
