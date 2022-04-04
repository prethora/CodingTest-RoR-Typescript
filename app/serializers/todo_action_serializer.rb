class TodoActionSerializer < ActiveModel::Serializer
  attributes :todo_id, :version, :kind
end
