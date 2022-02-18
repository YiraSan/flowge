import { Token } from "../lexer";
import { RIOFunc } from "../rio";
import { parseFunc } from "./obj";

export function parseFile(tokens: Token[]): RIOFunc[] | "error" {
    let pos = 0;
    const funcs: RIOFunc[] = [];
    while (true) {
        const func = parseFunc(tokens, pos);
        if (func == "error") {
            return "error";
        } else if (func == "invalid") {
            break;
        } else {
            funcs.push(func.res);
            pos = func.pos;
        }
    }
    return funcs;
}