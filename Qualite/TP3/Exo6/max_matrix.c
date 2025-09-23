#include "max_matrix.h"

int max_matrix(int **matrix, int n, int m) {
  int i = 0;
  int j = 0;
  int max = matrix[0][0];
  /*@ loop assigns i,j,max;
    @ loop invariant 0 <= i <= n;
    @ loop invariant 0 <= j < m;
    @ loop invariant \forall integer k, l; 0 <= k < i && 0 <= l < m ==> max >= matrix[k][l];
    @ loop invariant \forall integer l; 0 <= l <= j ==> max >= matrix[i][l];
    @ loop invariant max == matrix[0][0] || \exists integer k, l;
      ((0 <= k < i && 0 <= l < m) || (k == i && 0 <= l <= j)) && max == matrix[k][l];
    @ loop variant n * m - (i * m + j);
  */
  while (i < n) {
    if (max < matrix[i][j])
      max = matrix[i][j];
    j++;
    if (j == m) {
      i++;
      j = 0;
    }
  }
  return max;
}