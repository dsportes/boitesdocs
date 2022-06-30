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
- si une session de l'application locale s'est déjà exécutée une fois dans le navigateur pour un compte, celui-ci retrouve ses données telles que synchronisées lors de la dernière session exécutée en mode *synchronisé* sur ce poste pour ce compte.  
- les informations sont plus ou moins *en retard* par rapport à l'état de référence détenu en central, mais peuvent être très utiles.
- les mises à jour ne sont pas possibles : **toutefois les textes de nouveaux secrets ou des mises à jour de secrets peuvent être préparées pour être injectés dans leurs secrets lors de la prochaine session en mode *synchronisé***.

> **Il est ainsi possible de disposer de plusieurs copies synchronisées de ses secrets sur des appareils différents.**

### Mode dégradé visio
C'est un mode dégradé quand ni le réseau, ni le stockage local ne sont accessibles.
- depuis un mode initial *synchronisé*,
  - si le réseau n'est plus accessible, la session est dégradée en mode *avion*.
  - si le stockage local n'est plus accessible (espace saturé par exemple), la session est dégradée en mode *incognito*.
- depuis un mode *incognito* (initial ou dégradé depuis *synchronisé*),
  - si le réseau n'est plus accessible, la session est dégradée en mode *visio*.
- depuis un mode *avion* (initial ou dégradé depuis *synchronisé*),
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
- les pièces jointes de type texte _Markdown_ (`.md`), _image_ (`.jpg .png .svg`), _audio_ (`.mp3 `...) et _video_ peuvent s'afficher dans le navigateur qui peut, soit les afficher, soit ouvrir une application qui peut l'afficher, soit la charger sur un espace local de téléchargement.

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
  - l'administrateur de l'hébergement lui-même n'a aucun moyen technique de la retrouver.
- le **nom, immuable, de son premier avatar** (un pseudo).
- la **phrase de parrainage** conjointement fixée avec un autre compte rencontré (hors de l'application) et ayant accepté de le *parrainer* : 
  - parrain et filleul ont convenu de cette phrase et du nom du premier avatar du compte filleul.
  - le parrain a accepté de prendre sur ses quotas d'espace pour donner au compte filleul un forfait de ressources.
  - le parrain a enregistré la phrase de parrainage avec le nom d'avatar du filleul et les forfaits attribués.
  - quand le filleul accepte le parrainage, son compte est créé ainsi que son premier avatar qui a un premier contact, son parrain (réciproquement le filleul est un contact du parrain).

**Un compte,**
- est identifié par un numéro immuable aléatoire de 15 chiffres.
- reçoit une clé principale de cryptage immuable aléatoirement générée : celle-ci est mémorisée cryptée par une clé dérivée de la phrase secrète du compte (impossible à craquer par force brute).

**Un avatar,**
- est identifié par un numéro immuable aléatoire de 15 chiffres.
- a un **nom immuable**, défini par le titulaire du compte : les homonymies sont permises dans l'application (ce nom ne pourra pas être changé). Une partie du numéro accolé au nom lève les homonymies.
- reçoit des clés cryptographique générées aléatoirement et immuables :
  - la clé cryptant sa **carte de visite**.
  - un couple de clés de cryptage (publique / privée) utilisée pour les invitations à des groupes.

## Carte de visite d'un avatar

La **carte de visite** d'un avatar d'un compte est modifiable par le titulaire du compte et comporte :
- une photo de petite dimension,
- un court texte apportant une éventuelle précision au nom de l'avatar.

Elle est mémorisée cryptée par la clé de l'avatar et est visible :
- de tout avatar X membre d'un même groupe G que A,
- de tout avatar C ayant inscrit A dans ses contacts.

> _Il est possible de rencontrer deux avatars ayant même pseudo_, les homonymes étant autorisés : la fin du numéro interne permet de les distinguer mais surtout la carte de visite, quand les avatars en ont déclaré une, peut permettre de lever une éventuelle ambiguïté.

## Mots clés d'un compte et de l'organisation
Un mot clé d'un compte a un index (de 1 à 99): le mot peut contenir un émoji (de préférence en tête). Le titulaire d'un compte définit ses propres mots clés.

L'organisation déclare aussi des mots clés (d'index 200 à 255) : ils sont communs à tous et déclarés dans la configuration de l'hébergement. Quelques mots clés (à partir de 250) ont une signification interprétée, donc ne pouvant pas être configurée.

