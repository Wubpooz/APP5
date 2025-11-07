#include <stdlib.h>
#include <stdio.h>

typedef unsigned char pixel_t;

#define IDX(i, j) (((i) * M) + (j))

int main(int argc, char* argv[])
{
  const int N = 8192, M = 16384, taille_filtre = 3;

  /* Allocation des images */
  pixel_t* image_source = (pixel_t*)malloc(N * M * sizeof(pixel_t));
  pixel_t* image_dest = (pixel_t*)malloc(N * M * sizeof(pixel_t));
  double coeffs[taille_filtre][taille_filtre];

  if (!image_source || !image_dest) {
    printf("Erreur d'allocation mémoire\n");
    return 1;
  }

  /* Initialisation du filtre */
  printf("Initialisation du filtre de détection de contours...\n");
  for (int i = 0; i < taille_filtre; i++) {
    for (int j = 0; j < taille_filtre; j++) {
      if( i == j && i == taille_filtre / 2 ) 
        coeffs[i][j] = taille_filtre * taille_filtre - 1.0;
      else
      coeffs[i][j] = -1.0;
    }
  }

  /* Initialisation aléatoire de l'image source */
  printf("Initialisation de l'image source de taille %dx%d...\n", N, M);
  srand(1337*42);

  for (int i = 0; i < N; i++) {
    for (int j = 0; j < M; j++) {
      image_source[IDX(i,j)] = rand() % 256;
    }
  }

  printf("Traitement de l'image...\n");
  /* Gestion des première et dernière lignes de l'image */
  for (int j = 0; j < M; j++) {
    image_dest[IDX(0,j)] = image_source[IDX(0,j)];
    image_dest[IDX(N-1,j)] = image_source[IDX(N-1,j)];
  }

  /* Traitement de l'image */
  for (int i = 1; i < N-1; i++) {
    /* Gestion des première et dernière colonnes de l'image */
    image_dest[IDX(i,0)] = image_source[IDX(i,0)];
    image_dest[IDX(i,M-1)] = image_source[IDX(i,M-1)];

    /* Application du filtre */
    for (int j = 1; j < M-1; j++) {
      int idx = IDX(i,j);
      image_dest[idx] = 0;
      for (int ii = -1; ii <= 1; ii++) {
        for (int jj = -1; jj <= 1; jj++) {
          image_dest[idx] += image_source[IDX(i+ii,j+jj)] * coeffs[ii+2][jj+2]; // +2 comme mentionné dans l'énoncé
        }
      }
    }
  }

  /* Recherche des valeurs minimale et maximale des pixels
   * et du nombre de pixels dont la valeur est c (tirée aléatoirement) */
  printf("Analyse de l'image traitée de taille %dx%d...\n", N, M);
  pixel_t val_min = 255, val_max = 0, c = rand() % 256;
  int compteur = 0;

  for (int i = 0; i < N; i++) {
    for (int j = 0; j < M; j++) {
      pixel_t val = image_dest[IDX(i,j)];
      if (val < val_min) val_min = val;
      if (val > val_max) val_max = val;
      if (val == c) compteur++;
    }
  }

  printf("valeur minimale = %d | valeur maximale = %d | nombre d'occurences de %d = %d\n",
         val_min, val_max, c, compteur);

  /* Écriture de l'image traitée dans un fichier */
  FILE* fichier = fopen("image_dest.bin", "wb");
  if (!fichier) {
    printf("Erreur à l'ouverture du fichier\n");
    return 1;
  }
  fwrite(&image_dest[IDX(0,0)], sizeof(pixel_t), N * M, fichier);
  fclose(fichier);

  free(image_source);
  free(image_dest);
  return 0;
}
