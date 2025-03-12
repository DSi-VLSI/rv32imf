#include "io.c"

int main () {
  int a = 10, b = 20;

  // Test if-else statement
  if (a > b) {
    printf("%d is greater than %d\n", a, b);
  } else {
    printf("%d is not greater than %d\n", a, b);
  }

  // Test switch statement
  int day = 3;
  switch (day) {
    case 1:
      printf("Monday\n");
      break;
    case 2:
      printf("Tuesday\n");
      break;
    case 3:
      printf("Wednesday\n");
      break;
    case 4:
      printf("Thursday\n");
      break;
    case 5:
      printf("Friday\n");
      break;
    case 6:
      printf("Saturday\n");
      break;
    case 7:
      printf("Sunday\n");
      break;
    default:
      printf("Invalid day\n");
  }

  return 0;
}
