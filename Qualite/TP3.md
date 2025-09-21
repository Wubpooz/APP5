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