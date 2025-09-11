# TP1
**Mathieu WAHARTE** - 10/09/2025

&nbsp;  
&nbsp;  
## Exercice 1
5. Aucune des spécifications n'est correcte, pour `abs`, si l'on fait `abs(-INT_MAX)`, on va avoir de l'overflow (du fait de la représentation binaire des entiers). Pour `add`, on peut avoir de l'overflow si on additionne deux entiers très grands. Pour `div`, on peut avoir une division par zéro ou par un très grand nombre qui donnera un overflow. Les spécifications ne prennent pas en compte ces cas.
6. Les WP-rte guards générés sont:
   - Pour abs:
    ```c
    /*@ assert rte: signed_overflow: -2147483647 ≤ val; */
    ```
    - Pour add:
    ```c
    /*@ assert rte: signed_overflow: -2147483648 ≤ a + b; */
    /*@ assert rte: signed_overflow: a + b ≤ 2147483647; */
    ```
   - Pour div:
    ```c
    /*@ assert rte: division_by_zero: b ≢ 0; */
    /*@ assert rte: signed_overflow: a / b ≤ 2147483647; */
    ```
    On pourra deviner que "rte" signifie "runtime error".



&nbsp;  
&nbsp;  
## Exercice 2
1. Ma spécification pour max:
    ```c
    /*@ 
      ensures \result >= \old(a) && \result >= \old(b) && ( \result == \old(a) || \result == \old(b)); */
    ```
    Résultat de Frama-C qui valide la spécification:
    ![frama-c-max](./images/TP1_exo2_1_frama-c-max.png)

2. Résultat de ma spécification sur `max_wrong1.c`:
  ![frama-c-max-wrong1](./images/TP1_exo2_2_frama-c-max-wrong1.png)
    Frama-C détecte que la spécification n'est pas respectée, car le code renvoie toujours `a`, même si `b` est plus grand.
    Résultat de ma spécification sur `max_wrong2.c`:
  ![frama-c-max-wrong2](./images/TP1_exo2_2_frama-c-max-wrong2.png)
    Frama-C détecte que la spécification n'est pas respectée, car le code renvoie toujours `INT_MAX` qui n'est pas forcément la valeur de `a` ou `b`.

3. Ma spécification pour max de 5 entiers:
    ```c
    /*@ 
    ensures \result >= \old(a) && \result >= \old(b) && \result >= \old(c) && \result >= \old(d) && \result >= \old(e);
    ensures  \result == \old(a) || \result == \old(b) || \result == \old(c) || \result == \old(d) || \result == \old(e); */
    ```
    Résultat de Frama-C qui valide la spécification:
    ![frama-c-max-5](./images/TP1_exo2_3_frama-c-max-5.png)
    J'ai découpé la spécification en 2 ensures pour simplifier le travail du prouveur.


&nbsp;  
&nbsp;  
## Exercice 3
1. La spécification de `plus_one` donne:
  ![frama-c-plus-one](./images/TP1_exo3_1_frama-c-plus-one.png)
  Frama-C détecte que la spécification n'est pas respectée, car on ajoute juste 1 à un nombre mais la spécification demande que le résultat soit positif, elle ne correspond pas à la fonction.

2. $WP(plus\_one, res>=0) = WP(a+1, res>=0) = (a+1 >= 0) = (a >= -1)$
  Donc la précondition minimale de `plus_one` pour la postcondition que `resultat >= 0` est `a >= -1`.

3. Fram-C a généré le WP-rte guard suivant:
  ![frama-c-plus-one-rte](./images/TP1_exo3_3_frama-c-plus-one-rte.png)
  Cette assertion est là pour éviter un overflow lors de l'addition `a + 1`. En effet, si `a` est égal à `INT_MAX`, alors `a + 1` va provoquer un overflow. De prime ce résultat serait en plus négatif, ce qui viole la postcondition `resultat >= 0`.  
  L'option `-rte` de Frama-C permet d'ajouter des assertions pour vérifier que le code ne provoque pas d'erreurs d'exécution (comme des overflows, divisions par zéro, etc.).

