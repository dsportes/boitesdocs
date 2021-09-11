# Boîtes à secrets - Modèle de données

## Identification des entités

Les clés AES et les PBKFD2 font 32 bytes (44 caractères en base64 url).

Le hash des string en *integer* est un entier sur 53 bits (intègre en Javascript):
- 15 chiffres décimaux.
- 9 caractères en base64 URL.

Le hash des string en *BigInt* est un 64 bits (sans signe, toujours positif) :
- 19 chiffres décimaux.
- 12 caractères en base64 URL.

Les date-heures sont exprimées en micro-secondes depuis le 1/1/1970, soit 52 bits (entier intègre en Javascript).

### Compte
- `id` : un entier issu de 5 bytes aléatoires.  
- `clé K` : SHA de id + 20 bytes aléatoires.  
- `pcb` : PBKFD2 de la phrase complète (clé X) - 32 bytes.  
- `dpbh` : hashBin (53 bits) du PBKFD2 du début de la phrase secrète (32 bytes).

**La phrase secrète d'un compte reste dans le cerveau du titulaire.**
- sa transformée par PBKFD2 dès la saisie donne une clé AES X qui ne sort jamais de la session cliente et n'est jamais stockée de manière permanente.

**La clé K d'un compte**,
- n'est stockée en session comme en serveur que sous forme cryptée par X.
- n'est jamais transmise au serveur en clair.
- les données cryptées par K, ne sont lisibles dans le serveur que quand elles ont été transmises aussi en clair dans une opération. 

### Avatar
L'id **complète** d'un avatar est le triplet immuable `[id + rnd, nom]`
- `id` : 5 bytes aléatoires (donnant un entier pair).
- `rnd` : 15 bytes aléatoires.
- `nom` : nom lisible et signifiant, entre 6 et 20 caractères.

La clé de cryptage de la carte de visite est le SHA de la `id + rnd`.

### Groupe
L'id **complète** d'un groupe est le triplet immuable `[id + rnd, nom]`
- `id` : 5 bytes aléatoires (donnant un entier impair pair).
- `rnd` : 15 bytes aléatoires.
- `nom` : nom lisible et signifiant du groupe, entre 6 et 20 caractères.

La clé de cryptage du groupe (ses données ...) et de sa carte de visite est le SHA de la `id + rnd`.

### Secret
- `id + ns` : entier de son propriétaire, et numéro de secret relatif à son propriétaire depuis 5 bytes aléatoires.

### Attributs génériques
- `v` : version, entier.
- `dds` : date de dernière signature, en nombre de jours depuis le 1/1/2021. Signale que ce jour-là, l'avatar, le compte, le groupe était *vivant / utile / référencé*. Pour éviter des rapprochements entre eux, la *vraie* date de signature peut être entre 0 et 30 jours *avant*.  Permet de distinguer des seuils d'alerte :
   - aucune : vivant encore récemment.
   - alerte : des mois sans signe de vie, sera considéré comme disparu dans les 2 mois qui suivent.
   - disparu
- `dlv` : date limite de validité, en nombre de jours depuis le 1/1/2021.

Les comptes sont censés avoir au maximum N semaines entre 2 connexions faute de quoi ils sont considérés comme disparus.

### Version des rows
Les rows des tables devant être présents sur les clients ont une version, de manière à pouvoir être chargés sur les postes clients de manière incrémentale : la version est donc croissante avec le temps et figure dans tous les rows de ces tables.  
- utiliser une date-heure présente l'inconvénient de laisser une meta-donnée intelligible en base ;
- utiliser un compteur universel a l'inconvénient de facilement deviner des liaisons entre objets : par exemple l'invitation à établir un contact entre A et B n'apparaît pas dans les rows eux-mêmes mais serait lisible si les rows avaient la même version. Crypter l'appartenance d'un avatar à un groupe alors qu'on peut la lire de facto dans les versions est un problème.
- utiliser un compteur par objet rend complexe la génération de SQL avec des filtres qui associent chaque objet à sa dernière version connue.

Tous les objets synchronisables (sauf les comptes) sont identifiés, au moins en majeur, par une id d'avatar ou de groupe. Par exemple l'obtention des contacts d'un avatar se fait par une sélection d'abord sur l'id de l'avatar, puis sur sa version pour ne récupérer incrémentalement que ceux changés / créés. D'où l'option de gérer une séquence de versions, pas forcément par id d'avatar, mais par hash de cet id.  

Toutefois la synchronisation des cartes de visite est différente puisqu'elle s'effectue non pas avatar par avatar (ou groupe par groupe) mais pour une liste (longue) d'avatars : le filtre sur la version est impraticable avec des avatars ayant une version prise dans des séquences différentes. D'où l'existence d'une _séquence universelle_ au moins pour les cartes de visites.

## Tables

