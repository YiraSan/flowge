export type Tree = string | Tree[];

export interface BigTree {
    main: string,
    tree: Tree,
}

const char = {
    space: `  `,
    head: `└`,
    mid: `├`,
    linker: `┬`,
    inter: `─`,
    line: `│`,
};

function tree (_tree: Tree) {
    let _trace = '';
    for (let i = 0; i < _tree.length; i++) {
        const nextString = ()=>{
            for (let a = i; a < _tree.length; a++) {
                if (typeof _tree[a] !== "string") {
                    return true;
                }
            }
            return false;
        }
        if (typeof _tree[i] === "string") {
            if (_tree.length-1 === i) {
                _trace += `\n` + char.head + char.inter + char.inter + ` ` + _tree[i];
            } else {
                if (typeof _tree[i+1] === "string") {
                    _trace += `\n` + char.mid + char.inter + char.inter + ` ` + _tree[i];
                } else {
                    _trace += `\n`;
                    if (nextString()) {
                        _trace += char.mid;
                    } else _trace += char.head;
                    _trace += char.inter + char.linker + ` ` + _tree[i];
                }
            }
        } else {
            if (nextString()) {
                _trace += tree(_tree[i]).split("\n").map((v,i)=> i===0 ? ` `+v : char.line+` `+v).join("\n");
            } else {
                _trace += tree(_tree[i]).split("\n").map(v=>char.space+v).join("\n");
            }
        }
    }
    return _trace;
}

export function generateTrace (trace: BigTree) {
    let _trace = '';
    // message
    _trace += trace.main;
    // tree
    _trace += tree(trace.tree);
    return _trace;
}

console.log(generateTrace({
    "main": "Radi3nt... Une erreur en elle même.",
    "tree": [
        "Je m'amuse oui...",
        [
            "Ca te pose un problème hein ?",
            "HEIN ?",
            "Je m'amuse oui...",
            [
                "Ca te pose un problème hein ?",
                "HEIN ?",
                "Je m'amuse oui...",
                [
                    "Ca te pose un problème hein ?",
                    "HEIN ?"
                ],
                "OEOEOEOE)"
            ],
            "OEOEOEOE)"
        ],
        "OEOEOEOE)"
    ]
}))