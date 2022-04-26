import React, { useContext, useEffect, useRef, useState } from "react";
import { Container, ListGroup, Form } from "react-bootstrap";
import { Navigate, useParams } from "react-router-dom";
import { CurrentTodoListStateContext } from "../DataManager";
import dataManager from "../../services/data_manager";
import { Todo, TodoListAction, TodoListActionKind } from "../../services/data_manager/managers/todo_list/types";
import NavbarTitle from "../NavbarTitle";
import { generateUid } from "../../services/data_manager/managers/todo_list/helpers";
import css from 'styled-jsx/css';
import { EditableLabel } from "../EditableLabel";
import { ControlBar } from "../ControlBar";
import { IconButton } from "../IconButton";
import { MoveHandle } from "../MoveHandle";
import { MoveDestination } from "../MoveDestination";

type Props = {
};

const TodoList: React.FC<Props> = ({ }) => {
    const { id } = useParams<{ id: string }>();

    if (id !== "1") return <Navigate to="/todo/1" />;

    const [editingUiid, setEditingUiid] = useState<string>(null);
    const [showingActionsUiid, setShowingActionsUiid] = useState<string>(null);
    const [movingUiid, setMovingUiid] = useState<string>(null);
    const [moveVerticalShift, setMoveVerticalShift] = useState(0);

    const todoListId = parseInt(id);
    const todoListState = useContext(CurrentTodoListStateContext);
    const todoListStateRef = useRef(todoListState);
    todoListStateRef.current = todoListState;

    const checkBoxOnCheck = (todoId: number | string, checked: boolean) => {
        dataManager.addAction({
            todoListId,
            todoId: todoId,
            kind: checked ? TodoListActionKind.check : TodoListActionKind.uncheck
        });
    };

    const itemDoubleClickedHandle = (todo: Todo) => {
        setEditingUiid(todo.uiid);
    };

    const itemDeleteClickedHandle = (todo: Todo) => {
        dataManager.addAction({
            todoListId,
            todoId: todo.id,
            kind: TodoListActionKind.delete
        });
    };

    const itemChangedHandle = (todo: Todo, newValue: string) => {
        if ((newValue !== "") && (newValue !== todo.title)) {
            dataManager.addAction({ todoListId, todoId: todo.id, kind: TodoListActionKind.edit, title: newValue });
        }
        setEditingUiid(null);
    };

    const newItemChangedHandle = (newValue: string, tabPressed: boolean) => {
        setEditingUiid(null);
        if (newValue !== "") {
            dataManager.addAction({
                todoListId,
                todoId: generateUid(),
                kind: TodoListActionKind.insert,
                title: newValue,
                previousId: todoListState.todos[todoListState.todos.length - 1].id
            });
            if (tabPressed) {
                setTimeout(() => { setEditingUiid(""); }, 0);
            }
        }
    };

    const controlBarNewItemClickHandler = () => {
        setEditingUiid("");
    };

    const moveStartPositionRef = useRef({ x: 0, y: 0 });
    const moveItemIndexRef = useRef(-1);
    const [moveDestinationIndex, setMoveDestinationIndex] = useState(-1);
    const moveDestinationIndexRef = useRef(moveDestinationIndex);
    moveDestinationIndexRef.current = moveDestinationIndex;

    const itemMoveStartHandler = (todo: Todo, x: number, y: number) => {
        const { current: todoListState } = todoListStateRef;
        moveItemIndexRef.current = todoListState.todos.indexOf(todo);
        dataManager.pauseSubscription(todoListId);
        setMovingUiid(todo.uiid);
        setMoveVerticalShift(0);
        moveStartPositionRef.current = { x, y };
    };

    const itemMoveMoveHandler = (x: number, y: number) => {
        const { current: todoListState } = todoListStateRef;
        const { current: moveItemIndex } = moveItemIndexRef;
        const itemHeight = 43;
        const shift = y - moveStartPositionRef.current.y;
        setMoveVerticalShift(shift);
        if (Math.abs(shift) > itemHeight) {
            const midShift = Math.abs(shift) - (itemHeight / 2);
            const indexShift = Math.round(midShift / itemHeight);
            const destinationIndex = Math.min(
                todoListState.todos.length,
                Math.max(
                    0,
                    (shift > 0) ? (moveItemIndex + 1 + indexShift) : (moveItemIndex - indexShift)
                )
            );
            setMoveDestinationIndex(destinationIndex);
        }
        else {
            setMoveDestinationIndex(-1);
        }
    };

    const itemMoveEndHandler = () => {
        const { current: todoListState } = todoListStateRef;
        setMovingUiid(null);
        const { current: moveDestinationIndex } = moveDestinationIndexRef;
        dataManager.resumeSubscription(todoListId);
        if (moveDestinationIndex !== -1) {
            const { current: moveItemIndex } = moveItemIndexRef;
            setMoveDestinationIndex(-1);
            dataManager.addAction({
                todoListId,
                todoId: todoListState.todos[moveItemIndex].id,
                kind: TodoListActionKind.move,
                previousId: (moveDestinationIndex === 0) ? 0 : todoListState.todos[moveDestinationIndex - 1].id
            });
        }
    };

    const { className, styles } = css.resolve`
        .item {
            padding: 0px;
        }

        .item.new {
            display: flex;
            flex-direction: row;    
            padding: 8px 16px;
            padding-left: 20px;
        }
    `

    return (
        <>
            {todoListState ? (
                <>
                    <Container style={{ marginTop: 30, marginBottom: 50 }}>
                        <NavbarTitle text={todoListState.title} />
                        <ControlBar onNewItemClick={controlBarNewItemClickHandler} />
                        <ListGroup onMouseLeave={() => setShowingActionsUiid(null)}>
                            {todoListState.todos.map((todo, index) => (
                                <React.Fragment key={todo.uiid} >
                                    <ListGroup.Item className={className + " item"} onMouseOver={() => setShowingActionsUiid(todo.uiid)}>
                                        <MoveDestination show={moveDestinationIndex === index} />
                                        <div className={"item-frame-back" + ((index === 0) ? " first" : "")}>
                                            <div className={"item-frame" + ((movingUiid === todo.uiid) ? " moving" : "")} style={(movingUiid === todo.uiid) ? {
                                                transform: `translateY(${moveVerticalShift}px)`
                                            } : {}}>
                                                <div className={"move-handle" + ((showingActionsUiid === todo.uiid) ? " show" : "")}>
                                                    <MoveHandle
                                                        onMoveStart={(x, y) => itemMoveStartHandler(todo, x, y)}
                                                        onMove={itemMoveMoveHandler}
                                                        onMoveEnd={itemMoveEndHandler}
                                                    />
                                                </div>
                                                <Form.Check
                                                    type="checkbox"
                                                    label={""}
                                                    checked={todo.checked}
                                                    onChange={(e) => checkBoxOnCheck(todo.id, e.target.checked)}
                                                />
                                                <div className="label">
                                                    <EditableLabel
                                                        value={todo.title}
                                                        editing={todo.uiid === editingUiid}
                                                        onDoubleClick={() => itemDoubleClickedHandle(todo)}
                                                        onChange={(newValue) => itemChangedHandle(todo, newValue)}
                                                    />
                                                </div>
                                                <div className={"actions" + ((showingActionsUiid === todo.uiid) ? " show" : "")}>
                                                    <IconButton name="edit" size={18} offHoverOpacity={0.6} onClick={() => itemDoubleClickedHandle(todo)} />
                                                    <div className="spacer"></div>
                                                    <IconButton name="delete" size={18} offHoverOpacity={0.6} onClick={() => itemDeleteClickedHandle(todo)} />
                                                </div>
                                            </div>
                                        </div>
                                    </ListGroup.Item>
                                </React.Fragment>
                            ))}
                            <MoveDestination verticalShift={0} height={3} show={moveDestinationIndex === todoListState.todos.length} />
                            {(editingUiid === "") ? (
                                <ListGroup.Item className={className + " item new"}>
                                    <Form.Check
                                        type="checkbox"
                                        label={""}
                                        checked={false}
                                    />
                                    <div className="label">
                                        <EditableLabel
                                            value={""}
                                            editing={true}
                                            onChange={newItemChangedHandle}
                                        />
                                    </div>
                                </ListGroup.Item>
                            ) : null}
                            <button className="tab-sink"></button>
                        </ListGroup>
                    </Container>
                </>
            ) : null}
            <style jsx>{`
            .label {
                flex: 1 0;
                padding-left: 10px;
            }

            .item-frame-back {
                --border-radius: 3px;
                background-color: #ccc;
                height: 42px;
            }

            .item-frame-back.first,.item-frame-back.first .item-frame {                
                border-top-left-radius: var(--border-radius);
                border-top-right-radius: var(--border-radius);
            }

            .item-frame.moving {
                opacity: 0.75;
                z-index: 10;
                border: 1px solid #999;
                /* border-bottom: 1px solid #999; */
                height: 42px;
                position: relative;
                left: -1px;
                top: -1px;
            }

            .item-frame {
                display: flex;
                flex-direction: row;    
                padding: 8px 16px;
                padding-left: 0px;
                background-color: #fff;
                height: 42px;
            }

            .move-handle {
                opacity: 0;
                visibility: hidden;
                --duration: 0.15s;
                transition: opacity var(--duration),visibility var(--duration);
            }

            .actions {
                padding-top: 4px;
                opacity: 0;
                visibility: hidden;
                --duration: 0.15s;
                transition: opacity var(--duration),visibility var(--duration);
            }

            .actions.show, .move-handle.show {
                opacity: 1;
                visibility: visible;
            }

            .actions .spacer {
                display: inline-block;
                width: 12px;
            }

            .tab-sink {
                position: fixed;
                left: -10000px;
                top: 0px;
            }
            `}</style>
            {styles}
        </>
    );
};

export default TodoList;
