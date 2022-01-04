"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseThread = void 0;
const sirop_1 = require("sirop");
function parseThread(string) {
    const parser = new sirop_1.Parser();
    // Field
    parser.root({
        "expression": "<flag:public|private|safe> <type:$string> <name:$string> <_:=|;> [content^semicolon]",
        "validate": (matched) => {
            return true;
        }
    });
    parser.run(string);
}
exports.parseThread = parseThread;
