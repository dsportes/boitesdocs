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
- `id` : un entier issu de 6 bytes aléatoires.  
- `clé K` : 32 bytes aléatoires.  
- `pcb` : PBKFD2 de la phrase complète (clé X) - 32 bytes.  
- `dpbh` : hashBin (_integer_) du PBKFD2 du début de la phrase secrète.

**La phrase secrète d'un compte reste dans le cerveau du titulaire.**
- sa transformée par PBKFD2 dès la saisie donne une clé AES X qui ne sort jamais de la session cliente et n'est jamais stockée de manière permanente.

**La clé K d'un compte**,
- n'est stockée en session comme en serveur que sous forme cryptée par X.
- n'est jamais transmise au serveur en clair.
- les données cryptées par K, ne sont lisibles dans le serveur que quand elles ont été transmises aussi en clair dans une opération. 

### Avatar
Le **nom complet** d'un avatar est un string de la forme `[nom@rnd]`
- `nom` : nom lisible et signifiant, entre 6 et 20 caractères.
- `rnd` : 15 bytes aléatoires, 20 caractères en base 64.

La **clé de cryptage** de la carte de visite est le SHA de `rnd`.

L'`id` d'un avatar est le hash (integer) des bytes de `rnd`.

### Groupe
- `id` : un entier issu de 6 bytes aléatoires.
- `cleg` : la clé d'un groupe est formée de 32 bytes aléatoires.

### Secret
- `id` : du groupe ou de l'avatar propriétaire
- `ns` : numéro relatif au groupe / avatar, entier issu de 4 bytes aléatoires.

### Attributs génériques
- `v` : version, entier.
- `dds` : date de dernière signature, en nombre de jours depuis le 1/1/2021. Signale que ce jour-là, l'avatar, le compte, le groupe était *vivant / utile / référencé*. Pour éviter des rapprochements entre eux, la *vraie* date de signature peut être entre 0 et 30 jours *avant*.  
- `ad` : pour les avatars seulement, permet de distinguer des seuils d'alerte `ad` :
   - _OK_ : vivant encore récemment.
   - _alerte_ : des mois sans signe de vie, sera considéré comme disparu dans les 2 mois qui suivent.
   - _disparu_
- `dlv` : date limite de validité, en nombre de jours depuis le 1/1/2021.
- `st` : `avatar, contact, invitgr, invitct, parrain, membre, groupe, secret` : quand `st` est négatif c'est le numéro de semaine de sa suppression. Les rows ne sont pas supprimés physiquement pendant un certain temps afin de permettre aux mises à jour incrémentales des sessions de détecter les suppressions. Une session pour un compte étant ouverte au moins tous les 18 mois, les `st` négatifs de plus de 18 mois peuvent être physiquement supprimés.

Les comptes sont censés avoir au maximum N semaines entre 2 connexions faute de quoi ils sont considérés comme disparus.

### Signatures des comptes, avatars et groupes (`dds`)
A chaque connexion d'un compte, le compte signe si la `dds` actuelle n'est pas _récente_ (sinon les signatures ne sont pas mises à jour) :
- pour lui-même dans `compte` : jour de signature tiré aléatoirement entre j-28 et j-14.
- pour ses avatars dans `avatar` : jour de signature tiré aléatoirement pour chacun entre j-14 et j.
- pour les groupes auxquels ses avatars sont invités et dont l'accès n'est pas résilié dans `groupe` : jour de signature tiré aléatoirement pour chacun entre j-14 et j.

Le GC traitement quotidien des `dds` :
- pour les comptes : purge des rows `compte` afin de bloquer la connexion.
- pour les groupes : ils n'ont plus d'avatars qui les référencent, purge de leur données.
- pour les avatars :
  - mise à jour du statut OK/alerte/disparu.
    - *alerte* : _l'avatar_ est resté plusieurs mois sans connexion.
    - *disparu / supprimé* : _l'avatar_ est définitivement disparu.
  - purge / suppression de données pour les disparus.

### Version des rows
Les rows des tables devant être présents sur les clients ont une version, de manière à pouvoir être chargés sur les postes clients de manière incrémentale : la version est donc croissante avec le temps et figure dans tous les rows de ces tables.  
- utiliser une date-heure présente l'inconvénient de laisser une meta-donnée intelligible en base ;
- utiliser un compteur universel a l'inconvénient de facilement deviner des liaisons entre objets : par exemple l'invitation à établir un contact entre A et B n'apparaît pas dans les rows eux-mêmes mais serait lisible si les rows avaient la même version. Crypter l'appartenance d'un avatar à un groupe alors qu'on peut la lire de facto dans les versions est un problème.
- utiliser un compteur par objet rend complexe la génération de SQL avec des filtres qui associent chaque objet à sa dernière version connue.

Tous les objets synchronisables (sauf les comptes) sont identifiés, au moins en majeur, par une id d'avatar ou de groupe. Par exemple l'obtention des contacts d'un avatar se fait par une sélection d'abord sur l'id de l'avatar, puis sur sa version pour ne récupérer incrémentalement que ceux changés / créés. D'où l'option de gérer **une séquence de versions**, pas par id d'avatar, mais par hash de cet id.

#### `vcv` : version de la carte de visite d'un avatar
Afin de pouvoir rafraîchir uniquement les cartes de visites des avatars, la propriété vcv de avatar donne la version dans la séquence universelle

## Tables

