#!/usr/bin/env node

//#region import

const fs = require('fs');
const colors = require('colors');

//#endregion import

//#region init

const term = {

  rtag: () => {
    term.print("[ 🐲 Flowge ]".gray)
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

const version = `${require('./package.json').buildname.toUpperCase().yellow} ${require('./package.json').version}`;

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

    term.print(`Usage: ${"init".yellow} [--force]`);

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

      console.log("`--force`".gray, "flag is needed to override this dir.")

    }

  }

} else if (helpFlag || commandArgs[0] === "help") {
  term.ln();
  const command = [
    `help ${"Display this".gray}`,
    `init ${"Initialize a new project".gray}`
  ];
  term.println("Command:\n"+term.tab(command.join("\n")))
  term.ln();
  term.println("Version: " + version)
  term.ln();
} else if (versionFlag) {
  term.print(version);
} else if (commandArgs[0] == null) {
  term.print(`Is missing a command, no ? Check \`${"flg".yellow} help\``);
} else term.print(`Unknown Command. Check \`${"flg".yellow} help\``);

//#endregion command