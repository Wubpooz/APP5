#include "memcpy.h"

int memcpy(char* src, size_t src_size, size_t src_offset, char* dest, size_t dest_size,  size_t dest_offset, size_t size) {
  if (src_offset >= src_size ||
    dest_offset >= dest_size ||
    size > src_size - src_offset ||
    size > dest_size - dest_offset) {
    return -1;
  }

  /*@
    loop invariant 0 <= i <= size;
    loop invariant i <= size;
    loop invariant dest_offset + i <= dest_size;
    loop invariant src_offset + i <= src_size;
    loop invariant \forall integer k; 0 <= k < i ==> dest[dest_offset + k] == src[src_offset + k];
    loop invariant \forall integer k; 0 <= k < dest_size && (k < dest_offset || k >= dest_offset + size) ==> dest[k] == \at(dest[k], Pre);
    loop invariant \forall integer k; 0 <= k < src_size ==> src[k] == \at(src[k], Pre);
    loop assigns i, dest[dest_offset .. dest_offset + size - 1];
    loop variant size - i;
  */
  for (size_t i = 0; i < size; i++) {
    dest[dest_offset + i] = src[src_offset + i];
  }
  return 0;
}

/*@
  assigns \nothing;
*/
int main(void){
	char src[17] = "The expert knows.";
	char dest[22] = "I am a Frama-C newbie!";
	int res = memcpy(src,17,14,dest,22,1,6);
	//@ assert res == -1;
	res = memcpy(src,17,4,dest,22,21,6);
	//@ assert res == -1;
	res = memcpy (src,17,19,dest,22,15,6);
	//@ assert res == -1;
	res = memcpy (src,17,4,dest,22,25,6);
	//@ assert res == -1;
	res = memcpy (src,17,4,dest,22,15,0);
	//@ assert res == 0;
	res = memcpy(src,17,4,dest,22,15,6);
	//@ assert res == 0;
	//@ assert \forall size_t i; 0<= i< 6 ==> dest[15+i] == src[4+i];
	return 0;
}