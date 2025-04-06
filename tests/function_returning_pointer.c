#include "io.c"

int* getArray() {
  static int arr[5] = {1, 2, 3, 4, 5};
  return arr;
}

int main () {
  int *ptr = getArray();

  // Test function returning pointer
  for (int i = 0; i < 5; i++) {
    printf("Value at ptr[%d] = %d\n", i, ptr[i]);
  }

  return 0;
}
