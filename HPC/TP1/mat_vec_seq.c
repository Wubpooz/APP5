#include <stdio.h>
#include <stdlib.h>


int main(int argc, char** argv) {
  int N = 8;
  float A[N][N];
  float b[N];
  float c[N];

  for(int i = 0; i < N; i++) {
    b[i] = 1.0;
    c[i] = 0.0;
    for(int j = 0; j < N; j++) {
      A[i][j] = (float)(i + j);
    }
  }

  for(int i = 0; i < N; i++) {
    for(int j = 0; j < N; j++) {
      c[i] += A[i][j] * b[j];
    }
  }

  for(int i = 0; i < N; i++) {
    printf("%f\n", c[i]);
  }

  return 0;
}