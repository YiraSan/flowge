#include "codegen.h"

Level::Level(Level* parent, Codegen* codegen) {
    this->parent = parent;
    this->codegen = codegen;
}

Level* Level::make_sub() {
    return new Level(this, this->codegen);
}

void Level::add_type(std::string name, llvm::Type* type) {
    this->types[name] = type;
}

llvm::Type* Level::get_type(std::string name) {
    if (this->types.find(name) != this->types.end()) {
        return this->types[name];
    }

    if (this->parent != nullptr) {
        llvm::Type* p = this->parent->get_type(name);
        if (p != nullptr) {
            return p;
        }
    }

    return nullptr;
}

void Level::add_value(std::string name, llvm::Value* value) {
    this->values[name] = value;
}

llvm::Value* Level::get_value(std::string name) {
    if (this->values.find(name) != this->values.end()) {
        return this->values[name];
    }

    if (this->parent != nullptr) {
        llvm::Value* p = this->parent->get_value(name);
        if (p != nullptr) {
            return p;
        }
    }

    return nullptr;
}

void Level::add_function(Function* function) {

    if (this->get_type(function->name) != nullptr) {
        function->file_tokens->println("function cannot overwrite a type", function->name_index);
        exit(EXIT_FAILURE);
    }
    
    if (this->functions.find(function->name) != this->functions.end()) {
        auto fn = this->functions[function->name];
        fn->file_tokens->println("first definition here", fn->name_index);
        function->file_tokens->println("redefinition here", function->name_index);
        exit(EXIT_FAILURE);
    }

    function->level = this->make_sub();
    
    std::vector<llvm::Type *> parameters;
    for (size_t i = 0; i < function->parameters.size(); i++) {
        llvm::Type* type = this->get_type(function->parameters[i]->type);
        if (type == nullptr) {
            function->file_tokens->println("unknown type", function->parameters[i]->type_index);
            exit(EXIT_FAILURE);
        }
        parameters.push_back(type);
    }

    llvm::Type* return_type = this->get_type(function->return_type);
    if (return_type == nullptr) {
        function->file_tokens->println("unknown type", function->return_type_index);
        exit(EXIT_FAILURE);
    }

    llvm::FunctionType* fn_type = llvm::FunctionType::get(return_type, parameters, false);
    llvm::Function* fn = llvm::Function::Create(fn_type, llvm::Function::ExternalLinkage, function->name, this->codegen->llvm_module.get());

    function->llvm_fn = fn;

    this->functions[function->name] = function;

}

Codegen::Codegen() {
    this->llvm_context = std::make_unique<llvm::LLVMContext>();
    this->llvm_module = std::make_unique<llvm::Module>("flowge", *this->llvm_context);
    this->llvm_builder = std::make_unique<llvm::IRBuilder<>>(*this->llvm_context);

    this->top_level = new Level(nullptr, this);

    this->top_level->add_type("void", this->llvm_builder->getVoidTy());
    this->top_level->add_type("bool", this->llvm_builder->getInt1Ty());

    this->top_level->add_type("u8", this->llvm_builder->getInt8Ty());
    this->top_level->add_type("u16", this->llvm_builder->getInt16Ty());
    this->top_level->add_type("u32", this->llvm_builder->getInt32Ty());
    this->top_level->add_type("u64", this->llvm_builder->getInt64Ty());
    this->top_level->add_type("u128", this->llvm_builder->getInt128Ty());
}

std::string Codegen::print() {
    std::string result;
    llvm::raw_string_ostream buffer(result);
    this->llvm_module->print(buffer, nullptr);
    return result;
}

#include <fstream>
  

void Codegen::write(std::string file_path) {
    std::string content = this->print();
    std::ofstream file;
    file.open(file_path);
    file << content;
    file.close();
}

// expression codegen

void Function::codegen() {
    size_t i = 0;
    for (auto &arg : this->llvm_fn->args()) {
        auto t = this->level->get_type(this->parameters[i]->name);
        if (t != nullptr) {
            this->file_tokens->println("type is already defined with this name", this->parameters[i]->name_index);
            exit(EXIT_FAILURE);
        }
        arg.setName(this->parameters[i]->name);
        this->level->add_value(this->parameters[i]->name, (llvm::Value*) &arg);
        i += 1;
    }
    if (this->block != nullptr) {
        llvm::BasicBlock* bb = llvm::BasicBlock::Create(*this->level->codegen->llvm_context, "entry", this->llvm_fn);
        this->level->codegen->llvm_builder->SetInsertPoint(bb);
        this->block->codegen(this->level, this->return_type);
    }
}

llvm::Value* NumberExpression::codegen(Level* level, std::string return_type) {
    // todo: check return type
    auto t = level->get_type(return_type);
    if (this->is_float) {
        return llvm::ConstantFP::get(t, llvm::APFloat(this->value.floating));
    } else {
        
        return llvm::ConstantInt::get(t, llvm::APInt(t->getIntegerBitWidth(), this->value.integer, false));
    }
    return nullptr;
}

llvm::Value* ReferenceExpression::codegen(Level* level, std::string return_type) {
    return level->get_value(this->ref);
}

llvm::Value* BinaryTreeExpression::codegen(Level* level, std::string return_type) {
    llvm::Value* left = this->left->codegen(level, return_type);
    llvm::Value* right = this->right->codegen(level, return_type);

    // todo check return type

    if (this->op == "+") {
        return level->codegen->llvm_builder->CreateAdd(left, right, "addtmp");
    } else if (this->op == "-") {
        return level->codegen->llvm_builder->CreateSub(left, right, "subtmp");
    } else if (this->op == "*") {
        return level->codegen->llvm_builder->CreateMul(left, right, "multmp");
    } else if (this->op == "/") {
        return level->codegen->llvm_builder->CreateUDiv(left, right, "divtmp");
    } else {
        std::cout << "todo operator unsupported" << std::endl;
        exit(EXIT_FAILURE);
    }
}

llvm::Value* CallExpression::codegen(Level* level, std::string return_type) {
    return nullptr;
}

llvm::Value* ReturnExpression::codegen(Level* level, std::string return_type) {
    if (this->expression == nullptr) {
        // todo: check return type
        level->codegen->llvm_builder->CreateRetVoid();
    } else {
        // todo: check return type
        llvm::Value* expr = this->expression->codegen(level, return_type);
        level->codegen->llvm_builder->CreateRet(expr);
    }
    return nullptr;
}

llvm::Value* BlockExpression::codegen(Level* level, std::string return_type) {
    for (size_t i = 0; i < this->expressions.size(); i++) {
        this->expressions[i]->codegen(level, return_type);
    }
    return nullptr;
}
