"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const context_1 = require("./context");
const thread_1 = require("./object/thread");
const context = new context_1.RPAContext();
context.addThread("net.yirasan", new thread_1.RPAThread("Main", true, "public"));
console.log(context.lookFor(["net.yirasan", "Main"]));
