# Represents a change to a single todo item
# 
# @field [Integer] todo_list_id - the todo list this todo action belongs to
# @field [String] title - a textual description of the todo list
# @field [Integer] version - the version the todo list was moved to as a result of applying this action
# @field [Integer] todo_id - the todo item this change was applied to
# @field [String:"check" | "uncheck"] kind - the kind of action that was applied
class TodoAction < ApplicationRecord
  belongs_to :todo_list
  belongs_to :todo
  scope :version_between_inclusive, lambda {|from_version, to_version| where("version >= ? AND version <= ?", from_version, to_version ).order(:version) }
  enum kind: { check: "check", uncheck: "uncheck" }, _suffix: :kind
  validates_presence_of :kind
  validates_presence_of :version
  CRITICAL_FIELDS = ["todo_list_id","version","todo_id","kind"]

  def critical_attributes
    attributes.select { |key,v| CRITICAL_FIELDS.include?(key) }
  end
end
