import { ShowState, ShowStateChangeCallback } from "./types";

class UpdatingService {
    subscribe(cb: ShowStateChangeCallback) {
        const callbackEntry = { cb };
        this.callbackEntries.push(callbackEntry);
        cb(this.showState);
        return () => {
            this.callbackEntries = this.callbackEntries.filter((entry) => entry !== callbackEntry);
        };
    }

    async requesting<T>(cb: () => Promise<T>, { silent = false }: { silent?: boolean; } = {}) {
        if (!silent) {
            if (this.requestingCount === 0) {
                this.clearAllAnimationTimeouts();
                this.setShowState("updating");
                if (this.updatingStartedAt === 0) this.updatingStartedAt = new Date().getTime();
            }
            this.requestingCount++;
        }

        const result = await cb();

        if (!silent) {
            this.requestingCount--;
            if (this.requestingCount === 0) {
                const elapsed = (new Date().getTime()) - this.updatingStartedAt;

                const animateCompletion = () => {
                    this.updatingStartedAt = 0;
                    this.setShowState("none");
                    this.noneShowStateTimeoutHandle = setTimeout(() => {
                        this.setShowState("complete");
                        this.completeShowStateTimeoutHandle = setTimeout(() => {
                            this.setShowState("none");
                        }, this.completeShowStateTimeoutMsecs) as unknown as number;
                    }, this.noneShowStateTimeoutMsecs) as unknown as number;
                };

                if (elapsed >= this.updatingMinimumDurationMsecs) {
                    animateCompletion();
                }
                else {
                    this.updatingMinimumDurationTimeoutHandle = setTimeout(animateCompletion, this.updatingMinimumDurationMsecs - elapsed) as unknown as number;
                }
            }
        }

        return result;
    }

    setupOnBeforeUnload() {
        window.addEventListener("beforeunload", (event) => {
            if (this.requestingCount > 0) {
                event.returnValue = "You have unsaved changes, are you sure you want to leave?";
            }
        });
    }

    private updatingStartedAt = 0;
    private readonly updatingMinimumDurationMsecs = 500;
    private readonly noneShowStateTimeoutMsecs = 250;
    private readonly completeShowStateTimeoutMsecs = 2000;
    private updatingMinimumDurationTimeoutHandle = 0;
    private noneShowStateTimeoutHandle = 0;
    private completeShowStateTimeoutHandle = 0;

    private requestingCount = 0;
    private showState: ShowState = "none";
    private setShowState(showState: ShowState) {
        this.showState = showState;
        this.sendUpdateToCallbacks();
    }

    private callbackEntries: { cb: ShowStateChangeCallback }[] = [];
    private sendUpdateToCallbacks() {
        this.callbackEntries.forEach(({ cb }) => cb(this.showState));
    }
    private clearAllAnimationTimeouts() {
        if (this.updatingMinimumDurationTimeoutHandle !== 0) {
            clearTimeout(this.updatingMinimumDurationTimeoutHandle);
            this.updatingMinimumDurationTimeoutHandle = 0;
        }
        if (this.noneShowStateTimeoutHandle !== 0) {
            clearTimeout(this.noneShowStateTimeoutHandle);
            this.noneShowStateTimeoutHandle = 0;
        }
        if (this.completeShowStateTimeoutHandle !== 0) {
            clearTimeout(this.completeShowStateTimeoutHandle);
            this.completeShowStateTimeoutHandle = 0;
        }
    }
}

const updating = new UpdatingService();

export default updating;