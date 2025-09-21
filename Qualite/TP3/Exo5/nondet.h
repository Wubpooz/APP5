#include "limits.h"

/*@ requires a >= 0;
    terminates \true;
    ensures 0 <= \result <= a;
    assigns \nothing;
*/
int randInt(int a);

/*@
  behavior neg:
    assumes a <= 0;
    ensures \result == 0;
    assigns \nothing;
    
  behavior pos:
    assumes a > 0;
    requires a <= INT_MAX/2;
    ensures 0 <= \result <= 2 * \old(a);
    assigns \nothing;

  complete behaviors;
  disjoint behaviors;
*/
int nondet(int a);