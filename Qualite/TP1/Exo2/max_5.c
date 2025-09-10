#include "max_5.h"

int max(int a, int b, int c, int d, int e)
{
    int res = a;
    if (res < b)
        res = b;
    if (res < c)
        res = c;
    if (res < d)
        res = d;
    if (res < e)
        res = e;
    return res;
}