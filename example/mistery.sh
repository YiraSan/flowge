./flowge.bin build example/mistery.flg example/mistery.ll
/opt/homebrew/Cellar/llvm/18.1.6/bin/llc example/mistery.ll
mv example/mistery.ll example/mistery.ir
/opt/homebrew/Cellar/llvm/18.1.6/bin/clang++ -g example/mistery.cpp example/mistery.s -o example/mistery.bin