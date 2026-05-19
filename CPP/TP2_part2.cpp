
#include <iostream>
#include <utility>
#include <array>
#include <cassert>

/*
Le Système international d'unités (abrégé en SI), inspiré du 
système métrique, est le système d'unités le plus largement 
employé au monde.

Le Système international comporte sept unités de base, 
destinées à mesurer des grandeurs physiques indépendantes
 et possédant chacune un symbole :

  - La masse, mesurée en kilogramme (kg).
  - Le temps, mesuré en second (s).
  - La longueur, mesuré en mètre (m).
  - La température, mesurée en kelvin (K).
  - L'intensité électrique, mesurée en ampère (A).
  - La quantité de matière, mesurée en mole (mol).
  - L'intensité lumineuse, mesurée en candela (cd). 

A partir de ces unités de bases, il est possible de construire 
des unités dérivées. Par exemple : 

  - La frequence, exprimée en s^-1
  - La vitesse, exprimée en m.s^-1
  - L'energie, exprimée en kg.m^2.s^−2 

Ces unités dérivées sont toutes des produits de 
puissance des sept unités de base.

On se propose d'implémenter un systeme permettant de calculer des
grandeurs avec des unités en utilisant le type des objets
pour empecher des erreurs comme "kg + m".

Ressources
- https://fr.wikipedia.org/wiki/Syst%C3%A8me_international_d%27unit%C3%A9s#Unit%C3%A9s_d%C3%A9riv%C3%A9es
*/

/*
  ETAPE 1 - STRUCTURE UNIT
  Ecrivez une structure `unit` qui prend en parametre template un type `T`
  et 7 entiers, chacune représentant la puissance d'une unité de base.
  Vous les ordonnerez de façon à suivre l'ordre de la liste donnée plus haut.

  Cette structure contient une valeur de type `T`.
*/
// template<typename T, int kg, int s, int m, int K, int A, int mol, int cd> struct unit {
//   T value;
//   unit(T v) : value(v) {} // if not explicit, like = default, it doesn't work properly
// };

/*
  ETAPE 2 - UNITES ET UNITES DERIVEES
  En utilisant le modele ci dessous, définissez des types
  representant les grandeurs demandées.
*/

// Masse : kg
// template<typename T>
// using mass = unit<T,1,0,0,0,0,0,0>;

// // Longeur : m
// template<typename T>
// using length = unit<T,0,0,1,0,0,0,0>;

// // Vitesse m.s-1
// template<typename T>
// using speed =  unit<T,0,-1,1,0,0,0,0>;

// // Force exprimée en Newton
// template<typename T>
// using newton = unit<T,1,-2,1,0,0,0,0>;

// // conductance électrique
// template<typename T>
// using siemens = unit<T,-1,3,-2,0,2,0,0>;

/*
  ETAPE 3 - OPERATIONS
  Ecrivez les operateurs +,-,* et / entre deux unités 
  du même type T mais avec des unités cohérentes.

  On peut multiplier ou diviser du temps par une masse mais
  on ne peut pas ajouter des Kelvin à des metres.
*/
// template<typename T, int kg, int s, int m, int K, int A, int mol, int cd>
// unit<T,kg,s,m,K,A,mol,cd> operator+(const unit<T,kg,s,m,K,A,mol,cd>& a, const unit<T,kg,s,m,K,A,mol,cd>& b) {
//   return unit<T,kg,s,m,K,A,mol,cd>(a.value + b.value);
// }

// template<typename T, int kg, int s, int m, int K, int A, int mol, int cd>
// unit<T,kg,s,m,K,A,mol,cd> operator-(const unit<T,kg,s,m,K,A,mol,cd>& a, const unit<T,kg,s,m,K,A,mol,cd>& b) {
//   return unit<T,kg,s,m,K,A,mol,cd>(a.value - b.value);
// }

// template<typename T, 
//     int kg_a, int s_a, int m_a, int K_a, int A_a, int mol_a, int cd_a,
//     int kg_b, int s_b, int m_b, int K_b, int A_b, int mol_b, int cd_b>
// unit<T, kg_a + kg_b, s_a + s_b, m_a + m_b, K_a + K_b, A_a + A_b, mol_a + mol_b, cd_a + cd_b> operator*(
//   const unit<T,kg_a,s_a,m_a,K_a,A_a,mol_a,cd_a>& a, const unit<T,kg_b,s_b,m_b,K_b,A_b,mol_b,cd_b>& b) {
//   return unit<T, kg_a + kg_b, s_a + s_b, m_a + m_b, K_a + K_b, A_a + A_b, mol_a + mol_b, cd_a + cd_b>(a.value * b.value);
// }

// template<typename T, 
//     int kg_a, int s_a, int m_a, int K_a, int A_a, int mol_a, int cd_a,
//     int kg_b, int s_b, int m_b, int K_b, int A_b, int mol_b, int cd_b>
// unit<T, kg_a - kg_b, s_a - s_b, m_a - m_b, K_a - K_b, A_a - A_b, mol_a - mol_b, cd_a - cd_b> operator/(
//   const unit<T,kg_a,s_a,m_a,K_a,A_a,mol_a,cd_a>& a, const unit<T,kg_b,s_b,m_b,K_b,A_b,mol_b,cd_b>& b) {
//   return unit<T, kg_a - kg_b, s_a - s_b, m_a - m_b, K_a - K_b, A_a - A_b, mol_a - mol_b, cd_a - cd_b>(a.value / b.value);
// }


