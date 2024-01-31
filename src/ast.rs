use crate::lexer::{TokenType, Tokens};

#[derive(Debug)]
pub struct BlockAST {
    pub begin_index: usize,
    pub end_index: usize,
}

impl BlockAST {

    pub fn parse(tokens: &mut Tokens) -> BlockAST {
        let begin_index = tokens.index();
        tokens.next(); // eat '{'
        if tokens.current_char() != '}' {
            // todo expression parsing
        }
        if tokens.current_char() != '}' {
            tokens.println("expected '}'", tokens.index());
            std::process::exit(1);
        }
        let end_index = tokens.index();
        tokens.consume(); // eat '}'
        BlockAST { begin_index, end_index }
    }

}

#[derive(Debug)]
pub struct FunctionAST {
    pub name: String,
    pub name_index: usize,
    pub parameters: Vec<(String, String, usize, usize)>, // name, type, name_index, type_index
    pub return_type: String,
    pub block: Option<BlockAST>,
}

impl FunctionAST {

    pub fn parse(tokens: &mut Tokens) -> FunctionAST {
        tokens.next(); // eat "fn"
        if tokens.current().tk_type == TokenType::Identifier {
            let name = tokens.current().content.clone();
            let name_index = tokens.index();
            tokens.next(); // eat identifier
            if tokens.current_char() != '(' {
                tokens.println("expected '('", tokens.index());
                std::process::exit(1);
            }
            tokens.next(); // eat '('
            let mut parameters = vec!();
            if tokens.current_char() != ')' {
                while tokens.current_char() != ')' {
                    if tokens.current().tk_type != TokenType::Identifier {
                        tokens.println("expected type identifier", tokens.index());
                        std::process::exit(1);
                    }
                    let id = tokens.current().content.clone();
                    let id_index = tokens.index();
                    tokens.next(); // eat identifier
                    if tokens.current_char() != ':' {
                        tokens.println("expected ':'", tokens.index());
                        std::process::exit(1);
                    }
                    tokens.next(); // eat ':'
                    if tokens.current().tk_type != TokenType::Identifier {
                        tokens.println("expected type identifier", tokens.index());
                        std::process::exit(1);
                    }
                    let ty = tokens.current().content.clone();
                    let ty_index = tokens.index();
                    tokens.next(); // eat type
                    parameters.push((id, ty, id_index, ty_index));
                    if tokens.current_char() == ')' {
                        break;
                    } else if tokens.current_char() != ',' {
                        tokens.println("expected ')' or ','", tokens.index());
                        std::process::exit(1);
                    }
                    tokens.next(); // eat ','
                }
            }
            tokens.next(); // eat ')'
            let return_type = {
                if tokens.current_char() != ':' {
                    "void".to_string()
                } else {
                    tokens.next(); // eat ':'
                    if tokens.current().tk_type != TokenType::Identifier {
                        tokens.println("expected type identifier", tokens.index());
                        std::process::exit(1);
                    }
                    let r = tokens.current().content.clone();
                    tokens.next();
                    r
                }
            };
            if tokens.current_char() == ';' {
                tokens.consume();
                FunctionAST {
                    name,
                    name_index,
                    parameters,
                    return_type,
                    block: None,
                }
            } else if tokens.current_char() == '{' {
                let block = BlockAST::parse(tokens);
                FunctionAST {
                    name,
                    name_index,
                    parameters,
                    return_type,
                    block: Some(block),
                }
            } else {
                tokens.println("expected ';' or '{'", tokens.index());
                std::process::exit(1);
            }
        } else {
            tokens.println("expected function identifier", tokens.index());
            std::process::exit(1);
        }
    }

}
