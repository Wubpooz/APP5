# TP5 - Implémentation de l'algorithme Snowflake
**Mathieu WAHARTE - APP5**

## Comment lancer mes programmes
- Pour lancer un seul noeud avec configuration personnalisée:
  `python snowy.py <node_id> --port <port> --color <BLUE|RED> --crash-prob <prob> --neighbors <port1> <port2> <port3> ... --host <ip> --algorithm <SNOWFLAKE|SNOWBALL>`
- Pour lancer un seul noeud avec valeurs par défaut:
  `python snowy.py <node_id>`
- Pour lancer tous les noeuds ensemble (dans le même processus/terminal):
  `python snowy.py`

Options supplémentaires:
- `--host <ip>` : Adresse IP du noeud (défaut: 127.0.0.1)
- `--algorithm <SNOWFLAKE|SNOWBALL>` : Algorithme de consensus utilisé par le noeud (défaut: SNOWFLAKE)

- Pour lancer un réseau Snowball automatisé:
  `launch_snowball_network.bat [N]`: Script pour lancer N noeuds Snowball dans des terminaux séparés.

&nbsp;  

- Pour lancer des réseaux automatisés, utilisez les scripts batch:
  - `launch_network.bat [N]`: Script pour lancer N noeuds dans des terminaux séparés.
  - `launch_conflict_network.bat [N]`:  Script pour lancer N noeuds avec un conflit initial de couleurs.
  - `launch_crash_network.bat [N] [CRASH_PROB]`: Script pour lancer N noeuds avec simulation de pannes.
  - `launch_snowball_network.bat [N]`: Script pour lancer N noeuds Snowball dans des terminaux séparés.


&nbsp;  
- Pour lancer une visualisation en temps réel:
  `python consensus_viz.py`
  On peut choisir l'algorithme, augmenter le nombre de noeuds, régler la vitesse, réinitialiser le réseau, etc.


&nbsp;  
&nbsp;  
## TODO
- [x] Configuration : chaque nœud reçoit au démarrage son propre port et la liste des ports de tous les autres nœuds du réseau (connaissance statique pour simplifier la découverte).
- [x] Définir la classe principale de votre nœud et son état interne. Cet état sera accédé par
plusieurs threads simultanément et doit être protégé. Définissez les variables d’état nécessaires pour suivre la préférence actuelle (`my_color`), la conviction (`counter`), et l’état de décision (accepté ou non).
- [x] Intégrez les paramètres de l’algorithme ($k$, $\alpha$, $\beta$). Vous pouvez choisir des valeurs par défaut raisonnables (ex : $k = 3$, $\alpha = 2$, $\beta = 10$ pour un petit réseau).
- [x] récupérer ses arguments de configuration (son port, sa couleur initiale, et les ports des voisins) via la ligne de commande (`sys.argv`).
- [x] implémentez un thread qui écoute sur le port du noeud. Il doit accepter les connexions entrantes, lire la requête `"QUERY"`, et renvoyer la couleur actuelle du nœud au demandeur. Attention : l’accès à la couleur doit être "thread-safe" (utilisez un Lock).
- [x] implémentez une fonction `query_peers()` capable d’interroger un sous-ensemble aléatoire de k voisins. Cette fonction doit renvoyer les
comptes des couleurs reçues (ex : `{’R’: 2, ’B’: 1}`).
- [x] Implémentez la boucle principale dans votre thread principal (ou un thread "Consensus" dédié).
  - [x] Effectuer l’échantillonnage réseau.
  - [x] Mettre à jour les variables d’état selon les règles de Snowflake.
  - [x] Décider si le consensus est atteint (seuil $\beta$).
- [x] Ajoutez un court délai (`time.sleep`) à chaque itération pour rendre l’exécution observable.


### Bonus
- [x] Scripts d'automatisation
- [ ] Visualisation en temps réel
  - [x] window with nodes with the states (labels optionals), names as labels, edges as connections and current state/decision + end decision as text.
  - [x] later: add nodes button, reset, change color by clicking on nodes, etc.
- [x] Robustesse aux pannes
- [x] Snowball