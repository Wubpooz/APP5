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



&nbsp;  
&nbsp;  
## Exercice 3 - DNS