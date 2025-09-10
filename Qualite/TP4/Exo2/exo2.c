#include "exo2.h"


/*@ requires \valid(a) && \valid(b);
    requires INT_MIN <= *a + *b <= INT_MAX;
    ensures firstIsAdd{Post,Pre,Pre}(a,a,b);
*/
void addInPointer(int *a, int *b){
    *a = *a + *b;
    return;
}


/*@ requires \valid(a);
    requires INT_MIN <= *a + b <= INT_MAX;
    ensures add{Pre,Post}(b,a);
*/
void add(int *a, int b){
    *a += b;
}

/* @ requires \valid(t + (i .. n-1));
  @ requires \forall int j; i <= j < n ==> t[j] < INT_MAX;
  @ assigns t[i .. n-1];
  @ ensures tabNextIntFixed{Pre,Post}(t,t,i,n);
 */
void addOneTab(int *t, int i, int n){
	if (n<i) return;
	/*à compléter
	 */
	for(int j = i; j<n; j++){
		t[j]++;
	}
	return;
}