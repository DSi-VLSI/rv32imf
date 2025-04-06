#include "io.c"

int main () {
  int a = 10;
  int *p = &a;

  // Test pointer dereference
  printf("Value of a: %d\n", a);
  printf("Value of *p: %d\n", *p);

  // Test pointer address
  printf("Address of a: %p\n", (void*)&a);
  printf("Address stored in p: %p\n", (void*)p);

  return 0;
}
