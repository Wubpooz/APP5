#include "limits.h"

/*@ predicate firstIsAdd{L,M,N}(int *a, int *b, int *c) = \at(*a,L) == \at(*b,M) + \at(*c,N);
*/


/*@ predicate add{L,M}(integer i,int *j) = \at(*j,L) +i  == \at(*j,M);
*/


/* TODO: predicate unchangedTab{L,M}(int *tab, int *tab2, integer i, integer n) = ;
    «Entre les indices i et n-1, le tab à la position L, et tab2 à la position M contiennent les mêmes valeurs»
*/

/*TODO: predicate tabNextIntFixed{L,M}(int *tab, int *tab2, integer i, integer n) = ;
    «Entre les indices i et n-1, la valeur de tab2[j] à la position M est la valeur de tab[j] à la position L plus 1.»
*/