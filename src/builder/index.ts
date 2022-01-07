import { FileDefinition } from "../parser/file";
import { parseValue } from "../parser/global";
import { term } from "../terminal";
import { Field, Method, Packages } from "./types";

export function convert (files: {file: FileDefinition, path: string}[]): Packages {

    let packages: Packages = {};

    for (let i = 0; i < files.length; i++) {

        packages[files[i].path] = {
            threads: {},
            interface: {},
            class: {},
            structure: {}
        }

        // threads
        Object.keys(files[i].file.threads).forEach(v=> {

            // field
            let fields: {[key: string]: Field} = {};

            Object.keys(files[i].file.threads[v].proto.fields).forEach(ve=>{

                fields[ve] = {
                    flag: files[i].file.threads[v].proto.fields[ve].flag,
                    type: files[i].file.threads[v].proto.fields[ve].type,
                    value: parseValue(files[i].file.threads[v].proto.fields[ve].value)
                }

            })

            // method
            let methods: {[key: string]: Method} = {};

            Object.keys(files[i].file.threads[v].proto.methods).forEach(ve=>{

                let args: {[key: string]: string} = {};

                files[i].file.threads[v].proto.methods[ve].args.forEach(v=>{
                    if (args[v.name]!=null) {
                        term.rtag().space().println("".red);
                        process.exit();
                    }
                    args[v.name] = v.type;
                })

                methods[ve] = {
                    flag: files[i].file.threads[v].proto.methods[ve].flag,
                    type: files[i].file.threads[v].proto.methods[ve].type,
                    inst: files[i].file.threads[v].proto.methods[ve].instruction,
                    args: args,
                }

            })

            packages[files[i].path].threads[v] = {

                flag: files[i].file.threads[v].flag,
                isStatic: files[i].file.threads[v].isStatic,
                fields: fields,
                methods: methods,

            }

        })

    }

    return packages;

}