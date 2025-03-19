#include "io.c"
#include "string.h"

int main () {
  char str1[100] = "Hello";
  char str2[100] = "World";
  char str3[100];

  // Test strcat
  strcat(str1, str2);
  printf("Concatenated string: %s\n", str1);

  // Test strcpy
  strcpy(str3, str1);
  printf("Copied string: %s\n", str3);

  // Test strlen
  printf("Length of string: %lu\n", strlen(str3));

  // Test strcmp
  printf("Comparison result: %d\n", strcmp(str1, str3));

  return 0;
}
