#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "omp.h"

int *primenums(int n, int* prime_count) {
  char* sieve = (char*)malloc(n * sizeof(char));
  memset(sieve, 1, n);
  if (n > 0) sieve[0] = 0;
  if (n > 1) sieve[1] = 0;
  
  for(int i = 2; i * i < n; i++) {
    if(sieve[i]) {
      for(int j = i * i; j < n; j += i) {
        sieve[j] = 0;
      }
    }
  }

  int count = 0;
  #pragma omp parallel for reduction(+:count)
  for(int i = 2; i < n; i++) {
    if(sieve[i]) count++;
  }
  
  int* primes = (int*)malloc(count * sizeof(int));
  int idx = 0;
  for(int i = 2; i < n; i++) {
    if(sieve[i]) {
      primes[idx++] = i;
    }
  }
  
  free(sieve);
  *prime_count = count;
  return primes;
}


// int *fast_sieve(int lastNumber) {
//   omp_set_num_threads(omp_get_num_procs());
  
//   const int lastNumberSqrt = (int)sqrt((double)lastNumber);
//   int memorySize = (lastNumber-1)/2;
  
//   // Initialize - parallel
//   char* isPrime = (char*)malloc((memorySize+1) * sizeof(char));
//   #pragma omp parallel for
//   for(int i = 0; i <= memorySize; i++)
//     isPrime[i] = 1;
  
//   // Sieve - dynamic scheduling for load balancing
//   #pragma omp parallel for schedule(dynamic)
//   for(int i = 3; i <= lastNumberSqrt; i += 2) {
//     if(isPrime[i/2]) {
//       for (int j = i*i; j <= lastNumber; j += 2*i)
//         isPrime[j/2] = 0;
//     }
//   }
  
//   // Count primes - reduction
//   int found = lastNumber >= 2 ? 1 : 0;
//   #pragma omp parallel for reduction(+:found)
//   for(int i = 1; i <= memorySize; i++)
//     found += isPrime[i];
  
//   free(isPrime);
//   return found;
// }



// // Wheel pattern for multiples of 2, 3, 5
// static const int WHEEL_SIZE = 8;
// static const int wheel_offsets = {1, 7, 11, 13, 17, 19, 23, 29};
// static const int wheel_gaps = {6, 4, 2, 4, 2, 4, 6, 2};

// int wheelSieve(int limit) {
//     int wheel_limit = (limit / 30) + 1;
//     int sieve_size = wheel_limit * WHEEL_SIZE;
    
//     char* sieve = (char*)calloc(sieve_size, sizeof(char));
    
//     // Mark primes using wheel
//     #pragma omp parallel for
//     for (int w = 0; w < wheel_limit; w++) {
//         for (int i = 0; i < WHEEL_SIZE; i++) {
//             int num = w * 30 + wheel_offsets[i];
//             if (num <= limit && num > 1) {
//                 sieve[w * WHEEL_SIZE + i] = 1;  // Potentially prime
//             }
//         }
//     }
    
//     // Sieve with wheel-generated candidates
//     for (int w = 0; w < wheel_limit; w++) {
//         for (int i = 0; i < WHEEL_SIZE; i++) {
//             int prime = w * 30 + wheel_offsets[i];
//             if (prime > limit || prime <= 1) continue;
//             if (!sieve[w * WHEEL_SIZE + i]) continue;
            
//             // Mark multiples using wheel pattern
//             for (int multiple = prime * prime; multiple <= limit; multiple += prime) {
//                 if (multiple % 2 != 0 && multiple % 3 != 0 && multiple % 5 != 0) {
//                     int mult_w = multiple / 30;
//                     int mult_offset = multiple % 30;
                    
//                     // Find position in wheel
//                     for (int j = 0; j < WHEEL_SIZE; j++) {
//                         if (wheel_offsets[j] == mult_offset) {
//                             sieve[mult_w * WHEEL_SIZE + j] = 0;
//                             break;
//                         }
//                     }
//                 }
//             }
//         }
//     }
    
//     // Count primes
//     int count = 3;  // 2, 3, 5 are already included
//     for (int w = 0; w < wheel_limit; w++) {
//         for (int i = 0; i < WHEEL_SIZE; i++) {
//             int num = w * 30 + wheel_offsets[i];
//             if (num <= limit && num > 5 && sieve[w * WHEEL_SIZE + i]) {
//                 count++;
//             }
//         }
//     }
    
//     free(sieve);
//     return count;
// }

// Key Optimizations
// Memory Layout: Use char arrays instead of bool for better cache performance

// Scheduling: Use schedule(dynamic) for uneven workloads

// Cache Blocking: Process data in 128KB blocks for optimal cache usage

// Wheel Factorization: Skip multiples of 2, 3, 5 to reduce candidates by 77%

// SIMD: Consider vectorization for large-scale sieving operations

// Memory Usage Guidelines
// Small ranges (< 10^8): Use simple parallel sieve

// Medium ranges (10^8 to 10^12): Use block-wise sieve with 128KB blocks

// Large ranges (> 10^12): Use segmented sieve with wheel factorization

// Very large ranges (> 10^16): Combine segmented + wheel + specialized algorithms



// ===========================================================================
// Generate primes up to sqrt(n) for Goldbach verification
// int* generateSmallPrimes(int limit, int* count) {
//     int* primes = (int*)malloc(limit * sizeof(int));
//     char* is_prime = (char*)malloc((limit + 1) * sizeof(char));
    
