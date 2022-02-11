# Maîtrise des ressources utilisées par les comptes
## Présentation de la problématique
**L'hébergement de l'application a un coût récurrent** : même quand le coût effectif est  _sponsorisé_ par l'organisation qui la met en œuvre, il se pose deux questions :
- qui y a accès et peut en profiter,
- comment maîtriser la consommation de ressources correspondantes.

**Pour créer un compte il faut être parrainé** : en se limitant à ce principe, le parrain n'a aucun moyen de contrôler l'usage que fait son filleul de son compte, ni si celui-ci devient parrain d'autres invités. Le rôle de _parrain_ doit être régulé de manière à contribuer au contrôle de l'usage des ressources.

**Si l'organisation ne sponsorise pas en totalité les coûts d'hébergement**, elle se pose forcément la question de récupérer des comptes le part du coût global qui leur incombe.

#### Sponsoring publicitaire
Le cryptage des données est tel qu'une valorisation publicitaire est improbable : aucun ciblage ne peut être fait et bien peu de _business models_ s'équilibrent par de la publicité _non profilée_. Mais, même au cas bien improbable où des ressources publicitaires seraient envisagées, il faudrait pouvoir établir qu'il existe une audience réelle et non pas qu'un tout petit nombre d'utilisateurs monopolisent la quasi totalité des accès.

#### Maîtriser l'utilisation des ressources
Si les comptes étaient laissés libres de créer autant de secrets et de pièces jointes que voulu sans limitation, l'application pourrait être saturée et inutilisable pour la majorité de ses comptes _raisonnables_ du fait de l'utilisation _déraisonnable_ de quelques uns. 

Même une organisation très limitée de quelques membres pourraient être paralysée suite à une invitation imprudente.

Afin de protéger la confidentialité des secrets, il n'y a pas de _méta-données_ en clair dans la base de données permettant à un traitement d'administration de connaître les comptes utilisant beaucoup de ressources, ni aucun moyen de les bloquer. 

>Un mécanisme de _contrainte_ dans l'utilisation des ressources est nécessaire, les comptes devant pouvoir être contenus en cas d'inflation des secrets au delà des contraintes fixées.

>Un mécanisme de _comptabilisation_ des consommations de ressources, doit permettre, soit de reporter la charge sur les comptes, soit pour valoriser une audience de justifier que ses usagers sont bien ceux qui étaient ciblés.

#### Coûts d'hébergement
Les coûts / contraintes d'hébergement ont été classés pour simplifier en trois catégories :
- l'espace `v1` utilisé en _base de données_,
- l'espace `v2` utilisé en _espace de fichiers_ (ou _object storage_),
- le volume `tr` transféré sur le réseau.

>Le coût de calcul n'a pas été pris en compte directement : l'application n'a pas vraiment de calculs, hormis ceux nécessaires à lire et mettre à jour des secrets. Cette activité étant toujours associée à des transferts sur le réseau, le coût de calcul a été implicitement intégré dans le coût réseau.

**Hormis l'accès aux secrets**, l'application a très peu de charge de calcul et d'occupation d'espace pour gérer les contacts, les participation aux groupes, etc. D'où le principe de se ramener à une unique unité d'œuvre : le **stockage des secrets, textes et pièces jointes et leur transfert sur le réseau**.

#### Capacités et consommations
- La _capacité_ est la _possibilité de_, par exemple stocker des pièces jointes : elle s'exprime comme un plafond, par exemple un volume maximal.
- La _consommation_ est le volume réellement utilisé.

## Options de mise en œuvre
### Volume v1 et v2
La _contrainte_ d'un plafond est simple à comprendre et à mettre en œuvre : les opérations menant à un dépassement du plafond (création de secrets / pièces jointes et mises à jour en expansion) retournent une erreur.

**Le principe est de définir des _forfaits_ de volumes :**
- leur dépassement ponctuel est bloqué.
- le coût mensuel n'est pas basé sur le volume effectif consommé mais sur le _forfait_, le plafond possible.
- la mesure des volumes effectifs à deux intérêts :
  - montrer que celui-ci est correctement calculé et baisse ou monte selon les actions effectués.
  - permettre d'ajuster le niveau de _forfait_ utile, l'augmenter si on est proche du plafond ou l'abaisser.

>**Le coût _monétaire_ unitaire du Mo (méga-octet) de volume v1 est environ 10 fois celui du volume v2.**

