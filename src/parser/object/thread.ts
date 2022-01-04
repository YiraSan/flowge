import { Token } from 'rale';
import { Parser } from 'sirop';

interface ThreadPrototype {
    fields: {[key: string]: {
        flag: "public" | "private" | "safe",
        type: string,
        value: any,
    }},
}

export function parseThread(string: string|Token[]): ThreadPrototype {

    const parser = new Parser();

    let proto: ThreadPrototype = {
        fields: {},
    }

    // Field
    parser.root({
        "expression": "<flag:public|private|safe> <type:$string> <name:$string> <_:=|;> [content^semicolon]",
        "validate": (matched) => {

            const name = matched.name[0].content;
            const flag = matched.flag[0].content;
            const type = matched.type[0].content;

            if (typeof name !== "string") return false;
            if (typeof type !== "string") return false;
            if (flag !== "public" && flag !== "private" && flag !== "safe") return false;
            
            let value = null;

            if (matched["_"][0].content === "=") {

                if (matched.content != null) {

                    // todo: value logic

                } else {
                    console.log("Missing value");
                    process.exit();
                }

            }

            proto.fields[name] = {
                flag: flag,
                type: type,
                value: value,
            }

            return true;
        }
    })

    parser.run(string);

    return proto;

}