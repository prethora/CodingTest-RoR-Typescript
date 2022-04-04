require 'rails_helper'

RSpec.describe TodoAction, type: :model do
  let(:todo_list) { create(:todo_list) }
  let(:todo) { create(:todo,todo_list_id: todo_list.id) }

  subject {
    build(:todo_action,todo_list_id: todo_list.id,todo_id: todo.id)
  }

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a kind" do
      subject.kind = nil
      expect(subject).to_not be_valid
    end    

    it "is not valid without a version" do
      subject.version = nil
      expect(subject).to_not be_valid
    end    

    it "is not valid without a todo_list_id" do
      subject.todo_list_id = nil
      expect(subject).to_not be_valid
    end    

    it "is not valid without an existing todo_list" do
      subject.todo_list_id = 100
      expect(subject).to_not be_valid
    end    

    it "is not valid without a todo_id" do
      subject.todo_id = nil
      expect(subject).to_not be_valid
    end    

    it "is not valid without an existing todo" do
      subject.todo_id = 100
      expect(subject).to_not be_valid
    end    
  end
end
