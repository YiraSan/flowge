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

// Abstract Syntax Tree

pub const NumberExprNode = union(enum) {
    integer: struct {
        sign: bool,
        value: c_ulonglong,
    },

    pub fn init(alloc: Allocator) !*NumberExprNode {
        return try alloc.create(NumberExprNode);
    }

    pub fn deinit(self: *NumberExprNode, alloc: Allocator) void {
        alloc.destroy(self);
    }

    pub fn into_expr(self: *NumberExprNode, alloc: Allocator) !*ExprNode {
        const expr: *ExprNode = try alloc.create(ExprNode);
        expr.* = .{ .number = self };
        return expr;
    }

    pub fn codegen(self: *NumberExprNode, module: *Module) !types.LLVMValueRef {
        _ = module;
        return switch (self.*) {
            .integer => |v| {
                return core.LLVMConstInt(core.LLVMInt64Type(), v.value, v.sign);
            },
        };
    }
};

pub const ReferenceExprNode = struct {
    token_index: usize,
    identifier: []const u8,

    pub fn init(alloc: Allocator) !*ReferenceExprNode {
        return try alloc.create(ReferenceExprNode);
    }

    pub fn deinit(self: *ReferenceExprNode, alloc: Allocator) void {
        alloc.free(self.identifier);
        alloc.destroy(self);
    }

    pub fn into_expr(self: *ReferenceExprNode, alloc: Allocator) !*ExprNode {
        const expr: *ExprNode = try alloc.create(ExprNode);
        expr.* = .{ .reference = self };
        return expr;
    }

    pub fn codegen(self: *ReferenceExprNode, module: *Module) !types.LLVMValueRef {
        if (module.scope.contains(self.identifier)) {
            module.parser.err_token(self.token_index, "undeclared reference", 31);
            std.os.exit(0); // todo exit(1)
        }
        return module.scope.get(self.identifier);
    }
};

pub const BinaryExprNode = struct {
    lhs: *ExprNode,
    rhs: *ExprNode,
    operator: Operator,

    pub const Operator = enum {
        Add, Sub, Mul, Div,
        Superior, Inferior,

        pub fn parse(parser: *Parser) Operator {
            const operator = switch (parser.current_char()) {
                '+' => Operator.Add,
                '-' => Operator.Sub,
                '*' => Operator.Mul,
                '/' => Operator.Div,
                '>' => Operator.Superior,
                '<' => Operator.Inferior,
                else => parser.unexpected_token(),
            };
            parser.next_token(); // consume operator token
            return operator;
        }

        pub fn get_precedence(self: Operator) u8 {
            return switch (self) {
                Operator.Superior => 10,
                Operator.Inferior => 10,
                Operator.Add => 20,
                Operator.Sub => 20,
                Operator.Mul => 40,
                Operator.Div => 40,
            };
        }
    };

    pub fn init(alloc: Allocator) !*BinaryExprNode {
        return try alloc.create(BinaryExprNode);
    }

    pub fn deinit(self: *BinaryExprNode, alloc: Allocator) void {
        self.lhs.deinit(alloc);
        self.rhs.deinit(alloc);
        alloc.destroy(self);
    }

    pub fn into_expr(self: *BinaryExprNode, alloc: Allocator) !*ExprNode {
        const expr: *ExprNode = try alloc.create(ExprNode);
        expr.* = .{ .binary = self };
        return expr;
    }

    pub fn codegen(self: *BinaryExprNode, module: *Module) !types.LLVMValueRef {
        const left = try self.lhs.codegen(module);
        const right = try self.rhs.codegen(module);

        return switch (self.operator) {
            Operator.Add => {
                return core.LLVMBuildAdd(module.llvm_builder, left, right, "addtmp");
            },
            Operator.Sub => {
                return core.LLVMBuildSub(module.llvm_builder, left, right, "subtmp");
            },
            Operator.Mul => {
                return core.LLVMBuildMul(module.llvm_builder, left, right, "multmp");
            },
            Operator.Div => {
                return core.LLVMBuildSDiv(module.llvm_builder, left, right, "divtmp");
            },
            Operator.Superior => {
                return core.LLVMBuildICmp(module.llvm_builder, types.LLVMIntPredicate.LLVMIntSGT, left, right, "cmptmp");
            },
            Operator.Inferior => {
                return core.LLVMBuildICmp(module.llvm_builder, types.LLVMIntPredicate.LLVMIntSLT, left, right, "cmptmp");
            }
        };
    }
};

