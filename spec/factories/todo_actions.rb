FactoryBot.define do
  factory :todo_action do
    version { 0 }
    kind { "check" }
    uid { TodoAction.generate_uid }
  end
end