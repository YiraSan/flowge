#include "ast.h"

Function::Function(std::shared_ptr<Tokens> tokens) {
    this->file_tokens = tokens;

    tokens->next(); // eat "fn"

    if (tokens->current()->type != tok_identifier) {
        tokens->println("expected function identifier", tokens->index);
        exit(EXIT_FAILURE);
    }
    this->name = tokens->current()->content;
    this->name_index = tokens->index;
    tokens->next(); // eat identifier

    if (tokens->cu_char() != '(') {
        tokens->println("expected '('", tokens->index);
        exit(EXIT_FAILURE);
    }
    tokens->next(); // eat '('

    while (tokens->cu_char() != ')') {
        std::unique_ptr<Parameter> parameter = std::make_unique<Parameter>();
        
        if (tokens->current()->type != tok_identifier) {
            tokens->println("expected identifier", tokens->index);
            exit(EXIT_FAILURE);
        }
        parameter->name = tokens->current()->content;
        parameter->name_index = tokens->index;
        tokens->next(); // eat identifier

        if (tokens->cu_char() != ':') {
            tokens->println("expected ':'", tokens->index);
            exit(EXIT_FAILURE);
        }
        tokens->next(); // eat ':'

        if (tokens->current()->type != tok_identifier) {
            tokens->println("expected a type", tokens->index);
            exit(EXIT_FAILURE);
        }
        parameter->type = tokens->current()->content;
        parameter->type_index = tokens->index;
        tokens->next(); // eat identifier

        this->parameters.push_back(std::move(parameter));

        if (tokens->cu_char() == ',') {
            tokens->next(); // eat ','
        } else if (tokens->cu_char() != ')') {
            tokens->println("expected ',' or ')'", tokens->index);
            exit(EXIT_FAILURE);
        }
    }
    tokens->next(); // eat ')'

    if (tokens->cu_char() == ':') {
        tokens->next(); // eat ':'

        if (tokens->current()->type != tok_identifier) {
            tokens->println("expected a return type", tokens->index);
            exit(EXIT_FAILURE);
        }
        this->return_type = tokens->current()->content;
        this->return_type_index = tokens->index;
        tokens->next(); // eat identifier
    } else {
        this->return_type = "void";
        this->return_type_index = this->name_index;
    }
    
    if (tokens->cu_char() == '{') {
        std::cout << "todo fn body" << std::endl;
        exit(EXIT_FAILURE);
    } else if (tokens->cu_char() == ';') {
        tokens->consume(); // eat ';'
    } else {
        tokens->println("expected ';' or '{'", tokens->index);
        exit(EXIT_FAILURE);
    }

}
