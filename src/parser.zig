const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const lexer = @import("./lexer.zig");
const File = lexer.File;
const Token = lexer.Token;
const TokenType = lexer.TokenType;

const project = @import("./project.zig");
const Module = project.Module;

const llvm = @import("llvm/llvm.zig");
const types = llvm.types;
const core = llvm.core;

// ParserUtil

pub const Tokens = struct {
    alloc: Allocator,
    file_path: []const u8,
    tokens: []*Token,
    current_index: usize,

    pub fn init(alloc: Allocator, file_path: []const u8) !*Tokens {
        var util = try alloc.create(Tokens);
        util.alloc = alloc;
        util.current_index = 0;
        const temp: []u8 = try alloc.alloc(u8, file_path.len);
        std.mem.copyForwards(u8, temp, file_path);
        util.file_path = temp;

        // append all tokens to util.tokens

        var list = std.ArrayList(*Token).init(alloc);
        defer list.deinit();

        const file = try File.init(alloc, file_path);
        defer file.deinit();

        var token = try file.next_token();
        while (token.token_type != TokenType.EOF) {
            try list.append(token);
            token = try file.next_token();
        }
        try list.append(token); // eof token

        util.tokens = try list.toOwnedSlice();

        return util;
    }

    pub fn deinit(self: *Tokens) void {
        self.alloc.free(self.file_path);
        for (self.tokens) |token| {
            token.deinit();
        }
        self.alloc.free(self.tokens);
        self.alloc.destroy(self);
    }

    pub fn println(self: *Tokens, message: []const u8, token_index: usize, color: u8) void {
        const tk = self.tokens[token_index];
        print("{s}:{d}:{d} \u{001b}[{d}m{s}\u{001b}[0m\n", .{ self.file_path, tk.line, tk.begin_column, color, message });
        print("  \u{001b}[30m{d} |\u{001b}[0m", .{tk.line});
        var ltc: usize = 0;
        for (0.., self.tokens) |i, token| {
            if (token.line == tk.line) {
                if (token.begin_column - ltc != 0) {
                    print(" ", .{});
                }
                ltc = token.end_column;
                if (i == token_index) {
                    print("\u{001b}[4;{d}m", .{color});
                }
                switch (token.token_type) {
                    .I_CHAR => print("'{s}'", .{token.content}),
                    .I_STR => print("\"{s}\"", .{token.content}),
                    else => print("{s}", .{token.content}),
                }
                if (i == token_index) {
                    print("\u{001b}[0m", .{});
                }
            }
        }
        print("\n\n", .{});
    }

    pub fn panic(self: *Tokens, message: []const u8, token_index: usize) noreturn {
        const panic_err = 31;
        self.println(message, token_index, panic_err);
        std.os.exit(0); // todo: replace by `std.os.exit(1)` (0 to avoid zig long stacktrace in debug)
    }

    pub fn warn(self: *Tokens, message: []const u8, token_index: usize) void {
        const warn_color = 33;
        self.println(message, token_index, warn_color);
    }

    pub inline fn unexpected_token(self: *Tokens) noreturn {
        self.panic("unexpected token", self.current_index);
    }

    // parser utils

    pub inline fn current(self: *Tokens) *Token {
        return self.tokens[self.current_index];
    }

    pub inline fn current_char(self: *Tokens) u8 {
        return self.current().content[0];
    }

    /// consuming while expecting something next
    pub inline fn next(self: *Tokens) void {
        self.consume();
        if (self.current().token_type == TokenType.EOF) {
            self.panic("unexpected end of file", self.current_index - 1);
        }
    }

    /// consuming something past
    pub inline fn consume(self: *Tokens) void {
        if (self.current().token_type != TokenType.EOF) {
            self.current_index += 1;
        }
    }
};

