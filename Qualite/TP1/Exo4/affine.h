#include "limits.h"

/*@ requires -2147483648 ≤ (int)(a * x) + b ≤ 2147483647;
requires -2147483648 ≤ a * x ≤ 2147483647; 
ensures \result == \old(a) * \old(x) + \old(b); */
int f(int a, int b, int x);
