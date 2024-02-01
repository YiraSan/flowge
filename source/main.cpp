#include <memory>
#include <string>
#include <fstream>
#include <sstream>
#include <vector>
#include <iostream>

#define COLOR_BLACK "\e[0;30m"
#define COLOR_RED "\e[0;31m"
#define COLOR_MAGENTA "\e[0;35m"

#define COLOR_RESET "\e[0m"

enum TokenType {
    tok_eof,

    // commands
    tok_fn,

    // primary
    tok_identifier,
    tok_number,
    tok_char,
};

struct Token {
    size_t begin_column;
    size_t end_column;
    size_t line;
    TokenType type;
    std::string content;
};

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
            }
            token->end_column = *column;
            return token;
        } else if (isascii(current) && isdigit(current)) {
            Token* token = new Token;
            token->begin_column = *column;
            token->line = *line;
            token->type = tok_identifier;
            token->content = std::string();
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
            token->end_column = *column;
            return token;
        } else {
            Token* token = new Token;
            token->begin_column = *column;
            token->end_column = *column+1;
            token->line = *line;
            token->type = tok_char;
            std::string content;
            content += current;
            token->content = content;
            *column += 1;
            *index += 1;
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

class Tokens {
public:
    std::string path;
    std::vector<Token*> tokens;

    Tokens(std::string path) {

        this->path = path;

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

    void println(std::string message, size_t token_index) {
        Token* token = this->tokens[token_index];

        std::cout << this->path << ":" << token->line << ":" << token->begin_column 
        << " " << COLOR_RED << message << COLOR_RESET << std::endl;

        std::cout << "  " << COLOR_BLACK << token->line << " " << "|" << COLOR_RESET;
        std::string sub("  ");
        for (size_t i = 0; i < token->line; i++) {
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
};

int main() {
    std::cout << "🐉 flowge" << COLOR_MAGENTA << " 0.1n" << COLOR_RESET << std::endl << std::endl;
    Tokens* tokens = new Tokens("example/main.flg");
    tokens->println("yay", 11);
    return 0;
}
