"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseFile = void 0;
const sirop_1 = require("sirop");
const global_1 = require("./global");
function parseFile(string) {
    const parser = new sirop_1.Parser();
    let def = {
        imports: [],
    };
    // import
    parser.root({
        "expression": "<import:import> <pkg:$string^semicolon>",
        "validate": (matched) => {
            const namespace = matched.pkg.map(v => v.content);
            const typescriptIsDump = matched.pkg.map(v => v.content == null ? "{.}" : v.content);
            if (global_1.ValidPath.test(namespace.join(""))) {
                def.imports.push(typescriptIsDump);
            }
            else {
                console.log("Invalid Path:", namespace.join(""));
                process.exit();
            }
            return true;
        }
    });
    // Thread
    parser.root({
        "expression": "[flag:public|private|local] [static:static] <kind:thread> <name:$string> <content:$curly_bracket>",
        "validate": (matched) => {
            const isStatic = matched.static != null;
            const flag = matched.flag != null ?
                matched.flag[0].content
                : "local";
            const name = matched.name[0].content;
            const content = matched.content[0].wrapperContent;
            console.log("static:", isStatic, "\nflag:", flag, "\nname:", name, content);
            return true;
        }
    });
    parser.run(string);
    return def;
}
exports.parseFile = parseFile;
console.log(parseFile("import test.test;"));
