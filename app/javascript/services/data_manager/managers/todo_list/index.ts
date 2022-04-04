import axios from "axios";
import updating from "../../../updating";
import { kindStringToEnum, sleep } from "./helpers";
import { TodoListState } from "./state";
import { Subscription, TodoListAction, TodoListManagerSubscriptionCallback, TodoListPendingAction, VersionedTodoListResponse, VersionedTodoListUpdateResponse } from "./types";
import { createConsumer } from "@rails/actioncable";

const consumer = createConsumer();

export class TodoListManager {
    private readonly requestRetryEveryMsecs = 5000;

    id: number;
    version: number;
    state: TodoListState;

    constructor(id: number) {
        this.id = id;
    }

    async load() {
        if (this.loaded) return !this.error;
        try {
            const { data } = await axios.get<VersionedTodoListResponse>(`/todo/${this.id}`, {
                headers: {
                    "Accept": "application/json"
                }
            });
            this.version = data.version;
            this.knownVersion = data.version;
            this.state = new TodoListState(data.title, data.todos);
            this.setupActionCableSubscription();
            return true;
        }
        catch (err) {
            this.error = true;
            return false;
        }
        finally {
            this.loaded = true;
        }
    }

    subscribe(cb: TodoListManagerSubscriptionCallback) {
        if (!this.isActive) throw new Error("Cannot subscribe to a non-active data manager");
        const subscription: Subscription = { cb };
        this.subscriptions.push(subscription);
        cb(this.state);
        return () => {
            const index = this.subscriptions.indexOf(subscription);
            if (index > -1) this.subscriptions.splice(index, 1);
        };
    }

    addActions(actions: TodoListAction[]) {
        if (!this.isActive) throw new Error("Cannot add action to a non-active data manager");
        const pendingActions = actions.map((action) => this.state.applyAction(action)).filter((pendingAction) => pendingAction !== null);
        if (pendingActions.length > 0) {
            this.sendUpdatesToSubscriptions();
            this.pendingActions.push(...pendingActions);
            this.processPending();
        }
    }

    static preLoad({ todo_list_id, version, title, todos }: VersionedTodoListResponse) {
        const manager = new TodoListManager(todo_list_id);
        manager.loaded = true;
        manager.id = todo_list_id;
        manager.version = version;
        manager.knownVersion = version;
        manager.state = new TodoListState(title, todos);
        manager.setupActionCableSubscription();
        return manager;
    }

    private loaded = false;
    private error = false;
    private updating = false;
    private knownVersion = 0;
    private get isActive() {
        return this.loaded && !this.error;
    }
    private subscriptions: Subscription[] = []
    private pendingActions: TodoListPendingAction[] = [];

    private sendUpdatesToSubscriptions() {
        this.subscriptions.forEach(({ cb }) => cb(this.state));
    }

    private rollbackPendingActions() {
        for (let i = this.pendingActions.length - 1; i >= 0; i--) {
            const { rollback } = this.pendingActions[i].actions;
            this.state.applyAction(rollback, { omitResponse: true });
        }
    }

    private forwardPendingActions() {
        for (let i = 0; i < this.pendingActions.length; i++) {
            const { forward } = this.pendingActions[i].actions;
            this.state.applyAction(forward, { omitResponse: true });
        }
    }

    private processPending() {
        if ((this.updating) || ((this.pendingActions.length === 0) && (this.knownVersion <= this.version))) return;

        (async () => {
            this.updating = true;

            const createNewActions = () => this.pendingActions.map((pendingAction) => {
                const { actions: { forward: action } } = pendingAction;
                pendingAction.inRequest = true;
                return { todo_id: action.todoId, kind: action.kind };
            });

            let new_actions = createNewActions();

            const { version, actions_before } = await updating.requesting(async () => {
                while (true) {
                    try {
                        const { data } = await axios.post<VersionedTodoListUpdateResponse>(`/todo/${this.id}/update`, { old_version: this.version, new_actions });
                        return data;
                    }
                    catch (err) {
                    }
                    await sleep(this.requestRetryEveryMsecs);

                    if (this.pendingActions.length > new_actions.length) {
                        new_actions = createNewActions();
                    }
                }
            }, { silent: (new_actions.length === 0) });

            this.version = version;
            if (this.knownVersion < version) this.knownVersion = version;

            if (actions_before.length > 0) {
                this.rollbackPendingActions();
                actions_before.forEach(({ todo_id: todoId, kind }) => {
                    this.state.applyAction({ todoListId: this.id, todoId, kind: kindStringToEnum(kind) }, { omitResponse: true });
                });
                this.forwardPendingActions();
                this.sendUpdatesToSubscriptions();
            }
            this.pendingActions = this.pendingActions.filter(({ inRequest }) => !inRequest);
            this.updating = false;
            this.processPending();
        })();
    }

    private setupActionCableSubscription() {
        consumer.subscriptions.create({ channel: "TodoListChannel", id: this.id }, {
            connected: () => {
            },

            disconnected: () => {
            },

            received: ({ version }: { version: number }) => {
                if (version > this.knownVersion) {
                    this.knownVersion = version;
                    this.processPending();
                }
            }
        });
    }
}