//     for (int i = 0; i <= limit; i++) is_prime[i] = 1;
//     is_prime = is_prime = 0;
    
//     *count = 0;
//     for (int i = 2; i <= limit; i++) {
//         if (is_prime[i]) {
//             primes[(*count)++] = i;
//             for (int j = i * i; j <= limit; j += i)
//                 is_prime[j] = 0;
//         }
//     }
    
//     free(is_prime);
//     return primes;
// }

// // Fast primality test for Goldbach pairs
// int isPrimeFast(int n, int* primes, int prime_count) {
//     if (n < 2) return 0;
//     if (n == 2) return 1;
//     if (n % 2 == 0) return 0;
    
//     int limit = sqrt(n) + 1;
//     for (int i = 0; i < prime_count && primes[i] <= limit; i++) {
//         if (n % primes[i] == 0) return 0;
//     }
//     return 1;
// }

// // Goldbach verification with parallel search
// int verifyGoldbach(int n) {
//     if (n % 2 != 0 || n < 4) return 0;
    
//     int prime_count;
//     int* small_primes = generateSmallPrimes(sqrt(n) + 1, &prime_count);
    
//     int found = 0;
//     #pragma omp parallel for
//     for (int p = 2; p <= n/2; p++) {
//         if (!found && isPrimeFast(p, small_primes, prime_count)) {
//             int q = n - p;
//             if (isPrimeFast(q, small_primes, prime_count)) {
//                 #pragma omp critical
//                 {
//                     if (!found) {
//                         printf("%d = %d + %d\n", n, p, q);
//                         found = 1;
//                     }
//                 }
//             }
//         }
//     }
    
//     free(small_primes);
//     return found;
// }

// int main() {
//     // Example: verify Goldbach for even numbers
//     for (int n = 4; n <= 1000; n += 2) {
//         if (!verifyGoldbach(n)) {
//             printf("Goldbach conjecture fails for %d\n", n);
//             return 1;
//         }
//     }
    
//     printf("Goldbach conjecture verified for all even numbers up to 1000\n");
//     return 0;
// }



// ===========================================================================

int isprime(int n, int* primes, int prime_count) {
  if(n < 2) return 0;
  for(int i = 0; i < prime_count && primes[i] * primes[i] <= n; i++) {
    if(n % primes[i] == 0) return 0;
  }
  return 1;
}


// ============================================================================

int goldbach_simple(int x, int* primes, int prime_count) {
  int count = 0;
  if(x <= 2) return 0;
  for(int i = 0; i < prime_count && primes[i] <= x / 2; i++) {
    if(isprime(x - primes[i], primes, prime_count)) {
      count++;
    }
  }
  return count;
}


// https://oeis.org/A002372
// https://arxiv.org/pdf/2304.00024
// 3.1.5. Simplified outlines of Algorithms 1 and 2.
// Input: m1, m2, N, 4, α ∈ N
// + such that gcd(m1, m2) = 1, N > 9, 2m1m2|N, 2m1m2|4 and α ≤ 4.
// Output: array residual containing all numbers n ≤ N satisfying the conditions of GGCm1,m2
// for
// which there are no primes p and q such that n = m1p + m2q and m1p ≤ α.
// (1) Phase I: Unsegmented phase
// (a) Generating ‘small’ primes up to K = max {b√
// N/m2c, bα/m1c}.
// (b) Generating all numbers m1p ≤ α where p is prime. In Algorithm 2 these are sorted
// and stored separately according to their modulo m2 residues.
// (c) Generating the modulo lcmm1,m2
// ‘residue wheel’, i.e. the array of all modulo lcmm1,m2
// residues relatively prime to m1m2 and congruent to m1 + m2 modulo 2.
// (2) Phase II: Checking GGCm1,m2
// segment by segment
// For each interval [A, B):
// (a) Generating ‘large’ primes and their m2-times multiples in an interval.
// (i) Generating all primes in interval [C/m2, D/m2). (The values C and D depend
// on A and B.)
// (ii) Generating all numbers of the form m2q in interval [C, D), where q is prime. In
// Algorithm 1 these are sorted and stored separately according to their modulo
// m1 residues.
// (b) Checking GGCm1,m2
// in interval [A, B).


// gcc -O3 -march=native -fopenmp golbach.c -o goldbach -lm 
int main() {
  int LIMIT = 100000;
  int* goldbach_count = (int*)malloc((LIMIT/2 +1) * sizeof(int));

  double ts = omp_get_wtime();
  
  int prime_count = 0;
  int* primes = primenums(LIMIT, &prime_count);

  double tp = omp_get_wtime();
  printf("Generated %d primes up to %d in %f seconds.\n", prime_count, LIMIT, tp - ts);

  int nthreads;
  #pragma omp parallel
  nthreads = omp_get_num_threads();

  #pragma omp parallel for num_threads(nthreads) shared(primes, prime_count) schedule(dynamic)
  for(int i=1; i<LIMIT/2; i++) {
    goldbach_count[i] = goldbach_simple(2*i, primes, prime_count);
    // goldbach_count[i] = faster_goldbach(2*i, primes, prime_count);
  }

  double te = omp_get_wtime();
  printf("Goldbach counts for even numbers up to %d:\n", LIMIT);
  printf("n  Goldbach(n)\n");
  for(int i=1; i<30; i++) {
    printf("%d\t%d\n", 2*i, goldbach_count[i]);
  }
  printf("Time taken: %f seconds\n", te - ts);

  free(primes);
  free(goldbach_count);
  return 0;
}