#include "io.c"

volatile int flag = 0;

void setFlag() {
  flag = 1;
}

int main () {
  printf("Initial flag value: %d\n", flag);
  setFlag();
  printf("Flag value after setFlag: %d\n", flag);

  return 0;
}
