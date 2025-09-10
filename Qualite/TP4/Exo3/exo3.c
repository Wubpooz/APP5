#include "exo3.h"

/*@ assigns \nothing;
  @ ensures \result == fibonacci(x);
 */
int fibo(int x){
	if(x<=0) return 0;
	if(x==1) return 1;
	int prev = 0;
	int res = 1;
	int i = 1;
	/*@ loop invariant 1<=i<=x;
	  @ loop invariant res == fibonacci(i);
	  @ loop invariant prev == fibonacci(i-1);
	  @ loop assigns i,res,prev;
	  @ loop variant x-i;
	 */
	while (i<x){
		int aux = res;
		res = res + prev;
		prev = aux;
		i++;
	}
	return res;
}


/*@ requires \valid(t + (i .. n-1));
  @ assigns \nothing;
  @ ensures fiboTab(t,i,n) <==> \result == 1;
  @ ensures !fiboTab(t,i,n) <==> \result == 0;
 */
int isFiboTab(int *t, int i, int n){
	if(n<=i+2) return 1;
	/*@ loop assigns j;
	  @ loop invariant fiboTab(t,i,j);
	  @ loop invariant i+2<=j<=n;
	 */
	for(int j = i+2; j<n; j++){
		if(t[j] != t[j-1] + t[j-2]) return 0;
	}
	return 1;
}

/* @ requires \valid(t + (0 .. n-1));
  @ assigns \nothing;
  @ ensures \result == sumOfTab(t,0,n);
 */
int sumOfTab(int *t, int n){
	if (n<=0) return 0;
	int res = 0;
	/* invariants de boucles (et variants).
	 */
	for(int i = 0; i<n; i++) res+=t[i];
	return res;
}


/* @ requires \valid(t+ (0 .. n-1));
  @ assigns \nothing;
  @ ensures \result == countTab(t,0,n,val);
 */
int countTab(int *t, int n, int val){
	if(n<=0) return 0;
	int res = 0;
	/* invariants et variants.
	 */
	for(int i = 0; i<n; i++){
		if(t[i] == val) res++;
	}
	return res;
}

/* @ requires \valid(t + (0 .. n-1));
  @ assigns t[0..n-1];
  @ ensures \forall integer j; 0<=j<n ==> t[j] == sumOfTab(t,0,j+1);
 */
void sumOfTabInTab(int *t, int n){
	if (n<=0) return;
	int res = 0;
	/* invariants et variant
	 */
	for(int i = 0; i<n; i++) {
		res+=t[i];
		t[i] = res;
	}
	return;
}


/* @ requires \valid(t + (0 .. n-1));
  @ assigns t[a],t[b];
  @ ensures swapInArray{Pre,Post}(t,t,i,n,a,b);
 */
void swapArray(int *t, int i, int n, int a, int b){
	if (a<i || n<=a || b<i || n<=b) return;
	int aux = t[a];
	t[a] = t[b];
	t[b] = aux;
}

/* @ requires \valid(t + (0 .. n-1));
  @ requires n>i;
  @ requires i <= a < b <n;
  @ requires i <= c < d <n;
  @ requires i <= e < f <n;
  @ assigns t[a],t[b],t[c],t[d],t[e],t[f];
  @ ensures permutation{Pre,Post}(t,t,i,n);
 */
void threeSwap(int *t, int i, int n, int a, int b, int c, int d, int e, int f){
	// @ assert permutation{Pre,Here}(t,t,i,n);
	swapArray(t,i,n,a,b);
	swapArray(t,i,n,c,d);
	swapArray(t,i,n,e,f);
}
