#include "euclidean.h"

void euclidianDiv(int a, int b, int *q, int *r)
{
    *q = 0;
    *r = a;
    /*@ loop invariant I1: *r >= 0;
        loop invariant I2: a == b * *q + *r;
        loop assigns *r,*q;
        loop variant *r;
    */
    while (*r >= b)
    {
        *r = *r - b;
        *q = *q + 1;
    }
    return;
}