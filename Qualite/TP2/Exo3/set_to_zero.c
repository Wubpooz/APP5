#include "set_to_zero.h"

void set_to_zero(int *tab, int n)
{
  /*@ loop invariant 0 <= i <= n;
      loop invariant \forall int k; 0 <= k < i ==> tab[k] == 0;
      loop assigns i, tab[0..n-1];
      loop variant n - i;
  */
	for (int i = 0; i < n; i++)
	{
		tab[i] = 0;
	}
}