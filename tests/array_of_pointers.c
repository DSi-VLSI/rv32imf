#include "io.c"

int main () {
  const char *arr[] = {"Hello", "World", "Array", "of", "Pointers"};

  // Test array of pointers
  for (int i = 0; i < 5; i++) {
    printf("arr[%d] = %s\n", i, arr[i]);
  }

  return 0;
}
