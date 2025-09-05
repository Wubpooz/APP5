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

  int N = 1000000;
  if (N%size != 0) {
    if (rank == 0) {
      fprintf(stderr, "N must be divisible by the number of processes.\n");
    }
    MPI_Finalize();
    return EXIT_FAILURE;
  }
  int list[N];
  int sorted_list[N];
  int nb_elements_per_process = N / size;

  if(rank == 0) {
    // Initialize the array with random integers
    for (int i = 0; i < N; i++) {
      list[i] = rand() % 1000; // Random integers between 0 and 999
    }
  }

  MPI_Bcast(list, N, MPI_INT, 0, MPI_COMM_WORLD);


  //TODO

  MPI_Finalize();
  return 0;
}