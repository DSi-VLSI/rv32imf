#include "io.c"
#include "stdlib.h"

int main () {
  int *arr;
  int n = 5;

  // Allocate memory
  arr = (int*)malloc(n * sizeof(int));
  if (arr == NULL) {
    printf("Memory allocation failed\n");
    return 1;
  }

  // Initialize and print array
  for (int i = 0; i < n; i++) {
    arr[i] = i + 1;
    printf("arr[%d] = %d\n", i, arr[i]);
  }

  // Free allocated memory
  free(arr);

  return 0;
}
