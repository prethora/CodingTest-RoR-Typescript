import React, { useEffect, useState } from "react";
import { Spinner } from "react-bootstrap";
import updating from "../../services/updating";
import { ShowState } from "../../services/updating/types";

type Props = {
};

const Updating: React.FC<Props> = ({ }) => {
    const [showState, setShowState] = useState<ShowState>("none");

    useEffect(() => {
        updating.setupOnBeforeUnload();
        return updating.subscribe((showState) => {
            setShowState(showState);
        });
    }, []);

    return (
        <>
            <div className={"frame " + showState}>
                <img className="tick" src="/images/tick.svg" />
                <div className="spinner">
                    <Spinner animation="border" style={{ height: 50, width: 50 }} />
                </div>
            </div>
            <style jsx>{`
            .frame {
                position: fixed;
                bottom: 20px;
                right: 20px;
                font-size: 19px;
                color: #ccc;
            }

            .spinner {
                opacity: 0;
                visibility: hidden;
                --duration: 0.25s;
                transition: opacity var(--duration), visibility var(--duration);
            }

            .frame.updating .spinner {
                --duration: 0.5s;
                opacity: 1;
                visibility: visible;
            }

            .tick {
                height: 50px;
                position: absolute;
                opacity: 0;
                visibility: hidden;
                --duration: 1s;
                transition: opacity var(--duration), visibility var(--duration);
            }
            
            .frame.complete .tick {
                opacity: 1;
                visibility: visible;
                --duration: 0.5s;
            }
            `}</style>
        </>
    );
};

export default Updating;