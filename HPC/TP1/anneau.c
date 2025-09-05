#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"


int main(int argc, char** argv) {
  MPI_Init(&argc, &argv);

  int rank, size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  int jeton;
  int beginning_rank = 3;
  int prec = rank > 0 ? rank-1 : size-1; 
  int next = rank < size-1 ? rank+1 : 0;

  if(rank == beginning_rank) {
    jeton = 8;
    MPI_Send(&jeton, 1, MPI_INT, next, 0, MPI_COMM_WORLD);
    MPI_Recv(&jeton, 1, MPI_INT, prec, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    printf("Turn Completed.\n");
  } else {
    MPI_Recv(&jeton, 1, MPI_INT, prec, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    printf("Process %d received the token %d\n", rank, jeton);
    MPI_Send(&jeton, 1, MPI_INT, next, 0, MPI_COMM_WORLD);
  }

  MPI_Finalize();
  return 0;
}