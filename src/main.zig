const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;
const print = std.debug.print;

const parser = @import("./parser.zig");
const Parser = parser.Parser;

pub extern "kernel32" fn SetConsoleOutputCP(
    wCodePageID: u32,
) callconv(std.os.windows.WINAPI) bool;

pub fn main() !void {

    if (builtin.target.os.tag == .windows) {
        _ = SetConsoleOutputCP(65001);
    }

    print("🐉 flowge \u{001b}[35m0.1n\u{001b}[0m\n\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    // defer _ = gpa.deinit();

    const p = try Parser.init(alloc, "./test.flg");
    defer p.deinit();

    const expr = try p.parseExpr();
    defer expr.deinit(alloc);

}
