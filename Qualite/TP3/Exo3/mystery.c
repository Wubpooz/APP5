#include "mystery.h"

int mystery(int hidden){
	int b = hidden+1;
	while(b != hidden){
		b = askPlayerNumber();
	}
	return b;
}