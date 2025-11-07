#include <stdlib.h>
#include <stdio.h>
#include <omp.h>

typedef unsigned char pixel_t;

#define IDX(i, j) (((i) * M) + (j))

int main(int argc, char* argv[])
{
  omp_set_num_threads(16);

  const int N = 8192, M = 16384, taille_filtre = 3;

  #pragma omp parallel
  {
    #pragma omp single
    {
      int nthreads = omp_get_num_threads();
      printf("Nombre de threads disponibles : %d\n", nthreads);
    }
  }

  /* Allocation des images */
  pixel_t* image_source = (pixel_t*)malloc(N * M * sizeof(pixel_t));
  pixel_t* image_dest = (pixel_t*)malloc(N * M * sizeof(pixel_t));
  double coeffs[taille_filtre][taille_filtre];
  pixel_t c;

  if (!image_source || !image_dest) {
    printf("Erreur d'allocation mémoire\n");
    return 1;
  }

  // On optimize l'initialisation en collaspant les 2 for
  /* Initialisation du filtre */
  #pragma omp parallel for collapse(2) default(none) shared(coeffs, taille_filtre)
  for (int i = 0; i < taille_filtre; i++) {
    for (int j = 0; j < taille_filtre; j++) {
      if( i == j && i == taille_filtre / 2 ) 
        coeffs[i][j] = taille_filtre * taille_filtre - 1.0;
      else
      coeffs[i][j] = -1.0;
    }
  }

  /* Initialisation aléatoire de l'image source */
  // On utilise un seul thread pour l'initialisation, le premier arrivé, les autres attendent
  #pragma omp parallel
  {
    #pragma omp single
    {
      printf("Initialisation de l'image source de taille %dx%d...\n", N, M);
      srand(1337*42);
      c = rand() % 256;
      for (int i = 0; i < N; i++) {
        for (int j = 0; j < M; j++) {
          image_source[IDX(i,j)] = rand() % 256;
        }
      }
  
    } // barrière implicite => l'image source est partagée
  }
  
  printf("Traitement de l'image...\n");

  // timer start
  double start_time = omp_get_wtime();

  /* Gestion des première et dernière lignes de l'image */
  // Les itérations sont indépendantes, on peut paralléliser
  #pragma omp parallel for default(none) shared(image_source, image_dest, N, M)
  for (int j = 0; j < M; j++) {
    image_dest[IDX(0,j)] = image_source[IDX(0,j)];
    image_dest[IDX(N-1,j)] = image_source[IDX(N-1,j)];
  }  
  /* Gestion des première et dernière colonnes de l'image */
  // Les itérations sont indépendantes, on peut paralléliser
  #pragma omp parallel for default(none) shared(image_source, image_dest, N, M)
  for (int i = 0; i < N; i++) {
    image_dest[IDX(i,0)] = image_source[IDX(i,0)];
    image_dest[IDX(i,M-1)] = image_source[IDX(i,M-1)];
  }

  /* Traitement de l'image */
  // On a sorti la gestion des première et dernières colonnes pour éviter les calculs dans les boucles intermédiaires et utiliser collapse
  // On a aussi déroulé la boucle interne de double sommation pour permettre à openMP de mieux optimiser la distribution
  #pragma omp parallel for default(none) shared(image_source, image_dest, coeffs, N, M) collapse(2)
  for (int i = 1; i < N-1; i++) {
    for (int j = 1; j < M-1; j++) {
      int idx = IDX(i,j);
      image_dest[idx] = 0;

      image_dest[idx] += image_source[IDX(i-1,j-1)] * coeffs[1][1]; // +2 comme mentionné dans l'énoncé
      image_dest[idx] += image_source[IDX(i-1,j)] * coeffs[1][2];
      image_dest[idx] += image_source[IDX(i-1,j+1)] * coeffs[1][3];

      image_dest[idx] += image_source[IDX(i,j-1)] * coeffs[2][1];
      image_dest[idx] += image_source[IDX(i,j)] * coeffs[2][2];
      image_dest[idx] += image_source[IDX(i,j+1)] * coeffs[2][3];

      image_dest[idx] += image_source[IDX(i+1,j-1)] * coeffs[3][1];
      image_dest[idx] += image_source[IDX(i+1,j)] * coeffs[3][2];
      image_dest[idx] += image_source[IDX(i+1,j+1)] * coeffs[3][3];
    }
  }

  /* Recherche des valeurs minimale et maximale des pixels
   * et du nombre de pixels dont la valeur est c (tirée aléatoirement) */
  printf("Analyse de l'image traitée de taille %dx%d...\n", N, M);
  pixel_t val_min = 255, val_max = 0;
  int compteur = 0;

  // On parallelise la boucle avec des reductions pour val_min, val_max et compteur, cela permet de faire le calcul en parallèle sans conflits
  #pragma omp parallel for reduction(min:val_min) reduction(max:val_max) reduction(+:compteur) default(none) shared(image_dest, N, M, c)
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < M; j++) {
      pixel_t val = image_dest[IDX(i,j)];
      if (val < val_min) val_min = val;
      if (val > val_max) val_max = val;
      if (val == c) compteur++;
    }
  }

  
  // Séquentiellement, un seul thread affiche le résultat et enregistre l'image
  printf("valeur minimale = %d | valeur maximale = %d | nombre d'occurences de %d = %d\n", val_min, val_max, c, compteur);
  double end_time = omp_get_wtime();
  printf("Temps d'exécution : %f secondes\n", end_time - start_time);
  
  /* Écriture de l'image traitée dans un fichier */
  FILE* fichier = fopen("image_dest.bin", "wb");
  if (!fichier) {
    printf("Erreur à l'ouverture du fichier\n");
    free(image_source);
    free(image_dest);
    return 1;
  }
  fwrite(&image_dest[IDX(0,0)], sizeof(pixel_t), N * M, fichier);
  fclose(fichier);

  
  
  free(image_source);
  free(image_dest);
  return 0;
}
