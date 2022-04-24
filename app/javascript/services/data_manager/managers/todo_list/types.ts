import { TodoListState } from "./state";

export interface Todo {
    id: number | string;
    title: string;
    checked: boolean;
}

export interface VersionedTodoListResponse {
    todo_list_id: number;
    version: number;
    title: string;
    todos: Todo[];
}

export type UidResolution = { [uid: string]: number };

export interface VersionedTodoListUpdateResponse {
    todo_list_id: number;
    version: number;
    actions_before: { todo_id: number; version: number; kind: string; title?: string; previous_id?: number }[];
    uid_resolution: UidResolution;
    ignored_uids: string[];
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
    uncheck = "uncheck",
    insert = "insert",
    delete = "delete",
    edit = "edit",
    move = "move"
}

export interface TodoListAction {
    todoListId: number;
    todoId: number | string;
    kind: TodoListActionKind;
    title?: string;
    previousId?: number | string;
    uid?: string;
}

export interface TodoListPendingAction {
    actions: {
        forward: TodoListAction;
        rollback: TodoListAction[];
    };
    inRequest: boolean;
}

export interface TodoListServerAction {
    todo_id: number | string;
    kind: TodoListActionKind;
    title?: string;
    previous_id?: number | string;
    uid: string;
}