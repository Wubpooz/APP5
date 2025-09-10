#include "limits.h"

/*@ axiomatic Fibo{
	logic integer fibonacci(integer x);
	
	axiom Init: \forall integer x; x<=0 ==> fibonacci(x) == 0;
	
	axiom Init1: fibonacci(1) == 1;
	
	axiom Ind: \forall integer x; x >= 1 ==> fibonacci(x+1) == fibonacci(x) + fibonacci(x-1);
}
*/


/*@ axiomatic FiboTab{
	predicate fiboTab{L}(int *t, integer i, integer n) reads \at(t[i .. n-1],L);
	
	axiom EmptyOrSmallFiboTab: \forall int *t, integer i,n; n <= i+2 ==> fiboTab(t,i,n);
	
	axiom BigEnoughFiboTab: \forall int *t, integer i,n; i+2 < n ==> fiboTab(t,i,n-1) ==> t[n-1] == t[n-2] + t[n-3] ==> fiboTab(t,i,n);
	
	axiom MissNextVal: \forall int *t, integer i,n; i+2 < n ==> (\exists integer j; i+2<=j<n && t[j] != t[j-1] + t[j-2]) ==> !fiboTab(t,i,n);
}
 */

/* TODO axiomatic SumTab{
	logic integer sumOfTab(int *t,integer i, integer n) reads t[i .. n-1]; // Renvoie la somme des cases du tableau entre i et n-1
	
	axiom SumEmptyTab: "Quand le tableau est vide, la somme est nulle";
	
	axiom SumBiggerTab: "Pour tout i<n, lLa somme de i à n, c’est la somme de i à n-1 plus le dernier élément"
}
*/

/* TODO axiomatic CountTab{
	logic integer countTab(int *t, integer i, integer n, int v) reads t[i .. n-1]; // Renvoie le nombre d’occurences de v dans t entre i et n-1.
	
	axiom CountEmptyTab: "Pour tout v, dans le tableau vide, v apparait 0 fois."
	
	axiom MatchElem: "Pour tout v, si i<n, si t[n-1] == v, alors le résultat c’est le nombre d’occurences de v entre i et n-2 plus 1."
	
	axiom MissElem: "Pour tout v, si i<n, si t[n-1] != v, alors le résultat c’est le nombre d’occurences de v entre i et n-2."
}
 */


/*TODO: predicate swapInArray{L,M}(int *t, int *s, integer i, integer n, integer j, integer k) = ;

	Indication: Si vous écrivez entièrement le prédicat, il risque d’être long et difficile à lire (et redondant). Je vous conseille de le découper en deux sous-prédicats: un qui décrit ce qu’il se passe si on donne des valeurs incohérentes (j ou k ne sont pas entre i et n, ou n<=i), auquel cas on ne modifie pas le tableau; et un qui décrit ce qu’il se passe si les arguments sont dans l’ordre i<=j<=k<n. Le prédicat principal liera les deux (attention au fait que vous devez prendre en compte que des arguments dans l’ordre i<=k<j<n sont valide, et votre prédicat doit décrire ce qui se passe dans ce cas.
*/

/*TODO: axiomatic Permutation{
	predicate permutation{L,M}(int *t, int *s, integer i, integer n) reads \at(t[i .. n-1],L),\at(s[i .. n-1],M); //relie deux tableaux si le second est obtenu par une séquence de swapInArray à partir du premier.
	
	axiom IdentityIsPermutation{L,M}: Deux tableaux identiques sont reliés par une permutation;
	
	axiom SwapPermutation{L,M,K}: Si deux tableaux sont reliés par une permutation et qu’un troisième est obtenu par un swap depuis le deuxième, alors le premier et le troisième sont reliés par une permutation.
}
 */
