import { Token } from "rale";
import { Parser } from "sirop";
import { ValidPath } from "./global";

/**
 * Instruction (as string[]) are currently in phase to change
 */
export function parseMethod(str: string|Token[], isAScript: boolean): {
    instruction: string[],
    imports: string[][],
} {

    // instruction array

    let imports: string[][] = [];
    let instruction: string[] = [];

    // build the parser

    const parser = new Parser();

    /**
     * todo: move that/change it
     */
    parser.onUncaught((token)=>{
        console.log("Uncaught Token:", token)
    });

    // import
    parser.root({
        "expression": "<import:import> <pkg:$string^semicolon>",
        "validate": (matched) => {

            if (isAScript === true) {

                const namespace = matched.pkg.map(v=>v.content);
                const typescriptIsDump = matched.pkg.map(v=>v.content==null?"{.}":v.content);
        
                if (ValidPath.test(namespace.join(""))) {
                    imports.push(typescriptIsDump);
                    return true;
                } else {
                    console.log("Invalid Path:", namespace.join(""))
                    process.exit();
                }

            } else {
                console.log("Can't import in a method")
                process.exit();
            }
            
        }
    });

    // (un)mutable declaration
    parser.root({

        expression: "<type:$string> [mut:mut] <name:$string> <_:=|;> [content^semicolon]",

        validate: (matched) => {

            let isMutable = false;
            if (matched.mut!=null) isMutable = true;

            const name = matched.name[0].content;
            const type = matched.type[0].content;

            if (name == null || type == null) return false;

            let content = null;

            if (matched["_"][0].content === "=") {

                // do logic...

            } else if (!isMutable) {
                console.log("Unmutable can't store null value, turn it to a mutable to store null until you reasign a value to it.")
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