#ifndef _CODEGEN_H
#define _CODEGEN_H 1

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Type.h"

#include "ast.h"

#include <memory>

class Level {
public:
    std::shared_ptr<Level> parent;
    
    Level(std::shared_ptr<Level> parent);

};

class Codegen {
public:
    std::unique_ptr<llvm::LLVMContext> llvm_context;
    std::unique_ptr<llvm::Module> llvm_module;
    std::unique_ptr<llvm::IRBuilder<>> llvm_builder;

    std::shared_ptr<Level> top_level;

    Codegen();
    
};

#endif // _CODEGEN_H
