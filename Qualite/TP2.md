# TP2
**Mathieu WAHARTE** - 11/09/2025

&nbsp;  
&nbsp;  
## Exercice 1
1. On ne peut en effet pas prouver ces fonctions à cause de la longueur arbitraire du while et du for.
  ![while_for_not_proof](./images/TP2_exo1_1_while-for.png)

2. Code modifié avec l'invariant:
    ```c
    int identity_while(int n){
      int result = 0;
      /*@
        loop invariant result <= n;
      */
      while (result < n){
        result++;
      }
      return result;
    }
    ```
    Cependant, on ne peut toujours pas prouver la fonction car il manque une condition de terminaison. Pour la terminaison, il faut un variant. Frama-C ne peut donc pas prouver la fonction.
    ![while_not_proof](./images/TP2_exo1_2_while.png)

3. Code modifié avec le variant:
    ```c
    int identity_while(int n){
      int result = 0;
      /*@
        loop invariant result <= n;
        loop assigns result;
        loop variant n - result;
      */
      while (result < n){
        result++;
      }
      return result;
    }
    ```
    Maintenant, Frama-C peut prouver la fonction.
    ![while_proof](./images/TP2_exo1_3_while.png)
4. Code modifié avec l'invariant et le variant:
    ```c
    int identity_for(int n){
      int result = 0;
      /*@
        loop invariant 1 <= i <= n+1 && result == i-1;
        loop assigns result, i;
        loop variant n - i;
      */
      for (int i = 1; i <=n; i++){
        result++;
      }
      return result;
    }
    ```
    Maintenant, Frama-C peut prouver la fonction.
    ![for_proof](./images/TP2_exo1_4_for.png)



&nbsp;  
&nbsp;  
## Exercice 2