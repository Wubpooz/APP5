/*
 * ============================================================
 * SECTION 1 — Création et affichage de points
 * ============================================================
 *
 * Types manipulés lors de ce TP :
 *   template<std::size_t dim> struct point { double coords[dim]; };
 *   template<std::size_t dim> using points = std::vector<point<dim>>;
 *
 *
 * 1.1) Définissez une fonction pour créer un point avec des coordonnées
 *      aléatoires comprises entre 0 et 1, avec la signature :
 *        template<std::size_t dim> point<dim> randomPoint();
 *
 * 1.2) Définissez une fonction pour afficher les coordonnées d'un point
 *      sur le stream passé en argument, avec la signature :
 *        template<std::size_t dim>
 *        std::ostream& operator<<(std::ostream& out, point<dim> const& p);
 *
 *      Testez avec :
 *        std::cout << randomPoint<3>() << '\n';
 *
 * 1.3) Combinez std::generate_n, std::back_inserter et randomPoint pour
 *      remplir un vecteur de type points<4> avec 5 points aléatoires.
 *      (Le code ne doit pas dépasser une instruction.)
 *
 * 1.4) Combinez std::for_each avec une fonction anonyme affichant un point
 *      sur la sortie standard pour afficher le contenu du vecteur précédent.
 *      (Le code ne doit pas dépasser une instruction.)
 *
 * ============================================================
 * SECTION 2 — Longueur de chemin
 * ============================================================
 *
 * 2.1) Définissez une fonction calculant la distance euclidienne entre
 *      deux points de même dimension :
 *
 *        template<std::size_t dim>
 *        double dist(point<dim> const& p1, point<dim> const& p2);
 *
 * 2.2) Définissez une fonction pathLength prenant un vecteur de type
 *      points en argument et renvoyant la longueur du chemin FERMÉ
 *      passant par tous les points (dans l'ordre du vecteur).
 *      Utilisez std::for_each.
 *
 * 2.3) Proposez une variante de pathLength utilisant std::accumulate.
 *
 * 2.4) Testez vos deux fonctions en affichant le périmètre du triangle
 *      suivant (résultat attendu : environ 3.414) :
 *
 *        points<2> triangle = { {0.,0.}, {1.,0.}, {0.,1.} };
 *
 * ============================================================
 * SECTION 3 — Échantillonnage
 * ============================================================
 *
 * 3.1) Définissez une fonction quantize qui prend un point en argument
 *      et renvoie un point dont les coordonnées sont arrondies par défaut
 *      à 0.1 près.
 *      Exemple : (0.234, 0.456, 0.678) --> (0.2, 0.4, 0.6)
 *
 * 3.2) Définissez un opérateur de comparaison stricte lt qui prend deux
 *      points de même dimension et effectue une comparaison lexicographique
 *      stricte sur leurs versions arrondies par quantize.
 *      Vérifiez les résultats suivants :
 *        (0.15, 0.72) <  (0.43, 0.09)  --> vrai
 *        (0.27, 0.57) <  (0.21, 0.63)  --> vrai  (quantize: 0.2<0.2 faux, 0.5<0.6 vrai)
 *        (0.34, 0.72) <  (0.36, 0.73)  --> faux
 *        (0.43, 0.09) <  (0.15, 0.72)  --> faux
 *
 * 3.3) Essayez de définir un ensemble de points ordonné par lt :
 *        template<std::size_t dim>
 *        using point_set = std::set<point<dim>, lt<dim>>;
 *
 *      Note : le C++ n'autorise pas d'utiliser directement une fonction
 *      comme second paramètre template de std::set. Définissez donc une
 *      classe template ayant une unique méthode operator() qui appelle lt
 *      pour comparer deux points, et utilisez cette classe pour définir
 *      point_set.
 *
 * 3.4) Créez un vecteur de 10 000 points aléatoires en dimension 4.
 *      Combinez std::copy et std::inserter pour transformer ce vecteur
 *      en un ensemble ordonné de type point_set.
 *      Affichez la taille de l'ensemble résultant.
 *
 * ============================================================
*/

#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <iterator>
#include <numeric>
#include <set>
#include <vector>
#include <random>

template <std::size_t dim> struct point { double coords[dim]; };
template <std::size_t dim> using points = std::vector<point<dim>>;

