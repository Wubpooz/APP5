#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <omp.h>
#include <unistd.h> // for getopt
#include <getopt.h>

// Simple sieve that returns both is_prime table and primes list
static char* sieve_isprime(int limit, int** primes_out, int* prime_count_out) {
  char* is_prime = (char*)malloc((limit + 1) * sizeof(char));
  if (!is_prime) return NULL;
  memset(is_prime, 1, limit + 1);
  if (limit >= 0) is_prime[0] = 0;
  if (limit >= 1) is_prime[1] = 0;

  // strike evens
  for (int i = 4; i <= limit; i += 2) is_prime[i] = 0;

  int sqrt_limit = (int)sqrt((double)limit);
  for (int p = 3; p <= sqrt_limit; p += 2) {
    if (is_prime[p]) {
      for (int j = p * p; j <= limit; j += 2 * p) {
        is_prime[j] = 0;
      }
    }
  }

  int count = (limit >= 2) ? 1 : 0; // include 2 if present
  for (int i = 3; i <= limit; i += 2) if (is_prime[i]) count++;

  int* primes = (int*)malloc(count * sizeof(int));
  int idx = 0;
  if (limit >= 2) primes[idx++] = 2;
  for (int i = 3; i <= limit; i += 2) if (is_prime[i]) primes[idx++] = i;

  *primes_out = primes;
  *prime_count_out = count;
  return is_prime;
}

static inline int upper_bound_leq(const int* a, int n, int key) {
  int lo = 0, hi = n;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    if (a[mid] <= key) lo = mid + 1; else hi = mid;
  }
  return lo; // number of elements <= key
}

int goldbach_count(int x, const int* primes, int prime_count, const char* is_prime) {
  if (x <= 2 || (x & 1)) return 0;
  int half = x / 2;
  int limit_i = upper_bound_leq(primes, prime_count, half);
  int count = 0;
  for (int i = 0; i < limit_i; i++) {
    int p = primes[i];
    int q = x - p;
    if (is_prime[q]) count++;
  }
  return count;
}

int main(int argc, char* argv[]) {
  int LIMIT = 100000;
  char* output_file = NULL;
  int quiet = 0;
  int nice_print = 0;

  int opt;
  while ((opt = getopt(argc, argv, "n:o:q:s")) != -1) {
    switch (opt) {
      case 'n': LIMIT = atoi(optarg); break;
      case 'o': output_file = optarg; break;
      case 'q': quiet = 1; break;
      case 's': nice_print = 1; break;
      default:
        fprintf(stderr, "Usage: %s [-n limit] [-o output_file] [-q] [-s]\n", argv[0]);
        return 1;
    }
  }
  if (LIMIT < 4) { fprintf(stderr, "Limit must be at least 4\n"); return 1; }

  omp_set_num_threads(omp_get_max_threads());
  #pragma omp parallel
  { 
    #pragma omp single
    printf("OpenMP using %d threads (max %d)\n", omp_get_num_threads(), omp_get_max_threads());
  }

  double t0 = omp_get_wtime();
  int prime_count = 0;
  int* primes = NULL;
  char* is_prime = sieve_isprime(LIMIT, &primes, &prime_count);
  if (!is_prime || !primes) { perror("sieve"); return 1; }
  double t1 = omp_get_wtime();
  printf("Generated %d primes up to %d in %.3f s\n", prime_count, LIMIT, t1 - t0);

  int* counts = (int*)malloc((LIMIT / 2 + 1) * sizeof(int));
  if (!counts) { perror("malloc counts"); free(primes); free(is_prime); return 1; }

  // Only outer parallelism; inside goldbach_count is serial and uses O(1) primality checks
  #pragma omp parallel for schedule(guided)
  for (int n = 2; n <= LIMIT; n += 2) {
    counts[n / 2] = goldbach_count(n, primes, prime_count, is_prime);
  }
  double t2 = omp_get_wtime();
  printf("Computed Goldbach counts up to %d in %.3f s\n", LIMIT, t2 - t1);
  printf("Total time: %.3f s\n", t2 - t0);

  FILE* out = stdout;
  if (output_file) {
    out = fopen(output_file, "w");
    if (!out) { perror("open output"); free(primes); free(is_prime); free(counts); return 1; }
  }
  if (!quiet || output_file) {
    if(nice_print) {
      fprintf(out, "n\tGoldbach(n)\n");
      for (int n = 2; n <= LIMIT; n += 2) fprintf(out, "%d\t%d\n", n/2, counts[n / 2]);
    } else {
      for (int n = 2; n <= LIMIT; n += 2) fprintf(out, "%d,", counts[n / 2]);
    }
  }
  if (output_file) { fclose(out); printf("Results written to %s\n", output_file); }

  free(counts);
  free(primes);
  free(is_prime);
  return 0;
}