# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "home#landing"
  get "todo/:id", to: "todo_list#index"
  post "todo/:id/update", to: "todo_list#update", :defaults => { :format => 'json' }
end
