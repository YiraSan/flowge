const digits = "0123456789";
const alphas = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
const operators = "+=/*<>";
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

    end: {
        column: number,
        line: number,
    }

}

export function tokenize(text: string): Token[] {

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
        }

        const begin = {
            line: line,
            column: column,
        };

        // id
        if (isAlpha(text[i]) || text[i] == '_') {
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