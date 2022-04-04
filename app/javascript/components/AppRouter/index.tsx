import React from "react";
import { Link, Route, Routes, Navigate } from "react-router-dom";
import TodoList from "../TodoList";

type Props = {
};

const AppRouter: React.FC<Props> = ({ }) => {
    return (
        <Routes>
            <Route path="/" element={<Navigate to="/todo/1" />} />
            <Route path="/todo/:id" element={<TodoList />} />
        </Routes>
    );
};

export default AppRouter;