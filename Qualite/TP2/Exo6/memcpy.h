#ifndef MEMCPY_H
#define MEMCPY_H
#include <stddef.h>
#include <limits.h>

/* Informal  specification:
'src' is an array of size 'src_size'
'dest' is an array of size 'dest_size'
The function copies 'size' items from array 'src' into array 'dest',
with offsets 'src_offset' and 'dest_offset'.
Returns -1 in case of error (i.e., if size > (src_size - src_offset), if src_offset >= src_size, and similarly for dest).
*/

/**
 * @brief Copies the content of src[src_offset .. src_offset+size] into dest[dest_offset .. dest_offset+size]. Return 0 in case of success and -1 if a failure occurs. In that last case, the content of dest is left unchanged.
 * 
 * @param src an array to be read from
 * @param src_size the size of @p src
 * @param src_offset the starting position read in @p src
 * @param dest an array to be written to
 * @param dest_size the size of @p dest
 * @param dest_offset the starting position written to in @p dest
 * @param size the number of values to copy
 * @return int 0 in case of success, -1 in case of failure.
 * @pre @p src and @p dest must be valid arrays of their respective size
 * @pre @p src and @p dest must be disjoint arrays
 * 
 */

/*@
  requires src != \null && dest != \null;
  requires src_size > 0 && dest_size > 0;
  requires \valid_read(src + (0 .. src_size-1));
  requires \valid(dest + (0 .. dest_size-1));
  requires \separated(src + (0 .. src_size-1), dest + (0 .. dest_size-1));
  requires src_offset <= src_size;
  requires dest_offset <= dest_size;
  requires size <= INT_MAX - src_offset;
  requires size <= INT_MAX - dest_offset;

  behavior error:
    assumes size > src_size - src_offset || src_offset >= src_size
         || size > dest_size - dest_offset || dest_offset >= dest_size;
    ensures \result == -1;
    ensures \forall integer i; 0 <= i < dest_size ==> dest[i] == \old(dest[i]);
    ensures \forall integer i; 0 <= i < src_size ==> src[i] == \old(src[i]);
    assigns \nothing;

  behavior success:
    assumes src_offset < src_size && dest_offset < dest_size
         && size <= src_size - src_offset
         && size <= dest_size - dest_offset;
    ensures \result == 0;
    ensures \forall integer i; 0 <= i < src_size ==> src[i] == \old(src[i]);
    ensures \forall integer i; 0 <= i < dest_size && (i < dest_offset || i >= dest_offset + size) ==> dest[i] == \old(dest[i]);
    ensures \forall integer i; 0 <= i < size ==> dest[dest_offset + i] == src[src_offset + i];
    assigns dest[dest_offset .. dest_offset + size - 1];

  complete behaviors;
  disjoint behaviors;
@*/
int memcpy(char *src, size_t src_size, size_t src_offset, char *dest, size_t dest_size, size_t dest_offset, size_t size);

#endif // MEMCPY_H