pub const CallExprNode = struct {
    callee: *ReferenceExprNode,
    args: std.ArrayList(*ExprNode),

    pub fn init(alloc: Allocator) !*CallExprNode {
        var expr: *CallExprNode = try alloc.create(CallExprNode);
        expr.args = std.ArrayList(*ExprNode).init(alloc);
        return expr;
    }

    pub fn deinit(self: *CallExprNode, alloc: Allocator) void {
        self.callee.deinit(alloc);
        for (self.args.items) |expr| {
            expr.deinit(alloc);
        }
        alloc.destroy(self);
    }

    pub fn into_expr(self: *CallExprNode, alloc: Allocator) !*ExprNode {
        const expr: *ExprNode = try alloc.create(ExprNode);
        expr.* = .{ .call = self };
        return expr;
    }

    pub fn codegen(self: *CallExprNode, module: *Module) !types.LLVMValueRef {
        const function = core.LLVMGetNamedFunction(module.llvm_module, self.callee.identifier);
        var args = std.ArrayList(types.LLVMValueRef).init(module.alloc);
        if (core.LLVMCountParams(function) != args.items.len) {
            module.parser.err_token(self.callee.token_index, try std.fmt.allocPrint(module.alloc, "expected {d} parameters, found {d}", .{args.items.len, core.LLVMCountParams(function)}), 31);
        }
        for (self.args.items) |arg| {
            args.append(try arg.codegen(module));
        }
        return core.LLVMBuildCall2(module.llvm_builder, types.LLVMCallConv.LLVMCCallConv, function, args.items.ptr, args.items.len, "calltmp");
    }
};

pub const ExprNode = union(enum) {
    number: *NumberExprNode,
    reference: *ReferenceExprNode,
    binary: *BinaryExprNode,
    call: *CallExprNode,

    pub fn deinit(self: *ExprNode, alloc: Allocator) void {
        switch (self.*) {
            .number => |number| {
                number.deinit(alloc);
            },
            .reference => |reference| {
                reference.deinit(alloc);
            },
            .binary => |binary| {
                binary.deinit(alloc);
            },
            .call => |call| {
                call.deinit(alloc);
            },
        }
        alloc.destroy(self);
    }

    pub fn codegen(self: *ExprNode, module: *Module) !types.LLVMValueRef {
        return switch (self.*) {
            .number => |node| try node.codegen(module),
            .reference => |node| try node.codegen(module),
            .binary => |node| try node.codegen(module),
            .call => |node| try node.codegen(module),
        };
    }
};


pub const VarTypeNode = struct {
    name: []const u8,
    type: *ReferenceExprNode,

    pub fn deinit(self: *VarTypeNode, alloc: Allocator) void {
        alloc.free(self.name);
        self.type.deinit(alloc);
        alloc.free(self.type);
        alloc.destroy(self);
    }
};

pub const PrototypeNode = struct {
    identifier: []const u8,
    token_index: usize,
    args: []*VarTypeNode,
    return_type: *ReferenceExprNode,

    pub fn init(alloc: Allocator, identifier: []const u8, token_index: usize) !*PrototypeNode {
        var prototype: *PrototypeNode = try alloc.create(PrototypeNode);
        prototype.token_index = token_index;
        const temp = try alloc.alloc(u8, identifier.len);
        std.mem.copyForwards(u8, temp, identifier);
        prototype.identifier = temp;
        return prototype;
    }

    pub fn deinit(self: *PrototypeNode, alloc: Allocator) void {
        alloc.free(self.identifier);
        for (self.args) |arg| {
            arg.deinit(alloc);
        }
        self.return_type.deinit(alloc);
        alloc.free(self.args);
        alloc.destroy(self);
    }
};

