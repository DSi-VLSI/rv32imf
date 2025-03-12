#include "io.c"

enum Weekday { Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday };

int main () {
  enum Weekday today = Wednesday;

  printf("Today is: %d\n", today);

  return 0;
}
