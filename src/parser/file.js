"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseFile = void 0;
const sirop_1 = require("sirop");
const thread_1 = require("./object/thread");
function parseFile(entry) {
    const parser = new sirop_1.Parser();
    let def = {
        usings: [],
        threads: {},
    };
    parser.onUncaught((token) => {
        console.log("Uncaught Token:", token);
    });
    // use
    parser.root({
        expression: "<use> <path:$string^colon> <cl:$colon> <obj:$string|$curly_bracket> <;>",
        validate: (matched) => {
            const path = matched.path.filter(v => v.name !== "space").slice(0, -1);
            const obj = matched.obj[0].content || matched.obj[0].wrapperContent;
            if (obj == null)
                return false;
            // Namespace Check
            for (let i = 0; i < path.length; i++) {
                if (path[i].name !== "string" && path[i].name !== "dot")
                    return false;
            }
            if (typeof obj === "string") {
                def.usings.push({
                    "path": path.map(v => v.content) + "",
                    "used": obj === "*" ? "*" : [obj],
                });
            }
            else {
                throw "Unimplemented function";
            }
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
