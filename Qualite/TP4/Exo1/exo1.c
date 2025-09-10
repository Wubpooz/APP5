#include "exo1.h"
/*@ requires x < INT_MAX;
  @ assigns \nothing;
  @ ensures \result == nextInt(x);
*/
int plusOne(int x)
{
  return x + 1;
}

/* @ requires x>=1;
  @ requires sumOfInt(x) <= INT_MAX;
  @ assigns \nothing;
  @ ensures \result == sumOfInt(x);
 */
int sumInt(int x)
{
  int res = 0;
  /* @ loop invariant 1<=i<=x+1;
    @ loop invariant res == sumOfInt(i-1);
    @ loop assigns i,res;
    @ loop variant x+1-i;
   */
  for (int i = 1; i <= x; i++)
  {
    res += i;
  }
  return res;
}

/* @ requires n>0;
  @ requires INT_MIN <= sumFirstLast(t,n) <= INT_MAX;
  @ requires \valid(t + (0 .. n-1));
  @ ensures \result == sumFirstLast(t,n);
 */
int sumFL(int *t, int n)
{
  return t[0] + t[n - 1];
}

/* @ requires n>0;
  @ requires INT_MIN <= sumFirstLast(t,n) <= INT_MAX;
  @ requires \valid(t + (0 .. n-1));
  @ ensures \result == sumFirstLast{Pre}(t,n);
 */
int sumFLBis(int *t, int n)
{
  int res = t[0] + t[n - 1];
  t[0] = 0;
  t[n - 1] = 0;
  return res;
}

/*@ requires \valid(t);
    requires INT_MIN <= *t * 2 <= INT_MAX;
    ensures \result == twoTimes{Pre}(t,*t);
    ensures \result == \old(twoTimes(t,*t));
    ensures \result == twoTimesBis{Pre}(t);
*/
int doublePointer(int *t)
{
  int a = 2 * *t;
  *t = 0;
  return a;
}