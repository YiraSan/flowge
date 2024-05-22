#include "ast.h"
#include "parser.h"

int main() {
    std::cout << "; 🐉 flowge" << COLOR_MAGENTA << " 0.1n" << COLOR_RESET << std::endl << std::endl;

    Codegen* codegen = new Codegen();
    Tokens* tokens = new Tokens("example/main.flg");

    auto tok = tokens->current();
    while (tok->type != tok_eof) {
        if (tok->content != "fn") {
            tokens->println("unexpected token", tokens->index);
            exit(EXIT_FAILURE);
        }
        Function* function = parseFunction(tokens);
        codegen->top_level->add_function(function);
        tok = tokens->current();
    }

    for (auto i : codegen->top_level->functions) {
        i.second->codegen();
    }

    std::cout << codegen->print() << std::endl;

    return EXIT_SUCCESS;
}
