#!/usr/bin/env node

//#region import

const fs = require('fs');
const path = require('path');

const { parseFile } = require('./parser/file');

const { term } = require('./terminal');

let files = [];

function getFilesRecursively(directory) {
  fs.readdirSync(directory).forEach(file => {
      const absolute = path.join(directory, file);
      if (fs.statSync(absolute).isDirectory()) return getFilesRecursively(absolute);
      else return files.push(absolute);
  });
  return files;
}

//#endregion import

//#region init

const version = `${require('../project/config.json').build.name.toUpperCase().yellow} ${require('../project/config.json').build.tag}`;

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

    term.println(`Usage: ${"init".yellow} [--force]`);
    term.println(`Description: Create a new project in the current dir`)

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

      fs.writeFileSync("src/program.xflg", 
      'import system;\nuse system:println;\nprintln("Hello World!");'
      , "utf-8");

      // root file

      fs.writeFileSync("LICENSE", fs.readFileSync(__dirname + "/../LICENSE", "utf-8"), "utf-8");
      fs.writeFileSync("README.md", '# A Flowge Project\n\n> Oh wow what awesome stuff here!', 'utf-8');

      term.rtag().space().println("Success!");

    } else {

      term.rtag().space().println("`--force`".gray + " flag is needed to override this dir.");

    }

  }

} else if (commandArgs[0] === "build") {

  if (helpFlag) {

    term.println(`Usage: ${"build".yellow}`);
    term.println(`Description: Build the current project, with optimisation`)

  } else {

    term.rtag().space().println("Check dependencies...".green);

    term.println(term.tab("- skipped".yellow))

    term.rtag().space().println("Construct files...".green);

    let flgs = [];

    getFilesRecursively("src/").forEach(v => {
      if (v.endsWith(".flg")) 
        flgs.push(v);
    })

    flgs = flgs.map(v=>v.replace("src/", ""));

    term.println(term.tab("Parsing..."));

    let pc = [];

    flgs.forEach(v=>{
      // windows compatibility
      v = v.replaceAll("\\", "/");
      if (v.includes("/")) {
        term.println(term.tab(term.tab("+ " + v.blue)))
        pc.push({file: parseFile(fs.readFileSync("src/"+v, "utf-8").replaceAll("\r", "")+ "\n"), path: v.split("/").slice(0, -1).join(".")});
      } else {
        term.println(term.tab(term.tab("~ " + v.blue)))
      }
    });

    term.println(term.tab("Checking..."));

    //const constructed = toStable(convert(pc));

    term.rtag().space().println("Build project...".green);
    
  }

} else if (helpFlag || commandArgs[0] === "help") {
  term.ln();
  term.rtag().space().println("Need help ? You're on the right place :)").ln();
  const command = ["help", "init", "build"];
  term.println("Command:\n"+term.tab(command.join(", "))).ln();
  term.println("Check command details with: `flg <command> --help`");
  term.ln();
  term.println("Version: " + version)
  term.ln();
} else if (versionFlag) {
  term.rtag().space().println("Currently running on: " + version);
} else if (commandArgs[0] == null) {
  term.rtag().space().println(`Is missing a command, no ? Check \`${"flg".yellow} help\``);
} else term.rtag().space().println(`Unknown Command. Check \`${"flg".yellow} help\``);

//#endregion command