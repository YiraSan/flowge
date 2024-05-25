./flowge.bin build example/fibonacci.flg example/fibonacci.ll
/opt/homebrew/Cellar/llvm/18.1.6/bin/llc example/fibonacci.ll
mv example/fibonacci.ll example/fibonacci.ir
/opt/homebrew/Cellar/llvm/18.1.6/bin/clang++ -g example/fibonacci.cpp example/fibonacci.s -o example/fibonacci.bin