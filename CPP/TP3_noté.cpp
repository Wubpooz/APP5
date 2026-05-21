#include <iostream>
#include <cmath>
#include <tuple>
#include <algorithm>

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
    constexpr auto operator()(auto&& a, auto&& b) const { return a + b; }
    void print(std::ostream& os, const auto& a, const auto& b) const {
      os << "(";
      a.print(os);
      os << " + ";
      b.print(os);
      os << ")";
    }
  };

  struct sub_ {
    constexpr auto operator()(auto&& a, auto&& b) const { return a - b; }
    void print(std::ostream& os, const auto& a, const auto& b) const {
      os << "(";
      a.print(os);
      os << " - ";
      b.print(os);
      os << ")";
    }
  };

  struct mul_ {
    constexpr auto operator()(auto&& a, auto&& b) const { return a * b; }
    void print(std::ostream& os, const auto& a, const auto& b) const {
      os << "(";
      a.print(os);
      os << " * ";
      b.print(os);
      os << ")";
    }
  };

  struct div_ {
    constexpr auto operator()(auto&& a, auto&& b) const { return a / b; }
    void print(std::ostream& os, const auto& a, const auto& b) const {
      os << "(";
      a.print(os);
      os << " / ";
      b.print(os);
      os << ")";
    }
  };

  struct abs_ {
    constexpr auto operator()(auto&& a) const { return std::abs(a); }
    void print(std::ostream& os, const auto& a) const {
      os << "| ";
      a.print(os);
      os << "|";
    }
  };

  struct fma_ {
    constexpr auto operator()(auto&& a, auto&& b, auto&& c) const { return a * b + c; }
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


int main() {
  // Q5. Le mini exemple ci dessous doit fonctionner. Complétez le avec une série de tests
  // exhaustif de tous les cas qui vous paraissent nécessaire.
  constexpr auto f = et::fma(et::_1, abs(et::_2), et::_0/et::_1) - et::_1;
  f.print(std::cout) << "\n";
  std::cout << f(1,2,-3) << "\n"; // => ((arg<1> * | arg<2>| + (arg<0> / arg<1>)) - arg<1>), correct

  // Q6. Appliquez la fonction `f` à des vecteurs ou des matrices. Les operateurs + et *
  // doivent être effectués élément par élément (produit de hadamard).

  /* ???? */ 

  // Q7 - Comment modifiez le code pour permettre l'utilisation de constante dans les formules
  // Ex: constexpr auto f = et::fma(et::_1, 3, et::_0)
}
