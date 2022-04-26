import React, { useEffect, useRef, useState } from "react";

export type MoveHandleProps = {
    onMoveStart: (x: number, y: number) => void;
    onMove: (x: number, y: number) => void;
    onMoveEnd: () => void;
};

export function MoveHandle({ onMoveStart, onMove, onMoveEnd }: MoveHandleProps) {
    const startedRef = useRef(false);
    useEffect(() => {
        let handlerMove = (ev: MouseEvent) => {
            if (startedRef.current) {
                onMove(ev.pageX, ev.pageY);
            }
        };
        let handlerUp = (ev: MouseEvent) => {
            if (startedRef.current) {
                startedRef.current = false;
                onMoveEnd();
            }
        };
        document.addEventListener("mousemove", handlerMove);
        document.addEventListener("mouseup", handlerUp);
        return () => {
            document.removeEventListener("mousemove", handlerMove);
            document.removeEventListener("mouseup", handlerUp);
        };
    }, []);
    return (
        <>
            <div className="frame"
                onMouseDown={(ev) => { startedRef.current = true; onMoveStart(ev.pageX, ev.pageY) }}
            >
                <div className="dot"></div>
                <div className="dot"></div>
                <div className="dot"></div>
            </div>
            <style jsx>{`
            .frame {
                display: flex;
                flex-direction: column;
                justify-content: space-between;
                height: 19px;
                position: relative;
                padding-left: 8px;
                left: 0px;
                top: 3px;
                width: 20px;
                cursor: pointer;
            }

            .dot {
                --size: 3px;
                border-radius: 3px;
                width: var(--size);
                height: var(--size);
                background-color: #ddd;
            }
            `}</style>
        </>
    );
}