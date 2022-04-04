export type ShowState = "none" | "updating" | "complete";

export type ShowStateChangeCallback = (showState: ShowState) => void;