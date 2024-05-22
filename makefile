build:
	clang++-18 -g source/main.cpp source/tokens.cpp source/parser.cpp source/codegen.cpp `llvm-config-18 --cxxflags --ldflags --system-libs --libs core orcjit native` -o flowge.bin

run: build
	@ echo " "
	@ ./flowge.bin

build-bin: build
	@ ./flowge.bin >> mod.ll
	@ llc-18 mod.ll
	@ mv mod.ll mod.ir
