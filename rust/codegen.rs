use std::collections::HashMap;

use anyhow::Result;
use inkwell::builder::Builder;
use inkwell::module::Module;
use inkwell::support::LLVMString;
use inkwell::types::{AnyType, AnyTypeEnum};
use inkwell::context::Context;

pub struct Function {
    context: usize,
}

pub struct FlowgeContext<'ctx> {
    index: usize,
    parent: usize,
    types: HashMap<String, Box<dyn AnyType<'ctx>>>,
    functions: Vec<Function>,
}

impl<'ctx> FlowgeContext<'ctx> {

    pub fn add_type<S: Into<String>>(&mut self, name: S, ty: Box<dyn AnyType<'ctx>>) {
        self.types.insert(name.into(), ty);
    }

}

pub struct FlowgeModule<'ctx> {

    pub name: String,
    /// context\[0\] = primitive_context
    pub contexts: Vec<FlowgeContext<'ctx>>,
    /// file_path, context_index
    pub top_levels: HashMap<String, usize>,

    // LLVM

    pub llvm_context: &'ctx Context,
    pub llvm_module: Module<'ctx>,
    pub llvm_builder: Builder<'ctx>,

}

impl<'ctx> FlowgeModule<'ctx> {

    pub fn new<S: Into<String>>(name: S, llvm_context: &'ctx Context) -> FlowgeModule<'_> {
        let name = name.into();
        let llvm_module = llvm_context.create_module(&name);
        let llvm_builder = llvm_context.create_builder();
        let mut module = FlowgeModule {
            name,
            contexts: Vec::new(),
            top_levels: HashMap::new(),
            llvm_context,
            llvm_module,
            llvm_builder,
        };
        let ctx = module.new_context(0);
        let context = &mut module.contexts[ctx];

        context.add_type("void", );

        module
    }

    pub fn new_context(&mut self, parent: usize) -> usize {
        let index = self.contexts.len();
        self.contexts.push(FlowgeContext { 
            index,
            parent,
            types: HashMap::new(),
            functions: Vec::new(),
        });
        index
    }

    pub fn get_toplevel(&self, path: &str) -> &FlowgeContext<'ctx> {
        &self.contexts[*self.top_levels.get(path).unwrap()]
    }

    pub fn get_mut_toplevel(&mut self, path: &str) -> &mut FlowgeContext<'ctx> {
        &mut self.contexts[*self.top_levels.get(path).unwrap()]
    }

    pub fn print(&self) -> Result<String, LLVMString> {
        self.llvm_module.verify()?;
        Ok(self.llvm_module.print_to_string().to_string())
    }

}
