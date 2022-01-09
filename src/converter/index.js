"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.convert = void 0;
const global_1 = require("../parser/global");
const terminal_1 = require("../terminal");
function convert(files) {
    let packages = {};
    for (let i = 0; i < files.length; i++) {
        packages[files[i].path] = {
            threads: {},
            interface: {},
            class: {},
            structure: {}
        };
        // threads
        Object.keys(files[i].file.threads).forEach(v => {
            // field
            let fields = {};
            Object.keys(files[i].file.threads[v].proto.fields).forEach(ve => {
                fields[ve] = {
                    flag: files[i].file.threads[v].proto.fields[ve].flag,
                    type: files[i].file.threads[v].proto.fields[ve].type,
                    value: (0, global_1.parseValue)(files[i].file.threads[v].proto.fields[ve].value)
                };
            });
            // method
            let methods = {};
            Object.keys(files[i].file.threads[v].proto.methods).forEach(ve => {
                let args = {};
                files[i].file.threads[v].proto.methods[ve].args.forEach(v => {
                    if (args[v.name] != null) {
                        terminal_1.term.rtag().space().println("".red);
                        process.exit();
                    }
                    args[v.name] = v.type;
                });
                methods[ve] = {
                    flag: files[i].file.threads[v].proto.methods[ve].flag,
                    type: files[i].file.threads[v].proto.methods[ve].type,
                    inst: files[i].file.threads[v].proto.methods[ve].instruction,
                    args: args,
                };
            });
            packages[files[i].path].threads[v] = {
                flag: files[i].file.threads[v].flag,
                isStatic: files[i].file.threads[v].isStatic,
                fields: fields,
                methods: methods,
            };
        });
    }
    return packages;
}
exports.convert = convert;
