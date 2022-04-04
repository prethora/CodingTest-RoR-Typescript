import { NavbarTitleChangeCallback } from "./types";

class NavbarTitleService {
    subscribe(cb: NavbarTitleChangeCallback) {
        const callbackEntry = { cb };
        this.callbackEntries.push(callbackEntry);
        cb(this.title);
        return () => {
            this.callbackEntries = this.callbackEntries.filter((entry) => entry !== callbackEntry);
        };
    }

    set(title: string) {
        this.title = title;
        this.sendUpdateToCallbacks();
    }

    private title = "";
    private callbackEntries: { cb: NavbarTitleChangeCallback }[] = [];
    private sendUpdateToCallbacks() {
        this.callbackEntries.forEach(({ cb }) => cb(this.title));
    }
}

const navbarTitle = new NavbarTitleService();

export default navbarTitle;