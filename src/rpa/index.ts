import { RPAContext } from "./context";
import { RPAThread } from "./object/thread";

const context = new RPAContext();

context.addThread("net.yirasan", new RPAThread("Main", true, "public"));

console.log(context.lookFor(["net.yirasan", "Main"]));