#include "io.c"

int main () {
  const int a = 10;
  const int *ptr = &a;

  printf("Value of a: %d\n", a);
  printf("Value pointed by ptr: %d\n", *ptr);

  return 0;
}
