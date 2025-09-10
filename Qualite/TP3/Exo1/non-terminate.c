/*@ ensures \result == 42;
    ensures \result == 34;
    ensures \result == -15;
    ensures \result != \result;
*/
int f()
{
  int a = 42;
  while (1)
    ;
  return a;
}