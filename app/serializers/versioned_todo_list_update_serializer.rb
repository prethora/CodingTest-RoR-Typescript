class VersionedTodoListUpdateSerializer < ActiveModel::Serializer
  attributes :todo_list_id,:version,:actions_before
  has_many :actions_before, serializer: TodoActionSerializer
end