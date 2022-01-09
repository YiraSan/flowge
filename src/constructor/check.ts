import { Packages } from "../converter/types";

/**
 * Warning: This function use process.exit()
 */
export function typeCheck (packages: Packages) {

    const keys = Object.keys(packages);

    for (let i = 0; i < keys.length; i++) {

        const current = {
            key: keys[i],
            package: packages[keys[i]],
        };

        

    }    

}