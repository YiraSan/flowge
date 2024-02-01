use anyhow::Result;
use colored::Colorize;

#[derive(PartialEq, Clone)]
pub enum TokenType {

    Number,
    Identifier,
    EndOfFile,

    Char,
}

pub struct Token {
    line: usize,
    begin_column: usize,
    end_column: usize,
    pub tk_type: TokenType,
    pub content: String,
}

pub struct Tokens {
    path: String,
    tokens: Vec<Token>,
    index: usize,
}

fn tokenize_identifier(
    text: &str, 
    column: &mut usize, 
    index: &mut usize,
    token: &mut Token, 
) {
    if *index < text.len() {
        let current = text.chars().nth(*index).unwrap();
        if current.is_ascii_alphanumeric() || current == '_' {
            token.content.push(current);
            *column += 1;
            *index += 1;
            tokenize_identifier(text, column, index, token);
        }
    }
}

fn tokenize_number(
    text: &str, 
    column: &mut usize, 
    index: &mut usize,
    token: &mut Token, 
) {
    if *index < text.len() {
        let current = text.chars().nth(*index).unwrap();
        if current.is_ascii_digit() {
            token.content.push(current);
            *column += 1;
            *index += 1;
            tokenize_number(text, column, index, token);
        }
    }
}

fn tokenize(
    text: &str, 
    line: &mut usize, 
    column: &mut usize, 
    index: &mut usize,
) -> Token {
    if *index < text.len() {
        let current = text.chars().nth(*index).unwrap();
        match current {
            ' ' => {
                *column += 1;
                *index += 1;
                tokenize(text, line, column, index)
            },
            '\r' => {
                *column += 1;
                *index += 1;
                tokenize(text, line, column, index)
            },
            '\n' => {
                *column = 1;
                *line += 1;
                *index += 1;
                tokenize(text, line, column, index)
            },
            _ if current.is_ascii_alphabetic() || current == '_' => {
                let mut token = Token {
                    line: *line,
                    begin_column: *column,
                    end_column: 0,
                    tk_type: TokenType::Identifier,
                    content: "".to_string(),
                };
                tokenize_identifier(text, column, index, &mut token);
                token.end_column = *column;
                token
            },
            _ if current.is_ascii_digit() => {
                let mut token = Token {
                    line: *line,
                    begin_column: *column,
                    end_column: 0,
                    tk_type: TokenType::Number,
                    content: "".to_string(),
                };
                tokenize_number(text, column, index, &mut token);
                token.end_column = *column;
                token
            },
            _ => {
                let token = Token {
                    line: *line,
                    begin_column: *column,
                    end_column: *column+1,
                    tk_type: TokenType::Char,
                    content: current.to_string(),
                };
                *column += 1;
                *index += 1;
                token
            },
        }
    } else {
        Token {
            line: *line, 
            begin_column: *column,
            end_column: *column,
            tk_type: TokenType::EndOfFile,
            content: "".to_string(),
        }
    }
}

impl Tokens {

    pub fn from_path<S: Into<String>>(path: S) -> Result<Tokens> {
        let path = path.into();
        let text = std::fs::read_to_string(path.clone())?;
        let mut tokens = Vec::new();

        let mut line = 1usize;
        let mut column = 1usize;
        let mut index = 0usize;
        loop {
            let token = tokenize(&text, &mut line, &mut column, &mut index);
            let t = token.tk_type.clone();
            tokens.push(token);
            if t == TokenType::EndOfFile {
                break;
            }
        }

        Ok(Tokens { path, tokens, index: 0 })
    }

    pub fn println<S: Into<String>>(&self, message: S, token_index: usize) {
    
        let token = &self.tokens[token_index];

        println!("{}:{}:{} {}", self.path, token.line, token.begin_column, message.into().red());

        print!("  {} {}", token.line.to_string().black(), "|".black());

        let mut sub = "  ".to_string();
        for _ in 0..format!("{}", token.line).len() {
            sub.push(' ');
        }
        sub.push_str(&" |".black().to_string());

        let mut ltc = 0;
        for (i, tk) in self.tokens.iter().enumerate() {
            if tk.line == token.line {
                if tk.begin_column - ltc != 0 {
                    print!(" ");
                    sub.push(' ');
                }
                ltc = tk.end_column;
                match tk.tk_type {
                    _ => print!("{}", tk.content),
                }
                for _ in 0..tk.content.len() {
                    if token_index == i {
                        sub.push_str(&"^".red().to_string());
                    } else {
                        sub.push(' ');
                    }
                }
            }
        }

        println!("\n{sub}");

        println!();

    }

    pub fn current(&self) -> &Token {
        &self.tokens[self.index]
    }

    pub fn next(&mut self) {
        self.consume();
        if self.current().tk_type == TokenType::EndOfFile {
            self.println("unexpected end of file", self.index-1);
            std::process::exit(1);
        }
    }

    pub fn consume(&mut self) {
        if self.current().tk_type != TokenType::EndOfFile {
            self.index += 1;
        }
    }

    pub fn index(&self) -> usize {
        self.index
    }

    pub fn current_char(&self) -> char {
        if self.current().content.len() > 0 {
            self.current().content.chars().nth(0).unwrap()
        } else {
            '\0'
        }
    }

}
