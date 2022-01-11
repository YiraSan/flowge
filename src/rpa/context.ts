import { RPAThread } from "./object/thread";

export class RPAContext {

    private threads: {
        thread: RPAThread,
        package: string,
    }[] = [];

    public addThread(pkg: string, thread: RPAThread){
        this.threads.push({package: pkg, thread: thread});
        return this;
    }

    /**
     * This method return array to prevent multiple same path.
     */
    public lookFor(path: [string, string]): (RPAThread)[] {

        let found: (RPAThread)[] = [];

        for (let i = 0; i < this.threads.length; i++) {

            if (this.threads[i].package === path[0] && this.threads[i].thread.getId()===path[1]) {
                found.push(this.threads[i].thread);
            }

        }

        return found;

    }

}