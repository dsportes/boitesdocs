# Maîtrise du volume des secrets : quotas

Aucun compte, aucun administrateur ne peut connaître la liste des comptes et de leurs avatars ni n'a de pouvoir pour _bloquer_ un compte ou le dissoudre. 

Sans instauration de quotas par compte, n'importe quel compte pourrait créer autant de secrets qu'il veut et saturer l'espace physique au détriment des autres. C'est pour cela que chaque compte dispose de _quotas_ de volume de secrets.

Ce contrôle s'effectue à deux niveaux :
- le contrôle du volume de secrets créés par mois.
- le contrôle du volume des secrets permanents.

On distingue :
- le volume des secrets eux-mêmes : un montant forfaitaire par secret plus la taille de son texte.
- le volume des pièces jointes (_gzippées_ ou non selon leur type MIME).

Il y des quotas :
- **par avatar**, attribués :
    - par le parrain à la création du compte,
    - réattribués par un autre compte sur ses quotas personnels,
    - réattribués depuis les quotas d'un groupe par un animateur, en particulier lors de son archivage ou sa dissolution.
- **par groupe**, attribués par les membres du groupe sur leur propres quotas.

Un quota comporte 4 chiffres : 
- le volume maximal autorisé des secrets permanents.
- le volume maximal autorisé des pièces jointes pour les secrets permanents,
- le volume maximal autorisé des secrets **créés** chaque mois.
- le volume maximal autorisé des pièces jointes **créées** chaque mois.

## Banque centrale des quotas
La _Banque centrale_ dispose de quotas définis par l'administrateur de l'hébergement en fonction des ressources techniques dont il dispose.

Normalement l'attribution de quotas à un avatar ou à un groupe se fait par transfert de quotas déjà attribués à un autre avatar ou groupe.

Toutefois un compte qui connaîtrait la clé du _Grand Argentier_ peut y prélever des quotas pour les attribuer à un avatar ou un groupe sans prendre sur les siens : ceci décrémente d'autant les quotas disponibles de la _banque centrale_.

La disparition d'un compte ou d'un avatar ou d'un groupe rend ses quotas à la _Banque centrale_.

## Quotas mensuels de volume de secrets créés
Un avatar ne peut pas créer plus de secrets par mois que ses quotas ne l'autorisent.
- le décompte est mis à 0 à chaque début de mois.
- une création de secrets incrémente les volumes créés du mois.
- une mise à jour incrémente ces volumes si la mise à jour est une expansion.
- une alerte orange puis rouge apparaît à l'approche des limites des quotas ou à son dépassement.
 
## Quotas de volume de secrets permanents
Quand un secret devient permanent, le volume permanent du compte ou du groupe est incrémenté et ne peut pas dépasser les quotas permanents. Les volumes changent,
- par mise à jour du secret (augmentation ou réduction),
- par suppression du secret.

_Toutefois_, un volume permanent peut _temporairement_ excéder le quota autorisé pour un avatar, quand ceci résulte de l'action d'un autre avatar. Exemple :
- le secret permanent d'un couple A-B est mis à jour en expansion par B (sans dépasser les quotas de B),
- mais ceci lui fait dépasser le volume maximal de A : la mise à jour est acceptée pour ne pas bloquer B. Toutefois A devra ultérieurement supprimer des secrets permanents, ou augmenter ses quotas.

## Contrôle éthique
A partir du moment où un compte respecte ses quotas il est impossible à une quelconque autorité de le détruire. Les textes des secrets lui sont strictement privés et peuvent en conséquence être _éthiquement incorrects_ au regard d'autres personnes ou organisations. Ce concept est relatif, l'éthique pour l'un pouvant être anti-éthique pour un autre.

Toutefois :
- si un avatar A partage avec B des secrets que B considère comme non acceptables, quelqu'en soit la raison, B peut déclarer ne plus rien partager avec A.
- dans la cadre d'un groupe, un animateur peut résilier un membre du groupe et chacun peut s'auto résilier.

Bref nul n'est obligé de lire des secrets qu'il ne juge pas acceptables.

**L'application est agnostique vis à vis des contenus des secrets** qui peuvent être n'importe quoi, en bien ou en mal ... et selon ce que chacun considère comme bien ou mal: c'est une application qui reste du niveau de la communication / mémorisation **personnelle et/ou privée**, comme celle que peut avoir un groupe restreint d'amis discutant librement entre eux dans un domicile privé.  
C'est aussi pour cette raison qu'un groupe a une taille limitée, telle qu'il soit raisonnable qu'il est un groupe non public, et où tout le monde se connaît et a été coopté.

> Ce n'est pas une application _libertaire_ mais _privée_. Être libertaire supposerait un accès public sans restriction ce qui n'est pas le cas.

### Décompte des volumes des secrets et des pièces jointes
**Activité** : texte des secrets `vm1`, pièces jointes `vm2`
- il traduit l'activité sur les secrets en décomptant les **volumes écrits** des secrets et de leurs pièces jointes. Que le secret croisse ou décroisse en volume absolu, c'est de l'activité d'écriture. La suppression d'une pièce jointe n'est pas comptée comme activité, sa mise à jour oui.
- l'activité est décomptée sur l'avatar qui l'exerce.

**Volume** : texte des secrets `v1`, pièces jointes `v2`
Le volume occupé par les secrets est décompté en variation _en plus ou en moins_ à chaque mise à jour du texte ou d'une pièce jointe :
- sur l'avatar de l'auteur pour un secret personnel,
- sur les deux avatars du couple pour un secret de couple.
- sur le groupe pour un secret de groupe.

# Maîtrise des ressources

