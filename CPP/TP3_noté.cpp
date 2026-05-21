
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

namespace et
{
    
  //---------------------------------------------------------------------------------------
  // Q1 - Définissez un concept expr qui est valide si un type T fournit un membre T::is_expr()
  template<typename T>
  concept expr = requires( /* ???? */ )
  {
    /* ???? */  
  };

  //---------------------------------------------------------------------------------------
  /*
    Le premier élément fondamental d'un systeme d'EXPRESSION TEMPLATE est la classe
    `terminal`. Un TERMINAL représente une feuille de l'ARBRE DE SYNTAXE. Dans notre cas,
    nos terminaux sont numérotés statiquement pour représenter différentes variables.

    Q2. Complétez l'implémentation de la structure template `terminal` ci-dessous en suivant les demandes
  */
  //---------------------------------------------------------------------------------------
  template<int ID>
  struct terminal 
  {
    // Faite en sorte que terminal vérifie le concept expr
    /* ???? */ 

    std::ostream & print(std::ostream & os) const
    {
      // Pour terminal<I>, affiche "arg<I>" et renvoit os.
      /* ???? */ 
    }

    template<typename... Args>
    constexpr auto operator()(Args &&... args) const
    {
      // Construit un tuple de tout les args et renvoit le ID-eme via std::get
      // Veillez à bien respecter le fait que args est une reference universelle
      /* ???? */ 
    }
  };

  // Generateur de variable numérotée - arg<ID> est un terminal<ID>
  template<int ID>
  inline constexpr auto arg = /* ???? */;

  // Définissez les variables _0, _1 et _2 avec l'ID correspondant
  inline constexpr auto _0  = /* ??? */;
  inline constexpr auto _1  = /* ??? */;
  inline constexpr auto _2  = /* ??? */;

  //---------------------------------------------------------------------------------------
  /*
    Le deuxieme élément  d'un systeme d'EXPRESSION TEMPLATE est la classe de noeud. 
    Un NODE représente un opérateur ou une fonction dans l'ARBRE DE SYNTAXE. 

    Il est défini par le type de l'OPERATION effectuée au passage du noeud et d'une
    liste variadique de ses sous-nodes.

    Q3 Complétez l'implémentation de la structure template node ci dessous en suivant les demandes
  */
  //---------------------------------------------------------------------------------------
  template<typename Op, typename... Children>
  struct node
  {
    // Faite en sorte que node vérifie le concept expr
    /* ???? */ 

    // Construisez un node à partir d'une instande de Op et d'une liste variadique de Children
    // Ce constructeur sera constexpr
    /* ???? */ 

    // L'operateur() de node permet d'avaluer le sous-arbre courant de manière 
    // récursive. Les paramètres args... représentent dans l'ordre les valeurs des
    // variables contenus dans le sous arbre.
    // Par exemple, le node {op_add, terminal<1>, termnal<0>} appelant operator()(4, 9)
    // doit renvoyer op_add(9, 4);
    template<typename... Args>
    constexpr auto operator()(Args&&... args) const
    {
      /* ???? */ 
    }

    // Affiche un node en demandant à Op d'afficher les sous arbres
    std::ostream& print(std::ostream& os) const
    {
      /* ???? */ 
    }
    
    /* ???? */  op;
    /* ???? */  children;
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
}

int main()
{
  // Q5. Le mini exemple ci dessous doit fonctionner. Complétez le avec une série de tests
  // exhaustif de tous les cas qui vous paraissent nécessaire.

  constexpr auto f = et::fma(et::_1, abs(et::_2),et::_0/et::_1) - et::_1;
  f.print(std::cout) << "\n";
  std::cout << f(1,2,-3) << "\n";

  // Q6. Appliquez la fonction `f` à des vecteurs ou des matrices. Les operateurs + et *
  // doivent être effectués élément par élément (produit de hadamard).

  /* ???? */ 

  // Q7 - Comment modifiez le code pour permettre l'utilisation de constante dans les formules
  // Ex: constexpr auto f = et::fma(et::_1, 3, et::_0)
}
