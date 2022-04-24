import React, { useContext, useEffect, useRef } from "react";
import { Container, ListGroup, Form } from "react-bootstrap";
import { ResetButton } from "./uiComponent";
import { Navigate, useParams } from "react-router-dom";
import { CurrentTodoListStateContext } from "../DataManager";
import dataManager from "../../services/data_manager";
import { TodoListAction, TodoListActionKind } from "../../services/data_manager/managers/todo_list/types";
import NavbarTitle from "../NavbarTitle";
import { generateUid } from "../../services/data_manager/managers/todo_list/helpers";

type Props = {
};

const TodoList: React.FC<Props> = ({ }) => {
    const { id } = useParams<{ id: string }>();

    if (id !== "1") return <Navigate to="/todo/1" />;

    const todoListId = parseInt(id);
    const todoListState = useContext(CurrentTodoListStateContext);

    const checkBoxOnCheck = (todoId: number | string, checked: boolean) => {
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

        // const title = inputRef.current?.value ? inputRef.current?.value : "Exercise";

        // dataManager.addAction({
        //     todoListId: parseInt(id),
        //     todoId: generateUid(),
        //     kind: TodoListActionKind.insert,
        //     title,
        //     previousId: todoListState.todos[todoListState.todos.length - 1].id
        // });

        // const actions: TodoListAction[] = todoListState.todos.map(({ id: todoId, checked }) => {
        //     return checked ? { todoListId, todoId, kind: TodoListActionKind.delete } : null;
        // }).filter((action) => action !== null);
        // dataManager.addActions(actions);

        // const actions: TodoListAction[] = todoListState.todos.map(({ id: todoId, checked }) => {
        //     return checked ? { todoListId, todoId, kind: TodoListActionKind.edit, title } : null;
        // }).filter((action) => action !== null);
        // dataManager.addActions(actions);

        // let lastId: string | number = 0;
        // const actions: TodoListAction[] = todoListState.todos.map(({ id: todoId, checked }) => {
        //     if (checked) {
        //         const ret = { todoListId, todoId, kind: TodoListActionKind.move, previousId: lastId };
        //         lastId = todoId;
        //         return ret;
        //     }
        //     else {
        //         return null;
        //     }
        // }).filter((action) => action !== null);
        // dataManager.addActions(actions);
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
