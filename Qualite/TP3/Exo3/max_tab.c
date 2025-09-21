#include "max_tab.h"

int max_tab(int* tab, int n){
	int i = 0;
	int max = tab[0];
  /*@ loop invariant 0 <= i <= n;
    @ loop invariant \forall int j; 0 <= j < i ==> tab[j] <= max;
    @ loop invariant max == tab[0] || \exists int j; 0 <= j < n && tab[j] == max;
    @ loop assigns i, max;
    @ loop variant n - i;
  */ 
	while(i < n){
		if(max < tab[i]) max = tab[i];
		i++;
	}
	return max;
}
