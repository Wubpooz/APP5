//
// ====================================================================================================
// Introduction
// ====================================================================================================
//
// L’objectif de ce TP est de définir une classe proposant des fonctionnalités proches de `std::array<T,N>`
// (la version C++ d’un tableau C de type `T[N]`). L’implantation sera cependant un peu plus subtile dans
// le cas où le tableau est grand pour éviter qu’il ne fasse déborder la pile et pour éviter que certaines
// opérations comme `move` ou `swap` soient trop coûteuses.
// 
// Les trois classes template définies ci-dessous auront une signature du type :
//      template< typename T, std::size_t N >
//      class my_new_array {
//      ...
//      };
//
// ====================================================================================================
// Partie 1 : petits tableaux
// ====================================================================================================
// 
// Définissez une classe template `small_array<T,N>` contenant un champ privé ayant le type `T[N]`. Ajoutez
// les versions par défaut de toutes les méthodes spéciales: constructeur par défaut, constructeur par copie,
// constructeur par transfert, affectation par copie, affectation par transfert, destructeur.
// 
// Ajoutez deux opérateurs à la classe permettant d’accéder aux éléments comme si c’était un simple
// tableau :
//      T & operator[]( std::size_t i );
//      T const & operator[]( std::size_t i ) const ;
// 
// Question : pourquoi faut-il définir deux opérateurs crochets quasiment identiques ? (Voir le code de test
// ci-dessous pour un indice.)
//
//      Il en faut un pour l'accès aux éléments pour un tableau non-const et un pour const. L'un pouvant être modifié et l'autre non.
// 
// Ajoutez à ces opérateurs des assertions pour empêcher le programme de continuer son exécution en cas
// d’accès hors des bornes du tableau.
// 
// Question : est-il possible de marquer ces opérateurs comme étant noexcept ?
// 
//     Oui car les asserts sont trigger à l'exécution mais font in abort() et et non une exception
// 
// Testez votre classe en utilisant le `main()` initial.
// 
// Question : est-ce que votre code affiche des valeurs surprenantes pour les cases autres que la deuxième ?
// Si oui, c’est normal (et sinon, c’est un coup de chance). Pourquoi ?
// 
//      Le programme affiche des valeurs aléatoires pour les autres cases car elles ne sont pas initalisées. D'ailleurs c'est la même valeur pour toutes. 
//      PS: après test avec .at(), je remarque que les valeurs par défaut sont différentes entres [] et .at(). C'est probablement d^à des optimisations
//      du compilateur qui changent entre les 2, vu qu'il voit que ce sont des valeurs non initalisées et que le comportement est donc indéfini.
// 
// Ajoutez deux méthodes qui se comportent comme les opérateurs crochets, mais qui lèvent cette fois des
// exceptions quand les accès ont lieu hors des bornes :
// 
//      T & at( std::size_t i );
//      T const & at( std::size_t i ) const ;
// 
// Testez vos nouvelles méthodes en modifiant le code de `main()`.
//
// ====================================================================================================
// Partie 2 : grands tableaux
// ====================================================================================================
// 
// Testez votre classe avec le code suivant :
// 
//      int main() {
//        small_array< int , 1000 * 1000 * 10 > t ;
//        t[2] = 42;
//      }
// 
// Question : pourquoi le programme plante-t-il ?
// 
//      Le tableau de 10 millions d'int est alloué sur le stack, or le stack est petit (env. 8Mo) vs 10^7 * 4 octets = 40Mo pour le tableau.
//      On a donc un stack overflow.
// 
// Définissez une classe template `large_array<T,N>` dont le champ privé a maintenant le type suivant :
// `std::unique_ptr<small_array<T , N>>`.
// 
// Ajoutez des opérateurs crochets et des méthodes at permettant d’accéder aux éléments du tableau.
// 
// Question : pourquoi le constructeur par défaut fourni par le compilateur ne convient-il pas ?
//      Parce que le unique_ptr ne serait pas initialisé, il resterait nullptr ou en état indéfini.
//      Il faut un constructeur explicite qui initialise: data(std::make_unique<small_array<T, N>>())
// 
// Définissez un constructeur par défaut et testez votre classe avec le code suivant :
//   
//      int main() {
//        large_array<int , 1000 * 1000 * 10> t ;
//        t[2] = 42;
//      }
// 
// Les versions du constructeur par copie et de l’opérateur d’affectation par copie fournies par le compilateur
// ne conviennent pas non plus. Définissez des versions adaptées à `large_array`.
// 
// Complétez votre code de test en vous inspirant de celui utilisé pour les petits tableaux afin de vérifier
// que votre constructeur par copie fonctionne correctement.
// 
// Fournissez une méthode `swap` qui échange le contenu de deux tableaux larges en temps constant :
// 
//      void large_array<T, N>::swap( large_array & );
// 
// Proposez une variante de l’opérateur d’affectation par copie qui fournisse une garantie plus forte concernant
// les exceptions : si une exception est levée lors de la copie, le tableau original est rendu inchangé
// plutôt qu’à moitié modifié. (Note : cette garantie n’est pas fournie par small_array.)
// 
// Question : quel est l’inconvénient de cette variante ?
//      Elle crée une copie temporaire du tableau entier avant d'échanger, ce qui coûte en mémoire et performance.
//      Le résultat est peu visible sur un petit tableau mais l'est beaucoup sur un grand.
// 
// Une fonction template incorrecte n’est généralement pas détectée par le compilateur tant qu’elle n’est
// pas utilisée par du code non-template. Modifiez le code de test afin que l’opérateur d’affectation par
// copie soit lui-aussi utilisé, de même pour la méthode swap.
// 
// ====================================================================================================
// Partie 3 : tableaux malins
// ====================================================================================================
// 
// Définissez un type template qui se résout vers `small_array<T,N>` s’il est suffisamment petit (inférieur à
// 16 octets par exemple) et vers `large_array<T,N>` sinon.
// 
// Testez votre type avec le code suivant en faisant varier la taille passée en paramètre. On pourra ajouter
// une assertion dans le constructeur de `large_array` pour s’assurer qu’il n’est pas appelé avec un petit `N`.
// 
//      int main() {
//        my_array<int, 1000 * 1000 * 10> t;
//        t[2] = 42;
//      }
// 

