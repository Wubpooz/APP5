#include "limits.h"

/*@ 
  requires 0 < n <= INT_MAX;
  requires \valid(t + (0 .. n - 1));
  requires \separated(t + (0 .. n - 1), t);
  assigns t[0 .. n-1];
  ensures \forall int i; 0 <= i < n ==> t[i] <= t[\result];
  ensures \forall int i; 0 <= i < n ==> t[i] == \old(t[i]);
*/
int max_element(const int* t, int n);

/*@
  requires 0 < n <= INT_MAX;
  requires \valid(a + (0 .. n - 1));
  requires \valid(b + (0 .. n - 1));
  requires \forall int i; 0 <= i < n ==> INT_MIN <= a[i] + b[i] <= INT_MAX;
  requires \separated(a + (0 .. n-1), b + (0 .. n-1));
  assigns a[0 .. n-1];
  assigns b[0 .. n-1];
  ensures \forall int i; 0 <= i < n ==> a[i] == \old(a[i]) + b[i];
  ensures \forall int i; 0 <= i < n ==> b[i] == \old(b[i]);
*/
void sum_of_tab(int *a, int *b, int n);