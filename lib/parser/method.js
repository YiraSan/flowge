"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseMethod = void 0;
const sirop_1 = require("sirop");
const global_1 = require("./global");
/**
 * Instruction (as string[]) are currently in phase to change
 */
function parseMethod(str, isAScript) {
    // instruction array
    let imports = [];
    let instruction = [];
    // build the parser
    const parser = new sirop_1.Parser();
    /**
     * todo: move that/change it
     */
    parser.onUncaught((token) => {
        console.log("Uncaught Token:", token);
    });
    // import
    parser.root({
        "expression": "<import:import> <pkg:$string^semicolon>",
        "validate": (matched) => {
            if (isAScript === true) {
                const namespace = matched.pkg.map(v => v.content);
                const typescriptIsDump = matched.pkg.map(v => v.content == null ? "{.}" : v.content);
                if (global_1.ValidPath.test(namespace.join(""))) {
                    imports.push(typescriptIsDump);
                    return true;
                }
                else {
                    console.log("Invalid Path:", namespace.join(""));
                    process.exit();
                }
            }
            else {
                console.log("Can't import in a method");
                process.exit();
            }
        }
    });
    // (un)mutable declaration
    parser.root({
        expression: "<type:$string> [mut:mut] <name:$string> <_:=|;> [content^semicolon]",
        validate: (matched) => {
            let isMutable = false;
            if (matched.mut != null)
                isMutable = true;
            const name = matched.name[0].content;
            const type = matched.type[0].content;
            if (name == null || type == null)
                return false;
            let content = null;
            if (matched["_"][0].content === "=") {
                // do logic...
            }
            else if (!isMutable) {
                console.log("Unmutable can't store null value, turn it to a mutable to store null until you reasign a value to it.");
                process.exit();
            }
            instruction.push(`declare ${name} as ${type} with ${content}`);
            return true;
        },
    });
    parser.run(str);
    return {
        instruction: instruction,
        imports: imports,
    };
}
exports.parseMethod = parseMethod;
