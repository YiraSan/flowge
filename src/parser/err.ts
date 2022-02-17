import { Token } from "../lexer";
import { restoreLine } from "../lexer/util";
import { Terminal } from "../cli/terminal";

export function commonFilePos(token: Token) {
    Terminal.println(`${token.file}:${token.begin.line}:${token.begin.column}`.blue);
}

export function printError4(message: string) {
    Terminal.clear(4).tag().space().println(message.red);
}

export function autoRestore(tokens: Token[], token: Token) {
    Terminal.ln();
    Terminal.println(Terminal.tab(restoreLine(tokens, token.begin.line, token)));
}

export function EOF_ERR(token: Token): "error" {
    printError4(`End of file reached`);
    Terminal.println(`${token.file}`.blue)
    return "error";
}

export function EXPECTED_ERR(wht: string, tokens: Token[], token: Token): "error" {
    printError4(`Expected ${wht} instead of '${token.content}'`);
    autoRestore(tokens, token);
    commonFilePos(token);
    return "error";
}

export function UNEXPECTED_ERR(tokens: Token[], token: Token): "error" {
    printError4(`Unexpected '${token.content}'`);
    autoRestore(tokens, token);
    commonFilePos(token);
    return "error";
}