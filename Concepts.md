# Boîtes à secrets - Spécifications

Toute organisation `monorg` peut disposer d'un hébergement de l'application en s'adressant à un hébergeur de confiance (ou en s'hébergeant elle-même) lui procurant une URL d'accès `https://monhebergeur.net/monorg` que ses membres peuvent invoquer pour accéder à leurs secrets.
- Chaque organisation est totalement autonome des autres, ses données sont enregistrées dans des bases de données différentes et s'ignorent les unes les autres.
- Chaque membre de l'organisation souhaitant accéder aux secrets et partager les siens doit disposer d'un compte dont l'ouverture requiert le parrainage d'un compte existant ou disposer d'un mot de passe d'administration.
- L'application est structurée pour des organisations petites et moyennes : de quelques dizaines de comptes à quelques milliers, mais certainement pas des millions.

On ne considère par la suite qu'une seule organisation.

> L'application **Boîtes à secrets** propose aux comptes un stockage partagé de secrets en contrôlant très précisément qui peut accéder à quoi.

> **Aucun texte lisible humainement n'est disponible *en clair***, ni dans les stockages locaux des navigateurs des terminaux, ni dans la base de données sur le serveur : tout y est crypté par des clés définies par les comptes. 

Le vol des données locales ou de l'appareil qui les stockent ou de la base centrale centrale est complètement inexploitable, les _pirates_ ne peuvent en obtenir que des informations indéchiffrables.

> _Revers de cette sécurité_ : si un compte *oublie* sa **phrase secrète** qui crypte toutes ses clés d'accès, il est ramenée à l'impuissance du pirate.

# Comptes, avatars, groupes, contacts et secrets

## Comptes et leurs avatars
Un compte dans l'organisation a un ou plusieurs **avatars** qui sont perçus comme autant de personnalités différentes : une même personne participant à une organisation peut avoir des compartiments de vie différents, participer à des enquêtes différentes ou des actions différentes : ses activités sont cloisonnées vis à vis des autres.
- le titulaire d'un compte est le seul à pouvoir connaître la liste de ses propres avatars.
- on ne connaît des autres comptes que leurs avatars et il est impossible au regard de deux avatars de déterminer s'ils correspondent au même compte, la même personne, ou non.

### Code et pseudo (immuables) d'un avatar, carte de visite (modifiable)
Un avatar est créé avec un **pseudo immuable** censé être parlant dans l'organisation, du moins pour ceux de ses membres avec qui il sera en contact.  
- une **clé de cryptage** aléatoire et immuable lui est attribuée à sa création.
- un **code** immuable (de 15 chiffres) l'identifie mais il n'a pas d'intérêt pratique.

La **carte de visite** de l'avatar est modifiable par le titulaire du compte et comporte :
- une photo de petite dimension,
- un court texte apportant une éventuelle précision au pseudo.

> _Il est possible de rencontrer deux avatars ayant même pseudo_, les homonymes étant autorisés : le code permet de les distinguer (seul cas où le code sert à quelque chose) et la carte de visite si les avatars en ont déclaré une.

### Compte auto-résilié et *disparu*
Un compte peut s'auto-détruire. Ses données sont effacées *mais pas tous ses secrets* : ceux qu'il a partagé avec d'autres comptes et / ou groupes d'avatars restent accessibles aux autres, du moins pour les secrets ayant encore au moins un lecteur pouvant y accéder.

**Un compte qui ne s'est pas connecté pendant un certain temps (18 mois) est déclaré *disparu*** et est détruit. Comme rien ne raccorde un compte au monde réel, ni adresse e-mail, ni numéro de téléphone ... il n'est pas possible d'informer quiconque de la disparition prochaine d'un compte.

> **Toutefois** 6 mois avant d'être détruit, les avatars du compte vont apparaître **en alerte** pour les autres avatars avec qui ils sont en contact : certains de ceux-ci peuvent avoir dans la vraie vie un moyen d'alerter leur titulaire afin qu'il se connecte une fois ce qui le fera sortir de cet état.

## Groupes d'avatars partageant des secrets
Il est possible de créer de petits **groupes** réunissant des membres (des avatars).

