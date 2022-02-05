# Maîtrise du volume des secrets : quotas

Aucun compte, aucun administrateur ne peut connaître la liste des comptes et de leurs avatars ni n'a de pouvoir pour _bloquer_ un compte ou le dissoudre. 

Sans instauration de quotas par compte, n'importe quel compte pourrait créer autant de secrets qu'il veut et saturer l'espace physique au détriment des autres. C'est pour cela que chaque compte dispose de _quotas_ de volume de secrets.

## Ligne de crédit
Une ligne de crédit à un **numéro tiré au hasard** associé à un compte à sa création.
- elle donne les 3 compteurs ci-dessous définissant le forfait applicable.
- la date limite de validité facultative : le forfait peut être permanent ou limité dans le temps.

Chaque compte a **deux types de lignes de crédit** :
- **celle, unique, personnelle** dont le numéro ne sera jamais connu des autres.
- **celles, aucune, une ou plusieurs, qui sont associée chacune à un ou plusieurs groupes qu'il a créés, ou dont il a repris la charge**. Chaque ligne _de groupe_ a un forfait `max1 / max2` (pas de `maxt`, elle ne supporte pas de trafic). Ce numéro de ligne est connu des membres des groupes à laquelle elle a été affectée mais empêche de retrouver celle contrôlant le forfait personnel du membre qui supporte l'hébergement du groupe.

### Forfait d'une ligne de crédit
Il fixe 3 limites :
- `max1` : volume maximal total des **textes** des secrets.
- `max2` : volume maximal total des **pièces jointes** aux secrets.
- `maxt` : volume maximal total du **trafic réseau sur une semaine** :
  - des pièces jointes échangées (upload / download).
  - des textes des secrets téléchargés en début de session.
  - des textes des secrets mis à jour.

>Pour savoir si la limite applicable à une semaine est atteinte, on cumule la consommation effective de la semaine précédente et celle de la semaine en cours et on regarde si elle dépasse 2 fois la limite hebdomadaire inscrite au forfait. 

>Une organisation qui souhaiterait valoriser en unités monétaires le coût d'utilisation / immobilisation de ressources de son application n'a plus qu'à appliquer la formule de conversion de son choix depuis ces limites pour en donner un coût monétaire.

### Activités des avatars d'un compte
Tous les avatars du même compte ont la même ligne de crédit qui enregistre à tout instant l'activité des avatars du compte relative aux secrets de ses avatars.

La date-heure `t` indique quand la ligne a été calculée / mise à jour. Elle permet de recalculer lors d'une mise à jour à l'instant `t + x` :
- les moyennes hebdomadaires des volumes 1 et 2 sur la semaine précédente et la semaine en cours,
- le total hebdomadaire du trafic réseau sur la semaine précédente et la semaine en cours.

Les compteurs suivants sont mis à jour et/ou recalculés à chaque mise à jour :
- `v1` : volume total occupé par les textes des secrets à l'instant t.
- `v2` : volume total occupé par leurs pièces jointes à l'instant t.
- `mv1p mv1c` : moyenne de v1 sur la semaine précédente et courante.
- `mv2p mv2c` : moyenne de v2 sur la semaine précédente et courante.
- `trp` : volume total du transfert réseau des secrets sur la semaine précédente.
- `trc` : volume total du transfert réseau des secrets sur la semaine courante.
- `tal` : taux d'alerte entre 1% et 99%. Une ligne est en alerte quand l'un de ses compteurs excède n% du maximum prévu au forfait. Ceci définit un niveau de _réserve_.

Les lignes de crédit d'un compte (personnelle et de groupe) sont affichables en session de ce compte sur demande.

La ligne impliquée dans une opération sur un secret est retournée à la fin de l'opération. Quand le secret concerné est un secret de groupe, il y a deux lignes, a) celle du compte qui a demandé l'opération; b) celle du groupe cible. Ceci permet à chaque opération d'afficher une alerte éventuelle d'approche d'insuffisance de crédit, voire de dépassement.

### Contraintes imposées par les limites du forfait
#### max1 / max2
- Il n'est pas possible de créer un secret ou de mettre à jour un secret en extension qui impliquerait le dépassement de volume instantané v1 au delà de max1.  
- Il n'est pas possible de créer une pièce jointe ou de mettre à jour en extension une pièce jointe qui impliquerait le dépassement de volume instantané v2 au delà de max2.
- La suppression d'un secret ou d'une pièce jointe est toujours possible ainsi que leur remplacement par un nouveau texte plus petit.

