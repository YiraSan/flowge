#ifndef _TOKENS_H
#define _TOKENS_H 1

#include "colors.h"

#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <iostream>

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

class Tokens {
public:
    std::string path;
    std::vector<Token*> tokens;
    size_t index;

    Tokens(std::string path);

    void println(std::string message, size_t token_index);

    Token* current();
    char cu_char();

    void consume();
    void next();
    
};

#endif // _TOKENS_H
