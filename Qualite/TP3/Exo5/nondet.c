#include "nondet.h"

int nondet(int a)
{
	int res = 0;
	while (a > 0)
	{
		int b = randInt(a);
		if (b > 0)
			res += b + 1;
		a -= b;
	}
	return res;
}