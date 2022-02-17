export type RIOAccess = "public" | "private";

const accessKeyword = ["public", "private"];
export function isValidAccessKeyword(str: string){
    return accessKeyword.includes(str);
}

export interface RIOSignature {
    access: RIOAccess,
    name: string,
    type: string,
}

export interface RIOFunctionArg {
    name: string,
    type: string,
}

export interface RIOFunctionSignature extends RIOSignature {
    args: RIOFunctionArg[],
}

export interface RIOFunction extends RIOFunctionSignature {
    body: RIOInstruction[],
}

export interface RIOInstruction {
    type: string,
}

export interface RIOCallee extends RIOInstruction {
    type: "callee",
    args: RIOInstruction[],
}

export interface RIONamespace {
    functions: RIOFunction[],
}

export interface RIOProject {
    name: string,
    version: string,
    namespace: {[key: string]: RIONamespace},
    startup: RIOInstruction[],
}

const types = ["boolean", "int32", "void"];
export function isPrimitiveType(type: string) {
    return types.includes(type);
}