Un groupe est créé avec un **nom immuable** censé être parlant dans l'organisation, du moins pour ses membres.
- il a un **code** interne sur 15 chiffres (inutile dans la vie courante),
- il a une **clé de cryptage** aléatoire et immuable qui lui est attribuée à sa création. Elle ne sera transmise qu'aux membres du groupe et sert à crypter les données du groupe dont l'accès à ses secrets.

Chaque membre du groupe peut attribuer au groupe un intitulé qui lui est propre si le nom universel du groupe ne lui parle pas assez.

**Des avatars l'ayant accepté peuvent devenir membre du groupe** sur invitation d'un animateur du groupe : ils peuvent l'être avec un niveau de droit spécifié : *lecture, écriture, animation*.

Au cours du temps de nouveaux avatars peuvent être invités, certains peuvent être *résiliés* ou avoir *disparu* : la liste des membres change.

### Création d'un groupe
Le créateur d'un groupe en est le premier *animateur* : celui-ci doit lui transférer un minimum de quotas de stockage.

Les autres avatars membres sont **invités** par un animateur qui, soit doit avoir en contact son invité dans l'application, soit lui demander dans la vraie vie du lui communiquer ses identifiants dans l'application en cryptant ceci par une phrase de rencontre connues d'eux seuls.

### Inscription par A de C au groupe G
A, animateur du groupe G, peut inscrire un de ses contacts C à G. C en sera notifié :
- il pourra décliner cette invitation et apparaîtra comme membre *ayant refusé l'invitation*.
- il pourra accepter l'invitation et apparaîtra comme *ayant accepté* avec le statut de lecteur / auteur / animateur défini par l'invitant.

### Lecteur, auteur, animateur, résilié
Un **lecteur** ne peut que lire les secrets du groupe (donc en copier le contenu). Un lecteur peut se résilier lui-même. Il peut aussi apporter des quotas au groupe.

Un **auteur** peut *de plus* écrire / modifier / supprimer des secrets.

Un **animateur** peut *de plus* :
- inviter d'autres membres.
- changer le statut des autres membres non animateur et en particulier les résilier.
- reprendre des quotas du groupe et les redistribuer à des membres du groupe.

### Archivage d'un groupe
Un groupe peut être archivé par un animateur : plus aucun secret ne peut y être ajouté / modifié.  
En revanche le groupe peut continuer à avoir des mouvements de membres et ses secrets peuvent être copiés.  
Un groupe peut être désarchivé par un animateur.

### Fermeture d'un groupe
Un animateur peut *fermer* un groupe : il ne peut plus y avoir de nouvelles inscriptions.  
Pour rouvrir un groupe il faut que tous les animateurs aient voté vouloir le rouvrir.

## Contacts personnels d'un avatar
### Contact *simple*
Un avatar `A` peut inscrire un avatar `Ci` dans sa liste de contacts à condition d'en avoir l'identification : son code, son pseudo et la clé de cryptage de sa carte de visite. C'est le cas :
- _quand A et Ci sont membres d'un même groupe G_ : A dispose en effet de l'identification complète de tous les membres du groupe G ce qui lui permet de lire leur carte de visite.
- quand A n'a pas connaissance des identifiants de Ci mais l'a rencontré *dans la vraie vie* et que Ci a accepté de transmettre son identité dans l'application à A :
  - A et Ci ont convenu d'une phrase secrète de reconnaissance,
  - Ci a saisi cette phrase et déposé son identification complète.
  - A utilise cette phrase pour inscrire Ci comme un de ses contacts. 

A peut avoir C comme *simple contact*, C peut avoir ou non de son côté A comme *simple contact*, chacun ignore la connaissance que l'autre a de lui.