Les secrets des avatars personnels du compte ou des secrets partagés par le compte (de couple avec un contact ou de groupe) peuvent se voir attacher des mots clés par le compte afin de les classer / filtrer.

## Création d'un avatar
Un compte peut se créer un nouvel avatar supplémentaire en donnant son nom.

Un compte peut aussi détruire un de ses avatars (sauf le dernier existant).

## Auto résiliation d'un compte
Un compte peut s'auto-détruire. 

Ses données sont effacées *mais pas tous ses secrets* : 
- pour un secret *de couple* : son exemplaire est bien détruit, mais pas l'exemplaire détenu par l'autre.
- pour un secret de groupe, le secret *appartient* au groupe et reste normalement accessible aux autres membres.

##  Disparition d'un compte

**Un compte qui ne s'est pas connecté pendant un certain temps (12 mois) est déclaré *disparu*** et est détruit (ainsi que tous ses avatars). 

Comme rien ne raccorde un compte au monde réel, ni adresse e-mail, ni numéro de téléphone ... il n'est pas possible d'informer quiconque de la disparition prochaine d'un compte.

> Un certain temps avant d'être détruits, les avatars du compte vont apparaître **en alerte** pour les autres avatars avec qui ils sont en contact : certains de ceux-ci peuvent avoir dans la vraie vie un moyen d'alerter leur titulaire afin qu'il se connecte une fois ce qui le fera sortir de cet état.

## Création d'un contact d'un avatar
Un avatar `A` peut inscrire un avatar `C` dans sa liste de contacts dès lors que A et C sont membres d'un même groupe G.

Ainsi A conserve l'identification complète de C (son code, son nom et la clé de cryptage de sa carte de visite) même si A ou C sont résiliés du groupe G où ils se sont rencontrés. A pourra ainsi inviter C à un groupe.

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
- dégrader son propre pouvoir.

## Mots clés d'un groupe
Un mot clé d'un groupe a un index de 100 à 199, un mot pouvant contenir un émoji, de préférence en tête.

Les mots clés peuvent être attachés aux secrets du groupe.

Les mots clés du groupe sont mis à jour par un animateur du groupe.

## Archivage d'un groupe
Un groupe peut _être archivé_ par un de ses animateurs : plus aucun secret ne peut y être ajouté / modifié.

En revanche le groupe peut continuer à avoir des mouvements de membres et ses secrets peuvent être copiés.

Un groupe peut être désarchivé par un animateur.

## Fermeture d'un groupe
Un animateur peut *fermer* un groupe : il ne peut plus y avoir de nouvelles invitations.

Pour rouvrir un groupe il faut que tous les animateurs aient voté vouloir le rouvrir.

## Dissolution d'un groupe
Elle s'opère quand le dernier membre actif du groupe se résilie lui-même : tous les secrets sont détruits.

Quand le dernier membre actif d'un groupe passe en état *disparu*, le groupe s'auto-dissout (plus personne ne pouvant y accéder).

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

**Secrets voisins**
Au début il y a un secret A, normal.