Quelques forfaits v1 / v2 sont prédéfinis et portent un code simple auquel est associé un volume : la liste est enregistrée dans la configuration de l'installation.

### Le volume transféré sur le réseau
- il est beaucoup moins simple à percevoir.
- il est sujet à des pointes importantes : le téléchargement d'une sélection de secrets et de ses pièces jointes mobilise intensivement du transfert mais sur une période de temps courte.
- le fonctionnement _normal_ n'est pas particulièrement critique : les comportements de téléchargements systématiques et lourds le sont.

#### Volume de transfert associé aux textes des messages
- il est très corrélé au volume v1 de ceux-ci.
- le comportement qui l'influence est marginal : taux de mise à jour, fréquence des ouverture de sessions en mode _incognito_ ...

Compte tenu des bandes passantes actuelles, l'option est de ne pas le limiter ni même de le décompter : son _coût_ est intégré dans celui du volume v1.

#### Volume de transfert associé aux pièces jointes
- il peut être important.
- de manière normale un compte ne lit pas toutes ses pièces jointes tous les jours, mais il peut avoir un comportement de sécurité l'amenant à faire des téléchargements massifs sur disque local.
- pour un même volume v2 de pièces jointes, deux comptes peuvent avoir des comportements très contrastés et des volumes de transfert très différents.

>**Le coût _monétaire_ d'un Mo transféré sur le réseau équivaut au coût mensuel de son stockage.** Mais d'ordinaire chaque mois il n'est lu / modifié qu'une faible proportion des pièces jointes stockées ... sauf si on télécharge massivement systématiquement.

**Principes retenus**
- il n'y a pas de plafond impératif de transfert mensuel de volume v2.
- le cumul du volume des transfert des pièces jointes est mémorisé sur les 31 derniers jours : plus il approche puis dépasse le volume v2, plus des temporisations (explicitées à l'écran) ralentissent _artificiellement_ le débit.
- le volume mensuel est mémorisé en historique pour information.

>Ce procédé gêne les téléchargements massifs, mais impacte peu la lecture / mise à jour courante des pièces jointes.

### Comptes et lignes comptables
**Chaque compte reçoit à sa création une _ligne comptable_** : son identifiant est celui du compte ce qui ne permet pas d'établir de lien avec l'activité du compte qui passe par ses avatars. 

La _ligne comptable_ est un enregistrement des données des forfaits et de l'historique de suivi.

### Gestion des secrets des groupes
- un groupe est _hébergé_ par le compte d'un de ses membres (qui peut changer), son _hébergeur_.
- un groupe dispose de compteurs `max1 / max2` fixés par son compte hébergeur et les volumes `v1 / v2` des secrets du groupe à l'instant t.

>La mise à jour d'un secret d'un groupe entraîne la mise à jour : a) éventuellement de la ligne comptable du compte du demandeur pour le volume v2 transféré, b) de la ligne comptable du compte hébergeur du groupe pour les volumes v1 et v2, c) du groupe lui-même pour les volumes effectivement occupés.

La ou les deux lignes comptables impactées dans une opération sur un secret de groupe sont retournée en résultat de l'opération, ce qui est particulièrement utile si l'opération a échoué en raison de forfaits insuffisants (sur une ligne et / ou au niveau du groupe).

#### Changement _du compte hébergeur_ d'un groupe
Un membre animateur (auteur s'il n'y a plus d'animateurs) peut se déclarer _hébergeur_ du groupe en inscrivant son numéro de ligne de crédit à la place de celle actuelle :
- il débite sa ligne comptable des volumes actuels `v1` et `v2` occupés par les secrets du groupe et leurs pièces jointes et crédite d'autant la ligne comptable actuelle.
- il peut alors modifier les limites `max1 / max2` du groupe.

Le compte _hébergeur_ peut se retirer du groupe : **le groupe n'a plus d'hébergeur**. 
- **l'accès à ses secrets est suspendu** jusqu'à ce qu'un animateur y mette son compte.
- le groupe n'étant plus accédé, si personne ne s'est manifesté pour en reprendre la charge, il va finir par s'auto-dissoudre au bout d'un an.

>Dans l'entête du groupe le numéro du compte hébergeur est crypté par la clé du groupe. Seuls ses membres peuvent en avoir connaissance.

### Synthèse
Chaque compte a deux forfaits mensuels respectivement pour les volumes v1 et v2 :
- les opérations menant à dépasser le niveau de forfait pour le mois courant sont interdites.
- les transferts de pièces jointes sont ralentis, sans être bloqués, dès que leur cumul sur les 31 derniers jours approche puis dépasse le volume du forfait v2.

Chaque ligne comptable dispose des compteurs suivants :
- **la date du dernier calcul enregistré** : par exemple le 17 Mai de l'année A
- **pour le mois en cours**, celui de la date ci-dessus :
  - _en Mo_, volume v1 des textes des secrets : 1) moyenne depuis le début du mois, 2) actuel, 
  - _en Mo_, volume v2 de leurs pièces jointes : 1) moyenne depuis le début du mois, 2) actuel, 
  - _en Mo_, volume tr de cumul des transferts de pièces jointes : 31 compteurs pour les 31 derniers jours.
