import { TodoListActionKind } from "./types";

export const kindStringToEnum = (kind: string) => {
    switch (kind) {
        case "check":
            return TodoListActionKind.check;
        case "uncheck":
            return TodoListActionKind.uncheck;
        case "insert":
            return TodoListActionKind.insert;
        case "delete":
            return TodoListActionKind.delete;
        case "edit":
            return TodoListActionKind.edit;
        case "delete":
            return TodoListActionKind.delete;
        case "move":
            return TodoListActionKind.move;
        default:
            throw new Error(`Cannot convert unknown kind: ${kind}`);
    }
}

export const sleep = async (durationMsecs: number) => new Promise((resolve) => setTimeout(resolve, durationMsecs));

const generateUidTable = [
    ...Array.from({ length: 26 }, (x, i) => String.fromCharCode(65 + i)),
    ...Array.from({ length: 26 }, (x, i) => String.fromCharCode(97 + i)),
    ...Array.from({ length: 10 }, (x, i) => i.toString())
];
const generateUidLen = 12;
const generateUidRegexp = new RegExp(`^[a-zA-Z0-9]{${generateUidLen}}$`);
export const generateUid = () => Array.from({ length: generateUidLen }, () => generateUidTable[Math.floor(Math.random() * generateUidTable.length)]).join("");

export const isValidUid = (value: string) => generateUidRegexp.test(value);