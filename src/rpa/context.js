"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RPAContext = void 0;
class RPAContext {
    constructor() {
        this.threads = [];
    }
    addThread(pkg, thread) {
        this.threads.push({ package: pkg, thread: thread });
        return this;
    }
    /**
     * This method return array to prevent multiple same path.
     */
    lookFor(path) {
        let found = [];
        for (let i = 0; i < this.threads.length; i++) {
            if (this.threads[i].package === path[0] && this.threads[i].thread.getId() === path[1]) {
                found.push(this.threads[i].thread);
            }
        }
        return found;
    }
}
exports.RPAContext = RPAContext;
