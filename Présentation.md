# L'application Boîtes à secrets

Toute organisation `monorg` qui le souhaite peut disposer d'un hébergement de l'application Web _Boîtes à secrets_ en s'adressant, soit à un hébergeur de confiance, soit en s'hébergeant elle-même. Ses membres utilisent un navigateur pour accéder à leur application par une URL comme `https://monhebergeur.net/monorg`.
- les organisations sont autonomes les unes des autres, leurs données sont enregistrées dans des bases de données différentes.
- Chaque membre d'une organisation souhaitant accéder aux secrets et y partager les siens doit disposer d'un compte dont l'ouverture requiert le parrainage d'un compte déjà existant.
- L'application est structurée pour des organisations petites et moyennes : de quelques dizaines de comptes à quelques milliers, mais certainement pas des millions.

On ne considère par la suite qu'une seule organisation.

> L'application **Boîtes à secrets** propose aux comptes un stockage partagé de secrets en contrôlant très précisément qui peut accéder à quoi.
L'application permet des échanges **privés** d'information, réservées à des personnes *invitées* : les secrets n'y ont jamais un caractère public.

> **Aucun texte lisible humainement n'est disponible *en clair***, ni dans les stockages locaux des navigateurs des terminaux, ni dans la base de données sur le serveur : tout y est crypté par des clés issues d'une **phrase secrète** définie par chaque compte et mémorisée nulle part ailleurs que dans la tête du titulaire du compte. 

Le vol des appareils des titulaires des comptes (et de leurs données locales) ou de la base centrale centrale est complètement inexploitable, les _pirates_ ne peuvent en obtenir que des informations indéchiffrables.

> _Revers de cette sécurité_ : si le titulaire d'un compte *oublie* sa **phrase secrète** qui crypte indirectement toutes ses clés d'accès, il est ramenée à l'impuissance du pirate.

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

# Secrets, comptes et avatars, groupes, contacts

## Secrets
Un **secret** est un *texte* court (moins de 4000 signes) et peut avoir *une pièce jointe* de taille raisonnable. 
- Le texte est lisible avec quelques éléments de décoration (*gras, italique, listes ...*) selon la syntaxe MD.
- Le début du texte, les 140 premiers caractères ou la première ligne si elle est plus courte, est _l'aperçu_ du secret. Un certain nombre de *petits* secrets n'ont de fait qu'un aperçu et pas de texte à proprement parlé.

**Un secret est modifiable**, son texte comme sa pièce jointe, du moins jusqu'à ce que ce secret soit basculé en état *archivé* auquel cas il devient immuable.

**Par défaut un secret est temporaire**, il s'efface automatiquement au bout de quelques semaines, mais il peut être rendu **permanent**, ou créé directement permanent, et n'est alors effacé que sur demande explicite.

## Comptes et leurs avatars
Un compte a un ou plusieurs **avatars** qui sont comme autant de personnalités différentes. Une même personne peut avoir des compartiments de vie différents, contribuer à des réflexions ou des actions différentes. Ce cloisonnement est possible en se définissant plusieurs avatars :
- le titulaire d'un compte est le seul à pouvoir connaître la liste de ses propres avatars.
- un compte ne connaît des autres comptes que leurs avatars. Il est impossible, même à l'administrateur d'hébergement de l'application, de déterminer au regard de deux avatars s'ils correspondent au même compte ou non.

>Un avatar dispose de secrets **personnels** qui ne sont accessibles que par lui et ne seront jamais partagés avec d'autres.

## Groupes d'avatars partageant des secrets
Un avatar peut créer un **groupe** réunissant plusieurs avatars qu'il a invités et qui ont accepté cette invitation.

>Un groupe dispose de secrets **de groupe** qui ne sont accessibles qu'aux membres du groupe.

Les avatars membres d'un groupe partagent les secrets du groupe :
- dès qu'ils sont membres ils peuvent accéder à tous les secrets du groupe, même ceux écrits avant leur arrivée dans le groupe.
- dès qu'ils sont résiliés du groupe ils ne peuvent plus accéder aux secrets du groupe.

**Chaque membre du groupe** a un niveau de pouvoir :
- **lecteur** : il ne peut que lire les secrets du groupe.
- **auteur** : il peut lire, créer, modifier les secrets du groupe.
- **animateur** : il peut de plus inviter des avatars à rejoindre le groupe et les résilier (sauf ceux eux-mêmes animateurs). Le créateur d'un groupe en est le premier animateur. 