- `versions` (id) : table des prochains numéros de versions (actuel et dernière sauvegarde)  
- `etat` (singleton) : état courant permanent du serveur  
- `avgrvq` (id) : volumes et quotas d'un avatar ou groupe  
- `avrsa` (ida) : clé publique d'un avatar  
- `parrain` (dpbh) : offre de parrainage d'un avatar A pour la création d'un compte inconnu (mais d'avatar connu) 

_**Tables aussi persistantes sur le client (IDB)**_

- `cvsg` (id) : carte de visite et signature d'un compte / avatar / groupe
- `compte` (idc) : authentification et données d'un compte
- `avidcc` (ida) : identifications et clés c1 des contacts d'un avatar  
- `avcontact` (ida, nc) : données d'un contact d'un avatar    
- `avinvitct` () (idb) : invitation adressée à B à lier un contact fort avec A  
- `avinvitgr` () (idm) : invitation à M à devenir membre d'un groupe G
- `rencontre` (dpbh) ida : communication par A de son identification complète à un compte inconnu
- `grlmg` (idg) : liste des id + nc des membres du groupe  
- `grmembre` (idg, nm) : données d'un membre du groupe
- `secret` (id, ns) : données d'un secret d'un avatar ou groupe

## Table `etat` - singleton d'état global du serveur
Ce singleton est un JSON où le serveur peut stocker des données persistantes à propos de son état global : par exemple les date-heures d'exécution des derniers traitements GC, la dhc du dernier backup de la base...

	  CREATE TABLE "etat" ("data"	BLOB);

## Table `versions` - CP : `id`

Au lieu d'un compteur par avatar / groupe / compte on a 99 compteurs, un compteur pour plusieurs avatars / groupe (le reste d'une division de l'id + 1).  
La colonne `v` est un array d'entiers.

Le compteur 0 est par convention le compteur de la _séquence universelle_.

>Le nombre de collisions n'est pas vraiment un problème : détecter des proximités entre avatars / groupes dans ce cas devient un exercice très incertain (fiabilité de 1 sur 99).

L'id 0 correspondant à l'état courant et l'id 1 à la dernière sauvegarde.

    CREATE TABLE "versions" (
    "id"  INTEGER,
    "v"  BLOB
    PRIMARY KEY("id")
    ) WITHOUT ROWID;

## Table `avgrvq` - CP `id`. Volumes et quotas des avatars et groupes
Pour chaque avatar et groupe, par convention la *banque centrale* est l'avatar d'id 1, 
- `v1 v2` : les volumes utilisés augmentent quand des secrets sont rendus persistants ou mis à jour en augmentation et diminuent quand ils sont supprimés ou mis à jour en réduction : ce sont des actions qui peuvent être déclenchées par d'autres comptes (maj d'un secret déjà persistant).
- `vm1 vm2` : volumes consommés dans le mois. Le changement de mois remet à 0 `vm1` et `vm2`.
- `q1 q2 qm1 qm2` : quotas donnés à un groupe / avatar par une groupe / avatar / banque. En cas de GC d'un avatar / groupe, ils sont retournés à la banque. Pour un groupe il n'y a pas de `qm1 qm2`.

Les transferts de quotas entre avatars / groupes / banque se font sous la forme d'un débit / crédit.
- *Normalement* les sommes des quotas doivent être nulles.
- *Normalement* les volumes doivent être inférieurs à leur quotas.

Table :

    CREATE TABLE "avgrvq" (
    "id"	INTEGER,
    "q1"	INTEGER,
    "q2"	INTEGER,
    "qm1"	INTEGER,
    "qm2"	INTEGER,
    "v1"	INTEGER,
    "v2"	INTEGER,
    "vm1"	INTEGER,
    "vm2"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;

**Opération mensuelle**  
Les volumes mensuels sont mis à 0 le premier de chaque mois à minuit. Le cas échéant l'occasion de sortir des statistiques sur un fichier `xls`. 

## Table `cvsg` : CP `id`. Cartes de visites et signatures des comptes, avatars, groupes 
A chaque connexion d'un compte, le compte signe pour lui-même, ses avatars et les groupes que ses avatars ont en *contact* (dont l'accès n'est pas résilié):
- le jour de signature du compte est tiré aléatoirement entre j-28 et j-14.
- le jour de signature de ses avatars est tiré aléatoirement entre j-14 et j.
- le jour de signature des groupes accédés est tiré aléatoirement entre j-14 et j.

Le traitement quotidien met à jour le flag alerte/disparu.
- *alerte* : _l'avatar_ est resté plusieurs mois sans connexion.
- *disparu* : _l'avatar_ doit être considéré comme disparu (c'est définitif).

