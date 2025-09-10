#include "terminating.h"

int f(){
	int i = 30;
	int j = 0;
	while(i>0){
		j++;
		i--;
	}
	return j;
}