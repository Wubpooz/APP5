#include <limits.h>
#include "__fc_builtin.h"

/*@
  ensures \result >= 0;
*/
int abs(int val)
{
	if (val < 0)
		return -val;
	return val;
}

/*@ ensures \result == a + b;
 */
int add(int a, int b)
{
	return a + b;
}

/*@ ensures \result == a/b;
 */
int div(int a, int b)
{
	return a / b;
}

int main(void)
{
	int a = abs(42);
	int b = abs(-42);
	int c = abs(-74);
	int d = add(a, c);
	int e = add(d, d);
	//	b = add(INT_MAX,42);	//cas d’erreur 1
	//	a = abs(INT_MIN);		//cas d’erreur 2
	a = div(4, 8);
	b = div(17, -12);
	//	c = div(15,0);			//cas d’erreur 3
	a = div(-12, 54);
}