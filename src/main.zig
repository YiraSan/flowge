const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;
const print = std.debug.print;

const parser = @import("./parser.zig");
const Parser = parser.Parser;

const project = @import("./project.zig");

pub extern "kernel32" fn SetConsoleOutputCP(
    wCodePageID: u32,
) callconv(std.os.windows.WINAPI) bool;

pub fn main() !void {

    if (builtin.target.os.tag == .windows) {
        _ = SetConsoleOutputCP(65001);
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    _ = alloc;
    
    // const p = try Parser.init(alloc, "./test.flg");
    // defer p.deinit();

    // const expr = try p.parseExpr();
    // defer expr.deinit(alloc);

    

}