Puis quelqu'un crée un autre secret B en le déclarant _voisin_ de A. Quelqu'un encore peut créer un secret C _voisin_ de A (s'il le déclare voisin de B, en fait il est créé voisin de A).

L'intérêt est que si quelqu'un consulte C par exemple, il aura sous les yeux la liste des voisins (A, B, C en l'occurrence).

Ceci permet de créer des sortes du bulles autour d'un secret initial et traitant tous de la même chose. 
- si A est un secret d'un groupe par exemple, rien n'empêche de créer des secrets D E F personnels voisins de A. De même pour un secret de couple.
- quand il est dit qu'on voit la liste de tous ses voisins quand on affiche un secret c'est à nuancer : on ne voit que les secrets qu'on a le droit de voir.
- si le secret A est supprimé, ça ne change rien pour les autres qui restent voisins de A (mais on ne peut plus voir A).

**Pièces jointes d'un secret**
Une pièce jointe a un nom, comme un nom de fichier, relativement à son secret.
- une pièce jointe peut être mise à jour, supprimée, d'autres ajoutées.
- une pièce jointe est stockée cryptée par la clé du groupe : si elle est de type MIME 'text' elle est compressée.
- une pièce jointe est affichable en mode _synchronisé_ et _incognito_ : voir ci-arès comment par exception, elle peut être accessible en mode _avion_ sur certains appareils.
- les navigateurs peuvent en général afficher beaucoup de types de pièces jointes (mais pas tous tant s'en faut).
- on peut télécharger en local une pièce jointe, typiquement dans le répertoire `Téléchargement` de l'appareil.

Une opération de téléchargement permet d'écrire sur un disque local une sélection de secrets, leurs textes et leurs pièces jointes, en clair. Ceci requiert un PC (Linux ou Windows) et le chargement d'une petite application qui doit être lancée localement (un navigateur n'a pas le droit d'écrire sur l'espace de fichiers du PC).

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

## Accès aux pièces jointes en mode _avion_
En raison de leur volume les pièces jointes résident sur le serveur et ne sont pas mémorisées dans les bases locales des sessions : elles ne sont lisibles qu'en mode _synchronisé_ ou _incognito_ mais pas en mode _avion_.

Toutefois pour chaque appareil distinctement, le titulaire d'un compte peut **cocher** des pièces jointes pour accéder à leur contenu en mode _avion_ :
- ceci est à faire pièce jointe par pièce jointe et sur autant d'appareils que souhaité : tous n'ont pas forcément les mêmes pièces jointes cochées pour accès en mode _avion_.
- une pièce jointe ainsi cochée est maintenue à jour, synchronisée, en cas de changement, durant une session synchronisée.
- on peut décocher une pièce jointe cochée, elle ne sera plus mémorisée localement.
- si le secret disparaît, les pièces jointes correspondantes sont aussi supprimées localement.

> Un excès de pièces jointes accessibles en mode _avion_ peut entraîner le blocage de sessions, le stockage local tombant en erreur.

# Maîtrise de la consommation des ressources et du droit d'accès des comptes
Les ressources techniques ne sont, ni infinies, ni gratuites. L'organisation qui gère l'hébergement de l'application a besoin de pouvoir _contrôler / maîtriser_ les volumes des secrets et le cas échéant, si c'est sa politique, de redistribuer le coût d'hébergement sur les comptes, ou certains d'entre eux.

Par ailleurs une organisation peut souhaiter restreindre l'usage d'un compte à leurs _adhérents_ : elle doit être en mesure de supprimer l'accès à un compte si celui-ci n'en fait plus partie, ou toute autre raison comme par exemple de ne plus acquitter sa juste part des coûts d'hébergement.

## Forfaits v1 et v2 attribués aux avatars
Pour chaque avatar deux _forfaits_ sont définis :
- le forfait v1 du volume occupé par les textes des secrets.
- le forfait v2 du volume occupé par les fichiers attachés aux secrets.

#### Unités de volume pour les forfaits
- pour v1 : 0,25 MB
- pour v2 : 25 MB

Les forfaits, pour les comptes, pour les groupes, pour la réserve, peuvent être donnés en nombre d'unités ci-dessus.

Le _prix sur le marché_ du méga-octet de volume v1 est environ 10 fois supérieur à celui du méga-octet de volume v2 ... mais comme l'utilisation de v2 pour stocker des photos, des sons et des clips video est considérable par rapport à du texte, le volume v2 peut-être prépondérant selon le profil d'utilisation.

Les forfaits typiques s'étagent de 1 à 255 : (coût mensuel)
- (1) - XXS - 0,25 MB / 25 MB - 0,09c
- (4) - XS - 1 MB / 100 MB - 0,35c
- (8) - SM - 2 MB / 200 MB - 0,70c
- (16) - MD - 4 MB / 400 MB - 1,40c
- (32) - LG - 8 MB / 0,8GB - 2,80c
- (64) - XL - 16 MB / 1,6GB - 5,60c
- (128) - XXL - 32 MB / 3,2GB - 11,20c
- (255) - MAX - 64 MB / 6,4GB - 22,40c
> A tout instant les volumes effectivement occupés par les secrets **ne peuvent pas dépasser les forfaits** attribués à leurs avatars.

> Le transfert sur le réseau des fichiers attachés (download) **est ralenti** dès qu'il s'approche ou dépasse sur les 14 derniers jours le volume v2 : la temporisation est d'autant plus forte que cet écart l'est.

## Compte : UN avatar primaire + [0, n] secondaires
Un compte est représenté par son avatar primaire, créé à la création du compte, et d'éventuels avatars secondaires créés / résiliés par l'avatar primaire -le compte-.

L'auto-résiliation de l'avatar primaire correspond à la dissolution du compte et ne peut avoir lieu qu'après avoir résilié tous les avatars secondaires.

Chaque avatar primaire comme secondaire a **une ligne comptable** qui enregistre l'état courant et l'historique de ses utilisations de volumes V1 et V2.

C'est l'avatar primaire qui alloue des forfaits de volumes V1 / V2 à ses avatars secondaires en prenant sur ses propres forfaits.

### Compteurs d'une ligne comptable
La ligne comptable d'un avatar dispose des compteurs suivants :
- `j` : **la date du dernier calcul enregistré** : par exemple le 17 Mai de l'année A
- **pour le mois en cours**, celui de la date ci-dessus :
  - `v1 v1m` volume v1 des textes des secrets : 1) moyenne depuis le début du mois, 2) actuel, 
  - `v2 v2m` volume v2 de leurs pièces jointes : 1) moyenne depuis le début du mois, 2) actuel, 
  - `trm` cumul des volumes des transferts de pièces jointes : 14 compteurs pour les 14 derniers jours.
