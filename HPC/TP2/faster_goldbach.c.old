#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include <stdbool.h>
#include <stdint.h>

// Configuration constants
#define BLOCK_SIZE (128 * 1024) // 128KB blocks for optimal cache usage
#define WHEEL_SIZE 30           // 2*3*5 wheel factorization
#define MAX_SMALL_PRIME 1000000 // Threshold for small primes

// Wheel factorization pattern for 2*3*5
static const int wheel_offsets[] = {4, 6, 10, 12, 16, 18, 22, 24};
static const int wheel_pattern[] = {1, 7, 11, 13, 17, 19, 23, 29};

typedef struct {
  char *is_prime;
  int *primes;
  int prime_count;
  int limit;
} PrimeSieve;

// Global variables for m1, m2 coefficients
static int m1 = 1, m2 = 1;       // Default to standard Goldbach (1,1)
static int64_t alpha = 50000000; // 5 * 10^7 as in paper

// Function prototypes
PrimeSieve *sieve_of_eratosthenes(int limit);
void free_sieve(PrimeSieve *sieve);
bool is_prime_wheel(int n);
int gcd(int a, int b);
int lcm(int a, int b);
bool satisfies_ggc_conditions(int64_t n, int m1, int m2);
int64_t find_goldbach_partition_1a(int64_t n, PrimeSieve *sieve, int *p_min, int *q_max);
void generate_goldbach_numbers(int count, const char *output_file);

// Optimized sieve with wheel factorization and cache blocking
PrimeSieve *sieve_of_eratosthenes(int limit) {
  if (limit < 2)
    return NULL;

  PrimeSieve *sieve = malloc(sizeof(PrimeSieve));
  sieve->limit = limit;
  sieve->is_prime = calloc((limit / 2) + 1, sizeof(char));
  sieve->primes = malloc(limit * sizeof(int));
  sieve->prime_count = 0;

// Initialize odd numbers as potentially prime
#pragma omp parallel for schedule(static)
  for (int i = 1; i <= limit / 2; i++) {
    sieve->is_prime[i] = 1;
  }

  // Handle 2 separately
  if (limit >= 2) {
    sieve->primes[sieve->prime_count++] = 2;
  }

  int sqrt_limit = (int)sqrt(limit);

  // Use wheel factorization to skip multiples of 2, 3, 5
  for (int p = 3; p <= sqrt_limit; p += 2) {
    if (sieve->is_prime[p / 2]) {
// Mark multiples of p
#pragma omp parallel for schedule(dynamic)
      for (int64_t multiple = (int64_t)p * p; multiple <= limit; multiple += 2 * p) {
        if (multiple % 2 == 1) {
          sieve->is_prime[multiple / 2] = 0;
        }
      }
    }
  }

  // Collect all primes
  for (int i = 1; i <= limit / 2; i++) {
    if (sieve->is_prime[i]) {
      sieve->primes[sieve->prime_count++] = 2 * i + 1;
    }
  }

  return sieve;
}

void free_sieve(PrimeSieve *sieve) {
  if (sieve) {
    free(sieve->is_prime);
    free(sieve->primes);
    free(sieve);
  }
}

// Fast primality test for wheel factorization
bool is_prime_wheel(int n) {
  if (n < 2)
    return false;
  if (n == 2 || n == 3 || n == 5)
    return true;
  if (n % 2 == 0 || n % 3 == 0 || n % 5 == 0)
    return false;

  // Check if n follows wheel pattern
  int mod30 = n % 30;
  for (int i = 0; i < 8; i++) {
    if (mod30 == wheel_pattern[i]) {
      // Additional primality check for larger numbers
      int sqrt_n = (int)sqrt(n);
      for (int i = 7; i <= sqrt_n; i += 30) {
        for (int j = 0; j < 8; j++) {
          int factor = i + wheel_offsets[j] - 4;
          if (factor > sqrt_n)
            break;
          if (factor > 1 && n % factor == 0)
            return false;
        }
      }
      return true;
    }
  }
  return false;
}

int gcd(int a, int b) {
  while (b != 0) {
    int temp = b;
    b = a % b;
    a = temp;
  }
  return a;
}

int lcm(int a, int b) {
  return (a * b) / gcd(a, b);
}

// Check if n satisfies GGC conditions for given m1, m2
bool satisfies_ggc_conditions(int64_t n, int m1, int m2) {
  int d = gcd(m1, m2);

  // Condition 1: gcd(n, m1) = gcd(n, m2) = gcd(m1, m2)
  if (gcd(n, m1) != d || gcd(n, m2) != d)
    return false;

  // Condition 2: n ≡ m1 + m2 (mod 2^(s+1))
  // Find largest power of 2 dividing gcd(m1, m2)
  int s = 0;
  int temp_d = d;
  while (temp_d % 2 == 0) {
    temp_d /= 2;
    s++;
  }

  int mod_val = 1 << (s + 1); // 2^(s+1)
  return (n % mod_val) == ((m1 + m2) % mod_val);
}

