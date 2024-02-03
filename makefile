build:
	clang++-17 -g source/main.cpp source/tokens.cpp source/parser.cpp source/codegen.cpp `llvm-config-17 --cxxflags --ldflags --system-libs --libs core orcjit native` -o flowge

run: build
	@ echo " "
	@ ./flowge