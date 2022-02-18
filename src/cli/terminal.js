const colors = require('colors');

export const Terminal = {

    tag: () => {
        Terminal.print("[ 🐲 ".gray + "Flowge".black + " ]".gray);
        return Terminal;
    },

    print: (qa) => {
        process.stdout.write(qa+"".reset);
        return Terminal;
    },
  
    space: () => {
        Terminal.print(" ");
        return Terminal;
    },
  
    ln: () => {
        Terminal.print("\n");
        return Terminal;
    },
  
    println: (str) => {
        Terminal.print(str).ln();
        return Terminal;
    },
  
    tab: (str) => {
        return "    "+str.split("\n").join("\n    ");
    }, 

    clear: (line) => {
        const clearLastLine = () => {
            process.stdout.moveCursor(0, -1); 
            process.stdout.clearLine(1); 
        }
        for (let i = 0; i < line; i++) {
            clearLastLine();
        }
        process.stdout.moveCursor(0, -1);
        return Terminal;
    },

}