// statement

export interface RIODeclaration {
    dec_name: string,
    dec_type: string,
    dec_expr: RIOExpr,
}

export interface RIOAssign {
    asg_name: string,
    asg_expr: RIOExpr,
}

export type RIOStatement = 
    RIODeclaration | RIOAssign;

// object

export type RIOFuncAccess = "public" | "private";

export interface RIOFuncArg {
    arg_type: string,
    arg_name: string,
}

export interface RIOFuncSignature {
    func_access: RIOFuncAccess,
    func_type: string,
    func_name: string,
    func_args: RIOFuncArg[],
}

export type RIOObject = RIOFuncAccess | RIOFuncSignature | RIOFuncArg;

// expression

export interface RIOIntExpr {
    int_expr: number,
}

export interface RIOBoolExpr {
    bool_expr: boolean,
}

export interface RIOFloatExpr {
    float_expr: number,
}

export interface RIONullExpr {
    null_expr: null,
}

export interface RIOCharExpr {
    char_expr: string,
}

export interface RIOStrExpr {
    str_expr: string,
}

export interface RIOCalleeExpr {
    callee_name: string,
    callee_args: RIOExpr[],
}

export interface RIOBinaryExpr {
    binary_left: RIOExpr,
    binary_right: RIOExpr,
    binary_op: "+" | "-" | "*" | "/"
}

export interface RIOCompExpr {
    comp_left: RIOExpr,
    comp_right: RIOExpr,
    comp_op: "<" | "<=" | "==" | "!=" | ">=" | ">"
}

export interface RIOLogicExpr {
    logic_left: RIOExpr,
    logic_right: RIOExpr,
    logic_op: "&&" | "||"
}

export interface RIOIdExpr {
    id_name: string,
}

export interface FlowgeProject {
    name: string,
    run: string,
    version: string,
    license: string | null,
    repo: string | null,
}

export type RIOExpr = 
/* value */
RIONullExpr | RIOIntExpr | RIOBoolExpr | RIOFloatExpr | RIOCharExpr | RIOStrExpr | 
/* other */
RIOCalleeExpr | RIOCompExpr | RIOLogicExpr | RIOBinaryExpr | RIOIdExpr;