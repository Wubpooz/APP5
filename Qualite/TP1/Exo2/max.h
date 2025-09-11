/*@ 
  ensures \result >= \old(a) && \result >= \old(b) && ( \result == \old(a) || \result == \old(b)); */
int max(int a, int b);