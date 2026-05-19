#include <iostream>
#include <utility>
#include <array>


/*
Le Système international d'unités (abrégé en SI), inspiré du 
système métrique, est le système d'unités le plus largement 
employé au monde.

Le Système international comporte sept unités de base, 
destinées à mesurer des grandeurs physiques indépendantes
 et possédant chacune un symbole :

  + La masse, mesurée en kilogramme (kg).
  + Le temps, mesuré en second (s).
  + La longueur, mesuré en mètre (m).
  + La température, mesurée en kelvin (K).
  + L'intensité électrique, mesurée en ampère (A).
  + La quantité de matière, mesurée en mole   (mol).
  + L'intensité lumineuse, mesurée en candela  (cd). 

A partir de ces unités de bases, il est possible de construire 
des unités dérivées. Par exemple : 

  + La frequence, exprimée en s^-1
  + La vitesse, exprimée en m.s^-1
  + L'energie, exprimée en kg.m^2.s^−2 

On remarque que ses unités dérivées sont toutes des produits de 
puissance d'unité de base.

On se propose d'implémenter un systeme permettant de calculer des
grandeurs avec des unités en utilisant le type des objets unités
pour empecher des erreurs comme kg + m.
*/

/*
  ETAPE 1 - STRUCTURE UNIT

  Ecrivez une structure unit qui prend en parametre template un type T
  et 7 entiers, chacune représentant une unité de base. Vous les
  ordonnerez de façon à suivre l'ordre de la liste donnée plus haut.

  Cette structure contient une valeur de type T.
*/
template<typename T, int kg, int s, int m, int K, int A, int mol, int cd>
struct unit
{
  T value;
  explicit unit(T v) : value(v) {}
};

/*
  ETAPE 2 - UNITES ET UNITES DERIVEES
  En utilisant le modele ci dessous, définissez des types
  representant les grandeurs demandées.

  Indice : https://fr.wikipedia.org/wiki/Syst%C3%A8me_international_d%27unit%C3%A9s#Unit%C3%A9s_d%C3%A9riv%C3%A9es
*/

// Masse : kg
template<typename T>
using mass = unit<T,1,0,0,0,0,0,0>;

// Temps : s
template<typename T>
using time = unit<T,0,1,0,0,0,0,0>;

// Longeur : m
template<typename T>
using length = unit<T,0,0,1,0,0,0,0>;

// Vitesse m.s-1
template<typename T>
using speed = unit<T,0,-1,1,0,0,0,0>;

// Force exprimée en Newton
template<typename T>
using newton = unit<T,1,-2,1,0,0,0,0>;

// conductance électrique
template<typename T>
using siemens = unit<T,-1,3,-2,0,2,0,0>;

/*
  ETAPE 3 - OPERATIONS

  Ecrivez les operateurs +,-,* et / entre deux unités 
  du même type mais avec des unités cohérentes.

  On peut multipliez ou divisé du temps par une masse mais
  on ne peut pas ajouter des Kelvin à des metres.
*/
template<typename T, int kg, int s, int m, int K, int A, int mol, int cd>
unit<T,kg,s,m,K,A,mol,cd> operator+(
 const unit<T,kg,s,m,K,A,mol,cd>& a, const unit<T,kg,s,m,K,A,mol,cd>& b)
{
  return unit<T,kg,s,m,K,A,mol,cd>{a.value + b.value};
}

template<typename T, int kg, int s, int m, int K, int A, int mol, int cd>
unit<T,kg,s,m,K,A,mol,cd> operator-(
 const unit<T,kg,s,m,K,A,mol,cd>& a, const unit<T,kg,s,m,K,A,mol,cd>& b)
{
  return unit<T,kg,s,m,K,A,mol,cd>{a.value - b.value};
}

template<typename T, int kg, int s, int m, int K, int A, int mol, int cd, int kg2, int s2, int m2, int K2, int A2, int mol2, int cd2>
unit<T,kg+kg2,s+s2,m+m2,K+K2,A+A2,mol+mol2,cd+cd2> operator*(
 const unit<T,kg,s,m,K,A,mol,cd>& a, const unit<T,kg2,s2,m2,K2,A2,mol2,cd2>& b)
{
  return unit<T,kg+kg2,s+s2,m+m2,K+K2,A+A2,mol+mol2,cd+cd2>{a.value * b.value};
}

template<typename T, int kg, int s, int m, int K, int A, int mol, int cd, int kg2, int s2, int m2, int K2, int A2, int mol2, int cd2>
unit<T,kg-kg2,s-s2,m-m2,K-K2,A-A2,mol-mol2,cd-cd2> operator/(
 const unit<T,kg,s,m,K,A,mol,cd>& a, const unit<T,kg2,s2,m2,K2,A2,mol2,cd2>& b)
{
  return unit<T,kg-kg2,s-s2,m-m2,K-K2,A-A2,mol-mol2,cd-cd2>{a.value / b.value};
}

/*
  ETAPE 4 - SIMPLIFICATION
  A partir de C++20, n'importequelle structure constexpr peut servir
  de parametres template.

  Définissez une structure spec contenant un tableau de 7 entiers et les opérations et
  constrcuteurs que vous jugerez nécessaire et implémentez dans un deuxieme fichier la
  totalité des opérations et types précédent en partant du principe que unit devient

  template<typename T, spec D> struct unit;
*/
struct spec {
    std::array<int, 7> dims;  // {kg, s, m, K, A, mol, cd}

    constexpr spec(int kg_, int s_, int m_, int K_, int A_, int mol_, int cd_) 
        : dims{kg_, s_, m_, K_, A_, mol_, cd_} {}

    constexpr spec operator+(const spec& other) const {
        return spec(
            dims[0] + other.dims[0],
            dims[1] + other.dims[1],
            dims[2] + other.dims[2],
            dims[3] + other.dims[3],
            dims[4] + other.dims[4],
            dims[5] + other.dims[5],
            dims[6] + other.dims[6]
        );
    }

    constexpr spec operator-(const spec& other) const {
        return spec(
            dims[0] - other.dims[0],
            dims[1] - other.dims[1],
            dims[2] - other.dims[2],
            dims[3] - other.dims[3],
            dims[4] - other.dims[4],
            dims[5] - other.dims[5],
            dims[6] - other.dims[6]
        );
    }

    // Opérateur d'égalité pour comparer les unités
    constexpr bool operator==(const spec& other) const = default;
};
  


int main()
{
  // POUR CHAQUE ETAPE, ECRIVEZ LES TESTS QUE VOUS JUGEREZ SUFFISANT

  mass<double> m1(5.0);
  mass<double> m2(3.0);
  auto m3 = m1 + m2;
  std::cout << "Mass: " << m3.value << " kg\n";
}