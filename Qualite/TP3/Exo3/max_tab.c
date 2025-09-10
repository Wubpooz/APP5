#include "max_tab.h"

int max_tab(int* tab, int n){
	int i = 0;
	int max = tab[0];
	/*@ loop invariant 0 <=  i <= n;
	  @ loop invariant \forall int j; 0 <= j <= i-1 ==> tab[j] <= max;
	  @ loop invariant \exists int j; 0 <= j <= n-1 && tab[j] == max;
	  @ loop assigns i,max;
	*/
	while(i < n){
		if(max < tab[i]) max = tab[i];
		i = (i+1)%n;
	}
	return max;
}