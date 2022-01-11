import { RPAField } from "../sub/field";

export class RPAThread {

    private id: string;
    private isStatic: boolean;
    private flag: "public" | "private";
    private fields: RPAField[] = [];
    
    public constructor(id: string, isStatic: boolean, flag: "public" | "private"){
        this.id = id;
        this.isStatic = isStatic;
        this.flag = flag;
    }

    public getId(){
        return this.id;
    }

    public getStatic(){
        return this.isStatic;
    }

    public getFlag(){
        return this.flag;
    }

    public getFields(){
        return this.fields;
    }

    public addField(field: RPAField){
        this.fields.push(field);
        return this;
    }

}