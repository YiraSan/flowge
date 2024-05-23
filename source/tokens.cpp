#include "tokens.h"

Token* tokenize(
    std::string text, 
    size_t *line, 
    size_t *column, 
    size_t *index
) {
    if (*index < text.length()) {
        char current = text[*index];
        if (current == ' ' || current == '\r') {
            *column += 1;
            *index += 1;
            return tokenize(text, line, column, index);
        } else if (current == '\n') {
            *column = 1;
            *line += 1;
            *index += 1;
            return tokenize(text, line, column, index);
        } else if ((isascii(current) && isalpha(current)) || current == '_') {
            Token* token = new Token;
            token->begin_column = *column;
            token->line = *line;
            token->type = tok_identifier;
            token->content = std::string();
            while (*index < text.length()) {
                char current = text[*index];
                if ((isascii(current) && isalnum(current)) || current == '_') {
                    token->content += current;
                    *column += 1;
                    *index += 1;
                } else {
                    break;
                }
            }
            if (token->content == "fn") {
                token->type = tok_fn;
            } else if (token->content == "if") {
                token->type = tok_if;
            } else if (token->content == "else") {
                token->type = tok_else;
            }
            token->end_column = *column;
            return token;
        } else if (isascii(current) && isdigit(current)) {
            Token* token = new Token;
            token->begin_column = *column;
            token->line = *line;
            token->type = tok_number;
            token->content = std::string();
            if (current == '0') {
                token->content += current;
                *column += 1;
                *index += 1;
                if (*index < text.length()) {
                    char current = text[*index];
                    if (current == 'x' || current == 'b' || current == 'o') {
                        token->content += current;
                        *column += 1;
                        *index += 1;
                    }
                }
            }
            while (*index < text.length()) {
                char current = text[*index];
                if (isascii(current) && isalnum(current)) {
                    token->content += current;
                    *column += 1;
                    *index += 1;
                } else {
                    break;
                }
            }
            if (*index < text.length()) {
                if (text[*index] == '.') {
                    token->content += text[*index];
                    *column += 1;
                    *index += 1;
                    while (*index < text.length()) {
                        char current = text[*index];
                        if (isascii(current) && isdigit(current)) {
                            token->content += current;
                            *column += 1;
                            *index += 1;
                        } else {
                            break;
                        }
                    }
                }
            }
            token->end_column = *column;
            return token;
        } else if (current == '+' || current == '-' || current == '*' || current == '/' || current == '>' || current == '<' || current == '=') {
            Token* token = new Token;
            token->begin_column = *column;
            token->line = *line;
            token->type = tok_binary_operator;
            std::string content;
            content += current;
            token->content = content;
            *column += 1;
            *index += 1;
            if (*index < text.length()) {
                if (text[*index] == '=') {
                    token->content += text[*index];
                    *column += 1;
                    *index += 1;
                } else if (text[*index] == '/') {
                    *column += 1;
                    *index += 1;
                    while (*index < text.length()) {
                        if (text[*index] != '\n') {
                            *column += 1;
                            *index += 1;
                        } else {
                            break;
                        }
                    }
                    return tokenize(text, line, column, index);
                }
            }
            token->end_column = *column;
            return token;
        } else {
            Token* token = new Token;
            token->begin_column = *column;
            token->line = *line;
            token->type = tok_char;
            std::string content;
            content += current;
            token->content = content;
            *column += 1;
            *index += 1;
            token->end_column = *column;
            return token;
        }
    } else {
        Token* token = new Token;
        token->begin_column = *column;
        token->end_column = *column;
        token->line = *line;
        token->type = tok_eof;
        return token;
    }
}

Tokens::Tokens(std::string path) {

    this->path = path;
    this->index = 0;

    std::ifstream t(this->path);
    std::stringstream buffer;
    buffer << t.rdbuf();
    std::string text = buffer.str();
    t.close();

    size_t line = 1;
    size_t column = 1;
    size_t index = 0;
    Token* token = tokenize(text, &line, &column, &index);
    while (token->type != tok_eof) {
        this->tokens.push_back(token);
        token = tokenize(text, &line, &column, &index);
    }
    this->tokens.push_back(token); // push eof

}

void Tokens::println(std::string message, size_t token_index) {
    Token* token = this->tokens[token_index];

    std::cout << this->path << ":" << token->line << ":" << token->begin_column 
    << " " << COLOR_RED << message << COLOR_RESET << std::endl;

    std::cout << "  " << COLOR_BLACK << token->line << " " << "|" << COLOR_RESET;
    std::string sub("  ");
    std::string t;
    t += token->line;
    for (size_t i = 0; i < t.length(); i++) {
        sub += " ";
    }
    sub += COLOR_BLACK;
    sub += " |";
    sub += COLOR_RESET;
    size_t ltc = 0;
    for (size_t i = 0; i < this->tokens.size(); i++) {
        Token* tk = this->tokens[i];
        if (tk->line == token->line) {
            if (tk->begin_column - ltc != 0) {
                std::cout << " ";
                sub += " ";
            }
            ltc = tk->end_column;
            std::cout << tk->content;
            sub += COLOR_RED;
            for (size_t j = 0; j < tk->content.length(); j++) {
                if (token_index == i) {
                    sub += "^";
                } else {
                    sub += " ";
                }
            }
            sub += COLOR_RESET;
        }
    }
    std::cout << std::endl << sub << std::endl << std::endl;
}

Token* Tokens::current() {
    return this->tokens[this->index];
}

char Tokens::cu_char() {
    return this->current()->content[0];
}

void Tokens::consume() {
    if (this->tokens[this->index]->type != tok_eof) {
        this->index += 1;
    }
}

void Tokens::next() {
    this->consume();
    if (this->tokens[this->index]->type == tok_eof) {
        this->println("unexpected end of file", this->index - 1);
        exit(EXIT_FAILURE);
    }
}
