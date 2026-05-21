#include <iostream>
#include <cmath>
#include <tuple>
#include <algorithm>
#include <cassert>
#include <vector>

/*
  À la fin de la séance, envoyez le *Short link* de votre travail à l'adresse
  électronique qui vous a été donnée. Mettez en titre de votre email le nom de la séance,
  sous la forme :  
       ET5 - C++ Avancé - Travaux Pratiques n°... - NOM Prénom

  Comme contenu du message électronique :
       - [NOM Prénom ](https://godbolt.org/z/...)
*/

/*
  Le but de ce TP est de mettre en place un petit système d'EXPRESSION TEMPLATES.

  Les EXPRESSION TEMPLATES sont une technique d'optimisation de calcul numérique qui
  utilisent la méta-programmation pour construire une représentation légère d'une formule
  arbitraire sous la forme d'un ARBRE DE SYNTAXE ABSTRAITE.

  Une fois construit à la compilation, cet arbre devient exploitable à la compilation 
  ou à l'exécution pour effectuer des calculs de divers types. 

  Répondez aux questions dans l'ordre en complétant le code.
*/


namespace et {
  //---------------------------------------------------------------------------------------
  // Q1 - Définissez un concept expr qui est valide si un type T fournit un membre T::is_expr()
  template<typename T> concept expr = requires(T) {
    T::is_expr();
  };

  //---------------------------------------------------------------------------------------
  /*
    Le premier élément fondamental d'un systeme d'EXPRESSION TEMPLATE est la classe
    `terminal`. Un TERMINAL représente une feuille de l'ARBRE DE SYNTAXE. Dans notre cas,
    nos terminaux sont numérotés statiquement pour représenter différentes variables.

    Q2. Complétez l'implémentation de la structure template `terminal` ci-dessous en suivant les demandes
  */
  //---------------------------------------------------------------------------------------
  template<int ID> struct terminal {
    // Faite en sorte que terminal vérifie le concept expr
    static constexpr void is_expr() {} //TODO remplir? autre type?

    std::ostream & print(std::ostream & os) const {
      // Pour terminal<I>, affiche "arg<I>" et renvoit os.
      os << "arg<" << ID << ">";
      return os;
    }

    template<typename... Args>
    constexpr auto operator()(Args &&... args) const {
      // Construit un tuple de tout les args et renvoit le ID-eme via std::get
      // Veillez à bien respecter le fait que args est une reference universelle => std::forward comme au TP précédent
      auto arguments = std::tuple<Args&&...>(std::forward<Args>(args)...);
      return std::get<ID>(arguments);
      // I also found https://en.cppreference.com/cpp/utility/tuple/forward_as_tuple ce qui permet de faire:
      // return std::get<ID>(std::forward_as_tuple(std::forward<Args>(args)...));
    }
  };


  // Generateur de variable numérotée - arg<ID> est un terminal<ID>
  template<int ID> inline constexpr auto arg = terminal<ID>{};

  // Définissez les variables _0, _1 et _2 avec l'ID correspondant
  inline constexpr auto _0  = arg<0>;
  inline constexpr auto _1  = arg<1>;
  inline constexpr auto _2  = arg<2>;

  //---------------------------------------------------------------------------------------
  /*
    Le deuxieme élément  d'un systeme d'EXPRESSION TEMPLATE est la classe de noeud. 
    Un NODE représente un opérateur ou une fonction dans l'ARBRE DE SYNTAXE. 

    Il est défini par le type de l'OPERATION effectuée au passage du noeud et d'une
    liste variadique de ses sous-nodes.

    Q3 Complétez l'implémentation de la structure template node ci dessous en suivant les demandes
  */
  //---------------------------------------------------------------------------------------
  template<typename Op, typename... Children> struct node {
    // Faite en sorte que node vérifie le concept expr
    static constexpr void is_expr() {} //TODO remplir? autre type?

    // Construisez un node à partir d'une instande de Op et d'une liste variadique de Children
    // Ce constructeur sera constexpr
    constexpr node(Op o, Children... ch) : op(o), children(ch...) {}

    // L'operateur() de node permet d'avaluer le sous-arbre courant de manière 
    // récursive. Les paramètres args... représentent dans l'ordre les valeurs des
    // variables contenus dans le sous arbre.
    // Par exemple, le node {op_add, terminal<1>, termnal<0>} appelant operator()(4, 9)
    // doit renvoyer op_add(9, 4);
    template<typename... Args>
    constexpr auto operator()(Args&&... args) const {
      return std::apply([&](const auto&... child) {
        return op(child(std::forward<Args>(args)...)...); // évaluation sur chaque children récursivement (chaque children s'apply)
      }, children);
    }

    // Affiche un node en demandant à Op d'afficher les sous arbres
    std::ostream& print(std::ostream& os) const {
      std::apply([&](const auto&... child) { // std::apply fait le for_each_member du TP précédent
        op.print(os, child...); // le fait de demander à op de le faire ça évite les galères ou de devoir se concenter de l'écriture polonaise
      }, children);
      return os;
    }
    
    private:
      // Svp la prochaine fois mettez ça au début de la struct, c'est perturbant ici
      Op op;
      std::tuple<Children...> children;
  };