#include <iostream>
#include <cassert>
#include <memory>
#include <stdexcept>
#include <type_traits>
#include <typeinfo>

template<typename T, std::size_t N> class small_array {
  private:
    T data[N]{};
  
  public:
    small_array() = default;
    small_array(small_array const &) = default;
    small_array(small_array &&) = default;
    ~small_array() = default;
    small_array &operator=(small_array const &) = default;
    small_array &operator=(small_array &&) = default;
    T &operator[](std::size_t i) noexcept {
      assert(i < N); // i can be negative if we follow the std::array implementation since it's gonna wrap around to a large positive (return "std::out_of_range if pos >= size()", https://cppreference.com/cpp/container/array/at)
      return data[i];
    }
    T const &operator[](std::size_t i) const noexcept {
      assert(i < N); // i can be negative if we follow the std::array implementation since it's gonna wrap around to a large positive (return "std::out_of_range if pos >= size()", https://cppreference.com/cpp/container/array/at)
      return data[i];
    }
    T &at(std::size_t i) {
      if (i >= N) // i can be negative if we follow the std::array implementation since it's gonna wrap around to a large positive (return "std::out_of_range if pos >= size()", https://cppreference.com/cpp/container/array/at)
        throw std::out_of_range("out-of-bound access");
      return data[i];
    }
    T const &at(std::size_t i) const {
      if (i >= N)  // i can be negative if we follow the std::array implementation since it's gonna wrap around to a large positive (return "std::out_of_range if pos >= size()", https://cppreference.com/cpp/container/array/at)
        throw std::out_of_range("out-of-bound access");
      return data[i];
    }
};


