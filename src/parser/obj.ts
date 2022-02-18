/* function */

import { Token } from "../lexer";

import { RIOFuncSignature, RIOFuncArg, RIOFunc } from '../rio';
import { EOF_ERR, EXPECTED_ERR } from "./err";
import { parseBlockStatement } from "./statement";

export function parseFuncSignature(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOFuncSignature, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    const access = tokens[pos].content;
    if (access == "public" || access == "private") {
        pos++;
        if (tokens[pos].type == "id") {
            const type = tokens[pos].content;
            pos++;
            if (tokens[pos].type == "id") {
                const name = tokens[pos].content;
                pos++;
                if (tokens[pos].content == "(") {
                    pos++;
                    const args: RIOFuncArg[] = [];
                    if (tokens[pos].content == ")") {
                        pos++;
                    } else {
                        while (true) {
                            if (tokens[pos].type == "eof") {
                                return EOF_ERR(tokens[pos]);
                            } else {
                                if (tokens[pos].type == "id") {
                                    const arg_type = tokens[pos].content;
                                    pos++;
                                    if (tokens[pos].type == "id") {
                                        const arg_name = tokens[pos].content;
                                        pos++;
                                        args.push({
                                            arg_type: arg_type,
                                            arg_name: arg_name,
                                        });
                                        if (tokens[pos].content == ")") {
                                            pos++;
                                            break;
                                        } else if (tokens[pos].content == ",") {
                                            pos++;
                                        } else {
                                            return EXPECTED_ERR("')' or ','", tokens, tokens[pos]);
                                        }
                                    } else {
                                        return EXPECTED_ERR("argument name", tokens, tokens[pos]);
                                    }
                                } else {
                                    return EXPECTED_ERR("argument type", tokens, tokens[pos]);
                                }
                            }
                        }
                    }
                    return {
                        pos: pos,
                        res: {
                            func_access: access,
                            func_type: type,
                            func_name: name,
                            func_args: args,
                        }
                    };
                }
            }
        }
    }
    return "invalid";
}

export function parseFunc(tokens: Token[], pos?: number): {
    pos: number, // position
    res: RIOFunc, // result
} | "invalid" | "error" {
    if (pos == null) pos = 0;
    const signature = parseFuncSignature(tokens, pos);
    if (signature == "error") {
        return "error";
    } else if (signature != "invalid") {
        pos = signature.pos;
        const block = parseBlockStatement(tokens, pos);
        if (block == "error") {
            return "error";
        } else if (block != "invalid") {
            return {
                pos: signature.pos,
                res: {...signature.res, func_block: block.res}
            }
        }
    }
    return "invalid";
}