### Contacts mutuels *liés*
A et C peuvent décider de devenir contacts _liés_, chacun sachant qu'il est un contact de l'autre :
- A et C peuvent écrire *un* court texte lisible par l'autre : le dernier écrit est seul conservé.
- A et C peuvent désormais *partager des secrets*. Toutefois,
	- il faut que l'un et l'autre en soit d'accord.
	- si l'un des deux n'accepte plus le partage de secrets, ceci ne vaut que pour les secrets futurs : ceux déjà partagés restent accessibles à chacun.
	- l'un comme l'autre peuvent détruire leur exemplaire d'un secret partagé avec l'autre sans que ceci n'affecte l'accès de l'autre aux secrets supprimés de l'autre côté.
- ce contact reste établi jusqu'à disparition effective de A ou Ci : si Ci disparaît, les exemplaires pour A de ses secrets partagés avec Ci restent accessibles à A.

## Secrets
Un **secret** est un *texte* court (moins de 4000 signes) mais peut avoir *une pièce jointe* de taille raisonnable. 
- Le texte est lisible avec quelques éléments de décoration (*gras, italique, listes ...*) selon la syntaxe MD.
- Le début du texte, les 140 premiers caractères ou la première ligne si elle est plus courte, est _l'aperçu_ du secret. Un certain nombre de *petits* secrets n'ont de fait qu'un aperçu et pas de texte à proprement parlé.
- un secret est crypté selon une clé qui n'est connue que par les avatars ayant accès au secret.

**Un secret est modifiable**, comme sa pièce jointe qui peut changer. Du moins jusqu'à ce que ce secret soit basculé en état *archivé* auquel cas il devient immuable. Le statut d'un secret explicite par qui il peut être modifié :
- *normal* : le secret est modifiable par tous ceux y ayant accès ce qui change selon qu'il s'agit d'un secret personnel, de couple ou de groupe.
- *restreint* : le secret n'est modifiable que par le dernier avatar l'ayant modifié.
- *archivé* : le secret n'est plus jamais modifiable.

Un secret garde la liste des avatars l'ayant modifié, les plus récents en tête mais sans doublons.

**Un secret peut *faire référence* un autre secret**. L'affichage peut ainsi être hiérarchique :
- à la racine apparaissent tous les secrets relatifs à aucun.
- en dépliant un secret S1 on voit tous les secrets Si directement relatifs à S1 et ainsi de suite.

> Une pièce jointe peut être lue dans une session en ligne et sauvegardée cryptée (ou non !) localement par exemple dans *Téléchargement*. Ultérieurement au cours d'une session hors ligne, la pièce jointe peut être ré-obtenue depuis *Téléchargement* et affichée : ce n'est pas automatique, ça suppose une action explicite de l'utilisateur.

### Secrets personnels, de couple et de groupe
*Singulier*, *duel* (deux), *pluriel* (trois / trop ... plus de deux).

**Un secret personnel d'un avatar A** est un secret qu'il ne partage avec personne.
- s'il veut ultérieurement le partager il créera un autre secret et y recopiera le contenu.
- le propriétaire d'un secret personnel peut le modifier (tant qu'il n'est pas archivé) et le détruire.
- le propriétaire d'un secret personnel peut lui attacher des *mots clés* qui lui sont personnels afin de les classer, les filtrer etc.

