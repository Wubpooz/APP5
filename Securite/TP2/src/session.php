<?php
/*
ce fichier doit être chargé avant tout envoi d'une en-tête HTTP
un espace avant la balise PHP et c'est l'erreur fatale !
*/


# démarrage de la session
session_start();
# définition d'une date de validité pour le cookie sinon
# il ne sera valable que jusqu'à la fermeture du navigateur
# comme la session, d'ailleurs
$cookieDate = time() + 31536000; // valable un an
if (empty($_COOKIE['c_lastvisit'])) {

  # il s'agit d'un nouveau visiteur :
  # création du cookie et d'une session
  # à la date courante
  $_SESSION['s_lastvisit'] = time();
  setcookie('c_lastvisit', time(), $cookieDate);
} elseif (empty($_SESSION['s_lastvisit'])) {
  # il s'agit d'un visiteur connu :
  # mise à jour de la session selon cookie
  $_SESSION['s_lastvisit'] = $_COOKIE['c_lastvisit'];
  $_SESSION['s_menu'] = $_COOKIE['c_menu'];
  # mise à jour du cookie (la date courante)
  setcookie('c_lastvisit', time(), $cookieDate);
}

# l'utilisateur demande un autre menu
# ou une session 's_menu' n'a pas été implémentée
if (isset($_GET['menu']) || !isset($_SESSION['s_menu'])) {
  $_SESSION['s_menu'] = 1;
  if ($_GET['menu'] == 2) {
    $_SESSION['s_menu'] = 2;
  }
  # on mémorise la config dans un cookie
  setcookie('c_menu', $_SESSION['s_menu'], $cookieDate);
}



/*
Affichage et traitement :
quand vous rechargez la page ou quittez le navigateur
le choix ne change pas et votre date de visite est précisée
*/
echo "<html><head>\n<title>Test</title>\n</head><body>\n";
if ($_SESSION['s_menu'] == 1) {
  echo "<p>Voici un lien : \n";
  echo "<a href=\"?menu=2\">voir un second</a></p>\n";
  echo "<p>Recharger la <a href=\"" .
    $_SERVER['PHP_SELF'] . "\">page</a>\n";
  echo "<br>Dernière visite le " .
    date("d.m.Y à H:i", $_SESSION['s_lastvisit']) . "</p>\n";
} else {
  echo "<p>Voici un second lien : \n";
  echo "<a href=\"?menu=1\">revoir le premier</a></p>\n";
  echo "<p>Recharger la <a href=\"" .
    $_SERVER['PHP_SELF'] . "\">page</a>\n";
  echo "<br>Dernière visite le " .
    date("d.m.Y à H:i", $_SESSION['s_lastvisit']) . "</p>\n";
}
echo "</body></html>";
?>