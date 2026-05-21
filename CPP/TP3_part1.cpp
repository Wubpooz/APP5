#include <array>
#include <cstdint>
#include <cstring>
#include <tuple>
#include <utility>

/// int_<N> représente la valeur N encodée sous forme de type
template <int I> using int_ = std::integral_constant<int, I>;

//==============================================================================
/// Etape 1
/// Implémenter:
/// -  for_constexpr<Debut,Pas,Fin>(Func) qui appelle la fonction Func en lui
/// passant successivement
///    int_<Debut>, int_<Debut+Pas>, ..., jusqu'à que la valeur atteigne ou
///    dépasse Fin. Pour ce faire, vous utiliser un std::index_sequence pour
///    fournir un contexte variadique de répétition qui vous permettra
///    d'utiliser ... pour dérouler les appels à Func.

template <int Debut, int Pas, int Fin, typename Func>
void for_constexpr(Func &&f) {
  [&f]<std::size_t... Is>(std::index_sequence<Is...>){ (f(int_<Debut + Is * Pas>{}), ...); }
    (std::make_index_sequence<(Fin - Debut + Pas - 1) / Pas>{});
  // we create a lambda that is apply on each member using the indexe sequence
}

//==============================================================================
/// Etape 2
/// Implémenter une fonction for_each_members qui prend un tuple T et une
/// fonction Func pour appliquer Func à chaque membre du tuple. Utilisez
/// for_constexpr, std::tuple_size et std::get pour effectuer cette tache.
template <typename T, typename F> void for_each_member(T &&t, F &&f) {
  for_constexpr<0, 1, std::tuple_size<std::decay_t<T>>::value>([&](auto i){ std::forward<F>(f)(std::get<i>(std::forward<T>(t))); });
  // decay_t or remove_reference_t is needed because of && not being properly interpreted by std::tuple_size.
  // TODO Dès que vous utilisez une référence universelle (T&&), vous devez utiliser std::forward<T> pour la transmettre à une autre fonction (here for t in std::get)
}

//==============================================================================
/// Etape 3
/// Implémenter un fonction serialize qui prend un paramètre T et qui
///  - si T n'est pas un tuple, renvoit un std::array<std::uint8_t,N> avec N =
///  sizeof(T) qui
///    contient une copie des octets de T. Vous utiliserez std::memcpy pour
///    effectuer cette copie.
///  - si T est de la forme std::tuple<Ts...>, renvoit un
///  std::array<std::uint8_t,N> avec N égal
///    à la somme des sizeof(Ts) et qui contient la copie des octets de chaque
///    membre du tuple.
template <typename T> auto serialize(T const &value) {
  std::array<std::uint8_t, sizeof(T)> arr;
  std::memcpy(arr.data(), &value, sizeof(T));
  return arr;
}

template<typename T> constexpr auto size(T) { return sizeof(T); }
template<typename ...Ts> constexpr auto total_size_of(std::tuple<Ts...> const&) { 
  return (sizeof(Ts) + ...); 
}

template <typename... Ts> auto serialize(std::tuple<Ts...> const &value) {
  constexpr int size = total_size_of(std::tuple<Ts...>{});
  std::array<std::uint8_t, size> arr{};
  std::size_t offset = 0;
  for_each_member(value, [&](auto const& elem) { 
    std::memcpy(arr.data() + offset, &elem, sizeof(elem));
    offset += sizeof(elem);
  });
  return arr;
}

/// Boite à type
template <typename T> struct as {};

//==============================================================================
/// Etape 4
/// Implémenter un fonction deserialize qui prend un prend un array de
/// std::uint8_t de taille arbitraire et une instance de as<T> et reconstruit un
/// objet de type T à partir des octets stocké dans le array.
///
/// Vous aurez besoin de calculer des types intermédiaires, pensez à decltype
///
/// Question bonus, que se passe-t-il si vous désérialisez un objet dans un type
/// de même taille mais de contenu différent ? Par exemple deserialisez un float
/// dans un int ou un tuple dans un autre tuple de layout différent.
template <typename T, std::size_t N>
T deserialize(std::array<std::uint8_t, N> const &bytes, as<T>) {

}

template <typename... Ts, std::size_t N>
std::tuple<Ts...> deserialize(std::array<std::uint8_t, N> const &bytes, as<std::tuple<Ts...>>) {

}

#include <cassert>
#include <iostream>

int main() 
{
  //---- Tests pour for_constexpr
  int r = 0;
  for_constexpr<0, 2, 10>([&](auto i) 
  {
    std::cout << i << " ";
    r += i;
  });
  std::cout << "\n";
  assert(r == 20);

  //---- Tests pour for_each_member
  auto t = std::make_tuple(1, 2.5, 3.6f);

  for_each_member(t, [](auto m) { std::cout << m << " "; });
  std::cout << "\n";
  for_each_member(t, [](auto &m) { m += m; });
  for_each_member(t, [](auto m) { std::cout << m << " "; });
  std::cout << "\n";

  //---- Tests pour serialize
  auto f = 2.73f;
  auto bf = serialize(f);

  for (auto b : bf)
    std::cout << std::hex << +b << " ";
  std::cout << std::endl;
  assert(bf.size() == 4);
  assert(bf[0] == 0x52);
  assert(bf[1] == 0xB8);
  assert(bf[2] == 0x2E);
  assert(bf[3] == 0x40);

  auto t2 = std::make_tuple(0xaabbccdd, 'Z');
  auto bt = serialize(t2);

  for (auto b : bt)
    std::cout << std::hex << +b << " ";
  std::cout << std::endl;
  assert(bt.size() == 5);
  assert(bt[0] == 0xDD);
  assert(bt[1] == 0xCC);
  assert(bt[2] == 0xBB);
  assert(bt[3] == 0xAA);
  assert(bt[4] == 0x5A);

  auto t3 = std::make_tuple(short{1234}, t2);
  auto bu = serialize(t3);

  for (auto b : bu)
    std::cout << std::hex << +b << " ";
  std::cout << std::endl;
  assert(bu.size() == 7);
  assert(bu[0] == 0xD2);
  assert(bu[1] == 0x04);
  assert(bu[2] == 0xDD);
  assert(bu[3] == 0xCC);
  assert(bu[4] == 0xBB);
  assert(bu[5] == 0xAA);
  assert(bu[6] == 0x5A);

  auto g = deserialize(bf, as<float>{});
  assert(g == f);

  auto u = deserialize(bt, as<std::tuple<int, char>>{});
  assert(u == t2);

  auto v = deserialize(bu, as<std::tuple<short, std::tuple<int, char>>>{});
  assert(v == t3);
}