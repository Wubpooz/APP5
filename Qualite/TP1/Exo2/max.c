#include "max.h"

int max(int a, int b)
{
	int res = a;
	if (res < b)
		res = b;
	return res;
}