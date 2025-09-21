# TP3
**Mathieu WAHARTE** - 19/09/2025

&nbsp;  
&nbsp;  
## Exercice 1
1) On observe bien que `non-terminate` est prouvée par Frama-C.
  ![non-terminate_proof](./images/TP3_exo1_1_non-terminate.png)
  Cependant, la clause de terminaison ajoutée automatiquement n'est pas prouvée, la fonction ne se terminant pas. Nous reverons cela dans la question 3.

2) On ajoute l'assertion `/*@assert \false;*/` après la boucle:
    ```c
    while (1)
      ;
    /*@assert \false;*/
    return a;
    ```
    Frama-C arrive à prouver l'assertion alors que celle-ci est fausse. Cela nous indique bien que comme la boucle ne termine pas, le programme ne peut jamais atteindre l'assertion et donc elle est considérée comme toujours vraie au lieu de sa vrai valeur de vérité.
    ![non-terminate_assert](./images/TP3_exo1_2_non-terminate_assert.png)

3) On ajoute la clause de terminaison `/*@ terminates \true; */`:
    ```c
    /*@ terminates \true; */
    int f() {
      ...
    ```
    Comme pour la clause automatiquement ajoutée à la question 1, Frama-C n'arrive pas à prouver que la fonction termine pour tout ses contextes d'appels (c'est ce que `\true` signifie). En effet, la fonction ne termine pas.
    ![non-terminate_terminates](./images/TP3_exo1_3_non-terminate_terminates_clause.png)

4) Pour aider Frama-C, j'ajoute `/*@loop assigns \nothing; */` avant la boucle infinie:
    ```c
    /*@ terminates \true; */
    int f() {
      int a = 42;
      /*@loop assigns \nothing; */
      while (1)
        ;
      /*@assert \false;*/
      return a;
    }
    ```
    Cela indique à Frama-C que la boucle n'affecte aucune variable. Cependant, cela ne l'aide pas à prouver que la fonction termine, car la boucle ne termine pas.
    ![non-terminate_loop_assigns](./images/TP3_exo1_4_non-terminate_loop_assigns.png)

  
&nbsp;  
## Exercice 2

1) On ajoute ces invariants et assigns à la boucle de la fonction:
    ```c
    int f() {
      int i = 30;
      int j = 0;
      /*@ 
      loop invariant 0 <= i <= 30;
      loop invariant j == 30 - i;
      loop assigns i,j; 
      */
      while(i>0){
        j++;
        i--;
      }
      return j;
    }
    ```
    `i` est toujours entre 0 et 30 car elle est initialisée à 30 et décrémentée à chaque itération jusqu'à ce qu'elle atteigne 0. `j` est toujours égal à `30 - i` car elle est initialisée à 0 et incrémentée à chaque itération pendant que `i` est décrémentée. Les `assigns` indiquent que les variables `i` et `j` sont modifiées par la boucle. Frama-C arrive à prouver toutes les clauses.
    ![terminating_proof](./images/TP3_exo2_1_terminating_proof.png)

2) Cependant, on peut voir sur le screenshot précédent que la clause `terminates \true;` n'est pas prouvée. En effet, Frama-C ne peut pas déterminer automatiquement que la boucle termine.
  
3)  Pour l'aider, on ajoute la clause de terminaison `/*@ loop variant i; */`:
    ```c
    int f() {
      int i = 30;
      int j = 0;
      /*@ 
      loop invariant 0 <= i <= 30;
      loop invariant j == 30 - i;
      loop assigns i,j; 
      loop variant i;
      */
      while(i>0){
        j++;
        i--;
      }
      return j;
    }
    ```
    Cela indique à Frama-C que `i` diminue à chaque itération de la boucle et il sait aussi qu'elle est toujours positive au début de chaque itération (grâce à l'invariant `0 <= i <= 30`). Ainsi, Frama-C peut conclure que la boucle termine et donc que la fonction termine.
    ![terminating_variant](./images/TP3_exo2_2_terminating_variant.png)



&nbsp;  
## Exercice 3

