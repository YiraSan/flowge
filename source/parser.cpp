#include "parser.h"

Function* parseFunction(Tokens* tokens) {
    Function* fn = new Function();

    fn->file_tokens = tokens;
    fn->block = nullptr;

    tokens->next(); // eat "fn"

    if (tokens->current()->type != tok_identifier) {
        tokens->println("expected function identifier", tokens->index);
        exit(EXIT_FAILURE);
    }
    fn->name = tokens->current()->content;
    fn->name_index = tokens->index;
    tokens->next(); // eat identifier

    if (tokens->cu_char() != '(') {
        tokens->println("expected '('", tokens->index);
        exit(EXIT_FAILURE);
    }
    tokens->next(); // eat '('

    while (tokens->cu_char() != ')') {
        FnParameter* parameter = new FnParameter();
        
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

        fn->parameters.push_back(parameter);

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
        fn->return_type = tokens->current()->content;
        fn->return_type_index = tokens->index;
        tokens->next(); // eat identifier
    } else {
        fn->return_type = "void";
        fn->return_type_index = fn->name_index;
    }
    
    if (tokens->cu_char() == '{') {
        fn->block = parseBlock(tokens);
    } else if (tokens->cu_char() == ';') {
        tokens->consume(); // eat ';'
        fn->block = nullptr;
    } else {
        tokens->println("expected ';' or '{'", tokens->index);
        exit(EXIT_FAILURE);
    }

    return fn;
}

Expression* parseIdentifier(Tokens* tokens) {
    ReferenceExpression* expr = new ReferenceExpression();
    expr->ref = tokens->current()->content;
    expr->ref_index = tokens->index;
    tokens->consume(); // eat identifier

    if (tokens->cu_char() == '(') {
        CallExpression* call = new CallExpression();
        call->ref = expr;

        tokens->next(); // eat '('

        while (tokens->cu_char() != ')') {
            Expression* expression = parseExpression(tokens);
            call->expressions.push_back(expression);
            if (tokens->cu_char() == ',') {
                tokens->next(); // eat ','
            } else if (tokens->cu_char() != ')') {
                tokens->println("expected ',' or ')'", tokens->index);
                exit(EXIT_FAILURE);
            }
        }

        tokens->consume(); // eat ')'

        return call;
    }

    return expr;
}

Expression* parseNumber(Tokens* tokens) {
    NumberExpression* expr = new NumberExpression();
    auto tok = tokens->current();
    expr->token_index = tokens->index;
    if (tok->content.find('.') == std::string::npos) {
        expr->is_float = false;
        std::string prefix = tok->content.substr(0, 2);
        if (prefix == "0x") {
            for (size_t i = 2; i < tok->content.length(); i++) {
                char ch = tok->content[i];
                if ((ch < '0' || ch > '9') && (ch < 'A' || ch > 'F') && (ch < 'a' || ch > 'f')) {
                    tokens->println("invalid hexadecimal representation", tokens->index);
                    exit(EXIT_FAILURE);
                }
            }
            char* endp; 
            expr->value.integer = strtoull(tok->content.substr(2).c_str(), &endp, 16);
        } else if (prefix == "0o") {
            for (size_t i = 2; i < tok->content.length(); i++) {
                char ch = tok->content[i];
                if (ch < '0' || ch > '7') {
                    tokens->println("invalid octal representation", tokens->index);
                    exit(EXIT_FAILURE);
                }
            }
            char* endp; 
            expr->value.integer = strtoull(tok->content.substr(2).c_str(), &endp, 8);
        } else if (prefix == "0b") {
            for (size_t i = 2; i < tok->content.length(); i++) {
                char ch = tok->content[i];
                if (ch != '0' && ch != '1') {
                    tokens->println("invalid binary representation", tokens->index);
                    exit(EXIT_FAILURE);
                }
            }
            char* endp; 
            expr->value.integer = strtoull(tok->content.substr(2).c_str(), &endp, 2);
        } else {
            for (size_t i = 0; i < tok->content.length(); i++) {
                char ch = tok->content[i];
                if (ch < '0' || ch > '9') {
                    tokens->println("invalid decimal representation", tokens->index);
                    exit(EXIT_FAILURE);
                }
            }
            char* endp;
            expr->value.integer = strtoull(tok->content.c_str(), &endp, 10);
        }
    } else {
        expr->is_float = true;
        for (size_t i = 0; i < tok->content.length(); i++) {
            char ch = tok->content[i];
            if (ch == '.') {
                continue;
            } else if (ch < '0' || ch > '9') {
                tokens->println("float must only contain digits", tokens->index);
                exit(EXIT_FAILURE);
            }
        }
        char* endp;
        expr->value.floating = strtod(tok->content.c_str(), &endp);
    }
    tokens->consume(); // eat number
    return expr;
}