**Un secret de couple est partagé entre deux avatars A et B contacts *liés*** et seulement entre eux pour toujours.
- A et B peuvent modifier le secret, ils en voient tous deux le même contenu.
- si le secret est *archivé* ni A ni B ne peuvent plus le changer.
- si A ou B change le statut en *restreint* le secret n'est modifiable que par le dernier l'ayant modifié ... jusqu'à ce que celui-ci remette le statut en *normal* ou *archivé*.
- si A ou B veut transmettre le secret à d'autres, ça sera un autre secret dont le contenu sera recopié du premier : toutefois si le secret origine change, sa copie ne changera pas.
- *si l'un des deux A ou B est considéré comme disparu*, les secrets du couple restent lisible à l'autre.
- chacun A et B peut attacher à un secret de couple des *mots clés* qui lui sont personnels (non connus de l'autre) afin de les classer, les filtrer etc.

**Un secret de groupe est partagé entre tous les membres d'un groupe.**
- les membres actuels comme futurs.
- un membre nouvellement arrivé accède à tous les secrets du groupe.
- *un membre qui quitte le groupe n'en voit plus les secrets* : si certains l'intéressaient, il faut qu'il en fasse des copies personnelles de leur contenu tant qu'il a encore accès à ceux-ci.
- un animateur du groupe peut attacher à un secret du groupe des *mots clés* qui sont spécifiques du groupe afin de les classer, les filtrer etc. Chaque membre du groupe peut y ajouter ses propres mots clés qui ne seront visibles que de lui.

Dans un groupe, pour un secret donné :
- en état **normal** : tous les membres peuvent le mettre à jour.
- en état **restreint** : seul le dernier membre ayant fait une mise à jour peut l'éditer à condition d'avoir dans le groupe le rôle d'auteur ou d'animateur.
- en état **archivé** : personne ne peut plus jamais l'éditer.

### Secrets temporaires et permanents
Un **secret** est par défaut *temporaire* et s'autodétruit quelques semaines après sa création. Un avatar A qui le partage peut le déclarer *permanent*, le secret ne sera plus détruit automatiquement . A peut être,
- l'avatar propriétaire pour un secret personnel.
- les deux avatars pour un secret de couple.
- un des animateurs pour un secret de groupe.

### Mots clés : indexation / filtrage / annotation personnelle des secrets
Il existe une liste de 50 mots clés génériques de l'application définis à son déploiement. Par exemple : _à relire, important, à cacher, à traiter d'urgence, ..._ Chaque mot clé a un texte et un possible émoji.

Chaque compte a une liste de 100 mots clés qu'il définit lui-même. Par exemple : _écologie, économie, documentation, mot de passe, ..._ 

Chaque groupe a aussi une liste de 100 mots clé à sa disposition.

Chaque secret peut être indexé par ces mots clés à discrétion de chaque compte pour lui-même ce qui n'affecte pas les indexations des autres.
- les libellés des mots clés peuvent changer,
- l'affectation de mots clés aux secrets également, même pour un secret archivé.

## Compte

### Parrainage d'un compte
Une personne souhaitant ouvrir un compte doit trouver un compte *parrain*. Le parrain et le filleul se mettent d'accord sur **une phrase de reconnaissance** et sur le nom du premier avatar du filleul (qui pourra en ajouter d'autres).
- le parrain enregistre un *parrainage* avec cette phrase et donne à son filleul des quotas de création et de stockage de secrets.
- le filleul accède à l'application en fournissant la phrase de reconnaissance : ceci lui permet à la fois,
  - de créer son compte avec un minimum de quotas,
  - d'avoir un premier avatar contact lié avec son parrain.

*Remarques* :
- le parrain peut supprimer son parrainage avant qu'il ne soit accepté en laissant ou non un mot d'explication.
- le filleul peut renoncer au parrainage, en laissant ou non un mot d'explication.
- un parrainage non utilisé a une durée de vie limitée et disparaît automatiquement au delà.

### Phrase secrète d'un compte, clé générale
L'identifiant d'un compte est tiré au hasard : c'est un code de 15 chiffres sans intérêt.

A la création d'un compte sa *clé de cryptage générale* est tirée au sort et ne pourra jamais changer.
- **le titulaire du compte déclare une phrase secrète** qui n'est stockée sous aucune forme dans l'application.
- **la clé de cryptage générale du compte est enregistrée cryptée par la phrase secrète**.

> L'oubli par son titulaire de la phrase secrète de son compte est rédhibitoire : le compte est définitivement inaccessible.

**Une phrase secrète a deux lignes**, une première d'au moins 16 signes et une seconde d'au moins 16 signes. 
- L'application n'accepte pas d'avoir 2 comptes ayant des phrases secrètes ayant une même première ligne.
- Un compte peut changer de phrase secrète à condition de fournir l'ancienne et la nouvelle.

###  Quota
Un quota comporte 4 chiffres : 
- le volume maximal des secrets permanents : pour chaque secret, une taille forfaitaire + la taille de son texte.
- le volume maximal des pièces jointes pour les secrets permanents,
- le volume maximal des secrets créés chaque mois.
- le volume maximal des pièces jointes créées chaque mois.

