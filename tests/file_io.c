#include "io.c"
#include "stdio.h"

int main () {
  FILE *file;
  char str[100];

  // Write to file
  file = fopen("test.txt", "w");
  if (file == NULL) {
    printf("Failed to open file for writing\n");
    return 1;
  }
  fprintf(file, "Hello, World!\n");
  fclose(file);

  // Read from file
  file = fopen("test.txt", "r");
  if (file == NULL) {
    printf("Failed to open file for reading\n");
    return 1;
  }
  while (fgets(str, 100, file) != NULL) {
    printf("Read from file: %s", str);
  }
  fclose(file);

  return 0;
}
