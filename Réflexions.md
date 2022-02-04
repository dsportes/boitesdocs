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
