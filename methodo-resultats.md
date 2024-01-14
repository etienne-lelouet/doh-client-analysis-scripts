# Objectif

Obtenir une trace des requêtes DNS déclenchées par l'ouverture d'une page arbitraire dans un navigateur.

# Problèmes

## Problème 1:

Comment obtenir uniquement la trace du logiciel étudié ? Sur la machine que j'utilise, beaucoup de logiciels sont susceptibles de faire des requêtes DNS.

### Solution :

Lancer l'application dans un conteneur disposant de sa propre interface réseau (option --network dans docker) et capturer le traffic sur cette interface.

## Problème 2 :

Lancer firefox dans cause l'emission d'un certain nombre de requêtes DNS qu'il est difficile de différencier de celles dont l'emission a été déclenchée par le chargement de la page cible.

### Solution :

Lancer une instance de firefox, puis après le lancement, déclencher en ligne de commande le chargement de la page cible => pas forcément nécessaire, il peut être intéressant de constater si c'est à ce moment la que firefox initie (et maintient ouvert) la connexion au resolver.

## Problème 3 :

Créer des profils pour sauvegarder les paramètres de firefox (DoH / pas DoH), mais créer des profils requiert un accès à la GUI de firefox. Les créer dans le firefox de la machine locale et les bind dans le conteneur ne fonctionne pas, firefox se plaint que les profils ont été crées avec une version incompatible de firefox.

### Solution :

Donner à firefox l'accès au serveur X en passant les variables d'env DISPLAY et XAUTHORITY en arg au conteneur via le flag -e, et en bindant la socket X11 dans le conteneur (-v /tmp/.X11-unix/:/tmp/.X11/unix).

# Protocole

Le but est d'observer pendant combien de temps un client DoH conserve une connexion TCP ouvert vers un resolver.

Afin de mesurer ce temps, on mesure le nombre de connexions TCP ouvertes vers le resolver au cours d'une session ou on ouvre 2 pages web distinctes, séparées d'un temps arbitraire.

On répète les mesures en augmentant progressivement le temps entre les ouvertures de pages, en réinitialisant le client entre chaque mesure, afin de faire disparaitre les effets du cache coté client.

Dans le cas de firefox, on ouvre une session de firefox dans un conteneur docker (afin de capturer uniquement les paquets proveneant de firefox), puis on ouvre une page puis une autre. On tue le conteneur, arrète la capture et recommence (incrément et nombre d'itérations configurables).

# TODO

- itérer, et créer plusieurs sous dossiers de résultat (capture + keylog) en fonction de l'itération => DONE

- getopt pour les options nécessaires => DONE
Liste des options :

echo "Usage: $0 [ -e RESET (if set, deletes and restore the firefox profile.) ] [ -d XDISPLAY ] [ -s X11_SOCKET ] [ -n DOCKER NETWORK ] [ -f FIREFOX PROFILES ROOT DIR ] [ -p FIREFOX PROFILE NAME] [ -r RESOLVER IP (cidr notation) ] [ -t NUMBER OF ITERATIONS ] [ -i INITIAL WAIT TIME ] [ -c INCREMENT (first character is parsed as operator, remaining characters are parsed as operands ]"

- faire une image pour dnscrypt-proxy et appliquer le même principe
  - deuxième script ?
  - même script mais avec une syntaxe en mode executable commande [options] (comme pour tar par exemple) avec commande =~ firefox|kdig|dnscrypt-proxy*|flamethrower

Personellement je préfère la deuxième solution, elle prendra pas non plus beaucoup plus de temps à implémenter, il s'agit juste de diviser un peu plus le code

- Plot les données => gnuplot OU je réécris tout en python et j'utilise matplotlib
  - Pour python : la syntaxe me parait plus claire, sans doute des API pour controller docker, firefox et faire de l'analyse de paquets => en bref me permet de faire un truc plus propre et plus évolutif et je connais plus matplotlib que gnuplot
  - contre python => il faut tout réimplémenter et je ne sais pas à quel point je perds certaines fonctionnalités de bash, MAIS plus portable (je dois avoir un nombre de bash built-ins...)
  - Pour bash => déjà écrit, quand même relativement adapté
  - contre bash => je connais pas gnuplot, plus difficile à faire évoluer