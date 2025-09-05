#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"


// sudo apt-get install mpich libopenmpi-dev openmpi-bin
// mpicc pingpong.c -o ping_pong #or mpic++
// mpirun -np 4 ping_pong
int main(int argc, char** argv) {
  MPI_Init(&argc, &argv);

  int rank, size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  int msg;
  if(0 == rank%2 && rank+1 < size) {
    MPI_Send(&rank, 1, MPI_INT, rank+1, 0, MPI_COMM_WORLD);
    MPI_Recv(&msg, 1, MPI_INT, rank+1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    printf("Message reçu par le rang %d: %d\n", rank, msg);
  } 
  else if(1 == rank%2) {
    MPI_Recv(&msg, 1, MPI_INT, rank-1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    msg = 10*rank;
    MPI_Send(&msg, 1, MPI_INT, rank-1, 0, MPI_COMM_WORLD);
  }


  MPI_Finalize();
  return 0;
}