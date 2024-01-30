const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

pub const TokenType = enum {

    UNIQUE,
    IDENTIFIER,
    OPERATOR,
    NUMBER,
    I_STR,
    I_CHAR,

    // Here we enter the field of unparsable!

    FLOAT,
    HEXADECIMAL,
    BINARY,
    OCTAL,
    EOF,
    UNDEFINED,
    COMMENT,
    __END,
    LOP,

};

pub const Token = struct {
    line: usize,
    begin_column: usize,
    end_column: usize,
    token_type: TokenType,
    content: []u8,
    alloc: Allocator,

    fn init(alloc: Allocator) !*Token {
        var token: *Token = try alloc.create(Token);
        token.alloc = alloc;
        token.content = "";
        token.token_type = TokenType.UNDEFINED;
        token.line = 0;
        token.begin_column = 0;
        token.end_column = 0;
        return token; 
    }

    pub fn print(self: *Token) void {
        std.debug.print("Token {{\n  line: {d};\n  begin_column: {d};\n  end_column: {d};\n  type: {};\n  content: {s};\n}}\n", .{self.line, self.begin_column, self.end_column, self.token_type, self.content});
    }

    pub fn deinit(self: *Token) void {
        self.alloc.free(self.content);
        self.alloc.destroy(self);
    }

    pub fn clone(self: *Token) !*Token {
        var token: *Token = try self.alloc.create(Token);
        token.alloc = self.alloc;
        token.begin_column = self.begin_column;
        token.end_column = self.end_column;
        token.line = self.line;
        token.token_type = token.token_type;
        token.content = try self.alloc.alloc(u8, self.content.len);
        std.mem.copyForwards(u8, token.content, self.content);
        return token;
    }
};

