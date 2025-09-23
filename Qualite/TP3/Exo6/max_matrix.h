#include "limits.h"

/* @ lemma posTimesPosIsPos: \forall integer n,m; n>=0 ==> m>=0 ==> n*m >=0;
*/

/*@ requires 0 < n <= INT_MAX;
  @ requires 0 < m <= INT_MAX;
  @ requires \valid(matrix + (0 .. n-1));
  @ requires \forall int k; 0 <= k <= n-1 ==> \valid(matrix[k]+ (0 .. m-1));
  @ ensures \forall integer i,j; 0 <= i < n && 0 <= j < m ==> matrix[i][j] <= \result;
  @ ensures \exists integer i,j; 0 <= i < n && 0 <= j < m && matrix[i][j] == \result;
  @ assigns \nothing;
*/
int max_matrix(int **matrix, int n, int m);
