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

    let args: Args[] = [];

    let inType = false;

    let typePast = false;
    let namePast = false;

    let type = "";
    let name = "";

    for (let i = 0; i < str.length; i++) {

        if (namePast === false && typePast === false) {

            if (inType === false) {
                if (str[i] !== " ") {
                    inType = true;
                    type += str[i];
                }   
            } else {
                if (str[i] === " ") {
                    inType = false;
                    typePast = true;
                } else {
                    type += str[i];
                }
            }

        } else if (namePast === false && typePast === true) {

            if (str[i] === "," || i === str.length-1) {

                args.push({
                    name: i === str.length-1 ? name+str[i] : name,
                    type: type,
                })

                // reset
                inType = false;
                typePast = false;
                namePast = false;
                type = "";
                name = "";

            } else {
                name += str[i];
            }
            
        } else if (str[i] !== " ") {

            throw "Unable to parse unexpected token"

        }

    }

    return args;

}
