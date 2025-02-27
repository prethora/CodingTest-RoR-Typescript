class VersionedTodoListUpdateSerializer < ActiveModel::Serializer
  attributes :todo_list_id,:version,:actions_before,:uid_resolution,:ignored_uids
  has_many :actions_before, serializer: TodoActionSerializer
end