- **forfaits v1 et v2** `f1 f2` : les derniers appliqués.
- `rtr` : ratio de la moyenne des tr / forfait v2
- **pour les 12 mois antérieurs** `hist` (dans l'exemple ci-dessus Mai de A-1 à Avril de A),
  - `f1 f2` les derniers forfaits v1 et v2 appliqués dans le mois.
  - `r1 r2` le pourcentage du volume moyen dans le mois par rapport au forfait: 1) pour v1, 2) por v2.
  - `r3` le pourcentage du cumul des transferts des pièces jointes dans le mois par rapport au volume v2 du forfait.
- `s1 s2` : pour un avatar primaire, total des forfaits alloués à ses avatars secondaires.

### Décomptes des volumes des secrets
**Les secrets personnels** sont décomptés sur la ligne comptable de l'avatar qui les détient.

**Les secrets d'un contact** sont décomptés sur chacune des lignes comptables des avatars ayant déclaré accéder aux secrets du contact.

**Pour les secrets de groupe :**
- un avatar membre du groupe est _hébergeur_ du groupe : il peut fixer deux limites v1 / v2 de volume maximal pour les secrets du groupe.
- les secrets sont décomptés sur la ligne comptable de l'avatar hébergeur du groupe.
- l'hébergeur peut changer : les volumes occupés sont transférés du compte antérieur au compte repreneur.
- si l'hébergeur décide d'arrêter son hébergement, la mise à jour des secrets est suspendue tant qu'un repreneur ne s'est pas manifesté. Si la situation perdure au delà d'un an le groupe est déclaré disparu, les secrets sont effacés.

## LE compte du comptable
"Le" **comptable** d'une organisation est un compte particulier :
- sa phrase secrète est déclarée dans la configuration de l'organisation (son hash, pas celle en clair).
- il n'est pas limité en volumes.
- il peut avoir des _contacts_ mais pas de groupes.

Il peut déclarer des **tribus**, les doter en ressources et les bloquer, le cas échéant jusqu'à disparition.

## Tribus et leurs parrains
Une tribu rassemble un ensemble de comptes.
- tout compte n'appartient qu'à une seule tribu à un instant donné,
- le **comptable** peut, au cas par cas, passer un compte d'une tribu à une autre. 

**Informations attachées à une tribu**  
_Identifiant_ : `[nom, cle, id]` de la tribu. La clé est tirée aléatoirement à la création, le nom est un code immuable et l'id est un hash de la clé.

L'identifiant `[nom, rnd]` est transmis crypté par la clé de leur contact,
- par le comptable lors de la création d'un compte parrain de la tribu,
- par un compte parrain lors du parrainage d'un compte de la tribu.

