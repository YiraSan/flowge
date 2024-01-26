const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "flowge",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.defineCMacro("_FILE_OFFSET_BITS", "64");
    exe.defineCMacro("__STDC_CONSTANT_MACROS", null);
    exe.defineCMacro("__STDC_FORMAT_MACROS", null);
    exe.defineCMacro("__STDC_LIMIT_MACROS", null);

    // exe.linkSystemLibrary("z");
    switch (target.result.os.tag) {
        .linux => {
            exe.linkSystemLibrary("LLVM-17");
        }, 
        .macos => {
            exe.addLibraryPath(.{ .path = "/usr/local/opt/llvm/lib" });
            exe.linkSystemLibrary("LLVM");
        },
        .windows => {
            exe.addLibraryPath(.{.path = "C:\\Program Files\\LLVM\\lib"});
            exe.linkSystemLibrary("LLVM-C");
        },
        else => unreachable,
    }
    
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

}