- `versions` (id) : table des prochains numéros de versions (actuel et dernière sauvegarde) et autres singletons (id value)
- `avgrvq` (id) : volumes et quotas d'un avatar ou groupe  
- `avrsa` (id) : clé publique d'un avatar

_**Tables aussi persistantes sur le client (IDB)**_

- `compte` (id) : authentification et données d'un compte 
- `avatar` (id) : données d'un avatar et liste de ses contacts
- `invitgr` (id, ni) : invitation reçue par un avatar à devenir membre d'un groupe
- `contact` (id, nc) : données d'un contact d'un avatar    
- `invitct` (id, ni) : invitation reçue à lier un contact fort avec un autre avatar  
- `rencontre` (prh) id : communication par A de son nom complet à un avatar B non connu de A dans l'application
- `parrain` (pph) id : parrainage par un avatar A de la création d'un nouveau compte
- `groupe` (id) : données du groupe et liste de ses avatars, invités ou ayant été pressentis, un jour à être membre.
- `membre` (id, im) : données d'un membre du groupe
- `secret` (id, ns) : données d'un secret d'un avatar ou groupe
- `secran` (id, ns, im) : annotation d'un secret de groupe par un membre

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

## Table `avgrvq` - CP `id`. Volumes et quotas des avatars et groupes
Pour chaque avatar et groupe, par convention la *banque centrale* est l'avatar d'id 1, 
- `v1 v2` : les volumes utilisés augmentent quand des secrets sont rendus persistants ou mis à jour en augmentation et diminuent quand ils sont supprimés ou mis à jour en réduction : ce sont des actions qui peuvent être déclenchées par d'autres comptes (maj d'un secret déjà persistant).
- `vm1 vm2` : volumes consommés dans le mois. Le changement de mois remet à 0 `vm1` et `vm2`.
- `q1 q2 qm1 qm2` : quotas donnés à un groupe / avatar par une groupe / avatar / banque. En cas de GC d'un avatar / groupe, ils sont retournés à la banque. 

Pour un groupe il n'y a pas de `vm1 vm2 qm1 qm2`.

Les transferts de quotas entre avatars / groupes / banque centrale se font sous la forme d'un débit / crédit.
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

## Table : `compte` CP `id`. Authentification et données d'un compte
_Phrase secrète_ : une ligne 1 de 16 caractères au moins et une ligne 2 de 16 caractères au moins.  
`pcb` : PBKFD2 de la phrase complète (clé X) - 32 bytes.  
`dpbh` : hashBin (53 bits) du PBKFD2 du début de la phrase secrète (32 bytes).