L'id de la tribu _cryptée par la clé publique du comptable_ est inscrite dans chaque compte.

- `id` : id de la tribu.
- `nck` : `[nom, rnd]` crypté par la clé k du comptable.
- `f1 f2` : sommes des volumes V1 et V2 déjà attribués aux comptes de la tribu.
- `r1 r2` : volumes V1 et V2 en réserve pour attribution aux comptes actuels et futurs de la tribu.
- `sb` : statut de blocage (0, 1, 2, 3).
- `rbt` : libellé explicatif du blocage crypté par la clé de la tribu.
- `dh` : date-heure de dernier changement du statut de blocage.

### Parrains d'une tribu
Les **parrains** d'une tribu sont des comptes habilités par le comptable à créer par parrainage d'autres comptes de leur tribu.
- le pouvoir de parrainage d'un compte d'une tribu lui est conféré / retiré par le _comptable_.
- une tribu peut avoir plusieurs parrains à un instant donné, voire aucun dans des cas particuliers.
- quand un compte parrain parraine un autre compte, un _contact_ est toujours établi entre eux (leurs avatars primaires).
- un parrain d'une tribu a le pouvoir d'attribuer (et de retirer) des ressources à un compte de sa tribu en les prélevant sur la **réserve** de sa tribu.

> **Le comptable a dans ses _contacts_ les parrains actuels, passés et pressentis des tribus.** Un parrain pressenti est un contact établi pour discussion avant éventuelle attribution du statut de parrain par le comptable.

> Un parrain ayant pour contact _certains_ comptes de sa tribu, mais pas forcément tous, personne, pas même le comptable, ne peut lister _tous_ les comptes d'une tribu.

Un compte n'ayant plus de parrain de sa tribu dans sa liste de contacts peut discuter avec le comptable par _chat_ afin d'obtenir une phrase de rencontre qui sera communiquée par le comptable à un compte parrain de sa tribu de manière à ce qu'ils puissent établir un contact entre eux (si le parrain choisi par le comptable le veut bien).

> Les comptes _parrains_ sont responsables de la consommation d'espace de leur tribu :
>- ils peuvent en contraindre l'expansion et l'accueil de nouveaux comptes,
>- si l'organisation prévoit une forme ou l'autre de facturation, c'est la tribu qui est facturée. En cas de non paiement, les comptes de la tribu sont susceptibles d'être bloqués à la connexion et in fine de disparaître.

### Attribution / restitution des ressources
Le comptable peut attribuer des _réserves_ aux tribus et les diminuer.

Un compte parrain peut augmenter / réduire les forfaits de volumes V1 et V2 des comptes de sa tribu.

Lorsqu'un compte s'auto-détruit, les ressources sont rendues à la tribu par mise à jour (`r1 r2 f1 f2`) - tout compte disposant de la clé de la tribu.

**Lorsqu'un compte disparaît**, ni la clé ni l'id de la tribu n'étant pas accessible par le GC qui détecte la disparition (elles ne sont décodées qu'en session), le GC inscrit dans une table d'attente les volumes rendus et _la clé de la tribu cryptée par la clé publique du comptable_. Lors d'une session du comptable, ce dernier peut décrypter ces restitutions et en créditer les tribus.

## Mise en alerte / sursis / blocage des tribus et des comptes
Le **comptable** peut lever un statut d'alerte / sursis / blocage d'une tribu : il en explicite la raison dans l'enregistrement de la tribu, ce message apparaissant à chaque connexion d'un compte.
- La raison majeure est que la _tribu_ n'acquitte plus sa juste part du financement de l'hébergement de l'application.
- Une autre raison pourrait être liée à une organisation dont les tribus représentent une entité de l'organisation et que celle-ci est dissoute.

Un **parrain d'une tribu** peut lever un statut d'alerte / sursis / blocage d'un compte de la tribu : il en explicite la raison dans l'enregistrement de la ligne comptable du compte, ce message apparaissant à chaque connexion du compte.
- Le compte utilise un volume trop important et refuse de le réduire,
- Le compte a quitté l'organisation et la politique de celle-ci prévoit qu'au bout d'un certain temps le compte soit bloqué.
- Rupture d'éthique si ceci a été décidé au niveau de l'organisation.

