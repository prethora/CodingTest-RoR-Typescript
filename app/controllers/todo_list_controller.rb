# frozen_string_literal: true

class TodoListController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:update]  # disabled for now

  def index  
    versioned_todo_list = VersionedTodoList.get(1)
    respond_to do |format|
      format.html { @todo_list = versioned_todo_list }
      format.json { render json: versioned_todo_list }
    end
  end

  def update
    input_schema = {
      "type" => "object",
      "required" => ["old_version","new_actions"],
      "properties" => {
        "old_version" => {"type" => "integer"},
        "new_actions" => {
          "type" => "array",
          "items" => {
            "type" => "object",
            "required" => ["todo_id","kind","uid"],
            "properties" => {
              "todo_id" => {"type" => ["integer", "string"]},
              "kind" => {"type" => "string"},
              "title" => {"type" => "string"},
              "previous_id" => {"type" => ["integer","string"]},
              "uid" => {"type" => "string"}
            }
          }
        }
      }
    }

    respond_to do |format|
      format.json {        
        input = JSON.parse(request.raw_post)        
        JSON::Validator.validate!(input_schema,input)
        input.deep_symbolize_keys!
        render json: VersionedTodoList.update(params[:id],input)
      }
    end
  end
end