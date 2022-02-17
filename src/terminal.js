const colors = require('colors');

var ln = 0;

function countLine(str){
    if (typeof str !== "string") return 0;
    return str.split("\n").length;
}

const term = {

    rtag: () => {
        term.print("[ 🐲 ".gray + "Flowge".black + " ]".gray)
        return term;
    },
  
    print: (str) => {
        ln += countLine(str);
        process.stdout.write(str+"".reset);
        return term;
    },
  
    space: () => {
        term.print(" ");
        return term;
    },
  
    ln: () => {
        term.print("\n");
        return term;
    },
  
    println: (str) => {
        term.print(str).ln();
        return term;
    },
  
    tab: (str) => {
        return "    "+str.split("\n").join("\n    ");
    }, 

    clear: (line) => {
        const clearLastLine = () => {
            process.stdout.moveCursor(0, -1); 
            process.stdout.clearLine(1); 
        }
        if (typeof line !== "number") {
            for (let i = 0; i < ln; i++) {
                clearLastLine();
                ln--;
            }
        } else {
            for (let i = 0; i < line; i++) {
                clearLastLine();
                ln--;
                if (ln == 0) {
                    break;
                }
            }
        }
        process.stdout.moveCursor(0, -1);
        return term;
    },
  
}

module.exports = { term };