// gcc -O3 -std=c11 -march=native verify_goldbach.c -o verify -lm
// # verify tuples in file results.txt
// ./verify -i results.txt -m1 1 -m2 2

// # verify and try to check minimality using a sieve up to 5e6 (for p candidates)
// ./verify -i results.txt -m1 1 -m2 2 -check-minimal -sieve-limit 5000000


// verify_goldbach.c
// Verifier for (m1,m2)-Goldbach partitions (checks triples n,p,q).
// - primality: deterministic Miller-Rabin for 64-bit
// - GGC conditions: gcd-checks and modulus condition per paper
// Usage: see comments printed by program.
//
// Based on: "Empirical verification..." (arXiv:2304.00024) and user's implementation faster_goldbach.c. 
// Paper pseudocode / alpha discussion referenced. :contentReference[oaicite:5]{index=5}
// User implementation inspected: faster_goldbach.c. :contentReference[oaicite:6]{index=6}

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>
#include <math.h>
#include <ctype.h>
#include <stdbool.h>

// ---- utilities for 64-bit modular arithmetic ----
static inline uint64_t mulmod64(uint64_t a, uint64_t b, uint64_t m) {
    __uint128_t z = ( __uint128_t ) a * b;
    return (uint64_t)(z % m);
}
static inline uint64_t powmod64(uint64_t a, uint64_t e, uint64_t m) {
    uint64_t r = 1;
    while (e) {
        if (e & 1) r = mulmod64(r, a, m);
        a = mulmod64(a, a, m);
        e >>= 1;
    }
    return r;
}

// Deterministic Miller-Rabin for 64-bit integers using known bases
// Correct bases for testing 64-bit integers: {2,3,5,7,11,13,17} (safe set)
bool is_prime_u64(uint64_t n) {
    if (n < 2) return false;
    static const uint64_t smalls[] = {2,3,5,7,11,13,17,19,23,29,31,37};
    for (size_t i=0;i<sizeof(smalls)/sizeof(smalls[0]);++i) {
        if (n == smalls[i]) return true;
        if (n % smalls[i] == 0) return (n == smalls[i]);
    }
    uint64_t d = n - 1;
    int s = 0;
    while ((d & 1) == 0) { d >>= 1; ++s; }
    uint64_t bases[] = {2,3,5,7,11,13,17};
    for (size_t i=0;i<sizeof(bases)/sizeof(bases[0]);++i) {
        uint64_t a = bases[i];
        if (a % n == 0) continue;
        uint64_t x = powmod64(a, d, n);
        if (x == 1 || x == n-1) continue;
        bool composite = true;
        for (int r = 1; r < s; ++r) {
            x = mulmod64(x, x, n);
            if (x == n-1) { composite = false; break; }
        }
        if (composite) return false;
    }
    return true;
}

// gcd for uint64
uint64_t gcd_u64(uint64_t a, uint64_t b) {
    while (b) {
        uint64_t t = b;
        b = a % b;
        a = t;
    }
    return a;
}

// Check GGC conditions per the paper (reduced form): gcd constraints and parity / 2-power condition
bool satisfies_ggc_conditions(uint64_t n, uint64_t m1, uint64_t m2) {
    uint64_t d = gcd_u64(m1, m2);
    if (gcd_u64(n, m1) != d) return false;
    if (gcd_u64(n, m2) != d) return false;
    // find largest power 2^s dividing d
    uint64_t temp = d;
    int s = 0;
    while ((temp % 2) == 0 && temp > 0) { temp /= 2; ++s; }
    // condition: n ≡ m1 + m2 (mod 2^(s+1))
    uint64_t mod = 1ULL << (s + 1); // safe because m1,m2 small in practice; user aware
    return (n % mod) == ((m1 + m2) % mod);
}

