import { Token } from ".";

export function restoreLine(tokens: Token[], line: number, target?: Token): string {

    let restored = "";

    let count = 0;

    tokens.filter(v=>v.begin.line==line).forEach(v=>{
        if (v.type != "eof") {
            if (v == target) {
                count = restored.length;
            }
            restored += v.content;
            if (v.type != "unknown") {
                restored += " ";
            }
        }
    });

    if (target) {
        const r = `${" ".repeat(count)+"^".gray.repeat(target.content.length)}`
        if (r != "") {
            restored += "\n" + r;
        }
    }

    return restored;

}