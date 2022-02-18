/* statement */

import { Token } from "../lexer";

import { RIOAssignStatement, RIOStatement, RIODeclarationStatement, RIOReturnStatement, RIOBlockStatement } from '../rio/';
import { Terminal } from "../cli/terminal";
import { autoRestore, commonFilePos, EOF_ERR, EXPECTED_ERR, printError4, UNEXPECTED_ERR } from "./err";
import { parseExpr } from "./expr";

export function parseReferenceAsStatement(tokens: Token[], pos?: number): {
    pos: number, // position
    res: string, // result
} | "invalid" {
    if (pos == null) pos = 0;
    if (tokens[pos].type == "id") {
        const name = tokens[pos].content;
        pos++;
        if (tokens[pos].content == ";") {
            pos++;
            return {
                pos: pos,
                res: name,
            };
        }
    }
    return "invalid";
}

export function parseAssignStatement(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOAssignStatement, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].type == "id") {
        const name = tokens[pos].content;
        pos++;
        if (tokens[pos].content == "=") {
            pos++;
            const parsed = parseExpr(tokens, pos);
            if (parsed == "error") {
                return "error";
            } else if (parsed == "invalid") {
                if (tokens[pos].type == "eof") {
                    return EOF_ERR(tokens[pos]);
                } else {
                    return UNEXPECTED_ERR(tokens, tokens[pos]);
                }
            } else {
                pos = parsed.pos;
                if (tokens[pos].type == "eof") {
                    return EOF_ERR(tokens[pos]);
                } else if (tokens[pos].content == ";") {
                    pos++;
                    return {
                        pos: pos,
                        res: {
                            asg_name: name,
                            asg_expr: parsed.res,
                        }
                    }
                } else {
                    return EXPECTED_ERR("';'", tokens, tokens[pos]);
                }
            }
        }
    }
    return "invalid";
}

export function parseDeclaration(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIODeclarationStatement, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].type == "id") {
        const type = tokens[pos].content;
        pos++;
        const asign = parseAssignStatement(tokens, pos);
        if (asign == "error") {
            return "error";
        } else if (asign == "invalid") {
            let parsed = parseReferenceAsStatement(tokens, pos);
            if (parsed !== "invalid")  {
                printError4("Can't implicitly define identifier");
                autoRestore(tokens, tokens[parsed.pos-1]);
                Terminal.println(Terminal.tab(Terminal.tab("should be:"))).ln();
                Terminal.println(Terminal.tab(`${type} ${parsed.res} = null;`))
                commonFilePos(tokens[parsed.pos-1]);
                return "error";
            }
        } else {
            return {
                pos: asign.pos,
                res: {
                    dec_type: type,
                    dec_name: asign.res.asg_name,
                    dec_expr: asign.res.asg_expr,
                }
            }
        }
    }
    return "invalid";
}

// return before declaration
const expressions = [parseReturnStatement, parseDeclaration, parseAssignStatement, parseBlockStatement];
export function parseStatement(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOStatement, // result
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

export function parseReturnStatement(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOReturnStatement, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].content == "return") {
        pos++;
        const parsed = parseExpr(tokens, pos);
        if (parsed == "error") {
            return parsed;
        } else if (parsed == "invalid") {
            return UNEXPECTED_ERR(tokens, tokens[pos]);
        } else {
            pos = parsed.pos;
            if (tokens[pos].content == ";") {
                pos++;
                return {
                    pos: pos,
                    res: {
                        return_expr: parsed.res,
                    }
                }
            } else {
                return EXPECTED_ERR("';'", tokens, tokens[pos]);
            }
        }
    }
    return "invalid";
}

export function parseBlockStatement(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOBlockStatement, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    if (tokens[pos].content == '{') {
        pos++;
        const stms: RIOStatement[] = [];
        if (tokens[pos].content == '}') {
            pos++;
        } else {
            while (true) {
                const statement = parseStatement(tokens, pos);
                if (statement == "error") {
                    return "error";
                } else if (statement == "invalid") {
                    break;
                } else {
                    pos = statement.pos;
                    stms.push(statement.res);
                }
            }
        }
        return {
            pos: pos,
            res: {
                block_st: stms,
            }
        }
    }
    return "invalid";
}