Table :

    CREATE TABLE "compte" (
    "id"	INTEGER,
    "v"		INTEGER,
    "dds" INTEGER,
    "dpbh"	INTEGER,
    "pcbh"	INTEGER,
    "kx"   BLOB,
    "mack"  BLOB,
    "mmck"	BLOB,
    "memok" BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE UNIQUE INDEX "dpbh_compte" ON "compte" ( "dpbh" )
	
- `id` : id du compte.
- `v` : 
- `dds` : date (jour) de dernière signature.
- `dpbh` : hashBin (53 bits) du PBKFD2 du début de la phrase secrète (32 bytes). Pour la connexion, l'id du compte n'étant pas connu de l'utilisateur.
- `pcbh` : hashBin (53 bits) du PBKFD2 de la phrase complète pour quasi-authentifier une connexion avant un éventuel échec de décryptage de `kx`.
- `kx` : clé K du compte, crypté par la X (phrase secrète courante).
- `mmck` {} : cryptées par la clé K, map des mots clés déclarés par le compte.
  - *clé* : id du mot clé de 1 à 99.
  - *valeur* : libellé du mot clé.
- `mack` {} : map des avatars du compte `[nom@rnd, cpriv]`, cryptée par la clé K
  - `nomc` : `nom@rnd`, nom complet.
  - `cpriv` : clé privée asymétrique.
- `memok` : texte court libre (crypté par la clé K) vu par le seul titulaire du compte. Le début de la première ligne s'affiche en haut de l'écran.

**Remarques :** 
- un row `compte` ne peut être modifié que par une transaction du compte (mais peut être purgé par le traitement journalier de détection des disparus).
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

### Table `avatar` : CP `id`. Données d'un avatar
Chaque avatar a un row dans cette table :
- donne son statut de disparition _OK alerte disparu_ en hébergeant sa dernière signature de connexion,
- sa carte de visite,
- la liste de ses avatars en contact afin de garantir l'absence de doublons.

Table :

    CREATE TABLE "avatar" (
    "id"   INTEGER,
    "v"  	INTEGER,
    "st"  INTEGER,
    "vcv" INTEGER,
    "dds" INTEGER,
    "cva"	BLOB,
    "lctk" BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_v_avatar" ON "avatar" ( "id", "v" );
    CREATE INDEX "dds_avatar" ON "avatar" ( "dds" );
    CREATE INDEX "id_vcv_avatar" ON "avatar" ( "id", "vcv");

- `id` : id de l'avatar
- `v` :
- `st` : si négatif, l'avatar est supprimé / disparu (les autres colonnes sont à null). 0:OK, 1:alerte
- `vcv` : version de la carte de visite (séquence 0).
- `dds` :
- `cva` : carte de visite de l'avatar cryptée par la clé de l'avatar `[photo, info]`.
- `lctk` : liste, cryptée par la clé K du compte, des ids des contacts de l'avatar afin de garantir l'unicité de ceux-ci. L'indice d'un contact est celui dans cette liste + 1 (la valeur 0 est réservée).

Sur GC quotidien sur `dds` : 
- mise à jour du statut `st` OK/alerte/disparu.
  - *alerte* (1): _l'avatar_ est resté plusieurs mois sans connexion.
  - *disparu / supprimé* (<0): _l'avatar_ est définitivement disparu.
- purge / suppression des données pour les disparus.

**Remarques**
- à la signature d'un avatar, quand `dds` doit être mise à jour :
  - si le statut était _OK_, `v` n'est **pas** changé,
  - si le statut était _alerte_ (et va donc repasser à _OK_), `v` est changée afin que la mise à jour soit propagée dans les stockage off line.
- l'état disparu est immuable, un avatar ne _renaît_ jamais, le row `avatar` est marqué _supprimé_, les autres propriétés sont mise à null et le row sera physiquement détruit 18 mois après sa suppression.

### Table `contact` : CP `id ic`. Contact d'un avatar A
Les contacts ont un indice de contact `ic` attribué en séquence à la création du contact et qui les identifie pour toujours relativement à l'avatar A.  
Un avatar A peut avoir pour contact un avatar B avec deux états successifs possibles :
- **simple** (statut 0) : A a B pour contact `15` et B peut avoir ou non A pour contact `57`, ces situations sont autonomes l'une de l'autre et ni A ni B ne savent rien du contact éventuel de l'autre.
- **fort** : A a B pour contact `15`, B a A pour contact `57` : ces numéros de contacts mutuels forts sont connus et immuables de part et d'autre. A peut restreindre la nature de ses échanges avec B mais le contact fort subsiste tant que B n'a pas _disparu_.

Table :

    CREATE TABLE "contact" (
    "id"   INTEGER,
    "ic"	INTEGER,
    "v"  	INTEGER,
    "st" INTEGER,
    "q1" INTEGER,
    "q2" INTEGER,
    "qm1" INTEGER,
    "qm2" INTEGER,
    "ardc"	BLOB,
    "icbc"  BLOB
    "datak"	BLOB,
    "ank"	BLOB,
    PRIMARY KEY("id", "ic")
    );
    CREATE INDEX "id_v_contact" ON "contact" ( "id", "v" );

- `id` : id de l'avatar A
- `ic` : indice de contact de B pour A.
- `v` : 
- `st` : statut entier de 3 chiffres, `x y z` : **les valeurs < 0 indiquent un row supprimé (les champs après sont null)**.
  - `x` : 0: contact présumé actif, 1:disparu
  - `y` : A accepte 1 (ou non 0) les partages de B.
  - `z` : B accepte 1 (ou non 0) les partages de A.
- `q1 q2 qm1 qm2` : balance des quotas donnés / reçus par l'avatar A à l'avatar B (contact _fort_).
- `ardc` : **ardoise** partagée entre A et B cryptée par la clé `cc` associée au contact _fort_ avec un avatar B.
- `icbc` : pour un contact fort _accepté_, indice de A chez B (communiqué lors de l'acceptation par B) pour mise à jour dédoublée de l'ardoise et du statut, crypté par la clé `cc`.
- `datak` : information cryptée par la clé K de A.
  - `nomc` : nom complet de l'avatar `nom@rnd`.
  - `cc` : 32 bytes aléatoires donnant la clé `cc` d'un contact _fort_ avec B (en attente ou accepté).
  - `dlv` : date limite de validité de l'invitation à être contact _fort_ ou du parrainage.
  - `pph` : hash du PBKFD2 de la phrase de parrainage.
- `ank` : annotation cryptée par la clé K du membre
  - `mc` : mots clés
  - `txt` : commentaires (personnel) de A sur B

Un contact **fort**,
- est _accepté_ quand `icbc` est non null.
- est _refusé_ quand `icbc` est null et `ardc` ne l'est pas (raison du refus).
- en _attente d'acceptation_ quand `dlv` n'est pas dépassée : l'invitation peut être accédée étant identifiée par le hash de `cc`, typiquement pour être annulée ou corrigée.
- est _sans réponse_ quand `dlv` est dépassée.

**Un parrainage,**
- _en attente_ : `icbc` est null, `dlv` n'est pas dépassée, `pph` permet d'accéder au parrainage.
- _accepté_ : `icbc` non null. `ardc` contient le message de remerciement.  `dlv` et `phh` sans signification.
- _refusé_ : le row `contact` est supprimé. Il faut / fallait lire la raison du refus dans le row `parrain`.

Un contact est **supprimé** (`st` < 0) :
- soit après refus d'un parrainage ou dépassement de sa `dlv`.
- soit pour un contact simple quand l'avatar l'a jugé explicitement _obsolète_.
- les autres colonnes `ardc icbc datak` sont null.

Un *contact fort* permet de partager par **l'ardoise** un court texte entre A et B pour justifier d'un changement de statut ou n'importe quoi d'autre : en particulier quand A n'accepte pas le partage de secrets avec B par exemple, c'est le seul moyen de passer une courte information mutuelle qui n'encombre pas leurs volumes respectifs.

**Remarques :**
- un contact invité à devenir _fort_ mais avec une réponse de refus (ou dépassement de la `dlv`), reste un contact _simple_.
- le row `contact` d'un avatar _disparu_ reste pour information historique. La carte de visite du contact n'existe plus. L'utilisateur ne peut demander la suppression ce row d'information historique (`st` passe à < 0) que si c'était un contact simple.

## Table `invitgr`. Invitation d'un avatar M par un animateur A à un groupe G
Les invitations restent présentes jusqu'à disparition de l'avatar M : un numéro aléatoire d'invitation `ni` les identifient relativement à l'avatar invité. C'est `invitgr` qui permet à une session d'un compte d'obtenir la liste de ses groupes (en tant qu'invité ou actif).

Pour un couple avatar / groupe il ne peut y avoir qu'au plus une invitation : ceci est garanti par le row `groupe`.

_Remarque_ : L'invitant peut retrouver en session la liste des invitations en cours qu'il a faites : un membre de G avec son indice de membre comme invitant et un statut `invité`.

    CREATE TABLE "invitgr" (
    "id"  INTEGER,
    "ni" INTEGER,
    "v"   INTEGER,
    "dlv"	INTEGER,
    "st"  INTEGER,
    "datap" BLOB,
    "datak" BLOB,
    PRIMARY KEY ("id", "ni"));
    CREATE INDEX "dlv_invitgr" ON "invitgr" ( "dlv");

- `id` : id du membre invité.
- `ni` : numéro d'invitation.
- `v` :
- `dlv` :
- `st` : statut. `xy` : < 0 signifie supprimé (redondance de `st` de `membre`)
  - `x` : 2:invité, 3:actif.
  - `y` : 0:lecteur, 1:auteur, 2:administrateur.
- `datap` : pour une invitation _en cours_, crypté par la clé publique du membre invité, référence dans la liste des membres du groupe `[idg, cleg, im]`.
	- `idg` : id du groupe.
  - `cleg` : clé du groupe.
	- `im` : indice de membre de l'invité dans le groupe.
- `datak` : même données que `datap` mais cryptées par la clé K du compte de l'invité, après son acceptation.
- `ank` : annotation cryptée par la clé K de l'invité
  - `mc` : mots clés
  - `txt` : commentaire personnel de l'invité

**Remarques :**
- tant que l'invitation est en statut _invité_ et que `dlv` n'est pas dépassée, `datap` existe et l'invitation est en attente. 
- le GC ayant détecté un dépassement de `dlv`, _supprime_ le row.
- _acceptation_ : le statut passe à 1, `datap` est null et `datak` contient les informations d'accès. `dlv` est à 99999. `membre` est mis à jour (`st` `ardg`).
- _refus_ : le statut passe négatif, `datap` `datak` `ank` sont null. `membre` est mis à jour (`st` `ardg`).
- _résiliation / disparition_ : `datak` et `datak` sont null, `st` < 0. Le groupe, ses membres et ses secrets sont inaccessibles après résiliation. 
- Dans ce row seuls changent `st` `dlv` `ank`. `datak / datap` sont immuables mais peuvent passer à null en fonction du statut d'appartenance du membre au groupe : `v` est nécessaire pour trapper ces changements.

## Table `invitct` : CP : `id`. Invitation en attente reçue par B de A à établir un contact fort
Un contact *fort* est requis pour partager, un statut, une ardoise, des secrets et s'échanger des quotas.

    CREATE TABLE "invitct" (
    "id"  INTEGER,
    "ni" INTEGER,
    "v"   INTEGER,
    "dlv"	INTEGER,
    "st"  INTEGER,
    "datap" BLOB,
    "datak"  BLOB,
    "ardc"  BLOB)
    PRIMARY KEY ("id", "ni");
    CREATE INDEX "dlv_invitct" ON "invitct" ( "dlv" );

- `id` : id de B.
- `ni` : numéro aléatoire d'invitation en complément de `id`.
- `v`
- `dlv` : la date limite de validité permettant de purger les rencontres (quels qu'en soient les statuts).
- `st` : <= 0: annulée, 0: en attente, 1: acceptée, 2: refusée
- `datap` : données cryptées par la clé publique de B.
	- `nom@rnd` : nom complet de A.
	- `ic` : numéro du contact de A pour B (pour que B puisse écrire le statut et l'ardoise dans `contact` de A). 
  - `cc` : clé `cc` du contact *fort* A / B, définie par A.
- `datak` : même données que `datap` mais cryptées par la clé K de B après acceptation ou refus.
- `ardc` : texte de sollicitation écrit par A pour B et/ou réponse de B (après acceptation ou refus).

**En cas d'acceptation**, B peut, soit créer un contact chez lui pour A quand il n'y en a pas encore, soit récupérer celui existant chez lui pour A s'il l'avait déjà en contact simple, et inscrire les données de A comme contact *fort* chez lui (`st cc ardc icbc`). 
- Chez A il y a mise à jour de `st ardc icbc` avec le remerciement de B dans `ardc`. Le statut `st` du row `invitct` (de B) est à 1. `icbc` est le numéro de contact de A chez B et est inscrit chez A pour permettre la mise à jour dupliquée ultérieure du statut et de l'ardoise.

**En cas de refus**, le contact `ic` chez A reste un contact _simple_, l'ardoise `ardc` contient la raison du refus. Le statut `st` du row `invitct` (de B) est à 2. 

**Si B ne répond pas à temps**, le dépassement de `dlv` dans `contact` de A détecte le cas : le contact `ic` chez A reste un contact _simple_. 

Dans tous les cas le row `invitct` (de B) est supprimé par le GC sur la `dlv`.

A peut annuler une invitation (par sa clé primaire) avant la réponse de B (`st` < 0).

**Quand deux invitations croisées de A pour B et de B pour A sont en cours :**
A par exemple accepte celle de B (avant que B n'ait accepté celle de A).
- il prend la `cc` proposée par B,
- il détruit sa propre invitation pour que B ne puisse pas s'en saisir.

### Table `parrain` : CP `pph`. Parrainage par P de la création d'un compte F 

F est un *inconnu* n'ayant pas encore de compte.

Comme il va y avoir un don de quotas du *parrain* vers son *filleul*, ces deux-là vont avoir un contact *fort* (si F accepte). Toutefois,
- P peut indiquer que son contact est sans partage de secrets.
- F pourra indiquer que son contact est sans partage de secrets.

Le parrain fixe l'avatar filleul (mais pas son compte), donc son nom : le contact _fort_ est préétabli dans `contact` de P. Le filleul établira le sien lors de son acceptation du parrainage.

Un parrainage est identifié par le hash du PBKFD2 de la phrase de parrainage pour être retrouvée par le filleul.

    CREATE TABLE "parrain" (
    "pph"  INTEGER,
    "id" INTEGER,
    "v"   INTEGER,
    "nc" INTEGER,  
    "dlv"  INTEGER,
    "st"  INTEGER,
    "q1" INTEGER,
    "q2" INTEGER,
    "qm1" INTEGER,
    "qm2" INTEGER,
    "datak"  BLOB,
    "datax"  BLOB,
    "ardc"  BLOB,
    PRIMARY KEY("pph")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_parrain" ON "parrain" ( "dlv" );
    CREATE INDEX "id_parrain" ON "parrain" ( "id" );

- `pph` : hash du PBKFD2 de la phrase de parrainage.
- `id` : id du parrain.
- `ic` : numéro de contact du filleul chez le parrain.
- `dlv` : la date limite de validité permettant de purger les parrainages (quels qu'en soient les statuts).
- `st` : 0: annulé par P, 1: en attente de décision de F, 2: accepté par F, 3: refusé par F
- `q1 q2 qm1 qm2` : quotas donnés par P à F en cas d'acceptation.
- `datak` : cryptée par la clé K du parrain, **phrase de parrainage et clé X** (PBKFD2 de la phrase). La clé X figure afin de ne pas avoir à recalculer un PBKFD2 en session du parrain pour qu'il puisse afficher `datax`.
- `datax` : données de l'invitation cryptées par le PBKFD2 de la phrase de parrainage.
  - `nomp` : `nom@rnd` nom complet de l'avatar P.
  - `nomf` : `nom@rnd` : nom complet du filleul F (donné par P).
  - `cc` : clé `cc` générée par P pour le couple P / F.
- `ardc` : cryptée par la clé `cc`, *ardoise*, texte de sollicitation écrit par A pour B et/ou réponse de B.

**La parrain créé par anticipation un contact *fort* pour le filleul**  avec un row `contact`. 
- Les quotas de P sont prélevés à ce moment. 

**Si le filleul ne fait rien à temps : (`st` toujours à 1)** 
- Lors du GC sur la `dlv`, le row `parrain` sera supprimé par GC de la `dlv`. 
- Les quotas donnés par le parrain (`q1 q2 qm1 qm2`) lui sont restitués par le GC qui a l'id du parrain dans `id`.

**Si le filleul refuse le parrainage :** 
- Le row dans `contact` du parrain est marqué avec un `st` < 0 (supprimé), les autres propriétés sont null). 
- L'ardoise du `parrain` renseigne sur la raison de F. 
- Le row `parrain` est immuable et sera purgé par le GC sur `dlv`. 
- Les quotas donnés par P lui sont restitués.

**Si le filleul accepte le parrainage :** 
- Le filleul crée son compte et son premier avatar (dont il a reçu `nom@rnd` et l'indice de P) et créé un contact fort avec P. 
- L'ardoise des `contact` de P et de F contient l'ardoise de l'acceptation (`ardc`).
- Le row `parrain` est immuable et sera purgé par le GC sur `dlv`. 

**Le parrain peut annuler son row :** 
- son `st` passe à 0.
- Les quotas donnés par P lui sont restitués.

Dans tous les cas le GC sur `dlv` supprime le row `parrain`.

## Table `rencontre` : CP `prh`. Rencontre entre les avatars A et B
A et B se sont rencontrés dans la *vraie* vie mais ni l'un ni l'autre n'a les coordonnées de l'autre pour,
- soit s'inviter à créer un contact *fort*,
- soit pour B inviter A à participer à un groupe.

Une rencontre est juste un row qui va permettre à A de transmettre à B son `nom@rnd` en utilisant une phrase de rencontre convenue entre eux.  
En accédant à cette rencontre B pourra inscrire A comme contact *simple* : ensuite il pourra normalement l'inviter à un contact *fort* (ou l'inviter à un groupe).

Une rencontre est identifiée par le hash de la **clé X (PBKFD2 de la phrase de rencontre)**.

    CREATE TABLE "rencontre" (
    "prh" INTEGER,
    "id" INTEGER,
    "v"   INTEGER,
    "dlv" INTEGER,
    "st"  INTEGER,
    "datak" BLOB,
    "nomcx" BLOB,
    PRIMARY KEY("prh")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_rencontre" ON "rencontre" ( "dlv" );
    CREATE INDEX "id_v_rencontre" ON "rencontre" ( "id", "v" );

- `prh` : hash du PBKFD2 de la phrase de rencontre.
- `id` : id de l'avatar A ayant initié la rencontre.
- `v` :
- `dlv` : date limite de validité permettant de purger les rencontres.
- `st` : <= 0:annulée, 1:en attente, 2:acceptée, 3:refusée
- `datak` : **phrase de rencontre et son PBKFD2** (clé X) cryptée par la clé K du compte A pour que A puisse retrouver les rencontres qu'il a initiées avec leur phrase.
- `nomcx` : nom complet de A (pas de B, son nom complet n'est justement pas connu de A) crypté par la clé X.

Si B accepte la rencontre, il créé un contact simple, `st` passe à 2 (permet à A d'en suivre l'évolution).

Si B refuse la rencontre, `st` passe à 3 (permet à A d'en suivre l'évolution).

Le GC sur `dlv` détruit le row `rencontre` (`st` < 0, `datak / nomcx` sont mis à null).

A peut annuler la rencontre (remord), `st` passe à < 0.

## Table `groupe` : CP: `id`. Entête et état d'un groupe
Un groupe est caractérisé par :
- ses quotas et volumes : un row de `avgrvq`,
- son entête : un row de `groupe`.
- la liste de ses membres : des rows de `membre`.
- la liste de ses secrets : des rows de `secret`.

Table :

    CREATE TABLE "groupe" (
    "id"  INTEGER,
    "v"   INTEGER,
    "dds" INTEGER,
    "st"  INTEGER,
    "cvg"  BLOB,
    "mcg"   BLOB,
    "lstmg" BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_v_groupe" ON "groupe" ( "id", "v" );

- `id` : id du groupe.
- `v` : 
- `dds` :
- `st` : statut : < 0-supprimé - Deux chiffres `x y`
  - `x` : 1-ouvert, 2-fermé, 3-ré-ouverture en vote
  - `y` : 0-en écriture, 1-archivé 
- `cvg` : carte de visite du groupe `[photo, info]` cryptée par la clé G du groupe.
- `mcg` : liste des mots clés définis pour le groupe cryptée par la clé du groupe cryptée par la clé G du groupe.
- `lstmg` : liste des ids des membres du groupe.

**L'indice d'un membre**, quel que soit son statut, est son index + 1 dans cette liste et n'y est présent qu'une et une seule fois. Ce row permet un contrôle d'unicité d'attribution de cet indice (ajout à la fin) afin de prémunir contre des inscriptions possiblement parallèles.

## Table `membre` : CP `id nm`. Membre d'un groupe
Chaque membre d'un groupe a une entrée pour le groupe identifiée par son indice de membre `im`.   
Les données relatives aux membres sont cryptées par la clé du groupe.

Table

    CREATE TABLE "membre" (
    "id"  INTEGER,
    "im"	INTEGER,
    "v"		INTEGER,
    "st"	INTEGER,
    "vote"  INTEGER,
    "dlv"   INTEGER,
    "q1"   INTEGER,
    "q2"   INTEGER,
    "datag"	BLOB,
    "ardg"  BLOB,
    "ank"  BLOB,
    PRIMARY KEY("id", "im"));
    CREATE INDEX "id_v_membre" ON "membre" ( "id", "v" );

- `id` : id du groupe.
- `im` : numéro du membre dans le groupe.
- `v` :
- `st` : statut. `xy` : < 0 signifie supprimé.
  - `x` : 1:pressenti, 2:invité, 3:ayant refusé, 3:actif, 8: résilié.
  - `y` : 0:lecteur, 1:auteur, 2:administrateur.
- `vote` : vote de réouverture.
- `dlv` : date limite de validité de l'invitation. N'est significative qu'en statut _invité_.
- `q1 q2` : balance des quotas donnés / reçus par le membre au groupe.
- `datag` : données cryptées par la clé du groupe.
  - `nomc` : nom complet de l'avatar `nom@rnd` (donne la clé d'accès à sa carte de visite)
  - `ni` : numéro d'invitation du membre dans `invitgr` relativement à son `id` (issu de `nomc`). Permet de supprimer son accès au groupe (`st < 0, datap / datak null` dans `invitgr`) quand il est résilié / disparu.
	- `idi` : id du premier membre qui l'a pressenti / invité.
- `ardg` : ardoise du membre vis à vis du groupe. Contient le texte d'invitation puis la réponse de l'invité cryptée par la clé du groupe. Ensuite l'ardoise peut être écrite par le membre (actif) et les animateurs.

**Remarques**
- les membres de statut _invité_ et _actif_ peuvent accéder à la liste des membres et à leur _ardoise_ (ils ont la clé du groupe dans leur row `invitgr`).
- les membres _actif_ accèdent aux secrets. En terme de cryptographie, les membres invités _pourraient_ aussi en lecture (ils ont la clé) mais le serveur l'interdit.
- les membres des statuts _pressenti, ayant refusé, résilié, disparu_ n'ont pas / plus la clé du groupe dans leur row `invitgr`.
- un membre résilié peut être réinvité et conserve le même numéro d'invitation `ni`.

Les animateurs peuvent :
- inviter d'autres avatars à rejoindre la liste.
- changer les statuts des membres non animateurs.
- détruire le groupe.
- attribuer un statut *permanent* à un secret partagé par le groupe.

Les membres du groupe peuvent s'ils sont actifs et auteur / animateur :
- partager un secret avec le groupe,
- modifier un secret du groupe selon le statut du secret : 
  - *ouvert* : tous les *auteurs / animateurs* peuvent le modifier.
  - *restreint* : seul le dernier auteur peut le modifier.
  - *archivé* : le secret ne peut plus changer (jamais).

Un animateur peut lancer quand il veut un nettoyage pour détecter les membres qui auraient disparus *et* ne seraient plus auteurs d'aucuns secrets.

Le row `membre` d'un membre subsiste quand il est _résilié_ ou _disparu_ pour information historique : sa carte de visite reste accessible.

Le GC ne gère pas le dépassement de `dlv`.

## Secrets
Un secret est identifié par l'id du propriétaire (avatar ou groupe) et de `ns` complémentaire aléatoire (pair pour un secret d'avatar, impair pour un secret de groupe).

La clé de cryptage du secret `cs` est selon le cas :
- (0) *secret personnel d'un avatar A* : la clé K de l'avatar. `ic` vaut 0.
- (1) *secret d'un couple d'avatars A et B* : leur clé `cc` de contact fort. `ic` donne l'indice du contact ce qui permet d'obtenir `cc`.
- (2) *secret d'un groupe G* : la clé du groupe G. `ic` vaut 0. `ic` vaut 0.

**Un secret de couple A / B est matérialisé par 2 secrets de même contenu**
- un pour A et un pour B (et la même clé de cryptage, celle `cc` du couple). 
- chaque secret dans ce cas détient la référence de l'autre afin que la mise à jour de l'un puisse être répercutée sur l'autre (quand il existe encore).
- A et B peuvent indépendamment l'un de l'autre détruire leur exemplaire : de facto il n'y a plus de copie synchronisée de l'autre.
- A crée les deux exemplaires du secret en générant deux numéros `ns` afin que la relation entre A et B n'apparaisse pas dans la base.

### Un secret a toujours un texte et possiblement une pièce jointe
Le texte a une longueur maximale de 4000 caractères. L'aperçu d'un secret est constituée des 140 premiers caractères de son texte ou moins (première ligne au plus).

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

Un compte peut faire une requête retournant la liste des avatars ayant accès à un des secrets partagés de ses avatars et disposer de la liste des auteurs qui devraient tous lui être connus (dans un groupe et / ou en tant que contact).

### Secret temporaire et permanent
Par défaut à sa création un secret est *temporaire* :
- son `st` contient le *numéro de semaine de création* indiquant que S semaines plus tard il sera automatiquement détruit.
- un avatar Ai qui le partage peut le déclarer *permanent*, le secret ne sera plus détruit automatiquement :
  - l'avatar propriétaire pour un secret personnel.
  - les deux avatars pour un secret de couple.
  - un des animateurs pour un secret de groupe.

### Décompte du volume des secrets et des pièces jointes
- il est décompté à la création sur le décompte de secrets *créés / modifiés dans le mois* de l'auteur.
- le décompte intervient à chaque modification en plus dans le mois de l'auteur.

Dès que le secret est *permanent* il est décompté (en plus ou en moins à chaque mise à jour) sur le volume du groupe.

## Table `secret` : CP `id ns`. Secret

    CREATE TABLE "secret" (
    "id"  INTEGER,
    "ns"  INTEGER,
    "ic"  INTEGER,
    "v"		INTEGER,
    "st"	INTEGER,
    "txts"	BLOB,
    "ans"   BLOB,
    "aps"	BLOB,
    "dups"	BLOB,
    PRIMARY KEY("id", "ns");
    CREATE INDEX "id_v_secret" ON "secret" ("id", "v");
    CREATE INDEX "st_secret" ON "secret" ( "st" );

- `id` : id du groupe ou de l'avatar.
- `ns` : numéro du secret.
- `ic` : indice du contact pour un secret de couple, sinon 0.
- `v` : 
- `st` : < 0 pour un secret _supprimé_, numéro de semaine de création pour un _temporaire_, 99999 pour un *permanent*.
- `ora` : 0:ouvert, 1:restreint, 2:archivé
- `v1` : volume du texte
- `v2` : volume de la pièce jointe
- `txts` : crypté par la clé du secret.
  - `la` [] : liste des auteurs (identifié par leur indice de membre pour un groupe) ou id du dernier auteur pour un secret de couple.
  - `gz` : texte gzippé
  - `r` : référence à un autre secret (du même groupe, couple, avatar).
- `ans` : 
  - texte d'annotation pour un secret de couple seulement.
  - liste des mots clés crypté par la clé du secret.
- `pjs` : pièce jointe cryptées par la clé du secret (null : pas de pièce jointe)
  - `typ` : type de la pièce jointe : 0 inconnu, 1, 2 ... selon une liste prédéfinie.
  - `v` : version de la pièce jointe afin que l'upload de la version suivante n'écrase pas la précédente.
- `dups` : couple `[id ns]` crypté par la clé du secret de l'autre exemplaire pour un secret de couple A/B.

**Suppression d'un secret :**
- pour un secret temporaire, `st` est mis en négatif : les sessions synchronisées suppriment d'elles-mêmes ces secrets en local avant `st` si elles elles se synchronise avant `st`, sinon ça sera fait à `st`.
- pour un secret permanent, `st` est en négatif au numero de semaine courante + 18 mois.

### Mots clés
Un secret peut apparaître avec plusieurs mots clés indiquant :
- des états : _lus, important, à cacher, à relire, favori ..._
- des éléments de classement fonctionnel : _énergie bio-diversité réchauffement ..._

Le texte d'un mot clé peut contenir des emojis.

Les mots clés sont numérotés avec une conversion entre leur numéro et leur texte :
- 1-49 : pour ceux génériques de l'installation dans la configuration.
- 50-255 : pour ceux spécifiques de chaque compte dans `mc` du row `compte` de son avatar : la map est cryptée par la clé K du compte.
- 50-255 : pour ceux spécifiques de chaque groupe dans `mc` de son row `groupe` : la map est cryptée par la clé G du groupe.

**Pour un secret d'un avatar**
- `mcs` est la suite des numéros de mots clés attachés par l'avatar au secret.

**Pour un secret de couple**
- le secret étant dédoublé, dans chaque exemplaire `mcs` est la suite des numéros de mots clés attachés par l'avatar au secret.

**Pour un secret de groupe**
- `mcs` est la suite des numéros de mots clés attachés par un des animateurs du groupe au secret.

## Table `secran` : CP `id, ns, im`. Annotation d'un secret de groupe

    CREATE TABLE "secran" (
    "id"  INTEGER,
    "ns"  INTEGER,
    "im"  INTEGER,
    "v"		INTEGER,
    "ank" BLOB,
    PRIMARY KEY("id", "ns", "im");
    CREATE INDEX "id_v_secran" ON "secran" ("id", "v", "im");

- `id` : id du groupe.
- `ns` : numéro du secret.
- `im` : indice du membre.
- `v` : 
- `ank` : annotation cryptée par la clé K du membre
  - `mc` : mots clés
  - `txt` : commentaires du membre

# Gestion des disparitions
Les ouvertures de session *signent* dans les tables `compte avatar groupe`, colonne `dds`, les rows relatifs aux compte, avatars du compte et groupes accédés par le compte.

Une disparition est détectée dès lors que le GC quotidien détecte des `dds` trop vieilles.

## Disparition des comptes
La détection par `dds` trop ancienne d'un **compte** détruit son row dans `compte`.

Un compte est toujours détruit physiquement avant ses avatars puisqu'il apparaît plus ancien que ses avatars dans l'ordre des signatures.

Le compte n'étant plus accessible, ses avatars ne seront plus signés ni les groupes auxquels il accédait.

## Disparition des groupes
Par construction s'il avait existé encore un avatar dont l'accès au groupe n'est pas résilié, le groupe aurait été signé lors de la connexion du compte de cet avatar : un groupe de signature ancienne n'est donc par principe plus référencé (au plus par des rows `invitgr` conservés pour historique mais marqué _résilié_).

La détection par `dds` trop ancienne d'un **groupe**,
- détruit ses rows dans les tables `groupe membre secret`.
- transfère ses quotas de son row `avgrvq` sur la banque centrale et détruit son row `avgrvq`.

_Remarque_ : quand le dernier avatar ayant accès à un groupe _disparaît_, le groupe va finir par disparaître faute de ne plus être signé. Les données vont finir par être purgées, mais ça va prendre du temps. Avec la résiliation explicitement demandée (suppression du groupe), c'est différent : la purge des données ci-dessus peut être immédiate.

## Disparition des avatars
La détection s'effectue par le GC quotidien sur recherche des `dds` trop ancienne dans la table `avatar`.

Par principe un avatar est détecté disparu après la détection de la disparition de son compte. Il s'agit donc de purger les données.

### Purge des données identifiées par l'id de l'avatar
- transfert de ses quotas depuis son row `avgrvq` sur la banque et destruction de son row `avgrvq`.
- destruction des rows les tables `avrsa avatar contact invitct invitgr parrain rencontre secret`.

Dès cet instant le volume occupé est récupéré.

### Mise à jour des références chez les autres comptes
L'avatar _disparu_ D reste toutefois encore _référencé_ dans des rows :
- `parrain rencontre invitct invitgr` : la date limite de validité a déjà résolu la question, les rows ont _déjà_ été détruits.
- `avatar contact` : autres avatars l'ayant en contact.
- `groupe membre` : groupes l'ayant pour membre.  

#### contacts
Quand une session d'un avatar A synchronise les cartes de visite elle a connaissance par la carte de visite de D que cet avatar a disparu : le row `contact` correspondant a son statut mis à jour (disparu). 

Il n'y a pas de raisons pour que les secrets partagés avec D (et dédoublés) disparaissent aussi.

Le row contact garde une trace historique mais sur demande du compte, un contact _disparu_ peut être _oublié_ :
- le row `contact` a un statut supprimé (`st` < 0).
- tous les `secret` de l'avatar portant ce numéro de contact sont détruits (et l'avatar crédité des volumes supprimés).

#### membres
Pour chaque groupe accédé par l'avatar :
- le row `membre` de D (s'il existe) a son statut mis à jour à _disparu_. 
- sur demande d'un compte animateur du groupe, le row pourrait être marqué _supprimé_ pour _nettoyer_ la liste des membres : mais des secrets du groupe peuvent continuer à référencer ce membre comme auteur. Ne pas nettoyer dans ce cas ?

Dans la session la carte de visite est supprimée, elle ne sera plus synchronisée.

Les références peuvent mettre longtemps a être mises à jour, tous les comptes référençant l'avatar D ayant à être ouverts (ou disparaissant eux-mêmes).

# Base vivante et de backup ???
La base de backup est l'image de la base vivante la veille au soir.
- elle est accessible en lecture seule.
- la table versions permet de savoir jusqu'à quelles versions elle a été sauvée.

En début de session un compte *peut* avoir des jours / semaines / mois à rattraper, voire tout si la session est en mode incognito : une grande masse de rows peuvent être lus depuis le backup sans bloquer la base vivante. 

Comment savoir s'il est opportun de faire deux passes ou une seule directement sur la base vivante ?.

La vraie connexion / synchronisation se fait sur la base vivante pour avoir les toutes dernières mises à jour mais ça devrait être très léger.

