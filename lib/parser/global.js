"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseMethodArgs = exports.parseValue = exports.ValidPath = void 0;
exports.ValidPath = /^(?:[a-z]\d*(?:\.[a-z])?)+$/i;
function parseValue(token) {
    throw "Unimplemented function";
}
exports.parseValue = parseValue;
function parseMethodArgs(str) {
    let args = [];
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
            }
            else {
                if (str[i] === " ") {
                    inType = false;
                    typePast = true;
                }
                else {
                    type += str[i];
                }
            }
        }
        else if (namePast === false && typePast === true) {
            if (str[i] === "," || i === str.length - 1) {
                args.push({
                    name: i === str.length - 1 ? name + str[i] : name,
                    type: type,
                });
                // reset
                inType = false;
                typePast = false;
                namePast = false;
                type = "";
                name = "";
            }
            else {
                name += str[i];
            }
        }
        else if (str[i] !== " ") {
            throw "Unable to parse unexpected token";
        }
    }
    args.forEach((v, i) => args[i].name = v.name.split(" ").join(""));
    return args;
}
exports.parseMethodArgs = parseMethodArgs;