#### maxt
En début de session il s'opère un chargement des secrets en mémoire, soit intégralement (mode _incognito_) soit incrémentalement des seuls changements depuis la fin de la session précédente sur le poste en mode _synchronisé_.
- le chargement des textes des secrets est décompté mais ne provoque pas d'erreur en cas de dépassement de maxt.
- le (re)chargement des pièces jointes disponibles localement n'est pas effectué s'il aboutit à dépasser `maxt` (ou si `maxt` est déjà dépassé).

En cours de session la création d'un secret ou la mise à jour en expansion de son texte n'est pas possible si elle conduit à un dépassement de `maxt` ou que maxt est déjà dépassée, de même vis à vis d'une pièce jointe (upload).

La lecture (download) d'une pièce jointe est également impossible si elle conduit à dépasser cette limite.

L'upload sur disque local des textes des secrets sélectionnés est possible dans tous les cas mais le cas échéant pas de leurs pièces jointes quand ça aurait conduit à dépasser `maxt`.

>Il est en conséquence toujours possible de se connecter et de consulter les secrets (pas leurs pièces jointes) en cas dépassement de `maxt`.

>L'objectif est d'éviter que la bande passante ne soit réduite par quelques comptes effectuant des téléchargements fréquents de tous leurs secrets accessibles, pièces jointes incluses.

### Secrets personnels
Leurs volumes v1 / v2 sont imputés sur la ligne de crédit du compte.

Le volume en transfert est imputé au compte (chargement initial, création / mise à jour, download).

### Secrets de couple
Le volume en transfert est imputé au compte qui le demande (chargement initial, création / mise à jour, download).

Les variations de volumes v1 et v2 sont imputés au compte demandeur de la mise à jour / création (en plus ou en moins).

>Dans le couple formé par deux avatars en contact, l'un ne connaît pas le numéro de ligne de crédit de l'autre.

### Secrets de groupe
Le volume en transfert est imputé au compte qui le demande (chargement initial, création / mise à jour, download), pas au groupe.

A la création d'un groupe,
- sa ligne de crédit est celle du compte créateur (sur une ligne _groupe_, pas sur la ligne  _personnelle_),
- le compte fixe deux limites `max1 / max2` applicables aux volumes v1 et v2 des secrets du groupe.

Un membre animateur peut s'attribuer la ligne de crédit du groupe :
- il impute sur sa ligne de crédit les volumes actuels v1 et v2 occupés par les secrets du groupe et leurs pièces jointes ce qui re-crédite d'autant la ligne antérieure.
- il peut alors modifier les limites `max1 / max2` du groupe.

Le compte dont la ligne de crédit est celle du groupe peut la retirer : **le groupe n'a plus de ligne de crédit associée**. 
- l'accès à ses secrets est suspendu jusqu'à ce qu'un animateur y mette la sienne.
- le cas échéant le groupe n'étant plus accédé va finir par s'auto-dissoudre au bout d'un certain temps.

Dans l'entête du groupe le numéro de la ligne de crédit est crypté par la clé du groupe.

## Administrateurs comptables de l'organisation
Ils peuvent se connecter en utilisant un des quelques mots de passe enregistrés dans la configuration de l'application (ce qui les identifie a minima pour audit). Ils peuvent :
- attribuer un des forfaits prédéfinis à une ligne de crédit.
- retirer ce forfait, c'est à dire bloquer une ligne de crédit.
- consulter la liste des lignes de crédit.

Les mises à jour notent dans la ligne de crédit le numéro du mot de passe qui a été employé afin de permettre un audit sommaire éventuel (qui a fait quoi, quand).

### Échanges textuels courts entre l'administrateur et les titulaires des comptes
Ces conversations sont enregistrées par ligne de crédit avec pour chaque échange :
- sa date-heure,
- qui l'a émis (le compte ou un des administrateurs repéré par son numéro de mot de passe),
- son texte de moins de 140 signes.

La conversation conserve dans l'ordre chronologique inverse,
- ceux ayant moins de 6 semaines,
- au plus les 20 derniers.

C'est par ce moyen que le titulaire d'un compte peut communiquer a minima avec les administrateurs en particulier pour leur demander un accroissement de ses crédits (personnels / de groupe).

>Un compte peut toujours réduire de lui-même son crédit.

