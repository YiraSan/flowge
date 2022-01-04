#!/usr/bin/env node

//#region import

const fs = require('fs');

//#endregion import

//#region init

const term = {

  effect: {
    reset: "\x1b[0m",
    bright: "\x1b[1m",
    underscore: "\x1b[4m",
    reverse: "\x1b[7m",
  },

  textColor: {
    black: "\x1b[30m",
    red: "\x1b[31m",
    green: "\x1b[32m",
    yellow: "\x1b[33m",
    blue: "\x1b[34m",
    magenta: "\x1b[35m",
    cyan: "\x1b[36m",
    white: "\x1b[37m",
  },

  background: {
    black: "\x1b[40m",
    red: "\x1b[41m",
    green: "\x1b[42m",
    yellow: "\x1b[43m",
    blue: "\x1b[44m",
    magenta: "\x1b[45m",
    cyan: "\x1b[46m",
    white: "\x1b[47m",
  },

  rtag: () => {
    term.print(term.effect.bright + term.textColor.black + "[ 🐲 Flowge ]")
    return term;
  },

  print: (str) => {
    process.stdout.write(term.effect.reset + str + term.effect.reset);
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

  color: {

    yellow: (str) => {
      return term.textColor.yellow+str+term.effect.reset;
    },

    gray: (str) => {
      return term.effect.bright+term.textColor.black+str+term.effect.reset;
    }

  },

}

const version = `${term.color.yellow(require('./package.json').buildname.toUpperCase())} ${require('./package.json').version}`;

//#endregion init

//#region command

const args = process.argv.slice(2);

let flags = [];
let commandArgs = [];

for (let i = 0; i < args.length; i++) {

  if (args[i].startsWith("-")) {
    flags.push(args[i]);
  } else {
    commandArgs.push(args[i]);
  }

}

const helpFlag = (flags.includes("--help") || flags.includes("-h"));
const versionFlag = (flags.includes("--version") || flags.includes("-v"));

const forceFlag = (flags.includes("--force") || flags.includes("-f"));

if (commandArgs[0] === "init") {

  if (helpFlag) {

    term.print(`Usage: ${term.color.yellow("init")} [--force]`);

  } else {

    const dir = fs.readdirSync(".");

    if (dir.length===0||forceFlag) {

      if (dir.includes("project")) fs.rmSync("project", {"recursive": true});
      if (dir.includes("src")) fs.rmSync("src", {"recursive": true});
      if (dir.includes("build")) fs.rmSync("build", {"recursive": true});

      fs.mkdirSync("project");
      fs.mkdirSync("src");
      fs.mkdirSync("build");

      fs.writeFileSync("project/config.json", JSON.stringify({
        name: null,
        run: "program",
        build: {
          tag: "0.0.1",
          name: "initial"
        },
        license: "GPL-3.0",
        repo: "https://github.com/rantemma/flowge",
      }, null, 2), "utf-8");

      fs.writeFileSync("project/program.x.flg", 
      'println("Hello World!");'
      , "utf-8");

      // root file

      fs.writeFileSync("LICENSE", fs.readFileSync(__dirname + "\\LICENSE", "utf-8"), "utf-8");
      fs.writeFileSync("README.md", '# A Flowge Project\n\n> Oh wow what awesome stuff here!', 'utf-8');

      console.log("Project successfully initialized")

    } else {

      console.log(term.color.yellow("`--force`"), "flag is needed to override this dir.")

    }

  }

} else if (helpFlag || commandArgs[0] === "help") {
  term.ln();
  const command = [
    `help ${term.color.gray("Display this")}`,
    `init ${term.color.gray("Initialize a new project")}`
  ];
  term.println("Command:\n"+term.tab(command.join("\n")))
  term.ln();
  term.println("Version: " + version)
  term.ln();
} else if (versionFlag) {
  term.print(version);
} else if (commandArgs[0] == null) {
  term.print(`Is missing a command, no ? Check \`${term.color.yellow("flg")} help\``);
} else term.print(`Unknown Command. Check \`${term.color.yellow("flg")} help\``);

//#endregion command