4. Ma spécification corrigée de `plus_one`:
    ```c
    /*@ requires a < 2147483647 && a >= -1;
        ensures \result >= 0; */
    ```
    Résultat de Frama-C qui valide la spécification:
    ![frama-c-plus-one-corrige](./images/TP1_exo3_4_frama-c-plus-one-corrige.png)
    J'ai ajouté une précondition pour éviter l'overflow lors de l'addition `a + 1`. `INT_MAX` vaut `2147483647` en C sur une architecture 32 bits. J'ai aussi ajouté `a >= -1` pour respecter la postcondition.

5. Pour `div`, Frama-C génére les WP-rte guards suivantes:
    ```c
    /*@ assert rte: division_by_zero: b ≢ 0; */
    /*@ assert rte: signed_overflow: a / b ≤ 2147483647; */
    ```

    Je propose donc la spécification suivante:
    ```c
    /*@ requires b != 0 && (a != INT_MIN || b != -1);
        ensures \result == a / b; */
    ```
    Résultat de Frama-C qui valide la spécification:
    ![frama-c-div-corrige](./images/TP1_exo3_5_frama-c-div-corrige.png)
    J'ai ajouté une précondition pour éviter la division par zéro. La deuxième partie de la précondition évite l'overflow qui peut arriver si on divise `INT_MIN` par `-1` (le résultat serait `INT_MAX + 1`, ce qui provoque un overflow).

6. L'affichage du retour des "bad-calls" dans calling-functions donnent:
  ```
  Result of bad_call_1: -344 => valide mais ne respecte pas la postcondition
  Result of bad_call_2: -2147483648 => overflow
  Result of bad_call_3: Floating point exception (core dumped) => div by zero
  Result of bad_call_4: Floating point exception (core dumped) => overflow
  ```
  Frama-C donne:
  - `bad_call_1`: ![frama-c-bad-call-1](./images/TP1_exo3_6_frama-c-bad-call-1.png)
    Frama-C détecte que la postcondition n'est pas respectée, car le résultat est négatif.
  - `bad_call_2`: ![frama-c-bad-call-2](./images/TP1_exo3_6_frama-c-bad-call-2.png)
    Frama-C détecte que la précondition n'est pas respectée, car `a` est égal à `INT_MIN` et `b` est égal à `-1`, ce qui provoque un overflow.
  - `bad_call_3`: ![frama-c-bad-call-3](./images/TP1_exo3_6_frama-c-bad-call-3.png)
    Frama-C détecte que la précondition n'est pas respectée, car `b` est égal à `0`, ce qui provoque une division par zéro.
  - `bad_call_4`: ![frama-c-bad-call-4](./images/TP1_exo3_6_frama-c-bad-call-4.png)
    Frama-C détecte que la précondition n'est pas respectée, car `a` est égal à `INT_MIN` et `b` est égal à `-1`, ce qui provoque un overflow.
  - `good_call_1`: ![frama-c-good-call-1](./images/TP1_exo3_6_frama-c-good-call-1.png)
    Frama-C valide la précondition et la postcondition.
  - `good_call_2`: ![frama-c-good-call-2](./images/TP1_exo3_6_frama-c-good-call-2.png)
    Frama-C valide la précondition et la postcondition.
  - `good_call_3`: ![frama-c-good-call-3](./images/TP1_exo3_6_frama-c-good-call-3.png)
    Frama-C valide la précondition et la postcondition.
  - `good_call_4`: ![frama-c-good-call-4](./images/TP1_exo3_6_frama-c-good-call-4.png)
    Frama-C valide la précondition et la postcondition.
  - `good_call_5`: ![frama-c-good-call-5](./images/TP1_exo3_6_frama-c-good-call-5.png)
    Frama-C valide la précondition et la postcondition.



&nbsp;  
&nbsp;  
## Exercice 4