pub const PrimitiveType = enum {
    VOID,
    BOOL, // correspond to u1
    // NUMBER
    I8,
    I16,
    I32,
    I64,
    I128, // SIGNED
    U8,
    U16,
    U32,
    U64,
    U128, // UNSIGNED
    F16,
    F32,
    F64,
    F128, // REAL

    pub fn codegen(self: *PrimitiveType, module: *Module) types.LLVMTypeRef {
        _ = module;
        return switch (self.*) {
            .VOID => core.LLVMVoidType(),
            .BOOL => core.LLVMInt1Type(),
            .U8 => core.LLVMInt8Type(),
            .I8 => core.LLVMInt8Type(),
            .U16 => core.LLVMInt16Type(),
            .I16 => core.LLVMInt16Type(),
            .U32 => core.LLVMInt32Type(),
            .I32 => core.LLVMInt32Type(),
            .U64 => core.LLVMInt64Type(),
            .I64 => core.LLVMInt64Type(),
            .U128 => core.LLVMInt128Type(),
            .I128 => core.LLVMInt128Type(),
            .F16 => core.LLVMHalfType(),
            .F32 => core.LLVMFloatType(),
            .F64 => core.LLVMDoubleType(),
            .F128 => core.LLVMFP128Type(),
        };
    }
};

// Abstract Syntax Tree

pub const TypeAST = struct {
    token_index: usize,
    content: union(enum) {
        primitive: PrimitiveType,
        reference: *ReferenceAST,
    },

    pub fn parse(util: *Tokens) !*TypeAST {
        const typ = try util.alloc.create(TypeAST);
        typ.token_index = util.current_index;
        if (std.mem.eql(u8, util.current().content, "void")) {
            typ.content = .{ .primitive = PrimitiveType.VOID };
        } else if (std.mem.eql(u8, util.current().content, "bool")) {
            typ.content = .{ .primitive = PrimitiveType.BOOL };
        } else if (std.mem.eql(u8, util.current().content, "u8")) {
            typ.content = .{ .primitive = PrimitiveType.U8 };
        } else if (std.mem.eql(u8, util.current().content, "u16")) {
            typ.content = .{ .primitive = PrimitiveType.U16 };
        } else if (std.mem.eql(u8, util.current().content, "u32")) {
            typ.content = .{ .primitive = PrimitiveType.U32 };
        } else if (std.mem.eql(u8, util.current().content, "u64")) {
            typ.content = .{ .primitive = PrimitiveType.U64 };
        } else if (std.mem.eql(u8, util.current().content, "u128")) {
            typ.content = .{ .primitive = PrimitiveType.U128 };
        } else if (std.mem.eql(u8, util.current().content, "i8")) {
            typ.content = .{ .primitive = PrimitiveType.I8 };
        } else if (std.mem.eql(u8, util.current().content, "i16")) {
            typ.content = .{ .primitive = PrimitiveType.I16 };
        } else if (std.mem.eql(u8, util.current().content, "i32")) {
            typ.content = .{ .primitive = PrimitiveType.I32 };
        } else if (std.mem.eql(u8, util.current().content, "i64")) {
            typ.content = .{ .primitive = PrimitiveType.I64 };
        } else if (std.mem.eql(u8, util.current().content, "i128")) {
            typ.content = .{ .primitive = PrimitiveType.I128 };
        } else if (std.mem.eql(u8, util.current().content, "f16")) {
            typ.content = .{ .primitive = PrimitiveType.F16 };
        } else if (std.mem.eql(u8, util.current().content, "f32")) {
            typ.content = .{ .primitive = PrimitiveType.F32 };
        } else if (std.mem.eql(u8, util.current().content, "f64")) {
            typ.content = .{ .primitive = PrimitiveType.F64 };
        } else if (std.mem.eql(u8, util.current().content, "f128")) {
            typ.content = .{ .primitive = PrimitiveType.F128 };
        } else {
            const expr = try ReferenceAST.parse(util);
            defer util.alloc.destroy(expr);
            typ.content = .{ .reference = expr.reference };
            return typ;
        }
        util.consume(); // eat primitive type
        return typ;
    }

    pub fn deinit(self: *TypeAST, alloc: Allocator) void {
        switch (self.content) {
            .reference => |ref| {
                ref.deinit(alloc);
            },
            else => {},
        }
        alloc.destroy(self);
    }

    pub fn codegen(self: *TypeAST, module: *Module) types.LLVMTypeRef {
        return switch (self.content) {
            .reference => |_| {
                std.debug.panic("unsupported type", .{});
            },
            .primitive => |primitive| {
                return primitive.codegen(module);
            },
        };
    }
};

