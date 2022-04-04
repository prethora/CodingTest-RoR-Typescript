import React, { useEffect } from "react";
import { BrowserRouter, Routes, Route, Link } from "react-router-dom";
import { VersionedTodoListResponse } from "../../services/data_manager/managers/todo_list/types";
import App from "../App";
import AppRouter from "../AppRouter";
import DataManager from "../DataManager";

type Props = {
    todoList?: VersionedTodoListResponse;
};

const AppStarter: React.FC<Props> = ({ todoList }) => {
    return (
        <BrowserRouter>
            <DataManager todoList={todoList}>
                <App>
                    <AppRouter />
                </App>
            </DataManager>
        </BrowserRouter>
    );
};

export default AppStarter;