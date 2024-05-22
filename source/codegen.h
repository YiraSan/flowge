#ifndef _CODEGEN_H
#define _CODEGEN_H 1

#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Type.h"

class Level;
class Codegen; // useless ? todo

#include "ast.h"

#include <memory>
#include <map>

class Level {
public:
    Level* parent;
    Codegen* codegen;
    std::map<std::string, Function*> functions;
    std::map<std::string, llvm::Value*> values;
    std::map<std::string, llvm::Type*> types;
    
    Level(Level* parent, Codegen* codegen);

    Level* make_sub();

    void add_type(std::string name, llvm::Type* type);
    llvm::Type* get_type(std::string name);

    void add_value(std::string name, llvm::Value* value);
    llvm::Value* get_value(std::string name);

    void add_function(Function* function);

};

class Codegen {
public:
    std::unique_ptr<llvm::LLVMContext> llvm_context;
    std::unique_ptr<llvm::Module> llvm_module;
    std::unique_ptr<llvm::IRBuilder<>> llvm_builder;

    Level* top_level;

    Codegen();

    std::string print();
    
};

#endif // _CODEGEN_H
