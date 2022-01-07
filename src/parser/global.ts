import { Token } from "rale";

export const ValidPath = /^(?:[a-z]\d*(?:\.[a-z])?)+$/i;

export function parseValue(token: Token[]) {
    throw "Unimplemented function";
}

export interface Args {
    type: string,
    name: string,
}

export function parseMethodArgs(str: string): Args[] {

    if (str === "" || str === " ") return [];

    let _argu: Args[] = [];
    let _args = str.split(",").map(v=>v.split(" ").filter(v=>v!==""));

    for (let i = 0; i < _args.length; i++) {

        if (_args[i].length > 2) {
            throw "Unexpected token, there's too much token in a method argument";
        } else if (_args[i].length < 2) {
            throw "Missing argument parameters";
        }

        _argu.push({
            type: _args[i][0],
            name: _args[i][1],
        })

    }

    return _argu;

}
