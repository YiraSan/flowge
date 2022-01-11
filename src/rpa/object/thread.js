"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RPAThread = void 0;
class RPAThread {
    constructor(id, isStatic, flag) {
        this.fields = [];
        this.id = id;
        this.isStatic = isStatic;
        this.flag = flag;
    }
    getId() {
        return this.id;
    }
    getStatic() {
        return this.isStatic;
    }
    getFlag() {
        return this.flag;
    }
    getFields() {
        return this.fields;
    }
    addField(field) {
        this.fields.push(field);
        return this;
    }
}
exports.RPAThread = RPAThread;
