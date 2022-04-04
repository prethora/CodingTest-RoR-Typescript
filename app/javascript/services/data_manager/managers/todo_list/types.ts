import { TodoListState } from "./state";

export interface Todo {
    id: number;
    title: string;
    checked: boolean;
}

export interface VersionedTodoListResponse {
    todo_list_id: number;
    version: number;
    title: string;
    todos: Todo[];
}

export interface VersionedTodoListUpdateResponse {
    todo_list_id: number;
    version: number;
    actions_before: { todo_id: number; version: number; kind: string }[];
}

export type TodoListManagerSubscriptionCallback = (state: TodoListState) => void;

export interface Subscription {
    cb: TodoListManagerSubscriptionCallback;
}

export interface TodoListStateData {
    title: string;
    todos: Todo[];
}

export enum TodoListActionKind {
    check = "check",
    uncheck = "uncheck"
}

export interface TodoListAction {
    todoListId: number;
    todoId: number;
    kind: TodoListActionKind;
}

export interface TodoListPendingAction {
    actions: {
        forward: TodoListAction;
        rollback: TodoListAction;
    };
    inRequest: boolean;
}