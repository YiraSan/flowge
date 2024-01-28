const std = @import("std");
const Allocator = std.mem.Allocator;

const p = @import("./parser.zig");
const Parser = p.Parser;

const llvm = @import("llvm/llvm.zig");
const types = llvm.types;
const core = llvm.core;

// pub fn getLLVMContext() types.LLVMContextRef {
//     const container = struct {
//         var context = core.LLVMContextCreate();
//     };
//     return container.context;
// }

pub const Module = struct {
    alloc: Allocator,
    parser: *Parser,
    scope: std.StringHashMap(types.LLVMValueRef),
    llvm_module: types.LLVMModuleRef,
    llvm_builder: types.LLVMBuilderRef,

    pub fn init(alloc: Allocator, path: []const u8) !*Module {
        var module: *Module = try alloc.create(Module);
        const file_path = try std.fs.path.join(alloc, &[_][]const u8{path, "main.flg"});
        defer alloc.free(file_path);
        module.parser = try Parser.init(alloc, file_path);
        module.alloc = alloc;
        const res = try std.fs.cwd().realpathAlloc(alloc, path);
        defer alloc.free(res);
        const m = try alloc.dupeZ(u8, std.fs.path.basename(res));
        defer alloc.free(m);
        module.llvm_module = core.LLVMModuleCreateWithName(m);
        module.llvm_builder = core.LLVMCreateBuilder();
        module.scope = std.StringHashMap(types.LLVMValueRef).init(alloc);
        return module;
    }

    pub fn deinit(self: *Module) void {
        core.LLVMDisposeBuilder(self.llvm_builder);
        // if execution engine is in use : do not dispose module since its owned by exec engine!
        core.LLVMDisposeModule(self.llvm_module); 
        self.scope.deinit();
        self.parser.deinit();
        self.alloc.destroy(self);
    }
};
