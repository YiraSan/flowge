#ifndef _AST_H
#define _AST_H 1

#include "tokens.h"

class Function;

#include "codegen.h"

#include <memory>
#include <map>

class Expression {
public:
    virtual ~Expression() = default;

    virtual llvm::Value* codegen(Level* level, std::string return_type) = 0;
};

union NumberValue {
    unsigned long integer;
    double floating;
};

class NumberExpression : public Expression {
public:
    size_t token_index;
    NumberValue value;
    bool is_float;

    llvm::Value* codegen(Level* level, std::string return_type) override;
};

class ReferenceExpression : public Expression {
public:
    std::string ref;
    size_t ref_index;

    llvm::Value* codegen(Level* level, std::string return_type) override;
};

class BinaryTreeExpression : public Expression {
public:
    Expression* left;
    std::string op;
    size_t op_index;
    Expression* right;

    llvm::Value* codegen(Level* level, std::string return_type) override;
};

class CallExpression : public Expression {
public:
    std::vector<Expression*> expressions;
    ReferenceExpression* ref;

    llvm::Value* codegen(Level* level, std::string return_type) override;
};

class ReturnExpression : public Expression {
public:
    size_t return_index;
    Expression* expression;

    llvm::Value* codegen(Level* level, std::string return_type) override;
};

class BlockExpression : public Expression {
public:
    Level* level;
    std::vector<Expression*> expressions;

    llvm::Value* codegen(Level* level, std::string return_type) override;
};

struct FnParameter {
    std::string name;
    size_t name_index;
    std::string type;
    size_t type_index;
};

class Function {
public:
    Tokens* file_tokens;

    std::string name;
    size_t name_index;
    std::vector<FnParameter*> parameters;
    std::string return_type;
    size_t return_type_index;

    BlockExpression* block;

    Level* level;
    llvm::Function* llvm_fn;

    void codegen();
};

#endif // _AST_H
