#include "result-case.h"

int caseResult(int a, int b, int c)
{
    if (a == b || b == c || a == c)
        return 0;
    if (a <= b && a <= c)
        return 1;
    if (b <= a && a <= c)
        return 2;
    if (c <= a && c <= b)
        return 3;
    // Dans quel ordre sont rangés a,b et c ici ?
    return 2;
}