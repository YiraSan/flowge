build:
	@ clang++-18 -g source/main.cpp source/tokens.cpp source/parser.cpp source/codegen.cpp `llvm-config-18 --cxxflags --ldflags --system-libs --libs core orcjit native` -o flowge.bin

build-mistery: build
	@ ./flowge.bin build example/mistery.flg example/mistery.ll
	@ llc-18 example/mistery.ll
	@ mv example/mistery.ll example/mistery.ir
	@ clang++-18 -g example/mistery.cpp example/mistery.s -o example/mistery.bin

run-mistery: build-mistery
	@ ./example/mistery.bin

build-fibonacci: build
	@ ./flowge.bin build example/fibonacci.flg example/fibonacci.ll
	@ llc-18 example/fibonacci.ll
	@ mv example/fibonacci.ll example/fibonacci.ir
	@ clang++-18 -g example/fibonacci.cpp example/fibonacci.s -o example/fibonacci.bin

run-fibonacci: build-fibonacci
	@ ./example/mistery.bin