uint8_t precedence(std::string op) {
    if (op == "=" || op == "+=" || op == "-=" || op == "*=" || op == "/=") { // define
        return 10;
    } else if (op == "==" || op == ">" || op == ">=" || op == "<" || op == "<=" || op == "!=") {
        return 20;
    } else if (op == "+" || op == "-") {
        return 30;
    } else if (op == "*" || op == "/") {
        return 40;
    }
    std::cout << "panic: unknown operator" << std::endl;
    exit(EXIT_FAILURE);
}

Expression* parseBinaryOPRHS(Tokens* tokens, uint8_t last_precedence, Expression* left) {
    Expression* lhs = left;
    while (true) {
        Token* current = tokens->current();
        if (current->type == tok_binary_operator) {
            size_t op_index = tokens->index;
            std::string op = current->content;
            if (precedence(op) < last_precedence) {
                return lhs;
            } else {
                tokens->next(); // eat operand
                Expression* right = parsePrimaryExpression(tokens);
                if (tokens->current()->type == tok_binary_operator) {
                    std::string op2 = tokens->current()->content;
                    if (precedence(op) < precedence(op2)) {
                        right = parseBinaryOPRHS(tokens, precedence(op) + 1, right);
                    }
                }
                BinaryTreeExpression* binary_tree = new BinaryTreeExpression();
                binary_tree->left = lhs;
                binary_tree->right = right;
                binary_tree->op = op;
                binary_tree->op_index = op_index;
                lhs = binary_tree;
            }
        } else {
            return lhs;
        }
    }
}

Expression* parseParenthesis(Tokens* tokens) {
    tokens->next(); // eat '('
    Expression* expr = parseExpression(tokens);
    if (tokens->cu_char() != ')') {
        tokens->println("expected ')'", tokens->index);
        exit(EXIT_FAILURE);
    }
    tokens->consume(); // eat ')'
    return expr;
}

Expression* parsePrimaryExpression(Tokens* tokens) {
    auto current = tokens->current();
    if (current->type == tok_identifier) {
        return parseIdentifier(tokens);
    } else if (current->type == tok_number) {
        return parseNumber(tokens);
    } else if (current->type == tok_char) {
        auto ch = tokens->cu_char();
        if (ch == '(') {
            return parseParenthesis(tokens);
        } else if (ch == '{') {
            return parseBlock(tokens);
        } else {
            tokens->println("todo: unary operator", tokens->index);
            exit(EXIT_FAILURE);
        }
    } else if (current->type == tok_if) {
        return parseIf(tokens);
    }
    tokens->println("unexpected token", tokens->index);
    exit(EXIT_FAILURE);
}

Expression* parseExpression(Tokens* tokens) {
    return parseBinaryOPRHS(tokens, 0, parsePrimaryExpression(tokens));
}

BlockExpression* parseBlock(Tokens* tokens) {
    BlockExpression* block = new BlockExpression();
    tokens->next(); // eat '{'
    while (tokens->cu_char() != '}') {
        if (tokens->current()->content == "return") {
            ReturnExpression* ret = new ReturnExpression();
            ret->return_index = tokens->index;
            tokens->next(); // eat "return"
            if (tokens->cu_char() != ';') {
                ret->expression = parseExpression(tokens);
            } else {
                ret->expression = nullptr;
            }
            block->expressions.push_back(ret);
        } else {
            block->expressions.push_back(parseExpression(tokens));
        }
        if (tokens->cu_char() != ';') {
            tokens->println("expected ';'", tokens->index);
            exit(EXIT_FAILURE);
        }
        tokens->next(); // eat ';'
    }
    tokens->consume(); // eat '}'
    return block;
}

Expression* parseIf(Tokens* tokens) {
    IfExpression* if_expr = new IfExpression();
    tokens->next(); // eat 'if'
    if_expr->condition = parseExpression(tokens);
    if_expr->expression = parseExpression(tokens);
    if (tokens->current()->type == tok_else) {
        tokens->next(); // eat 'else'
        if_expr->else_ = parseExpression(tokens);
    } else {
        if_expr->else_ = nullptr;
    }
    return if_expr;
}