Table

    CREATE TABLE "cvsg" (
    "id"	INTEGER,
    "v"	INTEGER,
    "dds"  INTEGER,
    "ad"  INTEGER,
    "cvag"	BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "v_cvsg" ON "cvsg" ( "v" );
    CREATE INDEX "dds_ad_id_cvsg" ON "cvsg" ( "dds", "ad", "id" );
	
- `id` : id de l'avatar ou du groupe.
- `v` : de la séquence universelle.
- `dds` : date (jour) de dernière signature.
- `ad` : 0:OK, 1:alerte, 2:disparu.
- `cvag` : carte de visite cryptée par la clé de l'avatar ou du groupe. 
  - `photo` : photo ou icône.
  - `info` : court texte informatif.

**Remarques**
- un row est systématiquement créé à la création d'un compte / avatar / groupe : v est 0.
- à la signature, `dds` est changée uniquement pour un avatar :
  - si `ad` était _OK_, `v` n'est pas changé,
  - si `ad` était _alerte_, `v` est changée.
- à la modification / création de la carte de visite, `v` est changée.
- mise à jour de `ad` : par le traitement journalier. Si changement (OK -> alerte, alerte -> disparu) mise à jour de `v`.
- l'état disparu est immuable, un avatar ne _renaît_ jamais, le row est définitivement figé, sa carte de visite mise à nul et le row sera simplement détruit un jour lointain (dans 3 ans par exemple).
- un avatar d'un compte régulièrement accédé sans carte de visite a une version à 0.
- si un avatar n'est jamais monté en alerte, v est la version de sa carte de visite.

### GC des comptes et groupes
La détection par `dds` trop ancienne d'un **compte** 
- détruit le row dans `compte` et dans `cvsg`. 
- un compte est toujours détruit physiquement avant ses avatars puisqu'il apparaît plus ancien que ses avatars dans l'ordre des signatures.
- le compte n'étant plus accessible, ses avatars ne seront plus signés et les groupes auxquels il accédait non plus.

La détection par `dds` trop ancienne d'un **groupe**,
- détruit ses row dans toutes les tables `grlmg grmembre secret cvsg`.
- transfert ses quotas de son row `avgrvq` sur la banque centrale et détruit son row `avgrvq`.
- par construction un groupe ne tombe en désuétude que lorsque *tous* les avatars membres actifs ont disparu. Il suffit donc de purger ses données que plus personne ne référence. 
- par construction s'il avait existé encore un avatar dont l'accès au groupe n'est pas résilié, le groupe aurait été signé lors de la connexion du compte.
- **remarque** : la résiliation d'un accès pour un avatar provoque,
  - la mise à 0 de son slot dans `avidcc`.
  - la suppression physique de son row dans `avcontact`.
  - le contact résilié reste référencé en tant que résilié dans `grmembre` (mais son slot dans `grlmg` est 0).

Les *disparus* depuis plus d'un an sont détruits par le GC.

## Table : `compte` CP `idc`. Authentification et données d'un compte
_Phrase secrète_ : une ligne 1 de 16 caractères au moins et une ligne 2 de 16 caractères au moins.  
`pcb` : PBKFD2 de la phrase complète (clé X) - 32 bytes.  
`dpbh` : hashBin (53 bits) du PBKFD2 du début de la phrase secrète (32 bytes).

Table :

    CREATE TABLE "compte" (
    "id"	INTEGER,
    "v"		INTEGER,
    "dpbh"	INTEGER,
    "pcbsh"	INTEGER,
    "kx"   BLOB,
    "lack"  BLOB,
    "mmck"	BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE UNIQUE INDEX "dpbh_compte" ON "compte" ( "dpbh" )
	
- `id` : id du compte.
- `v` : 
- `dpbh` : pour la connexion, l'id du compte n'étant pas connu de l'utilisateur.
- `pcbsh` : hash du SHA du PBKFD2 de la phrase complète pour quasi-authentifier une connexion.
- `kx` : clé K du compte, crypté par la X (phrase secrète courante).
- `mmck` {} : cryptées par la clé K, map des mots clés déclarés par le compte.
  - *clé* : id du mot clé de 1 à 99.
  - *valeur* : libellé du mot clé.
- `lack` [] : liste des avatars du compte `[id, rnd, nom, cpriv]`, cryptée par la clé K, 
  - `id, rnd, nom` : id complète.
  - `cpriv` : clé privée asymétrique.

**Remarques :** 
- un row `compte` ne peut être modifié que par une transaction du compte.
- il est synchronisé lorsqu'il y a plusieurs sessions ouvertes en parallèle sur le même compte depuis plusieurs sessions de browsers.
- chaque mise à jour vérifie que `v` actuellement en base est bien celle à partir de laquelle l'édition a été faite pour éviter les mises à jour parallèles intempestives.

## Table `avrsa` : CP `id`. Clé publique RSA des avatars
Cette table donne la clé RSA (publique) obtenue à la création de l'avatar : elle permet d'inviter un avatar à être contact fort ou à devenir membre d'un groupe.

Table :

    CREATE TABLE "avrsa" (
    "id"	INTEGER,
    "clepub"	BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
	
- `id` : id de l'avatar.
- `clepub` : clé publique. 

### Avatars : liste et détails des contacts d'un avatar A
Les contacts ont un numéro de contact `nc` attribué en séquence à la création qui les identifie relativement à l'avatar A.  
Un avatar A peut avoir pour contact :
- **soit un avatar B**, avec deux états successifs possibles :
	- **simple** (statut 0) : A a B pour contact `15` et B peut avoir ou non A pour contact `57`, ces situations sont autonomes l'une de l'autre et ni A ni B ne savent rien du contact éventuel de l'autre. A peut décider de perdre B comme contact et B peut décider de perdre A comme contact, puis éventuellement de reprendre B pour contact sous un nouveau numéro `18`.
	- **fort** : A a B pour contact `15`, B a A pour contact `57` : ces numéros de contacts mutuels forts sont connus et immuables de part et d'autre. A peut restreindre la nature de ses échanges avec B mais ne peut plus les rompre tant que B n'a pas disparu.
- **soit un groupe G** : si A est membre du groupe G sous un numéro de contact 25, il le restera jusqu'à sa résiliation (volontaire ou par un animateur).

A chaque numéro de contact `nc` est associée la partie de la clé `rnd` :
- avatar B, contact simple : rien ou le `rnd` de la dernière demande de contact _fort_ refusée ou en attente.
- avatar B, contact fort : le `rnd` de la clé de partage entre A et B (15 bytes).
- groupe G dont A est membre : le `rnd` de la clé du groupe.

### Table `avidcc` : CP `ida`. Liste des contacts d'un avatar

Cette table donne les couples `id + cc/cg` pour chacun des `nc`. Elle énumère tous les avatars et groupes en contact (avec leur clé d'accès aux secrets).

    CREATE TABLE "avidcc" (
    "ida"   INTEGER,
    "v"		INTEGER,
    "idcck"  BLOB,
    PRIMARY KEY("ida")
    ) WITHOUT ROWID;
    CREATE INDEX "ida_v_avidcc" ON "avidcc" ( "ida", "v" )

- `ida` : id de l'avatar A.
- `v` : 
- `idcck` [ ] : table donnant la clé de cryptage `id + cc/cg` pour chaque `nc` (qui est l'index dans cette table) et permettant de récupérer en session toutes les ids des avatars non disparus et des groupes dont l'accès n'est pas résilié
  - `id` est une redondance puisqu'on le retrouve dans `avcontact` mais ça permet à l'avatar d'avoir la liste des contacts en une fois .
  - pour un groupe G le terme d'index `nc` est vide à la _résiliation_ de A du groupe G.
  - pour un avatar B, le terme d'index `nc` est vide lors du constat de la _disparition_ de B ou en cas de refus de parrainage de B.
  - chaque terme est crypté par la clé K. Ceci permet à un _animateur de groupe_ de mettre à 0 le terme `nc` à la résiliation sans avoir besoin de décrypter toute la liste (ce qu'il ne peut pas faire, n'ayant pas la clé K des membres). Même chose lors d'un refus de parrainage.

## Table `avct` : CP `id nc`. Contact d'un avatar

    CREATE TABLE "avct" (
    "id"   INTEGER,
    "nc"	INTEGER,
    "v"  	INTEGER,
    "st" INTEGER,
    "q1" INTEGER,
    "q2" INTEGER,
    "qm1" INTEGER,
    "qm2" INTEGER,
    "ardc"	BLOB,
    "datak"	BLOB,
    "rndgk" BLOB,
    PRIMARY KEY("id", "nc")
    );
    CREATE INDEX "id_v_avct" ON "avct" ( "id", "v" )

- `id` : id de l'avatar A
- `nc` : numéro de contact de B ou G pour A.
- `v` : 
- `st` : statut entier de 3 chiffres, `x y z` : **la valeur 0 indique un row supprimé (les champs après sont null)**.
  - `x` : statut du contact 
    - 1 - contact _simple_ avec un avatar présumé actif
    - 2 - contact _simple_ avec un avatar disparu
    - 3 - contact _fort_ en attente d'acceptation par un avatar présumé actif
    - 4 - contact _fort_ en attente d'acceptation avec un avatar en cours de parrainage
    - 5 - contact _fort_ avec un avatar présumé actif
    - 6 - contact _fort_ avec un avatar disparu
    - 7 - membre actif du groupe
    - 8 - membre résilié du groupe
  - `y z` :
    - _contact fort avec un avatar_ :
      - `y` : A accepte 1 (ou non 0) les partages de B.
      - `z` : B accepte 1 (ou non 0) les partages de A.
    - _contact de groupe_ :
      - `y` : 1:lecteur, 2:auteur, 3:administrateur.
      - `z` : plus haut y jamais atteint.
- `q1 q2 qm1 qm2` : balance des quotas donnés / reçus par l'avatar A au groupe G ou à l'avatar B.
- `ardc` : **ardoise** partagée entre A et B cryptée par la clé `cc` associée au `nc` pour un contact _fort_ avec un avatar B (en attente ou refusé - retombé en simple).
- `datak` : information cryptée par la clé K de A.
  - `rndcc` : seulement pour un contact _fort_ B (en attente ou accepté).
  - `id` : id de l'avatar B ou du groupe G.
  - `nom` : nom de l'avatar ou du groupe.
  - `info` : information libre donnée par A à propos du contact.
  - `mc` : liste des mots clés associés par A au contact.
- `rndk` : `rnd` de la carte de visite de l'avatar ou du groupe (clé du groupe) crypté par la clé K de A.

Un *contact fort* permet de partager par **l'ardoise** un court texte entre A et B pour justifier d'un changement de statut ou n'importe quoi d'autre : en particulier quand A n'accepte pas le partage de secrets avec B par exemple, c'est le seul moyen de passer une courte information mutuelle qui n'encombre pas leurs volumes respectifs.

**Remarques :**
- un contact _fort_ invité mais avec une réponse de refus, redevient un contact _simple_. Toutefois l'ardoise contient l'explication du refus et `rndcc` est la clé qui crypte cette ardoise.
- un parrainage refusé est traité par un statut `0` du row dans `avct` .
- le row `avct` d'un groupe dont l'accès est résilié pour A reste pour information historique. La carte de visite du groupe n'est plus accessible, le groupe non plus (`rndgk` est null).
- le row `avct` d'un avatar disparu reste pour information historique. La carte de visite de l'avatar n'est plus accessible (et d'ailleurs n'existe plus, `rndgk` est null.
- dans ces deux derniers cas, l'utilisateur peut demander la suppression ce row d'information historique (`st` passe à 0).

## Table `avinvitct` : CP : `id`. Invitation en attente reçue par B de A à établir un contact fort
Un contact *fort* est requis pour partager, un statut, une ardoise et des secrets et s'échanger des quotas.

Dans avct le contact simple a un statut invitation en cours

    CREATE TABLE "avinvitct" (
    "id"   INTEGER,
    "dlv"	INTEGER,
    "st"  INTEGER,
    "idncah"  INTEGER,
    "ccpub" BLOB,
    "datac"  BLOB,
    "ardc"  BLOB)
    PRIMARY KEY ("id", "idncah");
    CREATE INDEX "dlv_avinvitct" ON "avinvitct" ( "dlv" );

- `id` : id de B.
- `dlv` :
- `st` : 0: annulée, 1: en attente, 2: accepté, 3: refusé
- `idncah` : hash de `id + nc` de A pour servir de complément à `id` dans la clé primaire et permettre à A d'annuler son invitation.
- `ccpub` : `rnd` de la clé `cc` du contact *fort* A / B, définie par A, cryptée par la clé publique de B.
- `datac` : données cryptées par la clé `cc`.
	- `[id + rnd, nom]` : id complète de A.
	- `nc` : numéro du contact de A pour B (pour que B puisse écrire le statut et l'ardoise dans `avct` de A). 
- `ardc` : texte de sollicitation écrit par A pour B et/ou réponse de B (pour A ce texte figure déjà dans `avct` pour l'élément `nc` au moment du lancement de l'invitation).

**En cas d'acceptation**, B peut, soit créer un contact chez lui pour A quand il n'y en a pas encore, soit récupérer celui existant chez lui pour A s'il l'avait déjà en contact simple, et inscrire les données de A comme contact *fort* chez lui (`st rndcc ardc`). Chez A il y a mise à jour de `st ardc` avec le remerciement de B. Le statut `st` du row `avinvitct` (de B) est à 2.

**En cas de refus**, le contact `nc` chez A redevient un contact _simple_, l'ardoise `ardc` de `avct` de A contient la raison du refus. Le statut `st` du row `avinvitct` (de B) est à 3. 

**Si B ne répond pas à temps**, le dépassement de `dlv` détecte le cas : le contact `nc` chez A redevient un contact _simple_. 

Dans tous les cas le row `avinvitct` (de B) est supprimé par le GC sur la `dlv`.

A peut annuler une invitation (par sa clé primaire) avant la réponse de B.

### Table `parrain` : CP `pps`. Parrainage par P de la création d'un compte F 

F est un *inconnu* n'ayant pas encore de compte.

Comme il va y avoir un don de quotas du *parrain* vers son *filleul*, ces deux-là vont avoir un contact *fort* (si F accepte). Toutefois,
- P peut indiquer que son contact est sans partage de secrets.
- F pourra indiquer que son contact est sans partage de secrets.

Le parrain fixe l'avatar filleul (mais pas son compte), donc son nom : le contact _fort_ est préétabli dans `avct` de P. Le filleul établira le sien, s'il accepte.

Un parrainage est indexé par le hash du PBKFD2 de la phrase de parrainage pour être retrouvée par le filleul.

    CREATE TABLE "parrain" (
    "pps"  INTEGER,
    "id" INTEGER,
    "nc" INTEGER,  
    "dlv"  INTEGER,
    "st"  INTEGER,
    "datak"  BLOB,
    "datax"  BLOB,
    "ardc"  BLOB,
    PRIMARY KEY("pps")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_parrain" ON "parrain" ( "dlv" );
    CREATE INDEX "idp_parrain" ON "parrain" ( "id" )

- `id` : id du parrain.
- `nc` : numéro de contact du filleul chez le parrain.
- `pps` : hash du PBKFD2 de la phrase de parrainage.
- `dlv` : la date limite de validité permettant de purger les parrainages.
- `st` : 0: annulé, 1: en attente, 2: accepté, 3: refusé
- `datak` : phrase de parrainage cryptée par la clé K du parrain.
- `datax` : données de l'invitation cryptées par le PBKFD2 de la phrase de parrainage.
  - `[id + rnd, nom]` : id complète de l'avatar P. (id est une redondance, c'est le champ id en clair).
  - `[id + rnd, nom]` : id complète du filleul F.
  - `cc` : `rnd` de la clé `cc` générée par P pour le couple P / F.
- `ardc` : cryptée par la clé `cc`, *ardoise*, texte de sollicitation écrit par A pour B et/ou réponse de B.

**La parrain créé par anticipation un contact *fort* pour le filleul**  avec un row `avct`. 

**Si le filleul ne fait rien à temps : (`st` toujours à 0)** lors du GC sur la `dlv`, le row `parrain` sera supprimé par GC de la `dlv`, le row dans `avct` sera marqué avec un `st` à 0 (supprimé).

**Si le filleul refuse le parrainage :** le row dans `avct` du parrain est marqué avec un `st` à 3 (supprimé). L'ardoise de `parrain` renseigne sur la raison de B (et `datax` mis à null). Le row `parrain` est immuable et sera purgé par le GC sur `dlv`).

**Si le filleul accepte le parrainage :** le filleul crée son compte et son premier avatar (dont il a reçu `[id, rnd, nom]` de P) et créé un contact fort avec P. Les quotas sont prélevés à ce moment. Le `st` du row `parrain` est mis à 2. L'ardoise des `avcontact` de P et de F contient l'ardoise de l'acceptation (`ardc`).

**Le parrain peut annuler son row :** son `st` passe à 0.

Dans tous les cas le GC sur `dlv` supprime le row `parrain`.

## Table `rencontre` : CP `dpbh`. Rencontre entre les avatars A et B
A et B se sont rencontrés dans la *vraie* vie mais ni l'un ni l'autre n'a les coordonnées de l'autre pour,
- soit s'inviter à créer un contact *lié*,
- soit pour B inviter A à participer à un groupe.

Une rencontre est juste un row qui va permettre à A de transmettre à B son `id, rnd, nom` en utilisant une phrase de rencontre convenue entre eux.  
En accédant à cette rencontre B peut ainsi inscrire A comme contact *libre* : ensuite il pourra normalement l'inviter à un contact *lié* (ou l'inviter à un groupe).

Une rencontre est identifiée par le hash du PBKFD2 de la phrase de rencontre.

    CREATE TABLE "rencontre" (
    "prh" INTEGER,
    "id" INTEGER,
    "v"   INTEGER,
    "dlv" INTEGER,
    "datak" BLOB,
    "datax" BLOB,
    PRIMARY KEY("prh")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_rencontre" ON "rencontre" ( "dlv" )
    CREATE INDEX "id_rencontre" ON "rencontre" ( "id" )

- `prh` : hash du PBKFD2 de la phrase de rencontre.
- `id` : id de l'avatar A ayant initié la rencontre.
- `v` :
- `dlv` : la date limite de validité permettant de purger les rencontres.
- st : 0:annulée, 1:en attente, 2:acceptée, 3:refusée
- `datak` : phrase de rencontre cryptée par la clé K du compte A pour que A puisse retrouver les rencontres qu'il a initiées avec leur phrase.
- `datax` : données de l'invitation cryptées par le PBKFD2 de la phrase de rencontre.
  - `[id + rnd, nom]` : id complète de A (pas de l'invité, son id complète n'est justement pas connue).

Si B accepte la rencontre, il créé son contact simple, st passe à 2.

Si B refuse la rencontre, `st` passe à 3.

Le GC sur `dlv` détruit le row `rencontre`.

A peut annuler la rencontre (remord), `st` passe à 0.

## Table `avinvitgr`. Invitation par A de M à un groupe G
L'invitant peut retrouver en session la liste des invitations en cours qu'il a faites : un membre de G avec `ida` comme invitant et un statut en attente.

    CREATE TABLE "avinvitgr" (
    "idm"   INTEGER,
    "v"   INTEGER,
    "dlv"	INTEGER,
    "datapub"  BLOB);
    CREATE INDEX "dlv_grinvitgr" ON "grinvitgr" ( "dlv" );
    CREATE INDEX "idm_grinvitgr" ON "grinvitgr" ( "idm" );

- `idm` : id du membre invité.
- `v` :
- `dlv` :
- `datapub` : crypté par la clé publique du membre invité. Données permettant à l'invité de se localiser dans la liste des membres du groupe.
	- `id + rnd, nom` : id complète du groupe.
	- `nm` : numéro de membre de l'invité.

## Table `grlmg` : CP: `idg`. Liste des membres d'un groupe
- `id` : entier depuis 5 bytes aléatoires.  
- `code` : lisible (comme un nom de fichier) et immuable.
- `cg` : 15 bytes aléatoires. Permet d'accéder à la liste des membres du groupe et à la carte de visite du groupe.

Un groupe est caractérisé par :
- sa carte de visite dans `cvsg`,
- ses quotas et volumes dans `avgrvq`,
- la liste de ses membres dans `grmlg`.
- le détail de ses membres dans `grmembre`.
- la liste de ses secrets dans `secrets`.

Table

    CREATE TABLE "grlmg" (
    "idg"   INTEGER,
    "v"  INTEGER,
    "st"	INTEGER,
    "mcg" BLOB,
    "idncg"  BLOB,
    PRIMARY KEY("idg")
    ) WITHOUT ROWID;
    CREATE INDEX "idg_v_grlmg" ON "grlmg" ( "idg", "v" )

- `id` : id du groupe.
- `v` : 
- `st` : statut : 1)ouvert, 2)fermé, 3)ré-ouverture en vote, 4)archivé 
- `mcg` : liste des mots clés prédéfinis pour le groupe.
- `idncg` [`idm + nc`]: liste indexée par le numéro de membre (cryptée par la clé du groupe `cg`). Pour chaque membre actif `nm`, la référence de son contact :
	- `idm` : l'id du membre.
	- `nc` : son numéro de contact qui permet au membre de retrouver la clé `cg` du groupe (dans `avidcc`).

Quand un membre est résilié ou a disparu, son slot dans la liste est 0 : la liste des membres actifs s'obtient de cette liste.

## Table `grmembre` : CP `idg nm`. Détail d'un membre d'un groupe
Chaque membre d'un groupe a une entrée pour le groupe identifiée par un numéro de membre `nm` attribué en séquence.   
Les données relatives aux membres sont cryptées par la clé du groupe.

Table

    CREATE TABLE "grmembre" (
    "idg"   INTEGER,
    "nm"	INTEGER,
    "v"		INTEGER,
    "st"	TEXT,
    "datag"	BLOB,
    PRIMARY KEY("id", "nm"));
    CREATE INDEX "id_v_avlab" ON "grmembre" ( "idg", "v" )

- `id` : id du groupe.
- `nm` : numéro du membre dans le groupe.
- `v` :
- `st` : statut.
- `dlv` : date limite de validité de l'invitation.
- `datag` : données cryptées par la clé du groupe.
	- `id + rnd, nom` : id complète de l'avatar membre.
	- `idi` : id du membre qui l'a pressenti / invité.
	- `q1 q2` : balance des quotas donnés / reçus par le membre au groupe.
- `ardg` : ardoise du membre vis à vis du groupe, texte d'invitation / réponse de l'invité
- `vote` : de réouverture.

Le statut comporte trois chiffres `xyz` :
- x : 1:pressenti, 2:invité, 3:actif, 4:refusé, 8: résilié, 9:disparu.
- y : 1:lecteur, 2:auteur, 3:administrateur.
- z : plus haut y jamais atteint.

**Remarques**
- les membres de statut invité et actif accèdent à la liste des membres.
- les membres actifs accèdent aux secrets.
- seuls les animateurs peuvent :
    - inviter d'autres avatars à rejoindre la liste.
    - changer les statuts des membres non animateurs.
    - détruire le groupe.
    - attribuer un statut *permanent* à un secret partagé par le groupe.
- les avatars membres du groupe peuvent s'ils sont actifs et auteur / animateur :
	- partager un secret avec le groupe,
	- modifier un secret du groupe selon le statut du secret : 
		- *ouvert* : tous les *auteurs / animateurs* peuvent le modifier.
		- *restreint* : seul le dernier auteur peut le modifier.
		- *archivé* : le secret ne peut plus changer (jamais).
- un animateur peut lancer quand il veut un nettoyage pour détecter les membres qui auraient disparus *et* ne seraient plus auteurs d'aucuns secrets.
- le row `grmembre` d'un membre subsiste quand il est résilié et / ou disparu pour information historique : la carte de visite n'est plus accessible.

## Secrets
Un secret est identifié par,
- id : l'id du groupe ou de l'avatar proriétaire.
- ns : un numéro aléatoire relatif à cet id.

La clé de cryptage du secret `cs` est selon le cas :
- (0) *secret personnel d'un avatar A* : la clé K de l'avatar.
- (1) *secret d'un couple d'avatars A et B* : leur clé `cc` de contact fort.
- (2) *secret d'un groupe G* : la clé du groupe G.

**Un secret de couple A / B** est matérialisé par 2 secrets, un pour A et un pour B (et la même clé de cryptage, celle `cc` du couple). Chaque secret dans ce cas détient la référence de l'autre afin que la mise à jour de l'un puisse être répercutée sur l'autre (quand il existe, A et B peuvent indépendamment l'un de l'autre détruire leur exemplaire).

A crée les deux exemplaires du secret en générant deux numéros relatifs à A et B afin que la relation entre A et B n'apparaisse pas dans la base.

### Un secret a toujours un texte et possiblement une pièce jointe
Le texte a une longueur maximale de 4000 caractères. L'aperçu d'un secret est constituée des 140 premiers caractères de son texte.

*Le texte complet d'un secret* n'existe que lorsque le texte fait plus de 140 caractères : il est stocké gzippé.

Un secret peut avoir une pièce jointe,
- de taille limitée à quelques dizaines de Mo,
- ayant un type MIME,
- à chaque fois qu'une pièce jointe est changée elle a une version différente afin qu'à tout instant une pièce jointe puisse être lisible même durant son remplacement (son cryptage et son stockage peuvent prendre du temps).

### Mise à jour d'un secret
Le statut d'un secret peut être :
- *ouvert* : tous les avatars accédant possibles peuvent le mettre à jour et modifier son statut.
- *restreint* : seul le dernier auteur peut le mettre à jour et modifier son statut.
- *archivé* : personne ne peut le modifier, ni modifier son statut.

La liste des auteurs d'un secret donne les derniers auteurs,
- dans l'ordre de modification, le plus récent en tête,
- sans doublon.

Un secret créé par A partagé avec personne peut être mis à jour :
- par A si le statut du secret est *ouvert* ou *restreint*.
- par personne si le statut du secret est *archivé*.
- le seul auteur qui apparaît dans la liste des auteurs successifs du secret est A.

Un secret créé par A partagé avec B (contact *fort* de A) peut être mis à jour :
- par A si le statut du secret est *ouvert* ou *restreint*.
- par B si statut est *ouvert*.
- par personne si le statut du secret est *archivé*.
- les seuls auteurs qui peuvent apparaître dans la liste des auteurs successifs du secret sont A et B.

Un compte peut faire une requête retournant la liste des avatars ayant accès à un des secrets partagés (ou non) de ses avatars et disposer de la liste des auteurs qui devraient tous lui être connus (dans un groupe et / ou en tant que contact).

### Secret temporaire et permanent
Par défaut à sa création un secret est *temporaire* :
- son `nsc` *numéro de semaine de création* indique que S semaines plus tard il sera automatiquement détruit.
- un avatar Ai qui le partage peut le déclarer *permanent*, le secret ne sera plus détruit automatiquement :
  - l'avatar propriétaire pour un secret personnel.
  - les deux avatars pour un secret de couple.
  - un des animateurs pour un secret de groupe.

### Décompte du volume des secrets et des pièces jointes
- il est décompté à la création sur le décompte de secrets *créés / modifiés dans le mois* de l'auteur.
- le décompte intervient à chaque modification en plus dans le mois de l'auteur.

Dès que le secret est *permanent* il est décompté (en plus ou en moins à chaque mise à jour) sur le volume du groupe.

## Table `secret` : CP `ids`. Secret

    CREATE TABLE "secret" (
    "id"  INTEGER,
    "ns"  INTEGER,
    "v"		INTEGER,
    "nsc"	INTEGER,
    "txts"	BLOB,
    "mcs"   BLOB,
    "aps"	BLOB,
    "dups"	BLOB,
    PRIMARY KEY("id","ns"));
    CREATE INDEX "id_v_secret" ON "secret" ("id", "v")
    CREATE INDEX "nsc_secret" ON "secret" ( "nsc" )

- `id` : id du groupe ou de l'avatar.
- `ns` : numéro du secret relatif au groupe / avatar.
- `v` : 
- `nsc` : numéro de semaine de création ou 9999 pour un *permanent*.
- `txts` : texte complet gzippé crypté par la clé du secret.
- `mcs` : liste des mots clés.
- `aps` : données d'aperçu du secret cryptées par la clé du secret.
  - `la` [] : liste des auteurs (identifié par leur numéro de membre pour un groupe) ou id du dernier auteur pour un secret de couple.
  - `ap` : texte d'aperçu.
  - `st` : 5 bytes donnant :
    - 0:ouvert, 1:restreint, 2:archivé
    - la taille du texte : 0 pas de texte, 1, 2, ... (log) 
    - la taille de la pièce jointe : 0 pas de pièce, 1, 2 ... (log)
    - type de la pièce jointe : 0 inconnu, 1, 2 ... selon une liste prédéfinie.
    - version de la pièce jointe afin que l'upload de la version suivante n'écrase pas la précédente.
  - `r` : référence à un autre secret (du même groupe, couple, avatar).
- `dups` : référence de l'autre exemplaire pour un secret de couple A/B.

### Mots clés
Un secret peut apparaître avec plusieurs mots clés indiquant :
- des états : _lus, important, à cacher, à relire, favori ..._
- des éléments de classement fonctionnel : _énergie bio-diversité réchauffement ..._

Le texte d'un mot clé peut contenir en tête un emoji.

Les mots clés sont numérotés avec une conversion entre leur numéro et leur texte :
- 1-49 : pour ceux génériques de l'installation dans la configuration.
- 50-255 : pour ceux spécifiques de chaque compte dans `mc` de son row `cvsg` : la map est cryptée par la clé K du compte.
- 50-255 : pour ceux spécifiques de chaque groupe dans `mc` de son row `cvsg` : la map est cryptée par la clé G du groupe.

**Pour un secret d'un avatar**
- `mcs` est simplement la suite des numéros de mots clés attachés par l'avatar au secret.

**Pour un secret de couple**
- le secret est dédoublé, dans chaque exemplaire `mcs` est simplement la suite des numéros de mots clés attachés par l'avatar au secret.

**Pour un secret de groupe**
- c'est une map avec une entrée pour le groupe et une pour chaque membre (identifié par son numéro de membre dans le goupe).
- chaque membre voit l'union des mots clés fixés pour le groupe avec les siens propres.

# Gestions des avatars disparus
La détection s'effectue par le GC quotidien sur recherche des `dds` trop ancienne d'un avatar.

Par principe un avatar est détecté disparu après la détection de la disparition de son compte. Il s'agit donc de purger les données.

## Purge des données identifiées par l'id de l'avatar
- transfert de ses quotas depuis son row `avgrvq` sur la banque et destruction de son row `avgrvq`.
- destruction des rows les tables `avrsa avidcc avcontact avinvitct avinvitgr parrain rencontre secret`.
- son row dans `cvsg` est réduit, la carte de visite est effacée, son statut est _disparu_.

Dès cet instant le volume occupé est récupéré.

## Mise à jour des références chez les autres comptes
L'avatar _disparu_ D est _référencé_ par des avatars et groupes :
- `avidcc avcontact` des autres avatars l'ayant en contact.
- `parrain rencontre` : la date limite de validité a déjà résolu la question, les rows ont déjà été détruits.
- `grlmg grmembre` des groupes l'ayant pour membre.  

Quand une session d'un avatar A synchronise les cartes de visite elle a connaissance par la carte de visite de D que cet avatar a disparu :
- le row `avcontact` correspondant a son statut mis à jour. Mais il n'y a pas de raisons pour que les secrets partagés (et dédoublés) disparaissent aussi.
- sur demande du compte, le contact peut être _oublié_ :
  - dans la liste de ses contacts `avidcc` le slot correspondant est mis à 0.
  - le row `avcontact` est supprimé.
  - tous les `secret` de l'avatar portant ce numéro de contact sont détruits (et l'avatar crédité des volumes supprimés).
- pour chaque groupe accédé par l'avatar :
  - le slot correspondant dans `grlmg` est mis à 0 (ce qui évite à l'avenir d'aller rafraîchir sa carte de visite).
  - le row `grmembre` a son statut mis à jour. 
  - sur demande d'un compte animateur du groupe, le row pourrait être supprimé pour _nettoyer_ la liste des membres : mais des secrets du groupe peuvent continuer à référencer ce membre comme auteur. Ne pas nettoyer dans ce cas ?

Dans la session la carte de visite est supprimée, elle ne sera plus synchronisée.

Les références peuvent mettre longtemps a être mises à jour, tous les comptes référençant l'avatar D ayant à être ouverts (ou disparaissant elles-mêmes).

# Base vivante et de backup ???
La base de backup est l'image de la base vivante la veille au soir.
- elle est accessible en lecture seule.
- la table versions permet de savoir jusqu'à quelles versions elle a été sauvée.

En début de session un compte *peut* avoir des jours / semaines / mois à rattraper, voire tout si la session est en mode incognito : une grande masse de rows peuvent être lus depuis le backup sans bloquer la base vivante. 

Comment savoir s'il est opportun de faire deux passes ou une seule directement sur la base vivante ?.

La vraie connexion / synchronisation se fait sur la base vivante pour avoir les toutes dernières mises à jour mais ça devrait être très léger.

