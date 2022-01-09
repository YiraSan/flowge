export interface Field {
    flag: "public" | "private",
    type: string,
    value: any,
}

export interface Method {
    flag: "public" | "private",
    args: {[key: string]: string}, // contain a type
    type: string,
    inst: string[],
}

export interface Thread {

    flag: "public" | "private",

    isStatic: boolean,

    fields: {[key: string]: Field},
    methods: {[key: string]: Method},

}

export interface Package {
    threads: {[key: string]: Thread},
    class: {},
    interface: {},
    structure: {},
}

export interface Packages {
    [key: string]: Package
}