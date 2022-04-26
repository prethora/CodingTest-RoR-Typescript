import React, { useState } from "react";
import { IconButton } from "../IconButton";

export type ControlBarProps = {
    onNewItemClick: () => void
};

export function ControlBar({ onNewItemClick }: ControlBarProps) {
    return (
        <>
            <div className="frame">
                <IconButton name="plus" caption="Create Todo" onClick={onNewItemClick} />
            </div>
            <style jsx>{`
            .frame {
                padding: 12px 0px;
            }
            `}</style>
        </>
    );
}