/*
  Q1 - Implémentez un template de fonction 'compose' permettant de construire
  la composition de deux fonctions arbitraires à un paramétre.

  Q2 - Implémentez un template de fonction 'set1st' permettant de construire
  à partir d'une fonction à deux paramétres, une fonction à seul parametres
  en figeant la valeur du premier parametre de la fonction initiale à 0.
  Ainsi set1st(f)(x)  est equivalent à f(0,x).

  Q3 - Implémentez un template de fonction 'set2nd' permettant de construire
  à partir d'une fonction à deux paramétres, une fonction à seul parametres
  en figeant la valeur du deuxieme parametre de la fonction initiale à 0.
  Ainsi set2nd(f)(x)  est equivalent à f(x,0).

  Q4 - Modifiez set1st et set2nd pour permettre de choisir la valeur du
  paramétre figé. Ainsi set1st(f, 8)(x) est equivalent à f(8,x)
*/

#include <iostream>

// Q1
template <typename F, typename G>
auto compose(F f, G g) {
    return [f, g](auto x) { return f(g(x)); };
}

// Q2 & Q4
template <typename F, typename T = int>
auto set1st(F f, T val = 0) {
    return [f, val](auto x) { return f(val, x); };
}

// Q3 & Q4
template <typename F, typename T = int>
auto set2nd(F f, T val = 0) {
    return [f, val](auto x) { return f(x, val); };
}

// Fonctions de test
auto double_  = [](int x)        { return x * 2; };
auto add_one  = [](int x)        { return x + 1; };
auto add      = [](int a, int b) { return a + b; };
auto multiply = [](int a, int b) { return a * b; };

int main(int, char **) {
    // Q1 : attendu 7 et 8
    std::cout << "=== Q1 : compose ===\n";
    std::cout << "double_then_add_one(3) = " << compose(add_one, double_)(3) << "  (attendu 7)\n";
    std::cout << "add_one_then_double(3) = " << compose(double_, add_one)(3) << "  (attendu 8)\n";

    // Q2 : attendu 5 et 0
    std::cout << "\n=== Q2 : set1st (val=0) ===\n";
    std::cout << "set1st(add)(5)      = " << set1st(add)(5)      << "  (attendu 5)\n";
    std::cout << "set1st(multiply)(5) = " << set1st(multiply)(5) << "  (attendu 0)\n";

    // Q3 : attendu 5 et 0
    std::cout << "\n=== Q3 : set2nd (val=0) ===\n";
    std::cout << "set2nd(add)(5)      = " << set2nd(add)(5)      << "  (attendu 5)\n";
    std::cout << "set2nd(multiply)(5) = " << set2nd(multiply)(5) << "  (attendu 0)\n";

    // Q4 : attendu 13, 15, 13, 15
    std::cout << "\n=== Q4 : set1st / set2nd avec valeur figée ===\n";
    std::cout << "set1st(add, 8)(5)      = " << set1st(add, 8)(5)      << "  (attendu 13)\n";
    std::cout << "set1st(multiply, 3)(5) = " << set1st(multiply, 3)(5) << "  (attendu 15)\n";
    std::cout << "set2nd(add, 8)(5)      = " << set2nd(add, 8)(5)      << "  (attendu 13)\n";
    std::cout << "set2nd(multiply, 3)(5) = " << set2nd(multiply, 3)(5) << "  (attendu 15)\n";

    return 0;
}