### Niveau d'alerte d'une ligne de crédit
Ce niveau en pourcentage permet au compte (et aux administrateurs) de savoir si l'activité approche des niveaux de blocage.
- c'est un pourcentage applicable au forfait.
- si ce niveau est bas, par exemple 10%, ça signifie que le compte dispose d'une **réserve** de 90%.
- ce taux de 1 à 99 est inscrit sur la ligne de crédit.

Un compte qui en parraine un autre doit puiser un certain pourcentage de son forfait pour le prêter / donner à son filleul et lui permettre de démarrer sans intervention a priori d'un administrateur. Il est _convenable_ que le filleul rende à son parrain les crédits qu'il a reçu, mais rien ne l'y oblige.

### Réduction de forfait par un administrateur
Selon la politique de l'organisation, un administrateur peut être moralement / éthiquement habilité à réduire un forfait ayant une réserve importante.

### Suppression du forfait d'une ligne de crédit
La suppression du forfait, _pas la mise d'un forfait minimal mais existant_,
- **bloque l'accès au compte** si c'est une ligne _personnelle_. Le compte ne peut plus accéder à ses données, seulement échanger des textes courts avec les administrateurs comptables.
- **si c'est une ligne de groupe, bloque les accès à tous les groupes reliés à cette ligne**.

Un compte peut regonfler un forfait minimal d'une de ses lignes en prélevant sur une des autres autres qu'il lui appartiennent. Ceci n'est pas possible si le forfait est annulé, signe de blocage par l'administrateur comptable.

A la connexion à son compte, une session marque _un signe de vie_ sur toutes ses lignes de crédit (avec un jour de signature aléatoire dans les N dernières semaines) : ceci permet aux administrateurs de détecter les lignes de crédit _inactives_ correspondant à des comptes disparus (ne se servant pas de l'application depuis plus d'un an) et d'affecter des ressources à d'autres.

>Les comptes, avatars, groupes ont aussi leurs signatures d'activité afin de détecter l'inactivité des comptes et l'inutilité de conserver du volume pour garder des données qui ne seront plus accédées.

### Exemples de mise en œuvre
#### Organisation ayant un objet et connaissant ses membres
L'organisation supporte le _coût_ d'hébergement de l'application et ses membres l'utilisent pour supporter l'objet de l'organisation, son but social et / ou politique.

L'organisation est capable de relier toute ligne de crédit personnelle à un de ses membres et ses administrateurs peuvent en conséquence leur attribuer un forfait adapté au rôle de chacun.

L'organisation n'a aucun moyen de corréler l'identifiant de la ligne de crédit avec des avatars : elle ne peut en rien accéder aux secrets, ni aux contacts / groupes, etc. donc ne peut pas juger du caractère plus ou moins _éthiques_ de ceux-ci.

Un membre souhaitant une évolution de son forfait doit le demander à l'organisation dont un des administrateurs comptables pourra effectuer l'opération.

>Dans cette situation les lignes de crédit sont _plutôt_ sans dates limites, mais ça peut avoir un sens d'en mettre et de procéder périodiquement à la réévaluation des forfaits.

##### Contrôle éthique
Normalement les membres de l'organisation utilisent l'application pour servir les objectifs de l'organisation. Un administrateur ne peut jamais lire le contenu des secrets : il peut certes bloquer des lignes de crédit, mais à quel titre ?
- supposons un avatar A partageant avec B des secrets que B considère comme contraire à l'objet de l'association. B n'a pas accès au numéro de ligne de crédit de A et ne peut donc pas demander à un administrateur de la désactiver. Tout ce que B peut faire est de cesser le partage de secrets avec A.
- supposons un groupe G où se partagent des secrets résolument externes, voire contraires, à l'objet de l'organisation. 
  - un animateur du groupe peut résilier un membre perturbateur (s'il n'est pas animateur).
  - le numéro de ligne de crédit du groupe est connu des membres qui peuvent demander à un administrateur comptable de supprimer le forfait de cette ligne : ceci bloquera les accès en lecture.
  - n'importe quel animateur peut aussi changer la ligne de crédit du groupe, mais surtout rien n'empêche de reconstituer un autre groupe, de récupérer les textes des secrets et leurs pièces jointes et d'y inviter ... presque tous les membres de l'ancien.

>Le pouvoir d'exclusion d'une telle organisation est restreint du fait de l'impossibilité de connaître les avatars. Toutefois l'organisation a au moins la possibilité d'inhiber les lignes de crédits des membres quittant l'organisation et d'éviter ainsi de continuer à héberger gratuitement pour eux ceux qui la quitte.

