#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"

static inline double f(double x) {
  return 4.0 / (1.0 + x * x);
}

int main(int argc, char** argv) {
  MPI_Init(&argc, &argv);

  int rank, size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  int total_blocs = 1000000;
  int blocs_per_process = total_blocs / size;
  double step = 1.0 / (double) total_blocs;
  double sum = 0.0;
  double partial_sum = 0.0;

  int remainder = total_blocs % size;
  int start = rank * blocs_per_process + (rank < remainder ? rank : remainder);
  int end = start + blocs_per_process;

  for(int i = start; i < end; i++) {
    double x = (i + 0.5) * step;
    partial_sum += f(x);
  }

  MPI_Reduce(&partial_sum, &sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

  if(rank == 0) {
    printf("Approximation of Pi: %.16f\n", sum * step);
  }

  MPI_Finalize();
  return 0;
}