require 'rails_helper'

RSpec.describe Todo, type: :model do
  let(:todo_list) { create(:todo_list) }

  subject {
    build(:todo,todo_list_id: todo_list.id)
  }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a title" do
      subject.title = nil
      expect(subject).to_not be_valid
    end    

    it "is not valid without a todo_list_id" do
      subject.todo_list_id = nil
      expect(subject).to_not be_valid
    end    

    it "is not valid without an existing todo_list" do
      subject.todo_list_id = 10000000001
      expect(subject).to_not be_valid
    end

    it "is not valid if previous refers to a todo from another todo_list" do
      list = create(:todo_list,todo_count: 1)
      todo = list.first_ordered_todo
      subject.previous = todo
      expect(subject).to_not be_valid
    end
  end
end
