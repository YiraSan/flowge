"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseThread = void 0;
const sirop_1 = require("sirop");
const global_1 = require("../global");
function parseThread(entry) {
    const parser = new sirop_1.Parser();
    let proto = {
        fields: {},
        methods: {},
    };
    parser.onUncaught((token) => {
        console.log("Uncaught Token:", token);
    });
    // Field Declaration
    parser.root({
        expression: "<flag:public|private> <type:$string> <name:$string> <;>",
        validate: (resolved) => {
            const flag = resolved.flag[0].content;
            if (flag !== "private" && flag !== "public")
                return false;
            const type = resolved.type[0].content;
            if (typeof type !== "string")
                return false;
            const name = resolved.name[0].content;
            if (typeof name !== "string")
                return false;
            if (proto.fields[name] != null) {
                console.log(`${name} is already declared`);
                process.exit();
            }
            proto.fields[name] = {
                flag: flag,
                type: type,
                value: null,
            };
            return true;
        }
    });
    // Field Set
    parser.root({
        expression: "<flag:public|private> <type:$string> <name:$string> <=> <value^semicolon>",
        validate: (resolved) => {
            const flag = resolved.flag[0].content;
            if (flag !== "private" && flag !== "public")
                return false;
            const type = resolved.type[0].content;
            if (typeof type !== "string")
                return false;
            const name = resolved.name[0].content;
            if (typeof name !== "string")
                return false;
            const value = resolved.value[0].content;
            if (typeof value !== "string")
                return false;
            proto.fields[name] = {
                flag: flag,
                type: type,
                value: value,
            };
            return true;
        }
    });
    // Methods
    parser.root({
        expression: "<flag:public|private> <type:$string> <name:$string> <args:$parenthesis> <content:$curly_bracket>",
        validate: (resolved) => {
            const flag = resolved.flag[0].content;
            if (flag !== "private" && flag !== "public")
                return false;
            const type = resolved.type[0].content;
            if (typeof type !== "string")
                return false;
            const name = resolved.name[0].content;
            if (typeof name !== "string")
                return false;
            const args = resolved.args[0].wrapperContent;
            if (typeof args !== "object")
                return false;
            proto.methods[name] = {
                flag: flag,
                args: (0, global_1.parseMethodArgs)(args.map(v => v.content).join("")),
                type: type,
                instruction: [],
            };
            return true;
        }
    });
    parser.parse(entry);
    return proto;
}
exports.parseThread = parseThread;
