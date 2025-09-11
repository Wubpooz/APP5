#include "limits.h"

/*@ requires b != 0 && (a != INT_MIN || b != -1);
ensures \result == a/b;
*/
int div(int a, int b);