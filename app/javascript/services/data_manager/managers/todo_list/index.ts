import axios from "axios";
import updating from "../../../updating";
import { generateUid, kindStringToEnum, sleep } from "./helpers";
import { TodoListState } from "./state";
import { Subscription, TodoListAction, TodoListActionKind, TodoListManagerSubscriptionCallback, TodoListPendingAction, TodoListServerAction, UidResolution, VersionedTodoListResponse, VersionedTodoListUpdateResponse } from "./types";
import { createConsumer } from "@rails/actioncable";
import { isThisTypeNode } from "typescript";

const consumer = createConsumer();

export class TodoListManager {
    private readonly REQUEST_RETRY_EVERY_MSECS = 5000;

    id: number;
    version: number;
    state: TodoListState;

    onHold = false;

    constructor(id: number) {
        this.id = id;
        (window as any).todoListManager = this;
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

    pauseSubscription() {
        this.paused = true;
    }

    resumeSubscription(forceUpdate = false) {
        if (this.paused) {
            this.paused = false;
            if (forceUpdate) {
                this.sendUpdatesToSubscriptions();
            }
        }
    }

    addActions(actions: TodoListAction[]) {
        if (!this.isActive) throw new Error("Cannot add action to a non-active data manager");
        actions.forEach((action) => {
            if ((action.kind === TodoListActionKind.insert) && (typeof action.todoId === "string")) {
                action.uid = action.todoId;
            }
            else {
                action.uid = generateUid();
            }
        });
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
    private paused = false;
    private get isActive() {
        return this.loaded && !this.error;
    }
    private subscriptions: Subscription[] = []
    private pendingActions: TodoListPendingAction[] = [];

    private sendUpdatesToSubscriptions() {
        if (this.paused) return;
        this.subscriptions.forEach(({ cb }) => cb(this.state));
    }

    private rollbackPendingActions() {
        for (let i = this.pendingActions.length - 1; i >= 0; i--) {
            const { rollback } = this.pendingActions[i].actions;
            rollback.forEach((action) => this.state.applyAction(action, { omitResponse: true }));
        }
    }

    private forwardPendingActions(ignored_uids: string[]) {
        const isAnIgnoredUid = (uid: string) => ignored_uids.indexOf(uid) !== -1;
        for (let i = 0; i < this.pendingActions.length; i++) {
            const { forward } = this.pendingActions[i].actions;
            if (!isAnIgnoredUid(forward.uid)) {
                this.state.applyAction(forward, { omitResponse: true });
            }
        }
    }

    private processPending() {
        if ((this.updating) || ((this.pendingActions.length === 0) && (this.knownVersion <= this.version))) return;

        (async () => {
            this.updating = true;

            const createNewActions = () => this.pendingActions.map((pendingAction) => {
                const { actions: { forward: action } } = pendingAction;
                pendingAction.inRequest = true;

                const ret: TodoListServerAction = { todo_id: action.todoId, kind: action.kind, uid: action.uid };

                if ((action.kind === TodoListActionKind.insert) || (action.kind === TodoListActionKind.edit)) {
                    ret.title = action.title;
                }

                if ((action.kind === TodoListActionKind.insert) || (action.kind === TodoListActionKind.move)) {
                    ret.previous_id = action.previousId;
                }

                return ret;
            });

            let new_actions = createNewActions();

            const { version, actions_before, uid_resolution, ignored_uids } = await updating.requesting(async () => {
                while (true) {
                    try {
                        if (this.onHold) throw "on_hold";
                        const { data } = await axios.post<VersionedTodoListUpdateResponse>(`/todo/${this.id}/update`, { old_version: this.version, new_actions });
                        return data;
                    }
                    catch (err) {
                    }
                    await sleep(this.REQUEST_RETRY_EVERY_MSECS);

                    if (this.pendingActions.length > new_actions.length) {
                        new_actions = createNewActions();
                    }
                }
            }, { silent: (new_actions.length === 0) });

            let mustSendUpdateToSubscriptions = this.state.processUidResolution(uid_resolution, ignored_uids);
            this.processUidResolution(uid_resolution);

            this.version = version;
            if (this.knownVersion < version) this.knownVersion = version;

            if (actions_before.length > 0) {
                this.rollbackPendingActions();
                actions_before.forEach(({ todo_id: todoId, kind, title, previous_id: previousId }) => {
                    this.state.applyAction({
                        todoListId: this.id,
                        todoId, kind: kindStringToEnum(kind),
                        title,
                        previousId
                    }, { omitResponse: true });
                });
                this.forwardPendingActions(ignored_uids);
                mustSendUpdateToSubscriptions = true;
            }

            if (mustSendUpdateToSubscriptions) this.sendUpdatesToSubscriptions();

            this.pendingActions = this.pendingActions.filter(({ inRequest }) => !inRequest);
            this.updating = false;
            this.processPending();
        })();
    }

    private processUidResolution(uidResolution: UidResolution) {
        this.pendingActions.map(({ actions: { forward, rollback } }) => [forward, rollback]).flat(2).forEach((action) => {
            if (uidResolution[action.todoId]) action.todoId = uidResolution[action.todoId];
            if (uidResolution[action.previousId]) action.previousId = uidResolution[action.previousId];
        });
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