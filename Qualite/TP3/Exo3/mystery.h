#include "limits.h"

/*@ ensures INT_MIN <= \result <= INT_MAX;
  @ assigns \nothing;
*/
int askPlayerNumber();

/*@ ensures \result == hidden;
*/
int mystery(int hidden);