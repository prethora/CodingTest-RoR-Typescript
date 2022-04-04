# Represents a todo list
# 
# @field [String] title - a textual description of the todo list
# @field [Integer] version - the number of actions that have so far been applied to the todo list
class TodoList < ApplicationRecord
  has_many :todos
  has_many :actions, foreign_key: "todo_list_id", class_name: "TodoAction"
  validates_presence_of :title

  def versioned_todos()
    with_lock do
      VersionedTodoList.new self,self.todos.order(:id).load
    end      
  end

  def versioned_todos_update(old_version,new_actions = [])
    version_before = self.version
    result = with_lock do
      raise ArgumentError,"invalid value for old_version - cannot be greater than current version" if (old_version > self.version)
      actions_before = self.actions.version_between_inclusive old_version+1,self.version
      version_pointer = self.version
      new_actions.each do |action|
        todo = self.todos.find_by(id: action[:todo_id])
        next unless todo
        
        case action[:kind]
        when "check"
          if !todo.checked
            version_pointer+= 1
            self.actions.create!(todo: todo,version: version_pointer,kind: "check")
            todo.checked = true
            todo.save!
          end
        when "uncheck"
          if todo.checked
            version_pointer+= 1
            self.actions.create!(todo: todo,version: version_pointer,kind: "uncheck")
            todo.checked = false
            todo.save!
          end
        end
      end      
      if version_pointer > self.version
        self.version = version_pointer
        self.save!
      end
      result = VersionedTodoListUpdate.new self,actions_before.load
    end
    ActionCable.server.broadcast("todo_list_#{self.id}", {"version" => self.version}) if self.version > version_before
    result
  end  
end