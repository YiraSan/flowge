"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.toStable = void 0;
/**
 * Warning: This function use process.exit()
 */
function toStable(packages) {
    const keys = Object.keys(packages);
    let stable = {};
    // Turning packages to correct packages
    for (let i = 0; i < keys.length; i++) {
        const current = {
            key: keys[i],
            package: packages[keys[i]],
        };
        stable[current.key] = {
            threads: {},
            class: {},
            interface: {},
            structure: {},
        };
        const threads = Object.keys(current.package.threads);
        // threads
        for (let t = 0; t < threads.length; t++) {
            const thread = current.package.threads[threads[t]];
            stable[current.key].threads[threads[t]] = {
                fields: {},
                methods: {},
                flag: thread.flag,
                static: thread.isStatic,
            };
            const fields = Object.keys(thread.fields);
            // fields
            for (let f = 0; f < fields.length; f++) {
            }
        }
    }
    return stable;
}
exports.toStable = toStable;
