# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "home#landing"
  get "todo/:id", to: "todo_list#index"
  post "todo/:id/update", to: "todo_list#update", :defaults => { :format => 'json' }
  # post "todo", to: "home#edit_todo_item"
  # post "reset", to: "home#reset_todo_items"  # Bug Fix 1: controller method was misspelt - renamed "home#reset_todo_item" to "home#reset_todo_items"
end