##### Alerte (1)
Les comptes continuent à vivre normalement mais un panneau de pop-up s'affiche très régulièrement au cours des sessions pour rappeler cet état, le temps restant et ce qui l'attend en _sursis_.

##### En sursis (2)
Les comptes ne peuvent plus créer / mettre à jour de secrets, ni attacher des fichiers aux secrets, mais ils peuvent supprimer des secrets et des fichiers attachés.

##### Bloqué (3)
Les comptes sont bloqués, leur titulaire ne peut plus rien consulter. Ils ne conservent que la possibilité de converser par le _chat du comptable_.

Selon la _classe_ de la raison de la suspension,
- le niveau de suspension peut être différent,
- le temps de passage d'un niveau au suivant également.

> La politique de l'organisation se traduit dans la configuration de l'organisation par,
>- la liste des _classes_ de raisons de blocage,
>- pour chaque classe du niveau de suspension et des délais pour passer d'un niveau à un autre, et si cette classe est de veau comptable ou parrain.

## Chat avec le comptable
Ce chat est un canal de communication entre les comptes et le comptable qui peut être utilisé par un compte pour solliciter une fonction qui n'est que du pouvoir du comptable (demander à devenir parrain, obtenir la référence d'un parrain, changer de tribu, levée d'un blocage, etc.).

Le chat comptable est une suite datée d'items, chacun comprenant :
- l'identification de l'avatar primaire d'un compte,
- la date-heure d'écriture portant aussi l'indication disant si l'item a été écrit par l'avatar ou par le _comptable_,
- un texte court _crypté par la clé de la tribu_.

Un item une fois écrit ne peut plus être modifié : une purge périodique intervient globalement sur critère de date.

Le comptable accède à l'ensemble des items du chat, et peut les filtrer par avatar. Il peut y écrire des items. L'avatar n'accède qu'à ses items.

## Disparition par inactivité d'un compte

Des ressources sont immobilisées par les comptes (partagées pour les groupes) : l'application doit les libérer quand les comptes sont _présumés disparus_, c'est à dire sans s'être connecté depuis plus d'un an.
- pour préserver la confidentialité, toutes les ressources liées à un compte ne sont pas reliées au compte par des données lisibles dans la base de données mais cryptées et seulement lisibles en session.
- pour marquer que des ressources sont encore utiles, un compte dépose lors de la connexion des **jetons datés** ("approximativement datés" pour éviter des corrélations entre avatars / groupes / contacts) dans chacun de ses avatars et chacun des groupes et contacts auxquels il participe, ainsi que dans le compte lui-même.
- la présence d'un jeton, par exemple sur un avatar, va garantir que ses données ne seront pas détruites dans les 400 jours qui suivent la date du jeton.
- un traitement ramasse miettes tourne chaque jour, détecte les contacts / avatars / groupes dont le jeton est trop vieux et efface les données correspondantes jugées comme inutiles, l'avatar / contact / groupe correspondant ayant _disparu par inactivité_.
- le jeton de l'avatar primitif apparaît toujours comme le plus ancien afin que par exemple un avatar secondaire ne soit pas détecté disparu avant son avatar primaire.

>Comme aucune référence d'identification dans le monde réel n'est enregistrée pour préserver la confidentialité du système, aucune alerte du type mail ou SMS ne peut informer un compte de sa prochaine disparition s'il ne se connecte pas.

# Réflexions à propos des organisations et du contrôle de l'éthique
Des organisations bien différentes peuvent décider d'héberger l'application pour leurs adhérents. 

Ci-après quelques réflexions sur leurs profils types et les approches qu'elles peuvent avoir sur la maîtrise des ressources consommées par les comptes.

