#include "mystery.h"

int mystery(int hidden){
	int b = hidden+1;
  /*@ loop assigns b; */
	while(b != hidden){
		b = askPlayerNumber();
	}
	return b;
}