pub const BooleanAST = struct {
    token_index: usize,
    value: enum { True, False },

    pub fn parse(util: *Tokens) !*BooleanAST {
        const boolean = try util.alloc.create(BooleanAST);
        boolean.token_index = util.current_index;
        if (std.mem.eql(u8, util.current().content, "true")) {
            boolean.value = .True;
        } else if (std.mem.eql(u8, util.current().content, "false")) {
            boolean.value = .False;
        } else {
            util.panic("expected 'true' or 'false'", util.current_index);
        }
        util.consume();
        return boolean;
    }

    pub fn into_expr(self: *BooleanAST, alloc: Allocator) !*ExpressionAST {
        const expr = try alloc.create(ExpressionAST);
        expr.* = .{ .boolean = self };
        return expr;
    }

    pub fn deinit(self: *BooleanAST, alloc: Allocator) void {
        alloc.destroy(self);
    }

    pub fn codegen(self: *BooleanAST, module: *Module) types.LLVMValueRef {
        _ = module;
        return switch (self.value) {
            .True => core.LLVMConstInt(core.LLVMInt1Type(), 1, false),
            .False => core.LLVMConstInt(core.LLVMInt1Type(), 0, false),
        };
    }
};

pub const NumberAST = struct {
    token_index: usize,
    type: ?PrimitiveType,
    numeral: union(enum) {
        integer: struct {
            value: c_ulonglong,
            sign: bool,
        },
        real: f64,
    },

    pub fn parse(util: *Tokens) !*NumberAST {
        const number = try util.alloc.create(NumberAST);
        number.token_index = util.current_index;
        number.type = null;
        if (std.mem.indexOf(u8, util.current().content, ".") == null) { // integer
            number.numeral = .{ .integer = .{
                .value = try std.fmt.parseInt(c_ulonglong, util.current().content, 0),
                .sign = true,
            } };
        } else { // real
            number.numeral = .{ .real = try std.fmt.parseFloat(f64, util.current().content) };
        }
        util.consume();
        return number;
    }

    pub fn into_expr(self: *NumberAST, alloc: Allocator) !*ExpressionAST {
        const expr = try alloc.create(ExpressionAST);
        expr.* = .{ .number = self };
        return expr;
    }

    pub fn deinit(self: *NumberAST, alloc: Allocator) void {
        alloc.destroy(self);
    }

    pub fn codegen(self: *NumberAST, module: *Module) types.LLVMValueRef {
        return switch (self.numeral) {
            .integer => |integer| {
                if (self.type == null) {
                    return core.LLVMConstInt(core.LLVMInt32Type(), integer.value, integer.sign);
                } else {
                    return core.LLVMConstInt(self.type.?.codegen(module), integer.value, integer.sign);
                }
            },
            .real => |real| {
                if (self.type == null) {
                    return core.LLVMConstReal(core.LLVMDoubleType(), real);
                } else {
                    return core.LLVMConstReal(self.type.?.codegen(module), real);
                }
            },
        };
    }
};

