/* expression */

// (missing: logic, comparaison and binary expression)

import { Token } from "../lexer";
import { RIOCalleeExpr, RIOExpr, RIOFloatExpr, RIOCharExpr, RIOBoolExpr, RIOIntExpr, RIONullExpr, RIOStrExpr, RIOIdExpr } from '../rio';
import { EOF_ERR, EXPECTED_ERR, UNEXPECTED_ERR } from "./err";

export function parseNullExpr(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIONullExpr, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].content == "null") {
        pos++;
        return {
            pos: pos,
            res: {
                null_expr: null,
            },
        }
    }
    return "invalid";
}

export function parseBoolExpr(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOBoolExpr, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].content == "true") {
        pos++;
        return {
            pos: pos,
            res: {
                bool_expr: true,
            },
        }
    } else if (tokens[pos].content == "false") {
        pos++;
        return {
            pos: pos,
            res: {
                bool_expr: false,
            },
        }
    }
    return "invalid";
}

export function parseFloatExpr(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOFloatExpr, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].type == "float") {
        pos++;
        return {
            pos: pos,
            res: {
                float_expr: parseFloat(tokens[pos-1].content),
            },
        }
    }
    return "invalid";
}

export function parseCharExpr(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOCharExpr, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].type == "string") {
        pos++;
        return {
            pos: pos,
            res: {
                char_expr: tokens[pos-1].content,
            },
        }
    }
    return "invalid";
}

export function parseStrExpr(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOStrExpr, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].type == "string") {
        pos++;
        return {
            pos: pos,
            res: {
                str_expr: tokens[pos-1].content,
            },
        }
    }
    return "invalid";
}

export function parseIntExpr(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOIntExpr, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].type == "integer") {
        pos++;
        return {
            pos: pos,
            res: {
                int_expr: parseInt(tokens[pos-1].content),
            },
        }
    }
    return "invalid";
}

export function parseIdExpr(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOIdExpr, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].type == "id") {
        pos++;
        return {
            pos: pos,
            res: {
                id_name: tokens[pos-1].content,
            },
        }
    }
    return "invalid";
}

// note that calleeExpr has to test before idExpr
const expressions = [
    parseCharExpr, parseStrExpr, 
    parseIntExpr, parseBoolExpr, parseFloatExpr, parseNullExpr, 
    parseCalleeExpr, parseIdExpr];
export function parseExpr(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOExpr, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    for (let i = 0; i < expressions.length; i++) {
        const func = expressions[i];
        const result = func(tokens, pos);
        if (result == "error" || result != "invalid") {
            return result;
        }
    }
    return "invalid";
}

export function parseCalleeExpr(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOCalleeExpr, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].type == "id") {
        const name = tokens[pos].content;
        pos++;
        if (tokens[pos].content == '(') {
            pos++;
            const args: RIOExpr[] = [];
            if (tokens[pos].content == ')') {
                pos++;
            } else {
                while (true) {
                    if (tokens[pos].type == "eof") {
                        return EOF_ERR(tokens[pos]);
                    } else {
                        const parsed = parseExpr(tokens, pos);
                        if (parsed == "invalid") {
                            return UNEXPECTED_ERR(tokens, tokens[pos]);
                        } else if (parsed == "error") {
                            return parsed;
                        } else {
                            pos = parsed.pos;
                            args.push(parsed.res);
                            if (tokens[pos].content == ")") {
                                pos++;
                                break;
                            } else if (tokens[pos].content == ",") {
                                pos++;
                            } else {
                                return EXPECTED_ERR("')' or ','", tokens, tokens[pos]);
                            }
                        }
                    }
                }
            }
            return {
                pos: pos,
                res: {
                    callee_name: name,
                    callee_args: args,
                },
            }
        }
    }
    return "invalid";
}
