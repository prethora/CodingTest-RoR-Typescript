import axios from "axios";
import React, { useEffect, useRef, useState } from "react";
import { useLocation, useParams } from "react-router-dom";
import dataManager from "../../services/data_manager";
import { TodoListState } from "../../services/data_manager/managers/todo_list/state";
import { TodoListStateData, VersionedTodoListResponse } from "../../services/data_manager/managers/todo_list/types";

export const CurrentTodoListStateContext = React.createContext<TodoListStateData>(null);

type Props = {
    todoList?: VersionedTodoListResponse;
};

const DataManager: React.FC<Props> = ({ children, todoList }) => {
    const currentTodoListIdRef = useRef(-1);
    const currentTodoListUnSubscribeRef = useRef(null);
    const location = useLocation();

    const [currentTodoListState, setCurrentTodoListState] = useState<TodoListStateData>(null);

    useEffect(() => {
        if (todoList) dataManager.preLoad(todoList);
    }, []);

    useEffect(() => {
        (async () => {
            const res = /^\/todo\/(\d+)$/.exec(location.pathname);
            if (res) {
                const todoListId = parseInt(res[1]);
                if (todoListId !== currentTodoListIdRef.current) {
                    currentTodoListIdRef.current = todoListId;
                    try {
                        const { current: unsubscribe } = currentTodoListUnSubscribeRef;
                        if (unsubscribe) unsubscribe();
                        currentTodoListUnSubscribeRef.current = await dataManager.subscribeToTodoListState(todoListId, (state) => {
                            setCurrentTodoListState(state.getData());
                        });
                    }
                    catch (e) {
                        // TODO eventually deal with failed requests
                    }
                }
            }
            else {
                currentTodoListIdRef.current = -1;
                setCurrentTodoListState(null);
            }
        })();
    }, [location.pathname]);

    return (
        <CurrentTodoListStateContext.Provider value={currentTodoListState}>
            {children}
        </CurrentTodoListStateContext.Provider>
    );
};

export default DataManager;