#include "nondet.h"

int nondet(int a) {
	int res = 0;

  if(a<=0) {
    return res;
  }
  /*@ 
    loop invariant 0 <= a <= \at(a,Pre);
    loop invariant 0 <= res <= 2 * (\at(a,Pre) - a);
    loop assigns a, res;
    loop variant a;
  */
	while (a > 0) {
		int b = randInt(a);

    if (b == 0) {
      b = 1;
    }
    res += b + 1;
		a -= b;
  }
	return res;
}