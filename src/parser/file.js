"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseFile = void 0;
const sirop_1 = require("sirop");
const global_1 = require("./global");
const thread_1 = require("./object/thread");
function parseFile(entry) {
    const parser = new sirop_1.Parser();
    let def = {
        usings: [],
        imports: [],
        threads: {},
    };
    parser.onUncaught((token) => {
        console.log("Uncaught Token:", token);
    });
    // use
    parser.root({
        "expression": "<use> <path:$string^semicolon>",
        "validate": (matched) => {
            const namespace = matched.path.slice(0, -1).map(v => v.content);
            const typescriptIsDump = matched.path.slice(0, -1).map(v => v.content == null ? "{.}" : v.content);
            if (global_1.ValidPath.test(namespace.join(""))) {
                def.usings.push(typescriptIsDump.join(""));
                return true;
            }
            else {
                console.log("Invalid Path:", namespace.join(""));
                process.exit();
            }
        }
    });
    // import
    parser.root({
        "expression": "<import> <pkg:$string> <;>",
        "validate": (matched) => {
            if (matched.pkg[0].content != null) {
                def.imports.push(matched.pkg[0].content);
            }
            else
                return false;
            return true;
        }
    });
    // Thread
    parser.root({
        "expression": "[flag:public|private] [static] <thread> <name:$string> <content:$curly_bracket>",
        "validate": (matched) => {
            const isStatic = matched.static != null;
            const flag = matched.flag != null ? matched.flag[0].content || "private" : "private";
            const name = matched.name[0].content;
            const content = matched.content[0].wrapperContent;
            if (typeof name !== "string")
                return false;
            if (flag !== "public" && flag !== "private")
                return false;
            if (content == null)
                return false;
            const proto = (0, thread_1.parseThread)(content);
            def.threads[name] = {
                flag: flag,
                proto: proto,
                isStatic: isStatic,
            };
            return true;
        }
    });
    parser.parse(entry);
    return def;
}
exports.parseFile = parseFile;
