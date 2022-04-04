class TodoListChannel < ApplicationCable::Channel
  def subscribed
    stream_from "todo_list_#{params[:id]}"
    todo_list = TodoList.find_by(id: params[:id])
    ActionCable.server.broadcast("todo_list_#{todo_list.id}", {"version" => todo_list.version}) if todo_list
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
