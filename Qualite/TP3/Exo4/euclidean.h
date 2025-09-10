/*@ requires a>0;
    requires \separated(q,r);
    requires \valid(q);
    requires \valid(r);
    terminates b>0;
    ensures *q == a / b;
    ensures *r == a % b;
*/
void euclidianDiv(int a, int b, int *q, int *r);