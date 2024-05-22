#include "ast.h"
#include "parser.h"

#include <string.h>

std::string FLOWGE_VERSION = "0.1n";

int main(int argc, char *argv[]) {

    if (argc > 1) {
        if (strcmp(argv[1], "build") == 0) {
            if (argc < 4) {
                std::cout << COLOR_RED << "missing source path and output path" << COLOR_RESET << std::endl;
                return EXIT_FAILURE;
            } 

            Codegen* codegen = new Codegen();
            Tokens* tokens = new Tokens(std::string(argv[2]));

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

            codegen->write(std::string(argv[3]));
            return EXIT_SUCCESS;
        } else if (strcmp(argv[1], "version") == 0) {
            std::cout << FLOWGE_VERSION << std::endl;
            return EXIT_SUCCESS;
        }
    }

    std::cout << std::endl;
    std::cout << "🐉 flowge " << COLOR_MAGENTA << FLOWGE_VERSION << COLOR_RESET << std::endl << std::endl;
    std::cout << "    > build" << COLOR_GREEN << " [source path] [output path]" << COLOR_RESET << std::endl;
    std::cout << "        " << COLOR_BLACK << "Build a flowge file to LLVM IR" << COLOR_RESET << std::endl;
    std::cout << std::endl;
    std::cout << "    > version" << std::endl;
    std::cout << "        " << COLOR_BLACK << "Display complete flowge version" << COLOR_RESET << std::endl;
    std::cout << std::endl;
    return EXIT_SUCCESS;
}