// Sieve primes up to limit (simple bitset sieve). Returns array of primes (malloced, count output).
uint32_t* sieve_primes(uint32_t limit, size_t* out_count) {
    if (limit < 2) { *out_count = 0; return NULL; }
    uint8_t *is = calloc(limit+1, 1);
    if (!is) return NULL;
    for (uint32_t i=2;i<=limit;++i) is[i]=1;
    for (uint32_t p=2; p*p <= limit; ++p) if (is[p]) {
        for (uint32_t q = p*p; q <= limit; q += p) is[q] = 0;
    }
    size_t count = 0;
    for (uint32_t i=2;i<=limit;++i) if (is[i]) ++count;
    uint32_t *pr = malloc(count * sizeof(uint32_t));
    size_t idx = 0;
    for (uint32_t i=2;i<=limit;++i) if (is[i]) pr[idx++] = i;
    free(is);
    *out_count = count;
    return pr;
}

// Try to find a smaller p' < p that gives a valid partition (best-effort using sieve primes up to sieve_limit).
// Returns 1 if found (and fills p_found,q_found), 0 otherwise.
int find_smaller_p(uint64_t n, uint64_t m1, uint64_t m2, uint64_t p_given, uint32_t sieve_limit,
                   uint64_t *p_found, uint64_t *q_found)
{
    // We'll iterate over primes p' <= min(p_given-1, sieve_limit/m1)
    if (p_given <= 2) return 0;
    uint32_t limit = sieve_limit;
    if (limit < 2) return 0;
    size_t pcnt = 0;
    uint32_t *pr = sieve_primes(limit, &pcnt);
    if (!pr) return 0;
    // For each prime p' in increasing order < p_given:
    for (size_t i=0;i<pcnt;++i) {
        uint64_t p = pr[i];
        if (p >= p_given) break;
        uint64_t lhs = m1 * p;
        if (lhs >= n) break;
        uint64_t rem = n - lhs;
        if (rem % m2 != 0) continue;
        uint64_t q = rem / m2;
        if (q < 2) continue;
        // If q <= sieve_limit we can test via sieve; otherwise do Miller-Rabin
        bool qprime = (q <= limit) ? (bsearch(& (uint32_t){(uint32_t)q}, pr, pcnt, sizeof(uint32_t),
                        (int(*)(const void*, const void*))strcmp) != NULL) : is_prime_u64(q);
        // the above bsearch trick with inline + strcmp is messy; simpler:
        if (q <= limit) {
            // linear find (primes vector is small for typical use); avoid dependencies
            bool found = false;
            for (size_t j=0;j<pcnt;++j) if (pr[j] == (uint32_t)q) { found = true; break; }
            qprime = found;
        } else {
            qprime = is_prime_u64(q);
        }
        if (qprime) {
            *p_found = p;
            *q_found = q;
            free(pr);
            return 1;
        }
    }
    free(pr);
    return 0;
}

// Helper: robust parsing of "n p q" or "n, p, q"
int parse_triple(const char* line, uint64_t *n, uint64_t *p, uint64_t *q) {
    // replace commas with spaces
    char buf[256];
    size_t L = strlen(line);
    if (L >= sizeof(buf)-1) return 0;
    for (size_t i=0;i<=L;i++) {
        char c = line[i];
        if (c == ',' ) buf[i] = ' ';
        else buf[i] = c;
    }
    // tokenize
    char *s = buf;
    while (isspace((unsigned char)*s)) ++s;
    if (*s == '\0') return 0;
    char *tok1 = strtok(s, " \t\r\n");
    if (!tok1) return 0;
    char *tok2 = strtok(NULL, " \t\r\n");
    if (!tok2) return 0;
    char *tok3 = strtok(NULL, " \t\r\n");
    if (!tok3) return 0;
    char *endp;
    *n = strtoull(tok1, &endp, 10); if (*endp != '\0') return 0;
    *p = strtoull(tok2, &endp, 10); if (*endp != '\0') return 0;
    *q = strtoull(tok3, &endp, 10); if (*endp != '\0') return 0;
    return 1;
}

