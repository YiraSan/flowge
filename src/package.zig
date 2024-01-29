const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const p = @import("parser.zig");
const Tokens = p.Tokens;

const llvm = @import("llvm/llvm.zig");
const core = llvm.core;

const LLVMContext = llvm.types.LLVMContextRef;
const LLVMModule = llvm.types.LLVMModuleRef;
const LLVMBuilder = llvm.types.LLVMBuilderRef;

const LLVMValue = llvm.types.LLVMValueRef;
const LLVMType = llvm.types.LLVMTypeRef;

// pub const Expression = union(enum) {
    
// };

// pub const Body = struct {

// };

pub const FunctionParameter = struct {
    name: []const u8,
    type: LLVMType,
};

pub const Function = struct {

    alloc: Allocator,
    context: *Context,
    identifier: []const u8,
    parameters: []FunctionParameter,
    return_type: LLVMType,
    // body: ?*Body,

    func_value: ?LLVMValue,

    pub fn init(alloc: Allocator, parent: *Context) !*Function {
        _ = parent;
        const function = try alloc.create(Function);
        
        return function;
    }

    pub fn valuegen(self: *Function) void {
        _ = self;

    }

    pub fn codegen(self: *Function) void {
        if (self.func_value == null) {
            self.valuegen();
        }
    }

    pub fn get_llvm_value(self: *Function) LLVMValue {
        if (self.func_value == null) {
            self.valuegen();
        }
        return self.func_value;
    }

};

pub const Context = struct {

    alloc: Allocator,
    parent: ?*Context,
    types: std.StringHashMap(LLVMType),
    functions: std.StringHashMap(*Function),
    variable: std.StringHashMap(LLVMValue),
    constant: std.StringHashMap(LLVMValue),

    pub fn init(alloc: Allocator, parent: ?*Context) !*Context {
        const context = try alloc.create(Context);
        context.alloc = alloc;
        context.parent = parent;

        context.types = std.StringHashMap(LLVMType).init(alloc);
        context.functions = std.StringHashMap(*Function).init(alloc);
        context.variable = std.StringHashMap(LLVMValue).init(alloc);
        context.constant = std.StringHashMap(LLVMValue).init(alloc);

        return context;
    }

    pub fn get_type(self: *Context, name: []const u8) ?LLVMType {
        if (self.types.contains(name)) {
            return self.types.get(name).?;
        } else if (self.parent != null) {
            return self.parent.?.get_type(name).?;
        } else {
            return null;
        }
    }

    pub fn get_function(self: *Context, name: []const u8) ?LLVMValue {
        _ = name;
        _ = self;

    }

    pub fn append(self: *Context, tokens: *Tokens) void {
        _ = tokens;
        _ = self;
        
    }

};

pub const Package = struct {

    alloc: Allocator,
    dir_path: []const u8,
    llvm_context: LLVMContext,
    llvm_module: LLVMModule,
    llvm_builder: LLVMBuilder,

    top_level: *Context,

    pub fn init(alloc: Allocator, dir_path: []const u8) !*Package {
        const package = try alloc.create(Package);

        const res = try std.fs.cwd().realpathAlloc(alloc, dir_path);
        defer alloc.free(res);
        const m = try alloc.dupeZ(u8, std.fs.path.basename(res));
        defer alloc.free(m);

        package.llvm_context = core.LLVMContextCreate();
        package.llvm_module = core.LLVMModuleCreateWithNameInContext(m, package.llvm_context);
        package.llvm_builder = core.LLVMCreateBuilderInContext(package.llvm_context);

        package.top_level = Context.init(alloc, null);
        package.top_level.types.put("void", core.LLVMVoidTypeInContext(package.llvm_context));
        package.top_level.types.put("bool", core.LLVMInt1TypeInContext(package.llvm_context));
        
        package.top_level.types.put("u8", core.LLVMInt8TypeInContext(package.llvm_context));
        package.top_level.types.put("u16", core.LLVMInt8TypeInContext(package.llvm_context));
        package.top_level.types.put("u32", core.LLVMInt8TypeInContext(package.llvm_context));
        package.top_level.types.put("u64", core.LLVMInt8TypeInContext(package.llvm_context));
        package.top_level.types.put("u128", core.LLVMInt8TypeInContext(package.llvm_context));
        
        package.top_level.types.put("i8", core.LLVMInt8TypeInContext(package.llvm_context));
        package.top_level.types.put("i16", core.LLVMInt8TypeInContext(package.llvm_context));
        package.top_level.types.put("i32", core.LLVMInt8TypeInContext(package.llvm_context));
        package.top_level.types.put("i64", core.LLVMInt8TypeInContext(package.llvm_context));
        package.top_level.types.put("i128", core.LLVMInt8TypeInContext(package.llvm_context));
        
        package.top_level.types.put("f16", core.LLVMHalfTypeInContext(package.llvm_context));
        package.top_level.types.put("f32", core.LLVMFloatTypeInContext(package.llvm_context));
        package.top_level.types.put("f64", core.LLVMDoubleTypeInContext(package.llvm_context));
        package.top_level.types.put("f128", core.LLVMFP128TypeInContext(package.llvm_context));
        
        package.top_level.constant.put("true", core.LLVMConstInt(core.LLVMInt1TypeInContext(package.llvm_context), 1, false));
        package.top_level.constant.put("false", core.LLVMConstInt(core.LLVMInt1TypeInContext(package.llvm_context), 0, false));
        package.top_level.constant.put("null", core.LLVMConstNull(core.LLVMPointerTypeInContext(package.llvm_context, )));

        return package;
    }

    pub fn build(self: *Package, dir_path: []const u8) void {

        const temp = try self.alloc.alloc(u8, dir_path.len);
        std.mem.copyForwards(u8, temp, dir_path);
        self.dir_path = temp;

        const file_path = try std.fs.path.join(self.alloc, &[_][]const u8{dir_path, "main.flg"});
        defer self.alloc.free(file_path);
        const tokens = try Tokens.init(self.alloc, file_path);
        _ = tokens;
        
        

    }

    pub fn deinit(self: *Package) void {
        core.LLVMDisposeBuilder(self.llvm_builder);
        core.LLVMDisposeModule(self.llvm_module); 
        core.LLVMContextDispose(self.llvm_context);
        self.alloc.destroy(self);
    }
    
};