  /*
  Q4. Implémentez les Op et les operateurs associés
    - add_ et un operator+ pour l'addition
    - sub_ et un operator- pour la soustraction
    - mul_ et un operator* pour la multiplication
    - div_ et un operator/ pour la division
    - abs_ et une fonction abs pour le calcul de la valeur absolue
    - fma_ et une fonction fma(a,b,c) qui calcul a*b+c
  */

  // Pour être compatible avec node, on doit définir des structs "leaf" qui implémentent () et print
  struct add_ {
    constexpr auto operator()(auto&& a, auto&& b) const { 
      if constexpr (std::is_arithmetic_v<std::decay_t<decltype(a)>>) { // cas scalaire
        return a + b;
      } else { // cas std::vector
        std::decay_t<decltype(a)> res(a.size());
        for(size_t i = 0; i < a.size(); i++) {
          res[i] = (*this)(a[i], b[i]); // Appel récursif élément par élément
        }
        return res;
      }
    }

    void print(std::ostream& os, const auto& a, const auto& b) const {
      os << "(";
      a.print(os);
      os << " + ";
      b.print(os);
      os << ")";
    }
  };

  struct sub_ {
    constexpr auto operator()(auto&& a, auto&& b) const { 
      if constexpr (std::is_arithmetic_v<std::decay_t<decltype(a)>>) { // cas scalaire
        return a - b;
      } else { // cas std::vector
        std::decay_t<decltype(a)> res(a.size());
        for(size_t i = 0; i < a.size(); i++) {
          res[i] = (*this)(a[i], b[i]); // Appel récursif élément par élément
        }
        return res;
      }
    }


    void print(std::ostream& os, const auto& a, const auto& b) const {
      os << "(";
      a.print(os);
      os << " - ";
      b.print(os);
      os << ")";
    }
  };

  struct mul_ {
    constexpr auto operator()(auto&& a, auto&& b) const { 
      if constexpr (std::is_arithmetic_v<std::decay_t<decltype(a)>>) { // cas scalaire
        return a * b;
      } else { // cas std::vector
        std::decay_t<decltype(a)> res(a.size());
        for(size_t i = 0; i < a.size(); i++) {
          res[i] = (*this)(a[i], b[i]); // Appel récursif élément par élément
        }
        return res;
      }
    }

    void print(std::ostream& os, const auto& a, const auto& b) const {
      os << "(";
      a.print(os);
      os << " * ";
      b.print(os);
      os << ")";
    }
  };

  struct div_ {
    constexpr auto operator()(auto&& a, auto&& b) const {
      if constexpr (std::is_arithmetic_v<std::decay_t<decltype(a)>>) { // cas normal
        if (b == 0) {
          throw std::runtime_error("Division par zero !");  // bonus pour éviter les sigterm 
        }
        return a / b;
      } else { // std::vector
        std::decay_t<decltype(a)> res(a.size());
        for(size_t i = 0; i < a.size(); i++) {
          res[i] = (*this)(a[i], b[i]); // Appel récursif sur chaque élément
        }
        return res;
      }
    }

    void print(std::ostream& os, const auto& a, const auto& b) const {
      os << "(";
      a.print(os);
      os << " / ";
      b.print(os);
      os << ")";
    }
  };

  struct abs_ {
    constexpr auto operator()(auto&& a) const { 
      //Attention, abs n'est pas constexpr avant C++ 23 (pour des raisons obscures apparement, c.f. https://stackoverflow.com/questions/27708629/why-isnt-abs-constexpr)
      // return std::abs(a); => pas constexpr

      if constexpr (std::is_arithmetic_v<std::decay_t<decltype(a)>>) { // cas normal
        return a > 0 ? a : -a;
      } else { // std::vector
        std::decay_t<decltype(a)> res(a.size());
        for(size_t i = 0; i < a.size(); i++) {
          res[i] = (*this)(a[i]); // Appel récursif sur l'élément
        }
        return res;
      }
    }

