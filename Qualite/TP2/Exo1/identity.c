#include "identity.h"

int identity_while(int n){
	int result = 0;
  /*@
    loop invariant result <= n;
    loop assigns result;
    loop variant n - result;
  */
	while (result < n){
		result++;
	}
	return result;
}

int identity_for(int n){
	int result = 0;
  /*@
    loop invariant 1 <= i <= n+1 && result == i-1;
    loop assigns result, i;
    loop variant n - i;
  */
	for (int i = 1; i <=n; i++){
		result++;
	}
	return result;
}

