"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseMethodArgs = exports.ValidPath = void 0;
exports.ValidPath = /^(?:[a-z]\d*(?:\.[a-z])?)+$/i;
function parseMethodArgs(str) {
    if (str === "" || str === " ")
        return [];
    let _argu = [];
    let _args = str.split(",").map(v => v.split(" ").filter(v => v !== ""));
    for (let i = 0; i < _args.length; i++) {
        if (_args[i].length > 2) {
            throw "Unexpected token, there's too much token in a method argument";
        }
        else if (_args[i].length < 2) {
            throw "Missing argument parameters";
        }
        _argu.push({
            type: _args[i][0],
            name: _args[i][1],
        });
    }
    return _argu;
}
exports.parseMethodArgs = parseMethodArgs;