pub const File = struct {
    line: usize,
    column: usize,
    index: usize,
    text: []const u8,
    path: []const u8,
    alloc: Allocator,

    pub fn init(alloc: Allocator, path: []const u8) !*File {
        var file: *File = try alloc.create(File);
        file.alloc = alloc;
        file.line = 1;
        file.column = 1;
        const temp: []u8 = try alloc.alloc(u8, path.len);
        std.mem.copyForwards(u8, temp, path);
        file.path = temp;
        file.index = 0;
        file.text = try std.fs.cwd().readFileAlloc(alloc, path, std.math.maxInt(u32));
        return file;
    }

    pub fn deinit(self: *File) void {
        self.alloc.free(self.text);
        self.alloc.free(self.path);
        self.alloc.destroy(self);
    }

    inline fn __ncol(self: *File, token: *Token) void {
        self.index += 1;
        self.column += 1;
        token.begin_column = self.column;
        token.end_column = self.column;
    }

    inline fn __nline(self: *File, token: *Token) void {
        self.index += 1;
        self.column = 1;
        self.line += 1;
        token.line = self.line;
        token.begin_column = self.column;
        token.end_column = self.column;
    }

    inline fn __ecol(self: *File, token: *Token) void {
        self.index += 1;
        self.column += 1;
        token.end_column += 1;
    }

    inline fn _qerr(self: *File, token: *Token) void {
        print("{s}:{d}:{d} \u{001b}[{d}m{s}\u{001b}[0m\n", .{
            self.path, token.line, token.begin_column, 31, "lexing error"
        });
        print("  \u{001b}[30m{d} |\u{001b}[0m ", .{token.line});
        print("\u{001b}[4;{d}m", .{31});
        switch (token.token_type) {
            .I_CHAR => print("'{s}'", .{token.content}),
            .I_STR => print("\"{s}\"", .{token.content}),
            else => print("{s}", .{token.content}),
        }
        print("\u{001b}[0m", .{});
        print("\n\n", .{});
        std.os.exit(0); // todo exit(1)
    }

    inline fn _cerr(self: *File, token: *Token) void {
        if (token.token_type != TokenType.__END) { self._qerr(token); }
    }

    inline fn _nerr(self: *File, token: *Token) void {
        if (token.token_type != TokenType.__END and token.token_type != TokenType.EOF) { self._qerr(token); }
    }

    // push the current char to the string and go next
    inline fn __reg(self: *File, token: *Token) !void {
        const temp = token.content;
        token.content = try self.alloc.alloc(u8, temp.len+1);
        std.mem.copyForwards(u8, token.content, temp);
        self.alloc.free(temp);
        token.content[token.content.len-1] = self.text[self.index];
        self.__ecol(token);
        try self._next(token);
    }

    fn _next(self: *File, token: *Token) anyerror!void {
        if (self.index < self.text.len) {
            const current = self.text[self.index];
            switch (token.token_type) {
                TokenType.UNDEFINED => {
                    if (current == ' ') {
                        self.__ncol(token);
                        try self._next(token);
                    } else if (current == '\r') {
                        self.__ncol(token);
                        try self._next(token);
                    } else if (current == '\n') {
                        self.__nline(token);
                        try self._next( token);
                    } else if (std.ascii.isAlphabetic(current)) { // IDENTIFIER
                        token.token_type = TokenType.IDENTIFIER;
                        token.content = try self.alloc.alloc(u8, 1);
                        token.content[0] = current;
                        self.__ecol(token);
                        try self._next(token);
                        self._nerr(token);
                        token.token_type = TokenType.IDENTIFIER;
                    } else if (std.ascii.isDigit(current)) { // NUMBER
                        token.token_type = TokenType.NUMBER;
                        token.content = try self.alloc.alloc(u8, 1);
                        token.content[0] = current;
                        self.__ecol(token);
                        try self._next(token);
                        self._nerr(token);
                        token.token_type = TokenType.NUMBER;
                    } else if (current == '"') { // I_STR
                        token.token_type = TokenType.I_STR;
                        self.__ecol(token);
                        try self._next(token);
                        self._nerr(token);
                        token.token_type = TokenType.I_STR;
                    } else if (current == '\'') { // I_CHAR
                        token.token_type = TokenType.I_CHAR;
                        self.__ecol(token);
                        try self._next(token);
                        self._nerr(token);
                        token.token_type = TokenType.I_CHAR;
                    } else {
                        switch (current) {
                            '/' => {
                                self.__ecol(token);
                                if (self.text[self.index] == '/') {
                                    token.token_type = TokenType.COMMENT;
                                    try self._next(token);
                                } else {
                                    token.token_type = TokenType.LOP;
                                    token.content = try self.alloc.alloc(u8, 1);
                                    token.content[0] = current;
                                    try self._next(token);
                                    self._nerr(token);
                                    token.token_type = TokenType.OPERATOR;
                                }
                            },
                            '+', '-', '*',  '<', '>', '%', '=' => {
                                token.token_type = TokenType.LOP;
                                token.content = try self.alloc.alloc(u8, 1);
                                token.content[0] = current;
                                self.__ecol(token);
                                try self._next(token);
                                self._nerr(token);
                                token.token_type = TokenType.OPERATOR;
                            },
                            else => {
                                self.__ecol(token);
                                token.token_type = TokenType.UNIQUE;
                                token.content = try self.alloc.alloc(u8, 1);
                                token.content[0] = current;
                            }
                        }
                    }
                },
                TokenType.LOP => {
                    if (current == '=') {
                        try self.__reg(token);
                    }
                    token.token_type = TokenType.__END;
                },
                TokenType.COMMENT => {
                    if (current == '\n') {
                        token.token_type = TokenType.UNDEFINED;
                        self.__nline(token);
                        self.alloc.free(token.content);
                        token.content = "";
                    } else {
                        self.__ecol(token);
                    }
                    try self._next(token);
                },
                TokenType.IDENTIFIER => {
                    if (std.ascii.isAlphanumeric(current)) {
                        try self.__reg(token);
                        self._nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.NUMBER => {
                    if (std.ascii.isDigit(current)) {
                        try self.__reg(token);
                        self._nerr(token);
                    } else if (current == '.') {
                        token.token_type = TokenType.FLOAT;
                        try self.__reg(token);
                        self._nerr(token);
                    } else {
                        if (token.content.len == 1 and token.content[0] == '0') {
                            if (current == 'b') {
                                token.token_type = TokenType.BINARY;
                                try self.__reg(token);
                                self._nerr(token);
                            } else if (current == 'x') {
                                token.token_type = TokenType.HEXADECIMAL;
                                try self.__reg(token);
                                self._nerr(token);
                            } else if (current == 'o') {
                                token.token_type = TokenType.OCTAL;
                                try self.__reg(token);
                                self._nerr(token);
                            } else {
                                token.token_type = TokenType.__END;
                            }
                        } else {
                            token.token_type = TokenType.__END;
                        }
                    }
                },
                TokenType.FLOAT => {
                    if (std.ascii.isDigit(current)) {
                        try self.__reg(token);
                        self._nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.BINARY => {
                    if (current == '0' or current == '1') {
                        try self.__reg(token);
                        self._nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.HEXADECIMAL => {
                    if (std.ascii.isHex(current)) {
                        try self.__reg(token);
                        self._nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.OCTAL => {
                    if (current == '0' or current == '1' or current == '2' or current == '3' or current == '4' or current == '5' or current == '6' or current == '7' or current == '8') {
                        try self.__reg(token);
                        self._nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.I_STR => {
                    if (current == '"') {
                        token.token_type = TokenType.__END;
                        self.__ecol(token);
                    } else if (current == '\n' or current == '\r') {
                        self._qerr(token);
                    } else {
                        try self.__reg( token);
                        self._cerr(token);
                    }
                },
                TokenType.I_CHAR => {
                    if (current == '\'') {
                        token.token_type = TokenType.__END;
                        self.__ecol(token);
                    } else if (current == '\n' or current == '\r') {
                        self._qerr(token);
                    } else {
                        try self.__reg(token);
                        self._cerr(token);
                    }
                },
                else => {},
            }
        } else {
            token.token_type = TokenType.EOF;
        }
    }

    pub fn next_token(self: *File) !*Token {
        var token = try Token.init(self.alloc);
        token.line = self.line;
        token.begin_column = self.column;
        token.end_column = self.column;
        try self._next(token);
        return token;
    }
};

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