## Contacts personnels d'un avatar
### Contact *simple*
Un avatar `A` peut inscrire un avatar `C` dans sa liste de contacts dès lors qu'il en a son identification complète : c'est le cas dès lors que A et C sont ou ont été membres d'un même groupe.

>A peut avoir C comme *simple contact*, C peut avoir ou non de son côté A comme *simple contact*, chacun ignore la connaissance que l'autre a de lui.

### Contact *fort*
A et C peuvent décider explicitement, de devenir contacts _forts_, chacun sachant qu'il est un contact de l'autre.

A et C peuvent alors partager **des secrets de couple** : un secret de couple est _dédoublé_ sur chacun des contacts et toute mise à jour répercutée sur les deux exemplaires. L'un comme l'autre peuvent détruire leur exemplaire d'un secret partagé avec l'autre sans que ceci n'affecte l'accès de l'autre à son propre exemplaire.

L'un des deux peut décider, tout en restant contact *fort*, de ne plus accepter le partage de secrets avec l'autre : ceci ne vaut que pour les secrets futurs, ceux partagés antérieurement restent accessibles à chacun.

A et C partagent une petite *ardoise textuelle* (140 signes) : ceci leur permet un minimum d'échange sans utiliser un secret partagé (en particulier quand l'un des deux a bloqué le partage de secrets).

Un contact *fort* reste établi jusqu'à disparition effective de A ou C : si C disparaît par exemple, les exemplaires pour A de ses secrets partagés avec C restent accessibles à A.

### Contact rencontré hors de l'application
Si A et C n'ont jamais été membres d'un même groupe, ils ne connaissent pas l'identification complète de l'autre et ne peuvent pas s'enregistrer comme contact.

Mais ils peuvent se connaître par ailleurs et pourront établir un contact _fort_ en s'échangeant leurs identifications en utilisant une phrase de contact connue d'eux seuls.

# Compte et avatars

## Création d'un compte
Pour se créer un compte le titulaire doit déclarer :
- sa **phrase secrète** d'accès et ne devra jamais oublier car elle n'est mémorisée nulle part en clair dans l'application. 
  - elle sert à authentifier le titulaire à sa connexion à l'application.
  - **elle a deux lignes**, une première d'au moins 16 signes et une seconde d'au moins 16 signes. L'application n'accepte pas d'avoir 2 comptes ayant des phrases secrètes ayant une même première ligne.
  - elle pourra être changée à condition de pouvoir fournir celle en cours.
  - l'oubli de cette phrase est irrémédiable : indirectement elle crypte toutes les informations et secrets accessibles au compte.
  - l'administrateur d'hébergement lui-même n'a aucun moyen technique de la retrouver.
