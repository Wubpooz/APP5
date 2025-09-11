/*@ 
  ensures \result >= \old(a) && \result >= \old(b) && \result >= \old(c) && \result >= \old(d) && \result >= \old(e);
  ensures  \result == \old(a) || \result == \old(b) || \result == \old(c) || \result == \old(d) || \result == \old(e); */
int max(int a, int b, int c, int d, int e);