#include "io.c"

int main () {
  int arr[5] = {1, 2, 3, 4, 5};
  int *ptr = arr;

  // Test pointer increment
  for (int i = 0; i < 5; i++) {
    printf("Value at ptr[%d] = %d\n", i, *(ptr + i));
  }

  // Test pointer decrement
  for (int i = 4; i >= 0; i--) {
    printf("Value at ptr[%d] = %d\n", i, *(ptr + i));
  }

  return 0;
}