A la création d'un compte, son premier avatar reçoit de son parrain un quota.
- il peut le re-distribuer en partie à des contacts *liés*, des avatars ou groupes, en prenant sur les siens,
- il peut en recevoir d'un autre avatar ou d'un groupe dont il est membre.

### *Super* compte
Pour créer un compte il faut être parrainé par un compte existant ... ou fournir un mot de passe long prédéfini à la configuration de l'hébergement. 

Un *super* compte fournissant ce mot de passe peut se déclarer des quotas sans limite et en distribuer autant que souhaité, mais risque en cas d'excès de distribution de faire tomber l'application par manque de ressources allouées.

Un *super* compte n'est pas *super* à vie : il peut l'être à sa création pour se dispenser de parrainage et s'attribuer des quotas en puisant sur ceux de la *banque centrale*. Si plus tard il doit se recharger en quotas il devra prouver à nouveau qu'il est toujours *super*. La configuration de l'application peut changer le mot de passe, voire le supprimer, plus personne ne pouvant se déclarer *super*.

## Contrôle du volume des secrets
Aucun compte (même un compte connaissant la clé d'administration), aucun administrateur ne peut connaître la liste des comptes et de leurs avatars ni n'a de pouvoir pour _bloquer_ un compte ou le dissoudre. En conséquence, n'importe quel compte pourrait créer autant de secrets qu'il veut et saturer l'espace physique au détriment des autres. C'est pour cela que chaque compte dispose de _quotas_ afin de maîtriser une possible explosion de volume bloquant le système.

Ce contrôle s'effectue à deux niveaux :
- le contrôle du volume de secrets créés par mois.
- le contrôle du volume des secrets permanents.

On distingue :
- le volume des secrets eux-mêmes : un montant forfaitaire par secret plus la taille _gzippée_ de son texte.
- le volume des pièces jointes, _gzippées_ selon leur type MIME.

Il y des quotas :
- **par avatar**, attribués :
    - par le parrain à la création du compte,
    - réattribués par un autre compte sur ses quotas personnels,
    - réattribués depuis les quotas d'un groupe par un animateur, en particulier lors de son archivage ou sa dissolution.
- **par groupe**, attribués par les membres du groupe sur leur propres quotas.

### Quotas mensuels de volume de secrets créés
Un avatar ne peut pas créer plus de secrets par mois que ses quotas ne l'autorisent.
- le décompte est mis à 0 à chaque début de mois.
- une création de secrets incrémente les volumes créés du mois.
- une mise à jour incrémente ces volumes si la mise à jour est une expansion.
- une alerte orange puis rouge apparaît à l'approche des limites des quotas ou à son dépassement.
 
 ### Quotas de volume de secrets permanents
 Quand un secret devient permanent, le volume permanent du compte ou du groupe est incrémenté et ne peut pas dépasser les quotas permanents. Les volumes changent,
 - par mise à jour du secret (augmentation ou réduction),
 - par suppression du secret.

Un volume permanent peut temporairement excéder le quota pour un compte, si ceci résulte d'une action d'un autre avatar :
- le secret permanent d'un couple A-B est mis à jour en expansion par B (sans dépasser les quotas de B),
- mais ceci lui fait dépasser le volume maximal de A : la mise à jour est acceptée pour ne pas bloquer B. Toutefois A devra supprimer d'autres secrets, ou augmenter ses quotas.

### Quotas attribués par un _super_ compte
Les personnes à qui l'administrateur du site a confié la clé _super_ peuvent s'attribuer des quotas sans limitation et les redistribuer à leurs contacts de confiance. Cette délégation de _banque centrale_ peut être retirée en changeant la clé _super_ : elle suppose qu'elle ne soit communiquée qu'à quelques personnes de confiance.

## Contrôle éthique
A partir du moment où un compte respecte ses quotas il est impossible à une quelconque autorité de le détruire. Les textes des secrets lui sont strictement privés et peuvent en conséquence être éthiquement incorrects. Toutefois :
- si un avatar A partage avec B des secrets que B considère comme non acceptable, quelqu'en soit la raison, B peut déclarer ne plus rien partager avec A.
- dans la cadre d'un groupe, un animateur peut résilier un membre du groupe et chacun peut s'auto résilier.

Bref nul n'est obligé de lire des secrets qu'il ne juge pas acceptables : 
- la _haine_ non partagée n'est qu'une perte de temps pour son auteur,
- la _haine_ partagée par un groupe privé de haineux ne nuit à personne.

Il reste que l'application est agnostique vis à vis des contenus des secrets qui peuvent être n'importe quoi, en bien ou en mal ... et selon ce que chacun considère comme bien ou mal: c'est une application qui reste du niveau de la communication / mémorisation personnelle ou privée, comme celle que peut avoir un groupe restreint d'amis discutant librement entre eux.

# Serveur central et sessions de l'application Web

**Un utilisateur invoque l'application Web depuis un navigateur par une URL** ce qui lui affiche une page d'interface graphique qui connaît l'URL d'accès au serveur central.

**Le serveur central** héberge le stockage de référence des secrets et des informations sur les comptes. 
- seule *l'application serveur* met à jour ces informations.
- elle n'accepte des requêtes **qu'en provenance** du domaine de l'installation, c'est à dire émise par l'application Web *officielle*. Une application Web *officieuse / pirate* ne peut pas accéder aux données centrales.

**Stockage local**  
Quand le titulaire d'un compte ouvre une session de l'application Web d'accès à ses secrets depuis un navigateur sur un appareil quelconque et s'identifie, celle-ci accède au stockage local du navigateur *dédié au compte* :
- la première fois ce stockage est chargé des secrets détenus sur le serveur central (seulement ceux concernant le compte) : c'est une *synchronisation* totale.
- les fois suivantes, beaucoup de secrets étant déjà chargés, le stockage local est *synchronisé* plus rapidement avec l'état connu en central.

> Remarque : si la session a été ouverte en *navigation privée*, le stockage local du compte est effacé automatiquement par le navigateur à la fin de la session.

> Chaque compte choisit sur chaque appareil ce qu'il souhaite synchroniser : sur un mobile ce peut être moins de secrets que sur un poste fixe.

### Modes *synchronisé*, *incognito*, *avion*

#### Mode synchronisé 
**C'est le mode normal, les données sont synchronisées entre le stockage central et local** :
- le fonctionnement est accéléré,
- ça nécessite à la fois que le serveur soit accessible par le réseau et que le stockage local ait été autorisé par l'utilisateur.

#### Mode incognito
**Il n'y a pas de stockage local, toutes les données viennent du serveur** ce qui nécessite un accès au réseau. Le fonctionnement est plus lent à l'initialisation. Aucune trace n'est laissée sur l'appareil (utile au cyber-café ou sur le mobile d'un.e ami.e).

#### Mode avion
**Le réseau n'est pas utilisé : seul le stockage local est mis à contribution** :
- c'est parfois utile quand on craint que l'environnement réseau soit *surveillé / peu sûr* ou techniquement instable, ou qu'on souhaite qu'aucun accès réseau ne puisse être tracé.
- si une session de l'application locale s'est déjà exécutée une fois dans le navigateur pour un compte, celui-ci retrouve, ses données telles que synchronisées lors de la dernière session exécutée en mode *synchronisé* sur ce poste pour ce compte.  
- les informations sont plus ou moins *en retard* par rapport à l'état de référence détenu en central, mais peuvent être très utiles.
- les mises à jour ne sont pas possibles : **toutefois de nouveaux secrets ou des mises à jour de secrets peuvent être préparées pour être synchronisées lors de la prochaine session en mode *synchronisé***.

> Il n'est pas indispensable de couper le réseau : la page de l'application est éventuellement rechargée depuis le serveur central si elle diffère de la dernière chargée, puis on déclare lors de l'accueil vouloir poursuivre en mode *avion*. Toutefois une éventuelle surveillance du réseau montrera que l'application a été vérifiée (pas de changement depuis la dernière exécution) ou rechargée

> **Il est ainsi possible de disposer de plusieurs copies synchronisées de ses secrets sur des appareils différents.**


