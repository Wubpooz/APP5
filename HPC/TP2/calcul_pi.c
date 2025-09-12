#include <stdio.h>
#include <stdlib.h>
#include "omp.h"

static inline double f(double x) {
  return 4.0 / (1.0 + x * x);
}

int main(int argc, char **argv) {
  int NUM_THREADS = 16;
  int N = 1000000;
  float step = 1.0 / (double)(N);
  float sum = 0.0;

  #pragma omp parallel for num_threads(NUM_THREADS) default(none) shared(N, step) reduction(+:sum)
  for(int i = 0; i < N; i++) {
    double x = (i + 0.5) * step;
    sum += f(x);
  }

  sum *= step;
  printf("Approximation of Pi: %.16f\n", sum);
  return 0;
}