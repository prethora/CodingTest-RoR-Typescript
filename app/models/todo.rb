# Represents a single todo item
# 
# @field [String] title - a description of the todo task
# @field [Boolean] checked - whether or not the task has been completed
# @field [Integer] todo_list_id - the todo list this todo task belongs to
class Todo < ApplicationRecord
  belongs_to :todo_list, required: true
  belongs_to :previous, class_name: "Todo",optional: true
  has_one :next, class_name: "Todo", foreign_key: "previous_id"
  validates_presence_of :title
  validate :previous_doesnt_refer_to_a_todo_from_another_todo_list

  private

  def previous_doesnt_refer_to_a_todo_from_another_todo_list
    return if todo_list.nil?
    if !previous.nil? && !previous.todo_list.nil? && previous.todo_list.id!=todo_list.id
      errors.add(:previous_id,"refers to a todo from another todo_list");
    end
  end
end
