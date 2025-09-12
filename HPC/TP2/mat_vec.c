#include <stdio.h>
#include <stdlib.h>
#include "omp.h"

// export OMP_NUM_THREADS=4
//  gcc -fopenmp APP5/HPC/TP2/mat_vec.c APP5/HPC/TP2/build/mat_vec
int main(int argc, char **argv) {
  int dim = 2048;
  int NREPET = 10;

  double *A = (double *)malloc(dim * dim * sizeof(double));
  double *x = (double *)malloc(dim * sizeof(double));
  double *b = (double *)malloc(dim * sizeof(double));
  if (A == NULL || x == NULL || b == NULL) {
    printf("Error allocating memory\n");
    return -1;
  }

  for (int i = 0; i < dim; i++) {
    for (int j = 0; j < dim; j++) {
      A[i * dim + j] = i + j;
    }
    x[i] = 1;
  }

  #pragma omp parallel
  int nthreads = omp_get_num_threads();


  for (int repet = 0; repet < NREPET; repet++) {
    #pragma omp parallel default(none) num_threads(nthreads) shared(A,x,b,dim)
    {
      for(size_t i=0; i<dim; i++) {
        #pragma omp single
        {
          #pragma omp task
          {
            int s = 0;
            for(size_t j=0; j<dim; j++) {
              s += A[i*dim + j] * x[j];
            }
            b[i] = s;
          }
        }
      }
    }
  }

  #pragma omp single
  {
    for (int i = 0; i < 10; i++) {
      printf("b[%d] = %f\n", i, b[i]);
    }
  }

  free(A);
  free(x);
  free(b);
  return 0;
}