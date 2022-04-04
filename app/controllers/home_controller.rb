# frozen_string_literal: true

class HomeController < ApplicationController
  def landing
    @todo_list = VersionedTodoList.get(1)
  end
end
