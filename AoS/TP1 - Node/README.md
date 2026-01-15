# TP1 : Micro Services

Le but de ce TP va être de créer une API qui pourra être appelée par d'autres services (dans la suite de ce TP nous créerons une application front/ ou des tests POSTMAN qui consommera notre service)

## Prérequis

- Avoir installé [Nodejs](https://nodejs.org/en/) (dernière version de préférence pour les petits plus que vous trouverez en bonus)

## Le back

Le but de notre back va être de servir des informations au front. Ici nous allons créer un micro service qui gère une librairie de livre pour un utilisateur. L'utilisateur va pouvoir ajouter des livres à sa librairie, en supprimer, les lister et faire des recherches.

Dans ce TP il vous est fourni un dossier back qui contient toute la structure nécessaire pour bien commencer votre TP.

Si vous avez la moindre question n'hésitez pas à demander de l'aide !

### Rappel de cours /!\

Comme vu en cours, il existe 4 verbes principaux pour utiliser le protocol REST :

- GET : pour récupérer un objet ou une liste d'objet.
- POST : pour créer un objet.
- PUT : pour mettre à jour un objet.
- DELETE : pour supprimer un objet.

Comme vous pouvez vous en douter ces verbes sont nécessaire pour créer votre librairie.

En même temps de suivre ce TP, n'hésitez pas à faire du TDD (Test Driven Development).

N'hésitez pas à compléter la documentation en OpenApi 3.

## Les Questions

### Question 1 :

**Back :** Créer un service qui permet d'ajouter un livre.

### Question 2 :

**Back :** Créer un service qui permette de récupérer une liste de livres.

### Question 3 :

**Back :** Créer un service qui permet de récupérer toutes les informations d'un livre en particulier.

### Question 4 :

**Back :** Créer un service qui permet de supprimer un livre.

### Question 5 :

**Back :** Créer un service qui permet de modifier un livre.

### Question 6 :

Maintenant mon livre est écrit par des auteurs. On doit pouvoir ajouter des auteurs et les relier à des livres. Il doit être possible d'enlever un auteur d'un livre et d'en rajouter.

### Question 7 :

Il commence à y avoir un peu trop de livres... Il serait intéressant de faire une pagination de mes livres sur la page principal pour que cela soit plus lisible. La page doit donc afficher les livres 10 par 10.