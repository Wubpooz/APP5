#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <omp.h>
#include <unistd.h> // for getopt
#include <bits/getopt_core.h>

// # Default: up to 100000, print to console
// ./goldbach

// # Custom limit, quiet mode
// ./goldbach -n 200000 -q

// # Output to file
// ./goldbach -n 50000 -o results.txt

// # Help (if invalid args)
// ./goldbach -h


// Optimized prime sieve with wheel factorization (skips multiples of 2,3,5)
int* generate_primes(int limit, int* prime_count) {
  if (limit < 2) {
    *prime_count = 0;
    return NULL;
  }

  int memory_size = (limit - 1) / 2;
  char* is_prime = (char*)malloc((memory_size + 1) * sizeof(char));
  memset(is_prime, 1, memory_size + 1);

  int sqrt_limit = (int)sqrt(limit);
  #pragma omp parallel for schedule(dynamic)
  for (int i = 3; i <= sqrt_limit; i += 2) {
    if (is_prime[i / 2]) {
      for (int j = i * i; j <= limit; j += 2 * i) {
        if (j % 2 == 1) {
          is_prime[j / 2] = 0;
        }
      }
    }
  }

  // Count primes
  int count = 1; // for 2
  #pragma omp parallel for reduction(+:count)
  for (int i = 1; i <= memory_size; i++) {
    if (is_prime[i]) count++;
  }

  int* primes = (int*)malloc(count * sizeof(int));
  primes[0] = 2;
  int idx = 1;
  for (int i = 1; i <= memory_size; i++) {
    if (is_prime[i]) {
      primes[idx++] = 2 * i + 1;
    }
  }

  free(is_prime);
  *prime_count = count;
  return primes;
}

int is_prime_trial(int n, int* primes, int prime_count) {
  if (n < 2) return 0;
  if (n == 2) return 1;
  if (n % 2 == 0) return 0;
  int sqrt_n = (int)sqrt(n);
  for (int i = 0; i < prime_count; i++) {
    int p = primes[i];
    if(p > sqrt_n) break;
    if (n % p == 0) return 0;
  }
  return 1;
}

int goldbach_count(int x, int* primes, int prime_count) {
  if (x <= 2 || x % 2 != 0) return 0;
  int count = 0;

  // upper_bound(primes, primes+prime_count, half_x)
  int half_x = x/2;
  int lo = 0, hi = prime_count;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (primes[mid] <= half_x) lo = mid + 1;
    else hi = mid;
  }
  int limit_i = lo;

  #pragma omp parallel for reduction(+:count) schedule(dynamic)
  for (int i = 0; i < limit_i; i++) {
    int p = primes[i];
    int q = x - p;
    if (is_prime_trial(q, primes, prime_count)) {
      count++;
    }
  }
  return count;
}

int main(int argc, char* argv[]) {
  int LIMIT = 100000;
  char* output_file = NULL;
  int quiet = 0;

  int opt;
  while ((opt = getopt(argc, argv, "n:o:q")) != -1) {
    switch (opt) {
      case 'n':
        LIMIT = atoi(optarg);
        break;
      case 'o':
        output_file = optarg;
        break;
      case 'q':
        quiet = 1;
        break;
      default:
        fprintf(stderr, "Usage: %s [-n limit] [-o output_file] [-q]\n", argv[0]);
        return 1;
    }
  }

  if (LIMIT < 4) {
    fprintf(stderr, "Limit must be at least 4\n");
    return 1;
  }

  omp_set_num_threads(omp_get_max_threads());
  // omp_set_max_active_levels(2);
  // omp_set_nested(1);
  #pragma omp parallel
  {
    #pragma omp single
    printf("OpenMP using %d threads (max %d)\n", omp_get_num_threads(), omp_get_max_threads());
  }

  double start_time = omp_get_wtime();

  int prime_count = 0;
  int* primes = generate_primes(LIMIT, &prime_count);

  double prime_time = omp_get_wtime();
  printf("Generated %d primes up to %d in %.3f seconds.\n", prime_count, LIMIT, prime_time - start_time);


  int* goldbach_counts = (int*)malloc((LIMIT / 2 + 1) * sizeof(int));

  #pragma omp parallel for schedule(dynamic)
  for (int i = 2; i <= LIMIT; i += 2) {
    goldbach_counts[i / 2] = goldbach_count(i, primes, prime_count);
  }

  double end_time = omp_get_wtime();
  printf("Computed Goldbach counts for even numbers up to %d in %.3f seconds.\n", LIMIT, end_time - prime_time);
  printf("Total time: %.3f seconds\n", end_time - start_time);

  FILE* out = stdout;
  if (output_file) {
    out = fopen(output_file, "w");
    if (!out) {
      perror("Failed to open output file");
      free(primes);
      free(goldbach_counts);
      return 1;
    }
  }

  if (!quiet || output_file) {
    fprintf(out, "n\tGoldbach(n)\n");
    for (int i = 2; i <= LIMIT; i += 2) {
      fprintf(out, "%d\t%d\n", i, goldbach_counts[i / 2]);
    }
  }

  if (output_file) {
    fclose(out);
    printf("Results written to %s\n", output_file);
  }

  free(primes);
  free(goldbach_counts);
  return 0;
}