pub const FunctionNode = struct {
    prototype: *PrototypeNode,
    body: *ExprNode,

    pub fn init(alloc: Allocator, prototype: *PrototypeNode, body: *ExprNode) !*FunctionNode {
        var func = try alloc.create(FunctionNode);
        func.prototype = prototype;
        func.body = body;
        return func;
    }

    pub fn deinit(self: *FunctionNode, alloc: Allocator) void {
        self.prototype.deinit(alloc);
        self.body.deinit(alloc);
        alloc.destroy(self);
    }
};

// Parser

pub const Parser = struct {
    alloc: Allocator,
    file_path: []const u8,
    tokens: std.ArrayList(*Token),
    current_index: usize,

    pub fn init(alloc: Allocator, file_path: []const u8) !*Parser {
        var parser: *Parser = try alloc.create(Parser);
        parser.alloc = alloc;
        const temp: []u8 = try alloc.alloc(u8, file_path.len);
        std.mem.copyForwards(u8, temp, file_path);
        parser.file_path = temp;
        parser.tokens = std.ArrayList(*Token).init(alloc);
        parser.current_index = 0;
        var file = try File.init(alloc, file_path);
        defer file.deinit();
        var token = try file.next_token();
        defer token.deinit();
        while (token.token_type != TokenType.EOF) {
            try parser.tokens.append(token);
            token = try file.next_token();
        }
        return parser;
    }

    pub fn deinit(self: *Parser) void {
        self.alloc.free(self.file_path);
        for (self.tokens.items) |token| {
            token.deinit();
        }
        self.tokens.deinit();
        self.alloc.destroy(self);
    }

    fn err_token(self: *Parser, token_index: usize, message: []const u8, color: u8) void {
        const tk = self.tokens.items[token_index];
        print("{s}:{d}:{d} \u{001b}[{d}m{s}\u{001b}[0m\n", .{
            self.file_path, tk.line, tk.begin_column, color, message});
        print("  \u{001b}[30m{d} |\u{001b}[0m", .{tk.line});
        var ltc: usize = 0;
        for (0.., self.tokens.items) |i, token| {
            if (token.line == tk.line) {
                if (token.begin_column-ltc!=0) {
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

    fn logerr(self: *Parser, message: []const u8, color: u8) noreturn {
        self.err_token(self.current_index, message, color);
        std.os.exit(0); // todo: turn back to 1
    }

    fn unexpected_token(self: *Parser) noreturn {
        self.logerr("unexpected token", 31);
    }

    // real parser code here!!

    inline fn current(self: *Parser) *Token {
        return self.tokens.items[self.current_index];
    }

    inline fn current_char(self: *Parser) u8 {
        return self.current().content[0];
    }

    inline fn next_token(self: *Parser) void {
        self.current_index += 1;
        if (self.current_index >= self.tokens.items.len) {
            print("{s} \u{001b}[{d}m{s}\u{001b}[0m\n\n", .{
            self.file_path, 31, "unexpected end of file"});
            std.os.exit(0); // todo: exit(1)
        }
    }

    pub fn parseNumberExpr(self: *Parser) !*ExprNode {
        const expr = try NumberExprNode.init(self.alloc);
        expr.* = .{ .integer = .{ 
            .value = try std.fmt.parseInt(c_ulonglong, self.current().content, 0),
            .sign = true,
        } };
        self.next_token(); // consume number
        return expr.into_expr(self.alloc);
    }

    pub fn parseParenthesisExpr(self: *Parser) !*ExprNode {
        self.next_token(); // consume '('
        const expr = try self.parseExpr();
        if (self.current_char() != ')') 
            self.unexpected_token();
        self.next_token(); // consume ')'
        return expr;
    }

    pub fn parseReferenceExpr(self: *Parser) anyerror!*ExprNode {
        const ref = try ReferenceExprNode.init(self.alloc);
        ref.token_index = self.current_index;
        ref.identifier = self.current().content;
        self.next_token(); // consume identifier
        if (self.current_char() != '(')
            return ref.into_expr(self.alloc);
        const call = try CallExprNode.init(self.alloc);
        call.callee = ref;
        self.next_token(); // consume '('
        if (self.current_char() != ')') {
            while (true) {
                const expr = try self.parseExpr();
                try call.args.append(expr);

                if (self.current_char() == ')')
                    break;

                if (self.current_char() != ',')
                    return self.logerr("expected ')' or ','", 31);
                
                self.next_token();
            }
        }
        self.next_token(); // consume ')'
        return call.into_expr(self.alloc);
    }

    pub fn parsePrimaryExpr(self: *Parser) !*ExprNode {
        return switch (self.current().token_type) {
            .IDENTIFIER => try self.parseReferenceExpr(),
            .NUMBER => try self.parseNumberExpr(),
            .UNIQUE => switch (self.current_char()) {
                '(' => try self.parseParenthesisExpr(),
                '-' => {
                    self.next_token(); // consume '-'
                    return switch (self.current().token_type) {
                        .NUMBER => {
                            const expr = try self.parseNumberExpr();
                            expr.number.integer.sign = !expr.number.integer.sign;
                            return expr;
                        },
                        else => self.unexpected_token(),
                    };
                },
                else => self.unexpected_token(),
            },
            else => self.unexpected_token(),
        };
    }

    pub fn is_op(self: *Parser) u8 {
        return switch (self.current().token_type) {
            .OPERATOR => {

            },
            else => 0,
        };
    }

    pub fn parseBinOPRHS(self: *Parser, expr_prec: u8, _lhs: *ExprNode) !*ExprNode {
        var lhs = _lhs;
        _ = expr_prec;
        if (self.current().token_type != .OPERATOR) {
            return lhs;
        }
        while (true) {
            const op1 = BinaryExprNode.Operator.parse(self);
            
            var rhs = try self.parsePrimaryExpr();

            if (self.current().token_type == .OPERATOR) {
                const op2 = BinaryExprNode.Operator.parse(self);
                if (op1.get_precedence() < op2.get_precedence()) {
                    rhs = try self.parseBinOPRHS(op1.get_precedence() + 1, rhs);
                }
            }

            var temp = try BinaryExprNode.init(self.alloc);
            temp.lhs = lhs;
            temp.operator = op1;
            temp.rhs = rhs;

            lhs = try temp.into_expr(self.alloc);
        }
    }

    pub fn parseExpr(self: *Parser) anyerror!*ExprNode {
        return self.parseBinOPRHS(0, try self.parsePrimaryExpr());
    }

    pub fn parseVarType(self: *Parser) !*VarTypeNode {
        _ = self;
    }

    pub fn parsePrototype(self: *Parser) !*PrototypeNode {
        if (self.current().token_type == .IDENTIFIER) {
            var prototype = try PrototypeNode.init(self.alloc, self.current().content, self.current_index);
            self.next_token(); // eat identifier
            if (self.current_char() != '(') {
                self.logerr("expected '('", 31);
            }
            self.next_token(); // eat '('
            if (self.current_char() == ')') {
                self.next_token(); // eat ')'
            } else {
                std.debug.panic("todo!", .{});
            }
            if (self.current_char() == ':') {
                self.next_token(); // eat ':'
                prototype.return_type = (try self.parseReferenceExpr()).reference;
            } else {
                var ref = try ReferenceExprNode.init(self.alloc);
                ref.identifier = "void";
                ref.token_index = prototype.token_index;
                prototype.return_type = ref;
            }
            return prototype;
        } else {
            self.unexpected_token();
        }
    }

    pub fn parseFnDefinition(self: *Parser) !*FunctionNode {
        self.next_token(); // consume "fn"
        const proto = try self.parsePrototype();
        const body = try self.parseExpr();
        return try FunctionNode.init(self.alloc, proto, body);
    }

    pub fn parseExtern(self: *Parser) !*PrototypeNode {
        self.next_token(); // consume "extern"
        return try self.parsePrototype();
    }

    pub fn parseTopLevel(self: *Parser) anyerror!*TopLevel {
        while (self.current_index < self.tokens.items.len) {
            switch (self.current().token_type) {
                TokenType.IDENTIFIER => {
                    if (std.mem.eql(u8, self.current().content, "fn")) {
                        const func = try self.parseFnDefinition();
                        _ = func;
                        std.os.exit(0);
                    } else {
                        self.unexpected_token();
                    }
                },
                else => self.unexpected_token(),
            }
        }
        return TopLevel.init(self.alloc);
    }

};

pub const TopLevel = struct {
    pub fn init(alloc: Allocator) !*TopLevel {
        const toplevel = try alloc.create(TopLevel);
        return toplevel;
    }
};