// 1.1) Créer un point avec des coordonnées aléatoires dans [0, 1]
template <std::size_t dim> point<dim> randomPoint() {
  static thread_local std::mt19937_64 generator(std::random_device{}());
  std::uniform_real_distribution<double> distrib(0.0, 1.0);
  point<dim> p{};
  for (std::size_t i = 0; i < dim; i++) {
    p.coords[i] = distrib(generator);
  }
  return p;
}

// 1.2) Afficher les coordonnées d'un point sur un stream
template <std::size_t dim>
std::ostream &operator<<(std::ostream &out, point<dim> const &p) {
  out << "(";
  for (std::size_t i = 0; i < dim; i++) {
    if (i > 0) out << ", ";
    out << p.coords[i];
  }
  out << ")";
  return out;
}

// 1.3) Remplir un vecteur de n points aléatoires avec std::generate_n
template <std::size_t dim> points<dim> randomPoints(std::size_t n) {
  points<dim> pts;
  std::generate_n(std::back_inserter(pts), n, randomPoint<dim>);
  return pts;
}

// 1.4) Afficher tous les points d'un vecteur avec std::for_each
template <std::size_t dim>
std::ostream &operator<<(std::ostream &out, points<dim> const &pts) {
  std::for_each(pts.begin(), pts.end(),
    [&out](auto &p) { out << " " << p << "\n";});
  return out;
}

// 2.1) Distance euclidienne entre deux points
template <std::size_t dim>
double dist(point<dim> const &p1, point<dim> const &p2) {
  double sum = 0;
  for (std::size_t i = 0; i < dim; i++) {
    double d = p1.coords[i] - p2.coords[i];
    sum += d * d;
  }
  return std::sqrt(sum);
}

// 2.2) Longueur du chemin fermé avec std::for_each
template <std::size_t dim> double pathLength(points<dim> const &pts) {
  if (pts.size() == 0) return 0;
  double len = 0;
  std::for_each(pts.begin(), pts.end(),
    [&pts, &len](auto &p) { static point<dim> prev = pts.back(); len += dist(prev, p); prev = p; });
  return len;
}

// 2.3) Longueur du chemin fermé avec std::accumulate
template <std::size_t dim> double pathLength2(points<dim> const &pts) {
  if (pts.size() == 0) return 0;
  return std::accumulate(pts.begin(), pts.end(), 0.0,
    [&pts](double sum, auto &p) { static point<dim> prev = pts.back(); double d = dist(prev, p); prev = p; return sum + d; });
}

// 3.1) Arrondir les coordonnées d'un point à 0.1 près par défaut
template <std::size_t dim> point<dim> quant(point<dim> const &p1) {
  point<dim> p{};
  for (std::size_t i = 0; i < dim; i++) {
    p.coords[i] = (int)(p1.coords[i] * 10 )/ 10;
  }
  return p;
}

// 3.2) Comparaison lexicographique stricte sur les versions arrondies
template <std::size_t dim> bool lt(point<dim> const &p1, point<dim> const &p2) {
  std::lexicographical_compare(quant(p1).coords, quant(p1).coords + dim,
                             quant(p2).coords, quant(p2).coords + dim);
}

// 3.3) Classe foncteur encapsulant lt pour std::set
template <std::size_t dim> struct clt {
  bool operator()(point<dim> const &p1, point<dim> const &p2) const {
    return lt(p1, p2);
  }
};

template <std::size_t dim> using point_set = std::set<point<dim>, clt<dim>>;

int main() {
  std::cout << "un point : " << randomPoint<3>() << '\n';

  points<2> pts = randomPoints<2>(4);
  std::cout << "un vecteur de points :\n" << pts;

  points<2> triangle = {{0., 0.}, {1., 0.}, {0., 1.}};
  std::cout << "périmètre du triangle : " << pathLength(triangle) << ' '
            << pathLength2(triangle) << '\n';

  std::pair<point<2>, point<2>> ppts[4] = {{{0.15, 0.72}, {0.43, 0.09}},
                                           {{0.27, 0.57}, {0.21, 0.63}},
                                           {{0.34, 0.72}, {0.36, 0.73}},
                                           {{0.43, 0.09}, {0.15, 0.72}}};
  for (auto const &pp : ppts) {
    char const *s = lt(pp.first, pp.second) ? " <  " : " >= ";
    std::cout << pp.first << s << pp.second << '\n';
  }

  points<4> pts2 = randomPoints<4>(10000);
  point_set<4> pset;

  std::copy(pts2.begin(), pts2.end(), std::inserter(pset, pset.end()));

  std::cout << "taille de l'ensemble : " << pset.size() << '\n';
}