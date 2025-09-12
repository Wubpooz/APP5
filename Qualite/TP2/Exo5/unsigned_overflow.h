#include <limits.h>

/*@ 
requires a + b <= INT_MAX;
requires a + b >= 0;
ensures \result == a + b;
*/
unsigned int add(unsigned int a, unsigned int b);

/*@ 
requires 0 <= a - b;
requires a - b <= INT_MAX;
ensures \result == a - b;
*/
unsigned int sub(unsigned int a, unsigned int b);
