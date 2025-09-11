#include "plus_one.h"
#include "div.h"
#include <stdio.h>

int good_call_1(void)
{
    return plus_one(4);
}

int bad_call_1(void)
{
    return plus_one(-345);
}

int bad_call_2(void)
{
    return plus_one(INT_MAX);
}

int good_call_2(void)
{
    return div(45, 73);
}

int good_call_3(void)
{
    return div(0, 74);
}

int bad_call_3(void)
{
    return div(74, 0);
}

int good_call_4(void)
{
    return div(INT_MAX, INT_MIN);
}

int good_call_5(void)
{
    return div(INT_MAX, -1);
}

int bad_call_4(void)
{
    return div(INT_MIN, -1);
}


int main() {
  // testing the output of the bad calls
  int res1 = bad_call_1();
  printf("Result of bad_call_1: %d\n", res1);
  int res2 = bad_call_2();
  printf("Result of bad_call_2: %d\n", res2);
  int res3 = bad_call_3();
  printf("Result of bad_call_3: %d\n", res3);
  int res4 = bad_call_4();
  printf("Result of bad_call_4: %d\n", res4);
  return 0;
}