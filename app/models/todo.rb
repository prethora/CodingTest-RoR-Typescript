# Represents a single todo item
# 
# @field [String] title - a description of the todo task
# @field [Boolean] checked - whether or not the task has been completed
# @field [Integer] todo_list_id - the todo list this todo task belongs to
class Todo < ApplicationRecord
  belongs_to :todo_list
  validates_presence_of :title  
end
