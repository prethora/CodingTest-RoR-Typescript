import { generateUid, isValidUid } from "./helpers";
import { Todo, TodoListAction, TodoListActionKind, TodoListPendingAction, TodoListStateData, UidResolution } from "./types";

export class TodoListState {
    title: string;
    todos: Todo[];

    constructor(title: string, todos: Todo[]) {
        this.title = title;
        this.todos = [...todos];
        this.todos.forEach((todo) => {
            todo.uiid = generateUid();
            this.idMap[todo.id] = todo;
        });
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
                                rollback: [{ ...action, kind: TodoListActionKind.uncheck }]
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
                                rollback: [{ ...action, kind: TodoListActionKind.check }]
                            },
                            inRequest: false
                        }) : null;
                    }
                    break;
                case TodoListActionKind.delete:
                    const todoIndex = this.todos.indexOf(todo);
                    this.todos.splice(todoIndex, 1);
                    delete this.idMap[todo.id];

                    return (!omitResponse) ? ({
                        actions: {
                            forward: { ...action },
                            rollback: [
                                { todoListId: action.todoListId, todoId: todo.id, kind: TodoListActionKind.insert, title: todo.title, previousId: (todoIndex > 0) ? this.todos[todoIndex - 1].id : 0 },
                                ...(todo.checked ? [{ todoListId: action.todoListId, todoId: todo.id, kind: TodoListActionKind.check }] : [])
                            ]
                        },
                        inRequest: false
                    }) : null;
                    break;
                case TodoListActionKind.edit:
                    if (this.isValidEditAction(action)) {
                        const oldTitle = todo.title;
                        todo.title = action.title;

                        return (!omitResponse) ? ({
                            actions: {
                                forward: { ...action },
                                rollback: [
                                    { todoListId: action.todoListId, todoId: todo.id, kind: TodoListActionKind.edit, title: oldTitle }
                                ]
                            },
                            inRequest: false
                        }) : null;
                    }
                    break;
                case TodoListActionKind.move:
                    if (this.isValidMoveAction(action)) {
                        const todoIndex = this.todos.indexOf(todo);
                        const oldPreviousId = (todoIndex === 0) ? 0 : this.todos[todoIndex - 1].id;
                        this.todos.splice(todoIndex, 1);
                        let moveTo = (action.previousId) ? this.todos.indexOf(this.idMap[action.previousId]) + 1 : 0;
                        this.todos.splice(moveTo, 0, todo);

                        return (!omitResponse) ? ({
                            actions: {
                                forward: { ...action },
                                rollback: [
                                    { todoListId: action.todoListId, todoId: todo.id, kind: TodoListActionKind.move, previousId: oldPreviousId }
                                ]
                            },
                            inRequest: false
                        }) : null;
                    }
                    break;
            }
        }
        else {
            switch (action.kind) {
                case TodoListActionKind.insert:
                    if (this.isValidInsertAction(action)) {
                        const insertedTodo: Todo = {
                            id: action.todoId,
                            title: action.title,
                            checked: false,
                            uiid: generateUid()
                        };

                        if (typeof action.todoId === "string") {
                            this.idToUiidMap[action.todoId] = insertedTodo.uiid;
                        }
                        else if ((typeof action.todoId === "number") && (this.idToUiidMap[action.todoId])) {
                            insertedTodo.uiid = this.idToUiidMap[action.todoId];
                            delete this.idToUiidMap[action.todoId];
                        }

                        const insertAt = (!action.previousId) ? 0 : (this.todos.indexOf(this.idMap[action.previousId]) + 1);
                        this.todos.splice(insertAt, 0, insertedTodo);
                        this.idMap[insertedTodo.id] = insertedTodo;
                        return (!omitResponse) ? ({
                            actions: {
                                forward: { ...action },
                                rollback: [{ todoListId: action.todoListId, todoId: action.todoId, kind: TodoListActionKind.delete }]
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

    processUidResolution(uidResolution: UidResolution, ignoredUids: string[]) {
        let changed = false;
        Object.keys(uidResolution).forEach((uid) => {
            if (this.idMap[uid]) {
                const todo = this.idMap[uid];
                todo.id = uidResolution[uid];
                delete this.idMap[uid];
                this.idMap[todo.id] = todo;
                changed = true;
            }
            if (this.idToUiidMap[uid]) {
                if (ignoredUids.indexOf(uid) !== -1) {
                    this.idToUiidMap[uidResolution[uid]] = this.idToUiidMap[uid];
                }
                delete this.idToUiidMap[uid];
            }
        });
        return changed;
    }

    private idMap: { [id: number | string]: Todo } = {};
    private idToUiidMap: { [id: number | string]: string } = {};

    private isValidInsertAction(action: TodoListAction) {
        return (action.kind === TodoListActionKind.insert) &&
            (
                ((typeof action.todoId === "string") && (isValidUid(action.todoId)) && (action.uid === action.todoId)) ||
                ((typeof action.todoId === "number") && (action.todoId > 0))
            ) &&
            (!this.idMap[action.todoId]) &&
            ((!action.previousId) || (this.idMap[action.previousId])) &&
            ((typeof action.title === "string") && ((action.title = action.title.trim()) !== ""));
    }

    private isValidEditAction(action: TodoListAction) {
        return (action.kind === TodoListActionKind.edit) &&
            (
                ((typeof action.todoId === "string") && (isValidUid(action.todoId))) ||
                ((typeof action.todoId === "number") && (action.todoId > 0))
            ) &&
            (this.idMap[action.todoId]) &&
            ((typeof action.title === "string") && ((action.title = action.title.trim()) !== "") && (action.title !== this.idMap[action.todoId].title));
    }

    private isValidMoveAction(action: TodoListAction) {
        const todoIndex = this.todos.indexOf(this.idMap[action.todoId]);
        return (action.kind === TodoListActionKind.move) &&
            (
                ((typeof action.todoId === "string") && (isValidUid(action.todoId)) && (action.uid === action.todoId)) ||
                ((typeof action.todoId === "number") && (action.todoId > 0))
            ) &&
            (this.idMap[action.todoId]) &&
            (
                ((!action.previousId) && (todoIndex > 0)) ||
                ((this.idMap[action.previousId]) && (action.previousId !== action.todoId) && ((todoIndex === 0) || (action.previousId !== this.todos[todoIndex - 1].id)))
            );
    }
}