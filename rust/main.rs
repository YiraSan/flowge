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

    let llvm_context = Context::create();
    let module = FlowgeModule::new("flowge", &llvm_context);

    println!("\n{}", module.print().unwrap());

    Ok(())
    
}