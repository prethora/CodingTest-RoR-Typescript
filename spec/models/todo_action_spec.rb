require 'rails_helper'

RSpec.describe TodoAction, type: :model do
  let(:todo_list) { create(:todo_list) }
  let(:todo) { create(:todo,todo_list: todo_list, previous: todo_list.nil_todo) }

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
      subject.todo_list_id = 10000000001
      expect(subject).to_not be_valid
    end    

    it "is not valid without a todo_id" do
      subject.todo_id = nil
      expect(subject).to_not be_valid
    end    

    it "is not valid without an existing todo" do
      subject.todo_id = 10000000001
      expect(subject).to_not be_valid
    end    

    it "is not valid with a todo from another todo_list" do
      subject.todo = create(:todo_list,todo_count: 1).first_ordered_todo
      expect(subject).to_not be_valid
    end    

    it "is not valid without a title when kind is 'insert' or 'edit'" do
      subject.kind = "insert"
      subject.title = nil
      expect(subject).to_not be_valid
      subject.kind = "edit"
      expect(subject).to_not be_valid
    end    

    it "is not valid with a title when kind is not 'insert' or 'edit'" do
      subject.title = "some title"
      subject.kind = "check"
      expect(subject).to_not be_valid
      subject.kind = "uncheck"
      expect(subject).to_not be_valid
      subject.kind = "delete"
      expect(subject).to_not be_valid
      subject.kind = "move"
      expect(subject).to_not be_valid
      subject.kind = "insert"
      expect(subject).to be_valid
      subject.kind = "edit"
      expect(subject).to be_valid
    end

    it "is not valid with a previous_id when kind is not 'insert' or 'move'" do
      subject.previous = create(:todo,todo_list: todo_list, previous: todo)
      subject.kind = "check"
      expect(subject).to_not be_valid
      subject.kind = "uncheck"
      expect(subject).to_not be_valid
      subject.kind = "delete"
      expect(subject).to_not be_valid
      subject.kind = "move"
      expect(subject).to be_valid
      subject.title = "some title"
      subject.kind = "insert"
      expect(subject).to be_valid      
      subject.kind = "edit"
      expect(subject).to_not be_valid
    end

    it "is not valid with a previous_id that refers to a non-existant todo" do
      subject.kind = "move"
      subject.previous_id = 10000000001
      expect(subject).to_not be_valid
    end

    it "is not valid with a previous_id that refers to self.todo" do
      subject.kind = "move"
      subject.previous = todo
      expect(subject).to_not be_valid
    end

    it "is not valid with a previous_id that refers to a todo from another todo_list" do
      subject.kind = "move"
      subject.previous = create(:todo_list,todo_count: 1).first_ordered_todo
      expect(subject).to_not be_valid
    end

  end

  describe "Class Methods" do
    describe "generate_uid" do
      it "generates a random uid" do        
        uid1 = TodoAction.generate_uid
        uid2 = TodoAction.generate_uid
        expect(uid1).to match(/^[a-zA-Z0-9]{12}$/)
        expect(uid2).to match(/^[a-zA-Z0-9]{12}$/)
        expect(uid1).to_not eql(uid2)
      end
    end
  end
end