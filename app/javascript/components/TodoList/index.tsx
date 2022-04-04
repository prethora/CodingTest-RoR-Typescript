import React, { useContext, useEffect } from "react";
import { Container, ListGroup, Form } from "react-bootstrap";
import { ResetButton } from "./uiComponent";
import { Navigate, useParams } from "react-router-dom";
import { CurrentTodoListStateContext } from "../DataManager";
import dataManager from "../../services/data_manager";
import { TodoListAction, TodoListActionKind } from "../../services/data_manager/managers/todo_list/types";
import NavbarTitle from "../NavbarTitle";

type Props = {
};

const TodoList: React.FC<Props> = ({ }) => {
    const { id } = useParams<{ id: string }>();

    if (id !== "1") return <Navigate to="/todo/1" />;

    const todoListId = parseInt(id);
    const todoListState = useContext(CurrentTodoListStateContext);

    const checkBoxOnCheck = (todoId: number, checked: boolean) => {
        dataManager.addAction({
            todoListId: parseInt(id),
            todoId: todoId,
            kind: checked ? TodoListActionKind.check : TodoListActionKind.uncheck
        });
    };

    const resetButtonOnClick = (): void => {
        const actions: TodoListAction[] = todoListState.todos.map(({ id: todoId, checked }) => {
            return checked ? { todoListId, todoId, kind: TodoListActionKind.uncheck } : null;
        }).filter((action) => action !== null);
        dataManager.addActions(actions);
    };

    return (
        <>
            {todoListState ? (
                <Container style={{ marginTop: 30 }}>
                    <NavbarTitle text={todoListState.title} />
                    <ListGroup>
                        {todoListState.todos.map((todo) => (
                            <ListGroup.Item key={todo.id}>
                                <Form.Check
                                    type="checkbox"
                                    label={todo.title}
                                    checked={todo.checked}
                                    onChange={(e) => checkBoxOnCheck(todo.id, e.target.checked)}
                                />
                            </ListGroup.Item>
                        ))}
                        <ResetButton onClick={resetButtonOnClick}>Reset</ResetButton>
                    </ListGroup>
                </Container>
            ) : null}
        </>
    );
};

export default TodoList;
