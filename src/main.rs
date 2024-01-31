use std::collections::HashMap;

use anyhow::Result;
use colored::Colorize;

mod lexer;
use inkwell::context::Context;
use lexer::Tokens;

mod ast;
use ast::FunctionAST;

mod codegen;
use codegen::FlowgeModule;

fn main() -> Result<()> {

    println!("🐉 flowge {}\n", "0.1n".purple());

    let mut tokens = Tokens::from_path("example/main.flg")?;

    println!("{:?}", FunctionAST::parse(&mut tokens));

    let mod_name = "flowge";

    let llvm_context = Context::create();

    let mut module = FlowgeModule {
        name: mod_name.to_string(),
        contexts: Vec::new(),
        top_levels: HashMap::new(),
        llvm_module: llvm_context.create_module(mod_name),
        llvm_builder: llvm_context.create_builder(),
        llvm_context: &llvm_context,
    };

    let ctx = module.new_context(0);
    let context = &mut module.contexts[ctx];

    println!("\n{}", module.print().unwrap());

    Ok(())
    
}