#### Organisation agnostique, purement _commerciale_
Le titulaire d'un compte d'une telle organisation fait parvenir à la comptabilité de l'organisation des virements portant l'identifiant de sa ligne de crédit. 

Un des comptables met à jour la ligne de crédit correspondante avec une limite de validité correspondant au montant du virement reçu et au niveau du forfait souhaité.

>Les virements _pouvant_ être obscurs ou faits par un intermédiaire, il peut être quasi impossible de corréler (avec des moyens légaux) une personne physique ou morale à une ligne de crédit. In fine il est toujours complètement impossible ensuite de savoir quels avatars et secrets lui sont associés.

Une telle organisation n'est pas obligatoirement à but lucratif : elle peut simplement proposer un service d'hébergement qui sera maintenu **tant que les comptes supportent effectivement la juste part** des coûts d'hébergement.

**L'application est agnostique vis à vis des contenus des secrets** qui peuvent être n'importe quoi, en bien ou en mal ... et selon ce que chacun considère comme bien ou mal: c'est une application qui reste du niveau de la communication / mémorisation **personnelle et/ou privée**, comme celle que peut avoir un groupe restreint d'amis discutant librement entre eux dans un domicile privé.  
C'est aussi pour cette raison qu'un groupe a une taille limitée, telle qu'il soit raisonnable de juger qu'il n'est pas public, et où tout le monde en contact se connaît et a été coopté.

>Ce n'est pas une application _libertaire_ mais _privée_. Être libertaire supposerait un accès public sans restriction ce qui n'est pas le cas.

> Une organisation ayant un objet précis pourrait aussi parfaitement se doter d'une application du modèle agnostique purement comptable, c'est à dire renonçant à tout tentative de contrôle éthique : elle _paierait_ périodiquement l'accès à ses membres tant qu'ils sont membres et ne les exclueraient (ou pas) quand ils la quittent, mais assurément sans continuer de financer leur participation.

## Disparition des comptes *sans forfait*
Un compte *sans forfait* ne peut se connecter que pour dialoguer avec un administrateur de l'organisation.

Si la situation se prolonge, il sera classé en _disparu_ et ses ressources supprimées.

La seule sortie possible est d'obtenir de l'administrateur comptable l'attribution d'un forfait.
- dans une organisation _connaissant ses membres_, c'est à l'organisation de définir si les lignes de crédit ont une limite ou non et si tel membre doit ou non continuer à accéder au site de l'organisation.
- dans une organisation _commerciale_, c'est selon les règles contractuelles en vigueur que l'administrateur attribuera ou non un forfait minimal (ou aucun) en cas de défaut de paiement plus ou moins prolongé.

### Approches et atteintes des limites :
- elle est signalée à la connexion et est rappelée à chaque fois que la situation s'aggrave.
- l'atteinte de la limité `maxt` empêche l'accès aux pièces jointes mais pas les autres opérations. Toutefois par construction cette limite est relâchée en début de chaque semaine.
- l'atteinte des limites de volume bloque respectivement la création de nouveaux secrets et leur mise à jour en expansion pour `max1` et celle des pièces jointes pour `max2`.
- les actions de _nettoyage_ (réduction) sont possibles car elles tendent à relâcher, plus ou moins, ces limites.

>Un forfait **minimal** n'est pas une absence de forfait : le compte peut lire les secrets (mais plus les pièces jointes a priori mais cela dépend du `maxt` du forfait minimal en question).

## Création de compte
### Compte parrainé
Le parrain prélève un pourcentage de son choix sur son forfait : ceci permet au filleul un démarrage avec une ligne de crédit existante.  
Le parrain fixe aussi une date de validité (éventuellement) mais qui ne peut pas être plus lointaine que la sienne.

### Compte non parrainé
Le compte a un pouvoir d'administrateur (il connaît un des mots de passe) et peut se créer lui-même sa ligne de crédit.

>Un compte connaissant un de ces mots de passe a la possibilité de se définir le niveau de forfait qu'il veut pour lui-même, dans la limite toutefois du maximum inscrit à la configuration du déploiement (c'est une sécurité contournable, pour gentlemen).

## Analyse statistique
L'ensemble des lignes de crédit peuvent être téléchargées par un administrateur dans un tableur pour analyse globale et pouvoir détecter la marge de manœuvre dont il dispose pour gérer le site.

### Historisation
Depuis un tel extrait, il est possible, par un traitement externe, de construire et de maintenir un historique donnant les évolutions des lignes de crédit sur une période longue.
