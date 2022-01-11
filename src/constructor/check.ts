import { Method, Packages } from "../converter/types";

export interface StableField {
    value: boolean | string | number | null,
}

export interface StableThread {
    fields: {[key: string]: StableField},
    flag: "public" | "private",
    static: boolean,
    methods: {[key: string]: Method},
}

export interface StablePackage {
    threads: {[key: string]: StableThread},
    class: {},
    interface: {},
    structure: {},
}

export interface StablePackages  {
    [key: string]: StablePackage
}

/**
 * Warning: This function use process.exit()
 */
export function toStable (packages: Packages): StablePackages {

    const keys = Object.keys(packages);

    let stable: StablePackages = {};

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