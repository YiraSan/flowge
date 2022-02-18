#!/usr/bin/env node

import fs from 'fs';
import path from 'path';

import { tokenize } from '../lexer';
import { parseFile } from '../parser';

import { FlowgeProject } from '../rio';
import { Terminal } from './terminal';

const version = `${require('../../flowge.json').build.yellow} ${require("../../package.json").version}`;

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

let files: string[] = [];
function getFilesRecursively(directory: string) {
    fs.readdirSync(directory).forEach(file => {
        const absolute = path.join(directory, file);
        if (fs.statSync(absolute).isDirectory()) return getFilesRecursively(absolute);
        else return files.push(absolute);
    });
    return files;
}

if (commandArgs[0] === "init") {
    if (helpFlag) {
        Terminal.println(`Usage: ${"init".yellow} <name> [--force]`);
        Terminal.println(`Description: Create a new project in the current dir`);
    } else {
        if (typeof commandArgs[1] == "string") {
            const dir = fs.readdirSync(".");
            if (dir.length===0 || forceFlag) {
                if (dir.includes("build")) fs.rmSync("build", {"recursive": true});
                if (dir.includes("src")) fs.rmSync("src", {"recursive": true});
                fs.mkdirSync("src");
                fs.mkdirSync("build");
                fs.writeFileSync("src/main.flg", '// see: https://flowgedocs.github.io/', "utf-8");
                fs.writeFileSync("flowge.json", JSON.stringify({
                    name: commandArgs[1],
                    build: "initial",
                    run: "main",
                    license: null,
                    repo: "https://github.com/rantemma/flowge",
                }, null, 2), "utf-8");
            } else {
                Terminal.tag().space().println("`--force`".gray + " flag is needed to override this dir.");
            }
        } else {
            Terminal.tag().space().println("project name is missing".red);
        }
    }
} else if (
    !fs.existsSync("flowge.json") && commandArgs[0] !== "build") {
    Terminal.tag().space().println(`Please init a project with \`${"flg".yellow} init\``);
} else if (commandArgs[0] === "build") {
    if (helpFlag) {
        Terminal.println(`Usage: ${"build".yellow}`);
        Terminal.println(`Description: Build the current project`)
    } else {

        let project: FlowgeProject;

        try {
            project = JSON.parse(fs.readFileSync("flowge.json", "utf-8"));
        } catch {
            Terminal.tag().space().println("Invalid flowge project".red);
            process.exit();
        }

        if (typeof project.name !== "string" || project.name == "") {
            Terminal.tag().space().println("Empty flowge project name".red);
            process.exit();
        } else if (typeof project.build !== "string" || project.build == "") {
            Terminal.tag().space().println("Empty flowge project build".red);
            process.exit();
        } else if (typeof project.run !== "string" || project.run == "") {
            Terminal.tag().space().println("Empty flowge project entry point (run)".red);
            process.exit();
        }

        Terminal.tag().space().println("Check dependencies...".green);
        Terminal.println(Terminal.tab("- skipped".yellow));
        Terminal.tag().space().println("Build project...".green);

        let flgs: string[] = [];
        getFilesRecursively("src/").forEach(v => {
        if (v.endsWith(".flg")) 
            flgs.push(v);
        })
        flgs = flgs.map(v=>v.replace("src/", ""));

        Terminal.println(Terminal.tab("Parsing..."));

        let namespaces: any[] = [];
        let running: any[] = [];

        flgs.forEach((v,i)=>{
            // windows compatibility (yeah if someone absolutely want to use windows instead of wsl ;-;)
            v = v.replaceAll("\\", "/");
            const diplay = v.split("/").slice(0, -1).join(".")+"/"+v.split("/")[v.split("/").length-1];
            Terminal.clear(0);
            Terminal.println("    Parsing..." + ` ${i}/${flgs.length}`);
            const text = fs.readFileSync("src/"+v, "utf-8");
            const t = tokenize(text, "./src/"+v);
            if (v.includes("/")) {
                const r = parseFile(t);
                if (r == "error") {
                    process.exit();
                }
                namespaces.push({
                    name: v.split("/")[0],
                    funcs: r,
                });
            } else {
                const r = parseFile(t);
                if (r == "error") {
                    process.exit();
                }
                running.push({
                    name: v.split("/")[0].split(".flg")[0],
                    body: r,
                });
            }
        });

        Terminal.clear(0);
        Terminal.println("    Parsing..." + ` ${flgs.length}/${flgs.length}`.green);
        Terminal.println(Terminal.tab("Checking..."));

        const runs = running.filter(v=>v.name===project.run);
        if (runs.length==0){
            Terminal.clear(4).tag().space().println(`Missing project runnable '${project.run}'`.red);
            process.exit();
        }

        Terminal.println(Terminal.tab("Compiling..."));

        fs.writeFileSync("build/"+project.run+".rp", JSON.stringify({
            ...project,
            funcs: [...namespaces,...runs]
        }, null, "    "), "utf-8");
        
    }
} else if (helpFlag || commandArgs[0] === "help") {
    Terminal.ln();
    Terminal.tag().space().println("Need help ? You're on the right place :)").ln();
    const command = ["help", "init", "build"];
    Terminal.println("Command:\n"+Terminal.tab(command.join(", "))).ln();
    Terminal.println("Check command details with: `flg <command> --help`");
    Terminal.ln();
    Terminal.println("Version: " + version)
    Terminal.ln();
} else if (versionFlag) {
    Terminal.tag().space().println("Currently running on: " + version);
} else if (commandArgs[0] == null) {
    Terminal.tag().space().println(`Is missing a command, no ? Check \`${"flg".yellow} help\``);
} else {
    Terminal.tag().space().println(`Unknown Command. Check \`${"flg".yellow} help\``);
}