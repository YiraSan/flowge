const std = @import("std");
const Allocator = std.mem.Allocator;

const llvm = @import("llvm/llvm.zig");
const types = llvm.types;
const target = llvm.target;
const core = llvm.core;

// pub fn getLLVMContext() types.LLVMContextRef {
//     const container = struct {
//         var context = core.LLVMContextCreate();
//     };
//     return container.context;
// }

pub const Module = struct {
    alloc: Allocator,
    path: []const u8,
    llvm_module: types.LLVMModuleRef,
    llvm_builder: types.LLVMBuilderRef,

    pub fn init(alloc: Allocator, path: []const u8) !*Module {
        _ = path;
        var module: *Module = try alloc.create(Module);
        module.alloc = alloc;
        module.llvm_module = core.LLVMModuleCreateWithName("flowge");
        module.llvm_builder = core.LLVMCreateBuilder();
        return module;
    }  
};

// pub const LLVMModule = struct {
//     module: types.LLVMModuleRef,
//     builder: types.LLVMBuilderRef,
    
//     pub fn init(alloc: Allocator) !*LLVMModule {
//         var llvm_module: *LLVMModule = try alloc.create(LLVMModule);
//         _ = llvm_module;
//         // const context = core.LLVMContextCreate();
//         const module: types.LLVMModuleRef = core.LLVMModuleCreateWithName("sum_module");
//         const builder: types.LLVMBuilderRef = core.LLVMCreateBuilder();
//         _ = builder;
//         _ = module;
//     }

// };

// pub fn init_llvm() void {
//     _ = target.LLVMInitializeNativeTarget();
//     _ = target.LLVMInitializeNativeAsmPrinter();
//     _ = target.LLVMInitializeNativeAsmParser();


// }