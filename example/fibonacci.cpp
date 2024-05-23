#include <stdint.h>
#include <iostream>

extern "C" uint64_t fibonacci(uint64_t n);

int main() {
    std::cout << "fibonacci(8): " << fibonacci(8) << std::endl;
    return 0;
}
