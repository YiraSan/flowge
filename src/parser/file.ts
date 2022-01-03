import { Parser } from 'sirop';

export function parseFile(string: string) {

    const parser = new Parser();

    // Thread
    parser.root({
        "expression": "[flag:public|private|local] [static:static] <kind:thread> <name:$string> <content:$curly_bracket>",
        "validate": (matched) => {

            const isStatic = matched.static != null;

            const flag = 
                matched.flag != null ? 
                    matched.flag[0].content
                : "local";

            const name = matched.name[0].content;

            const content = matched.content[0].wrapperContent;

            console.log(isStatic, flag, name, content);

            return true;

        }
    })

    parser.run(string);

}

parseFile(`

static thread Main {



}

`)