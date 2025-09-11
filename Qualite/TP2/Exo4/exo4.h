#include "limits.h"

/*@ 
  requires n > 0;
  requires \valid(t + (0 .. n - 1));
  assigns t[0 .. n-1];
  ensures \forall int i; 0 <= i < n ==> t[i] <= t[\result];
  ensures \forall int i; 0 <= i < n ==> t[i] == \old(t[i]);
*/
int max_element(const int* t, int n);

/*@
  requires n > 0;
  requires \valid(a + (0 .. n - 1));
  requires \valid(b + (0 .. n - 1));
  assigns a[0 .. n-1];
  assigns b[0 .. n-1];
  ensures \forall int i; 0 <= i < n ==> a[i] == \old(a[i]) + b[i];
  ensures \forall int i; 0 <= i < n ==> b[i] == \old(b[i]);
*/
void sum_of_tab(int *a, int *b, int n);