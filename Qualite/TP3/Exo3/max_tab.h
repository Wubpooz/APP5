#include "limits.h"

/*@ requires \valid_read(tab + (0 .. n-1));
  @ requires n >= 1;
  @ ensures \forall int j; 0 <= j <= n-1 ==> tab[j] <= \result;
  @ ensures \exists int j; 0 <= j <= n-1 && tab[j] == \result;
*/
int max_tab(int *tab, int n);