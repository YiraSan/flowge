"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.madeRpa = void 0;
const context_1 = require("../rpa/context");
const thread_1 = require("../rpa/object/thread");
function madeRpa(files) {
    const context = new context_1.RPAContext();
    for (let i = 0; i < files.length; i++) {
        const PACKAGE = files[i].package;
        // THREADS
        const threads = Object.keys(files[i].def.threads);
        for (let t = 0; t < threads.length; t++) {
            const thread = files[i].def.threads[threads[t]];
            const obj = new thread_1.RPAThread(threads[t], thread.isStatic, thread.flag);
            // FIELDS
            const fields = Object.keys(thread.proto.fields);
            for (let f = 0; f < fields.length; f++) {
                const field = thread.proto.fields[fields[f]];
                obj.addField({
                    id: fields[f],
                    flag: field.flag,
                    type: field.type,
                    default: field.value,
                });
            }
            // push thread into context
            context.addThread(PACKAGE, obj);
        }
        // CLASSES
        // INTERFACE
        // STRUCTURE
    }
    return context;
}
exports.madeRpa = madeRpa;
