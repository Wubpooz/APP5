#include "exo4.h"
#include <stdio.h>

int max_element(const int* t, int n){
  int max = 0;
  /*@
    loop invariant 0 <= i <= n;
    loop invariant max >= 0 && max < n;
    loop invariant \forall integer k; 0 <= k < n ==> t[k] == \at(t[k], Pre);
    loop invariant \forall integer k; 0 <= k < i ==> t[k] <= t[max];
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
    loop invariant \forall integer k; 0 <= k < n ==> b[k] == \at(b[k], Pre);
    loop invariant \forall integer k; 0 <= k < i ==> a[k] == \at(a[k], Pre) + \at(b[k], Pre);
    loop invariant \forall integer k; i <= k < n ==> a[k] == \at(a[k], Pre);
    loop assigns a[0 .. n-1], i;
    loop variant n - i;
  */
	for (int i = 0; i<n; i++){
		a[i] += b[i];
	}
}




int main() {
  int n = 5;
  int a[6] = {1, 2, 3, 4, 5, 6};

  sum_of_tab(a + 1, a, n);
  for (int i = 0; i < n + 1; i++) {
    printf("a[%d] = %d\n", i, a[i]);
  }
  return 0;
}