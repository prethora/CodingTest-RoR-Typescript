import React, { useEffect, useState } from "react";
import { Container, Navbar } from "react-bootstrap";
import navbarTitle from "../../services/navbar_title";
import Updating from "../Updating";

type Props = {
};

const App: React.FC<Props> = ({ children }) => {
    const [title, setTitle] = useState("");

    useEffect(() => {
        return navbarTitle.subscribe((title) => setTitle(title));
    }, []);

    return (
        <>
            <Navbar bg="light" expand="lg">
                <Container className="frame" style={{ justifyContent: "center" }} >
                    <Navbar.Brand>
                        <div className="title-version">
                            <span className="title">{title}</span>
                            <span className="version">{title ? "0.0.1" : ""}</span>
                        </div>
                    </Navbar.Brand>
                </Container>
            </Navbar>
            <Updating />
            <div>
                {children}
            </div>
            <style jsx>{`
            .title-version {
                display: flex;
                flex-direction: row;
                align-items: center;
            }

            .title {
                font-size: 27px;
                font-weight: 500;
                color: #333;
            }

            .version {
                margin-left: 12px;
                color: #999;
                font-size: 18px;
            }
            `}</style>
        </>
    );
};

export default App;