#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"

int main(int argc, char** argv) {
  MPI_Init(&argc, &argv);

  int rank, size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  int N = 8;

  if(N % size != 0) {
    if(rank == 0) {
      printf("N doit etre un multiple du nombre de processus\n");
    }
    MPI_Finalize();
    return -1;
  }

  float A[N][N];
  float b[N];
  float c[N];
  int blocs_per_process = N / size;
  float local_A[blocs_per_process][N];
  float local_c[blocs_per_process];

  if(rank == 0) {
    for(int i = 0; i < N; i++) {
      b[i] = 1.0;
      for(int j = 0; j < N; j++) {
        A[i][j] = (float)(i + j);
      }
    }

    printf("Matrices initalisées, sending...\n");
  }
  MPI_Scatter(A, N * blocs_per_process, MPI_FLOAT, local_A, N * blocs_per_process, MPI_FLOAT, 0, MPI_COMM_WORLD);
  MPI_Bcast(b, N, MPI_FLOAT, 0, MPI_COMM_WORLD);

  printf("Process %d computing...\n", rank);
  for(int i = 0; i < blocs_per_process; i++) {
    local_c[i] = 0.0;
    for(int j = 0; j < N; j++) {
      local_c[i] += local_A[i][j] * b[j];
    }
  }
  printf("Process %d done.\n", rank);

  MPI_Gather(local_c, blocs_per_process, MPI_FLOAT, c, blocs_per_process, MPI_FLOAT, 0, MPI_COMM_WORLD);

  if(rank == 0) {
    printf("Result:\n");
    for(int i = 0; i < 8; i++) {
      printf("%f\n", c[i]);
    }
  }

  MPI_Finalize();
  return 0;
}