## Ligne de crédit
Une ligne de crédit à un **numéro tiré au hasard** et correspond à un compte.
- elle donne l'identifiant **d'un forfait** parmi ceux prédéfinis pour l'organisation. 
  - si par convention cet identifiant est absent, le compte correspondant est _sans forfait_ et ne peut plus accéder à l'application.
- une limite de validité facultative : le forfait peut être permanent ou limité dans le temps.

### Forfait
Un forfait fixe 4 limites :
- `max1` : volume maximal total des textes des secrets mémorisés.
- `max2` : volume maximal total des pièces jointes aux secrets mémorisés.
- `maxops` : nombre maximal d'opérations de mises à jour de secrets sur une période d'une semaine.
- `maxnet` : volume maximal total des pièce jointes échangées sur le réseau (upload / download) sur une période d'une semaine.

>Pour savoir si une limite applicable à une semaine est atteinte, on cumule la consommation effective de la semaine précédente et celle de la semaine en cours et on regarde si elle dépasse 2 fois la limite hebdomadaire du forfait. 

>Une organisation qui souhaiterait valoriser en unités monétaires le coût d'utilisation / immobilisation de ressources de son application n'a plus qu'à appliquer la formule de conversion de son choix depuis ces limites pour en donner un coût.

### Activités des avatars d'un compte
Tous les avatars du même compte ont la même ligne de crédit : celle-ci enregistre à tout instant l'activité des avatars du compte relative aux secrets de ses avatars :
- `vol1` : volume total occupé par les textes des secrets à l'instant t.
- `vol2` : volume total occupé par leurs pièces jointes à l'instant t.
- `opsP` : nombre d'opérations effectuées la semaine précédente.
- `opsC` : nombre d'opérations effectuées la semaine courante.
- `netP` : volume maximal total des pièces jointes échangées sur le réseau la semaine précédente.
- `netC` : volume maximal total des pièces jointes échangées sur le réseau la semaine courante.
- `sem` : le numéro de la semaine _courante_ considérée ci-avant. Chaque opération saura ainsi gérer la répartition entre semaine courante / précédente et déterminer si la limite hebdomadaire a été atteinte.

La ligne de crédit courante est :
- obtenue sur demande par le compte,
- retournée en résultat de chaque opération sur un secret, qu'elle soit acceptée ou refusée par dépassement de limite.

## Administrateur comptable de l'organisation
Il peut se connecter en utilisant un des quelques mots de passe enregistrés dans la configuration de l'application. Il peut :
- attribuer un des forfaits prédéfinis à une ligne de crédit.
- retirer ce forfait, c'est à dire bloquer une ligne de crédit.
- consulter la liste des lignes de crédit.

Les mises à jour notent dans la ligne de crédit le numéro du mot de passe qui a été employé afin de permettre un audit sommaire éventuel (qui a fait quoi).

### Exemples de mise en œuvre
#### Organisation connaissant ses membres
L'organisation est capable de relier un identifiant de ligne de crédit à un membre de l'organisation et en conséquence de lui attribuer selon son rôle un forfait adapté à ce rôle.

Le _coût_ supporté l'est globalement par l'organisation **mais** elle sait sur qui il a été réparti.

L'organisation n'a aucun moyen de corréler l'identifiant de la ligne de crédit avec des avatars : elle ne peut en rien accéder aux secrets, ni aux contacts / groupes, etc. donc ne peut pas juger du caractère plus ou moins _éthiques_ de ceux-ci.

Un membre souhaitant une évolution de son forfait doit le demander à l'organisation dont un des administrateurs comptables pourra effectuer l'opération.

#### Organisation purement commerciale
Le titulaire d'un compte fait parvenir à la comptabilité de l'organisation des virements portant l'identifiant de sa ligne de crédit. 

Un des comptables met à jour la ligne de crédit correspondante avec une limite de validité correspondant au montant du virement reçu et au niveau du forfait souhaité.

>Les virements _pouvant_ être obscurs ou faits par un intermédiaire, il peut être très difficile de corréler une personne physique ou morale à une ligne de crédit et complètement impossible ensuite de savoir quels avatars et secrets en sont dépendants.

## Disparition des comptes *sans forfait*
Un compte *sans forfait* ne peut pas se connecter : si la situation se prolonge, il sera classé en _disparu_ et ses ressources supprimées.

La seule sortie possible est d'obtenir de l'administrateur comptable une extension de limite et/ou l'attribution d'un forfait.
- dans une organisation _connaissant ses membres_, c'est à l'organisation de définir si les lignes de crédit ont une limite ou non et si tel membre doit ou non continuer à accéder au site de l'organisation.
- dans une organisation _commerciale_, c'est selon les règles contractuelles en vigueur que l'administrateur attribuera ou non un forfait minimal (ou aucun) en cas de défaut de paiement plus ou moins prolongé.

### Approches et atteintes des limites :
- elle est signalée à la connexion et est rappelée à chaque fois que la situation s'aggrave.
- l'atteinte de la limité `maxnet` empêche l'accès aux pièces jointes mais pas les autres opérations.
- l'atteinte de la limité `maxops` bloque le compte en lecture seule (sans mise à jour du texte des secrets).
- toutefois par construction ces deux limites sont relâchées en début de chaque semaine.
- l'atteinte des limites de volume bloque respectivement la création de nouveaux secrets et leur mise à jour en expansion pour `max1` et celle des pièces jointes pour `max2`.
- toute action de _nettoyage_ relâche, plus ou moins, ces limites.

>Un forfait **minimal** n'est pas une absence de forfait : le compte peut lire les secrets (mais plus les pièces jointes a priori mais cela dépend du `maxnet` du forfait minimal en question).

## Groupes

## Création de compte