    void print(std::ostream& os, const auto& a) const {
      os << "| ";
      a.print(os);
      os << " |";
    }
  };

  struct fma_ {
    constexpr auto operator()(auto&& a, auto&& b, auto&& c) const { 
      if constexpr (std::is_arithmetic_v<std::decay_t<decltype(a)>>) { // cas scalaire
        return a * b + c;
      } else { // cas std::vector
        std::decay_t<decltype(a)> res(a.size());
        for(size_t i = 0; i < a.size(); i++) {
          res[i] = (*this)(a[i], b[i], c[i]); // Appel récursif élément par élément
        }
        return res;
      }
    }
    void print(std::ostream& os, const auto& a, const auto& b, const auto& c) const {
      os << "(";
      a.print(os);
      os << " * ";
      b.print(os);
      os << " + ";
      c.print(os);
      os << ")";
    }
  };

  template<expr E> constexpr auto abs(E e) { return node{abs_{}, e}; } // constexpr requise pour pouvoir faire et::abs
  template<expr A, expr B, expr C> constexpr auto fma(A a, B b, C c) { return node{fma_{}, a, b, c}; } // pareil


  template<expr L, expr R>
  constexpr auto operator+(L a, R b) {
    return node{add_{}, a, b}; // {} est nécessaire pour utiliser la struct
  }

  template<expr L, expr R>
  constexpr auto operator-(L a, R b) {
    return node{sub_{}, a, b};
  }

  template<expr L, expr R>
  constexpr auto operator*(L a, R b) {
    return node{mul_{}, a, b};
  }

  template<expr L, expr R>
  constexpr auto operator/(L a, R b) {
    return node{div_{}, a, b};
  }
}


// Operateurs nécessaire pour la partie vecteurs
template<typename T> std::vector<T> operator+(const std::vector<T>& a, const std::vector<T>& b) {
  std::vector<T> res(a.size());
  for(size_t i = 0; i < a.size(); i++) {
    res[i] = a[i] + b[i];
  }
  return res;
}

template<typename T> std::vector<T> operator-(const std::vector<T>& a, const std::vector<T>& b) {
  std::vector<T> res(a.size());
  for(size_t i = 0; i < a.size(); i++) {
    res[i] = a[i] - b[i];
  }
  return res;
}

template<typename T> std::vector<T> operator*(const std::vector<T>& a, const std::vector<T>& b) {
  std::vector<T> res(a.size());
  for(size_t i = 0; i < a.size(); i++) {
    res[i] = a[i] * b[i];
  }
  return res;
}

template<typename T> std::vector<T> operator/(const std::vector<T>& a, const std::vector<T>& b) {
  std::vector<T> res(a.size());
  for(size_t i = 0; i < a.size(); i++) {
    res[i] = a[i] / b[i];
  }
  return res;
}

template<typename T> std::vector<T> abs(const std::vector<T>& v) {
  std::vector<T> res(v.size());
  for(size_t i = 0; i < v.size(); i++) { 
    res[i] = et::abs_{}(v[i]); // utilisation de notre abs pour que ce soit constexpr
  }
  return res;
}





// Code pour la Q7
// template<typename T>
// struct literal {
//   static constexpr void is_expr() {}
//   T value;
//   std::ostream& print(std::ostream& os) const { return os << value; }
  
//   template<typename... Args>
//   constexpr T operator()(Args&&...) const { return value; }
// };

// template<typename T>
// constexpr auto as_expr(T&& val) {
//   if constexpr (et::expr<std::decay_t<T>>) {
//     return std::forward<T>(val);
//   } else {
//     return literal<std::decay_t<T>>{std::forward<T>(val)};
//   }
// }

// template<typename L, typename R> requires (et::expr<L> || et::expr<R>)
// constexpr auto operator+(L&& l, R&& r) {
//   return et::node{et::add_{}, as_expr(std::forward<L>(l)), as_expr(std::forward<R>(r))};
// }
// template<typename L, typename R> requires (et::expr<L> || et::expr<R>)
// constexpr auto operator-(L&& l, R&& r) {
//   return et::node{et::sub_{}, as_expr(std::forward<L>(l)), as_expr(std::forward<R>(r))};
// }
// template<typename L, typename R> requires (et::expr<L> || et::expr<R>)
// constexpr auto operator*(L&& l, R&& r) {
//   return et::node{et::mul_{}, as_expr(std::forward<L>(l)), as_expr(std::forward<R>(r))};
// }
// template<typename L, typename R> requires (et::expr<L> || et::expr<R>)
// constexpr auto operator/(L&& l, R&& r) {
//   return et::node{et::div_{}, as_expr(std::forward<L>(l)), as_expr(std::forward<R>(r))};
// }

