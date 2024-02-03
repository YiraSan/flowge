#include "ast.h"

int main() {
    std::cout << "🐉 flowge" << COLOR_MAGENTA << " 0.1n" << COLOR_RESET << std::endl << std::endl;

    std::shared_ptr<Tokens> tokens = std::make_shared<Tokens>("example/main.flg");
    std::unique_ptr<Function> function = std::make_unique<Function>(tokens);

    std::unique_ptr<Codegen> codegen = std::make_unique<Codegen>();

    return EXIT_SUCCESS;
}
