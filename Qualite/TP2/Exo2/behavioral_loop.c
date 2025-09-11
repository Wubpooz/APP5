#include "behavioral_loop.h"

int behavioral_loop(int n, int c){
	int result = 0;
  /*@ loop invariant 1 <= i <= n+1;
      loop invariant (c >= 0 ==> result == 2*(i-1)) && (c < 0 ==> result == (i-1));
      loop assigns result, i;
      loop variant n - i + 1;
  */
	for(int i = 1; i <= n; i++){
		if(c >= 0) result++;
		result++;
	}
	return result;
}