# TP4 - Avalanche & Snowball
**Mathieu Waharte - APP5 IIM**
&nbsp;  
1) Pour la famille classique, le problème de scalabilité et de performance vient du fait que chaque noeud doit communiquer avec tous les autres noeuds pour parvenir à un consensus. Pour la famille Nakamoto, le problème vient du fait que les noeuds doivent constamment participer au protocole pour garantir la sécurité, même lorsqu'il n'y a pas de décisions à prendre, ce qui entraîne une consommation énergétique élevée et des limitations de performance.

2) L'approche Metastable permet de converger même en réseau bivalent en exploitant des perturbations aléatoires dans l'échantillonnage. En effectuant des échantillonnages répétés, les noeuds peuvent progressivement amplifier de petites différences dans les choix de couleur, conduisant finalement à une décision unique.

3) Si au moins $\alpha$ noeuds dans l'échantillon de taille $k$ ont la même couleur, le noeud change sa propre couleur pour cette couleur majoritaire. Si ce seuil n'est pas atteint, le noeud conserve sa couleur actuelle.


4) Pour consolider le choix, on ajoute un compteur dans Snowflake qui suit le nombre de fois qu'un noeud a adopté la même couleur consécutivement. Le paramètre $\beta$ détermine le nombre minimum de confirmations nécessaires pour qu'un noeud accepte définitivement une couleur, renforçant ainsi la confiance dans la décision prise.

5) La différence fondamentale entre le compteur de Snowflake (cnt) et les compteurs de confiance de Snowball (d[]) réside dans leur durabilité. Le compteur de Snowflake est "éphémère" car il est réinitialisé si le noeud change de couleur, tandis que les compteurs de Snowball accumulent des votes sur plusieurs rounds/queries, rendant l'état de Snowball durable et plus robuste face aux fluctuations temporaires. La couleur du noeud est maintenant la couleur avec le plus grand nombre de votes accumulés au round courant en prenant en compte les rounds précèdents et non plus la dernière couleur adoptée.

6) Les auteurs comparent ce risque à celui d'un problème matériel aléatoire (j'image par exemple au fameux bit flip due à une particule cosmique).

7) Un grand avantage du protocole Snow est qu'on limite le nombre de messages d'un noeud et on a donc une complexité en $O(1)$ par round et $O(\log{(n)})$ rounds. Cela aide à la scalabilité car chaque noeud n'a pas besoin de communiquer avec tous les autres noeuds, réduisant ainsi la charge de communication globale et permettant au système de gérer un plus grand nombre de noeuds efficacement. Ils le démontrent avec un DAG (Directed Acyclic Graph) dans Avalanche qui réduit le coût total par noeud de $O(\log{(n)})$ à $O(1)$.

8) L'algorithme Snowball en lui-même ne prévient pas les attaques Sybil. Les auteurs reconnaissent que pour protéger contre de telles attaques, un mécanisme de contrôle Sybil est nécessaire en complément de leur algorithme de consensus, d'après eux ces méchanismes de contrôle sont distincts des algorithmes de consensus. De ce fait, il proposent d'adopter une sorte de surcouche de sécurité pour gérer les attaques Sybil, comme l'utilisation de preuves de participation qui est alignée avec leur approche de capacité de "pauser" la participation des noeuds inactifs.
