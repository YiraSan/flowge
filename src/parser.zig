const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const lexer = @import("./lexer.zig");
const File = lexer.File;
const Token = lexer.Token;
const TokenType = lexer.TokenType;
const Tokens = lexer.Tokens;

// Abstract Syntax Tree

pub const BodyAST = struct {



};

pub const FunctionAST = struct {

    alloc: Allocator,
    token_index: usize,
    identifier: []const u8,
    parameters: []Parameter,
    return_index: usize,
    return_type: []const u8,
    body: ?*BodyAST,

    pub const Parameter = struct {
        name: []const u8,
        type: []const u8,
    };

    pub fn parse(tokens: *Tokens) !*FunctionAST {

        const function_ast = try tokens.alloc.create(FunctionAST);
        function_ast.alloc = tokens.alloc;
        tokens.next(); // eat "fn"

        function_ast.token_index = tokens.current_index;

        if (tokens.current().token_type != TokenType.IDENTIFIER) {
            tokens.unexpected_token();
        }
        const temp = try tokens.alloc.alloc(u8, tokens.current().content.len);
        std.mem.copyForwards(u8, temp, tokens.current().content);
        function_ast.identifier = temp;
        tokens.next(); // eat identifier
        
        if (tokens.current_char() != '(') {
            tokens.unexpected_token();
        }
        tokens.next(); // eat '('
        var parameters = std.ArrayList(Parameter).init(tokens.alloc);
        defer parameters.deinit();
        if (tokens.current_char() != ')') {
            while (tokens.current_char() != ')') {
                if (tokens.current().token_type != TokenType.IDENTIFIER) {
                    tokens.unexpected_token();
                }
                const id = try tokens.alloc.alloc(u8, tokens.current().content.len);
                std.mem.copyForwards(u8, id, tokens.current().content);
                tokens.next(); // eat identifier
                if (tokens.current_char() != ':') {
                    tokens.panic("missing type declaration", tokens.current_index - 1);
                }
                tokens.next(); // eat ':'
                if (tokens.current().token_type != TokenType.IDENTIFIER) {
                    tokens.unexpected_token();
                }
                const typ = try tokens.alloc.alloc(u8, tokens.current().content.len);
                std.mem.copyForwards(u8, typ, tokens.current().content);
                tokens.next(); // eat type
                try parameters.append(Parameter { .name = id, .type = typ, });
                if (tokens.current_char() == ')') {
                    break;
                } else if (tokens.current_char() != ',') {
                    tokens.panic("expected ',' or ')'", tokens.current_index);
                }
                tokens.next(); // eat ','
            }
        }
        tokens.next(); // eat ')'
        function_ast.parameters = try parameters.toOwnedSlice();

        if (tokens.current_char() == ':') {
            tokens.next(); // eat ':'
            if (tokens.current().token_type != TokenType.IDENTIFIER) {
                tokens.unexpected_token();
            }
            const temp2 = try tokens.alloc.alloc(u8, tokens.current().content.len);
            std.mem.copyForwards(u8, temp2, tokens.current().content);
            function_ast.return_type = temp2;
            function_ast.return_index = tokens.current_index;
            tokens.next(); // eat identifier
        } else {
            const temp2 = try tokens.alloc.alloc(u8, 4);
            std.mem.copyForwards(u8, temp2, "void");
            function_ast.return_type = temp2;
        }

        if (tokens.current_char() == ';') {
            tokens.consume(); // eat ';'
            function_ast.body = null;
        } else {
            tokens.unexpected_token();
        }

        return function_ast;

    }

    pub fn deinit(self: *FunctionAST) void {
        self.alloc.free(self.identifier);
        self.alloc.free(self.parameters);
        self.alloc.free(self.return_type);
        if (self.body != null) {
            // todo
        }
        self.alloc.destroy(self);
    }

};
