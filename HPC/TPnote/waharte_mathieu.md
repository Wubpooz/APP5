# TP Noté, Filtre de détection de contours - Calcul Hautes Performances
**Mathieu Waharte** APP5 IIM

## I. MPI
1) Le problème avec les tableaux à 2 dimensions alloués dynamiquement est que les lignes du tableau ne sont pas contiguës en mémoire, du coup on ne peut pas juste donner un pointeur de début pour la communication MPI. Pour régler cela, on peut utiliser un tableau 1D (qui sera lui contiguë) avec des macro comme on a déjà avec IDX. On pourrait aussi allouer un tableau 2D de manière contiguë à l'aide de fonctions personnalisées, mais c'est plus compliqué (on pourrait free avec le free normal et non le spécifique, on ne peut pas faire d'overload comme en C++).

<!-- Quel problème se poserait pour les communications MPI si on avait des tableaux a 2 dimensions alloués dynamiquement:
```c
unsigned char**img_src = (unsigned char**)malloc(N * sizeof(unsigned char*));
for(int i=0;i<N;i++) {
  img_src[i] = (unsigned char*)malloc(M*sizeof(unsigned char));
}
```
Bonus: proposer une solution pour contourner ce problème en gardant des tableaux à deux dimension alloués dynamiquement. -->


2) Mon implémentation est bonne, il ne semble pas qu'on processus doive attendre plus que les autres puisque tous les processus envoient et reçoivent des données de manière synchronisée (ce qui du coup n'est pas optimal). Une amélioration possible serait d'utiliser des communications non bloquantes (MPI_Isend et MPI_Irecv) pour permettre aux processus de continuer à travailler pendant qu'ils attendent les données. Cela veut dire aussi qu'il faut revoir le calcul pour ne faire la somme sur les pixels loin des bords en premier et checker que les données sont reçues avant de faire le calcul sur les bords, ce qui rendrait le calcul aléatoire en temps mais plus efficace (on peut s'attendre à avoir reçu les données après qu'on ait traité l'ensemble du reste).
Sur une autre note, avoir 2 SendRecv qui se suivent peut être optimisé par 2 Isend/Irecv suivis d'un MPI_Waitall, mais l'impact serait plus faible je pense.

<!-- Votre implémentation des communications entre voisons vous paraît-elle optimale? Justifier votre réponse et proposer une amélioration si nécessaire.
Indice: y'a-t-il un processus qui risque d'attendre les données plus longtemps que les autres?  -->


&nbsp;  
## II. OpenMP
Impossible d'optimiser l'initalisation aléatoire car dans la spécification de rand() (trouvable en ligne ou avec `man rand`) on trouve:  
![man rand](man_rand.png)  
Ce qui signifie que l'utilisation de rand() dans une région parallèle peut causer des problèmes de concurrence et des résultats imprévisibles. Pour contourner ce problème, on pourrait utiliser rand_r() qui est une version réentrante de rand() et permet de gérer l'état de manière explicite pour chaque thread. Mais sinon on ne peut pas utliser rand() dans une région parallèle donc on ne peut pas paralléliser cette partie du code.  


&nbsp;  
## III. Performances
1-2)&nbsp;  &nbsp;  Après mesure, on obtient les résultats suivants:  
|   | Temps   | Accélération | Efficacité |
|---|---| ---|---|
| Séquentiel  | 16.02s  | 1x | 100% |
| MPI (4 process)  | 3.95s  | 4.06x | **101.5%** |
| OpenMP (16 threads)  | **1.28s**  | **12.5x** | 78.1% |

&nbsp;  
3) On n'obtient pas les gains attendus car...

4) Si l'on incluait l'initalisation, ..... Donc, ....


&nbsp;  
Sources des mesures:   
![Sequential time](sequential_time.png)
![MPI Time 4 processus](mpi_time_4proc.png)
![OpenMP Time 16 processus](openmp_time_16.png)
