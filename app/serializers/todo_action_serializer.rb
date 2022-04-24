class TodoActionSerializer < ActiveModel::Serializer
  attributes :todo_id, :version, :kind, :title, :previous_id
end
