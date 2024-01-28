const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;
const print = std.debug.print;

const project = @import("./project.zig");

pub extern "kernel32" fn SetConsoleOutputCP(
    wCodePageID: u32,
) callconv(std.os.windows.WINAPI) bool;

const llvm = @import("llvm/llvm.zig");
const core = llvm.core;
const target = llvm.target;

pub fn main() !void {

    _ = target.LLVMInitializeNativeTarget();
    _ = target.LLVMInitializeNativeAsmPrinter();
    _ = target.LLVMInitializeNativeAsmParser();
    defer core.LLVMShutdown();

    if (builtin.target.os.tag == .windows) {
        // dumb windows need to know that this program uses UTF-8 !
        _ = SetConsoleOutputCP(65001);
    }

    print("🐉 flowge \u{001b}[35m0.1n\u{001b}[0m\n\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();

    const module = try project.Module.init(alloc, "example");
    defer module.deinit();

    _ = try module.parser.parseTopLevel();

}
