const colors = require('colors');

const term = {

    rtag: () => {
      term.print("[ 🐲 ".gray + "Flowge".black + " ]".gray)
      return term;
    },
  
    print: (str) => {
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
    }
  
  }

module.exports = { term };