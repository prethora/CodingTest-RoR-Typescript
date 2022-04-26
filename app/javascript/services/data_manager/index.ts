import axios from "axios";
import { TodoListManager } from "./managers/todo_list";
import { TodoListState } from "./managers/todo_list/state";
import { TodoListAction, TodoListManagerSubscriptionCallback, VersionedTodoListResponse } from "./managers/todo_list/types";

class DataManagerService {
    todoListManagers: { [id: number]: TodoListManager } = {}

    async subscribeToTodoListState(id: number, cb: TodoListManagerSubscriptionCallback) {
        await this.ensureTodoDataManager(id);
        if (!this.todoListManagers[id]) throw new Error("Todo list does not exist");
        return this.todoListManagers[id].subscribe(cb);
    }

    pauseSubscription(id: number) {
        if (!this.todoListManagers[id]) throw new Error("Todo list does not exist");
        return this.todoListManagers[id].pauseSubscription();
    }

    resumeSubscription(id: number) {
        if (!this.todoListManagers[id]) throw new Error("Todo list does not exist");
        return this.todoListManagers[id].resumeSubscription();
    }

    addAction(action: TodoListAction) {
        this.addActions([action]);
    }

    addActions(actions: TodoListAction[]) {
        const actionsMap: { [id: number]: TodoListAction[] } = {};
        actions.forEach((action) => {
            actionsMap[action.todoListId] = actionsMap[action.todoListId] || [];
            actionsMap[action.todoListId].push(action);
        });
        Object.keys(actionsMap).forEach((id) => {
            const todoListId = parseInt(id);
            if (this.todoListManagers[todoListId]) {
                this.todoListManagers[todoListId].addActions(actionsMap[todoListId]);
            }
        });
    }

    preLoad(todoList: VersionedTodoListResponse) {
        this.todoListManagers[todoList.todo_list_id] = TodoListManager.preLoad(todoList);
    }

    private async ensureTodoDataManager(id: number) {
        if (!this.todoListManagers[id]) {
            const manager = new TodoListManager(id);
            if (await manager.load()) {
                this.todoListManagers[id] = manager;
            }
        }
        return this.todoListManagers[id];
    }
}

const dataManager = new DataManagerService();

export default dataManager;