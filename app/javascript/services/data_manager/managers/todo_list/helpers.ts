import { TodoListActionKind } from "./types";

export const kindStringToEnum = (kind: string) => {
    switch (kind) {
        case "check":
            return TodoListActionKind.check;
        case "uncheck":
            return TodoListActionKind.uncheck;
        default:
            throw new Error(`Cannot convert unknown kind: ${kind}`);
    }
}

export const sleep = async (durationMsecs: number) => new Promise((resolve) => setTimeout(resolve, durationMsecs));