### Organisation payant l'hébergement pour ses adhérents
L'accès à l'application est un service de l'organisation, gratuit pour ses adhérents (du moins invisiblement inclus dans leur adhésion, ou les crédits de sponsoring dont elle bénéficie).
- L'organisation connaît ses adhérents et leurs rôles : elle propose des forfaits conformes aux exigences des rôles tenus, aux statuts (salariés, ...).
- L'organisation fait le rapprochement entre chaque adhérent et son numéro d'avatar dans l'application. Mais elle ne peut pas le faire avec les autres avatars du compte, les groupes auxquels il participe, ni les couples qu'ils forment avec les autres avatars, ni les secrets qu'il écrit et lit.
- **Questions :**
  - (1) si un adhérent quitte l'organisation, comment lui retirer son accès -sous quel délai- (et de facto récupérer ses ressources) ?
  - (2) si des personnes rapportent l'usage par un compte de l'application pour des fins étrangères à l'objet de l'organisation, voire opposées à cet objet, comment lui retirer son accès ? Cette question lève le sujet du contrôle éthique sur l'usage de l'application.

### Organisation par _cotisation_
L'organisation, qu'elle soit à but lucratif ou non, a opté pour laisser chaque adhérent choisir son niveau de forfait et corrélativement en payer l'usage.
- chaque titulaire choisit les niveaux de forfait qui lui semble correspondre à son besoin,
- il paye un abonnement pour contribuer à supporter le coût global d'hébergement.
- **Questions :**
  - (1) si un abonné ne paye plus son abonnement, comment lui retirer son accès -sous quel délai- (et de facto récupérer ses ressources) ?
  - (2) si des comptes rapportent des propos _inappropriés_ vis à vis de la charte éthique de l'organisation dans les secrets partagés, voire non conformes à la loi, comment lui retirer son accès ?

>Les virements des abonnements _pouvant_ être obscurs ou passer par un intermédiaire, il peut être quasi impossible de corréler (avec des moyens légaux) une personne physique ou morale à une ligne comptable. Dans ce type d'organisation **les comptes peuvent être totalement anonymes** ... ce qui n'empêche pas de devoir pouvoir les bloquer, ni qu'ils n'aient pas à respecter la charte éthique s'il y en a une.

>Le modèle de _paiement de cotisation_ peut tout à fait être sans but lucratif et proposé par des associations désireuses de permettre à chacun de disposer d'espaces privés et sécurisés pour noter ses pensées, échanger avec des contacts des propos privés. Ce n'est en rien, _a priori_ un modèle marchand (mais ça peut aussi l'être).

>Il reste donc que dans certains cas, une organisation peut devoir mettre fin à l'activité d'un compte, ne serait-ce que pour répondre à une injonction judiciaire sans devoir détruire tous les comptes (et sans considérer les pressions _physiques_, légales ... (?) ou non).

### Contrôle éthique ... ou non
Ce sujet ne concerne que les organisations ayant un objet social / politique : ses membres utilisent l'application pour les servir.

Aucun contrôle éthique n'est envisageable vis à vis des secrets personnels : il n'y a que le compte qui peut y accéder, on ne voit pas pourquoi il se dénoncerait de lui-même de textes illisibles par d'autres.

Concernant des secrets de couples, si des écrits sont jugés inappropriés pour l'un des deux,
- il sort du couple,
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

L'organisation aura besoin qu'un compte _lanceur d'alerte_ ayant accès aux secrets de groupe litigieux accède physiquement à ceux-ci (par une manipulation claire) pour mettre en évidence le caractère inapproprié de certains secrets justifiant une mise en sursis voire un blocage.

>L'application permet de facto une modération par exclusion d'un compte, en aucun cas par retrait des textes litigieux, sauf à ce que le compte _lanceur d'alerte_ le fasse (s'il le peut).

>Une organisation peut aussi déclarer dans ses conditions qu'elle ne procède jamais à un blocage de compte pour raisons éthiques, les autres comptes ayant facilement les moyens de se protéger d'écrits inappropriés.

**L'application est agnostique vis à vis des contenus des secrets** (pas de vote, d'avis ...) qui peuvent être n'importe quoi, en bien ou en mal ... et selon ce que chacun considère comme bien ou mal: c'est une application qui reste du niveau de la communication / mémorisation **personnelle et/ou privée**, comme celle que peut avoir un groupe restreint d'amis discutant librement entre eux dans un domicile privé.  
C'est aussi pour cette raison qu'un groupe a une taille limitée, telle qu'il soit raisonnable de juger qu'il n'est pas public, et où tout le monde en contact se connaît et a été coopté.

>Ce n'est pas une application _libertaire_ mais _privée_. Être libertaire supposerait un accès public sans restriction ce qui n'est pas le cas.