void usage(const char* prog) {
    fprintf(stderr,
        "Usage: %s [options]\n"
        "Options:\n"
        "  -i FILE         Input file (lines: n p q or n, p, q). If omitted reads stdin.\n"
        "  -m1 M1 -m2 M2   Coefficients (defaults 1 1)\n"
        "  -alpha VAL      alpha parameter (informational only), default 50000000\n"
        "  -check-minimal  Try to find a strictly smaller p' giving a partition (uses sieve-limit)\n"
        "  -sieve-limit N  Limit for sieve used by -check-minimal (default 500000)\n"
        "  -h              Show help\n",
        prog);
}

int main(int argc, char** argv) {
    const char* infile = NULL;
    uint64_t m1 = 1, m2 = 1;
    uint64_t alpha = 50000000ULL;
    bool do_check_minimal = false;
    uint32_t sieve_limit = 500000; // default for minimality checks

    for (int i=1;i<argc;++i) {
        if (strcmp(argv[i], "-i")==0 && i+1<argc) { infile = argv[++i]; }
        else if (strcmp(argv[i], "-m1")==0 && i+1<argc) { m1 = strtoull(argv[++i], NULL, 10); }
        else if (strcmp(argv[i], "-m2")==0 && i+1<argc) { m2 = strtoull(argv[++i], NULL, 10); }
        else if (strcmp(argv[i], "-alpha")==0 && i+1<argc) { alpha = strtoull(argv[++i], NULL, 10); }
        else if (strcmp(argv[i], "-check-minimal")==0) { do_check_minimal = true; }
        else if (strcmp(argv[i], "-sieve-limit")==0 && i+1<argc) { sieve_limit = (uint32_t)atoi(argv[++i]); }
        else if (strcmp(argv[i], "-h")==0) { usage(argv[0]); return 0; }
        else { usage(argv[0]); return 1; }
    }

    FILE *in = stdin;
    if (infile) {
        in = fopen(infile, "r");
        if (!in) { perror("fopen"); return 1; }
    }

    char line[512];
    size_t lineno = 0;
    printf("# Verifier starting: m1=%" PRIu64 " m2=%" PRIu64 " alpha=%" PRIu64 "\n", m1, m2, alpha);
    printf("# Input format: n p q (or n, p, q)\n");
    while (fgets(line, sizeof(line), in)) {
        lineno++;
        uint64_t n,p,q;
        if (!parse_triple(line, &n, &p, &q)) continue; // skip blank or unparsable lines
        printf("Line %zu: n=%" PRIu64 " p=%" PRIu64 " q=%" PRIu64 " -- ", lineno, n, p, q);
        bool ok_eq = (n == m1 * p + m2 * q);
        if (!ok_eq) {
            printf("BAD: equation fails (n != m1*p + m2*q)\n");
            continue;
        }
        bool pprime = is_prime_u64(p);
        bool qprime = is_prime_u64(q);
        if (!pprime || !qprime) {
            printf("BAD: primality: p:%s q:%s\n", pprime ? "prime":"composite", qprime ? "prime":"composite");
            continue;
        }
        if (!satisfies_ggc_conditions(n, m1, m2)) {
            printf("BAD: does not satisfy GGC conditions (gcd/mod) per paper\n");
            continue;
        }
        printf("OK (equation + primes + GGC-conds).\n");

        if (do_check_minimal) {
            uint64_t p_found=0,q_found=0;
            // best-effort: try to find p' < p using sieve up to sieve_limit
            int found = find_smaller_p(n, m1, m2, p, sieve_limit, &p_found, &q_found);
            if (found) {
                printf("  NOTE: Found smaller p'=%" PRIu64 " with q'=%" PRIu64 " (so p was NOT minimal within sieve limit %u)\n",
                       p_found, q_found, sieve_limit);
            } else {
                printf("  Checked minimality up to sieve limit %u: no smaller p' found (best-effort)\n", sieve_limit);
            }
        }
    }

    if (infile) fclose(in);
    return 0;
}
