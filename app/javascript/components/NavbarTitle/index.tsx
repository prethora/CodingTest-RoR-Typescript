import React, { useEffect } from "react";
import navbarTitle from "../../services/navbar_title";

type Props = {
    text: string;
};

const NavbarTitle: React.FC<Props> = ({ text }) => {
    useEffect(() => {
        navbarTitle.set(text);
    }, [text]);
    return null;
};

export default NavbarTitle;