// Algorithm 1/a: Find p-minimal (m1,m2)-partition using descending search
int64_t find_goldbach_partition_1a(int64_t n, PrimeSieve *sieve, int *p_min, int *q_max) {
  *p_min = -1;
  *q_max = -1;

  if (!satisfies_ggc_conditions(n, m1, m2)) {
    return 0; // n doesn't satisfy GGC conditions
  }

  // Descending search for q (to maximize q, minimize p)
  int max_q = (n - m1 * 2) / m2; // Maximum possible q

  for (int i = sieve->prime_count - 1; i >= 0; i--) {
    int q = sieve->primes[i];
    if (q > max_q)
      continue;

    // Check if (n - m2*q) is divisible by m1
    int64_t remainder = n - (int64_t)m2 * q;
    if (remainder <= 0 || remainder % m1 != 0)
      continue;

    int64_t p_candidate = remainder / m1;
    if (p_candidate < 2)
      continue;

    // Check if m1*p <= alpha constraint
    if ((int64_t)m1 * p_candidate > alpha)
      continue;

    // Check if p_candidate is prime
    bool p_is_prime = false;
    if (p_candidate <= sieve->limit) {
      if (p_candidate == 2) {
        p_is_prime = true;
      }
      else if (p_candidate % 2 == 1 && p_candidate <= sieve->limit) {
        p_is_prime = sieve->is_prime[p_candidate / 2];
      }
    }
    else {
      p_is_prime = is_prime_wheel(p_candidate);
    }

    if (p_is_prime) {
      *p_min = p_candidate;
      *q_max = q;
      return n;
    }
  }

  return 0; // No partition found
}

void generate_goldbach_numbers(int count, const char *output_file) {
  printf("Generating first %d Goldbach numbers for m1=%d, m2=%d\n", count, m1, m2);
  printf("Using alpha = %ld\n", alpha);

  // Estimate sieve size based on count (heuristic)
  int sieve_limit = (count < 1000) ? 100000 : (count * 50);
  printf("Creating sieve up to %d\n", sieve_limit);

  PrimeSieve *sieve = sieve_of_eratosthenes(sieve_limit);
  if (!sieve) {
    fprintf(stderr, "Failed to create prime sieve\n");
    return;
  }
  printf("Sieve created with %d primes\n", sieve->prime_count);

  FILE *output = NULL;
  if (output_file) {
    output = fopen(output_file, "w");
    if (!output) {
      fprintf(stderr, "Cannot open output file: %s\n", output_file);
      free_sieve(sieve);
      return;
    }
    fprintf(output, "# First %d Goldbach numbers (m1=%d, m2=%d)\n", count, m1, m2);
    fprintf(output, "# Format: n, p_min, q_max\n");
  }

  int found = 0;
  int64_t n = m1 + m2; // Start from smallest possible value

  printf("Searching for Goldbach partitions...\n");

  double start_time = omp_get_wtime();

  while (found < count && n < 1000000) { // Safety limit
    int p_min, q_max;

    if (find_goldbach_partition_1a(n, sieve, &p_min, &q_max)) {
      found++;

      if ((found <= 20 || found % 100 == 0) && output == NULL) {
        printf("Found #%d: %ld = %d*%d + %d*%d\n", found, n, m1, p_min, m2, q_max);
      }

      if (output) {
        fprintf(output, "%ld, %d, %d\n", n, p_min, q_max);
      }
    }

    // Increment n to next candidate
    do {
      n += 2; // Skip even numbers for odd sums
    } while (!satisfies_ggc_conditions(n, m1, m2) && n < 1000000);
  }

  double end_time = omp_get_wtime();

  printf("\nCompleted in %.3f seconds\n", end_time - start_time);
  printf("Found %d Goldbach numbers\n", found);

  if (output) {
    fclose(output);
    printf("Results written to %s\n", output_file);
  }

  free_sieve(sieve);
}

int main(int argc, char *argv[]) {
  int count = 100; // Default count
  const char *output_file = NULL;

  // Parse command line arguments
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-n") == 0 && i + 1 < argc) {
      count = atoi(argv[i + 1]);
      i++;
    }
    else if (strcmp(argv[i], "-m1") == 0 && i + 1 < argc) {
      m1 = atoi(argv[i + 1]);
      i++;
    }
    else if (strcmp(argv[i], "-m2") == 0 && i + 1 < argc) {
      m2 = atoi(argv[i + 1]);
      i++;
    }
    else if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
      printf("Output file set to %s\n", argv[i + 1]);
      output_file = argv[i + 1];
      i++;
    }
    else if (strcmp(argv[i], "-alpha") == 0 && i + 1 < argc) {
      alpha = atoll(argv[i + 1]);
      i++;
    }
    else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
      printf("Usage: %s [options]\n", argv[0]);
      printf("Options:\n");
      printf("  -n COUNT     Number of Goldbach numbers to find (default: 100)\n");
      printf("  -m1 M1       First coefficient (default: 1)\n");
      printf("  -m2 M2       Second coefficient (default: 1)\n");
      printf("  -o FILE      Output file (optional)\n");
      printf("  -alpha VAL   Alpha constraint (default: 50000000)\n");
      printf("  -h, --help   Show this help\n");
      return 0;
    }
  }

  // Validate inputs
  if (count <= 0 || m1 <= 0 || m2 <= 0) {
    fprintf(stderr, "Error: count, m1, and m2 must be positive\n");
    return 1;
  }

  if (gcd(m1, m2) != 1) {
    fprintf(stderr, "Warning: m1 and m2 are not coprime. Results may not match GGC exactly.\n");
  }

  printf("OpenMP using %d threads\n", omp_get_max_threads());

  generate_goldbach_numbers(count, output_file);

  return 0;
}

// based on: https://arxiv.org/pdf/2304.00024

// gcc -O3 -march=native -fopenmp goldbach.c -o goldbach -lm

// # Standard Goldbach conjecture (first 100)
// ./goldbach -n 100

// # Custom coefficients (like Lemoine's conjecture)
// ./goldbach -n 50 -m1 1 -m2 2

// # Save results to file
// ./goldbach -n 1000 -o goldbach_results.txt

// # Show help
// ./goldbach -h