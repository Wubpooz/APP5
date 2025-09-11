#include "limits.h"

/* Cette fonction assure que pour tout i, si i est entre 0 et n-1, tab[i] = 0.
Elle assure également qu’il existe au moins une telle case.
En ACSL, pour tout k s’écrit "\forall int k;", et il existe k, "\exists int k;".
*/
/*@
  requires n > 0;
  requires \valid(tab + (0 .. n - 1));
  ensures \forall int k; 0 <= k < n ==> tab[k] == 0;
*/
void set_to_zero(int *tab, int n);