- **forfaits v1 et v2** : les plus élevés appliqués le mois en cours.
- **pour les 11 mois antérieurs** (dans l'exemple ci-dessus Mai de A-1 à Avril de A),
  - les forfaits v1 et v2 appliqués dans le mois.
  - le pourcentage du volume moyen dans le mois par rapport au forfait: 1) pour v1, 2) por v2.
  - le pourcentage du cumul des transferts des pièces jointes dans le mois par rapport au volume v2 du forfait.

Une ligne comptable en base de données n'est pas forcément calculée par rapport à l'instant t du fait des notions de _mois en cours, 31 derniers jours, 11 mois antérieurs_. Un calcul de _normalisation_ est effectué en fonction de l'instant t et de la date du dernier calcul de normalisation :
- à l'ouverture d'une session par un compte.
- en cours d'une session d'un compte à chaque création / mise à jour d'un secret, texte ou pièce jointe et à chaque téléchargement sur disque local.
- quand un _comptable_ ou un parrain affiche une ligne comptable : elle est alors calculée vis à vis de l'instant t cité en tête de la ligne.

## Parrains et filleuls
La création d'un compte est assurée par parrainage d'un compte _parrain_. 
- les comptes filleul et parrain sont **contact** par l'intermédiaire d'un de leurs avatars respectifs.
- la parrain a attribué des forfaits v1 et v2 au filleul à la création. C'est lui qui peut ensuite :
  - augmenter le niveau des forfaits en cours.
  - réduire le niveau des forfaits en cours mais toujours au-dessus du volume courant.
- la ligne comptable du filleul porte le numéro de compte du parrain.

La ligne comptable d'un parrain comporte deux parties :
- l'une porte ses propres compteurs.
- l'autre porte le cumul des compteurs de ses comptes filleul :
  - total des volumes forfaitaires v1 et v2 actuellement attribués.
  - limites v1 / v2 des volumes attribuables aux filleuls (actuels et futurs).

## Comptables de l'organisation
Ce sont quelques comptes normaux mais dont le _hash_ de leurs phrases secrètes est pré-enregistré dans la configuration de l'application (avec un numéro court) ce qui leur confère quelques possibilités d'actions :
- se créer eux-mêmes sans être parrainés par un autre compte.
- consulter / télécharger toutes les lignes comptables.
- consulter et répondre aux messages des comptes.
- attribuer aux comptes parrains les limites de volumes v1 / v2 qu'ils peuvent attribuer à leur filleuls.

>**Le rôle majeur des comptables est de pouvoir maîtriser les forfaits attribués selon la politique propre à chaque organisation**.

Cette maîtrise est à 2 niveaux :
- les comptables distribuent l'allocation globale à des parrains,
- chaque parrain peut allouer des forfaits à des comptes filleuls à l'intérieur de son allocation propre.

### Échanges textuels courts entre les comptables et les titulaires des comptes
Ces conversations sont enregistrées _par ligne comptable_ avec pour chaque échange :
- sa date-heure,
- qui l'a émis (le compte ou un des comptables repéré par son code court),
- son texte de moins de 140 signes.

La conversation conserve les échanges dans l'ordre chronologique inverse,
- ceux ayant moins de 6 semaines,
- au plus les 20 derniers.

Un compte peut consulter sa conversation avec les comptables.

Le parrain d'un compte peut consulter les conversations de ses filleuls (et bien entendu la sienne).

