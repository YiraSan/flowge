#include "codegen.h"

Level::Level(std::shared_ptr<Level> parent) {
    this->parent = parent;
}

Codegen::Codegen() {
    this->llvm_context = std::make_unique<llvm::LLVMContext>();
    this->llvm_module = std::make_unique<llvm::Module>("flowge", *this->llvm_context);
    this->llvm_builder = std::make_unique<llvm::IRBuilder<>>(*this->llvm_context);

    this->top_level = std::make_shared<Level>(nullptr);
}
