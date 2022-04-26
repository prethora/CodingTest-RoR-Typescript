import React, { useState } from "react";

export type IconButtonProps = {
    name: string;
    caption?: string;
    size?: number;
    offHoverOpacity?: number;
    onClick?: () => void;
};

export function IconButton({
    name,
    caption,
    size = 16,
    offHoverOpacity = 0.75,
    onClick = () => { }
}: IconButtonProps) {
    return (
        <>
            <div style={{ display: "inline-block" }}>
                <div className="frame" onClick={onClick} style={{ fontSize: size }}>
                    <i className={`icon-${name} icon`} />
                    {caption ? (
                        <div className="caption">{caption}</div>
                    ) : null}
                </div>
            </div>
            <style jsx>{`
            .frame {
                display: flex;
                flex-direction: row;
                align-items: center;
                cursor: pointer;
                opacity: ${offHoverOpacity};
                transition: opacity 0.3s;          
            }

            .frame:hover {
                opacity: 1;
            }

            .icon {
                color: #666;
            }

            .caption {
                padding-left: 7px;
                color: #5656c3;
            }

            `}</style>
        </>
    );
}