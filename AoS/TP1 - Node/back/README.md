# Back

## Librairie tierce

- Prisma : cette librarie va servir à faire la liaison entre notre API et la base de données.
  Exemple d'utilisation [ici](https://www.prisma.io/docs/getting-started)

## La structure

- src : le code source

- docs : contient la documentation en openapi3

- test : via postman ou autre ?

## Structure du dossier src

Le dossier src a été créé en pensant séparation des responsabilités

- main.ts : point d'entrée de l'app
- config.ts : les variables d'env de l'app
- infrastructure : les dépendances externe de l'app
- contexts : les contexts de l'app

## Executer le projet

1. créer un fichier .env en copiant le fichier .env.example
2. créer un fichier .env.local en copiant le fichier .env.example
3. exécuter la commande : yarn db:generate (générera la configuration prisma)
4. exécuter la commande : yarn db:migrate (exécutera les fichiers de migration prisma dans une bdd sqlite)
5. lancer le projet avec la commande : yarn serve

Enjoy !

## Petit bonus

- Pour bien débuter avec [Prisma](https://www.prisma.io/docs/getting-started)

- Pour arrêter de faire des [if == null](https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Op%C3%A9rateurs/Optional_chaining)

- Comment faire des vraies valeurs par défaut en [nodejs](https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Operators/Nullish_coalescing_operator)

- Comment faire une bonne structure [nodejs](https://softwareontheroad.com/ideal-nodejs-project-structure/)

- Les variables d'environnement ne doivent pas être écrites en dur... essayez plutôt [dotenv](https://www.npmjs.com/package/dotenv)
