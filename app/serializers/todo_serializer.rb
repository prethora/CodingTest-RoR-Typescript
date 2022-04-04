class TodoSerializer < ActiveModel::Serializer
  attributes :id, :title, :checked
end
