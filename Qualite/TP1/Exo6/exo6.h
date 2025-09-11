#include "limits.h"

/*@
  ensures \result <= a && \result <= b && \result <= c && (a == \result || b == \result || c == \result);
*/
/**
 * @brief Computes the min of these arguments.
 * 
 * @param a an integer
 * @param b an integer
 * @param c an integer
 * @return int The smallest value among a, b and c.
*/
int min(int a, int b, int c) {
  int m = a;
  if(b < m) {
    m = b;
  }
  if( c < m) {
    m = c;
  }
  return m;
}

/*@ 
requires a != 0 && a != INT_MIN && a != (INT_MAX-1)/3;
ensures a%2==0 ==> \result == a/2 && a%2==1 ==> \result == 3*a + 1;
*/
/**
 * @brief Computes the next step of @p a in the Syracuse sequence, i.e., its quotient by 2 if @p a is even, and 3 * @p a +1 otherwise.
 * 
 * @param a an integer.
 * @return int The next value in the Syracuse sequence.
 */
int syracuseStep(int a) {
  return a%2==0 ? a/2 : 3*a + 1;
}


/*@
  requires b != 0;
  requires b != -1 || a != INT_MIN;
  requires b != 1  || a != INT_MAX;
  requires b < 0 ==> -a >= -2147483647 && -b >= -2147483647;
  requires b > 0 ==> (
    (a >= 0 ==> -2147483648 <= a + b/2 <= 2147483647) &&
    (a < 0  ==> -2147483648 <= a - b/2 <= 2147483647)
  );
  ensures b < 0 ==> \result == ((-a >= 0) ? ((-a + -b/2)/-b) : ((-a - -b/2)/-b));
  ensures b >= 0 ==> \result == ((a >= 0) ? ((a + b/2)/b) : ((a - b/2)/b));
*/
/**
 * @brief Computes the rounding of the (real) quotient of a by b, i.e. the closest integer to the quotient. We will accept a function that does that only for positive integers (remember the C int division is not the Euclidean division). As a bonus, you might implement a function that works for any pair of integer (such that the quotient is defined of course).
 *
 * @param a the dividend
 * @param b the diviser
 * @return int The rounding of a/.b.
 * @pre a and b are positive (or not, depending of your implementation).
 * @pre b is not 0.
 */
int roundedDiv(int a, int b) {
  if(b < 0) {
    a = -a;
    b = -b;
  }
  if(a >= 0) {
    return (a + b/2)/b;
  } else {
    return (a - b/2)/b;
  }
}