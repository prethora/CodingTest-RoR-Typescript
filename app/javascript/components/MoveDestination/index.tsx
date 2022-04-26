import React, { } from "react";

export type MoveDestinationProps = {
    verticalShift?: number;
    height?: number;
    show: boolean;
};

export function MoveDestination({ verticalShift = 0, height = 4, show }: MoveDestinationProps) {
    return (
        <>
            {show ? (
                <div className="frame">
                    <div className="line"></div>
                </div>) : null}

            <style jsx>{`
            .frame {
                height: 0px;
                position: relative;
                top: ${verticalShift}px;
            }
            
            .line {
                width: 100%;
                position: absolute;
                left: 0px;
                top: -2px;
                height: ${height}px;
                background-color: #bbb;
                z-index: 11;
            }
            `}</style>
        </>
    );
}