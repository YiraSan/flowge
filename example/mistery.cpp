#include <stdint.h>
#include <iostream>

extern "C" uint32_t mistery(uint32_t a, uint32_t b);

int main() {
    std::cout << "mistery(8, 10): " << mistery(8, 10) << std::endl;
    std::cout << "8 + 10 * 4: " << 8 + 10 * 4 << std::endl;
    return 0;
}
