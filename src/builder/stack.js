"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateTrace = void 0;
const char = {
    space: `  `,
    head: `└`,
    mid: `├`,
    linker: `┬`,
    inter: `─`,
    line: `│`,
};
function tree(_tree) {
    let _trace = '';
    for (let i = 0; i < _tree.length; i++) {
        const nextString = () => {
            for (let a = i; a < _tree.length; a++) {
                if (typeof _tree[a] !== "string") {
                    return true;
                }
            }
            return false;
        };
        if (typeof _tree[i] === "string") {
            if (_tree.length - 1 === i) {
                _trace += `\n` + char.head + char.inter + char.inter + ` ` + _tree[i];
            }
            else {
                if (typeof _tree[i + 1] === "string") {
                    _trace += `\n` + char.mid + char.inter + char.inter + ` ` + _tree[i];
                }
                else {
                    _trace += `\n`;
                    if (nextString()) {
                        _trace += char.mid;
                    }
                    else
                        _trace += char.head;
                    _trace += char.inter + char.linker + ` ` + _tree[i];
                }
            }
        }
        else {
            if (nextString()) {
                _trace += tree(_tree[i]).split("\n").map((v, i) => i === 0 ? ` ` + v : char.line + ` ` + v).join("\n");
            }
            else {
                _trace += tree(_tree[i]).split("\n").map(v => char.space + v).join("\n");
            }
        }
    }
    return _trace;
}
function generateTrace(trace) {
    let _trace = '';
    // message
    _trace += trace.main;
    // tree
    _trace += tree(trace.tree);
    return _trace;
}
exports.generateTrace = generateTrace;
