#include "io.c"

int main () {
  int num;
  char str[100];
  char ch;

  printf("Enter a number: ");
  scanf("%d", &num);
  printf("You entered: %d\n", num);

  printf("Enter a string: ");
  scanf("%s", str);
  printf("You entered: %s\n", str);

  printf("Enter a character: ");
  scanf(" %c", &ch); // Note the space before %c to consume any leftover newline
  printf("You entered: %c\n", ch);

  return 0;
}
