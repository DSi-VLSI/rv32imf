#include "io.c"

#define PI 3.14159
#define SQUARE(x) ((x) * (x))

int main () {
  printf("Value of PI: %.5f\n", PI);
  printf("Square of 5: %d\n", SQUARE(5));
  printf("Square of 7+1: %d\n", SQUARE(7+1)); // Demonstrates macro expansion

  return 0;
}
