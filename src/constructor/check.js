"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.typeCheck = void 0;
/**
 * Warning: This function use process.exit()
 */
function typeCheck(packages) {
    const keys = Object.keys(packages);
    for (let i = 0; i < keys.length; i++) {
        const current = {
            key: keys[i],
            package: packages[keys[i]],
        };
    }
}
exports.typeCheck = typeCheck;
