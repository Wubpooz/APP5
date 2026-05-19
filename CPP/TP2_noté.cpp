#include <iostream>
#include <algorithm>
#include <tuple>
#include <type_traits>

/*
  À la fin de la séance, envoyez le *Short link* de votre travail à l'adresse
  électronique qui vous a été donnée. Mettez en titre de votre email le nom de la séance,
  sous la forme :
       ET5 - C++ Avancé - Travaux Pratiques n°... - NOM Prénom

  Comme contenu du message électronique :
       NOM Prénom - https://godbolt.org/z/...
*/

/*
On définit une **Séquence de Type** comme un *template* variadique de classe
dont les paramètres *templates* encode le contenu d'une liste de types.

Ces séquences de types sont utilisées comme abstraction dans certaines 
opérations de méta-programmation.

Quelques ressources indispensables :
- https://en.cppreference.com/w/cpp/language/sizeof...
- https://en.cppreference.com/w/cpp/language/pack, section *pack expansion* 
- https://en.cppreference.com/w/cpp/language/fold

On définit ci-dessous une structure `type_list` qui encode une séquence
de type, et quelques instances globales pour les tests.

L'ensemble du TP consiste à définir des fonctions `constexpr` permettant de
manipuler des instances de `type_list`, en complétant les parties manquantes
marquées `---`.

A chaque fois, des tests sont fournis, qui sont exécutable à la compilation.
Il n'est pas nécessaire d'avoir une fonction main(), ni même de produire un
binaire exécutable pour savoir si le code est correct, puisque tout est
vérifié à la compilation par les `static_assert`.
*/

template<typename... Types>
struct type_list
{};

constexpr type_list<> null_tl;
constexpr type_list<int,float,char[19], double, char, void**> test_tl;

//==============================================================================
// "size" renvoie le nombre de types dans une instance de "type_list"
//==============================================================================

template<typename... Types>
constexpr auto size(type_list<Types...>)
{
  return sizeof...(Types); //(j'imagine ceux qui n'ont vu que du JS lire ça...)
}

static_assert( size(null_tl) == 0 );
static_assert( size(type_list<int>{}) == 1 );
static_assert( size(test_tl) == 6 );

//==============================================================================
// "operator==" renvoie true  si 2 type lists sont identiques
// "operator!=" renvoie false si 2 type lists sont identiques
//==============================================================================

template<typename... T1,typename... T2>
constexpr auto operator==(type_list<T1...>, type_list<T2...>)
{
  return std::is_same_v<type_list<T1...>, type_list<T2...>>; // is_same_v compare valeur par valeur, pas besoin de le refaire nous même, merci std
}

template<typename... T1,typename... T2>
constexpr auto operator!=(type_list<T1...>, type_list<T2...>)
{
  return !std::is_same_v<type_list<T1...>, type_list<T2...>>;
}

static_assert( test_tl == test_tl );
static_assert( test_tl != null_tl );

//==============================================================================
// "operator+" opérateur permettant de concaténer deux "type_list"
//==============================================================================

template<typename... T1, typename... T2>
constexpr auto operator+(type_list<T1...>, type_list<T2...>)
{ 
  return type_list<T1..., T2...>{};
}

static_assert( (null_tl + null_tl) == null_tl );
static_assert( (null_tl + test_tl) == test_tl );
static_assert( (test_tl + null_tl) == test_tl );
static_assert( (test_tl + test_tl) == 
               type_list< int,float,char[19], double, char, void**
                        , int,float,char[19], double, char, void**
                        >{}   
              );

//==============================================================================
// "largest" renvoie la valeur maximale de la taille en octet des types 
// d'une "type_list"
//==============================================================================

template<typename... T>
constexpr std::size_t largest(type_list<T...>) {
  if constexpr (sizeof...(T) == 0) { // sans constexpr, on aurait une erreur de compilation à cause de l'appel à std::max avec une liste vide
    return 0;
  } else {
    return std::max({sizeof(T)...});
  }
}

static_assert(largest(null_tl) == 0 );
static_assert(largest(type_list<double>{}) == 8 );
static_assert(largest(test_tl) == 19);

//==============================================================================
// "all_of" renvoie "true" indiquant si tous les types de la type_list sont
// identiques au type "T" passé en template
//==============================================================================

template<typename T, typename... U>
constexpr bool all_of(type_list<U...>) {
  return (std::is_same_v<T, U> && ...); // on applique le prédicat pour chaque élément
}

// https://en.cppreference.com/cpp/language/fold: 
// bool all(Args... args) { return (... && args); }
// bool b = all(true, true, true, false);
// // within all(), the unary left fold expands as
// //  return ((true && true) && true) && false;
// // b is false


