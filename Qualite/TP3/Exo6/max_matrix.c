#include "max_matrix.h"

int max_matrix(int **matrix, int n, int m)
{
	int i = 0;
	int j = 0;
	int max = matrix[0][0];
	/*@ loop assigns i,j,max;
	  @ loop invariant 0 <= i <= n;
	  @ loop invariant 0 <= j < m;
	*/
	while (i < n)
	{
		if (max < matrix[i][j])
			max = matrix[i][j];
		j++;
		if (j == m)
		{
			i++;
			j = 0;
		}
	}
	return max;
}