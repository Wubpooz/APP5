#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"


void sort(int* list, int size) {
  for (int i = 0; i < size - 1; i++) {
    for (int j = 0; j < size - i - 1; j++) {
      if (list[j] > list[j + 1]) {
        int temp = list[j];
        list[j] = list[j + 1];
        list[j + 1] = temp;
      }
    }
  }
}



void merge(int* local, int* recv, int size, int keep_smallest) {
  int* temp = (int*)malloc(2 * size * sizeof(int));
  int i = 0, j = 0, k = 0;

  // Fusion
  while (i < size && j < size) {
    if (local[i] < recv[j])
      temp[k++] = local[i++];
    else
      temp[k++] = recv[j++];
  }
  while (i < size) temp[k++] = local[i++];
  while (j < size) temp[k++] = recv[j++];

  // Copie les size plus petits ou plus grands
  if (keep_smallest == 1) {
    for (i = 0; i < size; i++) local[i] = temp[i];
  } else {
    for (i = 0; i < size; i++) local[i] = temp[2*size - size + i];
  }
  free(temp);
}



int main(int argc, char** argv) {
  MPI_Init(&argc, &argv);

  int rank, size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  int N = 160;
  if (N%size != 0) {
    if (rank == 0) {
      fprintf(stderr, "N must be divisible by the number of processes.\n");
    }
    MPI_Finalize();
    return EXIT_FAILURE;
  }
  int list[N];
  int nb_elements_per_process = N / size;
  int* local_list = (int*)malloc(nb_elements_per_process * sizeof(int));
  int* received_list = (int*)malloc(nb_elements_per_process * sizeof(int));

  if(rank == 0) {
    int original_list[N];
    printf("Unsorted list of len %d: \n", N);
    srand(789);
    for (int i = 0; i < N; i++) {
      list[i] = rand() % 1000; // Random integers between 0 and 999
      printf("%d ", list[i]);
    }
    printf("\n");

    for(int i = 0; i < N; i++) {
      original_list[i] = list[i];
    }
  }

  MPI_Scatter(list, nb_elements_per_process, MPI_INT, local_list, nb_elements_per_process, MPI_INT, 0, MPI_COMM_WORLD);

  printf("Process %d: local list before sort.\n", rank);
  sort(local_list, nb_elements_per_process);


  for(int step = 0; step < size; step++) {
    if(rank == 0) {
      printf("Step %d/%d\n", step + 1, size);
    }
    MPI_Barrier(MPI_COMM_WORLD);
    if(step%2 == 0) {
      if(rank%2 == 0 && rank < size - 1) {
        MPI_Send(local_list, nb_elements_per_process, MPI_INT, rank + 1, 0, MPI_COMM_WORLD);
        MPI_Recv(received_list, nb_elements_per_process, MPI_INT, rank + 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        merge(local_list, received_list, nb_elements_per_process, 1);
      } else if(rank%2 == 1) {
        MPI_Send(local_list, nb_elements_per_process, MPI_INT, rank - 1, 0, MPI_COMM_WORLD);
        MPI_Recv(received_list, nb_elements_per_process, MPI_INT, rank - 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        merge(local_list, received_list, nb_elements_per_process, 0);
      }
    } else {
      if(rank%2 == 0 && rank > 0) {
        MPI_Send(local_list, nb_elements_per_process, MPI_INT, rank - 1, 0, MPI_COMM_WORLD);
        MPI_Recv(received_list, nb_elements_per_process, MPI_INT, rank - 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        merge(local_list, received_list, nb_elements_per_process, 0);
      } else if(rank%2 == 1 && rank < size - 1) {
        MPI_Send(local_list, nb_elements_per_process, MPI_INT, rank + 1, 0, MPI_COMM_WORLD);
        MPI_Recv(received_list, nb_elements_per_process, MPI_INT, rank + 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        merge(local_list, received_list, nb_elements_per_process, 1);
      }
    }
  }

  MPI_Gather(local_list, nb_elements_per_process, MPI_INT, list, nb_elements_per_process, MPI_INT, 0, MPI_COMM_WORLD);

  if(rank == 0) {
    printf("Sorted list of len %d: \n", N);
    for(int i = 0; i < N; i++) {
      printf("%d ", list[i]);
    }
    printf("\n");


    // Verification
    for(int i = 0; i < N - 1; i++) {
      if(list[i] > list[i + 1]) {
        fprintf(stderr, "List is not sorted!\n");
        fprintf(stderr, "Error at index %d: %d > %d\n", i, list[i], list[i + 1]);
        free(local_list);
        free(received_list);
        MPI_Finalize();
        return EXIT_FAILURE;
      }
    }

    // Check if all original elements are present and no duplicates/losses
    int* count = (int*)calloc(1000, sizeof(int)); // Assuming numbers
    for(int i = 0; i < N; i++) {
      count[list[i]]++;
    }
    for(int i = 0; i < N; i++) {
      count[list[i]]--;
    }
    for(int i = 0; i < 1000; i++) {
      if(count[i] != 0) {
        fprintf(stderr, "Element count mismatch detected!\n");
        fprintf(stderr, "Element %d has count %d\n", i, count[i]);
        free(count);
        free(local_list);
        free(received_list);
        MPI_Finalize();
        return EXIT_FAILURE;
      }
    }
    free(count);
    printf("List is sorted and all elements are present.\n");
  }

  MPI_Finalize();
  return 0;
}