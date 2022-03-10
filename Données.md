# Boîtes à secrets - Modèle de données

## Identification des objets

Les clés AES et les PBKFD font 32 bytes (44 caractères en base64 url).

Le hash des string en *integer* est un entier sur 53 bits (intègre en Javascript):
- 15 chiffres décimaux.
- 9 caractères en base64 URL.

Le hash des string en *BigInt* est un 64 bits (sans signe, toujours positif) :
- 19 chiffres décimaux.
- 12 caractères en base64 URL.

Les date-heures sont exprimées en micro-secondes depuis le 1/1/1970, soit 52 bits (entier intègre en Javascript).

### Compte
- `id` : un entier (intègre en Javascript) issu de 6 bytes aléatoires.  
- `clé K` : 32 bytes aléatoires.  
- `pcb` : PBKFD de la phrase complète (clé X) - 32 bytes.  
- `dpbh` : hashBin (_integer_) du PBKFD du début de la phrase secrète.

**La phrase secrète d'un compte reste dans le cerveau du titulaire.**
- sa transformée par PBKFD dès la saisie donne une clé AES X qui ne sort jamais de la session cliente et n'est jamais stockée de manière permanente.

**La clé K d'un compte**,
- n'est stockée en session comme en serveur que sous forme cryptée par X.
- n'est jamais transmise au serveur en clair.
- les données cryptées par K, ne sont lisibles dans le serveur que quand elles ont été transmises aussi en clair dans une opération. 

### Nom complet d'un avatar ou d'un groupe
Le **nom complet** d'un avatar ou d'un groupe est un couple `[nom, rnd]`
- `nom` : nom lisible et signifiant, entre 6 et 20 caractères.
- `rnd` : 32 bytes aléatoires. Clé de cryptage.
- A l'écran le nom est affiché sous la forme `nom@abgh` ou `ab` sont les deux premiers caractères de l'id en base64 et `gh` les deux derniers.

**Dans les noms,** les caractères `< > : " / \ | ? *` et ceux dont le code est inférieur à 32 (donc de 0 à 31) sont interdits afin de permettre d'utiliser le nom complet comme nom de fichier.

### Avatar
La **clé de cryptage** de la carte de visite est `rnd`.

L'`id` d'un avatar est le hash (integer) des bytes de `rnd`, 6 bytes, soit 8 base64.

### Groupe
La **clé de cryptage** du groupe (carte de visite et secrets) est`rnd`.

L'`id` d'un groupe est le hash (integer) des bytes de `rnd`, 6 bytes, soit 8 base64.

### Secret
- `id` : du groupe ou de l'avatar propriétaire
- `ns` : numéro relatif au groupe / avatar, entier issu de 4 bytes aléatoires.

### Attributs génériques
- `v` : version, entier.
- `dds` : date de dernière signature, en nombre de jours depuis le 1/1/2021. Signale que ce jour-là, l'avatar, le compte, le groupe était *vivant / utile / référencé*. Pour éviter des rapprochements entre eux, la *vraie* date de signature peut être entre 0 et 30 jours *avant*.  
- `dlv` : date limite de validité, en nombre de jours depuis le 1/1/2021.
- `st` : `avatar, contact, groupe, secret` : quand `st` est négatif c'est le numéro du jour de sa suppression logique. Les rows ne sont pas supprimés physiquement pendant un certain temps afin de permettre aux mises à jour incrémentales des sessions de détecter les suppressions. Une session pour un compte étant ouverte au moins un fois sur le N0 (365) jours, les `st` négatifs de plus de 365 (+ 30) jours peuvent être physiquement supprimés.

Les comptes sont censés avoir au maximum N0 jours entre 2 connexions faute de quoi ils sont considérés comme disparus.

### Signatures des comptes, avatars et groupes (`dds`)
A chaque connexion d'un compte, le compte signe si la `dds` actuelle n'est pas _récente_ (sinon les signatures ne sont pas mises à jour) :
- pour lui-même dans `compte` : jour de signature tiré aléatoirement entre j-28 et j-14.
- pour ses avatars dans `avatar` : jour de signature tiré aléatoirement pour chacun entre j-14 et j.
- pour les groupes auxquels ses avatars sont invités ou actifs (dont l'accès n'est pas résilié) dans `groupe` : jour de signature tiré aléatoirement pour chacun entre j-14 et j.

