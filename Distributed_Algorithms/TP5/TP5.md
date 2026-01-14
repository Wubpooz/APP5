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
- [x] Robustesse aux pannes
- [ ] Snowball