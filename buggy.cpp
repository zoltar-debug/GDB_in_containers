#include <iostream>
#include <vector>
#include <string>
#include <cstring>

// ──────────────────────────────────────────────
//  Demo 1: Classic null-pointer dereference
// ──────────────────────────────────────────────
void null_ptr_deref() {
    std::cout << "[demo] null_ptr_deref()\n";
    int* p = nullptr;
    *p = 42;          // BOOM
}

// ──────────────────────────────────────────────
//  Demo 2: Stack buffer overflow
// ──────────────────────────────────────────────
void stack_overflow() {
    std::cout << "[demo] stack_overflow()\n";
    char buf[8];
    // strcpy has no bounds check — writes past buf
    strcpy(buf, "This string is way too long for the buffer!");
}

// ──────────────────────────────────────────────
//  Demo 3: Use-after-free
// ──────────────────────────────────────────────
void use_after_free() {
    std::cout << "[demo] use_after_free()\n";
    int* p = new int(100);
    delete p;
    std::cout << "value after free: " << *p << "\n";  // undefined behaviour → often segfault
    *p = 999;                                          // write after free — more reliably crashes
}

// ──────────────────────────────────────────────
//  Demo 4: Out-of-bounds vector access
// ──────────────────────────────────────────────
void oob_vector() {
    std::cout << "[demo] oob_vector()\n";
    std::vector<int> v = {1, 2, 3};
    // operator[] does no bounds checking
    std::cout << v[1000000] << "\n";
}

// ──────────────────────────────────────────────
//  Demo 5: Infinite recursion → stack exhaustion
// ──────────────────────────────────────────────
int recurse(int n) {
    return recurse(n + 1);   // no base case
}

void stack_exhaustion() {
    std::cout << "[demo] stack_exhaustion()\n";
    recurse(0);
}

// ──────────────────────────────────────────────
//  Entry point — pick your crash scenario
// ──────────────────────────────────────────────
int main(int argc, char* argv[]) {
    std::cout << "=== GDB Lunch & Learn — crash demo ===\n";
    std::cout << "Usage: " << argv[0] << " <1-5>\n";
    std::cout << "  1 = null pointer dereference\n";
    std::cout << "  2 = stack buffer overflow\n";
    std::cout << "  3 = use-after-free\n";
    std::cout << "  4 = out-of-bounds vector\n";
    std::cout << "  5 = stack exhaustion\n\n";

    int choice = (argc > 1) ? std::stoi(argv[1]) : 1;

    switch (choice) {
        case 1: null_ptr_deref();    break;
        case 2: stack_overflow();    break;
        case 3: use_after_free();    break;
        case 4: oob_vector();        break;
        case 5: stack_exhaustion();  break;
        default:
            std::cerr << "Unknown demo. Pick 1–5.\n";
            return 1;
    }

    std::cout << "If you see this, no crash occurred.\n";
    return 0;
}
