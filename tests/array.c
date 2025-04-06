#include "io.c"

int main () {
  int arr[5] = {1, 2, 3, 4, 5};
  int sum = 0;

  // Test array sum
  for (int i = 0; i < 5; i++) {
    sum += arr[i];
  }
  printf("Sum of array elements: %d\n", sum);

  // Test array average
  float avg = sum / 5.0;
  printf("Average of array elements: %.2f\n", avg);

  return 0;
}
