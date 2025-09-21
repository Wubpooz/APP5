#include "terminating.h"

int f() {
	int i = 30;
	int j = 0;
  /*@ 
  loop invariant 0 <= i <= 30;
  loop invariant j == 30 - i;
  loop assigns i,j; 
  loop variant i;
  */
 while(i>0){
   j++;
   i--;
	}
	return j;
}