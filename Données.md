# Boîtes à secrets - Modèle de données

## Identification des entités

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
Le **nom complet** d'un avatar ou d'un groupe est un string de la forme `[nom@rnd]`
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

- `compte` (id) : authentification et liste des avatars d'un compte 
- `prefs` (id) : données et préférences d'un compte 
- `avatar` (id) : données d'un avatar et liste de ses contacts
- `invitgr` (id, ni) : invitation reçue par un avatar à devenir membre d'un groupe
- `contact` (id, ic) : données d'un contact d'un avatar    
- `invitct` (id, ni) : invitation reçue à lier un contact fort avec un autre avatar  
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
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;

**Opération mensuelle**  
Les volumes mensuels sont mis à 0 le premier de chaque mois à minuit. Le cas échéant l'occasion de sortir des statistiques sur un fichier `xls`. 

## Table : `compte` CP `id`. Authentification d'un compte
_Phrase secrète_ : une ligne 1 de 16 caractères au moins et une ligne 2 de 16 caractères au moins.  
`pcb` : PBKFD de la phrase complète (clé X) - 32 bytes.  
`dpbh` : hashBin (53 bits) du PBKFD du début de la phrase secrète (32 bytes).

Table :

    CREATE TABLE "compte" (
    "id"	INTEGER,
    "v"		INTEGER,
    "dds" INTEGER,
    "dpbh"	INTEGER,
    "pcbh"	INTEGER,
    "kx"   BLOB,
    "mack"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE UNIQUE INDEX "dpbh_compte" ON "compte" ( "dpbh" )
	
- `id` : id du compte.
- `v` :
- `dds` : date (jour) de dernière signature.
- `dpbh` : hashBin (53 bits) du PBKFD du début de la phrase secrète (32 bytes). Pour la connexion, l'id du compte n'étant pas connu de l'utilisateur.
- `pcbh` : hashBin (53 bits) du PBKFD de la phrase complète pour quasi-authentifier une connexion avant un éventuel échec de décryptage de `kx`.
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
- le row `compte` change très rarement : à l'occasion de l'ajout / suppression d'un avatar et d'un changment de phrase secréte.

## Table : `prefs` CP `id`. Préférences et données d'un compte
Afin que le row compte qui donne la liste des avatars ne soit mis à jour que rarement, les données et préférences associées au compte sont mémorisées dans une autre table :
- chaque type de données porte un code court :
  - `mp` : mémo personnel du titulaire du compte.
  - `mc` : mots clés du compte.
  - `fs` : filtres des secrets.
- le row est juste un couple `[id, map]` où map est la sérialisation d'une map ayant :
  - une entrée pour chacun des codes courts ci-dessus : la map est donc extensible sans modification du serveur.
  - pour valeur la sérialisation cryptée par la clé K du compte de l'objet Javascript en donnant le contenu.
- le row est chargé lors de l'identification du compte, conjointement avec le row compte.
- une mise à jour ne correspond qu'à un seul code court afin de réduire le risque d'écrasements entre sessions parallèles/

Table :

    CREATE TABLE "compte" (
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
    "lgrk" BLOB,
    "vsh"	INTEGER,
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
- `lctk` : liste, cryptée par la clé K du compte, des couples `[id, ic]` des contacts de l'avatar afin de garantir l'unicité de ceux-ci.
- `lgrk` : map :
  - _clé_ : `ni`, numéro d'invitation (aléatoire 4 bytes) obtenue sur invitgr.
  - _valeur_ : cryptée par la clé K du compte du triplet `[nom, rnd, im]` reçu sur `invitgr` et inscrit à l'acceptation de l'invitation.
  - une entrée est effacée par la résiliation du membre au groupe, sur refus de l'invitation et dépassement de la `dlv` (ce qui lui empêche de continuer à utiliser la clé du groupe).
- `vsh`

La lecture de avatar permet d'obtenir les deux listes de ses contacts et des groupes dont il est membre.

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
    "mc"  BLOB,
    "infok"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id", "ic")
    );
    CREATE INDEX "id_v_contact" ON "contact" ( "id", "v" );

- `id` : id de l'avatar A
- `ic` : indice de contact de B pour A.
- `v` :
- `st` : statut entier de 3 chiffres, `x y z` : **les valeurs < 0 indiquent un row supprimé (les champs après sont null)**.
  - `x` : 0: contact présumé actif, 2:disparu
  - `y` : A accepte 1 (ou non 0) les partages de B.
  - `z` : B accepte 1 (ou non 0) les partages de A.
- `q1 q2 qm1 qm2` : balance des quotas donnés / reçus par l'avatar A à l'avatar B (contact _fort_).
- `ardc` : **ardoise** partagée entre A et B cryptée par la clé `cc` associée au contact _fort_ avec un avatar B.
- `icbc` : pour un contact fort _accepté_, indice de A chez B (communiqué lors de l'acceptation par B) pour mise à jour dédoublée de l'ardoise et du statut, crypté par la clé `cc`.
- `datak` : information cryptée par la clé K de A.
  - `nom rnd` : nom complet de l'avatar.
  - `cc` : 32 bytes aléatoires donnant la clé `cc` d'un contact _fort_ avec B (en attente ou accepté). Le hash de `cc` est **le numéro d'invitation** `ni` retrouvé en clé de invitct correspondant.
  - `dlv` : date limite de validité de l'invitation à être contact _fort_ ou du parrainage.
  - `pph` : hash du PBKFD de la phrase de parrainage.
- `mc` : mots clés à propos du contact.
- `infok` : commentaire à propos du contact crypté par la clé K du membre.
- `vsh`

Un contact **fort**,
- est encore en _attente d'acceptation_ quand `icbc` et `ardc` sont null et `dlv` n'est pas dépassée : l'invitation peut être accédée étant identifiée par le hash de `cc` pour être annulée.
- est _accepté_ quand `icbc` est non null. `ardc` contient le message de remerciement. `dlv` sans signification.
- est _refusé_ quand `icbc` est null et `ardc` ne l'est pas (raison du refus de B).
- est _sans réponse_ quand `icbc` et `ardc` sont null et `dlv` est dépassée.

**Un parrainage,**
- est encore _en attente d'acceptation_ quand `icbc` et `ardc` sont null et `dlv` n'est pas dépassée : `pph` permet d'accéder au parrainage pour le supprimer.
- _accepté refusé sans réponse_, comme contact **fort**.

Un contact est **supprimé** (`st` < 0) :
- soit après refus d'un parrainage après dépassement de sa `dlv`.
- soit pour un contact simple quand l'avatar l'a jugé explicitement _obsolète_.
- les autres colonnes `ardc icbc datak ank` sont null.

Un *contact fort* permet de partager par **l'ardoise** un court texte entre A et B pour justifier d'un changement de statut ou n'importe quoi d'autre : en particulier quand A n'accepte pas le partage de secrets avec B par exemple, c'est le seul moyen de passer une courte information mutuelle qui n'encombre pas leurs volumes respectifs.

**Remarques :**
- un contact invité à devenir _fort_ mais avec une réponse de refus (ou dépassement de la `dlv`), reste un contact _simple_.
- le row `contact` d'un avatar _disparu_ reste pour information historique. La carte de visite du contact n'existe plus. L'utilisateur ne peut demander la suppression ce row d'information historique (`st` passe à < 0) que si c'était un contact simple.

## Table `invitct` : CP : `id`. Invitation en attente reçue par A de B à établir un contact fort
Un contact *fort* est requis pour partager, un statut, une ardoise, des secrets et s'échanger des quotas.

    CREATE TABLE "invitct" (
    "id"  INTEGER,
    "ni" INTEGER,
    "v"   INTEGER,
    "dlv"	INTEGER,
    "st"  INTEGER,
    "datap" BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY ("id", "ni");
    CREATE INDEX "dlv_invitct" ON "invitct" ( "dlv" );

- `id` : id de A.
- `ni` : numéro aléatoire d'invitation en complément de `id` (généré par B).
- `v` :
- `dlv` : la date limite de validité permettant de purger les rencontres (quels qu'en soient les statuts).
- `st` : <= 0: annulée, 0: en attente
- `datap` : données cryptées par la clé publique de B.
  - `nom rnd` : nom complet de B.
  - `ic` : index de A dans la liste des contacts de B (pour que A puisse écrire le statut et l'ardoise dans `contact` de B). 
  - `cc` : clé `cc` du contact *fort* A / B, définie par B.
- `vsh`

**En cas d'acceptation par A**, A peut, soit créer un contact chez lui pour B quand il n'y en a pas encore, soit récupérer celui existant chez lui pour B s'il l'avait déjà en contact simple, et inscrire les données de B comme contact *fort* chez lui (`st cc ardc icbc`). 
- Dans le contact de A pour B, mise à jour de `st ardc icbc` avec le remerciement de A dans `ardc`. `invitct` est supprimé mais A a désormais B dans ses contacts.

**En cas de refus par A**, le contact `ic` de A chez B reste un contact _simple_, l'ardoise `ardc` contient la raison du refus. Le statut `st` du row contact de A chez B est 2 (refusé) et l'ardoise donne la raison donnée par A. `invitct` de A est détruit. 

**Si A ne répond pas à temps**, le dépassement de `dlv` dans `contact` de B détecte le cas : le contact `ic` de A chez B reste un contact _simple_. 

Dans tous les cas le row `invitct` de A est supprimé par le GC sur la `dlv`.

B peut annuler une invitation (par sa clé primaire) avant la réponse de A (`st` < 0).

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

Un parrainage est identifié par le hash du PBKFD de la phrase de parrainage pour être retrouvée par le filleul.

    CREATE TABLE "parrain" (
    "pph"  INTEGER,
    "id" INTEGER,
    "v"   INTEGER,
    "dlv"  INTEGER,
    "st"  INTEGER,
    "q1" INTEGER,
    "q2" INTEGER,
    "qm1" INTEGER,
    "qm2" INTEGER,
    "datak"  BLOB,
    "datax"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("pph")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_parrain" ON "parrain" ( "dlv" );
    CREATE INDEX "id_parrain" ON "parrain" ( "id" );

- `pph` : hash du PBKFD de la phrase de parrainage.
- `id` : id du parrain.
- `v`
- `dlv` : la date limite de validité permettant de purger les parrainages (quels qu'en soient les statuts).
- `st` : <0: annulé par P, 0: en attente de décision de F
- `q1 q2 qm1 qm2` : quotas donnés par P à F en cas d'acceptation.
- `datak` : cryptée par la clé K du parrain, **phrase de parrainage et clé X** (PBKFD de la phrase). La clé X figure afin de ne pas avoir à recalculer un PBKFD en session du parrain pour qu'il puisse afficher `datax`.
- `datax` : données de l'invitation cryptées par le PBKFD de la phrase de parrainage.
  - `nomp, rndp` : nom complet de l'avatar P.
  - `nomf, rndf` : nom complet du filleul F (donné par P).
  - `cc` : clé `cc` générée par P pour le couple P / F.
  - `ic` : numéro de contact du filleul chez le parrain.
- `vsh`

**La parrain créé par anticipation un contact *fort* pour le filleul**  avec un row `contact`. 
- Les quotas de P sont prélevés à ce moment. 

**Si le filleul ne fait rien à temps : (`st` toujours à 0)** 
- Lors du GC sur la `dlv`, le row `parrain` sera supprimé par GC de la `dlv`. 
- Les quotas donnés par le parrain (`q1 q2 qm1 qm2`) lui sont restitués par le GC qui a l'id du parrain dans `id`.

**Si le filleul refuse le parrainage :** 
- Le row dans `contact` du parrain, son `icbc` y est null mais son ardoise `ardc` indique la raison du refus. 
- Le row `parrain` est supprimé. 
- Les quotas donnés par P lui sont restitués.

**Si le filleul accepte le parrainage :** 
- Le filleul crée son compte et son premier avatar (dont il a reçu `nom@rnd` et l'indice de P) et créé un contact fort avec P. 
- L'ardoise des `contact` de P et de F contient l'ardoise de l'acceptation (`ardc`).
- Le row `parrain` est supprimé. 

**Le parrain peut annuler son row :** 
- son `st` passe à <0.
- Les quotas donnés par P lui sont restitués.

Dans tous les cas le GC sur `dlv` supprime le row `parrain`.

## Table `rencontre` : CP `prh`. Rencontre entre les avatars A et B
A et B se sont rencontrés dans la *vraie* vie mais ni l'un ni l'autre n'a les coordonnées de l'autre pour,
- soit s'inviter à créer un contact *fort*,
- soit pour B inviter A à participer à un groupe.

Une rencontre est juste un row qui va permettre à A de transmettre à B son `nom@rnd` en utilisant une phrase de rencontre convenue entre eux.  
En accédant à cette rencontre B pourra inscrire A comme contact *simple* : ensuite il pourra normalement l'inviter à un contact *fort* (ou l'inviter à un groupe).

Une rencontre est identifiée par le hash de la **clé X (PBKFD de la phrase de rencontre)**.

    CREATE TABLE "rencontre" (
    "prh" INTEGER,
    "id" INTEGER,
    "v"   INTEGER,
    "dlv" INTEGER,
    "st"  INTEGER,
    "datak" BLOB,
    "nomcx" BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("prh")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_rencontre" ON "rencontre" ( "dlv" );
    CREATE INDEX "id_v_rencontre" ON "rencontre" ( "id", "v" );

- `prh` : hash du PBKFD de la phrase de rencontre.
- `id` : id de l'avatar A ayant initié la rencontre.
- `v` :
- `dlv` : date limite de validité permettant de purger les rencontres.
- `st` : < 0:annulée, 0:en attente, 1:contact simple récupéré par B, 2:contact refusé
- `datak` : **phrase de rencontre et son PBKFD** (clé X) cryptée par la clé K du compte A pour que A puisse retrouver les rencontres qu'il a initiées avec leur phrase.
- `nomcx` : nom complet `[nom, rnd]` de A (pas de B, son nom complet n'est justement pas connu de A) crypté par la clé X.
- `vsh`

Si B accepte la rencontre, il créé un contact simple, `st` passe à 2 (permet à A d'en suivre l'évolution ???).

Si B refuse la rencontre, `st` passe à 2 (permet à A d'en suivre l'évolution ???).

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
    "lmbg" BLOB,
    "vsh"	INTEGER,
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
- `lmbg` : liste des ids des membres (possiblement seulement pressentis / invités) du groupe. L'indice dans la liste est leur `im`.
- `vsh`

**L'indice d'un membre** (2 bytes), quel que soit son statut, est repris dans cette liste et n'y est présent qu'une et une seule fois. Ce row permet un contrôle d'unicité d'attribution de cet indice afin de prémunir contre des inscriptions possiblement parallèles.

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
    "vsh"	INTEGER,
    PRIMARY KEY ("id", "ni"));
    CREATE INDEX "dlv_invitgr" ON "invitgr" ( "dlv");

- `id` : id du membre invité.
- `ni` : numéro d'invitation.
- `v` :
- `dlv` :
- `st` : statut.  < 0 signifie supprimé. 0: invité.
- `datap` : crypté par la clé publique du membre invité.
	- `nom rnd` : nom complet du groupe (donne sa clé).
	- `im` : indice de membre de l'invité dans le groupe.
  - `idi` : id du membre invitant.
  - `p` : 0:lecteur, 1:auteur, 2:administrateur.
- `vsh`

**L'acceptation d'une invitation inscrit `[nom, rnd, im]` dans la liste des groupes de l'avatar `lgrk`.**

**Remarques :**
- tant que l'invitation est en statut _invité_ et que `dlv` n'est pas dépassée, `datap` existe et l'invitation est en attente. 
- le GC ayant détecté un dépassement de `dlv`, _supprime_ le row.
- _acceptation_ : le statut passe à 1, `datap` est null et `datak` contient les informations d'accès. `dlv` est à 99999. `membre` est mis à jour (`st` `ardg`).
- _refus_ : le statut passe négatif, `datap` `datak` `ank` sont null. `membre` est mis à jour (`st` `ardg`).
- _résiliation / disparition_ : `datak` et `datak` sont null, `st` < 0. Le groupe, ses membres et ses secrets sont inaccessibles après résiliation. 
- Dans ce row seuls changent `st` `dlv` `ank`. `datak / datap` sont immuables mais peuvent passer à null en fonction du statut d'appartenance du membre au groupe : `v` est nécessaire pour trapper ces changements.

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
    "mc"  BLOB,
    "infok" BLOB,
    "datag"	BLOB,
    "ardg"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id", "im"));
    CREATE INDEX "id_v_membre" ON "membre" ( "id", "v" );

- `id` : id du groupe.
- `im` : numéro du membre dans le groupe.
- `v` :
- `st` : statut. `xp` : < 0 signifie supprimé.
  - `x` : 1:pressenti, 2:invité, 3:ayant refusé, 3:actif (invitation acceptée), 8: résilié.
  - `p` : 0:lecteur, 1:auteur, 2:administrateur.
- `vote` : vote de réouverture.
- `q1 q2` : balance des quotas donnés / reçus par le membre au groupe.
- `mc` : mots clés du membre à propos du groupe.
- `infok` : commentaire du membre à propos du groupe crypté par la clé K du membre.
- `datag` : données cryptées par la clé du groupe.
  - `nom, rnd` : nom complet de l'avatar.
  - `ni` : numéro d'invitation du membre dans `invitgr`. Permet de supprimer supprimer l'invitation et d'effacer le groupe dans son avatar (`lmbk`).
  - `dlv` : date limite de validité de l'invitation. N'est significative qu'en statut _invité_.
	- `idi` : id du premier membre qui l'a pressenti / invité.
- `ardg` : ardoise du membre vis à vis du groupe. Contient le texte d'invitation puis la réponse de l'invité cryptée par la clé du groupe. Ensuite l'ardoise peut être écrite par le membre (actif) et les animateurs.
- `vsh`

**Remarques**
- un membre _pressenti_ a un row `membre` mais `datag.dlv` est 0 et `datak` null.
- un membre _invité_ a un row `membre`, `datag.dlv` non 0 et `datak` null.
- quand un membre `invité` accepte l'invitation,
  - dans son row avatar, `lmbk` a un item de plus (de clé `ni`) contenant le nom complet du groupe et l'indice membre `im` de l'avatar (crypté par sa clé K). `datag.dlv` est 0, `datak` est non null
- les membres de statut _invité_ et _actif_ peuvent accéder à la liste des membres et à leur _ardoise_ (ils ont la clé du groupe dans leur row `invitgr`).
- les membres _actif_ accèdent aux secrets. En terme de cryptographie, les membres invités _pourraient_ aussi en lecture (ils ont reçu la clé dans l'invitation) mais le serveur l'interdit.
- les membres des statuts _pressenti, ayant refusé, résilié, disparu_ n'ont pas / plus la clé du groupe dans leur row `avatar` (`lmbk`). `datak` est null, `dlv` et `ni` sont à 0.
- un membre résilié peut être réinvité, le numéro d'invitation `ni` sera tiré au sort à nouveau.

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

Le row `membre` d'un membre subsiste quand il est _résilié_ ou _disparu_ pour information historique du groupe: sa carte de visite reste accessible.

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

**Un secret personnel** créé par A partagé avec personne peut être mis à jour :
- par A si le statut du secret est *ouvert* ou *restreint*.
- par personne si le statut du secret est *archivé*.

**Un secret de couple** créé par A partagé avec B (contact *fort* de A) peut être mis à jour :
- par A si le statut du secret est *ouvert* ou *restreint*.
- par B si statut est *ouvert*.
- par personne si le statut du secret est *archivé*.

**Un secret de groupe** créé par un animateur ne peut être modifié que par des auteurs et animateurs :
- chacun est repéré par son im (indice de membre de 1 à 255).
- si le statut est 
  - *ouvert* tout animateur ou auteur peut le mettre à jour.
  - *restreint* par le dernier membre l'ayant modifié, mais un animateur peut changer le statut.
  - *archivé* par personne, mais un animateur peut changer le statut.
- la liste des auteurs est une suite des ids des auteurs successifs. Quand un auteur modifie le texte,
  - il est enlevé de la liste s'il y était,
  - il est placé en tête de la liste.

### Secret temporaire et permanent
Par défaut à sa création un secret est *temporaire* :
- son `st` contient la *date limite de validité* indiquant qu'il sera automatiquement détruit à cette échéance.
- un secret temporaire peut être prolongé, tout en restant temporaire.
- un avatar Ai qui le partage peut le déclarer *permanent*, le secret ne sera plus détruit automatiquement et par convention son `st` est égal à `99999`:
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
    CREATE INDEX "st_secret" ON "secret" ( "st" );

- `id` : id du groupe ou de l'avatar.
- `ns` : numéro du secret.
- `ic` : indice du contact pour un secret de couple, sinon 0.
- `v` :
- `st` :
  - < 0 pour un secret _supprimé_.
  - 99999 pour un *permanent*.
  - `dlv` pour un _temporaire_.
- `ora` : 0:ouvert, 1:restreint, 2:archivé
- `v1` : volume du texte
- `v2` : volume de la pièce jointe
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
- `refs` : référence vers un autre secret cryptée par la clé du secret.
- `vsh`

**Suppression d'un secret :**
`st` est mis en négatif : les sessions synchronisées suppriment d'elles-mêmes ces secrets en local avant `st` si elles elles se synchronise avant `st`, sinon ça sera fait à `st`.

**Référence à un autre secret**
- la référence est immuable, donnée à la création. Elle permet de définir des secrets liés entre eux, se rapportant au même sujet.
- un secret _premier_ n'a pas de ref. Les secrets seconds ont le premier pour référence.
- **le secret premier est de groupe**. Les secrets seconds peuvent être 
  - soit du même groupe. Leur référence est de la forme `[nsg]`
  - soit des secrets personnels d'un avatar. Leur référence est de la forme `[idg, nsg]`
- **le secret premier est de couple**. Les secrets seconds peuvent être 
  - soit du même couple. Leur référence est de la forme `[ns1, ns2]`
  - soit des secrets personnels d'un avatar. Leur référence est de la forme `[idc, nsc]`, référence vers le secret du couple correspondant à l'avatar qui le référence.
- **le secret premier est personnel**. Les secrets seconds ne peuvent être 
  que des secrets personnels du même avatar. Leur référence est de la forme `[nsp]`.

### Pièces jointes
Une pièce jointe est identifiée par : `nom.ext/type/dh`
- le `nom.ext` d'une pièce jointe est un nom de fichier, d'où un certain nombre de caractères interdits (dont le `/`). Quand le texte a été gzippé par l'application, le nom est `nom.ext.gz`.
- `type` est le MIME type du fichier d'origine.
- `dh` est la date-heure d'enregistrement de la pièce jointe.

**Map des pièces jointes :**
- _clé_ : hash (court) de `nom.ext` en base64 URL. Permet d'effectuer des remplacements par une version ultérieure.
- _valeur_ : `[idc, taille]`
  - `idc` : id complète de la pièce jointe (`nom.ext|type|dh`), cryptée par la clé du secret et en base64 URL.
  - `taille` : en bytes, avant gzip éventuel.

**Identifiant de stockage :** `org/sid@sid2/cle@idc`  
- `org` : code de l'organisation.
- `sid` : id du secret en base64 URL.
- `sid2` : ns du secret en base64 URL.
- `cle` : hash court en base64 URL de nom.ext
- `idc` : id complète de la pièce jointe, cryptée par la clé du secret et en base64 URL.

_Une nouvelle version_ d'une pièce jointe est stockée sur support externe **avant** d'être enregistrée dans son secret.
- _l'ancienne version_ est supprimée du support externe **après** enregistrement dans le secret.
- les versions crées par anticipation et non validées dans un secret comme celles qui n'ont pas été supprimées après validation du secret, peuvent être retrouvées par un traitement périodique de purge qui peut s'exécuter en ignorant les noms et date-heures des fichiers scannés.

> Le contenu d'une pièce jointe sur stockage externe est crypté par la clé du secret.

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

