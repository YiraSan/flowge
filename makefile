build:
	clang++-17 -g source/main.cpp `llvm-config-17 --cxxflags --ldflags --system-libs --libs core orcjit native` -o flowge

run: build
	@ echo " "
	@ ./flowge