- le **nom, immuable, de son premier avatar** (un pseudo).
- la **phrase de parrainage** conjointement fixée avec un autre compte rencontré (hors de l'application) et ayant accepté de le *parrainer* : 
  - parrain et filleul ont convenu de cette phrase et du nom du premier avatar du compte filleul.
  - le parrain a accepté de prendre sur ses propres quotas d'espace pour ses secrets pour en donner au compte filleul.
  - le parrain a enregistré la phrase de parrainage avec le nom d'avatar du filleul et les quotas donnés.
  - quand le filleul accepte le parrainage son compte est créé ainsi que son premier avatar qui a un premier contact *fort*, son parrain (réciproquement le filleul est un contact four lui).

**Si au lieu d'une phrase de parrainage**, le titulaire fournit une clé longue définie par l'administrateur de l'hébergement, le compte et son premier avatar sont créés sans parrainage et avec des quotas définis par le titulaire lui-même.

>Ceci permet d'amorcer l'application avec un, ou quelques, comptes _primitifs_ sachant que le tout premier compte ne peut pas être parrainé par un autre compte ... vu qu'il est le premier.

>L'administrateur de l'hébergement peut supprimer ou changer cette clé par sécurité après création de ce ou ces comptes _primitifs_.

**Un compte,**
- est identifié par un code immuable aléatoire de 15 chiffres qui n'a pas d'intérêt pratique.
- reçoit une clé principale de cryptage immuable aléatoirement générée : celle-ci est mémorisée cryptée par une clé dérivée de la phrase secrète du compte et est donc impossible à craquer.

**Un avatar,**
- est identifié par un code immuable aléatoire de 15 chiffres qui n'a pas d'intérêt pratique.
- a un **nom immuable**, défini par le titulaire du compte : les homonymies sont permises dans l'application. Ce nom ne pourra pas être changé.
- reçoit des clés cryptographique générées aléatoirement et immuables :
  - un code aléatoire permettant de générer la clé cryptant sa **carte de visite**.
  - un couple de clés (publique / privée) d'usage interne.

## Carte de visite d'un avatar

La **carte de visite** d'un avatar d'un compte est modifiable par le titulaire du compte et comporte :
- une photo de petite dimension,
- un court texte apportant une éventuelle précision au pseudo.

Elle est mémorisée cryptée par la clé de l'avatar et est visible :
- de tout avatar X membre d'un même groupe G que A,
- de tout avatar C ayant inscrit A dans ses contacts (simple ou fort).

> _Il est possible de rencontrer deux avatars ayant même pseudo_, les homonymes étant autorisés : le code permet de les distinguer (seul cas où le code sert à quelque chose) mais surtout la carte de visite, quand les avatars en ont déclaré une, peut permettre de les distinguer.

## Mots clés d'un compte
Un mot clé d'un compte a un index, un texte très court et un émoji facultatif. C'est le titulaire d'un compte qui définit ses propres mots clés.

Les secrets des avatars personnels du compte ou des secrets partagés par le compte (de couple avec un contact ou de groupe) peuvent se voir attacher des mots clés par le compte afin de les classer / indexer.

## Création d'un avatar
Un compte peut se créer un nouvel avatar supplémentaire :
- en donnant son pseudo,
- en fixant les quotas qu'il lui attribue et prélevé sur un autre de ses avatars.

Un compte peut aussi détruire un de ses avatars (pas le dernier existant).

## Auto résiliation d'un compte
Un compte peut s'auto-détruire. 

Ses données sont effacées *mais pas tous ses secrets* : 
- pour un secret *de couple* : son exemplaire est bien détruit, mais pas l'exemplaire détenu par l'autre.
- pour un secret de groupe, le secret *appartient* au groupe et reste normalement accessible aux autres membres.

##  Disparition d'un compte

**Un compte qui ne s'est pas connecté pendant un certain temps (18 mois) est déclaré *disparu*** et est détruit (ainsi que tous ses avatars). 

Comme rien ne raccorde un compte au monde réel, ni adresse e-mail, ni numéro de téléphone ... il n'est pas possible d'informer quiconque de la disparition prochaine d'un compte.

>6 mois avant d'être détruits, les avatars du compte vont apparaître **en alerte** pour les autres avatars avec qui ils sont en contact : certains de ceux-ci peuvent avoir dans la vraie vie un moyen d'alerter leur titulaire afin qu'il se connecte une fois ce qui le fera sortir de cet état.

## Création d'un contact *simple* d'un avatar
Un avatar `A` peut inscrire un avatar `C` dans sa liste de contacts *simple* dès lors que A et C sont membres d'un même groupe G.

Ainsi A conserve l'identification complète de C (son code, son pseudo et la clé de cryptage de sa carte de visite) même si A ou C sont résiliés du groupe G où ils se sont rencontrés. A pourra ainsi inviter à un groupe ou établir un contact *fort* avec lui.

A peut associer un commentaire à un contact C (mais que C ne verra pas).

## Création d'un contact *fort* entre A et C
Pour qu'un contact devienne *fort* il faut que A et C en soient d'accord : le contact devient réciproque et indissoluble (jusqu'à disparation d'un des deux avatars).

Si C est déjà contact simple de A, A invite C à devenir contact *fort* et dès que C l'accepte le lien est établi.

Si C et A se sont rencontrés hors de l'application et souhaitent établir un contact fort :
- ils décident d'une phrase de contact connue d'eux seuls, par exemple `la framboise est précoce`.
- chacun va citer cette phrase dans l'application :
  - le premier à citer la phrase y enregistre automatiquement son identification,
  - le second à citer la phrase provoque la création du contact fort entre eux (et efface la phrase).

La phrase a une durée de vie courte, elle s'efface automatiquement par sécurité si le second avatar tarde à citer la phrase.

A peut associer un commentaire à un contact *fort* C (mais que C ne verra pas) et réciproquement.

A et C partagent une petite ardoise (moins de 140 signes) ce qui leur permet un minimum d'échange sans partager un secret.

# Groupe

Un groupe est créé par un avatar avec un **nom immuable** censé être parlant dans l'organisation, du moins pour ses membres.
- un **code** interne sur 15 chiffres lui est attribué (inutile dans la vie courante),
- une **clé de cryptage** aléatoire et immuable lui est aussi attribuée à sa création : elle ne sera transmise qu'aux membres du groupe et sert à crypter les données du groupe dont l'accès à ses secrets.

L'avatar créateur,
- a le pouvoir d'animation du groupe, 
- lui transfert un minimum de quotas de stockage de secrets prélevés sur ses propres quotas.

## Invitation d'un avatar à un groupe
Un animateur A peut *inviter* un autre avatar I dont il a l'identification complète, avec un pouvoir proposé de *lecteur*, *auteur* ou *animateur* :
- soit A et I sont membres d'un même groupe G,
- soit I est un des contacts de A, simple ou fort.

I a désormais le statut *invité* dans la liste des membres du groupe jusqu'à ce qu'il,
  - accepte l'invitation : il passe en statut *actif*,
  - ou refuse l'invitation : il passe en statut *refus*.

Chaque membre du groupe peut attribuer au groupe un intitulé qui lui est propre si le nom du groupe ne lui parle pas assez.

## Membre pressenti
N'importe quel membre *auteur* ou *animateur* peut inscrire un avatar P dont il a l'identifiant complet comme membre *pressenti* :
- sa carte de visite sera lisible dans le groupe,
- une discussion dans le groupe peut alors s'opérer sur l'opportunité d'inviter ou non P dans le groupe,
- l'invitation effective reste à discrétion d'un *animateur*.

## Pouvoir des animateurs
Un animateur peut agir sur les statuts des autres membres :
- supprimer un membre ayant un statut *invité* et n'ayant pas encore accepté,
- supprimer un membre ayant un statut *refus*,
- supprimer un membre ayant un statut *pressenti*,
- résilier un membre ayant un pouvoir *auteur* ou *lecteur*.

Un animateur peut agir sur les pouvoirs des autres membres non animateurs :
- dégrader le pouvoir d'un membre de *auteur* à *lecteur*,
- promouvoir un *lecteur* en *auteur* ou *animateur*,
- promouvoir un *auteur* à *animateur*,

Un animateur peut reprendre des quotas en excédent au groupe.

Tout membre peut,
- s'auto-résilier,
- dégrader son propre pouvoir,
- apporter des quotas au groupe afin de lui permettre d'avoir plus de secrets.

## Mots clés d'un groupe
Un mot clé d'un groupe a un index, un texte très court et un émoji facultatif.

Les mots clés peuvent être attachés aux secrets du groupe.

Les mots clés du groupe sont mis à jour par un animateur.

## Archivage d'un groupe
Un groupe peut _être archivé_ par un de ses animateurs : plus aucun secret ne peut y être ajouté / modifié.

En revanche le groupe peut continuer à avoir des mouvements de membres et ses secrets peuvent être copiés.

Un groupe peut être désarchivé par un animateur.

## Fermeture d'un groupe
Un animateur peut *fermer* un groupe : il ne peut plus y avoir de nouvelles inscriptions.

Pour rouvrir un groupe il faut que tous les animateurs aient voté vouloir le rouvrir.

## Dissolution d'un groupe
Elle s'opère quand le dernier membre actif du groupe se résilie lui-même : tous les secrets sont détruits.

Quand le dernier membre actif d'un groupe passe en état *disparu*, le groupe se dissout (plus personne ne pouvant y accéder).

# Secret

Un secret est créé dans l'un des trois contextes suivants :
- **secret personnel** d'un avatar d'un compte. Seul le titulaire du compte le connaît et peut le lire et le mettre à jour.
- **secret de couple** de deux avatars A et B contacts forts. Le secret est dédoublé en deux exemplaires, chacun propriété respective de A et de B :
  - les mises à jour faites sur un exemplaire sont reportées sur l'autre.
  - si A ou B détruit son exemplaire ceci n'affecte pas l'autre exemplaire.
  - si B par exemple est considéré comme disparu, les secrets du couple restent lisible par A (les exemplaires de A restent accessibles).
  - les mots clés attachés par A à son exemplaire sont indépendants des mots clés attachés par B à son exemplaire.
- **secret de groupe**. Seuls les membres actifs du groupe y ont accès et peuvent agir dessus.
  - le secret a un seul exemplaire partagé, toute mise à jour est visible par tous les membres du groupe.
  - le dernier auteur du secret et tout animateur peut attribuer au secret des mots clés du groupe.
  - tout membre peut attribuer de plus ses propres mots clés personnels (non visibles des autres membres).

**Un secret est modifiable**, son texte comme sa pièce jointe, du moins jusqu'à ce que ce secret soit basculé en état *archivé* auquel cas il devient immuable. L'état d'un secret indique par qui il peut être modifié :
- *normal* : le secret est modifiable par tous ceux y ayant accès ce qui change selon qu'il s'agit d'un secret personnel, de couple ou de groupe.
- *restreint* : le secret n'est modifiable que par le dernier avatar l'ayant modifié.
- *archivé* : le secret n'est plus modifiable.

L'état d'un secret de groupe peut être forcé par un animateur du groupe.

Un secret de groupe garde la liste ordonnée des avatars l'ayant modifié, les plus récents en tête mais sans doublons.

**Un secret peut *faire référence* un autre secret** de la même _famille_ : un secret personnel à un autre secret personnel du même avatar, un secret de couple à un secret du même couple, un secret de groupe à un autre secret du même groupe. L'affichage peut ainsi être hiérarchique :
- à la racine apparaissent tous les secrets relatifs à aucun.
- en dépliant un secret S1 on voit tous les secrets Si faisant référence à S1 et ainsi de suite.

> Une pièce jointe peut être lue dans une session en ligne et sauvegardée cryptée (ou non !) localement par exemple dans *Téléchargement*. Ultérieurement au cours d'une session hors ligne, la pièce jointe peut être ré-obtenue depuis *Téléchargement* et affichée.

## Mots clés : indexation / filtrage / annotation personnelle des secrets
Il existe une liste de 50 mots clés génériques de l'application définis à son déploiement par l'administrateur de l'hébergement. Par exemple : _à relire, important, à cacher, à traiter d'urgence, ..._ 

Chaque mot clé a un texte et un possible émoji.

Chaque compte a une liste de 100 mots clés qu'il définit lui-même. Par exemple : _écologie, économie, documentation, mot de passe, ..._ 

Chaque groupe a aussi une liste de 100 mots clé à sa disposition.

Chaque secret peut être indexé par ces mots clés à discrétion de chaque compte pour lui-même ce qui n'affecte pas les indexations des autres.
- les libellés des mots clés peuvent changer,
- l'affectation de mots clés aux secrets également, même pour un secret archivé.

# Maîtrise du volume des secrets : quotas

Aucun compte, aucun administrateur ne peut connaître la liste des comptes et de leurs avatars ni n'a de pouvoir pour _bloquer_ un compte ou le dissoudre. 

Sans instauration de quotas par compte, n'importe quel compte pourrait créer autant de secrets qu'il veut et saturer l'espace physique au détriment des autres. C'est pour cela que chaque compte dispose de _quotas_ de volume de secrets.

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

Un quota comporte 4 chiffres : 
- le volume maximal autorisé des secrets permanents.
- le volume maximal autorisé des pièces jointes pour les secrets permanents,
- le volume maximal autorisé des secrets **créés** chaque mois.
- le volume maximal autorisé des pièces jointes **créées** chaque mois.

## Banque centrale des quotas
La _Banque centrale_ dispose de quotas définis par l'administrateur de l'hébergement en fonction des ressources techniques dont il dispose.

Normalement l'attribution de quotas à un avatar ou à un groupe se fait par transfert de quotas déjà attribués à un autre avatar ou groupe.

Toutefois un compte qui connaîtrait la clé de la _Banque centrale_ peut y prélever des quotas pour les attribuer à un avatar ou un groupe sans prendre sur les siens : ceci décrémente d'autant les quotas disponibles de la _banque centrale_.

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

Un volume permanent peut temporairement excéder le quota autorisé pour un avatar, quand ceci résulte d'une action d'un autre avatar :
- le secret permanent d'un couple A-B est mis à jour en expansion par B (sans dépasser les quotas de B),
- mais ceci lui fait dépasser le volume maximal de A : la mise à jour est acceptée pour ne pas bloquer B. Toutefois A devra ultérieurement supprimer des secrets permanents, ou augmenter ses quotas.

# Contrôle éthique
A partir du moment où un compte respecte ses quotas il est impossible à une quelconque autorité de le détruire. Les textes des secrets lui sont strictement privés et peuvent en conséquence être éthiquement incorrects au regard d'autres personnes ou organisations. Toutefois :
- si un avatar A partage avec B des secrets que B considère comme non acceptables, quelqu'en soit la raison, B peut déclarer ne plus rien partager avec A.
- dans la cadre d'un groupe, un animateur peut résilier un membre du groupe et chacun peut s'auto résilier.

Bref nul n'est obligé de lire des secrets qu'il ne juge pas acceptables.

L'application est agnostique vis à vis des contenus des secrets qui peuvent être n'importe quoi, en bien ou en mal ... et selon ce que chacun considère comme bien ou mal: c'est une application qui reste du niveau de la communication / mémorisation personnelle ou privée, comme celle que peut avoir un groupe restreint d'amis discutant librement entre eux.

# Annexe : liste des opérations
Un opération est initiée par un utilisateur et modifie l'état des données.

## Opérations sans connexion
Ces actions peuvent être déclenchées **avant** par un utilisateur avant de s'être authentifié.

### Création d'un compte
Parrainé ou non : en cas de succès l'utilisateur est authentifié après cette opération, les opérations suivantes s'effectuent dans le contexte d'une session identifié par le compte créé.

### Connexion à un compte
Si la phrase secrète fourni authentifie l'utilisateur, les opérations suivantes s'effectueront dans le contexte d'une session identifié par le compte correspondant.

Le compte et ses avatars ont désormais environ 18 mois sans connexion avant d'être considérés comme *disparu*.

## Opérations portant sur le compte de la session
... donc après connexion à un compte.

### Création d'un avatar

### Suppression d'un avatar
Sauf le dernier du compte.

### Mise à jour des mots clés du compte

### Auto-destruction du compte

### Transfert de quotas
depuis / vers un avatar ou un groupe, ou la banque centrale.

### Parrainage d'un nouveau compte 
Déclaration d'une phrase de parrainage avec un nom d'avatar pour le filleul et attribution de quotas. Un parrainage peut être :
- mis à jour avant son acceptation,
- supprimé par le parrain avant son acceptation.

## Opérations portant sur un avatar

### Création / mise à jour de sa carte de visite

### Création d'un secret personnel

### Création d'un groupe

### Acceptation ou refus d'une invitation à un groupe

### Création / mise à jour / suppression d'un contact simple
La mise à jour concerne le commentaires du compte à propos du contact.

### Proposition à un contact simple de devenir *fort*

### Acceptation / refus d'une proposition d'établissement d'un contact fort

### Mise à jour de l'ardoise partagée avec un contact fort

### Blocage / déblocage du partage de secrets avec un contact fort

### Déclaration d'une phrase de contact
Si la phrase n'avait pas encore été déclarée, l'avatar dépose son identification et précise s'il accepte ou non le partage de secrets lors de l'établissement du contact fort.

Si la phrase avait été déclarée par l'autre avatar, le contact fort est établi (ou refusé) avec ou sans partage de secrets.

### Création d'un secret de couple avec un contact fort

## Opération portant sur un groupe

### Invitation d'un avatar à devenir membre
et mise à jour de cette invitation (pouvoir proposé *lecteur, auteur, animateur*), voire suppression.

### Enregistrement d'un avatar en tant que membre pressenti

### Mise à jour d'un membre
Changement de son pouvoir, résiliation, auto-résiliation, suppression quand il n'est pas actif (et ne l'a jamais été).

### Mise à jour des mots clé du groupe

### Changement de l'intitulé du groupe visible du compte

### Création d'un secret de groupe

## Opérations portant sur un secret

### Mise à jour du texte / pièce jointe

### Changement de son autorisation de modification (libre, restreinte, archivé)

### Suppression d'un secret

### Passage d'un secret temporaire à permanent

### Modification des mots clés attachés au secret
Pour un secret de groupe avec la distinction des mots clés du groupe et des mots clés personnels.