template<typename T, std::size_t N> class large_array {
  private:
    std::unique_ptr<small_array<T, N>> data;
  public:
    large_array() : data(std::make_unique<small_array<T, N>>()) {
      static_assert(sizeof(small_array<T,N>) > 64, "large_array should only be used for arrays larger than 16 bytes");
    }
    large_array(const large_array& t) {
      // if issue during copy, no change
      std::unique_ptr<small_array<T, N>> tmp = std::make_unique<small_array<T, N>>(*t.data);
      data = std::move(tmp);
    } 
    large_array(large_array&& t) {
        data = std::move(t.data);
    }
    ~large_array() noexcept = default;

    large_array &operator=(large_array const &t) {
      large_array u = t; // extra allocation but garantes that we don't have weird data if interupted
      data.swap(u.data);
      return *this;
    }
    large_array &operator=(large_array &&) noexcept = default;

    T &operator[](std::size_t i) noexcept {
      assert(i < N);
      return (*data)[i];
    }
    T const &operator[](std::size_t i) const noexcept {
      assert(i < N);
      return (*data)[i];
    }

    T &at(std::size_t i) {
      if (i >= N)
        throw std::out_of_range("out-of-bound access");
      return (*data)[i];
    }
    T const &at(std::size_t i) const {
      if (i >= N)
        throw std::out_of_range("out-of-bound access");
      return (*data)[i];
    }

    void swap(large_array &t) {
      data.swap(t.data);
    }
};

template <typename T, std::size_t N>
using my_array = std::conditional_t<(sizeof(small_array<T,N>) <= 64), small_array<T, N>, large_array<T, N>>;


int main () {
  // 1. Test de small_array
  small_array<int, 4> t;
  t[2] = 42;
  small_array<int, 4> const u = t ;

  for ( std::size_t i = 0; i < 4; ++i ) {
    std::cout << "t[ " << i << " ] = " << u[i] << "\n";
  }
  // t[4] = 0; // assertion failed !
  
  // 2. Test de .at()
  for ( std::size_t i = 0; i < 4; ++i ) {
    std::cout << "t at " << i << " = " << u.at(i) << "\n";
  }
  // t.at(4) = 0; // exception thrown
  
  
  // 3. Test de small_array LARGE
  // small_array< int , 1000 * 1000 * 10 > t ;
  // t[2] = 42;
  
  // 4. Test de large_array
  large_array<int , 1000 * 1000 * 10> Lt;
  Lt[0] = 23;
  Lt[1] = 47;
  Lt[2] = 106;
  Lt[3] = 235;
  Lt[4] = 551;
  Lt[42] = 4;
  
  large_array<int, 1000 * 1000 * 10> const Lt2 = Lt;
  std::cout << "Lt2[42] = " << Lt2[42] << '\n';
  large_array<int, 1000 * 1000 * 10> Lt3;
  Lt3[42] = 24;
  Lt.swap(Lt3);
  std::cout << "Post swap, Lt[42] = " << Lt[42] << '\n';
  std::cout << "Post swap, Lt[42] = " << Lt3[42] << '\n';
  
  for ( std::size_t i = 0; i < 5; ++i ) {
    std::cout << "Lt3[ " << i << " ] = " << Lt3[i] << "\n";
    std::cout << "Lt3 at " << i << " = " << Lt3.at(i) << "\n";
  }
  // t[1000 * 1000 * 10] = 3; // assert fail
  // t.at(1000 * 1000 * 10) = 3; // exception thrown



  // 5. Dynamic array
  my_array<int, 1000 * 1000 * 10> dynT1;
  dynT1[2] = 42;
  std::cout << "dynT1 type = " << typeid(dynT1).name() << '\n';
  
  my_array<int, 8> dynT2;
  dynT2[2] = 42;
  std::cout << "dynT2 type = " << typeid(dynT2).name() << '\n';
  
  my_array<int, 16> dynT3;
  dynT3[2] = 42;
  std::cout << "dynT3 type = " << typeid(dynT3).name() << '\n';

  // large_array<int, 8> small_large_arr; // static assert
  }
