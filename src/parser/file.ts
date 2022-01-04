import { formatToExpr, Parser } from 'sirop';
import { ValidPath } from './global';
import { parseThread, ThreadPrototype } from './object/thread';

export interface FileDefinition {
    imports: string[][],
    threads: {[key: string]: {
        prototype: ThreadPrototype,
        flag: "public" | "private" | "local",
        isStatic: boolean,
    }}
}

export function parseFile(string: string): FileDefinition {

    const parser = new Parser();

    let def: FileDefinition = {
        imports: [],
        threads: {},
    }

    parser.onUncaught((token)=>{
        console.log("Uncaught Token:", token)
    })

    // semicolon
    parser.root({
        "expression": "<;:;>",
        "validate": ()=>true
    })

    // import
    parser.root({
        "expression": "<import:import> <pkg:$string^semicolon>",
        "validate": (matched) => {

            const namespace = matched.pkg.map(v=>v.content);
            const typescriptIsDump = matched.pkg.map(v=>v.content==null?"{.}":v.content);
    
            if (ValidPath.test(namespace.join(""))) {
                def.imports.push(typescriptIsDump);
                return true;
            } else {
                console.log("Invalid Path:", namespace.join(""))
                process.exit();
            }
            
        }
    })

    // Thread
    parser.root({
        "expression": "[flag:public|private|local] [static:static] <thread:thread> <name:$string> <content:$curly_bracket>",
        "validate": (matched) => {

            const isStatic = matched.static != null;
            const flag = matched.flag[0].content || "local";
            const name = matched.name[0].content;

            const content = matched.content[0].wrapperContent;

            if (typeof name !== "string") return false;
            if (flag !== "public" && flag !== "private" && flag !== "local") return false;
            if (content == null) return false;

            const proto = parseThread(content);

            def.threads[name] = {
                flag: flag,
                prototype: proto,
                isStatic: isStatic,
            };

            return true;

        }
    })

    parser.run(string);

    return def;

}