### Création de compte d'un comptable
Sa phrase secrète (brouillée) ayant été enregistrée dans la configuration du site, le titulaire d'un compte _comptable_ peut se créer sans parrainage et se créditer du montant jugé pertinent. Il est de facto un _parrain_.

### Changement de parrain
Un compte parrainé peut changer de parrain, être rattaché à un autre. Il peut aussi _devenir_ un parrain.

C'est un comptable qui peut effectuer cette opération :
- sur demande du parrain,
- sur demande d'un filleul,
- de son propre chef (typiquement suite à disparition du parrain).

## Disparition par inactivité d'un compte

Des ressources sont immobilisées par les comptes (partagées pour les groupes) : l'application doit les libérer quand les comptes sont _présumés disparus_, c'est à dire sans s'être connecté depuis plus d'un an.
- mais pour préserver la confidentialité, toutes les ressources liées à un compte ne sont pas reliées au compte par des données lisibles dans la base de données mais cryptées et seulement lisibles en session.
- pour marquer que des ressources sont encore utiles, un compte dépose lors de la connexion des **jetons datés** ("approximativement datés" pour éviter des corrélations entre avatars / groupes / comptes) dans chacun de ses avatars et chacun des groupes auxquels il participe, ainsi que dans le compte lui-même (en fait dans sa ligne comptable).
- la présence d'un jeton, par exemple sur un avatar, va garantir que ses données ne seront pas détruites dans les 400 jours qui suivent la date du jeton.
- un traitement ramasse miettes tourne chaque jour, détecte les comptes / avatars / groupes dont le jeton est trop vieux et efface les données correspondantes jugées comme inutiles, l'avatar / compte / groupe correspondant ayant _disparu par inactivité_.
- le jeton daté du compte ayant été déposé dans la ligne comptable du compte, les comptables peuvent savoir si un compte est inactif (ou actif, ou proche de l'inactivité).

>Comme aucune référence d'identification dans le monde réel n'est enregistrée pour préserver la confidentialité du système, aucune alerte du type mail ou SMS ne peut informer un compte de sa prochaine disparition s'il ne se connecte pas.

## Ventilation éventuelle des coûts réels d'hébergement
Pour l'instant l'organisation a les moyens de contrôler ses ressources :
- elle maîtrise sa facture globale d'hébergement,
- elle assure aux comptes qu'ils peuvent utiliser dans des conditions normales les ressources forfaitaires qui leur ont été allouées.

En considérant deux types d'organisation bien différents, on observe une convergence vers une exigence commune : comment résilier des comptes devenus _indésirables_, qu'elle qu'en soit la raison.

>Si les ressources étaient gratuites et infinies cette question ne se poserait pas, sauf à prendre en compte un point de vue _dogmatique_ vis à vis des contenus des secrets. Or l'organisation, par conception même de l'application n'y a pas accès direct, seulement le cas échéant par l'intermédiaire de comptes émettant des alertes.

### Organisation payant l'hébergement pour ses adhérents
L'accès à l'application est un service de l'organisation, gratuit pour ses adhérents (du moins invisiblement inclus dans leur adhésion, ou les crédits de sponsoring dont elle bénéficie).
- L'organisation connaît ses adhérents et leurs rôles : elle propose des forfaits conformes aux exigences des rôles tenus, aux statuts (salariés, ...).
- L'organisation fait le rapprochement entre chaque adhérent et son numéro de compte dans l'application mais ne peut pas le faire avec les avatars du compte, les groupes auxquels il participe, ni les contacts avec les autres avatars (même pas des comptes), ni les secrets qu'il écrit et lit.
- **Questions :**
  - (1) si un adhérent quitte l'organisation, comment lui retirer son accès -sous quel délai- (et de facto récupérer ses ressources) ?
  - (2) si des comptes rapportent l'usage par un compte de l'application pour des fins étrangères à l'objet de l'organisation, voire opposées à cet objet, comment lui retirer son accès ? Cette question lève le sujet du contrôle éthique sur l'usage de l'application.

>**Un paragraphe spécifique traite du sujet du contrôle _éthique_.**

### Organisation par _cotisation_
L'organisation, qu'elle soit à but lucratif ou non, a opté pour laisser chaque adhérent choisir son niveau de forfait et corrélativement en payer l'usage.
- chaque compte choisit les niveaux de forfait qui lui semble correspondre à son besoin,
- il paye un abonnement pour contribuer à supporter le coût global d'hébergement.
- **Questions :**
  - (1) si un abonné ne paye plus son abonnement, comment lui retirer son accès -sous quel délai- (et de facto récupérer ses ressources) ?
  - (2) si des comptes rapportent des propos _inappropriés_ vis à vis de la charte éthique de l'organisation dans les secrets partagés, voire non conformes à la loi, comment lui retirer son accès ?

>Les virements des abonnements _pouvant_ être obscurs ou passer par un intermédiaire, il peut être quasi impossible de corréler (avec des moyens légaux) une personne physique ou morale à une ligne comptable. Dans ce type d'organisation **les comptes peuvent être totalement anonymes** ... ce qui n'empêche pas de devoir pouvoir les bloquer, ni qu'ils n'aient pas à respecter la charte éthique s'il y en une.

>Le modèle de _paiement de cotisation_ peut tout à fait être sans but lucratif et proposé par des associations désireuses de permettre à chacun de disposer d'espaces privés et sécurisés pour noter ses pensées, échanger avec des contacts des propos privés. Ce n'est en rien, _a priori_ un modèle mercantile (mais ça peut aussi l'être).

Il reste donc que dans certains cas, une organisation peut devoir mettre fin à l'activité d'un compte, ne serait-ce que pour répondre à une injonction judiciaire sans devoir détruire tous les comptes (et sans considérer les pressions _physiques_, légales ... (?) ou non).

### Mise _en sursis_ et _blocage_ d'un compte
Un compte peut être marqué _en sursis_ par application d'une décision de l'organisation : un comptable inscrit dans la ligne comptable une date de mise en sursis.
- **les dépôts de jetons effectués à la connexion et attestant de la vitalité du compte sont suspendus**. Le compte a au maximum un an avant la disparition de ses données (ou la sortie de cet état).

Mais rien n'oblige le compte à se connecter et à en prendre connaissance. Une organisation peut parfaitement n'avoir aucun moyen de contacter la personne physique (ou morale) titulaire de sa mise en sursis.

Une seconde date est notée dans la ligne comptable : **celle de la prise de connaissance de la mise _en sursis_**, celle de la première connexion du compte après sa mise en sursis.

Il y a deux états _en sursis_ et un état _bloqué_.
- la mise en sursis peut spécifier de passer directement en état 2, voir _bloqué_.
- les durées pour passer automatiquement de l'état 1 à 2 (n1) puis de 2 à 3 (n2) sont spécifiés en nombre de jours à la configuration de l'installation.
- le jour de départ est celui de la prise de connaissance de son état par le compte.
- dans tous les cas de figure, le compte ne déposant plus de jetons de vitalité à la connexion depuis le jour de la mise en sursis / blocage, peut disparaître avant de passer en état 2 ou 3.

#### En sursis (1)
Le compte continue à vivre normalement mais un panneau de pop-up s'affiche très régulièrement au cours des sessions pour rappeler cet état, le temps restant et ce qui l'attend en _sursis 2_.

#### En sursis (2)
Le compte ne peut plus créer de secrets, de pièces jointes ni les mettre à jour mais il peut en supprimer.

#### Bloqué (3)
Le compte est bloqué et ne peut rien consulter. Il ne conserve que de la possibilité de converser avec le comptable.

#### Retour à l'état normal
Un comptable peut supprimer l'état de sursis / bloqué à tout instant.

## Contrôle éthique ... ou non
Ce sujet ne concerne que les organisations ayant un objet social / politique : ses membres utilisent l'application pour les servir.

Aucun contrôle éthique n'est envisageable vis à vis des secrets personnels : il n'y a que le compte qui peut y accéder, on ne voit pas pourquoi il se dénoncerait de lui-même de textes illisibles par d'autres.

Concernant des secrets de couples, si des écrits sont jugés inappropriés pour l'un des deux,
- il arrête le partage de secrets,
- il supprime les secrets qui le dérange.
L'autre compte est ramené à gérer des secrets personnels.

La question se pose vis à vis de secrets d'un groupe :
- un avatar peut être résilié d'un groupe, sauf s'il en est animateur.
- s'il n'est pas possible de le résilier parce qu'il est animateur, rien n'empêche les membres du groupes choqués par les écrits inappropriés,
  - d'ouvrir un autre groupe,
  - d'y transférer par copie les secrets intéressants de l'ancien,
  - d'y inviter les mêmes membres, sauf l'indésirable,
  - de s'auto-résilier de l'ancien groupe.

La question n'est donc pas pour les autres comptes de se _mettre à l'abri_ d'un comportement problématique (ils peuvent facilement le faire) mais de _dénoncer_ auprès de l'organisation un compte utilisant les ressources de l'application à des fins personnelles / contraires à l'organisation / illégales ...

Cette question se pose moins dans le cadre d'une organisation _par cotisation_ où finalement c'est l'indésirable lui-même qui paye pour disposer de secrets.

L'organisation aura besoin qu'un compte _témoin_ ayant accès aux secrets de groupe litigieux accède physiquement à ceux-ci (par une manipulation claire) pour mettre en évidence le caractère inapproprié de certains secrets justifiant, une mise en sursis voire un blocage.

>L'application permet de facto une modération par exclusion d'un compte, en aucun cas par retrait des textes litigieux, sauf à ce qu'un compte lanceur d'alerte le fasse.

>Une organisation peut aussi déclarer dans ses conditions qu'elle ne procède jamais à un blocage de compte pour raisons éthiques, les autres comptes ayant facilement les moyens de se protéger d'écrits inappropriés.

**L'application est agnostique vis à vis des contenus des secrets** (pas de vote, d'avis ...) qui peuvent être n'importe quoi, en bien ou en mal ... et selon ce que chacun considère comme bien ou mal: c'est une application qui reste du niveau de la communication / mémorisation **personnelle et/ou privée**, comme celle que peut avoir un groupe restreint d'amis discutant librement entre eux dans un domicile privé.  
C'est aussi pour cette raison qu'un groupe a une taille limitée, telle qu'il soit raisonnable de juger qu'il n'est pas public, et où tout le monde en contact se connaît et a été coopté.

>Ce n'est pas une application _libertaire_ mais _privée_. Être libertaire supposerait un accès public sans restriction ce qui n'est pas le cas.

# Estimations monétaires
Tous les prix sont mensuels en centimes d'€.

L'espace v1 est de l'espace de base de données. Son coût est en fait celui d'une instance VPS, CPU + RAM + SSD. Environ 3GB de SSD sont pris par l'OS.
- une instance de 40GB de SSD doit pouvoir supporter 10GB de textes de messages (de v1) : **0,05c / MB**

L'espace v2 est de l'espace Object Storage ou File System externe.
- l'offre en général comporte une part de stockage et une part de transfert.
- approximativement on trouve des offres à 3c / GB : **0,3c / 100MB**

La granularité pourrait être :
- pour v1 : 1 MB - 0,05c
- pour v2 : 100 MB - 0,3c

Les forfaits typiques s'étagent de 1 à 64 : (coût mensuel)
- (1) - XXS - 1 MB / 100 MB - 0,35c
- (2) - XS - 2 MB / 200 MB - 0,70c
- (4) - SM - 4 MB / 400 MB - 1,40c
- (8) - MD - 8 MB / 800 MB - 2,80c
- (16) - LG - 16 MB / 1,6GB - 5,60c
- (32) - XL - 32 MB / 3,2GB - 1,12€
- (64) - XXL - 64 MB / 6,4GB - 2,24€

**Remarques**
- le _coût_ de v1 est négligeable en monétaire : c'est surtout sa limitation qui est importante puisque au total il va déterminer la taille du VPS.
- on peut concevoir des comptes avec très peu d'espace v2, la valeur principale de l'application étant de partager des notes textuelles.
- mais on peut aussi imaginer des organisations très orientées _images_ et / ou _gros documents externes_. Les textes des secrets ne sont alors que des remarques / synthèses / commentaires à propos de documents infiniment plus volumineux.

**Limites technologiques**
La limite v2 n'existe pas : les transferts s'effectuent directement entre le site d'hébergement de l'object store et les navigateurs, sans passer par le serveur.

La limite v1 en tant que _volume_ est assez lointaine : on peut imaginer une base SQLite de 200GB : soit environ 100,000,000 de secrets ce qui est énorme.

En pratique ça signifie un ordre de grandeur de 10,000 comptes : en accès séquentiel en écriture par un seul processus, il est probable que le couple _node / SQLite_ soit déjà saturé bien avant cette limite.

L'application n'est pas structurellement conçue pour des organisations ayant un grand nombre de comptes mais peut supporter un nombre significatif de comptes partageant des secrets ayant des volumes de fichiers joints très importants.
