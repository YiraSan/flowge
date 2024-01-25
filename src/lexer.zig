const std = @import("std");
const Allocator = std.mem.Allocator;

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

    inline fn _qerr(token: *Token) void {
        _ = token;
        std.debug.panic("error while lexing (todo: add nice error!)\n", .{});
    }

    inline fn _cerr(token: *Token) void {
        if (token.token_type != TokenType.__END) { _qerr(token); }
    }

    inline fn _nerr(token: *Token) void {
        if (token.token_type != TokenType.__END and token.token_type != TokenType.EOF) { _qerr(token); }
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
                        _nerr(token);
                        token.token_type = TokenType.IDENTIFIER;
                    } else if (std.ascii.isDigit(current)) { // NUMBER
                        token.token_type = TokenType.NUMBER;
                        token.content = try self.alloc.alloc(u8, 1);
                        token.content[0] = current;
                        self.__ecol(token);
                        try self._next(token);
                        _nerr(token);
                        token.token_type = TokenType.NUMBER;
                    } else if (current == '"') { // I_STR
                        token.token_type = TokenType.I_STR;
                        self.__ecol(token);
                        try self._next(token);
                        _nerr(token);
                        token.token_type = TokenType.I_STR;
                    } else if (current == '\'') { // I_CHAR
                        token.token_type = TokenType.I_CHAR;
                        self.__ecol(token);
                        try self._next(token);
                        _nerr(token);
                        token.token_type = TokenType.I_CHAR;
                    } else {
                        switch (current) {
                            '+', '-', '*', '/', '<', '>', '%', '=' => {
                                token.token_type = TokenType.LOP;
                                token.content = try self.alloc.alloc(u8, 1);
                                token.content[0] = current;
                                self.__ecol(token);
                                try self._next(token);
                                _nerr(token);
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
                TokenType.IDENTIFIER => {
                    if (std.ascii.isAlphanumeric(current)) {
                        try self.__reg(token);
                        _nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.NUMBER => {
                    if (std.ascii.isDigit(current)) {
                        try self.__reg(token);
                        _nerr(token);
                    } else if (current == '.') {
                        token.token_type = TokenType.FLOAT;
                        try self.__reg(token);
                        _nerr(token);
                    } else {
                        if (token.content.len == 1 and token.content[0] == '0') {
                            if (current == 'b') {
                                token.token_type = TokenType.BINARY;
                                try self.__reg(token);
                                _nerr(token);
                            } else if (current == 'x') {
                                token.token_type = TokenType.HEXADECIMAL;
                                try self.__reg(token);
                                _nerr(token);
                            } else if (current == 'o') {
                                token.token_type = TokenType.OCTAL;
                                try self.__reg(token);
                                _nerr(token);
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
                        _nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.BINARY => {
                    if (current == '0' or current == '1') {
                        try self.__reg(token);
                        _nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.HEXADECIMAL => {
                    if (std.ascii.isHex(current)) {
                        try self.__reg(token);
                        _nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.OCTAL => {
                    if (current == '0' or current == '1' or current == '2' or current == '3' or current == '4' or current == '5' or current == '6' or current == '7' or current == '8') {
                        try self.__reg(token);
                        _nerr(token);
                    } else {
                        token.token_type = TokenType.__END;
                    }
                },
                TokenType.I_STR => {
                    if (current == '"') {
                        token.token_type = TokenType.__END;
                        self.__ecol(token);
                    } else if (current == '\n' or current == '\r') {
                        _qerr(token);
                    } else {
                        try self.__reg( token);
                        _cerr(token);
                    }
                },
                TokenType.I_CHAR => {
                    if (current == '\'') {
                        token.token_type = TokenType.__END;
                        self.__ecol(token);
                    } else if (current == '\n' or current == '\r') {
                        _qerr(token);
                    } else {
                        try self.__reg(token);
                        _cerr(token);
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
