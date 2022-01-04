"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseThread = void 0;
const sirop_1 = require("sirop");
function parseThread(string) {
    const parser = new sirop_1.Parser();
    let proto = {
        fields: {},
        methods: {},
    };
    parser.onUncaught((token) => {
        console.log("Uncaught Token:", token);
    });
    // Field
    parser.root({
        "expression": "<flag:public|private|safe> <type:$string> <name:$string> <_:=|;> [content^semicolon]",
        "validate": (matched) => {
            const name = matched.name[0].content;
            const flag = matched.flag[0].content;
            const type = matched.type[0].content;
            if (typeof name !== "string")
                return false;
            if (typeof type !== "string")
                return false;
            if (flag !== "public" && flag !== "private" && flag !== "safe")
                return false;
            let value = null;
            if (matched["_"][0].content === "=") {
                if (matched.content != null) {
                    // todo: value logic
                }
                else {
                    console.log("Missing value");
                    process.exit();
                }
            }
            proto.fields[name] = {
                flag: flag,
                type: type,
                value: value,
            };
            return true;
        }
    });
    // Method
    parser.root({
        expression: "<flag:public|private|safe> <type:$string> <name:$string> <args:$parenthesis> <content:$curly_bracket>",
        validate: (matched) => {
            console.log(matched);
            return true;
        }
    });
    parser.run(string);
    return proto;
}
exports.parseThread = parseThread;
