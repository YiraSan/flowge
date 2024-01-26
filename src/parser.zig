const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const lexer = @import("./lexer.zig");
const File = lexer.File;
const Token = lexer.Token;
const TokenType = lexer.TokenType;

const llvm = @import("llvm/llvm.zig");
const types = llvm.types;

// Abstract Syntax Tree

pub const NumberExprNode = union(enum) {
    integer: i64,

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

    pub fn codegen(self: *NumberExprNode) types.LLVMValueRef {
        _ = self;
        
    }
};

pub const ReferenceExprNode = struct {
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

    fn err_token(self: *Parser, message: []const u8, color: u8) void {
        const tk = self.tokens.items[self.current_index];
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
                if (i == self.current_index) {
                    print("\u{001b}[4;{d}m", .{color});
                }
                switch (token.token_type) {
                    .I_CHAR => print("'{s}'", .{token.content}),
                    .I_STR => print("\"{s}\"", .{token.content}),
                    else => print("{s}", .{token.content}),
                }
                if (i == self.current_index) {
                    print("\u{001b}[0m", .{});
                }
            }
        }
        print("\n\n", .{});
    }

    fn logerr(self: *Parser, message: []const u8, color: u8) noreturn {
        self.err_token(message, color);
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
            self.logerr("unexpected end of file", 31);
        }
    }

    pub fn parseNumberExpr(self: *Parser) !*ExprNode {
        const expr = try NumberExprNode.init(self.alloc);
        expr.* = .{ .integer = try std.fmt.parseInt(i32, self.current().content, 0) };
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
                            expr.number.integer = -expr.number.integer;
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
        while (true) {
            if (self.current().token_type != .OPERATOR) {
                return lhs;
            }

            const op1 = BinaryExprNode.Operator.parse(self);

            if (op1.get_precedence() < expr_prec) {
                return lhs;
            }
            
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

};
