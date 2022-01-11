#!/usr/bin/env node

//#region import

const fs = require('fs');
const path = require('path');

const { typeCheck } = require('./constructor/check');
const { convert } = require('./converter');
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

      console.log("Project successfully initialized")

    } else {

      console.log("`--force`".gray, "flag is needed to override this dir.")

    }

  }

} else if (commandArgs[0] === "build") {

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
    if (v.includes("\\")) {
      term.println(term.tab(term.tab("+ " + v.blue)))
      pc.push({file: parseFile(fs.readFileSync("src/"+v, "utf-8").replaceAll("\r", "")), path: v.split("\\").slice(0, -1).join(".")});
    } else {
      term.println(term.tab(term.tab("~ " + v.blue)))
    }
  });

  term.println(term.tab("Checking..."));

  const constructed = convert(pc);

  typeCheck(constructed);

  term.rtag().space().println("Build project...".green);

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
  term.println(version);
} else if (commandArgs[0] == null) {
  term.println(`Is missing a command, no ? Check \`${"flg".yellow} help\``);
} else term.println(`Unknown Command. Check \`${"flg".yellow} help\``);

//#endregion command