#include "io.c"

typedef unsigned long ulong;
typedef int (*func_ptr)(int, int);

int add(int a, int b) {
  return a + b;
}

int main () {
  ulong num = 1000000;
  func_ptr f = add;

  printf("Number: %lu\n", num);
  printf("Function pointer result: %d\n", f(10, 20));

  return 0;
}
