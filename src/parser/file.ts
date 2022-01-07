import { Parser } from 'sirop';
import { ValidPath } from './global';
import { parseThread, ThreadPrototype } from './object/thread';

export interface FileDefinition {
    imports: string[],
    threads: {[key: string]: {
        proto: ThreadPrototype,
        flag: "public" | "private",
        isStatic: boolean,
    }}
}

export function parseFile(entry: string): FileDefinition {

    const parser = new Parser();

    let def: FileDefinition = {
        imports: [],
        threads: {},
    }

    parser.onUncaught((token)=>{
        console.log("Uncaught Token:", token)
    })

    // import
    parser.root({
        "expression": "<import> <pkg:$string^semicolon>",
        "validate": (matched) => {
            
            const namespace = matched.pkg.slice(0, -1).map(v=>v.content);
            const typescriptIsDump = matched.pkg.slice(0, -1).map(v=>v.content==null?"{.}":v.content);
    
            if (ValidPath.test(namespace.join(""))) {
                def.imports.push(typescriptIsDump.join(""));
                return true;
            } else {
                console.log("Invalid Path:", namespace.join(""))
                process.exit();
            }
            
        }
    })

    // Thread
    parser.root({
        "expression": "[flag:public|private] [static] <thread> <name:$string> <content:$curly_bracket>",
        "validate": (matched) => {

            const isStatic = matched.static != null;
            const flag = matched.flag != null ? matched.flag[0].content || "private" : "private";
            const name = matched.name[0].content;

            const content = matched.content[0].wrapperContent;

            if (typeof name !== "string") return false;
            if (flag !== "public" && flag !== "private") return false;
            if (content == null) return false;

            const proto = parseThread(content);

            def.threads[name] = {
                flag: flag,
                proto: proto,
                isStatic: isStatic,
            };

            return true;

        }
    })

    parser.parse(entry);

    return def;

}
