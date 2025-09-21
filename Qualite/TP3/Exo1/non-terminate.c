/*@ terminates \true;
    ensures \result == 42;
    ensures \result == 34;
    ensures \result == -15;
    ensures \result != \result;
*/
int f()
{
  int a = 42;
  /*@loop assigns \nothing; */
  while (1)
    ;
  /*@assert \false;*/
  return a;
}