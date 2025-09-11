// Basic
/*
  ensures (a == b || b == c || a == c) <==> \result == 0;
  ensures (a != b && a != c && b != c && a < b && a < c) <==> \result == 1;
  ensures (a != b && a != c && b != c && b < a && b < c) <==> \result == 2;
  ensures (a != b && a != c && b != c && c < a && c < b) <==> \result == 3;
*/

// Predicate
/*
  predicate allDifferent(integer a, integer b, integer c) = a != b && a != c && b != c;
  predicate firstInputIsSmallest(integer a, integer b, integer c) = a < b && a < c;
*/
/*
  ensures !allDifferent(a,b,c) <==> \result == 0;
  ensures allDifferent(a,b,c) && firstInputIsSmallest(a,b,c) <==> \result == 1;
  ensures allDifferent(a,b,c) && firstInputIsSmallest(b,a,c) <==> \result == 2;
  ensures allDifferent(a,b,c) && firstInputIsSmallest(c,a,b) <==> \result == 3;
*/

// Behavior
/*@
  behavior equal:
    assumes a == b || b == c || a == c;
    ensures \result == 0;

  behavior firstSmallest:
    assumes a != b && a != c && b != c && a < b && a < c;
    ensures \result == 1;

  behavior secondSmallest:
    assumes a != b && a != c && b != c && b < a && b < c;
    ensures \result == 2;

  behavior thirdSmallest:
    assumes a != b && a != c && b != c && c < a && c < b;
    ensures \result == 3;

  complete behaviors;
  disjoint behaviors equal, firstSmallest, secondSmallest, thirdSmallest;
*/
int caseResult(int a, int b, int c);