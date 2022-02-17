import colors from 'colors';

var ln = 0;

function countLine(str: string){
    if (typeof str !== "string") return 0;
    return str.split("\n").length;
}

export const Terminal = {

    tag() {
        Terminal.print("[ 🐲 ".gray + "Flowge".black + " ]".gray)
        return Terminal;
    },

    print(str: string) {
        ln += countLine(str);
        process.stdout.write(str+"".reset);
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
  
    println: (str: string) => {
        Terminal.print(str).ln();
        return Terminal;
    },
  
    tab: (str: string) => {
        return "    "+str.split("\n").join("\n    ");
    }, 

    clear: (line: number) => {
        const clearLastLine = () => {
            process.stdout.moveCursor(0, -1); 
            process.stdout.clearLine(1); 
        }
        for (let i = 0; i < line; i++) {
            clearLastLine();
            ln--;
            if (ln == 0) {
                break;
            }
        }
        process.stdout.moveCursor(0, -1);
        return Terminal;
    },

}