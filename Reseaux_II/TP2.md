# TP2
**Mathieu Waharte** - 06/11/2025

<!--! TODO Mercredi prochain 23:59 -->

&nbsp;  
&nbsp;  
## Exercice 1 - Web Server
On se place dans le répertoire `web-server` et on lance le lab avec `kathara lstart`.  
On peut vérifier que apache2 est bien lancé sur le server avec `systemctl start apache2` et on a:  
![Apache Working](./TP_assets/TP2_Exo1_apache.png)  

On va se connecter au serveur depuis le client avec `links http://10.0.0.1`. La page HTML s'affiche:
![Apache Page](./TP_assets/TP2_Exo1_apache_page.png)  

Ensuite on peut regarder les logs d'accès avec `tail -f /var/log/apache2/access.log` sur le server et les logs d'erreur avec `tail -f /var/log/apache2/error.log`.
![Apache Logs](./TP_assets/TP2_Exo1_apache_logs.png)  

On peut lister les modules apache avec `apache2 -l` et activer un module avec `a2enmod rewrite` par exemple puis en redémarrant:  
![Apache Modules](./TP_assets/TP2_Exo1_apache_modules.png)


Pour expérimenter avec la configuration, on crée un fichier `.htaccess` dans `/var/www/html` avec le contenu suivant:  
```
DirectoryIndex custom_file.html
```
Pour qu'il soit bien pris en compte, on doit modifier la configuration à `/etc/apache2/apache2.conf` pour `AllowOverride All`.  
Et on change le nom du fichier `index.html` en `custom_file.html` avant de redémarrer le serveur.
![File renaming on Server](./TP_assets/TP2_Exo1_file_renaming.png)
L'accès à la page web depuis le client fonctionne toujours:
![Apache Custom File](./TP_assets/TP2_Exo1_apache_custom_file.png)

En revanche si l'on remet le nom du fichier en `index.html` sans modifier le `.htaccess`, on devrait obtienir une erreur 403 Forbidden mais le serveur nous préviens juste et donne le dossier à la place:
![Apache Forbidden](./TP_assets/TP2_Exo1_apache_forbidden.png)


&nbsp;  
&nbsp;  
## Exercice 2 - Load-balancer
La topologie de ce TP consiste en 2 clients, 3 servers et un load-balancer entre les clients et les serveurs.  
![Load Balancer Topology](./TP_assets/TP2_Exo2_topology.png)

On va se connecter au load-balancer sur un client avec `links http://10.0.0.2`. Le load-balancer redirige vers un des serveurs. Pour retenter, on peut relancer une connexion et le load-balancer redirige vers un autre serveur ou le même. Cela permet de répartir la charge entre les serveurs, normalement leur comportement est identique. On peut donc observer les 3 servers avec la même commande:
![Client1 command](./TP_assets/TP2_Exo2_client1_command.png)
![Server1 response](./TP_assets/TP2_Exo2_server1_response.png)
![Server2 response](./TP_assets/TP2_Exo2_server2_response.png)
![Server3 response](./TP_assets/TP2_Exo2_server3_response.png)

On voit bien qu'on a obtenu des réponses de chacun des serveurs.  
Un autre algorithme de répartition de charge pourrait chercher à nous rediriger autant que possible vers le même serveur quand on est le même client pour réduire la latence de connexion, ne changeant qu'en cas de besoin.  

&nbsp;  
&nbsp;  
## Exercice 3 - DNS