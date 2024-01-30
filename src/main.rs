use anyhow::Result;

mod lexer;
use lexer::Tokens;

pub struct FunctionAST {
    name: String,
    parameters: Vec<(String, String)>, // name, type
    return_type: String,
}

// impl FunctionAST {

//     pub fn parse(tokens: &mut Tokens) -> FunctionAST {
        
//     }

// }

fn main() -> Result<()> {

    let tokens = Tokens::from_path("example/main.flg")?;

    tokens.println("yay", 1);

    Ok(())
    
}