pub const BinaryTreeAST = struct {
    left: *ExpressionAST,
    right: *ExpressionAST,
    token_index: usize, // refer to operator
    operator: Operator,

    pub fn parse(util: *Tokens, last_precedence: u8, left: *ExpressionAST) anyerror!*ExpressionAST {
        var lhs = left;
        while (true) {
            if (util.current().token_type == TokenType.OPERATOR) {
                const op_index = util.current_index;
                var op = BinaryTreeAST.Operator.parse(util);
                if (op.precedence() < last_precedence) {
                    util.current_index = op_index;
                    return lhs;
                } else {
                    var right = try ExpressionAST.parsePrimary(util);
                    if (util.current().token_type == TokenType.OPERATOR) {
                        const op2_index = util.current_index;
                        var op2 = BinaryTreeAST.Operator.parse(util);
                        if (op.precedence() < op2.precedence()) {
                            util.current_index = op2_index;
                            right = try BinaryTreeAST.parse(util, op.precedence() + 1, right);
                        }
                    }
                    var binary_tree = try util.alloc.create(BinaryTreeAST);
                    binary_tree.left = lhs;
                    binary_tree.right = right;
                    binary_tree.operator = op;
                    binary_tree.token_index = op_index;
                    lhs = try binary_tree.into_expr(util.alloc);
                }
            } else {
                return lhs;
            }
        }
    }

    pub fn into_expr(self: *BinaryTreeAST, alloc: Allocator) !*ExpressionAST {
        const expr = try alloc.create(ExpressionAST);
        expr.* = .{ .binary_tree = self };
        return expr;
    }

    pub fn deinit(self: *BinaryTreeAST, alloc: Allocator) void {
        self.left.deinit(alloc);
        self.right.deinit(alloc);
        alloc.destroy(self);
    }

    pub const Operator = enum {
        Add,
        Sub,
        Mul,
        Div,
        // Define,
        // Equal, GreaterThan, LessThan, GreaterOrEqual, LessOrEqual,

        pub fn parse(util: *Tokens) Operator {
            var op: Operator = undefined;
            if (std.mem.eql(u8, util.current().content, "+")) {
                op = Operator.Add;
            } else if (std.mem.eql(u8, util.current().content, "-")) {
                op = Operator.Sub;
            } else if (std.mem.eql(u8, util.current().content, "*")) {
                op = Operator.Mul;
            } else if (std.mem.eql(u8, util.current().content, "/")) {
                op = Operator.Div;
            } else {
                util.unexpected_token();
            }
            util.consume();
            return op;
        }

        pub fn precedence(self: Operator) u8 {
            return switch (self) {
                // Operator.Define => 5,
                // Operator.Equal => 10,
                // Operator.GreaterThan => 20,
                // Operator.GreaterOrEqual => 20,
                // Operator.LessThan => 20,
                // Operator.LessOrEqual => 20,
                Operator.Add => 30,
                Operator.Sub => 30,
                Operator.Mul => 50,
                Operator.Div => 50,
            };
        }
    };
};

pub const CallAST = struct {
    token_index: usize,
    reference: *ReferenceAST,
    expressions: []*ExpressionAST,

    pub fn into_expr(self: *CallAST, alloc: Allocator) !*ExpressionAST {
        const expr = try alloc.create(ExpressionAST);
        expr.* = .{ .call = self };
        return expr;
    }

    pub fn deinit(self: *CallAST, alloc: Allocator) void {
        for (self.expressions) |node| {
            node.deinit(alloc);
        }
        alloc.free(self.expressions);
        self.reference.deinit(alloc);
        alloc.destroy(self);
    }

    pub fn codegen(self: *CallAST, module: *Module) types.LLVMValueRef {
        const name = try module.alloc.dupeZ(u8, self.reference.identifier);
        defer module.alloc.free(name);
        const func = core.LLVMGetNamedFunction(module.llvm_module, name);

        if (core.LLVMCountParams(func) != self.expressions.len) {
            module.util.panic(std.fmt.allocPrint(module.alloc, "expected {d} params found {d}", .{ core.LLVMCountParams(func), self.expressions.len }), self.token_index);
        }

        const args = std.ArrayList(types.LLVMValueRef).init(module.alloc);
        defer args.deinit();
        for (self.expressions) |expr| {
            try args.append(expr.codegen(module));
        }
        const length = args.items.len;
        const z = try module.alloc.dupeZ(types.LLVMValueRef, try args.toOwnedSlice());

        const return_type = core.LLVMGetCalledFunctionType(func);
        return core.LLVMBuildCall2(module.llvm_builder, return_type, func, z, length, "calltmp");
    }
};

