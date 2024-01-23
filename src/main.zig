const std = @import("std");

const fs = std.fs;
const Allocator = std.mem.Allocator;

const TokenType = enum {
    KEY,
    DIGIT,
    EOF,
    I_STR,
    I_CHAR,
    UNKNOWN,
};

const Token = struct {
    begin_line: usize,
    begin_column: usize,
    end_line: usize,
    end_column: usize,
    token_type: TokenType,
    content: []const u8,

    fn print(self: *Token) void {
        std.debug.print("Token {{\n  begin_line: {d};\n  begin_column: {d};\n  end_line: {d};\n  end_column: {d};\n  type: {};\n  content: {s};\n}}", .{self.begin_line, self.begin_column, self.end_line, self.end_column, self.token_type, self.content});
    }

    inline fn __ncol(file: *File) void {
        file.index += 1;
        file.column += 1;

    }

    fn _next(alloc: Allocator, file: *File, token: *Token) !void {
        if (file.text.len > file.index) {
            const current = file.text[file.index];
            switch (token.token_type) {
                TokenType.UNKNOWN => {
                    if (current == ' ') {
                        __ncol(file);
                        try _next(alloc, file, token);
                    } else if (current == '\r') {
                        __ncol(file);
                        try _next(alloc, file, token);
                    } else if (current == '\n') {
                        __ncol(file);
                        try _next(alloc, file, token);
                    } else if (std.ascii.isAlphabetic(current)) {
                        token.token_type = TokenType.KEY;
                        token.content = alloc.alloc(u8, 1);
                        __ncol(file);       
                        try _next(alloc, file, token);
                        // change to UNKNOWN and check.
                    } else {
                        std.debug.panic("unknown token", .{});
                    }
                },
            }
            // 
            // if (current == '\n') {
            //     file.column = 1;
            //     file.line += 1;
            // } else if (current == ' ') {
            //     file.column += 1;
            // } else if (current == '\r') {
            //     file.column += 1;
            // } else if (std.ascii.isAlphabetic(current)) {
            //     token.token_type = TokenType.KEY;
            // } else if (std.ascii.isDigit(current)) {
            //     token.token_type = TokenType.DIGIT;
            // }
            // file.index += 1;
            // _next(alloc, file, token);
        } else {
            token.token_type = TokenType.EOF;
        }
    }

    fn next_token(alloc: Allocator, file: *File) !*Token {
        var token: *Token = try alloc.create(Token);
        token.content = "";
        token.begin_line = file.line;
        token.begin_column = file.column;
        token.end_line = file.line;
        token.end_column = file.column+1;
        token.token_type = TokenType.UNKNOWN;
        try _next(alloc, file, token);
        return token;
    }

    fn deinit(self: *Token, alloc: Allocator) void {
        alloc.free(self.content);
        alloc.destroy(self);
    }
};

const File = struct {
    line: usize,
    column: usize,
    index: usize,
    text: []const u8,

    fn init(alloc: Allocator, path: []const u8) !*File {
        var file: *File = try alloc.create(File);
        file.line = 1;
        file.column = 1;
        file.index = 0;
        file.text = try std.fs.cwd().readFileAlloc(alloc, path, std.math.maxInt(u32));
        return file;
    }

    fn deinit(self: *File, alloc: Allocator) void {
        alloc.free(self.text);
        alloc.destroy(self);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    var file = try File.init(alloc, "./test.flg");
    defer file.deinit(alloc);

    var token = try Token.next_token(alloc, file);
    defer token.deinit(alloc);

    token.print();
}