// template<typename A, typename B, typename C> requires (et::expr<A> || et::expr<B> || et::expr<C>) 
// constexpr auto fma(A a, B b, C c) { return et::node{et::fma_{}, a, b, c}; } // pareil






int main() {
  // Q5. Le mini exemple ci dessous doit fonctionner. Complétez le avec une série de tests
  // exhaustif de tous les cas qui vous paraissent nécessaire.
  constexpr auto f = et::fma(et::_1, et::abs(et::_2), et::_0/et::_1) - et::_1;
  f.print(std::cout) << "\n"; // => ((arg<1> * | arg<2>| + (arg<0> / arg<1>)) - arg<1>), correct
  std::cout << f(1,2,-3) << "\n"; // => 4

  // tests en plus:
  // calculs
  std::cout << "f(1, 2, -3) = " << f(1, 2, -3) << "\n";
  assert(f(1, 2, -3) == 4);
  std::cout << "f(1.0, 2.0, -3.0) = " << f(1.0, 2.0, -3.0) << "\n";
  assert(f(1., 2., -3.) == 4.5);

  // constexpr test  |  Attention, abs n'est pas constexpr avant C++ 23 (pour des raisons obscures apparement, c.f. https://stackoverflow.com/questions/27708629/why-isnt-abs-constexpr)
  constexpr auto compile_time_val = f(1, 2, -3); 
  static_assert(compile_time_val == 4, "Erreur de calcul à la compil");


  // évaluation avec division par 0
  try {
    std::cout << "Tentative de f(1, 0, -3)..." << std::endl;
    auto x = f(1, 0, -3); // Va lever une exception std::runtime_error via div_
  } catch (const std::runtime_error& e) {
    std::cout << "Exception capturée avec succès : " << e.what() << std::endl;
  }

  // types mismatch mais compatibles
  double res_compatible = f(1.0, 3.0, -3);
  std::cout << "f(1.0, 3.0, -3) = " << res_compatible << "\n";
  assert(std::abs(res_compatible - 6.333333333333333) < 1e-9); // calculs sur les flotants on une certaine précision

  // types mismatch incompatibles mais passe quand meme car pas de static_assert qui contraint les types
  std::cout << "f('a', 3, -3) = " << f('a', 3, -3) << "\n";
  assert(f('a', 3, -3) == 38);


  // Q6. Appliquez la fonction `f` à des vecteurs ou des matrices. Les operateurs + et *
  // doivent être effectués élément par élément (produit de hadamard).
  std::vector<double> v0 = {1.0, 4.0, 9.0};
  std::vector<double> v1 = {2.0, 2.0, 3.0};
  std::vector<double> v2 = {-3.0, -1.0, -2.0};

  std::vector<double> result = f(v0, v1, v2);

  std::cout << "Resultat vectoriel : { ";
  for(double x : result) std::cout << x << " ";
  std::cout << "}\n";

  // Q7 - Comment modifiez le code pour permettre l'utilisation de constante dans les formules
  // Ex: constexpr auto f = et::fma(et::_1, 3, et::_0)
  // Je pense qu'il faut:
  // 1) Créer des feuilles 'litteral'/'constantes (technique standard pour les AST)
  // 2) Convertir les littéraux automatique (tout ce qui n'est pas une experssion)
  // 3) Faire que nos opérateurs acceptent qu'un des 2 côtés ne soit pas une expression ( avec requires (expr<L> || expr<R>))

  // TENTE DE FAIRE DU CODE MAIS IL NE FONCTIONNE PAS ENCORE:
  //  fatal error: use of overloaded operator '-' is ambiguous (with operand types 'node<fma_, terminal<1>, node<abs_, terminal<2>>, node<div_, terminal<0>, terminal<1>>>' (aka 'et::node<et::fma_, et::terminal<1>, et::node<et::abs_, et::terminal<2>>, et::node<et::div_, et::terminal<0>, et::terminal<1>>>') and 'const terminal<1>')
  //   357 |   constexpr auto f = et::fma(et::_1, et::abs(et::_2), et::_0/et::_1) - et::_1;

  // constexpr auto g = fma(12, et::abs(et::_2), et::_0/et::_1) - 52;
  // g.print(std::cout) << "\n"; // => ((12 * | arg<2>| + (arg<0> / arg<1>)) - 52)
  // std::cout << g(1,2,-3) << "\n"; // => ??
}


