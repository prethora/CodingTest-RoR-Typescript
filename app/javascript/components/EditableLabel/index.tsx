import React, { useContext, useEffect, useLayoutEffect, useRef, useState } from "react";

export type EditableLabelProps = {
    value: string;
    editing: boolean;
    onDoubleClick?: () => void;
    onChange?: (newValue: string, tabPressed: boolean) => void;
};

export function EditableLabel({ value, editing: _editing, onDoubleClick = () => { }, onChange = () => { } }: EditableLabelProps) {
    const [editing, setEditing] = useState(_editing);
    const editingRef = useRef(editing);
    editingRef.current = editing;
    const inputRef = useRef<HTMLInputElement>(null);
    const [editingValue, setEditingValue] = useState(value);

    const changeSentRef = useRef(false);
    const tabPressedRef = useRef(false);

    useEffect(() => {
        const { current: editing } = editingRef;
        if (_editing !== editing) {
            setEditingValue(value);
            setEditing(_editing);
        }
    }, [_editing]);

    useLayoutEffect(() => {
        const { current: editing } = editingRef;
        const { current: inputElem } = inputRef;
        if ((editing) && (inputElem)) {
            changeSentRef.current = false;
            tabPressedRef.current = false;
            inputElem.setSelectionRange(inputElem.value.length, inputElem.value.length);
            inputElem.focus();
        }
    }, [editing]);

    const sendChange = (newValue: string) => {
        if (!changeSentRef.current) {
            changeSentRef.current = true;
            onChange(newValue, tabPressedRef.current);
        }
    };

    const inputChangeHandler = () => {
        const { current: inputElem } = inputRef;
        if (inputElem) {
            setEditingValue(inputElem.value);
        }
    };

    const inputKeyUpHandler = (key: string) => {
        if (key === "Enter") {
            sendChange(editingValue.trim());
        }
        if (key === "Escape") {
            sendChange(value);
        }
    };

    const inputKeyDownHandler = (key: string) => {
        if (key === "Tab") {
            tabPressedRef.current = true;
        }
    };

    const inputBlurHandler = () => {
        sendChange(editingValue.trim());
    };

    return (
        <>
            <div className={"frame" + (editing ? " editing" : "")} onDoubleClick={onDoubleClick}>
                {value}
                <input
                    ref={inputRef}
                    className="input"
                    type="text"
                    value={editingValue}
                    onChange={inputChangeHandler}
                    onKeyUp={(event) => { inputKeyUpHandler(event.key); }}
                    onKeyDown={(event) => { inputKeyDownHandler(event.key); }}
                    onBlur={inputBlurHandler}
                />
            </div>
            <style jsx>{`
            .frame {
                width: 100%;
                height: 100%;
                position: relative;
                user-select: none;
            }

            .input {
                position: absolute;
                left: 0px;
                top: -1px;
                width: 100%;
                height: 100%;
                opacity: 1;
                border: none;
                padding: 0px;
                outline: none;
                color: #666;
                display: none;
            }

            .frame.editing .input {
                display: block;
            }
            `}</style>
        </>
    );
}