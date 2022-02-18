// statement

export interface RIODeclarationStatement {
    dec_name: string,
    dec_type: string,
    dec_expr: RIOExpr,
}

export interface RIOAssignStatement {
    asg_name: string,
    asg_expr: RIOExpr,
}

export interface RIOReturnStatement {
    return_expr: RIOExpr,
}

export interface RIOBlockStatement {
    block_st: RIOStatement[],
}

export type RIOStatement = RIODeclarationStatement | RIOAssignStatement | RIOReturnStatement | RIOBlockStatement;

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

export interface RIOFunc extends RIOFuncSignature {
    func_block: RIOBlockStatement,
}

export type RIOObject = RIOFunc;

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
    build: string,
    license: string | null,
    repo: string | null,
}

export type RIOExpr = 
/* value */
RIONullExpr | RIOIntExpr | RIOBoolExpr | RIOFloatExpr | RIOCharExpr | RIOStrExpr | 
/* other */
RIOCalleeExpr | RIOCompExpr | RIOLogicExpr | RIOBinaryExpr | RIOIdExpr;