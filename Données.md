# Boîtes à secrets - Modèle de données

## Identification des objets

Les clés AES et les PBKFD sont des bytes de longueur 32.

Un entier sur 53 bits est intègre en Javascript (15 chiffres décimaux). Il peut être issu de 6 bytes aléatoires.

Un hash en *BigInt* est un 64 bits sans signe, toujours positif (19 chiffres décimaux): _pas utilisé_

Le hash (_integer_) d'un bytes est un entier intègre en Javascript multiple de 4.

Le hash (_integer_) d'un string est un entier intègre en Javascript.

Les date-heures _serveur_ sont exprimées en micro-secondes depuis le 1/1/1970, soit 52 bits (entier intègre en Javascript). Les date-heures fonctionnelles sont en milli-secondes.

### Compte
- `id` : c'est l'id de son avatar primaire.  
- `clé K` : 32 bytes aléatoires.  
- `pcb` : PBKFD de la phrase complète (clé X) - 32 bytes.  
- `dpbh` : hashBin (_integer_) du PBKFD du début de la phrase secrète.

**La phrase secrète d'un compte reste dans le cerveau du titulaire.**
- sa transformée par PBKFD dès la saisie donne une clé AES X qui ne sort jamais de la session cliente et n'est jamais stockée de manière permanente.

**La clé K d'un compte**,
- n'est stockée en session comme en serveur que sous forme cryptée par X.
- n'est jamais transmise au serveur en clair.
- les données cryptées par K, ne sont lisibles dans le serveur que quand elles ont été transmises aussi en clair dans une opération. 

### Nom complet d'un avatar / contact / groupe / tribu
Le **nom complet** d'un avatar / contact / groupe / tribu est un couple `[nom, rnd]`
- `nom` : nom lisible et signifiant, entre 6 et 20 caractères. Le nom `Comptable` est réservé.
- `rnd` : 32 bytes aléatoires. Clé de cryptage.
- A l'écran le nom est affiché sous la forme `nom@abgh` (sauf `Comptable`) ou `ab` sont les deux premiers caractères de l'id en base64 et `gh` les deux derniers.

**Dans les noms,** les caractères `< > : " / \ | ? *` et ceux dont le code est inférieur à 32 (donc de 0 à 31) sont interdits afin de permettre d'utiliser le nom complet comme nom de fichier.

### Avatar
La **clé de cryptage** de la carte de visite est `rnd`.

L'`id` d'un avatar est le hash (_integer_) des bytes de `rnd`, SAUF pour le compte de nom réservé `Comptable` pour lequel, quel que soit le `rnd`, l'id est Number.MAX_SAFE_INTEGER (2^53 - 1 = 9007199254740990).

### Contact
La **clé de cryptage** d'un contact (carte de visite et secrets) est`rnd`.

L'`id` d'un contact est le hash (_integer_) des bytes de `rnd` + 1.

### Groupe
La **clé de cryptage** d'un groupe (carte de visite et secrets) est`rnd`.

L'`id` d'un groupe est le hash (_integer_) des bytes de `rnd` + 2.

### tribu
La **clé de cryptage** d'une tribu (données de la tribu) est`rnd`.

L'`id` d'une tribu est le hash (_integer_) des bytes de `rnd` + 3.

### Type d'objet majeur
Le reste de la division par 4 de l'id d'un objet majeur donne son type:
- 0 : avatar,
- 1 : contact,
- 2 : groupe,
- 3 : tribu.

### Secret
- `id` : de l'avatar, du contact ou du groupe propriétaire
- `ns` : numéro relatif au groupe / avatar / contact, entier issu de 4 bytes aléatoires.

### Attributs génériques
- `v` : version, entier.
- `dds` : date de dernière signature, en nombre de jours depuis le 1/1/2021. Signale que ce jour-là, l'avatar, le contact, le groupe était *vivant / utile / référencé*. Pour éviter des rapprochements entre eux, la *vraie* date de signature peut être entre 0 et 30 jours *avant*.  
- `dlv` : date limite de validité, en nombre de jours depuis le 1/1/2021.

Les comptes sont censés avoir au maximum N0 jours entre 2 connexions faute de quoi ils sont considérés comme disparus.

### Signatures des avatars, contacts et groupes
A chaque connexion d'un compte, son avatar primaire signe si la `dds` actuelle n'est pas _récente_ (sinon les signatures ne sont pas mises à jour) :
- pour lui-même dans `cv` : jour de signature tiré aléatoirement entre j-28 et j-14.
- dans `cv` : jour de signature tiré aléatoirement pour chacun entre j-14 et j.
  - pour ses avatars secondaires,
  - pour ses contacts,
  - pour les groupes auxquels ses avatars sont invités ou actifs.

Il y a aussi des signatures en plus de la connexion à un compte :
- pour un avatar: à sa création.
- pour un contact: à sa création par A0 et à l'acceptation par A1.
- pour un groupe: à sa création et à l'acceptation d'une invitation d'un membre.

Les purges exécutées par le GC :
- pour les **comptes** : purge des rows `compte prefs` afin de bloquer la connexion.
- pour les **groupes** : purge de leur rows `groupe membre secret`.
- pour les **avatars** : purge de leur rows `avatar compta avrsa secret`.
- pour les **contacts** : purge de leur rows `couple secret`.

### Version des rows
Les rows des tables devant être présents sur les clients ont une version, de manière à pouvoir être chargés sur les postes clients de manière incrémentale : la version est donc croissante avec le temps et figure dans tous les rows de ces tables.  
- utiliser une date-heure présente l'inconvénient de laisser une meta-donnée intelligible en base ;
- utiliser un compteur universel a l'inconvénient de facilement deviner des liaisons entre objets : par exemple l'invitation à établir un contact entre A et B n'apparaît pas dans les rows eux-mêmes mais serait lisible si les rows avaient la même version. Crypter l'appartenance d'un avatar à un groupe alors qu'on peut la lire de facto dans les versions est un problème.
- utiliser un compteur par objet rend complexe la génération de SQL avec des filtres qui associent chaque objet à sa dernière version connue.

Tous les objets synchronisables sont identifiés, au moins en majeur, par une id de compte, d'avatar, de couple ou de groupe : d'où l'option de gérer **une séquence de versions**, pas par id de ces objets mais par hash de cet id.

La table `cv` ne suit pas cette règle et a une séquence unique afin de synchroniser tous les états d'existence et les cartes de visite de tous les objets majeurs. **Sa séquence de versions est 0.**

## Tables

- `versions` (id) : table des prochains numéros de versions (actuel et dernière sauvegarde) et autres singletons (id value)
- `avrsa` (id) : clé publique d'un avatar
- `trec` (id) : transfert de fichier en cours (uploadé mais pas encore enregistré comme fichier d'un secret)
- `gcvol` (id) : GC des volumes des comptes disparus.

_**Tables transmises au client**_

- `compte` (id) : authentification et liste des avatars d'un compte
- `prefs` (id) : données et préférences d'un compte
- `compta` (id) : ligne comptable du compte
- `cv` (id) : statut d'existence, signature et carte de visite des avatars, contacts et groupes
- `avatar` (id) : données d'un avatar et liste de ses contacts et groupes
- `couple` (id) : données d'un contact entre deux avatars
- `groupe` (id) : données du groupe
- `membre` (id, im) : données d'un membre du groupe
- `secret` (id, ns) : données d'un secret d'un avatar, couple ou groupe
- `contact` (phch) : parrainage ou rencontre de A0 vers un A1 à créer ou inconnu par une phrase de contact
- `invitgr` (id, ni) : **NON persistante en IDB**. invitation reçue par un avatar à devenir membre d'un groupe
- `invitcp` (id, ni) : **NON persistante en IDB**. invitation reçue par un avatar à devenir membre d'un couple
- `chat` (id, dh) : chat d'un avatar primaire (compte) avec les comptables.
- `tribu` (id) : données et compteurs d'une tribu.

## Singletons id / valeur
Ils sont identifiés par un numéro de singleton.  
- Leur valeur est un BLOB, qui peut être un JSON en UTF8.  
- Le singleton 0 est un JSON libre utilisé pour stocker l'état du serveur (dernière sauvegarde, etc.).  
- C'est la table `versions` qui les stocke.

## Table: `versions` - CP : `id`

Au lieu d'un compteur par avatar / couple / groupe / compte on a 100 compteurs, un compteur pour plusieurs avatars / groupe (le reste de la division de l'id par 99 + 1). Le compteur 0 est celui de la séquence universelle.

La colonne `v` est un array d'entiers.

>Le nombre de collisions n'est pas vraiment un problème : détecter des proximités entre avatars / groupes dans ce cas devient un exercice très incertain (fiabilité de 1 sur 99).