static_assert(!all_of<int>(type_list<double>{}));
static_assert(!all_of<int>(test_tl));
static_assert( all_of<int>(null_tl));
static_assert( all_of<int>(type_list<int>{}));
static_assert( all_of<int>(type_list<int,int,int,int,int>{}));
static_assert(!all_of<int>(type_list<int,int,int,void,int>{}));

//==============================================================================
// "any_of" renvoie "true" si au moins un type "T" donné est présent dans 
// une instance de "type_list"
//==============================================================================

template<--->
--- any_of(---)
{
  ---
}

static_assert(!any_of<int>(type_list<double>{}));
static_assert(!any_of<int>(null_tl));
static_assert( any_of<int>(test_tl));
static_assert( any_of<int>(type_list<int>{}));
static_assert( any_of<int>(type_list<int,int,int,int,int>{}));
static_assert( any_of<int>(type_list<void,void,void,void,int>{}));

//==============================================================================
// "none_of" qui renvoie "true" si aucun type de la "type_list" ne correspond
// au type "T" donné
//==============================================================================

template<--->
--- none_of(---)
{
  ---
}

static_assert( none_of<int>(type_list<double>{}));
static_assert( none_of<int>(null_tl));
static_assert(!none_of<int>(test_tl));
static_assert(!none_of<int>(type_list<int>{}));
static_assert(!none_of<int>(type_list<int,int,int,int,int>{}));
static_assert(!none_of<int>(type_list<void,void,void,void,int>{}));

//==============================================================================
// "find" renvoie la première position (=l'index) d'un type "T" donné dans
// une "type_list". Si "T" n'est pas présent, -1 est renvoyée
//==============================================================================

---
--- std::ptrdiff_t find(---)
{
  ---
}

static_assert(find<int>(null_tl) == -1);
static_assert(find<int>(test_tl) == 0);
static_assert(find<float>(test_tl) == 1);
static_assert(find<char[19]>(test_tl) == 2);
static_assert(find<double>(test_tl) == 3);
static_assert(find<char>(test_tl) == 4);
static_assert(find<void**>(test_tl) == 5);
static_assert(find<void***>(test_tl) == -1);

//==============================================================================
// "largest_index" renvoie l'index du type avec le plus grand sizeof
//==============================================================================

template<--->
--- largest_index(---)
{
  ---
}

static_assert(largest_index(null_tl) == -1);
static_assert(largest_index(test_tl) ==  2);

//==============================================================================
// "unroll" renvoie une "type_list" constituée de toutes les combinaisons possibles
// entre une "type_list<T1>" et une "type_list<T2...>".
// "cartesian_product", en s'appuyant sur "unroll", prend deux "type_list" et en
// fait le produit cartésien.
//==============================================================================

template<--->
--- unroll(---)
{ 
  ---
}

template<--->
--- cartesian_product(---)
{ 
  ---
}

constexpr type_list<int[1],int[2],int[3]> i123; 
constexpr type_list<float[10],float[100],float[1000]> f123; 
constexpr type_list<
  type_list<int[1],float[10]>,type_list<int[1],float[100]>,type_list<int[1],float[1000]>,
  type_list<int[2],float[10]>,type_list<int[2],float[100]>,type_list<int[2],float[1000]>,
  type_list<int[3],float[10]>,type_list<int[3],float[100]>,type_list<int[3],float[1000]>
> cpif; 

static_assert( cartesian_product(i123,f123) == cpif);

//==============================================================================
// "to_tuple" convertit un "type_list" en "std::tuple"
//==============================================================================

template<--->
--- to_tuple(---)
{ 
  ---
}

static_assert( std::is_same_v<decltype(to_tuple(null_tl)), std::tuple<>> );
static_assert( std::is_same_v<decltype(to_tuple(test_tl))   , std::tuple<int,float,char[19],double,char,void**>> );

//==============================================================================
// La structure "reducer" fournit un opérateur % faisant la réduction
// d'une valeur de type U et Z avec une fonction de type F.
//
// Elle facilite lécriture de la fonction "reduce", qui applique une fonction
// de type F pour réduire tous les éléments d'une "type_list", initialisée
// à la valeur z valeur de type Z.
//==============================================================================

template<typename Z, typename F>
struct reducer
{
  ---

  Z acc;
  F f;
};

template<typename... T, typename F, typename Z>
constexpr auto reduce(type_list<T...>, F f, Z z)
{ 
  ---
}

static_assert
(
  reduce (
    test_tl,
    []<typename T>(auto acc, type_list<T>) {
      return acc + sizeof(T);
    },
    0ULL
  ) == 44
);

