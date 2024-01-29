const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const l = @import("lexer.zig");
const Tokens = l.Tokens;
const TokenType = l.TokenType;

const p = @import("parser.zig");
const FunctionAST = p.FunctionAST;

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
    ast: *FunctionAST,
    context: *Context,
    identifier: []const u8,
    parameters: []FunctionParameter,
    return_type: LLVMType,
    // body: ?*Body,

    func_value: ?LLVMValue,

    pub fn init(parent: *Context) !*Function {
        const function = try parent.alloc.create(Function);
        function.context = try Context.init(parent.alloc, parent);
        function.alloc = parent.alloc;
        return function;
    }

    pub fn deinit(self: *Function) void {
        self.context.deinit();
        self.ast.deinit();
        self.alloc.free(self.identifier);
        self.alloc.free(self.parameters);
        // todo: deinit body
        self.alloc.destroy(self);
    }

    pub fn valuegen(self: *Function, package: *Package) !void {        
        const arg_types = try self.alloc.alloc(LLVMType, self.parameters.len);
        for (0.., self.parameters) |i, param| {
            arg_types[i] = param.type;
        }

        const name = try self.alloc.dupeZ(u8, self.identifier);
        
        const func_type = core.LLVMFunctionType(self.return_type, arg_types.ptr, @intCast(arg_types.len), 0);
        const func = core.LLVMAddFunction(package.llvm_module, name.ptr, func_type);
        self.func_value = func;
        core.LLVMSetLinkage(func, llvm.types.LLVMLinkage.LLVMExternalLinkage);
    
        // for (0.., self.parameters) |i, fparam| {
        //     const param = core.LLVMGetParam(func, @intCast(i));
        //     const param_name = try self.alloc.dupeZ(u8, fparam.name);
        //     defer self.alloc.free(param_name);
        //     core.LLVMSetValueName2(param, param_name, @intCast(fparam.name.len));
        // }

    }

    pub fn codegen(self: *Function) !void {
        _ = try self.get_llvm_value();
    }

    pub fn get_llvm_value(self: *Function) !LLVMValue {
        if (self.func_value == null) {
            try self.valuegen();
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

    pub fn deinit(self: *Context) void {
        self.types.deinit();
        var iterator = self.functions.iterator();
        while (iterator.next()) |entry| {
            entry.value_ptr.*.deinit();
        }
        self.functions.deinit();
        self.variable.deinit();
        self.constant.deinit();
        self.alloc.destroy(self);
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

    pub fn append(self: *Context, package: *Package, tokens: *Tokens) !void {
        while (tokens.current().token_type != TokenType.EOF) {
            if (std.mem.eql(u8, tokens.current().content, "fn")) {

                const func = try FunctionAST.parse(tokens);
                const function = try Function.init(self);
                function.ast = func;

                const return_type = self.get_type(func.return_type);
                if (return_type == null) {
                    tokens.panic("unknown type", func.return_index);
                }
                function.return_type = return_type.?;

                if (self.functions.contains(func.identifier)) {
                    tokens.println("function first declared here", self.functions.get(func.identifier).?.ast.token_index, 34);
                    tokens.println(try std.fmt.allocPrint(self.alloc, "redeclaration of {s} here", .{func.identifier}), func.token_index, 31);
                    std.os.exit(0); // todo: std.os.exit(1);
                }

                const temp = try tokens.alloc.alloc(u8, func.identifier.len);
                std.mem.copyForwards(u8, temp, func.identifier);
                function.identifier = temp;

                function.parameters = try tokens.alloc.alloc(FunctionParameter, func.parameters.len);
                // todo

                try function.valuegen(package);

                try self.functions.put(function.identifier, function);
            } else {
                tokens.unexpected_token();
            }
        }
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
        package.alloc = alloc;

        const temp = try alloc.alloc(u8, dir_path.len);
        std.mem.copyForwards(u8, temp, dir_path);
        package.dir_path = temp;

        const res = try std.fs.cwd().realpathAlloc(alloc, dir_path);
        defer alloc.free(res);
        const m = try alloc.dupeZ(u8, std.fs.path.basename(res));
        defer alloc.free(m);

        package.llvm_context = core.LLVMContextCreate();
        package.llvm_module = core.LLVMModuleCreateWithNameInContext(m, package.llvm_context);
        package.llvm_builder = core.LLVMCreateBuilderInContext(package.llvm_context);

        package.top_level = try Context.init(alloc, null);
        try package.top_level.types.put("void", core.LLVMVoidTypeInContext(package.llvm_context));
        try package.top_level.types.put("bool", core.LLVMInt1TypeInContext(package.llvm_context));
        
        try package.top_level.types.put("u8", core.LLVMInt8TypeInContext(package.llvm_context));
        try package.top_level.types.put("u16", core.LLVMInt8TypeInContext(package.llvm_context));
        try package.top_level.types.put("u32", core.LLVMInt8TypeInContext(package.llvm_context));
        try package.top_level.types.put("u64", core.LLVMInt8TypeInContext(package.llvm_context));
        try package.top_level.types.put("u128", core.LLVMInt8TypeInContext(package.llvm_context));
        
        try package.top_level.types.put("i8", core.LLVMInt8TypeInContext(package.llvm_context));
        try package.top_level.types.put("i16", core.LLVMInt8TypeInContext(package.llvm_context));
        try package.top_level.types.put("i32", core.LLVMInt8TypeInContext(package.llvm_context));
        try package.top_level.types.put("i64", core.LLVMInt8TypeInContext(package.llvm_context));
        try package.top_level.types.put("i128", core.LLVMInt8TypeInContext(package.llvm_context));
        
        try package.top_level.types.put("f16", core.LLVMHalfTypeInContext(package.llvm_context));
        try package.top_level.types.put("f32", core.LLVMFloatTypeInContext(package.llvm_context));
        try package.top_level.types.put("f64", core.LLVMDoubleTypeInContext(package.llvm_context));
        try package.top_level.types.put("f128", core.LLVMFP128TypeInContext(package.llvm_context));
        
        try package.top_level.constant.put("true", core.LLVMConstInt(core.LLVMInt1TypeInContext(package.llvm_context), 1, 0));
        try package.top_level.constant.put("false", core.LLVMConstInt(core.LLVMInt1TypeInContext(package.llvm_context), 0, 0));
        // try package.top_level.constant.put("null", core.LLVMConstNull(core.LLVMPointerTypeInContext(package.llvm_context, )));

        return package;
    }

    pub fn build(self: *Package) !void {

        const file_path = try std.fs.path.join(self.alloc, &[_][]const u8{self.dir_path, "main.flg"});
        defer self.alloc.free(file_path);
        const tokens = try Tokens.init(self.alloc, file_path);
        defer tokens.deinit();
        
        try self.top_level.append(self, tokens);

    }

    pub fn deinit(self: *Package) void {
        core.LLVMDisposeBuilder(self.llvm_builder);
        core.LLVMDisposeModule(self.llvm_module); 
        core.LLVMContextDispose(self.llvm_context);
        self.alloc.free(self.dir_path);
        self.top_level.deinit();
        self.alloc.destroy(self);
    }
    
};
