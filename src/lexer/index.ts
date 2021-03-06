const digits = "0123456789";
const alphas = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
const operators = "=+-/*<>";
const delimiters = ";(){}[],:";

const keywords = [
    "public", "private"
];

function isDelimiter(char: string){
    return delimiters.includes(char[0]);
}

function isOperator(char: string){
    return operators.includes(char[0]);
}

function isDigit(char: string) {
    return digits.includes(char[0]);
}

function isAlpha(char: string) {
    return alphas.includes(char[0]);
}

function isAlnum(char: string) {
    return isDigit(char) || isAlpha(char);
}

export interface Token {

    type: 
    "eof" | 
    "unknown" |
    "integer" |
    "float" |
    "string" |
    "char" |
    "id" |
    "keyword" | 
    "operator" | 
    "delimiter",

    content: string,

    begin: {
        column: number,
        line: number,
    },

    file: string,

    end: {
        column: number,
        line: number,
    }

}

export function tokenize(text: string, file: string): Token[] {

    const result: Token[] = [];

    let line = 1;
    let column = 1;

    for (let i = 0; i < text.length; i++) {

        if (text[i] == "\n") {
            column = 1;
            line++;
            continue;
        } else if (text[i] == "\r") {
            continue;
        } else if (text[i] == " ") {
            column++;
            continue;
        } else if (text[i] == '/' && text[i+1] == '/') {
            i++;
            while (true){
                i++;
                if (text[i] == '\n' || text[i] == '\r' || text[i] == null) {
                    break;
                }
            }
            i--;
            continue;
        }

        const begin = {
            line: line,
            column: column,
        };

        // id
        if (text[i] == "'" && text[i+2] == "'") {

            let char = text[i+1];

            i+=2;
            column+=3;

            result.push({
                type: "char",
                content: char,
                file: file,
                begin: begin,
                end: {
                    line: line,
                    column: column,
                }
            });

        } else if (text[i] == '"') {

            let full = "";
            let fmr = i+1;
            let fmrc = 1;

            while (true) {
                if (text[fmr]=='"') {
                    break;
                } else if (text[fmr]=='\n'||text[fmr]=='\r'||fmr>=text.length) {
                    break;
                } else {
                    full += text[fmr];
                    fmr++;
                    fmrc++;
                }
            }
        
            if (text[fmr]=='"') {
                i = fmr;
                column += fmrc+1;
                result.push({
                    type: "string",
                    content: full,
                    file: file,
                    begin: begin,
                    end: {
                        line: line,
                        column: column,
                    }
                });
            } else {
                column++;
                result.push({
                    type: "unknown",
                    content: text[i],
                    file: file,
                    begin: begin,
                    end: {
                        line: line,
                        column: column,
                    }
                });
            }

        } else if (isAlpha(text[i]) || text[i] == '_') {
            let full = text[i];
            i++;
            column++;
            while (true) {
                if (i < text.length) {
                    if (isAlnum(text[i]) || text[i] == '_') {
                        full += text[i];
                        i++;
                        column++;
                    } else {
                        i--;
                        break;
                    }
                } else {
                    break;
                }
            }
            let type: "id" | "keyword" = "id";
            if (keywords.includes(full)) {
                type = "keyword";
            }
            result.push({
                type: type,
                content: full,
                file: file,
                begin: begin,
                end: {
                    line: line,
                    column: column,
                }
            });
        } else if (isDigit(text[i])) {
            let full = text[i];
            let type: "integer" | "float" = "integer";
            i++;
            column++;
            while (true) {
                if (i < text.length) {
                    if (isDigit(text[i])) {
                        full += text[i];
                        i++;
                        column++;
                    } else {
                        i--;
                        break;
                    }
                } else {
                    break;
                }
            }
            if (i+2 < text.length) {
                if (text[i+1] == "." && isDigit(text[i+2])) {
                    full += ".";
                    i+=2;
                    column+=1;
                    while (true) {
                        if (i < text.length) {
                            if (isDigit(text[i])) {
                                full += text[i];
                                i++;
                                column++;
                            } else {
                                i--;
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                    type = "float";
                }
            }
            result.push({
                type: type,
                content: full,
                begin: begin,
                file: file,
                end: {
                    line: line,
                    column: column,
                }
            });
        } else if (isOperator(text[i])) {
            column++;
            result.push({
                type: "operator",
                content: text[i],
                begin: begin,
                file: file,
                end: {
                    line: line,
                    column: column,
                }
            });
        } else if (isDelimiter(text[i])) {
            column++;
            result.push({
                type: "delimiter",
                content: text[i],
                file: file,
                begin: begin,
                end: {
                    line: line,
                    column: column,
                }
            });
        } else {
            column++;
            result.push({
                type: "unknown",
                content: text[i],
                file: file,
                begin: begin,
                end: {
                    line: line,
                    column: column,
                }
            });
        }

    }

    result.push({
        type: "eof",
        content: "",
        file: file,
        begin: {
            line: -1,
            column: -1,
        },
        end: {
            line: -1,
            column: -1,
        },
    });

    return result;

}