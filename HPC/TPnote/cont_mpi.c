#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"

typedef unsigned char pixel_t;

#define IDX(i, j) (((i) * M) + (j))

int main(int argc, char** argv) {
  MPI_Init(&argc, &argv);

  int rank, size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  printf("Process %d/%d started...\n", rank+1, size);

  const int N = 8192, M = 16384, taille_filtre = 3;

  pixel_t* image_source = (pixel_t*)malloc(N * M * sizeof(pixel_t));
  pixel_t* image_dest = (pixel_t*)malloc(N * M * sizeof(pixel_t));
  double coeffs[taille_filtre][taille_filtre];

  if(N % size != 0) {
    if(rank == 0) {
      printf("Le nombre de lignes de l'image doit être un multiple du nombre de processus\n");
    }
    MPI_Finalize();
    return -1;
  }

  int blocs_per_process = (N / size ) + 2;
  pixel_t* local_source = (pixel_t*)malloc(blocs_per_process * M * sizeof(pixel_t));
  pixel_t* local_dest = (pixel_t*)malloc(blocs_per_process * M * sizeof(pixel_t));
  pixel_t local_val_min = 255, local_val_max = 0;
  int compteur = 0;

  pixel_t global_min, global_max;
  pixel_t c;
  int global_count;


  if (!image_source || !image_dest) {
    printf("Erreur d'allocation mémoire\n");
    return 1;
  }

  /* Initialisation du filtre */
  for (int i = 0; i < taille_filtre; i++) {
    for (int j = 0; j < taille_filtre; j++) {
      if( i == j && i == taille_filtre / 2 ) 
        coeffs[i][j] = taille_filtre * taille_filtre - 1.0;
      else
      coeffs[i][j] = -1.0;
    }
  }

  
  if(rank == 0) {
    /* Initialisation aléatoire de l'image source */
    printf("Initialisation de l'image source de taille %dx%d...\n", N, M);
    srand(1337*42);
  
    for (int i = 0; i < N; i++) {
      for (int j = 0; j < M; j++) {
        image_source[IDX(i,j)] = rand() % 256;
      }
    }

    c = rand() % 256;
    printf("Traitement et analyse de l'image...\n");
  }
  // c est initialisé uniquement par le processus 0 pour toujours compter la même valeur
  MPI_Bcast(&c, 1, MPI_UNSIGNED_CHAR, 0, MPI_COMM_WORLD);

  // On envoie l'initalisation du processus 0  en passant la première ligne fantôme
  MPI_Scatter(image_source, (blocs_per_process - 2) * M, MPI_UNSIGNED_CHAR, &local_source[IDX(1, 0)], (blocs_per_process - 2) * M, MPI_UNSIGNED_CHAR, 0, MPI_COMM_WORLD);

  // On attend que 0 ait fini l'initialisation et l'envoi
  MPI_Barrier(MPI_COMM_WORLD);

  // Timer start
  double start_time = MPI_Wtime();


  // Gestion des bordures
  MPI_Sendrecv(&local_source[IDX(1, 0)], M,  MPI_UNSIGNED_CHAR, (rank - 1 + size) % size, 0,
               &local_source[IDX(0, 0)], M, MPI_UNSIGNED_CHAR, (rank + 1) % size, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
  MPI_Sendrecv(&local_source[IDX(blocs_per_process - 2, 0)], M,  MPI_UNSIGNED_CHAR, (rank + 1) % size, 0,
               &local_source[IDX(blocs_per_process - 1, 0)], M, MPI_UNSIGNED_CHAR, (rank - 1 + size) % size, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

  // Application du filtre
  for (int i = 1; i < blocs_per_process - 1; i++) {
    // Gestion des première et dernière colonnes de l'image
    local_dest[IDX(i, 0)] = local_source[IDX(i, 0)];
    local_dest[IDX(i, M-1)] = local_source[IDX(i, M-1)];
    for (int j = 1; j < M-1; j++) {
      int idx = IDX(i,j);
      local_dest[idx] = 0;
      for (int ii = -1; ii <= 1; ii++) {
        for (int jj = -1; jj <= 1; jj++) {
          local_dest[idx] += local_source[IDX(i+ii, j+jj)] * coeffs[ii+2][jj+2]; // +2 comme mentionné dans l'énoncé
        }
      }
    }
  }

  // Analyse locale (on passe les bordures)
  for (int i = 1; i < blocs_per_process - 1; i++) {
    for (int j = 0; j < M; j++) {
      pixel_t val = local_dest[IDX(i,j)];
      if (val < local_val_min) local_val_min = val;
      if (val > local_val_max) local_val_max = val;
      if (val == c) compteur++;
    }
  }


  // On renvoie les résultats à 0
  MPI_Reduce(&local_val_min, &global_min, 1, MPI_UNSIGNED_CHAR, MPI_MIN, 0, MPI_COMM_WORLD);
  MPI_Reduce(&local_val_max, &global_max, 1, MPI_UNSIGNED_CHAR, MPI_MAX, 0, MPI_COMM_WORLD);
  MPI_Reduce(&compteur, &global_count, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);

  if(rank == 0) {
    printf("valeur minimale = %d | valeur maximale = %d | nombre d'occurences de %d = %d\n", global_min, global_max, c, global_count);
  }

  // On commence à 1 et on finit à blocs_per_process - 1 pour éviter les bordures
  MPI_Gather(&local_dest[IDX(1, 0)], (blocs_per_process - 2) * M, MPI_UNSIGNED_CHAR, image_dest, (blocs_per_process - 2) * M, MPI_UNSIGNED_CHAR, 0, MPI_COMM_WORLD);

  // Timer end
  
  if(rank == 0) {
    double end_time = MPI_Wtime();
    printf("Temps de traitement : %f secondes\n", end_time - start_time);

    FILE* fichier = fopen("image_dest.bin", "wb");
    if (!fichier) {
      printf("Erreur à l'ouverture du fichier\n");
      return 1;
    }
    fwrite(&image_dest[IDX(0,0)], sizeof(pixel_t), N * M, fichier);
    fclose(fichier);
  }

  free(image_source);
  free(image_dest);
  free(local_source);
  free(local_dest);
  MPI_Finalize();
  return 0;
}