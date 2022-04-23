# Represents a todo list
# 
# @field [String] title - a textual description of the todo list
# @field [Integer] version - the number of actions that have so far been applied to the todo list
class TodoList < ApplicationRecord
  has_many :actions, foreign_key: "todo_list_id", class_name: "TodoAction", dependent: :destroy
  has_many :_todos, foreign_key: "todo_list_id", class_name: "Todo", dependent: :destroy
  belongs_to :nil_todo, class_name: "Todo",optional: true
  belongs_to :tmp_todo, class_name: "Todo",optional: true
  belongs_to :last_todo, class_name: "Todo",optional: true
  validates_presence_of :title
  before_destroy :clear_all_todos_previous, prepend: true
  after_create :create_nil_and_tmp_todo_and_point_last_todo_to_nil_todo

  def todos_with_deleted
    _todos.where.not(id: self.nil_todo_id).where.not(id: self.tmp_todo_id)
  end

  def todos
    todos_with_deleted.where(deleted: false)
  end

  def first_ordered_todo
    nil_todo.reload.next
  end

  def last_ordered_todo
    last_todo = self.reload.last_todo
    last_todo = nil if last_todo.id==self.nil_todo.id
    last_todo
  end

  def ordered_todos
    todos_by_id = {}
    id_to_next_id = {}
    self.todos.each do |todo|
      todos_by_id[todo.id] = todo
      id_to_next_id[todo.previous_id] = todo.id
    end

    todos = []
    pnt = self.nil_todo_id
    while id_to_next_id.key?(pnt) do
      next_todo = todos_by_id[id_to_next_id[pnt]]
      todos << next_todo
      pnt = next_todo.id
    end

    todos
  end

  def versioned_todos()
    with_lock do
      VersionedTodoList.new self,ordered_todos
    end
  end

  def versioned_todos_update(old_version,new_actions = [])
    uid_count_map = {}
    new_actions.each do |action|
      raise ArgumentError,"invalid action uid - must match ^[a-zA-Z0-9]{12}$" unless action[:uid].is_a?(String) && action[:uid].match(/^[a-zA-Z0-9]{12}$/)
      uid_count_map[action[:uid]]||= 0
      uid_count_map[action[:uid]]+= 1
      raise ArgumentError,"same action uid used more than once - must be unique to each action" unless uid_count_map[action[:uid]]==1
    end

    uid_resolution = {}
    
    resolve_uid = ->(uid) {
      result = uid
      result = uid_resolution[uid] if uid.is_a?(String) && uid.length==12
      result
    }

    ignored_uids = []

    version_before = self.version
    result = with_lock do
      raise ArgumentError,"invalid value for old_version - cannot be greater than current version" if (old_version > self.version)
      actions_before = self.actions.version_between_inclusive old_version+1,self.version
      version_pointer = self.version
      new_actions.each do |_action|
        action = _action.clone
        
        unless TodoAction.find_by(uid: action[:uid]).nil?
          ignored_uids << action[:uid]
          next 
        end

        if action[:kind]!="insert"
          action[:todo_id] = resolve_uid.call action[:todo_id]
          todo = self.todos.find_by(id: action[:todo_id])
          next unless todo
        end
        
        case action[:kind]
        when "check"
          if !todo.checked
            todo.update!(checked: true)
            version_pointer+= 1
            self.actions.create!(todo: todo,version: version_pointer,kind: "check",uid: action[:uid])
          end
        when "uncheck"
          if todo.checked
            todo.update!(checked: false)
            version_pointer+= 1
            self.actions.create!(todo: todo,version: version_pointer,kind: "uncheck",uid: action[:uid])
          end
        when "insert"
          if !action[:title].blank? && action.key?(:previous_id)
            previous_todo = nil
            action[:previous_id] = resolve_uid.call action[:previous_id]
            if action[:previous_id].is_a?(Integer) && action[:previous_id]>0
              previous_todo = self.todos_with_deleted.find_by(id: action[:previous_id])
              if !previous_todo.nil? && previous_todo.deleted
                previous_todo = self.last_ordered_todo
                previous_todo = self.nil_todo if previous_todo.nil?
              end              
            elsif action[:previous_id]==0
              previous_todo = self.nil_todo
            end
            if !previous_todo.nil?
              next_todo = previous_todo.reload.next
              next_todo.update!(previous: self.tmp_todo) if !next_todo.nil?              
              inserted_todo = self.todos.create!(title: action[:title],previous: previous_todo)
              next_todo.update!(previous: inserted_todo) if !next_todo.nil?
              if next_todo.nil?
                self.update!(last_todo_id: inserted_todo.id)
                self.reload
              end

              version_pointer+= 1                            
              if previous_todo.id==self.nil_todo.id
                action_previous_id = nil
              else
                action_previous_id = previous_todo.id
              end
              self.actions.create!(todo: inserted_todo,version: version_pointer,kind: "insert",title: action[:title],previous_id: action_previous_id,uid: action[:uid])
              uid_resolution[action[:uid]] = inserted_todo.id
            end
          end
        when "edit"  
          if !action[:title].blank? && action[:title]!=todo.title
            todo.update!(title: action[:title])
            version_pointer+= 1
            self.actions.create!(todo: todo,version: version_pointer,kind: "edit",title: action[:title],uid: action[:uid])
          end
        when "delete"
          next_todo = todo.reload.next
          todo_previous_id = todo.previous_id
          todo.update!(deleted: true,previous_id: nil)
          todo.reload
          next_todo.update!(previous_id: todo_previous_id) if !next_todo.nil?          
          if next_todo.nil?
            self.update!(last_todo_id: todo_previous_id)
            self.reload
          end
          version_pointer+= 1
          self.actions.create!(todo: todo,version: version_pointer,kind: "delete",uid: action[:uid])
        when "move"
          if action.key?(:previous_id)
            previous_todo = nil
            action[:previous_id] = resolve_uid.call action[:previous_id]
            if action[:previous_id].is_a?(Integer) && action[:previous_id]>0
              previous_todo = self.todos_with_deleted.find_by(id: action[:previous_id])
              if !previous_todo.nil? && previous_todo.deleted
                previous_todo = self.last_ordered_todo 
                previous_todo = self.nil_todo if previous_todo.nil?
              end              
            elsif action[:previous_id]==0
              previous_todo = self.nil_todo
            end
            if !previous_todo.nil? && previous_todo.id!=todo.id
              current_previous_todo = todo.previous
              current_next_todo = todo.next
              todo.update!(previous: self.tmp_todo)
              todo.reload
              current_next_todo.update!(previous: current_previous_todo) if !current_next_todo.nil? 
              if current_next_todo.nil? 
                self.update!(last_todo_id: current_previous_todo.id)
                self.reload
              end

              next_todo = previous_todo.next
              next_todo.update!(previous: todo) if !next_todo.nil?
              if next_todo.nil?
                self.update!(last_todo_id: todo.id)
                self.reload
              end
              todo.update!(previous: previous_todo)              

              version_pointer+= 1                            
              if previous_todo.id==self.nil_todo.id
                action_previous_id = nil
              else
                action_previous_id = previous_todo.id
              end
              self.actions.create!(todo: todo,version: version_pointer,kind: "move",previous_id: action_previous_id,uid: action[:uid])
            end
          end
        end
      end      
      if version_pointer > self.version
        self.version = version_pointer
        self.save!
      end
      result = VersionedTodoListUpdate.new self,actions_before.load,uid_resolution,ignored_uids
    end
    ActionCable.server.broadcast("todo_list_#{self.id}", {"version" => self.version}) if self.version > version_before
    result
  end  

  private

  def clear_all_todos_previous
    todos.update_all(previous_id: nil)
  end

  def create_nil_and_tmp_todo_and_point_last_todo_to_nil_todo
    self.nil_todo_id = Todo.create!(title: "nil_todo",todo_list: self).id
    self.tmp_todo_id = Todo.create!(title: "tmp_todo",todo_list: self).id
    self.last_todo_id = self.nil_todo_id
    self.save!
  end
end