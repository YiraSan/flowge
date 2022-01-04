#!/usr/bin/env node

const args = require('args');
const fs = require('fs');

const { parseFile } = require(__dirname + '\\lib\\parser\\file.js');

args.config.name = "flg";
const version = `${require('./package.json').buildname.toUpperCase()} ${require('./package.json').version}`
args.showVersion = ()=>{console.log(version)}

args.option("allow-override", "Allow overriding current dir", false);
args.option("use-gpl", "Use GPL-3.0 as License", false);

args.command("init", "Initialize a new project", (name, sub, options) => {

  const dir = fs.readdirSync(".");

  if (dir.length===0||options.allowOverride===true) {

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
      license: options.useGpl === true ? "GPL-3.0" : null,
      repo: "https://github.com/rantemma/flowge",
    }, null, 2), "utf-8");

    fs.writeFileSync("project/program.x.flg", 
    'println("Hello World!");'
    , "utf-8");

    // root file

    if (options.useGpl === true) fs.writeFileSync("LICENSE", fs.readFileSync(__dirname + "\\LICENSE", "utf-8"), "utf-8");

    fs.writeFileSync("README.md", '# A Flowge Project\n\n> Oh wow what awesome stuff here!', 'utf-8');

    console.log("Project successfully initialized")

  } else {

    console.log("\x1b[33m`--allow-override`\x1b[0m", "flag is needed to override this dir.")

  }

});
 


args.parse(process.argv)
