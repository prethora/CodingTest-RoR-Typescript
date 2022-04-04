import { Todo, TodoListAction, TodoListActionKind, TodoListPendingAction, TodoListStateData } from "./types";

export class TodoListState {
    title: string;
    todos: Todo[];

    constructor(title: string, todos: Todo[]) {
        this.title = title;
        this.todos = [...todos];
        this.todos.forEach((todo) => this.idMap[todo.id] = todo);
    }

    applyAction(action: TodoListAction, { omitResponse = false }: { omitResponse?: boolean } = {}): TodoListPendingAction {
        const todo = this.idMap[action.todoId];
        if (todo) {
            switch (action.kind) {
                case TodoListActionKind.check:
                    if (!todo.checked) {
                        todo.checked = true;
                        return (!omitResponse) ? ({
                            actions: {
                                forward: { ...action },
                                rollback: { ...action, kind: TodoListActionKind.uncheck }
                            },
                            inRequest: false
                        }) : null;
                    }
                    break;
                case TodoListActionKind.uncheck:
                    if (todo.checked) {
                        todo.checked = false;
                        return (!omitResponse) ? ({
                            actions: {
                                forward: { ...action },
                                rollback: { ...action, kind: TodoListActionKind.check }
                            },
                            inRequest: false
                        }) : null;
                    }
                    break;
            }
        }
        return null;
    }

    getData(): TodoListStateData {
        return {
            title: this.title,
            todos: [...this.todos]
        };
    }

    private idMap: { [id: string]: Todo } = {};
}