const std = @import("std");
const fs = std.fs;

const lexer = @import("./lexer.zig");
const File = lexer.File;
const Token = lexer.Token;
const TokenType = lexer.TokenType;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    var file = try File.init(alloc, "./test.flg");
    defer file.deinit();

    var token = try file.next_token();
    defer token.deinit();
    while (token.token_type != TokenType.EOF) {
        token.print();
        token.deinit();
        token = try file.next_token();
    }
    
}
