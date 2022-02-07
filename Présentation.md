# L'application Boîtes à secrets

Toute organisation `monorg` qui le souhaite peut disposer de l'application Web _Boîtes à secrets_ en s'adressant, soit à un hébergeur de confiance, soit en s'hébergeant elle-même. Ses membres utilisent un navigateur pour accéder à leur application par une URL comme `https://monhebergeur.net/monorg`.
- Les organisations sont autonomes les unes des autres, leurs données sont enregistrées dans des bases de données différentes, même si plusieurs organisations utilisent par économie un même hébergement.
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

## Modes *synchronisé*, *incognito*, *avion* et *visio*

### Mode synchronisé 
**C'est le mode normal, les données sont synchronisées entre le stockage central et local** :
- le fonctionnement est accéléré,
- ça nécessite à la fois que le serveur soit accessible par le réseau et que le stockage local ait été autorisé par l'utilisateur.

### Mode incognito
**Il n'y a pas de stockage local, toutes les données viennent du serveur** ce qui nécessite un accès au réseau. Le fonctionnement est plus lent à l'initialisation. Aucune trace n'est laissée sur l'appareil (utile au cyber-café ou sur le mobile d'un.e ami.e).

### Mode avion
**Le réseau n'est pas utilisé : seul le stockage local est mis à contribution** :
- c'est parfois utile quand on craint que l'environnement réseau soit *surveillé / peu sûr* ou techniquement instable, ou qu'on souhaite qu'aucun accès réseau ne puisse être tracé.
- si une session de l'application locale s'est déjà exécutée une fois dans le navigateur pour un compte, celui-ci retrouve, ses données telles que synchronisées lors de la dernière session exécutée en mode *synchronisé* sur ce poste pour ce compte.  
- les informations sont plus ou moins *en retard* par rapport à l'état de référence détenu en central, mais peuvent être très utiles.
- les mises à jour ne sont pas possibles : **toutefois les textes de nouveaux secrets ou des mises à jour de secrets peuvent être préparées pour être injectés dans leurs secrets lors de la prochaine session en mode *synchronisé***.

> **Il est ainsi possible de disposer de plusieurs copies synchronisées de ses secrets sur des appareils différents.**

### Mode dégradé visio
C'est un mode dégradé quand ni le réseau, ni le stockage local ne sont accessibles.
- depuis un mode initial *synchronisé*,
  - si le réseau n'est plus accessible, la session est dégradée en mode *avion*.
  - si le stockage local n'est plus accessible (espace saturé par exemple), la session est dégradée en mode *incognito*.
- depuis un mode initial *incognito* (ou dégradé depuis *synchronisé*),
  - si le réseau n'est plus accessible, la session est dégradée en mode *visio*.
- depuis un mode initial *avion* (ou dégradé depuis *synchronisé*),
  - si le stockage local n'est plus accessible, la session est dégradée en mode *visio*.

En mode *dégradé* **visio** les données actuellement chargées en session peuvent continuer à être consultées mais aucune mise à jour ne peut être faite. 

> Pour utiliser le mode **avion**, il n'est pas indispensable de couper le réseau, le choix se fait à l'accueil de l'application. Toutefois, si le réseau est accessible, la version de l'application est éventuellement rechargée si celle du serveur central est plus récente : un échange sur le réseau peut alors être détecté par les outils de surveillance.  
> Pour être totalement indétectable il faut utiliser le mode **avion** de son appareil et choisir le mode **avion** de l'application.

# Secrets, comptes et avatars, groupes, contacts

## Secrets
Un **secret** est un *texte* court (moins de 4000 signes). 
- Le texte est lisible avec quelques éléments de décoration (*gras, italique, listes ...*) selon la syntaxe MD.
- Le début du texte, les 140 premiers caractères ou la première ligne si elle est plus courte, est _l'aperçu ou titre_ du secret, le texte qui s'affiche à l'écran quand on y voit une liste de secrets.

**Un secret est modifiable**, son texte comme ses pièces jointes, du moins jusqu'à ce que ce secret soit basculé en état *archivé* auquel cas il devient immuable.

**Par défaut un secret est temporaire**, il s'efface automatiquement au bout de quelques semaines, mais il peut être rendu **permanent**, ou créé directement permanent, et n'est alors effacé que sur demande explicite.

**Un secret a des _mots clés_** : le filtrage à l'affichage des secrets peut se faire par sélection de mots clés selon leurs sujets (thème abordé ...), leurs états (_favori, obsolète, important, à lire_ etc.). Le filtrage peut être affiné selon la présence d'une portion de texte (mot ...) dans le titre ou le texte complet.

**Un secret peut avoir des _pièces jointes_**
- une pièce jointe a un _nom_, comme un nom de fichier, ayant en général (sauf sur MAC) une extension (`.jpg .pdf .md` ...) correspondant à son type MIME.
- une pièce jointe a une taille raisonnable : les clips vidéo doivent être courts.
- on peut changer les pièces jointes d'un secret (même sans changer le texte du secret), en ajouter, en supprimer, en remplacer une par une nouvelle version.
- les pièces jointes de type texte _Markdown_ (`.md`), _image_ (`.jpg .png .svg`), _audio_ (`.mp3 `...) et _video_ peuvent s'afficher dans le navigateur qui peut soit les afficher, soit ouvrir une application qui peut l'afficher, soit la charger sur un espace local de téléchargement.

## Comptes et leurs avatars
Un compte a un ou plusieurs **avatars** qui sont comme autant de personnalités différentes. Une même personne peut avoir des compartiments de vie différents, contribuer à des réflexions ou des actions différentes. Ce cloisonnement est possible en se définissant plusieurs avatars :
- le titulaire d'un compte est le seul à pouvoir connaître la liste de ses propres avatars.
- un compte ne connaît des autres comptes que leurs avatars. Il est impossible, même à l'administrateur d'hébergement de l'application, de déterminer au regard de deux avatars s'ils correspondent au même compte ou non.

> Un avatar dispose de secrets **personnels** qui ne sont accessibles que par lui et ne seront jamais partagés avec d'autres.

## Groupes d'avatars partageant des secrets
Un avatar peut créer un **groupe** réunissant plusieurs avatars qu'il a invités et qui ont accepté cette invitation.

> Un groupe dispose de secrets **de groupe** qui ne sont accessibles qu'aux membres du groupe.

Les avatars membres d'un groupe partagent les secrets du groupe :
- dès qu'ils sont membres ils peuvent accéder à tous les secrets du groupe, même ceux écrits avant leur arrivée dans le groupe.
- dès qu'ils sont résiliés du groupe, ils ne peuvent plus accéder aux secrets du groupe.

**Chaque membre du groupe** a un niveau de pouvoir :
- **lecteur** : il ne peut que lire les secrets du groupe.
- **auteur** : il peut lire, créer, modifier les secrets du groupe.
- **animateur** : il peut de plus inviter des avatars à rejoindre le groupe et les résilier (sauf ceux eux-mêmes animateurs). Le créateur d'un groupe en est le premier animateur. 

## Contacts personnels d'un avatar
### Contact *simple*
Un avatar `A` peut inscrire un avatar `C` dans sa liste de contacts dès lors qu'il en a son identification complète : `C` verra alors `A` comme contact quand il ouvrira une session (ou immédiatement si sa session est ouverte).

A et C **peuvent** alors partager **des secrets de couple** : un secret de couple est _dédoublé_ sur chacun des contacts et toute mise à jour répercutée sur les deux exemplaires. L'un comme l'autre peuvent détruire leur exemplaire d'un secret partagé avec l'autre sans que ceci n'affecte l'accès de l'autre à son propre exemplaire.

L'un des deux peut décider de ne plus accepter le partage de secrets avec l'autre : ceci ne vaut que pour les secrets futurs, ceux partagés antérieurement restent accessibles à chacun.

A et C partagent une petite *ardoise textuelle* (140 signes), offrant un minimum d'échange sans utiliser un secret partagé. Ceci est utile en particulier quand l'un des deux a bloqué le partage de secrets : l'ardoise reste le seul moyen de communiquer a minima.

Un contact reste établi jusqu'à disparition effective de A ou C : si C disparaît par exemple, les exemplaires pour A de ses secrets partagés avec C restent accessibles à A.

### Contact rencontré hors de l'application
Si A et C n'ont jamais été membres d'un même groupe, ils ne connaissent pas l'identification complète de l'autre et ne peuvent pas s'enregistrer comme contact.

Mais ils peuvent se connaître par ailleurs et peuvent établir un contact : A par exemple déclare une **phrase de rencontre** et la communique hors de l'application à C. C en frappant cette phrase dans l'application récupère l'identité complète de A et devient contact de A (avec ou sans partage de secrets).

# Compte et avatars

## Création d'un compte
Pour se créer un compte le titulaire doit déclarer :
- sa **phrase secrète** d'accès et ne devra jamais l'oublier car elle n'est mémorisée nulle part en clair dans l'application. 
  - elle sert à authentifier le titulaire à sa connexion à l'application.
  - **elle a deux lignes**, une première d'au moins 16 signes et une seconde d'au moins 16 signes. L'application n'accepte pas d'avoir 2 comptes ayant des phrases secrètes ayant une même première ligne.
  - la phrase secrète peut être changée ... à condition de pouvoir fournir celle en cours.
  - l'oubli de cette phrase est irrémédiable : indirectement elle crypte toutes les informations et secrets accessibles au compte.
  - l'administrateur d'hébergement lui-même n'a aucun moyen technique de la retrouver.
- le **nom, immuable, de son premier avatar** (un pseudo).
- la **phrase de parrainage** conjointement fixée avec un autre compte rencontré (hors de l'application) et ayant accepté de le *parrainer* : 
  - parrain et filleul ont convenu de cette phrase et du nom du premier avatar du compte filleul.
  - le parrain a accepté de prendre sur ses propres quotas d'espace pour ses secrets pour en donner au compte filleul.
  - le parrain a enregistré la phrase de parrainage avec le nom d'avatar du filleul et les quotas donnés.
  - quand le filleul accepte le parrainage, son compte est créé ainsi que son premier avatar qui a un premier contact, son parrain (réciproquement le filleul est un contact du parrain).

**Un compte,**
- est identifié par un numéro immuable aléatoire de 15 chiffres qui n'a pas d'intérêt pratique.
- reçoit une clé principale de cryptage immuable aléatoirement générée : celle-ci est mémorisée cryptée par une clé dérivée de la phrase secrète du compte (impossible à craquer par force brute).

**Un avatar,**
- est identifié par un numéro immuable aléatoire de 15 chiffres qui n'a pas d'intérêt pratique.
- a un **nom immuable**, défini par le titulaire du compte : les homonymies sont permises dans l'application (ce nom ne pourra pas être changé). Une partie du numéro accolé au nom lève les homonymies.
- reçoit des clés cryptographique générées aléatoirement et immuables :
  - la clé cryptant sa **carte de visite**.
  - un couple de clés (publique / privée) d'usage interne.

## Carte de visite d'un avatar

La **carte de visite** d'un avatar d'un compte est modifiable par le titulaire du compte et comporte :
- une photo de petite dimension,
- un court texte apportant une éventuelle précision au pseudo.

Elle est mémorisée cryptée par la clé de l'avatar et est visible :
- de tout avatar X membre d'un même groupe G que A,
- de tout avatar C ayant inscrit A dans ses contacts.

> _Il est possible de rencontrer deux avatars ayant même pseudo_, les homonymes étant autorisés : le suffixe permet de les distinguer mais surtout la carte de visite, quand les avatars en ont déclaré une, peut permettre de lever une éventuelle ambiguïté.

## Mots clés d'un compte et de l'organisation
Un mot clé d'un compte a un index (de 1 à 99), un texte très court pouvant contenir un émoji (de préférence en tête). Le titulaire d'un compte définit ses propres mots clés.

L'organisation déclare aussi des mots clés (d'index 200 à 255) : ils sont communs à tous et déclarés dans la configuration de l'hébergement.

Les secrets des avatars personnels du compte ou des secrets partagés par le compte (de couple avec un contact ou de groupe) peuvent se voir attacher des mots clés par le compte afin de les classer / filtrer.

## Création d'un avatar
Un compte peut se créer un nouvel avatar supplémentaire en donnant son pseudo.

Un compte peut aussi détruire un de ses avatars (sauf le dernier existant).

## Auto résiliation d'un compte
Un compte peut s'auto-détruire. 

Ses données sont effacées *mais pas tous ses secrets* : 
- pour un secret *de couple* : son exemplaire est bien détruit, mais pas l'exemplaire détenu par l'autre.
- pour un secret de groupe, le secret *appartient* au groupe et reste normalement accessible aux autres membres.

##  Disparition d'un compte

**Un compte qui ne s'est pas connecté pendant un certain temps (12 mois) est déclaré *disparu*** et est détruit (ainsi que tous ses avatars). 

Comme rien ne raccorde un compte au monde réel, ni adresse e-mail, ni numéro de téléphone ... il n'est pas possible d'informer quiconque de la disparition prochaine d'un compte.

> un certain temps avant d'être détruits, les avatars du compte vont apparaître **en alerte** pour les autres avatars avec qui ils sont en contact : certains de ceux-ci peuvent avoir dans la vraie vie un moyen d'alerter leur titulaire afin qu'il se connecte une fois ce qui le fera sortir de cet état.

## Création d'un contact d'un avatar
Un avatar `A` peut inscrire un avatar `C` dans sa liste de contacts dès lors que A et C sont membres d'un même groupe G.

Ainsi A conserve l'identification complète de C (son code, son pseudo et la clé de cryptage de sa carte de visite) même si A ou C sont résiliés du groupe G où ils se sont rencontrés. A pourra ainsi inviter C à un groupe.

A peut associer un commentaire et des mots clés à un contact C (que C ne voit pas).

Pour que A et C puissent partager des secrets *de couple* il faut qu'il en soit d'accord tous les deux.

Si C et A se sont rencontrés hors de l'application et souhaitent établir un contact :
- ils décident d'une phrase de contact connue d'eux seuls, par exemple `la framboise est précoce`.
- chacun va citer cette phrase dans l'application :
  - le premier à citer la phrase y enregistre automatiquement son identification,
  - le second à citer la phrase provoque la création du contact entre eux (et efface la phrase).

La phrase a une durée de vie courte, elle s'efface automatiquement par sécurité si le second avatar tarde à citer la phrase.

A et C partagent une petite ardoise (moins de 140 signes) ce qui leur permet un minimum d'échange sans partager un secret.

# Groupe

Un groupe est créé par un avatar avec un **nom immuable** censé être parlant dans l'organisation, du moins pour ses membres.
- un **numéro** interne sur 15 chiffres lui est attribué (inutile dans la vie courante),
- une **clé de cryptage** aléatoire et immuable lui est aussi attribuée à sa création : elle ne sera transmise qu'aux membres du groupe et sert à crypter les données du groupe dont l'accès à ses secrets.

L'avatar créateur,
- a le pouvoir d'animation du groupe, 
- lui transfère un minimum de quotas de stockage de secrets prélevés sur ses propres quotas.

## Carte de visite d'un groupe

La **carte de visite** d'un groupe est modifiable par un animateur du groupe et comporte :
- une photo (logo, image ...) de petite dimension,
- un court texte décrivant l'objet du groupe.

Elle est mémorisée cryptée par la clé du groupe et est visible de tous les avatars membres actifs du groupe.

## Invitation d'un avatar à un groupe
Un animateur A peut *inviter* un autre avatar I dont il a l'identification complète, avec un pouvoir proposé de *lecteur*, *auteur* ou *animateur* :
- soit A et I sont membres d'un même autre groupe G,
- soit I est un des contacts de A.

I a désormais le statut *invité* dans la liste des membres du groupe jusqu'à ce qu'il,
  - accepte l'invitation : il passe en statut *actif*,
  - ou refuse l'invitation : il passe en statut *refus*.

Chaque membre du groupe peut attacher au groupe des mots clés et un intitulé / commentaire qui lui est propre si le nom du groupe ne lui parle pas assez.

## Membre pressenti
N'importe quel membre *auteur* ou *animateur* peut inscrire un avatar P dont il a l'identifiant complet comme membre *pressenti* :
- sa carte de visite sera lisible dans le groupe,
- une discussion dans le groupe peut alors s'opérer sur l'opportunité d'inviter ou non P dans le groupe,
- l'invitation effective reste à discrétion d'un *animateur*.

## Pouvoir des animateurs
Un animateur peut agir sur les statuts des autres membres :
- supprimer un membre ayant un statut *invité* et n'ayant pas encore accepté,
- supprimer un membre ayant un statut *refus* (bien que ce soit automatique au bout de quelques jours),
- supprimer un membre ayant un statut *pressenti*,
- résilier un membre ayant un pouvoir *auteur* ou *lecteur*.

Un animateur peut agir sur les pouvoirs des autres membres non animateurs :
- dégrader le pouvoir d'un membre de *auteur* à *lecteur*,
- promouvoir un *lecteur* en *auteur* ou *animateur*,
- promouvoir un *auteur* à *animateur*,

Tout membre peut,
- s'auto-résilier,
- dégrader son propre pouvoir,
- apporter des quotas au groupe afin de lui permettre d'avoir plus de secrets.

## Mots clés d'un groupe
Un mot clé d'un groupe a un index de 100 à 199, un mot pouvant contenir un émoji, de préférence en tête.

Les mots clés peuvent être attachés aux secrets du groupe.

Les mots clés du groupe sont mis à jour par un animateur du groupe.

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
- **secret de couple** de deux avatars A et B contacts. Le secret est dédoublé en deux exemplaires, chacun propriété respective de A et de B :
  - les mises à jour faites sur un exemplaire sont reportées sur l'autre.
  - si A ou B détruit son exemplaire ceci n'affecte pas l'autre exemplaire.
  - si B par exemple est considéré comme disparu, les secrets du couple restent lisible par A (les exemplaires de A restent accessibles).
  - les mots clés attachés par A à son exemplaire sont indépendants des mots clés attachés par B à son exemplaire.
- **secret de groupe**. Seuls les membres actifs du groupe y ont accès et peuvent agir dessus.
  - le secret a un seul exemplaire partagé, toute mise à jour est visible par tous les membres du groupe.
  - tout animateur peut attribuer au secret des mots clés du groupe ou de l'organisation.
  - tout membre peut attribuer de plus ses propres mots clés : mots clés du groupe, de l'organisation ou les siens propres (ces derniers ne sont pas interprétables par les autres membres et en conséquence masqués).

**Un secret est modifiable**, son texte comme ses pièces jointes, du moins jusqu'à ce que ce secret soit basculé en état *protégé* auquel cas il devient immuable. L'état d'un secret indique par qui il peut être modifié :
- *normal* : le secret est modifiable par tous ceux y ayant accès ce qui change selon qu'il s'agit d'un secret personnel, de couple ou de groupe.
- *exclusif* : le secret n'est modifiable que par un avatar.
- *protégé* : le secret n'est plus modifiable.

L'état d'un secret de groupe peut être forcé par un animateur du groupe.

Un secret de groupe garde la liste ordonnée des avatars l'ayant modifié, les plus récents en tête mais sans doublons.


**Un secret peut *faire référence* un autre secret** de la même _famille_ : un secret de couple à un secret du même couple, un secret de groupe à un autre secret du même groupe. Un secret personnel peut référencer n'importe quel secret.

L'affichage peut ainsi être hiérarchique :
- à la racine apparaissent tous les secrets relatifs à aucun.
- en dépliant un secret S1 on voit tous les secrets Si faisant référence à S1 et ainsi de suite.

> Une pièce jointe peut être lue dans une session en ligne et sauvegardée cryptée (ou non !) localement par exemple dans *Téléchargement*.

## Mots clés : indexation / filtrage / annotation personnelle des secrets
Il existe une liste de 56 mots clés (de 200 à 255) génériques de l'application définis à son déploiement par l'administrateur de l'hébergement. Par exemple : _à relire, important, à cacher, à traiter d'urgence, ..._ 

Chaque mot clé a un texte et un possible émoji.

Chaque compte a une liste de 99 mots clés (de 1 à 99) qu'il définit lui-même. Par exemple : _écologie, économie, documentation, mot de passe, ..._ 

Chaque groupe a aussi une liste de 100 mots clé (de 100 à 199) à sa disposition.

Chaque secret peut être indexé par ces mots clés à discrétion de chaque compte pour lui-même ce qui n'affecte pas les indexations des autres.
- les libellés des mots clés peuvent changer,
- l'affectation de mots clés aux secrets également, même pour un secret archivé.

# Spécificités du mode _avion_
## Consultation seulement
Les miss à jour sont interdites : les secrets peuvent n'être que lus, les invitations, gestion des contacts, etc. ne sont pas possibles.

### Notes en brouillon
Toutefois en mode _avion_ il est possible de créer des **notes** : ce sont des textes qui pourront être utilisés plus tard en mode _synchronisé_ pour être copiés/collés dans des secrets par exemple.

### Pièces jointes en attente
De même des pièces jointes peuvent être préparées : elles référencent des secrets précis (elles sont cryptées par la clé des secrets). Elles pourront être chargées sur le serveur à l'occasion de la prochaine session _synchronisée_. Cette action n'est pas automatique par sécurité : elle doit être déclenchée explicitement, typiquement pour éviter d'écraser une pièce jointe plus récente par une plus ancienne capturée en mode _avion_.

## Accès aux pièces jointes en mode *_avion_
En raison de leur volume les pièces jointes résident sur le serveur et ne sont pas mémorisées dans les bases locales des sessions : elles ne sont lisibles qu'en mode _synchronisé_ ou _incognito_ mais pas en mode _avion_.

Toutefois pour chaque appareil distinctement, le titulaire d'un compte peut **cocher** des pièces jointes pour accéder à leur contenu en mode _avion_ :
- ceci est à faire pièce jointe par pièce jointe et sur autant d'appareils que souhaité : tous n'ont pas forcément les mêmes pièces jointes cochées pour accès en mode _avion_.
- une pièce jointe ainsi cochée est maintenue à jour, synchronisée, en cas de changement, durant une session synchronisée.
- on peut décocher une pièce jointe cochée, elle ne sera plus mémorisée localement.
- si le secret disparaît, les pièces jointes correspondantes sont aussi supprimées localement.

> Un excès de pièces jointes accessibles en mode _avion_ peut entraîner le blocage de sessions, le stockage local tombant en erreur.
