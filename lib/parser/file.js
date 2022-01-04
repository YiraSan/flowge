"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseFile = void 0;
const sirop_1 = require("sirop");
const global_1 = require("./global");
const thread_1 = require("./object/thread");
function parseFile(string) {
    const parser = new sirop_1.Parser();
    let def = {
        imports: [],
        threads: {},
    };
    parser.onUncaught((token) => {
        console.log("Uncaught Token:", token);
    });
    // import
    parser.root({
        "expression": "<import:import> <pkg:$string^semicolon>",
        "validate": (matched) => {
            const namespace = matched.pkg.map(v => v.content);
            const typescriptIsDump = matched.pkg.map(v => v.content == null ? "{.}" : v.content);
            if (global_1.ValidPath.test(namespace.join(""))) {
                def.imports.push(typescriptIsDump);
                return true;
            }
            else {
                console.log("Invalid Path:", namespace.join(""));
                process.exit();
            }
        }
    });
    // Thread
    parser.root({
        "expression": "[flag:public|private|local] [static] <thread> <name:$string> <content:$curly_bracket>",
        "validate": (matched) => {
            const isStatic = matched.static != null;
            const flag = matched.flag != null ? matched.flag[0].content || "local" : "local";
            const name = matched.name[0].content;
            const content = matched.content[0].wrapperContent;
            if (typeof name !== "string")
                return false;
            if (flag !== "public" && flag !== "private" && flag !== "local")
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
    parser.run(string);
    return def;
}
exports.parseFile = parseFile;