Le GC traitement quotidien des `dds` :
- pour les **comptes** : purge des rows `compte compta ardoise prefs` afin de bloquer la connexion.
- pour les **groupes** (voir aussi la gestion de `dfh` date de fin d'hébergement): purge de leur données `membre secret` et suppression logique du row `groupe` lui-même.
- pour les **avatars** : suppression logique du row `avatar` et purge physique des `contact parrain rencontre secret avrsa`.

### Version des rows
Les rows des tables devant être présents sur les clients ont une version, de manière à pouvoir être chargés sur les postes clients de manière incrémentale : la version est donc croissante avec le temps et figure dans tous les rows de ces tables.  
- utiliser une date-heure présente l'inconvénient de laisser une meta-donnée intelligible en base ;
- utiliser un compteur universel a l'inconvénient de facilement deviner des liaisons entre objets : par exemple l'invitation à établir un contact entre A et B n'apparaît pas dans les rows eux-mêmes mais serait lisible si les rows avaient la même version. Crypter l'appartenance d'un avatar à un groupe alors qu'on peut la lire de facto dans les versions est un problème.
- utiliser un compteur par objet rend complexe la génération de SQL avec des filtres qui associent chaque objet à sa dernière version connue.

Tous les objets synchronisables (sauf les comptes) sont identifiés, au moins en majeur, par une id d'avatar ou de groupe. Par exemple l'obtention des contacts d'un avatar se fait par une sélection d'abord sur l'id de l'avatar, puis sur sa version pour ne récupérer incrémentalement que ceux changés / créés. D'où l'option de gérer **une séquence de versions**, pas par id d'avatar, mais par hash de cet id.

#### `vcv` : version de la carte de visite d'un avatar
Afin de pouvoir rafraîchir uniquement les cartes de visites des avatars (porteuses aussi de l'information de disparition), la propriété `vcv` de avatar donne la version dans la séquence universelle

## Tables

- `versions` (id) : table des prochains numéros de versions (actuel et dernière sauvegarde) et autres singletons (id value)
- `avrsa` (id) : clé publique d'un avatar

_**Tables aussi persistantes sur le client (IDB)**_

- `compte` (id) : authentification et liste des avatars d'un compte 
- `prefs` (id) : données et préférences d'un compte
- `compta` (id) : ligne comptable du compte
- `ardoise` (id) : ardoise du compte avec parrain / comptables
- `avatar` (id) : données d'un avatar et liste de ses contacts
- `invitgr` (id, ni) : invitation reçue par un avatar à devenir membre d'un groupe
- `contact` (id, ic) : données d'un contact d'un avatar    
- `rencontre` (prh) id : communication par A de son nom complet à un avatar B non connu de A dans l'application
- `parrain` (pph) id : parrainage par un avatar A de la création d'un nouveau compte
- `groupe` (id) : données du groupe et liste de ses avatars, invités ou ayant été pressentis, un jour à être membre.
- `membre` (id, im) : données d'un membre du groupe
- `secret` (id, ns) : données d'un secret d'un avatar ou groupe

## Singletons id / valeur
Ils sont identifiés par un numéro de singleton.  
- Leur valeur est un BLOB, qui peut être un JSON en UTF8.  
- Le singleton 0 est un JSON libre utilisé pour stocker l'état du serveur (dernière sauvegarde, etc.).  
- C'est la table `versions` qui les stocke.

## Table `versions` - CP : `id`

Au lieu d'un compteur par avatar / groupe / compte on a 100 compteurs, un compteur pour plusieurs avatars / groupe (le reste de la division de l'id par 99 + 1). Le compteur 0 est celui de la séquence universelle.

La colonne `v` est un array d'entiers.

>Le nombre de collisions n'est pas vraiment un problème : détecter des proximités entre avatars / groupes dans ce cas devient un exercice très incertain (fiabilité de 1 sur 99).

L'id 0 correspondant à l'état courant et l'id 1 à la dernière sauvegarde.

    CREATE TABLE "versions" (
    "id"  INTEGER,
    "v"  BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;

## Table : `compte` CP `id`. Authentification d'un compte
_Phrase secrète_ : une ligne 1 de 16 caractères au moins et une ligne 2 de 16 caractères au moins.  
`pcb` : PBKFD de la phrase complète (clé X) - 32 bytes.  
`dpbh` : hashBin (53 bits) du PBKFD du début de la phrase secrète (32 bytes).

Table :

    CREATE TABLE "compte" (
    "id"	INTEGER,
    "v"		INTEGER,
    "dpbh"	INTEGER,
    "pcbh"	INTEGER,
    "kx"   BLOB,
    "cpriv" BLOB,
    "mack"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE UNIQUE INDEX "dpbh_compte" ON "compte" ( "dpbh" );

- `id` : id du compte.
- `v` :
- `dpbh` : hashBin (53 bits) du PBKFD du début de la phrase secrète (32 bytes). Pour la connexion, l'id du compte n'étant pas connu de l'utilisateur.
- `pcbh` : hashBin (53 bits) du PBKFD de la phrase complète pour quasi-authentifier une connexion avant un éventuel échec de décryptage de `kx`.
- `cpriv` : clé asymétrique privée du compte (pour gérer les rencontres entre comptes). La clé publique est dans la table `avrsa`.
- `kx` : clé K du compte, crypté par la X (phrase secrète courante).
- `mack` {} : map des avatars du compte cryptée par la clé K. Clé: id, valeur: `[nom, rnd, cpriv]`
  - `nom rnd` : nom complet.
  - `cpriv` : clé privée asymétrique.
première ligne s'affiche en haut de l'écran.
- `vsh`

**Remarques :** 
- un row `compte` ne peut être modifié que par une transaction du compte (mais peut être purgé par le traitement journalier de détection des disparus).
- il est synchronisé lorsqu'il y a plusieurs sessions ouvertes en parallèle sur le même compte depuis plusieurs sessions de browsers.
- chaque mise à jour vérifie que `v` actuellement en base est bien celle à partir de laquelle l'édition a été faite pour éviter les mises à jour parallèles intempestives.
- le row `compte` change très rarement : à l'occasion de l'ajout / suppression d'un avatar et d'un changement de phrase secrète.

## Table : `prefs` CP `id`. Préférences et données d'un compte
Afin que le row compte qui donne la liste des avatars ne soit mis à jour que rarement, les données et préférences associées au compte sont mémorisées dans une autre table :
- chaque type de données porte un code court :
  - `mp` : mémo personnel du titulaire du compte.
  - `mc` : mots clés du compte.
  - ... `fs` : filtres des secrets (par exemple).
- le row est juste un couple `[id, map]` où map est la sérialisation d'une map ayant :
  - une entrée pour chacun des codes courts ci-dessus : la map est donc extensible sans modification du serveur.
  - pour valeur la sérialisation cryptée par la clé K du compte de l'objet Javascript en donnant le contenu.
- le row est chargé lors de l'identification du compte, conjointement avec le row compte.
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
- `vsh`

## Table `compta` : CP `id`. Ligne comptable d'un compte
Il y a une ligne par compte, l'id étant l'id du compte. `idp` est l'id du parrain pour un filleul : un parrain a donc `null` dans cette colonne.

Table :

    CREATE TABLE "compta" (
    "id"	INTEGER,
    "idp"	INTEGER,
    "v"	INTEGER,
    "dds"	INTEGER,
    "st"	INTEGER,
    "dst" INTEGER,
    "data"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "idp_compta" ON "compta" ( "idp" );
    CREATE INDEX "dds_compta" ON "compta" ( "dds" );
    CREATE INDEX "st_compta" ON "compta" ( "st" ) WHERE "st" > 0;

- `id` : du compte.
- `idp` : pour un filleul, id du parrain (null pour un parrain).
- `v` :
- `dds` : date de dernière signature du compte (dernière connexion). Un compte en sursis ou bloqué ne signe plus, sa disparition physique est déjà programmée.
- `st` :
  - 0 : normal.
  - 1 : en sursis 1.
  - 2 : en sursis 2.
  - 3 : bloqué.
- `dst` : date du dernier changement de st.
- `data`: compteurs sérialisés (non cryptés)
- `vsh` :

**data**
- `j` : jour de calcul
- `v1 v1m` : volume v1 actuel et total du mois
- `v2 v2m` : volume v2 actuel et total du mois
- `f1 f2` : forfait de v1 et v2
- `tr` : array de 31 compteurs (les 31 derniers jours) : cumul journalier du volume de transfert de pièces jointes.
- `hist` : array de 12 éléments, un par mois. 4 bytes par éléments.
  - `f1 f2` : forfaits du mois
  - `r1` : ratio du v1 du mois par rapport à son forfait.
  - `r2` : ratio du v2 du mois par rapport à son forfait.
- `res1 res2` : pour un parrain, réserve de forfaits v1 et v2.
- `t1 t2` : pour un parrain, total des forfaits 1 et 2 attribués aux filleuls.

#### Unités de volume
- pour v1 : 1 MB
- pour v2 : 100 MB

Les forfaits, pour les comptes, pour les groupes, pour la réserve, peuvent être donnés en nombre d'unités ci-dessus.

Les forfaits typiques s'étagent de 1 à 64 : (coût mensuel)
- (1) - XXS - 1 MB / 100 MB - 0,35c
- (2) - XS - 2 MB / 200 MB - 0,70c
- (4) - SM - 4 MB / 400 MB - 1,40c
- (8) - MD - 8 MB / 800 MB - 2,80c
- (16) - LG - 16 MB / 1,6GB - 5,60c
- (32) - XL - 32 MB / 3,2GB - 1,12€
- (64) - XXL - 64 MB / 6,4GB - 2,24€

Les codes _numériques_ des forfaits tiennent sur 1 octet : c'est le facteur multiplicateur du forfait le plus petit (1MB / 100MB). Des codes symboliques peuvent être ajoutés, voire modifiés, sans affecter les données.

Les _ratios_ sont exprimés en pourcentage de 1 à 255% : mais 1 est le minimum (< 1 fait 1) et 255 le maximum.

## Table `ardoise` : CP `id`. Ardoise supportant les échanges d'administration d'un compte
Il y a une ardoise par compte, l'id étant l'id du compte.

Table :

    CREATE TABLE "ardoise" (
    "id"	INTEGER,
    "v"  INTEGER,
    "dhl"  INTEGER,
    "mcp"	TEXT,
    "mcc"	TEXT,
    "data"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_mcp_ardoise" ON "ardoise" ( "id", "mcp" ) WHERE mcp NOTNULL;
    CREATE INDEX "v_mcc_ardoise" ON "ardoise" ( "v", "mcc" ) WHERE mcc NOTNULL;

- `id` : du compte.
- `v` : date-heure d'insertion du dernier échange
- `dhl` : date-heure de dernière lecture par le titulaire
- `mcp` : mots clés du parrain - String de la forme `245/232/114/`
- `mcc` : mots clés du comptable
- `data`: contenu sérialisé _crypté soft_ de l'ardoise. Array des échanges :
  - `dh` : date-heure d'écriture de l'échange
  - `aut`: auteur : 0:titulaire du compte, 1:parrain du compte, 2:comptable
  - `texte`: texte
- `vsh`:

**Sélections pour un parrain :**
- ardoises des filleuls (par `compta`) dont mcp contient nnn/

**Sélections pour un comptable :**
- ardoises dont les dh sont comprises entre d1 et d2 et dont mcc contient nnn/

**Opérations :**
- insertion d'un échange. dh est mis à jour
  - par le titulaire : insère 255/ (nouveau) dans mcp et mcc 
  - par le parrain : insère 255/ (nouveau) dans mcc
  - par le comptable : insère 255/ (nouveau) dans mcp
- lecture par le titulaire : change dhl
- par un parrain / comptable : mots-clés dans mcp / mcc

Une ardoise conserve,
- tous les échanges de moins de 90 jours,
- au moins les 10 derniers quels qu'en soit la date.

## Table `avrsa` : CP `id`. Clé publique RSA des avatars
Cette table donne la clé RSA (publique) obtenue à la création de l'avatar : elle permet d'inviter un avatar à être contact fort ou à devenir membre d'un groupe.

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

### Table `avatar` : CP `id`. Données d'un avatar
Chaque avatar a un row dans cette table :
- donne son statut de disparition,
- sa dernière signature de connexion,
- sa carte de visite,
- la liste de ses groupes (avec leur nom et clé).

**Un avatar supprimé logiquement** n'a plus que les colonnes:
- `id`
- `v`
- `vsv`
- `st` (négatif) ; ces quatre colonnes sont immuables.
- `cva` (la carte de visite) et les autres colonnes sont `null`.

Table :

    CREATE TABLE "avatar" (
    "id"   INTEGER,
    "v"  	INTEGER,
    "st"  INTEGER,
    "vcv" INTEGER,
    "dds" INTEGER,
    "mxic"  INTEGER,
    "cva"	BLOB,
    "lgrk" BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_v_avatar" ON "avatar" ( "id", "v" );
    CREATE INDEX "dds_avatar" ON "avatar" ( "dds" );
    CREATE INDEX "id_vcv_avatar" ON "avatar" ( "id", "vcv");
    CREATE INDEX "st_avatar" ON "avatar" ( "st" ) WHERE "st" < 0;

- `id` : id de l'avatar
- `v` :
- `st` : négatif : l'avatar est supprimé / disparu (les autres colonnes sont à null). 
- `vcv` : version de la carte de visite (séquence 0).
- `dds` :
- `mxic` : indice du dernier contact (attribution en séquence croissante).
- `cva` : carte de visite de l'avatar cryptée par la clé de l'avatar `[photo, info]`.
- `lgrk` : map :
  - _clé_ : `ni`, numéro d'invitation (aléatoire 4 bytes) obtenue sur `invitgr`.
  - _valeur_ : cryptée par la clé K du compte de `[nom, rnd, im]` reçu sur `invitgr`.
  - une entrée est effacée par la résiliation du membre au groupe ou sur refus de l'invitation (ce qui lui empêche de continuer à utiliser la clé du groupe).
- `vsh`

La lecture de `avatar` permet d'obtenir la liste des groupes dont il est membre.

Sur GC quotidien sur `dds` : 
- mise à jour du statut `st` : jour (en négatif) de sa disparition logique.
- purge / suppression des rows `contact secret parrain rencontre avrsa` pour les disparus.

### Table `contact` : CP `id ic`. Contact d'un avatar A
Un contact entre A et B est créé par exemple à l'initiative de A et a deux exemplaires : l'un dont l'id est celle de A, l'autre dont l'id est celle de B :
- `ic` de `C[a]`, l'indice du contact B chez A.
- `ic` de `C[b]`, l'indice du contact de A chez B.

L'opération de création vérifie que le contact C[b] n'existe pas afin de se prémunir contre une création parallèle de deux sessions du compte A. 
- les ic respectifs sont égaux aux mxic + 1 des deux avatars.
- la clé `cc` du couple est tirée au hasard.
- deux contacts `C[a]` et `C[b]` sont créés :
  - dans `C[b]` `data` contient :
    - le `nom rnd` de A,
    - la clé `cc`,
    - l'indice `ic` du contact chez A qui permet donc à B d'accéder au contact `C[a]`
    - `data` est crypté par la **clé publique de B**.
    - `mc` contient une seule valeur 255 qui signifie *nouveau*.
  - dans `C[a]` `data` contient :]
    - le `nom rnd` de B,
    - la clé `cc`,
    - l'indice `ic` du contact chez B qui permet à A d'accéder au contact `C[b]`
    - `data` est crypté par la **clé K du compte de A**.

Juste avant d'émettre une opération de création, la session du compte de A vérifie qu'il n'existe aucun contact C dont le `data.[nom rnd]` correspond à l'id de B : en effet B *pourrait* avoir devancé de peu A et créé le contact qui est parvenu par synchronisation à A pendant le processus de création.

Quand une session de B obtient par chargement initial ou synchronisation le *nouveau* contact `C[b]` elle poste immédiatement une opération `regulCT` qui remplace le `datap` par le même contenu crypté par sa clé K `datak`, `datap` passant à null.
- `datap / datak` sont immuables après création, de même que l'identifiant `id ic`.
- en session et en base locale, `datap` n'existe jamais et `datak` est décryptée en `data`.


**Statuts réciproques x/y**
- le statut `xy` de C[a] est égal au statut `yx` de C[b]
- `x` prend 3 valeurs (par exemple pour C[a]):
  0: A n'accepte pas le partage de secrets avec B.
  1: A accepte le partage de secrets avec B.
  2: A a disparu. Ce statut ne peut apparaître qu'en position `y` (l'avatar disparu n'ayant plus de contacts).

Tant que A et B n'ont pas disparu, un contact reste éternel, mais A par exemple :
- peut arrêter d'accepter de partager des secrets (voir n'avoir jamais accepté),
- peut ne pas lire l'ardoise commune,
- peut mettre sur le contact un mot clé *liste noire* qui fait que le contact avec B n'apparaîtra plus dans ses listes à l'écran (jusqu'à levée éventuelle de ce mot clé). 

> La clé `cc` relative à un couple A/B ne doit jamais disparaître avant que A et B n'aient disparu : elle crypte leurs secrets partagés.

Un contact permet de partager par **l'ardoise** un court texte entre A et B pour justifier d'un changement de statut ou n'importe quoi d'autre : en particulier quand A n'accepte pas / plus le partage de secrets avec B par exemple, c'est le seul moyen pour passer une courte information mutuelle qui n'encombre pas leurs volumes respectifs.

Table :

    CREATE TABLE "contact" (
    "id"   INTEGER,
    "ic"	INTEGER,
    "v"  	INTEGER,
    "st" INTEGER,
    "nccc"	BLOB,
    "ardc"	BLOB,
    "datap"  BLOB
    "datak"	BLOB,
    "mc"  BLOB,
    "infok"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id", "ic"));
    CREATE INDEX "id_v_contact" ON "contact" ( "id", "v" );
    CREATE INDEX "st_contact" ON "contact" ( "st" ) WHERE "st" < 0;

- `id` : id de l'avatar A
- `ic` : indice de contact de B pour A.
- `v` :
- `st` : statut entier de 2 chiffres, `xy` : `xy` dans le contact de A est `yx` dans le contact de B.
  - `x` : `x` c'est LE COMPTE, `y` c'est l'autre (le contact).
    - 0 : n'accepte pas le partage de secrets.
    - 1 : accepte le partage de secrets.
    - 2 : présumé disparu
- `nccc` : numéro de compte de l'avatar contact **si le contact accepte le partage de secrets** (y vaut 1, redondance assumée), crypté par la clé `cc`. 
- `ardc` : **ardoise** partagée entre A et B cryptée par la clé `cc` associée au contact _fort_ avec un avatar B. Couple `[dh, texte]`.
- `datak` : information cryptée par la clé K de A.
  - `nom rnd ic` : nom complet du contact (B) et son indice chez lui.
  - `cc` : 32 bytes aléatoires donnant la clé `cc` d'un contact avec B.
  - `idcf` : si ce contact est un avatar d'un compte filleul, `id` du compte filleul.
- `datap` : mêmes données que `datak` mais cryptées par la clé publique de A.
- `mc` : mots clés à propos du contact.
- `infok` : commentaire à propos du contact crypté par la clé K du membre.
- `vsh`

Un contact est **purgé** quand son avatar est supprimé logiquement.

### Table `parrain` : CP `pph`. Parrainage par P de la création d'un compte F 

F est un *inconnu* n'ayant pas encore de compte.

Comme il va y avoir un don de forfaits du *parrain* vers son *filleul*, ces deux-là vont être contact. Toutefois,
- P peut indiquer que son contact est sans partage de secrets.
- F pourra indiquer que son contact est sans partage de secrets.

Le parrain fixe l'avatar filleul (donc son nom). Le filleul établira le contact lors de son acceptation du parrainage.

Un parrainage est identifié par le hash du PBKFD de la phrase de parrainage pour être retrouvée par le filleul.

    CREATE TABLE "parrain" (
    "pph"  INTEGER,
    "id" INTEGER,
    "v"   INTEGER,
    "dlv"  INTEGER,
    "st"  INTEGER,
    "f1" INTEGER,
    "f2" INTEGER,
    "datak"  BLOB,
    "datax"  BLOB,
    "data2k"  BLOB,
    "ardc"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("pph")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_parrain" ON "parrain" ( "dlv" );
    CREATE INDEX "id_parrain" ON "parrain" ( "id" );

- `pph` : hash du PBKFD de la phrase de parrainage.
- `id` : id du parrain.
- `v`
- `dlv` : la date limite de validité permettant de purger les parrainages (quels qu'en soient les statuts).
- `st` : < 0: supprimé,
  - 0: en attente de décision de F
  - 1 : refusé
  - 2 : accepté avec partage
  - 3 : accepté sans partage
  - 4 : remord du parrain, le parrainage est suspendu.
- `datak` : cryptée par la clé K du parrain, **phrase de parrainage et clé X** (PBKFD de la phrase). La clé X figure afin de ne pas avoir à recalculer un PBKFD en session du parrain pour qu'il puisse afficher `datax`.
- `datax` : données de l'invitation cryptées par le PBKFD de la phrase de parrainage.
  - `idcp` : id du compte parrain.
  - `idcf` : id du compte filleul.
  - `nomp, rndp` : nom complet de l'avatar P.
  - `nomf, rndf` : nom complet du filleul F.
  - `cc` : clé `cc` générée par P pour le couple P / F.
  - `aps` : `true` si le parrain accepte le partage de secrets.
  - `f: [f1 f2]` : forfaits attribués par P à F.
  - `r: [r1 r2]` : si non null, réserve attribuable aux filleuls si le compte _parrainé_ est en fait un _parrain_ lui-même.
- `data2k` : c'est le `datak` du futur contact créé en cas d'acceptation.
  - `nom rnd` : nom complet du contact (B).
  - `cc` : 32 bytes aléatoires donnant la clé `cc` d'un contact avec B (en attente ou accepté).
  - `icb` : indice de A dans les contacts de B : toujours 1, le parrain est par principe toujours le premier contact du filleul.
  - `idcf` : id du compte filleul.
- `ardc` : ardoise (couple `[dh, texte]` cryptée par la clé `cc`).
  - du parrain, mot de bienvenue écrit par le parrain (cryptée par la clé `cc`).
  - du filleul, explication du refus par le filleul (cryptée par la clé `cc`) quand il décline l'offre. Quand il accepte, ceci est inscrit sur l'ardoise de leur contact afin de ne pas disparaître.
- `vsh`

**Les forfaits sont prélevés sur la réserve du parrain lors de l'acceptation.** 

**Si le filleul ne fait rien à temps : (`st` toujours à 0)** 
- Lors du GC sur la `dlv`, le row `parrain` sera supprimé par GC de la `dlv`. 

**Si le filleul refuse le parrainage :** 
- L'ardoise contient une justification / remerciement du refus.
- Le row `parrain` sera supprimé à l'expiration de la `dlv`. 

**Le parrain peut annuler son row avant acceptation / refus :** 
- son `st` passe à 4.

**Le parrain peut prolonger la date-limite d'un parrainage** (encore en attente), sa `dlv` est augmentée.

**Si le filleul accepte le parrainage :** 
- Le filleul crée son compte et son premier avatar (dont il a reçu `nom rnd`).
- sa ligne `compta` est créée et crédités des forfaits attribués par le parrain.
- la ligne `compta` du parrain est mise à jour (total des forfaits et réserve).
- sa ligne `ardoise` est créée vide.
- il créé un double contact C[p] et C[f] avec P.
  - dans `C[p]` le `datak` est le `data2k` transmis dans le row `parrain` : ce contact est déjà _régularisé_ dès sa création.
  - dans `C[f]` le `datak` est créé à partir des données contenues dans le `datax` du row `parrain`: l'indice ic chez le parrain est obtenu depuis le `mxic` de l'avatar parrain.
- l'ardoise des `contact` de P et de F contient l'ardoise de l'acceptation (`ardc`).
- Le row `parrain` a son `st` à 2 ou 3 et sera supprimé à l'expiration de la `dlv`. 

Dans tous les cas le GC sur `dlv` supprime le row `parrain`.

## Table `rencontre` : CP `prh`. Rencontre entre les avatars A et B
A et B se sont rencontrés dans la *vraie* vie mais ni l'un ni l'autre n'a les coordonnées de l'autre pour,
- soit s'inviter à créer un contact,
- soit pour B inviter A à participer à un groupe.

Une rencontre est juste un row qui va permettre à A de transmettre à B son `nom rnd` en utilisant une phrase de rencontre convenue entre eux.  
En accédant à cette rencontre B pourra inscrire A comme contact personnel ou d'un groupe.

Une rencontre est identifiée par `prh` le hash de la **clé X (PBKFD de la phrase de rencontre)**.

    CREATE TABLE "rencontre" (
    "prh" INTEGER,
    "id" INTEGER,
    "v"   INTEGER,
    "dlv" INTEGER,
    "st"  INTEGER,
    "datak" BLOB,
    "nomax" BLOB,
    "nombx" BLOB,
    "ardx"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("prh")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_rencontre" ON "rencontre" ( "dlv" );
    CREATE INDEX "id_v_rencontre" ON "rencontre" ( "id", "v" );

- `prh` : hash du PBKFD de la phrase de rencontre.
- `id` : id de l'avatar A ayant initié la rencontre.
- `v` :
- `dlv` : date limite de validité permettant de purger les rencontres.
- `st` : 0:en attente. 1: annulée
- `datak` : **phrase de rencontre et son PBKFD** (clé X) cryptée par la clé K du compte A pour que A puisse retrouver les rencontres qu'il a initiées avec leur phrase.
- `nomax` : nom complet `[nom, rnd]` de A crypté par la clé X.
- `nombx` : nom complet de B nom rnd quand B a lu la rencontre.
- `ardx` : ardoise de A (mot de bienvenue). Couple `[dh, texte]` crypté par la clé X.
- `vsh`

Quand B *ouvre* la rencontre, il laisse son `nom rnd` dans cette rencontre : A comme B peuvent décider ensuite de créer un contact.

Le GC sur `dlv` purge le row `rencontre`.

A peut annuler la rencontre (remord), `st` passe à 1.

## Table `groupe` : CP: `id`. Entête et état d'un groupe
Un groupe est caractérisé par :
- son entête : un row de `groupe`.
- la liste de ses membres : des rows de `membre`.
- la liste de ses secrets : des rows de `secret`.

Un groupe est hébergé par un compte _hébergeur_ (ses volumes sont décomptés sur ce compte). L'hébergement est noté par :
- `idhg` : l'id du compte hébergeur crypté par la clé G du groupe (cryptage non identifiant, son _salt_ est aléatoire).
- `imh` : l'indice de l'avatar du compte hébergeur qui a créé le groupe et en a été le premier animateur.
- `dfh`, la date de fin d'hébergement, qui vaut 0.

Le compte peut mettre fin à son hébergement:
- `dfh` indique le jour de la fin d'hébergement : `idhg` est null, `imh` est 0.
- les secrets ne peuvent plus être mis à jour ou créés (comme un état archivé).
- le groupe sera détruit par le GC quotidien N1 jours après `dfh`.

Au login les comptes signent dans `dds` le fait qu'ils accèdent au groupe. Toutefois ils ne signent plus si a été mis _en sursis_ par un comptable.
- le groupe sera détruit par le GC quotidien N2 jours après `dds`.

La **suppression (logique)** d'un groupe consiste à ne laisser que les propriétés suivantes :
- `id`
- `v`
- `st` : contient en négatif le jour de suppression.
- toutes les autres sont null
- le row est désormais immuable (`v` ne changera plus).
- tous les row secret et membre ayant pour id le groupe supprimé sont physiquement supprimés à la suppression logique du groupe

La **purge physique** d'un row supprimé logiquement intervient N2 jours après st (jour de suppression logique).

Tous les rows avatars qui le référencent dans `lgrk` seront mis à jour (opération `regulAv`), 
- soit suite à une synchro,
- soit au prochain login,
- les entrées dans `lgrk` correspondant au groupe supprimé seront détruites.

**Les membres d'un groupe** reçoivent lors de leur création (opération de création d'un contact d'un groupe) un indice membre im :
- cet indice est attribué en séquence : le premier membre est celui du créateur du groupe a pour indice 1 (il est animateur et hébergeur).
- les rows membres ne sont jamais supprimés, sauf par purge physique à la suppression logique de leur groupe.

Table :

    CREATE TABLE "groupe" (
    "id"  INTEGER,
    "v"   INTEGER,
    "dds" INTEGER,
    "dfh" INTEGER,
    "st"  INTEGER,
    "mxim"  INTEGER,
    "cvg"  BLOB,
    "idhg"  BLOB,
    "imh"  INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "f1"  INTEGER,
    "f2"  INTEGER,
    "mcg"   BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "dds_groupe" ON "groupe" ( "dds" );
    CREATE INDEX "dfh_groupe" ON "groupe" ( "dfh" ) WHERE "dfh" > 0;
    CREATE INDEX "id_v_groupe" ON "groupe" ( "id", "v" );
    CREATE INDEX "st_groupe" ON "groupe" ( "st" ) WHERE "st" < 0;

- `id` : id du groupe.
- `v` :
- `dds` :
- `dfh` : date (jour) de fin d'hébergement du groupe par son hébergeur
- `st` : statut
  - _négatif_ : le groupe est supprimé logiquement (c'est le numéro du jour de sa suppression).
  - _positif_ `x y`
    - `x` : 1-ouvert (accepte de nouveaux membres), 2-fermé (ré-ouverture en vote)
    - `y` : 0-en écriture, 1-protégé contre la mise à jour, création, suppression de secrets.
- `cvg` : carte de visite du groupe `[photo, info]` cryptée par la clé G du groupe.
- `idhg` : id du compte hébergeur crypté par la clé G du groupe.
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `v1 v2` : volumes courants des secrets du groupe.
- `f1 f2` : forfaits attribués par le compte hébergeur.
- `mcg` : liste des mots clés définis pour le groupe cryptée par la clé du groupe cryptée par la clé G du groupe.
- `vsh`

## Table `membre` : CP `id nm`. Membre d'un groupe
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
    CREATE INDEX "st_membre" ON "membre" ( "st" ) WHERE "st" < 0;

- `id` : id du **groupe**.
- `im` : indice du membre dans le groupe.
- `v` :
- `st` : `x p`
  - `x` : 0:contact, 1:invité, 2:actif (invitation acceptée), 3: inactif (invitation refusée), 4: inactif (résilié), 5: inactif (disparu).
  - `p` : 0:lecteur, 1:auteur, 2:animateur.
- `vote` : vote de réouverture.
- `mc` : mots clés du membre à propos du groupe.
- `infok` : commentaire du membre à propos du groupe crypté par la clé K du membre.
- `datag` : données cryptées par la clé du groupe. (immuable)
  - `nom, rnd` : nom complet de l'avatar.
  - `ni` : numéro d'invitation du membre dans `invitgr`. Permet de supprimer l'invitation et d'effacer le groupe dans son avatar (clé de `lgrk`).
	- `idi` : id du membre qui l'a inscrit en contact.
- `ardg` : ardoise du membre vis à vis du groupe. Couple `[dh, texte]` crypté par la clé du groupe. Contient le texte d'invitation puis la réponse de l'invité cryptée par la clé du groupe. Ensuite l'ardoise peut être écrite par le membre (actif) et les animateurs.
- `vsh`

**Remarques**
- un membre _contact_ a un row `membre` de statut x `0`: (l'avatar contact ne le sait pas, n'a pas le groupe dans sa liste des groupes). Tous les membres commencent leur cycle de vie en tant que _contact_.
- un membre _invité_ a un row `membre` de statut x `1`: l'avatar a le groupe dans sa liste des groupes, il peut répondre à l'invitation, accepter ou refuser et motiver sa réponse dans son ardoise..
- quand un membre `invité` accepte son statut passe à `2`.
- les membres de statut _invité_ et _actif_ peuvent accéder à la liste des membres et à leur _ardoise_ : ils ont la clé du groupe dans leur row `avatar`.
- les membres _actif_ accèdent aux secrets. En terme de cryptographie, les membres invités _pourraient_ aussi en lecture (ils ont reçu la clé dans l'invitation) mais le serveur l'interdit.
- les membres des statuts _contact, ayant refusé, résilié, disparu_ n'ont pas / plus la clé du groupe dans leur row `avatar` (`lgrk`). `infok` est null.
- un membre résilié peut être réinvité, le numéro d'invitation `ni` est réutilisé.

Les animateurs peuvent :
- inviter d'autres avatars à rejoindre la liste.
- changer les statuts des membres non animateurs, en particulier les résilier.

Le row `membre` d'un membre subsiste quand il est _résilié_ ou _disparu_ pour information historique du groupe: sa carte de visite reste accessible quand il est _résilié_.

## Table `invitgr`. Invitation d'un avatar M par un animateur A à un groupe G
Un avatar A connaît la liste des groupes dont il est membre par son row `avatar` qui reprend les identités des groupes cryptées par la clé K du compte.

Une invitation est un row qui **notifie** une session de A qu'il a été inscrit comme membre invité d'un groupe :
- elle porte l'id de l'invité.
- elle porte un numéro d'invitation aléatoire qui permettra aux animateurs du groupe de *résilier* l'accès de A au groupe en détruisant la référence au groupe dans le row avatar de A.
- elle porte le couple `nom rnd` identifiant le groupe et sa clé crypté par la clé publique de l'avatar.

Dans une session de A dès que cette invitation parvient, soit par synchronisation, soit au chargement initial, la session poste une opération `regulGr` qui va inscrire dans le row avatar de A le nouveau groupe `nom rnd im` mais crypté par la clé K du compte de A. Ceci détruit l'invitation devenu inutile.

    CREATE TABLE "invitgr" (
    "id"  INTEGER,
    "ni" INTEGER,
    "datap" BLOB,
    PRIMARY KEY ("id", "ni"));

- `id` : id du membre invité.
- `ni` : numéro d'invitation.
- `datap` : crypté par la clé publique du membre invité.
	- `[nom, rnd, im]` : nom complet du groupe (donne sa clé) + indice de l'invité dans le groupe.

## Secrets
Un secret est identifié par:
- `id` : l'id du propriétaire (avatar ou groupe),
- `ns` : numéro complémentaire aléatoire: 
 - multiple de 3 pour un secret personnel.
 - multiple de 3 + 1 pour un secret de couple.
 - multiple de 3 + 2 pour un secret de groupe.

La clé de cryptage du secret `cles` est selon le cas :
- (0) *secret personnel d'un avatar A* : la clé K de l'avatar. `ic` vaut 0.
- (1) *secret d'un couple d'avatars A et B* : leur clé `cc` de contact mutuel. `ic` donne l'indice du contact ce qui permet d'obtenir `cc` dans la donnée de `contact`.
- (2) *secret d'un groupe G* : la clé du groupe G. `ic` vaut 0.

**Un secret de couple A / B est matérialisé par 2 secrets de même contenu**
- un pour A et un pour B (et la même clé de cryptage, celle `cc` du couple). 
- chaque secret dans ce cas détient la référence de l'autre afin que la mise à jour de l'un puisse être répercutée sur l'autre (quand il existe encore).
- A et B peuvent indépendamment l'un de l'autre détruire leur exemplaire : de facto il n'y a plus de copie synchronisée de l'autre.
- A crée les deux exemplaires du secret en générant deux numéros `ns` afin que la relation entre A et B n'apparaisse pas dans la base.

### Un secret a toujours un texte et possiblement une pièce jointe
Le texte a une longueur maximale de 4000 caractères. L'aperçu d'un secret est constituée des N3 premiers caractères de son texte ou moins (première ligne au plus).
- le texte est stocké gzippé au delà d'une certaine taille.

**La liste des auteurs d'un secret donne les derniers auteurs:**
- dans l'ordre de modification, le plus récent en tête,
- sans doublon.

### Pièces jointes
Un secret _peut_ avoir plusieurs pièces jointes, chacune identifiée par : `nom.ext|type|dh`.
- le `nom.ext` d'une pièce jointe est un _nom de fichier_, d'où un certain nombre de caractères interdits (dont le `/`). Pour un secret donné, ce nom est identifiant.
- `type` est le MIME type du fichier d'origine.
- `dh` est la date-heure d'enregistrement de la pièce jointe (pas de la création ou dernière modification de son fichier d'origine).
- un signe `$` à la fin indique que le contenu est gzippé en stockage.
- le volume de la pièce jointe est le volume NON gzippé. Seuls les fichiers de types `text/...` sont gzippés.

Une pièce jointe d'un nom donné peut être mise à jour / remplacée : le nouveau texte peut avoir un type différent et aura par principe une date-heure différente.

> **Le contenu d'une pièce jointe sur stockage externe est crypté par la clé du secret.**

### Mise à jour d'un secret
Le droit de mise à jour d'un secret est contrôlé par le couple `xxxp` :
- `xxx` indique quel avatar a l'exclusivité d'écriture et le droit de basculer la protection :
  - pour un secret personnel, x est implicitement l'avatar détenteur du secret.
  - pour un secret de couple, 1 désigne celui des deux contacts du couple ayant l'id le plus bas, 2 désigne l'autre.
  - pour un secret de groupe, x est l'indice du membre.
- `p` indique si le texte est protégé contre l'écriture ou non.

Celui ayant l'exclusivité peut décider :
- de protéger le secret contre l'écriture (se l'interdire à lui-même),
- de lever cette protection (se l'autoriser à lui-même),
- de transférer l'exclusivité à un autre membre,
- de supprimer l'exclusivité.

Un animateur a ces mêmes droits.

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
- **un secret de référence n'a pas lui-même de référence** : ce sont ses voisins qui le référenceront.
- si B est un secret voisin de A (référençant A), on peut créer C voisin de B mais en fait C portera la référence de A (pas de B).
- rien n'empêche ainsi indirectement de rajouter des voisins à un secret disparu.
- un avatar peut ainsi avoir des secrets voisins d'un secret de référence auquel il ne peut pas accéder (et qui peut-être n'existe plus), la grande famille des voisins peut ainsi s'étendre loin. 

## Table `secret` : CP `id ns`. Secret

    CREATE TABLE "secret" (
    "id"  INTEGER,
    "ns"  INTEGER,
    "ic"  INTEGER,
    "v" INTEGER,
    "st"  INTEGER,
    "ora" INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "mc"   BLOB,
    "txts"  BLOB,
    "mpjs"  BLOB,
    "dups"  BLOB,
    "refs"  BLOB,
    "vsh" INTEGER,
    PRIMARY KEY("id", "ns");
    CREATE INDEX "id_v_secret" ON "secret" ("id", "v");
    CREATE INDEX "st_secret" ON "secret" ( "st" ) WHERE "st" < 0;

- `id` : id du groupe ou de l'avatar.
- `ns` : numéro du secret.
- `ic` : indice du contact pour un secret de couple, sinon 0.
- `v` :
- `st` :
  - < 0 pour un secret _supprimé_.
  - `99999` pour un *permanent*.
  - `dlv` pour un _temporaire_.
- `ora` : _xxxxxp_ (`p` reste de la division par 10)
   - `xxxxx` : exclusivité : l'écriture et la gestion de la protection d'écriture sont restreintes au membre du groupe dont `im` est `x` (un animateur a toujours le droit de gestion de protection et de changement du `x`). Pour un secret de couple : 1 désigne celui des deux contacts du couple ayant l'id le plus bas, 2 désigne l'autre.
    - `p` : 0: pas protégé, 1: protégé en écriture.
- `v1` : volume du texte
- `v2` : volume total des pièces jointes
- `mc` : 
  - secret personnel ou de couple : vecteur des index de mots clés.
  - secret de groupe : map sérialisée,
    - _clé_ : `im` de l'auteur (0 pour les mots clés du groupe),
    - _valeur_ : vecteur des index des mots clés attribués par le membre.
- `txts` : crypté par la clé du secret.
  - `d` : date-heure de dernière modification du texte
  - `l` : liste des auteurs (pour un secret de couple ou de groupe).
  - `t` : texte gzippé ou non
- `mpjs` : sérialisation de la map des pièces jointes.
- `dups` : couple `[id, ns]` crypté par la clé du secret de l'autre exemplaire pour un secret de couple A/B.
- `refs` : couple `[id, ns]` crypté par la clé du secret référençant un autre secret (référence de voisinage qui par principe, lui, n'aura pas de `refs`).
- `vsh`

**Suppression d'un secret :**
`st` est mis en négatif : les sessions synchronisées suppriment d'elles-mêmes ces secrets en local avant `st` si elles elles se synchronise avant `st`, sinon ça sera fait à `st`.

**Map des pièces jointes :**
- _clé_ : hash (court) de `nom.ext` en base64 URL. Permet d'effectuer des remplacements par une version ultérieure.
- _valeur_ : `[idc, taille]`
  - `idc` : id complète de la pièce jointe (`nom.ext|type|dh$`), cryptée par la clé du secret et en base64 URL.
  - `taille` : en bytes, avant gzip éventuel.

**Identifiant de stockage :** `org/sid@sns/cle@idc`  
- `org` : code de l'organisation.
- `sid` : id du secret en base64 URL. Pour un secret de couple `id ns` est par convention celui de l'id la plus faible du couple (la pièce jointe n'est pas dédoublée contrairement au secret lui-même).
- `sns` : ns du secret en base64 URL.
- `cle` : hash court en base64 URL de `nom.ext`
- `idc` : id complète de la pièce jointe, cryptée par la clé du secret et en base64 URL.

En imaginant un stockage sur file system, il y a un répertoire par secret : dans ce répertoire pour une valeur donnée de cle@ il n'y a qu'un fichier. Le suffixe `idc` permet de gérer les états intermédiaires lors d'un changement de version).

_Une nouvelle version_ d'une pièce jointe est stockée sur support externe **avant** d'être enregistrée dans son secret.
- _l'ancienne version_ est supprimée du support externe **après** enregistrement dans le secret.
- les versions crées par anticipation et non validées dans un secret comme celles qui n'ont pas été supprimées après validation du secret, peuvent être retrouvées par un traitement périodique de purge qui peut s'exécuter en ignorant les noms et date-heures réelles des fichiers scannés.

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

### Présence des listes de mots clés
- sur un **contact** d'un avatar du compte : la liste est accompagnée d'un court texte de commentaire.
- sur **l'invitation** à un groupe d'un des avatars du compte : la liste est accompagnée d'un court texte de commentaire.
- sur un **secret**. La propriété mc contient un objet de structure différente selon le type de secret.

**Secret personnel**  
`mc` est un vecteur d'index de mots clés. Les index sont ceux du compte et de l'organisation.

**Secret de couple**
`mc` est le vecteur d'index de mots clés. Les index sont ceux du compte et de l'organisation.

**Secret de groupe**
`mc` est une map :
- _clé_ : im, indice du membre dans le groupe. Par convention 0 désigne le groupe lui-même.
- _valeur_ : vecteur d'index de secrets. Les index sont ceux personnels du membre, ceux du groupe, ceux de l'organisation.

A l'affichage un membre du groupe peut voir ce que chaque membre à indiquer comme mots clés. Mais, les index personnels des autres (de 1 à 99) étant ininterprétables ne sont pas affichés.

Pour utilisation pour filtrer une liste de secrets dans un groupe :
- si le compte a lui-même donné une liste de mots clés, c'est celle-ci qui est prise, sans considérer les mots clés du groupe.
- sinon ce sont les mots clés du groupe.
- ainsi le groupe peut avoir indiqué que le secret est _nouveau_ et _important_, mais si le compte A a indiqué que le secret est _lu_ et _sans intérêt_ c'est ceci qui sera utilisé pour filtrer les listes.

# Gestion des disparitions
Les ouvertures de session *signent* dans les tables `compta avatar groupe`, colonne `dds`, les rows relatifs aux compte, avatars du compte et groupes accédés par le compte.

Une disparition est détectée dès lors que le GC quotidien détecte des `dds` trop vieilles.

## Disparition des comptes
La détection par `dds` trop ancienne d'un **compte** détruit son row dans `compte compta prefs ardoise`.

Un compte est toujours détruit physiquement avant ses avatars puisqu'il apparaît plus ancien que ses avatars dans l'ordre des signatures.

Le compte n'étant plus accessible, ses avatars ne seront plus signés ni les groupes auxquels il accédait.

## Disparition des groupes
Par construction s'il avait existé encore un avatar dont l'accès au groupe n'est pas résilié, le groupe aurait été signé lors de la connexion du compte de cet avatar : un groupe de signature ancienne n'est donc par principe plus référencé.

La détection par `dds` trop ancienne d'un **groupe** détruit ses rows dans les tables `groupe membre secret`.

_Remarque_ : quand le dernier avatar ayant accès à un groupe _disparaît_, le groupe va finir par disparaître faute de ne plus être signé. Les données vont finir par être purgées, mais ça va prendre du temps. Avec la résiliation explicitement demandée (suppression du groupe), c'est différent : la purge des données ci-dessus peut être immédiate.

## Disparition des avatars
La détection s'effectue par le GC quotidien sur recherche des `dds` trop ancienne dans la table `avatar`.

Par principe un avatar est détecté disparu après la détection de la disparition de son compte. Il s'agit donc de purger les données.

### Purge des données identifiées par l'id de l'avatar
- destruction des rows les tables `avrsa avatar contact invitgr parrain rencontre secret`.

Dès cet instant le volume occupé est récupéré.

### Mise à jour des références chez les autres comptes
Un avatar _disparu_ D reste toutefois encore _référencé_ dans des rows :
- `parrain rencontre invitgr` : la date limite de validité a déjà résolu la question, les rows ont _déjà_ été détruits.
- `contact` : autres avatars l'ayant en contact.
- `membre` : groupes l'ayant pour membre.  

#### contacts
Quand une session d'un avatar A synchronise les cartes de visite elle a connaissance par la carte de visite de D que cet avatar a disparu : le row `contact` correspondant a son statut mis à jour (disparu). 

Il n'y a pas de raisons pour que les secrets partagés avec D (et dédoublés) disparaissent aussi.

Le row contact garde une trace historique mais sur demande du compte, un contact _disparu_ peut être _oublié_ :
- le row `contact` a un statut supprimé (`st` < 0).
- tous les `secret` de l'avatar portant ce numéro de contact sont détruits.

#### membres
Pour chaque groupe accédé par l'avatar :
- le row `membre` de D (s'il existe) a son statut mis à jour à _disparu_. 
- sur demande d'un compte animateur du groupe, le row pourrait être marqué _supprimé_ pour _nettoyer_ la liste des membres : mais des secrets du groupe peuvent continuer à référencer ce membre comme auteur. Ne pas nettoyer dans ce cas ?

Dans la session la carte de visite est supprimée, elle ne sera plus synchronisée.

Les références peuvent mettre longtemps a être mises à jour, tous les comptes référençant l'avatar D ayant à être ouverts (ou disparaissant eux-mêmes).

## Secrets de couple A / B
### A et B acceptent le partage de secrets
Les volumes sont décomptés sur A et sur sur B, pour v1 comme pour v2, justement parce qu'ils peuvent en toute indépendance détruire leur exemplaire.

On sait chez A que B a détruit son exemplaire (sur `ora` xx vaut 0, 1 ou 2. 3 signifiant exemplaire unique, donc exclusivité au restant.

Si B **détruit** son exemplaire :
- A continue à agir sur le sien comme il l'entend : il retrouve de facto une exclusivité qu'il n'avait peut-être pas. De toutes les façons B n'a plus de moyens de s'en plaindre, il a abandonné le secret.
- B récupère du volume v1 / v2.

### B n'accepte plus le partage de secrets
... mais ça _pourrait_ revenir.
- le secret est gelè, aucune mise à jour ni de texte ni de pièces jointes.
- changement d'exclusivité / protection impossible.
- seuls les mots-clés de chacun peuvent changer afin de pouvoir les filtrer en sélection.

Le secret ne redevient normal que si les A et B acceptent le partage de secrets.

## Echanges sur les ardoises des comptes

Un échange est identifié par :
- idt : le titulaire de l'ardoise,
- idp : son parrain au moment de l'écriture (s'il en avait un) - celui qui en a eu copie ou qui l'a écrit
- dh : sa date-heure d'écriture
- em: son auteur. 0:titulaire de l'ardoise, 1:parrain du compte, 2:comptable

Propriétés
- dhlt: dh de lecture par le titulaire : 0 quand c'est le titulaire qui est l'auteur
- dhlp: dh de lecture par le parrain : 0 quand idp est 0 (pas de parrain)
- dhlc: dh de lecture par comptable : 0 quand le comptable est l'auteur
- texte: son texte

L'inscription d'un échange d'une ardoise d'un compte ayant un parrain, est dupliquée sur l'ardoise du parrain;

Sur l'ardoise d'un compte ayant un parrain:
- tous les échanges ont pour idt le numéro de son compte : 0 pour simplifier.

Sur l'ardoise d'un parrain:
- les échanges ayant pour idt le numéro du compte sont ceux du compte : 0 pour simplifier.
- les échanges ayant pour idt nf, sont des copies d'échanges de l'ardoise du compte filleul nf (dont il était parrain à dh).

La lecture d'un message :
  - écrit par le titulaire
    - lecture par un compatble : notée sur l'ardoise du titulaire + l'ardoise de son parrain s'i le titulaire en avait un
    - lecture par le parrain: notée sur l'ardoise du titulaire + l'ardoise du parrain
  - écrit par le parrain
    - lecture par le titulaire : notée sur l'ardoise du titulaire + l'ardoise du parrain
    - lecture par un comptable : notée sur l'ardoise du titulaire + l'ardoise du parrain
  - écrit par un comptable
    - lecture par le titulaire : notée sur l'ardoise du titulaire + l'ardoise de son parrain s'i le titulaire en avait un
    - lecture par le parrain : notée sur l'ardoise du titulaire + l'ardoise du parrain

Quand un compte déclare avoir lu son ardoise :
- scan de tous les échanges non lus par lui et actions ci-dessus
- pour un _filleul_ deux ardoises (au moins) : la sienne et celle(s) de son(ses) parrain(s)
- pour un parrain : N ardoises. La sienne + toutes celles des filleuls dont il n'avait pas encore lu les échanges.
