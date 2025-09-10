#include "limits.h"

/*@ requires a >= 0;
    terminates \true;
    ensures 0 <= \result <= a;
    assigns \nothing;
*/
int randInt(int a);

/*@ requires a >= 0;
    ensures \result >= a;
    ensures \result <= 2 * a;
*/
int nondet(int a);