pub const ReferenceAST = struct {
    identifier: []const u8,
    token_index: usize,

    pub fn parse(util: *Tokens) !*ExpressionAST {
        const reference = try util.alloc.create(ReferenceAST);
        reference.token_index = util.current_index;
        if (std.mem.eql(u8, util.current().content, "void") or std.mem.eql(u8, util.current().content, "bool") or std.mem.eql(u8, util.current().content, "u8") or std.mem.eql(u8, util.current().content, "u16") or std.mem.eql(u8, util.current().content, "u32") or std.mem.eql(u8, util.current().content, "u64") or std.mem.eql(u8, util.current().content, "u128") or std.mem.eql(u8, util.current().content, "i8") or std.mem.eql(u8, util.current().content, "i16") or std.mem.eql(u8, util.current().content, "i32") or std.mem.eql(u8, util.current().content, "i64") or std.mem.eql(u8, util.current().content, "i128") or std.mem.eql(u8, util.current().content, "f16") or std.mem.eql(u8, util.current().content, "f32") or std.mem.eql(u8, util.current().content, "f64") or std.mem.eql(u8, util.current().content, "f128") or std.mem.eql(u8, util.current().content, "null") or std.mem.eql(u8, util.current().content, "fn") or std.mem.eql(u8, util.current().content, "extern") or std.mem.eql(u8, util.current().content, "if") or std.mem.eql(u8, util.current().content, "else") or std.mem.eql(u8, util.current().content, "var") or std.mem.eql(u8, util.current().content, "const") or std.mem.eql(u8, util.current().content, "true") or std.mem.eql(u8, util.current().content, "false") or std.mem.eql(u8, util.current().content, "return")) {
            util.unexpected_token();
        }
        const temp = try util.alloc.alloc(u8, util.current().content.len);
        std.mem.copyForwards(u8, temp, util.current().content);
        reference.identifier = temp;
        util.consume(); // eat name
        if (util.current_char() != '(') {
            return try reference.into_expr(util.alloc);
        } else {
            const call = try util.alloc.create(CallAST);
            call.token_index = util.current_index;
            call.reference = reference;
            util.next(); // eat '('
            var list = std.ArrayList(*ExpressionAST).init(util.alloc);
            defer list.deinit();
            if (util.current_char() != ')') {
                while (true) {
                    const expr = try ExpressionAST.parseBinary(util);
                    try list.append(expr);
                    if (util.current_char() == ')') {
                        break;
                    } else if (util.current_char() != ',') {
                        util.next(); // eat ','
                    } else {
                        util.panic("expected ',' or ')'", util.current_index);
                    }
                }
            }
            util.consume(); // eat ')'
            call.expressions = try list.toOwnedSlice();
            return try call.into_expr(util.alloc);
        }
    }

    pub fn into_expr(self: *ReferenceAST, alloc: Allocator) !*ExpressionAST {
        const expr = try alloc.create(ExpressionAST);
        expr.* = .{ .reference = self };
        return expr;
    }

    pub fn deinit(self: *ReferenceAST, alloc: Allocator) void {
        alloc.free(self.identifier);
        alloc.destroy(self);
    }
};

