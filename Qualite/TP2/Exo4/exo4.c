#include "exo4.h"

int max_element(const int* t, int n){
	int max = 0;
  /*@
    loop invariant 0 <= i <= n;
    loop invariant max >= 0 && max < n;
    loop assigns max, i;
    loop variant n - i;
  */
	for (int i = 0; i < n; i++){
		if (t[max] < t[i]) max = i;
	}
	return max;
}

void sum_of_tab(int *a, int *b, int n){
  /*@
    loop invariant 0 <= i <= n;
    loop assigns a[0 .. n-1], i;
    loop variant n - i;
  */
	for (int i = 0; i<n; i++){
		a[i] += b[i];
	}
}