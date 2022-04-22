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
  belongs_to :previous, class_name: "Todo",optional: true
  scope :version_between_inclusive, lambda {|from_version, to_version| where("version >= ? AND version <= ?", from_version, to_version ).order(:version) }
  enum kind: { check: "check", uncheck: "uncheck", insert: "insert", delete: "delete", edit: "edit", move: "move" }, _suffix: :kind
  validates_presence_of :kind
  validates_presence_of :version
  validate :todo_isnt_from_another_todo_list
  validate :title_is_set_for_and_only_for_insert_and_edit_kinds
  validate :previous_id_refers_to_an_existing_todo_of_the_same_list_other_than_self_todo_if_set_and_is_only_ever_set_for_insert_and_move_kinds
  CRITICAL_FIELDS = ["todo_list_id","version","todo_id","kind","title","previous_id"]

  @generate_uid_tab = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  @generate_uid_len = 12

  def self.generate_uid
    @generate_uid_len.times.map { @generate_uid_tab[Random.rand(@generate_uid_tab.length)] }.join
  end

  def critical_attributes
    attributes.select { |key,v| CRITICAL_FIELDS.include?(key) }
  end

  private

  def todo_isnt_from_another_todo_list
    return if todo.nil? || todo_list.nil?
    if !todo.todo_list.nil? && todo_list.id!=todo.todo_list.id
      errors.add(:todo_id, "cannot refer to a todo from another todo_list")
    end
  end

  def title_is_set_for_and_only_for_insert_and_edit_kinds
    if (insert_kind? || edit_kind?) && title.blank?
      errors.add(:title, "must be set for a todo_action of kind 'insert' or 'edit'")
    end
    if (!insert_kind? && !edit_kind?) && !title.nil?
      errors.add(:title, "must not be set for a todo_action that is not of kind 'insert' or 'edit'")
    end
  end

  def previous_id_refers_to_an_existing_todo_of_the_same_list_other_than_self_todo_if_set_and_is_only_ever_set_for_insert_and_move_kinds
    return if todo.nil? || todo_list.nil?
    if !previous_id.nil?
      if (!insert_kind? && !move_kind?)
        errors.add(:previous_id, "can only be set for a todo_action of kind 'insert' or 'move'")
      elsif previous.nil?
        errors.add(:previous_id,"refers to a non-existant todo");
      elsif previous.id==todo.id
        errors.add(:previous_id,"cannot refer to self.todo");
      elsif previous.todo_list.id!=todo_list.id
        errors.add(:previous_id,"refers to a todo that is not owned by the same todo_list");
      end
    end
  end
end