/*
  ETAPE 4 - SIMPLIFICATION

  A partir de C++20, n'importe quelle structure constexpr peut servir
  de parametres template.

  Définissez une structure spec contenant un tableau de 7 entiers et les opérations et
  constructeurs que vous jugerez nécessaire et implémentez dans un deuxieme fichier la
  totalité des opérations et types précédent en partant du principe que unit devient

  template<typename T, spec D> struct unit;
*/
struct spec {
  std::array<int, 7> dimensions;

  constexpr spec(int kg, int s, int m, int K, int A, int mol, int cd) : dimensions{kg, s, m, K, A, mol, cd} {}

  constexpr spec operator+(const spec& S) const {
    return spec(dimensions[0] + S.dimensions[0], dimensions[1] + S.dimensions[1], dimensions[2] + S.dimensions[2], 
                dimensions[3] + S.dimensions[3], dimensions[4] + S.dimensions[4], dimensions[5] + S.dimensions[5], 
                dimensions[6] + S.dimensions[6]);
  }

  constexpr spec operator-(const spec& S) const {
    return spec(dimensions[0] - S.dimensions[0], dimensions[1] - S.dimensions[1], dimensions[2] - S.dimensions[2], 
                dimensions[3] - S.dimensions[3], dimensions[4] - S.dimensions[4], dimensions[5] - S.dimensions[5], 
                dimensions[6] - S.dimensions[6]);
  }

  constexpr bool operator==(const spec& S) const {
    return dimensions == S.dimensions;
  }
};


template<typename T, spec D> struct unit {
  T value;
  unit(T v) : value(v) {} // if not explicit, like = default, it doesn't work properly
};

template<typename T> using mass = unit<T,spec(1,0,0,0,0,0,0)>;
template<typename T> using length = unit<T,spec(0,0,1,0,0,0,0)>;
template<typename T> using speed =  unit<T,spec(0,-1,1,0,0,0,0)>;
template<typename T> using newton = unit<T,spec(1,-2,1,0,0,0,0)>;
template<typename T> using siemens = unit<T,spec(-1,3,-2,0,2,0,0)>;


template<typename T, spec D>
unit<T,D> operator+(const unit<T,D>& a, const unit<T,D>& b) {
  return unit<T,D>(a.value + b.value);
};

template<typename T, spec D>
unit<T,D> operator-(const unit<T,D>& a, const unit<T,D>& b) {
  return unit<T,D>(a.value - b.value);
};

template<typename T, spec D1, spec D2>
unit<T, D1 + D2> operator*(
  const unit<T,D1>& a, const unit<T,D2>& b) {
  return unit<T, D1 + D2>(a.value * b.value);
};

template<typename T, spec D1, spec D2>
unit<T, D1 - D2> operator/(
  const unit<T,D1>& a, const unit<T,D2>& b) {
  return unit<T, D1 - D2>(a.value / b.value);
};

// new multiply by a constant
template<typename T, spec D>
unit<T,D> operator*(const unit<T,D>& a, T scalar) {
  return unit<T,D>(a.value * scalar);
}

template<typename T, spec D>
unit<T,D> operator*(T scalar, const unit<T,D>& a) {
  return unit<T,D>(scalar * a.value);
}

template<typename T, spec D>
unit<T,D> operator/(const unit<T,D>& a, T scalar) {
  return unit<T,D>(a.value / scalar);
}

template<typename T, spec D>
unit<T,D> operator/(T scalar, const unit<T,D>& a) {
  return unit<T,D>(scalar / a.value);
}

// equality operator
template<typename T, spec D>
bool operator==(const unit<T,D>& a, const unit<T,D>& b) {
  if constexpr (std::is_floating_point_v<T>) {
    return std::abs(a.value - b.value) < 1e-9;
  } else {
    return a.value == b.value;
  }
}

/*
  ETAPE 5 - CONSTANTES
  Ajouter ce test dans `main` :
    si::length l = 50.*KM ;
    si::time t1 = 10.*Mi, t2 = 20.*Mi ;
    si::speed s = l/(t1+t2) ;
    assert(s==(100.*KM/H));

  Compléter votre code pour que ce test passe.
*/

// Constants
const unit<double, spec(0,0,1,0,0,0,0)> KM(1000.0);
const unit<double, spec(0,1,0,0,0,0,0)> Mi(60.0);
const unit<double, spec(0,1,0,0,0,0,0)> H(3600.0);

namespace si {
  using length = unit<double, spec(0,0,1,0,0,0,0)>;
  using time = unit<double, spec(0,1,0,0,0,0,0)>;
  using speed = unit<double, spec(0,-1,1,0,0,0,0)>;
};

int main()
{
  mass<double> m1(5.0);
  mass<double> m2(3.0);

  auto m3 = m1 + m2;
  std::cout << "Mass: " << m3.value << " kg\n";


  si::length l = 50.*KM ;
  si::time t1 = 10.*Mi, t2 = 20.*Mi ;
  si::speed s = l/(t1+t2) ;
  assert(s==(100.*KM/H));
}
