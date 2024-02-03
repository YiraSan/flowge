#ifndef _AST_H
#define _AST_H 1

#include "tokens.h"
#include "codegen.h"

struct Parameter {
    std::string name;
    size_t name_index;
    std::string type;
    size_t type_index;
};

class Function {
public:
    std::shared_ptr<Tokens> file_tokens;

    // Parser
    std::string name;
    size_t name_index;
    std::vector<std::unique_ptr<Parameter>> parameters;
    std::string return_type;
    size_t return_type_index;

    Function(std::shared_ptr<Tokens> tokens);

    // Codegen
    

};

#endif // _AST_H