pub const ExpressionAST = union(enum) {
    number: *NumberAST,
    boolean: *BooleanAST,
    binary_tree: *BinaryTreeAST,
    reference: *ReferenceAST,
    body: *BodyAST,
    return_expr: struct {
        token_index: usize,
        expression: ?*ExpressionAST,
    },
    call: *CallAST,

    fn parsePrimary(util: *Tokens) anyerror!*ExpressionAST {
        return switch (util.current().token_type) {
            .IDENTIFIER => {
                if (std.mem.eql(u8, util.current().content, "true") or std.mem.eql(u8, util.current().content, "false")) {
                    return (try BooleanAST.parse(util)).into_expr(util.alloc);
                } else {
                    return try ReferenceAST.parse(util);
                }
            },
            .NUMBER => (try NumberAST.parse(util)).into_expr(util.alloc),
            .UNIQUE => switch (util.current_char()) {
                '(' => try parseParenthesis(util),
                '{' => (try BodyAST.parse(util)).into_expr(util.alloc),
                '-' => {
                    util.next(); // eat '-'
                    return switch (util.current().token_type) {
                        .NUMBER => {
                            const expr = try NumberAST.parse(util);
                            expr.numeral.integer.sign = !expr.numeral.integer.sign;
                            return expr.into_expr(util.alloc);
                        },
                        else => util.unexpected_token(),
                    };
                },
                else => util.unexpected_token(),
            },
            else => util.unexpected_token(),
        };
    }

    fn parseParenthesis(util: *Tokens) anyerror!*ExpressionAST {
        util.next(); // eat '('
        const expresion = try ExpressionAST.parseBinary(util);
        if (util.current_char() != ')') {
            util.unexpected_token();
        }
        util.consume(); // eat ')'
        return expresion;
    }

    pub fn parseBinary(util: *Tokens) anyerror!*ExpressionAST {
        return BinaryTreeAST.parse(util, 0, try ExpressionAST.parsePrimary(util));
    }

    pub fn deinit(self: *ExpressionAST, alloc: Allocator) void {
        switch (self.*) {
            .number => |node| node.deinit(alloc),
            .boolean => |node| node.deinit(alloc),
            .binary_tree => |node| node.deinit(alloc),
            .reference => |node| node.deinit(alloc),
            .body => |node| node.deinit(alloc),
            .return_expr => |node| {
                if (node.expression != null) {
                    node.expression.?.deinit(alloc);
                }
            },
            .call => |node| node.deinit(alloc),
        }
        alloc.destroy(self);
    }

    pub fn codegen(self: *ExpressionAST, module: *Module) types.LLVMValueRef {
        return switch (self.*) {
            .number => |node| node.codegen(module),
            .boolean => |node| node.codegen(module),
            .binary_tree => |node| node.codegen(module),
            .reference => |node| node.codegen(module),
            .body => |node| node.codegen(module),
            .return_expr => |node| {
                if (node.expression != null) {
                    const expr = node.expression.?.codegen(module);
                    return core.LLVMBuildRet(module.llvm_builder, expr);
                } else {
                    return core.LLVMBuildRetVoid(module.llvm_builder);
                }
            },
            .call => |node| node.codegen(module),
        };
    }
};

pub const BodyAST = struct {
    token_index: usize,
    expressions: []*ExpressionAST,

    pub fn parse(util: *Tokens) !*BodyAST {
        const body = try util.alloc.create(BodyAST);
        body.token_index = util.current_index;
        util.next(); // eat '{'
        var list = std.ArrayList(*ExpressionAST).init(util.alloc);
        defer list.deinit();
        while (util.current_char() != '}') {
            if (util.current().token_type == TokenType.IDENTIFIER and std.mem.eql(u8, util.current().content, "return")) {
                const ret = try util.alloc.create(ExpressionAST);
                util.next(); // eat "return"
                if (util.current_char() == ';') {
                    ret.* = .{ .return_expr = .{
                        .token_index = util.current_index - 1,
                        .expression = null,
                    } };
                } else {
                    ret.* = .{ .return_expr = .{
                        .token_index = util.current_index - 1,
                        .expression = try ExpressionAST.parseBinary(util),
                    } };
                }
                try list.append(ret);
            } else {
                try list.append(try ExpressionAST.parseBinary(util));
            }
            if (util.current_char() == ';') {
                util.next();
            } else {
                util.unexpected_token();
            }
        }
        util.consume(); // eat '}'
        body.expressions = try list.toOwnedSlice();
        return body;
    }

    pub fn into_expr(self: *BodyAST, alloc: Allocator) !*ExpressionAST {
        const expr = try alloc.create(ExpressionAST);
        expr.* = .{ .body = self };
        return expr;
    }

    pub fn deinit(self: *BodyAST, alloc: Allocator) void {
        for (self.expressions) |expr| {
            expr.deinit(alloc);
        }
        alloc.free(self.expressions);
        alloc.destroy(self);
    }
};