L'id 0 correspondant à l'état courant et l'id 1 à la dernière sauvegarde.

    CREATE TABLE "versions" (
    "id"  INTEGER,
    "v"  BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;

## Table : `tribu` - CP `id`. Informations d'une tribu
Les tribus sont crées et purgées par le comptable.

Table : 

    CREATE TABLE "tribu" (
    "id"	INTEGER,
    "v"		INTEGER,
    "nbc" INTEGER,
    "f1"  INTEGER,
    "f2"  INTEGER,
    "r1"  INTEGER,
    "r2"  INTEGER,
    "datak"	BLOB,
    "datat"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;

- `id` : id de la tribu.
- `v`
- `nbc` : nombre de comptes actifs dans la tribu.
- `f1 f2` : sommes des volumes V1 et V2 déjà attribués comme forfaits aux comptes de la tribu.
- `r1 r2` : volumes V1 et V2 en réserve pour attribution aux comptes actuels et futurs de la tribu.
- `datak` : cryptée par la clé K du comptable :
  - `[nom, rnd]`: nom immuable et clé de la tribu.
  - `info` : commentaire privé du comptable.
  - `lp` : liste des ids des parrains (certains _pourraient_ être disparu)
- `datat` : cryptée par la clé de la tribu :
  - `st` : statut de blocage `nc` :
    - `n` : niveau de blocage (0 à 4).
    - `c` : classe du blocage : 0 à 9 repris dans la configuration de l'organisation.
  - `txt` : libellé explicatif du blocage.
  - `dh` : date-heure de dernier changement du statut de blocage.
- `vsh`

## Table: `chat` - CP `id dh`. Chat des avatars (primaires) avec le _comptable_
Une ligne par item de chat.

Table :

    CREATE TABLE "chat" (
    "id"	INTEGER,
    "dh"	INTEGER,
    "txtt"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id", "dh")
    );
    CREATE INDEX "dh_chat" ON "chat" ( "dh" );

- `id` : de l'avatar primaire.
- `dh` : date-heure d'écriture. Par convention si elle est paire c'est un texte écrit par l'avatar, sinon il est écrit par le comptable.
- `txtt` : serial de [x, t, l]
  - x : [nom, rnd] de l'avatar crypté par la clé publique du comptable
  - t : texte crypté pat rnd
  - l : liste de noms d'avatar : [[nom, rnd] ...]
La liste l permet au comptable de retourner des contacts, par exemple des parrains
d'une tribu sur demande d'un avatar cherchant un autre parrain ou changeant de tribu.

Un item est logiquement immuable et purgé sur critère de date-heure. 

Pour qu'un avatar puisse écrire un item de chat il doit avoir le [nom, rnd] de l'avatar à qui il écrit:
- soit c'est un _parrain_ et il l'a en tant que contact,
- soit il a reçu un item sur lequel le [non, rnd] a été fourni (c'est donc toujours une _réponse_).

## Table: `gcvol`. Récupération des forfaits des comptes disparus
Quand un avatar primaire (un compte) disparaît, le GC stocke dans cette table les compteurs f1 f2 du forfait du compte pour que le comptable les réaffecte à la tribu et décrémente le compteur de compte actif. 

Un certain délai se passe donc entre la détection d'une disparition et le crédit des forfaits à la tribu.

L'id de la tribu est donné crypté par la clé publique du comptable (trouvée dans le row `compte`).

Table :

    CREATE TABLE "gcvol" (
    "id"  INTEGER
    "idt"	BLOB,
    "f1"  INTEGER
    "f2"	INTEGER,
    "vsh"	INTEGER
    PRIMARY KEY("id")
    ) WITHOUT ROWID;

- `id` : date-heure comme clé primaire
- `idt` : id de la tribu est donné crypté par la clé publique du comptable.
- `f1 f2` : volumes de forfaits à restituer à la tribu.

## Table: `trec` - CP `id idf`. Transfert de fichier en cours

    CREATE TABLE IF NOT EXISTS "trec" (
      "id"	INTEGER,
      "idf" INTEGER,
      "dlv" INTEGER,
      PRIMARY KEY("id", "idf")
    );
    CREATE INDEX "dlv_trec" ON "trec" ( "dlv" );

## Table : `compte` - CP `id`. Authentification d'un compte
_Phrase secrète_ : une ligne 1 de 16 caractères au moins et une ligne 2 de 16 caractères au moins.  
`pcb` : PBKFD de la phrase complète (clé X) - 32 bytes.  
`dpbh` : hashBin (53 bits) du PBKFD du début de la phrase secrète (32 bytes).

Table :

    CREATE TABLE "compte" (
    "id"	INTEGER,
    "v"		INTEGER,
    "dpbh"	INTEGER,
    "pcbh"	INTEGER,
    "kx"  BLOB,
    "stp"  INTEGER,
    "nctk"  BLOB,
    "idtpc"  BLOB,
    "mack"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE UNIQUE INDEX "dpbh_compte" ON "compte" ( "dpbh" );

- `id` : id de l'avatar primaire du compte.
- `v` :
- `dpbh` : hashBin (53 bits) du PBKFD du début de la phrase secrète (32 bytes). Pour la connexion, l'id du compte n'étant pas connu de l'utilisateur.
- `pcbh` : hashBin (53 bits) du PBKFD de la phrase complète pour quasi-authentifier une connexion avant un éventuel échec de décryptage de `kx`.
- `kx` : clé K du compte, cryptée par la X (phrase secrète courante).
- `stp` : statut parrain (0: non, 1:oui).
- `nctk` : nom complet `[nom, rnd]` de la tribu crypté,
  - soit par la clé K du compte,
  - soit par la clé publique de son avatar primaire après changement de tribu par le comptable.
- `idtpc` : id de la tribu cryptée par la clé publique du comptable.
- `chkt` : hash (integer) de (id avatar base64 + id tribu base64)
- `mack` {} : map des avatars du compte cryptée par la clé K. 
  - _Clé_: id,
  - _valeur_: `[nom, rnd, cpriv]`
    - `nom rnd` : nom et clé de l'avatar.
    - `cpriv` : clé privée asymétrique.
- `vsh`

**Remarques :** 
- un row `compte` ne peut être modifié que par une transaction du compte (mais peut être purgé par le traitement journalier de détection des disparus).
- il est synchronisé lorsqu'il y a plusieurs sessions ouvertes en parallèle sur le même compte depuis plusieurs sessions de browsers.
- chaque mise à jour vérifie que `v` actuellement en base est bien celle à partir de laquelle l'édition a été faite pour éviter les mises à jour parallèles intempestives.
- le row `compte` change rarement : seulement à l'occasion de l'ajout / suppression d'un avatar, d'un changement de phrase secrète et d'un changement de tribu.

`chkt` permet seulement à un compte X de la tribu T1 de savoir si un compte dont il connaît l'id est ou non de la même tribu T1.

## Table : `prefs` - CP `id`. Préférences et données d'un compte
Afin que le row compte qui donne la liste des avatars ne soit mis à jour que rarement, les données et préférences associées au compte sont mémorisées dans une autre table :
- chaque type de données porte un code court :
  - `mp` : mémo personnel du titulaire du compte.
  - `mc` : mots clés du compte.
  - ... `fs` : filtres des secrets (par exemple).
- le row est juste un couple `[id, map]` où map est la sérialisation d'une map ayant :
  - une entrée pour chacun des codes courts ci-dessus : la map est donc extensible sans modification du serveur.
  - pour valeur la sérialisation cryptée par la clé K du compte de l'objet Javascript en donnant le contenu.
- le row est chargé lors de l'identification du compte, conjointement avec le row `compte`.
- une mise à jour ne correspond qu'à un seul code court afin de réduire le risque d'écrasements entre sessions parallèles.

Table :

    CREATE TABLE "prefs" (
    "id"	INTEGER,
    "v"		INTEGER,
    "mapk" BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
	
- `id` : id du compte.
- `v` :
- `mapk` {} : map des préférences.
  - _clé_ : code court (`mp, mc ...`)
  - _valeur_ : sérialisation cryptée par la clé K du compte de l'objet JSON correspondant.
- `vsh`

## Table `avrsa` : CP `id`. Clé publique RSA des avatars
Cette table donne la clé RSA (publique) obtenue à la création de l'avatar : elle permet d'inviter un avatar à être contact ou à devenir membre d'un groupe.

Table :

    CREATE TABLE "avrsa" (
    "id"	INTEGER,
    "clepub"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
	
- `id` : id de l'avatar.
- `clepub` : clé publique.
- `vsh`

## Table: `cv` : CP `id`. Répertoire des objets majeurs : avatars, contacts, groupes
Cette table a plusieurs objectifs :
- `dds` : **garde la trace des signes de vie des objets** dans la propriété `dds`, dernière date de signature, remplie à l'ouverture d'une session pour signaler que les avatars, contacts et groupes de l'espace de données du compte de la session sont toujours _en vie_ (utiles) et se prémunir contre leur destruction pour non usage.
- `x` : **donne le statut d'existence de ces objets** et tracer leur disparition:
  - `0` : objet vivant,
  - `1` : le processus de disparition a été demandé. Pour les sessions l'objet (et ceux dépendants) a déjà disparu (le compte / avatar ne le référence plus), mais les purges techniques (`avatar contact groupe compta avrsa secret membre chat`) doivent encore être exécutées par le démon de purge quotidien.
  - `J > 1` : **le row** `cv` est à purger définitivement le jour J (les autres l'ont déjà été).
- `cv` : **détient la carte de visite des objets** (`[photo, info]` cryptée par la clé de l'objet).
  - toujours `null` pour un objet disparu (x > 1).
  - `null` ou `[photo, info]` selon que l'objet _avatar contact groupe_ a ou non une carte de visite.
- `v` : version à laquelle `x` ou `cv` ont changé pour la dernière fois. Les versions sont prises dans la séquence 0, tous les objets partagent donc pour leur `cv` la même séquence de version dans le répertoire. Les sessions peuvent ainsi requérir en début de session,
  - tous les rows qui les concernent quelle que soit leur version (mode _incognito_),
  - seulement ceux ayant changé d'état d'existence et / ou de carte de visite postérieurement à leur dernière version de synchronisation de leur session locale.
  - en cours de session pour les nouveaux objets apparaissant dans leur espace de données, la dernière version de leur `x cv`.

Cette table est elle-même purgée des objets disparus depuis plus de N1 jours (typiquement 500 pour couvrir un an) afin d'éviter une croissance éternelle de la table `cv`: le temps que toutes les sessions rarement ouvertes aient eu le temps de se synchroniser.

Table :

    CREATE TABLE "cv" (
    "id"	INTEGER,
    "v" INTEGER,
    "x" INTEGER,
    "dds" INTEGER,
    "cv"	BLOB,
    "vsh" INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_v_cv" ON "cv" ( "id", "v");
    CREATE INDEX "dds_cv" ON "cv" ( "dds" ) WHERE "dds" > 0;
    CREATE INDEX "x_cv" ON "cv" ( "x" ) WHERE "x" = 1;
	
- `id` : id de l'avatar / du couple / du groupe.
- `v` : version du dernier changement de `x` ou `cv` (PAS de `dds`).
- `x` : statut de disparition :
  - 0 : existant
  - 1 : inexistant logiquement mais la purge des objets demandée au GC quotidien.
  - N : inexistant logiquement et purges des objets terminées.
- `dds` : date de dernière signature de l'avatar / contact / groupe (dernière connexion). Un compte en _alerte / sursis / bloqué_ ne signe plus, sa disparition physique est déjà programmée (mais pas certaine, l'alerte peut être levée).
- `cv` : carte de visite cryptée par la clé de l'objet.
- `vsh` :

#### Synchronisation
Les sessions s'abonnent à la liste des avatars / contacts / groupes qui délimitent l'espace de données du compte :
- _central_ : **soit pour l'objet intégralement** : les avatars du compte, les groupes accédés par le compte, les contacts ou figurent un de leurs avatars,
- _annexe_ : **soit pour les seules données d'existence / carte de visite** : les _avatars_ membres des groupes cités ci-dessus et des contacts cités ci-dessus.

Quand un row de `cv` est modifié (`x` et / ou `cv`), le row est retourné pour synchronisation de la session : c'est ainsi que celle-ci prend connaissance de la disparition de ses objets centraux et annexes (membres de groupe / conjoints de contacts).

#### Suppression logique (1)
Elle met `x` à `1`, et `cv` à `null`. Elle est répercutée par synchronisation aux sessions.

Elle est provoquée par :
- **le GC quotidien** : scanne les groupes dont la date de fin d'hébergement `dfh` + N2 jours est dépassée.
- **pour un contact** : le fait que le conjoint survivant décide de _quitter_ le contact supprime logiquement le couple (qui n'est déjà plus référencé par aucun avatar dans ce cas).
- **pour un groupe** : le fait que le dernier membre de statut actif s'auto-résilie supprime logiquement le groupe (qui n'est déjà plus référencé par aucun avatar dans ce cas).
- **pour un avatar** : la _suppression explicite_ de l'avatar d'un compte. Ceci nécessite préalablement,
  - la fin de l'hébergement des groupes qu'il héberge,
  - son auto-résiliation des groupes dont il est membre (et par conséquence _éventuellement_ la suppression logique du groupe),
  - sa disparition de ses contacts (et par conséquence _éventuellement_ la suppression logique du contact),
  - la suppression de tous ses secrets personnels.
  - chacune de ces 4 étapes est lancée successivement en session et se termine donc par la suppression d'un avatar inutile.
  - l'avatar _primaire_ ne peut être supprimé qu'en dernier, ce qui correspond à la suppression du compte.

#### Purges des objets (2)
Les objets supprimés logiquement sont supprimés physiquement par le GC quotidien lors d'une seconde phase :
- pour un avatar : le row avatar lui-même, sa compta, son chat, sa clé RSA et ses secrets.
- pour un groupe : le row groupe lui-même, ses membres et ses secrets.
- pour un contact : le row contact lui-même et ses secrets.
- pour les secrets, suppression de ses fichiers attachés en les citant un par un. Toutefois la suppression d'un avatar / contact / groupe permet de supprimer tous les fichiers attachés aux secrets de son avatar / contact / groupe sans les citer un par un.

#### Réactions en session aux avis de destruction d'objets
Pour les avatars du compte, les groupes auxquels le compte participe et les contacts d'un de ses avatars, les objets en session sont supprimés, ainsi que les objets dépendants (secrets, membres). Ils sont aussi supprimés de la base IDB.

Concernant les autres avatars _externes_ (pas du compte), ils apparaissent :
- soit comme conjoint d'un contact,
- soit comme membre d'un groupe.

A réception de ces notifications,
- les cartes de visites sont supprimées et le statut disparu rendu apparent (impact sur les vues).
- une opération est lancée pour mettre à jour, si nécessaire, les statuts des membres et conjoints concernés.

## Table: `avatar` : CP `id`. Données d'un avatar
Chaque avatar a un row dans cette table :
- la liste de ses groupes (avec leur nom et clé).
- la liste des contacts dont il fait partie (avec leur clé).

Table :

    CREATE TABLE "avatar" (
    "id"   INTEGER,
    "v"  	INTEGER,
    "lgrk" BLOB,
    "lcck"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_v_avatar" ON "avatar" ( "id", "v" );

- `id` : id de l'avatar
- `v` :
- `lgrk` : map :
  - _clé_ : `ni`, numéro d'invitation (aléatoire 4 bytes) obtenue sur `invitgr`.
  - _valeur_ : cryptée par la clé K du compte de `[nom, rnd, im]` reçu sur `invitgr`.
  - une entrée est effacée par la résiliation du membre au groupe ou sur refus de l'invitation (ce qui l'empêche de continuer à utiliser la clé du groupe).
- `lcck` : map :
  - _clé_ : `ni`, numéro pseudo aléatoire. Hash de (`cc` en hexa suivi de `0` ou `1`).
  - _valeur_ : clé `cc` cryptée par la clé K de l'avatar cible (le hash _integer_ donne son id).
- `vsh`

La lecture de `avatar` permet d'obtenir,
- la liste des groupes dont il est membre (avec leur nom, id et clé),
- la liste des couples dont il fait partie (avec leur id et clé).

## Table: `compta` : CP `id`. Ligne comptable de l'avatar d'un compte
Il y a une ligne par avatar, l'id étant l'id de l'avatar.

Table :

    CREATE TABLE "compta" (
    "id"	INTEGER,
    "t"	INTEGER,
    "v"	INTEGER,
    "st"	INTEGER,
    "txtt"  INTEGER,
    "dh" INTEGER,
    "data"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "st_compta" ON "compta" ( "st" ) WHERE "st" > 0;

- `id` : de l'avatar.
- `t` :
  - (0) : avatar secondaire.
  - (1) : avatar primaire.
- `v` :
- `st` : statut de blocage `nc` :
  - `n` : niveau de blocage (0 à 4).
  - `c` : classe du blocage : 0 à 9 repris dans la configuration de l'organisation.
- `txtt` : libellé explicatif du blocage crypté par la clé de la tribu actuelle de l'avatar.
- `dh` : date-heure de dernier changement du statut de blocage.
- `data`: compteurs sérialisés (non cryptés)
- `vsh` :

**data**
- `j` : **la date du dernier calcul enregistré** : par exemple le 17 Mai de l'année A
- **pour le mois en cours**, celui de la date ci-dessus :
  - `v1 v1m` volume v1 des textes des secrets : 1) moyenne depuis le début du mois, 2) actuel, 
  - `v2 v2m` volume v2 de leurs pièces jointes : 1) moyenne depuis le début du mois, 2) actuel, 
  - `trm` cumul des volumes des transferts de pièces jointes : 14 compteurs pour les 14 derniers jours.
- **forfaits v1 et v2** `f1 f2` : les plus élevés appliqués le mois en cours.
- `rtr` : ratio de la moyenne des tr / forfait v2
- **pour les 12 mois antérieurs** `hist` (dans l'exemple ci-dessus Mai de A-1 à Avril de A),
  - `f1 f2` les forfaits v1 et v2 appliqués dans le mois.
  - `r1 r2` le pourcentage du volume moyen dans le mois par rapport au forfait: 1) pour v1, 2) por v2.
  - `r3` le pourcentage du cumul des transferts des pièces jointes dans le mois par rapport au volume v2 du forfait.
- `s1 s2` : pour un avatar primaire, total des forfaits attribués aux secondaires.

#### Unités de volume
- pour v1 : 0,25 MB
- pour v2 : 25 MB

Les forfaits, pour les comptes, pour les groupes, pour la réserve, peuvent être donnés en nombre d'unités ci-dessus.

Les forfaits typiques s'étagent de 1 à 255 : (coût mensuel)
- (1) - XXS - 0,25 MB / 25 MB - 0,09c
- (4) - XS - 1 MB / 100 MB - 0,35c
- (8) - SM - 2 MB / 200 MB - 0,70c
- (16) - MD - 4 MB / 400 MB - 1,40c
- (32) - LG - 8 MB / 0,8GB - 2,80c
- (64) - XL - 16 MB / 1,6GB - 5,60c
- (128) - XXL - 32 MB / 3,2GB - 11,20c
- (255) - MAX - 64 MB / 6,4GB - 22,40c

Les codes _numériques_ des forfaits tiennent sur 1 octet : c'est le facteur multiplicateur du forfait le plus petit (0,25MB / 25MB). Des codes symboliques peuvent être ajoutés, voire modifiés, sans affecter les données.

Les _ratios_ sont exprimés en pourcentage de 1 à 255% : mais 1 est le minimum (< 1 fait 1) et 255 le maximum.

## Table: `couple` : CP id. Contact entre deux avatars A0 et A1
Deux avatars A0 et A1 sont en **contact** dès lors que A0 a pris contact avec A1 et que A1 a accepté :
- (1) un contact est _en attente_ quand A0 a émis une proposition à A1 (sous trois formes possibles) et que A1 n'a pas encore accepté mais peut encore le faire.
- (2) un contact est _hors délai_ quand A0 a émis une proposition mais que A1 n'a pas répondu dans le délai imparti,
- (3) un contact est _refusé_ quand A0 a émis une proposition mais que A1 l'a explicitement refusée.
- (4) un contact _en attente_ devient _actif_ dès que A1 a accepté le contact proposé.
- (5) un contact _actif_ devient _orphelin_ lorsque l'un des deux avatars A0 ou A1 a été détecté disparu.

Un contact est **détruit** :
- de facto lorsque les deux avatars ont disparus,
- quand il est _en attente_ quand A0 a un remord et retire sa proposition de contact,
- quand il est _hors délai_ ou _refusé_ quand A0 ne souhaite plus voir cette proposition de contact sans intérêt autre qu'historique,
- quand il est _orphelin_ et que l'avatar non disparu A0 (ou A1, celui non disparu) le trouve sans intérêt.

> A0 et A1 peuvent avoir plus d'un contact entre eux (par exemple pas un contact _amical_ et un contact _professionnel_) ce que la carte de visite du contact va préciser.

**Un contact partage :**
- une **ardoise** commune de quelques lignes : elle est active dans toutes les phases.
- des **secrets** dans les phases _active_ et _orphelin_:
  - quand **A0 et A1 ont activé le partage de secrets**, ils peuvent en créer, les mettre à jour et les lire :
    - si A0 (ou A1) a une exclusivité sur un secret l'autre ne peut que le lire,
    - les volumes d'un secret sont décomptés sur les avatars ayant activé le partage de secrets,
    - _A0 et A1 peuvent fixer une limite maximale de v1 et v2_ : les créations et mises à jour de secrets sont bloquées dès qu'elles risquent de dépasser la plus faible des deux limites.
  - si seul A0 (respectivement A1) a activé le partage de secrets, A1 (respectivement A0) n'y a pas accès et le volume n'est imputé qu'à A0 (respectivement à A1).
  - si A0 (ou A1) active le partage de secrets, le volume des secrets existants lui est débité et il les voit.
  - si A0 (ou A1) désactive le partage de secrets, le volume des secrets existants lui est crédité et il ne les voit plus.
  - si A0 (ou A1) désactive le partage de secrets mais que l'autre n'a pas activé le partage de secrets, les secrets sont détruits (puisqu'ils n'intéressent plus personne).

Un **contact** est déclaré avec :
- une clé `cc` (aléatoire de 32 bytes) cryptant les données communes dont les secrets du contact.
- une `id` qui est le hash de cette clé.
- le nom et la clé de A0.
- a minima le nom de A1 (pas toujours sa clé qui peut ne pas être connue avant acceptation de A1).

Un contact est connu dans chaque avatar A0 et A1 par une entrée dans leurs maps respectives `lcck` : 
- les clés dans ces maps sont des numéros _d'invitation_ : hash de (`cc` en hexa suivi de `0` (pour A0) ou `1` (pour A1)).
- la valeur est la `clé` crypté par la clé K du compte de l'avatar.

**Un contact a un nom et une carte de visite**
- le `nom` d'un contact est formé de l'accolement des deux noms de A0 et A1 : il est donc bien immuable. Même dans le cas d'une prise de contact A0 doit fournir le _nom exact_ de l'avatar qu'il contacte à défaut d'avoir sa clé (donc pas son id).
- **un contact peut avoir une carte de visite**, une photo et un texte, que chacun des deux A0 et A1 peut mettre à jour et qui ne sera visible que d'eux.
- dans une session de A0 respectivement de A1), le nom du contact affiché est,
  - le nom donné dans la carte de visite du contact quand il existe,
  - sinon le nom de A1.
  - idem pour la photo : photo de la carte de visite du contact sinon photo de A1 (respectivement de A0).

#### Prises de contact
Il y a 3 moyens pour A0 de prendre contact :
- **par création direct d'un contact _en attente_** quand A0 connaît l'identification de A1, 
  - soit parce que A1 est un membre d'un groupe G dont A0 est membre aussi,
  - soit parce que A1 est membre d'un groupe G dont un autre avatar du compte de A0 est membre,
  - soit parce que A1 est un contact d'un autre avatar du compte de A0.
  - **A0 crée le contact** qui reste en phase 1 tant que A1 n'a pas accepté le contact.
- **parrainage** par A0 de A1 : ils ont convenu entre eux d'une _phrase de parrainage_. A1 en tant qu'avatar _est connu_ de A0 qui lui a créé l'identification de son premier avatar, mais rien ne dit que A1 va effectivement valider la création de son compte et donc du contact qui peut rester en attente ou refusé.
- **rencontre**. A0 a rencontré A1 dans la vraie vie et ils ont convenu d'une _phrase de rencontre_.
  - A1 n'est PAS connu de A0, mais lui a communiqué son _nom exact_ (immuable) mais pas sa clé (donc pas son id).
  - A0 créé un contact mais celui-ci reste en attente jusqu'à acceptation ou refus de A1.

#### États d'un contact

**Phase**
- (1) en attente,
- (2) hors délai (parrainage / rencontre seulement),
- (3) refusé,
- (4) actif,
- (5) orphelin.

**Origine du contact**
- (0) direct
- (1) parrainage de compte
- (2) rencontre dans la vraie vie

- **(0) prise de contact directe par A0**. A1 est totalement identifié par A0 (typiquement A0 et A1 participent à un même groupe).
  - tant que A1 n'a pas accepté, 
    - le contact reste dans l'état _attente_, aucun secret ne peut être inscrit.
    - A0 peut détruire le contact qui n'apparaît plus, ni chez A0 ni chez A1.
  - si A1 refuse le contact,
    - le contact passe en état _refusé_, aucun secret ne peut être inscrit.
    - A0 détruira le contact après avoir pris connaissance de la motivation du refus.
  - si A1 accepte, le contact passe en phase 4.
- **(1) parrainage du compte de A1 par A0**. A1 en tant qu'avatar est totalement identifié par A0 mais n'a pas encore de compte. A1 a un délai limité pour accepter le _parrainage_ identifié par la phrase de parrainage convenue entre A0 et A1.
  - tant que A1 n'a pas encore accepté avant expiration du délai,
    - le contact reste dans l'état _attente_, aucun secret ne peut être inscrit.
    - A0 peut détruire le contact qui n'apparaît plus chez A0, le _parrainage_ étant aussi est inaccessible par A1.
    - A0 peut prolonger la date limite du parrainage.
  - si A1 refuse le parrainage,
    - le _parrainage_ est détruit,
    - le contact passe en état _refusé_, aucun secret ne peut être inscrit.
    - A0 détruira le contact après avoir pris connaissance de la motivation du refus.
  - si A1 accepte, le contact passe en phase 4.
  - si le délai est dépassé avant acceptation de A1,
    - le _parrainage_ s'est auto-détruit,
    - le contact apparaît dans les sessions de A0 en état _hors délai_.
    - A0 peut détruire le contact qui n'a plus d'utilité (sauf historique).
- **(2) rencontre de A1 initiée par A0**. A0 ne connaît de A1 que son nom mais pas son identifiant / clé. A1 a un délai limité pour accepter la _rencontre_ identifiée par la phrase de rencontre convenue entre A0 et A1.
  - tant que A1 n'a pas encore accepté avant expiration du délai,
    - le contact reste dans l'état _attente_, aucun secret ne peut être inscrit.
    - A0 peut détruire le contact qui n'apparaît plus chez A0, la _rencontre_ étant aussi détruite est inaccessible par A1.
    - A0 peut prolonger la date limite du rencontre.
  - si A1 refuse la rencontre,
    - la _rencontre_ est détruite,
    - le contact passe en état _refusé_, aucun secret ne peut être inscrit.
    - A0 détruira le contact après avoir pris connaissance de la motivation du refus.
  - si A1 accepte, le contact passe en phase 4.
  - si le délai est dépassé avant acceptation de A1,
    - la _rencontre_ s'est auto-détruite,
    - le contact apparaît dans les sessions de A0 en état _hors délai_.
    - A0 peut détruire le contact qui n'a plus d'utilité (sauf historique).

**Niveaux d'activité de A0 et A1**
Quand un contact est _actif_ ou _orphelin_, le niveau d'activité de A0 (ou A1) peut varier :
- (0) _non partage de secrets_ : ni lecture, ni écriture ni imputation des volumes.
  - il peut **réactiver le partage de secrets**, le volume des messages lui étant débité (s'il y en avait donc que l'autre n'avait pas aussi suspendu le partage de secret).
  - il peut devenir disparu quand il a été détecté tel quel.
- (1) _partage de secrets_ : lecture et écriture des secrets, le volume est imputé à l'avatar.
  - il peut **suspendre le partage de secrets**, le volume des secrets lui étant crédité (s'il y en avait).
  - il peut devenir disparu quand il a été détecté tel quel.
- (2) _disparu_ : par principe il n'accède à rien et l'autre ne connaît plus que son nom (c'est historique) puisque même sa carte de visite n'existe plus.

Quand A0 et A1 sont tous deux _disparu_, le contact disparaît.

#### Prolongation
- pour un parrainage ou une rencontre, la prolongation ne peut s'effectuer qu'avant la fin de la `dlv`.
- la `dlv` est modifiée sur les rows `contact` et `couple`.

Table :

    CREATE TABLE "couple" (
    "id"   INTEGER,
    "v"  	INTEGER,
    "st"  INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "mx10"  INTEGER,
    "mx20"  INTEGER,
    "mx11"  INTEGER,
    "mx21"  INTEGER,
    "dlv"	INTEGER,
    "datac"  BLOB,
    "phk0"	BLOB,
    "infok0"	BLOB,
    "infok1"	BLOB,
    "mc0"	BLOB,
    "mc1"  BLOB,
    "ardc"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_v_couple" ON "couple" ( "id", "v" );

- `id` : id du contact
- `v` :
- `st` : quatre chiffres `p o 0 1` : phase / état
  - `p` : phase - (1) en attente, (2) hors délai, (3) refusé, (4) actif, (5) orphelin.
  - `o` : origine du contact: (0) direct, (1) parrainage, (2) rencontre.
  - `0` : pour A0 - (0) pas de partage de secrets, (1) partage de secrets, (2) disparu.
  - `1` : pour A1 -
- `v1 v2` : volumes actuels des secrets.
- `mx10 mx20` : maximum des volumes autorisés pour A0
- `mx11 mx21` : maximum des volumes autorisés pour A1
- `dlv` : date limite de validité éventuelle de prise de contact.
- `datac` : données cryptées par la clé `cc` du couple :
  - `x` : `[nom, rnd], [nom, rnd]` : nom et clé d'accès à la carte de visite respectivement de A0 et A1.
- `phk0` : phrase de parrainage / rencontre cryptée par la clé K du parrain (sera détruite après acceptation / refus hors délai).
- `infok0 infok1` : commentaires personnels cryptés par leur clé K, respectivement de A0 et A1.
- `mc0 mc1` : mots clé définis respectivement par A0 et A1.
- `ardc` : ardoise commune cryptée par la clé cc. [dh, texte]
- `vsh` :

Dans un contact il y a deux avatars, l'initiateur et l'autre : `im` **l'indice membre** d'un avatar dans un de ses contacts est par convention,
- `1` s'il est initiateur `datac.x[0]`,
- `2` dans l'autre cas `datac.x[1]`,
- la valeur 0 n'est pas utilisée (même logique que dans un groupe).

_Remarques_
- pour un compte parrain, la liste de ses filleuls est la liste des contacts ayant par convention un mot clé `Filleul`.
- pour un compte filleul: son parrain de création et tout avatar pouvant être utilisé comme parrain (de la même tribu) ont par convention le mot clé `Parrain`. La tribu comme le statut de parrain pouvant changer, c'est une opération qui effectue cette vérification sur demande explicite.

## Table: `contact` : CP `phch`. Prise de contact par phrase de contact de A1 par A0
Les rows `contact` ne sont pas synchronisés en session : ils sont,
- lus sur demande par A1,
- supprimés physiquement éventuellement par A0 sur remord ou prolongés par mise à jour de la `dlv`.

Ceci couvre les deux cas de parrainage et de rencontre.
- pour un parrainage: c'est sur la page de login que le filleul peut accéder à son parrainage, l'accepter ou le refuser.
- pour une rencontre: c'est sur la page de l'avatar souhaitant la rencontre qu'un bouton permet d'accéder à la rencontre et aux détails du couple pour accepter ou refuser.
- dans les deux cas (acceptation / refus) le row `contact` est détruit.

**En cas de non réponse, le GC détruit le row après dépassement de la `dlv`.**

Table :

    CREATE TABLE "contact" (
    "phch"   INTEGER,
    "dlv"	INTEGER,
    "datax"  BLOB,
    "vsh" INTEGER,
    PRIMARY KEY("phch");
    CREATE INDEX "dlv_contact" ON "contact" ( "dlv" );

- `phch` : hash de la phrase de contact convenue entre le parrain A0 et son filleul A1 (s'il accepte)
- `dlv`
- `datax` : cryptée par le PBKFD de la phrase de contact:
  - `cle` : clé du couple (donne son id).
  - `nom` : nom de A1 pour première vérification immédiate en session que la phrase est a priori bien destinée à cet avatar. Le nom de A1 figure dans le nom du couple après celui de A1.
  - Pour un parrainage seulement
    - `tribu` : `[nom, rnd]` nom complet de la tribu.
    - `idtpc` : id de la tribu cryptée par la clé publique du comptable.
    - `forfaits` : `[f1, f2]` forfaits attribués par le parrain (pour un parrainage seulement).
  - Pour une rencontre seulement
    - `idt` : id de sa tribu SI A0 en est parrain.
- `vsh` :

#### _Parrainage_
- Le parrain peut détruire physiquement son `contact` avant acceptation / refus (remord).
- Le parrain peut prolonger la date-limite de son contact (encore en attente), sa `dlv` est augmentée.

**Si le filleul refuse le parrainage :** 
- L'ardoise du `couple` contient une justification / remerciement du refus, la phase passe à 2, la phrase de contact est effacée du contact.
- Le row `contact` est supprimé. 

**Si le filleul ne fait rien à temps :** 
- Lors du GC sur la `dlv`, le row `contact` sera supprimé par GC de la `dlv`,
- la phrase de contact est effacée du row `couple`. 

**Si le filleul accepte le parrainage :** 
- Le filleul crée son compte et son premier avatar (dans `couple.datac.x[1]` vaut `[nom, rnd]` qui donne l'id de son avatar et son nom). Les infos de tribu pour le compte sont obtenu de `contact`.
- la ligne `compta` du filleul est créée et créditée des forfaits attribués par le parrain.
- la ligne `tribu` est mise à jour (forfaits / réserves).
- le row `couple` est mis à jour (phase 4), l'ardoise renseignée, les volumes maximum sont fixés.

#### _Rencontre_ initiée par A0 avec A1
- A0 peut détruire physiquement son contact avant acceptation / refus (remord).
- A0 peut prolonger la date-limite de la rencontre (encore en attente), sa `dlv` est augmentée.

**Si A1 refuse la rencontre :** 
- L'ardoise du `couple` contient une justification / remerciement du refus, la phase passe à 2.
- Le row `contact` est supprimé. 

**Si A1 ne fait rien à temps :** 
- Lors du GC sur la `dlv`, le row `contact` sera supprimé par GC de la `dlv`. 

**Si A1 accepte la rencontre :** 
- le row `couple` est mis à jour (phase 4), l'ardoise renseignée, les données `[nom, rnd]` sont définitivement fixées (`nom` l'était déjà). Les volumes maximum sont fixés.

## Table: `groupe` : CP: `id`. Entête et état d'un groupe
Un groupe est caractérisé par :
- son entête : un row de `groupe`.
- la liste de ses membres : des rows de `membre`.
- la liste de ses secrets : des rows de `secret`.

Un groupe est hébergé par un avatar _hébergeur_ (ses volumes sont décomptés sur sa ligne comptable). L'hébergement est noté par :
- `imh` : indice membre de l'avatar hébergeur qui a créé le groupe et en a été le premier animateur.
- `dfh`, la date de fin d'hébergement, qui vaut 0.

Le compte peut mettre fin à son hébergement:
- `dfh` indique le jour de la fin d'hébergement.
- les secrets ne peuvent plus être mis à jour ou créés (comme un état archivé).
- à `dfh` + N jours, le GC plonge le groupe en état _zombi_
  - `dfh` vaut 99999 et toutes les propriétés autres que `id v` sont 0 / null.
  - les secrets et membres sont purgés.
  - le groupe est _ignoré_ en session, comme s'il n'existait plus et est retiré au fil des login des maps `lgrk` des avatars qui le référencent (ce qui peut prendre jusqu'à un an).
  - le row `groupe` sera effectivement détruit par le GC quotidien seulement sur dépassement de `dds`.
  - ceci permet aux sessions de ne pas risquer de trouver un groupe dans des `lgrk` d'avatar sans row `groupe` (sur dépassement de `dds`, les login sont impossibles).

**Les membres d'un groupe** reçoivent lors de leur création (opération de création d'un contact d'un groupe) un indice membre `im` :
- cet indice est attribué en séquence : le premier membre est celui du créateur du groupe a pour indice 1 (il est animateur et hébergeur).
- les rows membres ne sont jamais supprimés, sauf par purge physique à la suppression logique de leur groupe.

Table :

    CREATE TABLE "groupe" (
    "id"  INTEGER,
    "v"   INTEGER,
    "dfh" INTEGER,
    "st"  INTEGER,
    "mxim"  INTEGER,
    "imh"  INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "f1"  INTEGER,
    "f2"  INTEGER,
    "mcg"   BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "dfh_groupe" ON "groupe" ( "dfh" ) WHERE "dfh" > 0;
    CREATE INDEX "id_v_groupe" ON "groupe" ( "id", "v" );

- `id` : id du groupe.
- `v` :
- `dds` :
- `dfh` : date (jour) de fin d'hébergement du groupe par son hébergeur
- `st` : `x y`
    - `x` : 1-ouvert (accepte de nouveaux membres), 2-fermé (ré-ouverture en vote)
    - `y` : 0-en écriture, 1-protégé contre la mise à jour, création, suppression de secrets.
- `mxim` : dernier `im` de membre attribué.
- `idhg` : id du compte hébergeur crypté par la clé G du groupe.
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `v1 v2` : volumes courants des secrets du groupe.
- `f1 f2` : forfaits attribués par le compte hébergeur.
- `mcg` : liste des mots clés définis pour le groupe cryptée par la clé du groupe cryptée par la clé G du groupe.
- `vsh`

## Table: `membre` : CP `id nm`. Membre d'un groupe
Chaque membre d'un groupe a une entrée pour le groupe identifiée par son indice de membre `im`.
- pour ajouter un membre _contact_ à un groupe il est fourni son indice `im` qui doit est égal à `mxim` du groupe + 1 : ceci prémunit contre des enregistrements parallèles d'un même avatar en tant que membre contact. L'opération boucle jusqu'à ce que ça soit le cas.

Les données relatives aux membres sont cryptées par la clé du groupe.

Table

    CREATE TABLE "membre" (
    "id"  INTEGER,
    "im"	INTEGER,
    "v"		INTEGER,
    "st"	INTEGER,
    "vote"  INTEGER,
    "mc"  BLOB,
    "infok" BLOB,
    "datag"	BLOB,
    "ardg"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id", "im"));
    CREATE INDEX "id_v_membre" ON "membre" ( "id", "v" );

- `id` : id du **groupe**.
- `im` : indice du membre dans le groupe.
- `v` :
- `st` : `x p`
  - `x` : 0:envisagé, 1:invité, 2:actif (invitation acceptée), 3: inactif (invitation refusée), 4: inactif (résilié), 5: inactif (disparu).
  - `p` : 0:lecteur, 1:auteur, 2:animateur.
- `vote` : vote de réouverture.
- `mc` : mots clés du membre à propos du groupe.
- `infok` : commentaire du membre à propos du groupe crypté par la clé K du membre.
- `datag` : données cryptées par la clé du groupe. (immuable)
  - `nom, rnd` : nom complet de l'avatar.
  - `ni` : numéro d'invitation du membre dans `invitgr`. Permet de supprimer l'invitation et d'effacer le groupe dans son avatar (clé de `lgrk`).
	- `idi` : id du membre qui l'a _envisagé_.
- `ardg` : ardoise du membre vis à vis du groupe. Couple `[dh, texte]` crypté par la clé du groupe. Contient le texte d'invitation puis la réponse de l'invité cryptée par la clé du groupe. Ensuite l'ardoise peut être écrite par le membre (actif) et les animateurs.
- `vsh`

**Remarques**
- un membre _envisagé_ a un row `membre` de statut `stx` `0`: (l'avatar ne le sait pas, n'a pas le groupe dans sa liste des groupes). Tous les membres commencent leur cycle de vie en tant que _envisagé_.
- un membre _invité_ a un row `membre` de statut `stx` `1`: l'avatar a le groupe dans sa liste des groupes, il peut répondre à l'invitation, accepter ou refuser et motiver sa réponse dans son ardoise.
- quand un membre `invité` accepte son statut `stx` passe à `2`.
- les membres de statut _invité_ et _actif_ peuvent accéder à la liste des membres et à leur _ardoise_ : ils ont la clé du groupe dans leur row `avatar`.
- les membres _actif_ accèdent aux secrets. En terme de cryptographie, les membres invités _pourraient_ aussi en lecture (ils ont reçu la clé dans l'invitation) mais le serveur l'interdit.
- les membres des statuts _envisagé, ayant refusé, résilié, disparu_ n'ont pas / plus la clé du groupe dans leur row `avatar` (`lgrk`). `infok` est null.
- un membre _résilié_ peut être réinvité, le numéro d'invitation `ni` est réutilisé.

Les animateurs peuvent :
- inviter d'autres avatars à rejoindre la liste.
- changer les statuts des membres non animateurs, en particulier les résilier.

Le row `membre` d'un membre subsiste quand il est _résilié_ ou _disparu_ pour information historique du groupe: sa carte de visite reste accessible quand il est _résilié_.

## Table: `invitgr` : CP `id ni`. Invitation d'un avatar M par un animateur A à un groupe G
Un avatar A connaît la liste des groupes dont il est membre par son row `avatar` qui reprend les identités des groupes cryptées par la clé K du compte.

Une invitation est un row qui **notifie** une session de M qu'il a été inscrit comme membre invité d'un groupe :
- elle porte l'id de l'invité.
- elle porte un numéro d'invitation aléatoire qui permettra aux animateurs du groupe de *résilier* l'accès de A au groupe en détruisant la référence au groupe dans le row avatar de A.
- elle porte le couple `nom rnd` identifiant le groupe et sa clé crypté par la clé publique de l'avatar.

Dans une session de M dès que cette invitation parvient, soit par synchronisation, soit au chargement initial, la session poste une opération `regulGr` qui va inscrire dans le row avatar de M le nouveau groupe `nom rnd im` mais crypté par la clé K du compte de M. Ceci détruit l'invitation devenu inutile.

    CREATE TABLE "invitgr" (
    "id"  INTEGER,
    "ni" INTEGER,
    "datap" BLOB,
    PRIMARY KEY ("id", "ni"));

- `id` : id du membre invité.
- `ni` : numéro d'invitation.
- `datap` : crypté par la clé publique du membre invité.
	- `[nom, rnd, im]` : nom complet du groupe (donne sa clé) + indice de l'invité dans le groupe.

## Table `invitcp` : CP `id ni`. Invitation d'un avatar B par un avatar A à former un couple C
Un avatar connaît la liste des couples dont il fait partie par son row `avatar` qui reprend les clés de ces couples cryptées par la clé K du compte.

Une invitation est un row qui **notifie** une session de B qu'il a été inscrit comme second membre du couple :
- elle porte l'id de l'invité.
- elle porte son numéro d'invitation en complément d'identification.
- elle porte `cc` la clé du couple cryptée par la clé publique de l'avatar B.

Dans une session de B dès que cette invitation parvient, soit par synchronisation, soit au chargement initial, la session poste une opération `regulCp` qui va inscrire dans le row avatar de B la clé du nouveau couple `cc` mais crypté par la clé K du compte de B. Ceci détruit l'invitation devenu inutile.

    CREATE TABLE "invitcp" (
    "id"  INTEGER,
    "ni" INTEGER,
    "datap" BLOB,
    PRIMARY KEY ("id", "ni"));

- `id` : id du membre invité.
- `ni` : numéro d'invitation pseudo aléatoire. Hash de (`cc` en hexa suivi de `0` ou `1` selon que ça s'adresse au membre 0 ou 1 du couple).
- `datap` : clé du couple cryptée par la clé publique du membre invité.

## Table `secret` : CP `id ns`. Secret
Un secret est identifié par:
- `id` : l'id du propriétaire (avatar / contact / groupe),
- `ns` : numéro complémentaire aléatoire.

La clé de cryptage du secret `cles` est selon le cas :
- (0) *secret personnel d'un avatar A* : la clé K de l'avatar.
- (1) *secret d'un couple d'avatars A0 et A1* : la clé `cc` de leur `couple`.
- (2) *secret d'un groupe G* : la clé du groupe G.

### Un secret a toujours un texte et possiblement des fichiers attachés
Le texte a une longueur maximale de 4000 caractères. L'aperçu d'un secret est constituée des N3 premiers caractères de son texte ou moins (première ligne au plus).
- le texte est stocké gzippé au delà d'une certaine taille.

**La liste des auteurs d'un secret donne les derniers auteurs:**
- dans l'ordre de modification, le plus récent en tête,
- sans doublon.

### Fichiers attachés
Un secret _peut_ avoir plusieurs fichiers attachés, chacun est identifié par un numéro aléatoire très grand. Pour chaque fichier les propriétés suivantes sont mémorisées:
- `idf` : identifiant aléatoire relatif au secret.
- `nom` est un _nom de fichier_, d'où un certain nombre de caractères interdits (dont le `/`).
- `info` : courte indication de version lorsqu'il existe plusieurs fichiers de même nom.
- `dh` est la date-heure d'enregistrement du fichier (pas de la création ou dernière modification de son fichier d'origine).
- `type` : type mime de la version du fichier.
- `gz` : les fichiers de types `text/...` sont gzippés en stockage.
- `lg` : la taille du fichier est celle NON gzippé.
- `sha` : SHA1 du fichier d'origine.

> On ne peut qu'ajouter ou supprimer des fichiers : on peut disposer de plusieurs _versions_ pour un nom donné.

> **Le contenu d'un fichier attaché sur stockage externe est crypté par la clé du secret.**

### Mise à jour d'un secret
Le droit de mise à jour d'un secret est contrôlé par le couple `xxxp` :
- `xxx` indique quel avatar a l'exclusivité d'écriture et le droit de basculer la protection :
  - pour un secret personnel, x est implicitement l'avatar détenteur du secret.
  - pour un secret de couple, 1 ou 2.
  - pour un secret de groupe, x est `im` l'indice du membre.
- `p` indique si le texte est protégé contre l'écriture ou non.

Celui ayant l'exclusivité peut décider :
- de protéger le secret contre l'écriture (se l'interdire à lui-même),
- de lever cette protection (se l'autoriser à lui-même),
- de transférer l'exclusivité à un autre membre (pour un groupe) ou à l'autre dans le couple,
- de supprimer l'exclusivité.

Un animateur de groupe a ces mêmes droits pour un secret de groupe.

### Secret temporaire et permanent
Par défaut à sa création un secret est *temporaire* :
- son `st` contient la *date limite de validité* indiquant qu'il sera automatiquement détruit à cette échéance.
- un secret temporaire peut être prolongé, tout en restant temporaire.
- un avatar Ai qui le partage peut le déclarer *permanent*, le secret ne sera plus détruit automatiquement et par convention son `st` est égal à `99999`:
  - l'avatar propriétaire pour un secret personnel.
  - les deux avatars pour un secret de couple.
  - un des animateurs pour un secret de groupe.

### Secrets voisins
Les secrets peuvent être regroupés par *voisinage* autour d'un secret de référence : ceci permet de voir ensemble facilement les secrets parlant d'un même sujet précis ou correspondant à une conversation.
- **un secret voisin d'un secret de référence** contient sa référence (id et numéro de secret) ; celle-ci est immuable, donnée à la création.
- **un secret de référence n'a pas lui-même de référence** : ce sont ses voisins qui le référencent.
- si B est un secret voisin de A (référençant A), on peut créer C voisin de B mais en fait C portera la référence de A (pas de B).
- rien n'empêche ainsi indirectement de rajouter des voisins à un secret de référence disparu.
- un avatar peut ainsi avoir des secrets voisins d'un secret de référence auquel il ne peut pas accéder (et qui peut-être n'existe plus), la grande famille des voisins peut ainsi s'étendre loin. 

Table :

    CREATE TABLE "secret" (
    "id"  INTEGER,
    "ns"  INTEGER,
    "v" INTEGER,
    "x" INTEGER,
    "st"  INTEGER,
    "xp" INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "mc"   BLOB,
    "txts"  BLOB,
    "mfas"  BLOB,
    "refs"  BLOB,
    "vsh" INTEGER,
    PRIMARY KEY("id", "ns");
    CREATE INDEX "id_v_secret" ON "secret" ("id", "v");

- `id` : id du groupe ou de l'avatar.
- `ns` : numéro du secret.
- `x` : jour de suppression (0 si existant).
- `v` :
- `st` :
  - `99999` pour un *permanent*.
  - `dlv` pour un _temporaire_.
- `xp` : _xxxp_ (`p` reste de la division par 10)
   - `xxx` : exclusivité : l'écriture et la gestion de la protection d'écriture sont restreintes au membre du groupe dont `im` est `x` (un animateur a toujours le droit de gestion de protection et de changement du `x`). Pour un secret de couple : 1 ou 2.
    - `p` : 0: pas protégé, 1: protégé en écriture.
- `v1` : volume du texte
- `v2` : volume total des fichiers attachés
- `mc` :
  - secret personnel : vecteur des index de mots clés.
  - secret de couple : map sérialisée,
    - _clé_ : `im` de l'auteur (0 ou 1 - couple.avc),
    - _valeur_ : vecteur des index des mots clés attribués par le conjoint.
  - secret de groupe : map sérialisée,
    - _clé_ : `im` de l'auteur (0 pour les mots clés du groupe),
    - _valeur_ : vecteur des index des mots clés attribués par le membre.
- `txts` : crypté par la clé du secret.
  - `d` : date-heure de dernière modification du texte
  - `l` : liste des auteurs (pour un secret de couple ou de groupe).
  - `t` : texte gzippé ou non
- `mfas` : map des fichiers attachés.
- `refs` : couple `[id, ns]` crypté par la clé du secret référençant un autre secret (référence de voisinage qui par principe, lui, n'aura pas de `refs`).
- `vsh`

**_Remarque :_** un secret peut être explicitement supprimé. Afin de synchroniser cette forme particulière de mise à jour pendant un an (le délai maximal entre deux login), le row est conservé jusqu'à la date x + 400 avec toutes les colonnes (sauf `id ns x v`) à 0 / null.

**Map des fichiers attachés :**
- _clé_ `idf`: 
  - `idf` : numéro aléatoire généré à la création.
- _valeur_ : `{ nom, info, dh, type, gz, lg, sha }` crypté par la clé S du secret.

**Identifiant de stockage :** `org/sid/idf`  
- `org` : code de l'organisation.
- `sid` : id du secret en base64 URL : identifiant de l'avatar / contact / groupe auquel le secret appartient.
- `idf` : identifiant aléatoire du fichier

En imaginant un stockage sur file system,
- il y a un répertoire par organisation,
- pour chacun, un répertoire par avatar / contact / groupe ayant des secrets ayant des fichiers attachés,
- pour chacun, un fichier par fichier attaché.

_Une nouvelle version_ d'un fichier attaché est stockée sur support externe **avant** d'être enregistrée dans son secret.
- les versions crées par anticipation et non validées dans un secret comme celles qui n'ont pas été supprimées après validation du secret, peuvent être retrouvées par un traitement périodique de purge qui peut s'exécuter en ignorant les noms et date-heures réelles des fichiers scannés simplement en lisant les _clés_ de la map `mafs`.

La suppression d'un avatar / contact / groupe s'accompagne de la suppression de son _répertoire_. 

La suppression d'un secret s'accompagne de la suppressions de N fichiers dans un seul répertoire.

## Mots clés, principes et gestion

Les mots clés sont utilisés pour :
- filtrer / caractériser à l'affichage les **contacts** d'un compte.
- filtrer / caractériser à l'affichage les **groupes** accédés par un compte.
- filtrer / caractériser à l'affichage les **secrets**, personnels, partagés avec un contact ou d'un groupe.

### Mots clés : index, catégorie, nom
Un mot clé a un **index** et un **nom** :
- **l'index** (représenté sur un octet) identifie le mot clé et qui l'a défini :
  - un index de 1 à 99 est un mot clé personnel d'un compte.
  - un index de 100 à 199 est un mot clé défini pour un groupe.
  - un index de 200 à 255 est un mot clé défini par l'organisation et enregistré dans sa configuration (donc peu modifiable).
- **le nom** est un texte unique dans l'ensemble des mots clés du définissant : deux mots clés d'un compte, d'un groupe ou de l'organisation ne peuvent pas avoir un même nom. 
  - le nom est court et peut contenir des caractères émojis en particulier comme premier caractère.
  - l'affichage _réduit_ ne montre que le premier caractère si c'est un émoji, sinon les deux premiers.

#### Catégories de mots clés
Afin de faciliter leur attribution, un mot clé a une _catégorie_ qui permet de les regrouper par finalité :
- la catégorie est un mot court commençant par une majuscule : par exemple _Statut_, _Thème_, _Projet_, _Section_
- la catégorie ne fait pas partie du nom : elle est donnée à la définition / mise à jour du mot clé mais est externe.
- il n'y a pas de catégories prédéfinies.
- la catégorie sert pour sélectionner des mots clés à attacher à son objet et à l'affichage pour choisir plus facilement un mot clé pour filtre selon leur usage / signification.

#### Liste de mots clés
C'est la liste de leurs index, pas de leurs noms : il est ainsi possible de corriger le nom d'un mot clé et toutes ses références s'afficheront avec le nouveau nom rectifié.
- un index n'est présent qu'une fois.
- l'ordre n'a pas d'importance.
- les mots clés d'index 1 à 99 sont toujours ceux du compte qui les regardent. 
- ceux d'index de 200 à 255 sont toujours ceux de l'organisation.
- ceux d'index de 100 à 199 ne peuvent être attachés qu'à un secret de groupe, leur signification est interprétée vis à vis du groupe détenteur du secret.

> Remarque : deux mots clé d'un compte et d'un groupe peuvent porter le même nom (voire d'ailleurs un mot clé de l'organisation). L'origine du mot clé est distinguée à l'affichage en lisant son code.

#### Mots clés _obsolètes_
Un mot clé _obsolète_ est un mot clé sans catégorie :
- son attribution est interdite : quand une liste de mots clés est éditée, les mots clés obsolètes sont effacés.
- la suppression définitive d'un mot clé ne s'opère que sur un mot clé obsolète. Une recherche permettra de lister où il apparaît avant de décider.

### Présence des mots clés
- sur un **contact** d'un avatar (une liste pour A0 et une pour A1).
- sur un **membre** d'un groupe : mot clés attribués par le membre au groupe.
- sur un **secret**. La propriété `mc` contient un objet de structure différente selon le type de secret.

**Secret personnel**  
`mc` est un vecteur d'index de mots clés. Les index sont ceux du compte et de l'organisation.

**Secret de contact**
`mc` est une map a deux entrée `1 2`, une pour A0 et A1 du contact. La valeur est le vecteur des mots clés attribué par l'avatar A0 ou A1. Les index des mots clés sont ceux personnels de l'avatar et ceux de l'organisation.

**Secret de groupe**
`mc` est une map :
- _clé_ : im, indice du membre dans le groupe. Par convention 0 désigne le groupe lui-même.
- _valeur_ : vecteur d'index de secrets. Les index sont ceux personnels du membre, ceux du groupe, ceux de l'organisation.

Pour utilisation pour filtrer une liste de secrets dans un groupe :
- si le compte a lui-même donné une liste de mots clés, c'est celle-ci qui est prise, sans considérer les mots clés du groupe.
- sinon ce sont les mots clés du groupe.
- ainsi le groupe peut avoir indiqué que le secret est _nouveau_ et _important_, mais si le compte A a indiqué que le secret est _lu_ et _sans intérêt_ c'est ceci qui sera utilisé pour filtrer les listes.

# Gestion des disparitions / résiliations
**Les ouvertures de session** *signent* dans la table `cv`, colonne `dds`, les rows relatifs aux avatars du compte, contacts et groupes accédés par le compte. 

Cette signature toutefois n'a pas lieu si le row `compta` de l'avatar primaire est marqué _en alerte / sursis / bloqué_ ou si son parrain est lui-même _en alerte / sursis / bloqué_.

**La fin d'hébergement d'un groupe** provoque l'inscription de la date du jour dans la propriété `dfh` du row `groupe` (sinon elle est à zéro).

## GC quotidien
Le GC quotidien effectue les activités de nettoyage suivantes :
- suppression logique des rows `avatar` dans `cv` sur dépassement de leur `dds` + N1 jours. Purge physique des rows `secret avrsa compta` de même id.
- suppression logique des rows `couple` dans `cv` sur dépassement de leur `dds` + N1 jours. Purge physique des rows `secret` de même id.
- suppression logique des rows `groupe` dans `cv` sur dépassement de leur `dds` + N1 jours. Purge physique des rows `membre secret` de même id.
- suppression logique des rows `groupe` sur dépassement ou de leur `dfh` + N2 jours. Purge physique des rows `membre secret` de même id.
- suppression physique des rows `contact` ayant une date-limite de validité `dlv` dépassée.

**_Remarque_** : l'avatar primaire d'un compte est toujours détruit physiquement avant ses avatars secondaires puisqu'il apparaît plus ancien que ses avatars dans l'ordre des signatures. Le compte n'étant plus accessible par son avatar primaire, ses avatars secondaires ne seront plus signés ni les groupes et contacts auxquels ils accédaient.

## Rows `secret` et leurs fichiers attachés
Pour chaque secret détruit il faut aussi détruire ses fichiers attachés : ceci ne peut pas s'effectuer dans la même transaction puisque affectant un espace de stockage séparé non lés au commit de la base.
- un row portant l'identification du fichier `id, idf` est inséré dans une table d'attente `trec` dès lors que son volume v2 n'est pas 0.
- ce row est supprimé à la validation du secret.
- le GC purge de l'espace secondaire tous les fichiers listés dans cette table et inscrit içl y a un certain temps (transferts finalement non validés en table `secret`).

## Rows `couple membre` et le statut _disparu_
La disparition de A0 ou A1 d'un couple ou d'un membre est constaté en session quand sa carte de visite est demandée / rafraîchie : elle revient alors à `null` avec un statut _disparu_.
- cette constatation n'est pas pérenne sur le long terme: au bout d'un certain temps, la carte de visite ne revient plus du tout du serveur et il est impossible à une session de discerner si c'est parce qu'elle est inchangée ou disparue.
- chaque session constatant une carte de visite _disparu_ pour A0 / A1 d'un contact ou un membre d'un groupe, fait inscrire sur le serveur le statut _disparu_ sur le contact (`st0` ou `st1` à 2) ou le membre :
  - ceci évite aux autres sessions de procéder à la même opération.
  - les cartes de visite ne sont plus demandées par les sessions (ce qui réduit le trafic et les recherches inutiles en base centrale).

## Disparition _explicite_ d'un groupe
Elle est causée par l'auto-résiliation du dernier memebre du groupe : son row `cv` a son `x` à 1 afin que le GC quotidien purge les rows `groupe membre secret` et les fichiers de ses secrets.

## Disparition _explicite_ d'un avatar
Pour un avatar primaire, tous les avatars secondaires sont préalablement supprimés.

C'est une opération _longue_ :
- fin d'hébergement sur tous les groupes hébergés par le compte de l'avatar.
- si c'est un avatar secondaire récupération de ses forfaits sur la compta de l'avatar primaire.
- mise à jour de son statut _disparu_ sur les membres des groupes : ceci peut entraîner la suppression logique du groupe si c'était le dernier membre actif / invité.
- mise à jour de son `st0` ou `st1` à 2 sur ses contacts et suppression logique du couple s'il était seul dans le couple.
- si c'est un avatar secondaire, retrait de l'avatar dans la liste des avatars du compte.
- si c'est un avatar primaire, suppression des rows `compte` et `prefs`.

Son row `cv` a son `x` à 1 afin que le GC quotidien purge les rows `compta secret` et les fichiers de ses secrets.
