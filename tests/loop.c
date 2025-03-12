#include "io.c"

int main () {
  int sum = 0;

  // Test for loop
  for (int i = 1; i <= 10; i++) {
    sum += i;
  }
  printf("Sum of first 10 natural numbers using for loop: %d\n", sum);

  // Test while loop
  sum = 0;
  int i = 1;
  while (i <= 10) {
    sum += i;
    i++;
  }
  printf("Sum of first 10 natural numbers using while loop: %d\n", sum);

  // Test do-while loop
  sum = 0;
  i = 1;
  do {
    sum += i;
    i++;
  } while (i <= 10);
  printf("Sum of first 10 natural numbers using do-while loop: %d\n", sum);

  return 0;
}