pub const ParameterAST = struct {
    name: []const u8,
    type: *TypeAST,

    pub fn parse(util: *Tokens) !*ParameterAST {
        const parameter = try util.alloc.create(ParameterAST);
        const temp = try util.alloc.alloc(u8, util.current().content.len);
        std.mem.copyForwards(u8, temp, util.current().content);
        parameter.name = temp;
        util.next(); // eat name
        if (util.current_char() != ':') {
            util.panic(try std.fmt.allocPrint(util.alloc, "expected ':' found '{s}'", .{util.current().content}), util.current_index);
        }
        util.next(); // eat ':'
        const typ = try TypeAST.parse(util);
        parameter.type = typ;
        return parameter;
    }

    pub fn deinit(self: *ParameterAST, alloc: Allocator) void {
        alloc.free(self.name);
        self.type.deinit(alloc);
        alloc.destroy(self);
    }
};

pub const PrototypeAST = struct {
    name: []const u8,
    parameters: []*ParameterAST,
    return_type: *TypeAST,

    pub fn parse(util: *Tokens) !*PrototypeAST {
        const prototype = try util.alloc.create(PrototypeAST);
        util.next(); // eat "fn"
        if (util.current().token_type == TokenType.IDENTIFIER) {
            const id_index = util.current_index;
            const temp = try util.alloc.alloc(u8, util.current().content.len);
            std.mem.copyForwards(u8, temp, util.current().content);
            prototype.name = temp;
            util.next(); // eat identifier
            if (util.current_char() == '(') {
                var list = std.ArrayList(*ParameterAST).init(util.alloc);
                defer list.deinit();
                util.next(); // eat '('
                while (util.current_char() != ')') {
                    try list.append(try ParameterAST.parse(util));
                    if (util.current_char() == ',') {
                        util.next(); // eat ','
                    } else if (util.current_char() != ')') {
                        util.panic(try std.fmt.allocPrint(util.alloc, "expected ',' or ')' found '{s}'", .{util.current().content}), util.current_index);
                    }
                }
                util.consume(); // eat ')'
                prototype.parameters = try list.toOwnedSlice();
                if (util.current_char() == ':') {
                    util.next(); // eat ':'
                    prototype.return_type = try TypeAST.parse(util);
                } else {
                    const typ = try util.alloc.create(TypeAST);
                    typ.content = .{ .primitive = PrimitiveType.VOID };
                    typ.token_index = id_index;
                    prototype.return_type = typ;
                }
            } else {
                util.panic(try std.fmt.allocPrint(util.alloc, "expected '(' found '{s}'", .{util.current().content}), util.current_index);
            }
        }
        return prototype;
    }

    pub fn deinit(self: *PrototypeAST, alloc: Allocator) void {
        alloc.free(self.name);
        for (self.parameters) |parameter| {
            parameter.deinit(alloc);
        }
        alloc.free(self.parameters);
        self.return_type.deinit(alloc);
        alloc.destroy(self);
    }
};

pub const FunctionAST = struct {
    prototype: *PrototypeAST,
    body: ?*BodyAST,

    pub fn parse(util: *Tokens) !*FunctionAST {
        const function = try util.alloc.create(FunctionAST);
        function.prototype = try PrototypeAST.parse(util);
        if (util.current_char() == '{') {
            function.body = try BodyAST.parse(util);
        } else if (util.current_char() == ';') {
            function.body = null;
            util.consume();
        } else {
            util.unexpected_token();
        }
        return function;
    }

    pub fn deinit(self: *FunctionAST, alloc: Allocator) void {
        self.prototype.deinit(alloc);
        if (self.body != null) {
            self.body.?.deinit(alloc);
        }
        alloc.destroy(self);
    }
};
