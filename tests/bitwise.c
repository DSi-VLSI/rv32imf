#include "io.c"

int main () {
  int a = 5;  // 0101 in binary
  int b = 3;  // 0011 in binary

  printf("Bitwise AND: %d & %d = %d\n", a, b, a & b); // 0001 in binary
  printf("Bitwise OR: %d | %d = %d\n", a, b, a | b);  // 0111 in binary
  printf("Bitwise XOR: %d ^ %d = %d\n", a, b, a ^ b); // 0110 in binary
  printf("Bitwise NOT: ~%d = %d\n", a, ~a);           // 1010 in binary (two's complement)
  printf("Left shift: %d << 1 = %d\n", a, a << 1);    // 1010 in binary
  printf("Right shift: %d >> 1 = %d\n", a, a >> 1);   // 0010 in binary

  return 0;
}
