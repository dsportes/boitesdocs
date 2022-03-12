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
- `avatar` (id) : données d'un avatar et liste de ses contacts
- `invitct` (id, ni) : invitation reçue par un avatar à former un couple de contacts avec un autre avatar
- `couple` (id) : données d'un couple de contacts entre deux avatars    
- `rencontre` (prh) id : communication par A de son nom complet à un avatar B non connu de A dans l'application
- `parrain` (pph) id : parrainage par un avatar A de la création d'un nouveau compte
- `groupe` (id) : données du groupe
- `invitgr` (id, ni) : invitation reçue par un avatar à devenir membre d'un groupe
- `membre` (id, im) : données d'un membre du groupe
- `secret` (id, ns) : données d'un secret d'un avatar, couple ou groupe

## Singletons id / valeur
Ils sont identifiés par un numéro de singleton.  
- Leur valeur est un BLOB, qui peut être un JSON en UTF8.  
- Le singleton 0 est un JSON libre utilisé pour stocker l'état du serveur (dernière sauvegarde, etc.).  
- C'est la table `versions` qui les stocke.

## Table `versions` - CP : `id`

Au lieu d'un compteur par avatar / couple / groupe / compte on a 100 compteurs, un compteur pour plusieurs avatars / groupe (le reste de la division de l'id par 99 + 1). Le compteur 0 est celui de la séquence universelle.

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
    "mack"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE UNIQUE INDEX "dpbh_compte" ON "compte" ( "dpbh" );

- `id` : id du compte.
- `v` :
- `dpbh` : hashBin (53 bits) du PBKFD du début de la phrase secrète (32 bytes). Pour la connexion, l'id du compte n'étant pas connu de l'utilisateur.
- `pcbh` : hashBin (53 bits) du PBKFD de la phrase complète pour quasi-authentifier une connexion avant un éventuel échec de décryptage de `kx`.
- `kx` : clé K du compte, cryptée par la X (phrase secrète courante).
- `mack` {} : map des avatars du compte cryptée par la clé K. Clé: id, valeur: `[nom, rnd, cpriv]`
  - `nom rnd` : nom et clé de l'avatar.
  - `cpriv` : clé privée asymétrique.
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

## Table `compta` : CP `id`. Ligne comptable d'un compte
Il y a une ligne par compte, l'id étant l'id du compte. `idp` est l'id du parrain pour un filleul : un parrain a donc `null` dans cette colonne.

**L'ardoise** est une zone de texte partagé entre le titulaire du compte et les comptes comptables : elle est cryptée _soft_ c'est à dire avec une clé figurant dans le code source, ce qui empêche juste de lire le texte en base de données. Rien de confidentiel ne doit y figurer.

Table :

    CREATE TABLE "compta" (
    "id"	INTEGER,
    "idp"	INTEGER,
    "refp"  BLOB,
    "reff"  BLOB,
    "v"	INTEGER,
    "dds"	INTEGER,
    "st"	INTEGER,
    "dst" INTEGER,
    "data"	BLOB,
    "dhard" INTEGER,
    "ard" BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "idp_compta" ON "compta" ( "idp" );
    CREATE INDEX "dds_compta" ON "compta" ( "dds" );
    CREATE INDEX "st_compta" ON "compta" ( "st" ) WHERE "st" > 0;

- `id` : du compte.
- `idp` : pour un filleul, id du parrain (null pour un parrain).
- `refp` : id du couple avec le filleul cryptée par la clé K du parrain (null pour un parrain).
- `reff` : id du couple avec le parrain cryptée par la clé K du filleul (null pour un parrain).
- `v` :
- `dds` : date de dernière signature du compte (dernière connexion). Un compte en sursis ou bloqué ne signe plus, sa disparition physique est déjà programmée.
- `st` :
  - 0 : normal.
  - 1 : en sursis 1.
  - 2 : en sursis 2.
  - 3 : bloqué.
- `dst` : date du dernier changement de st.
- `data`: compteurs sérialisés (non cryptés)
- `dard` : date-heure de dernière écriture sur l'ardoise.
- `ard` : texte de l'ardoise _crypté soft_.
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

### Table `avatar` : CP `id`. Données d'un avatar
Chaque avatar a un row dans cette table :
- donne son statut de disparition,
- sa dernière signature de connexion,
- sa carte de visite,
- la liste de ses groupes (avec leur nom et clé).
- la liste des couples dont il fait partie (avec leur clé).

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
    "cva"	BLOB,
    "lgrk" BLOB,
    "lcck"  BLOB,
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
- `cva` : carte de visite de l'avatar cryptée par la clé de l'avatar `[photo, info]`.
- `lgrk` : map :
  - _clé_ : `ni`, numéro d'invitation (aléatoire 4 bytes) obtenue sur `invitgr`.
  - _valeur_ : cryptée par la clé K du compte de `[nom, rnd, im]` reçu sur `invitgr`.
  - une entrée est effacée par la résiliation du membre au groupe ou sur refus de l'invitation (ce qui lui empêche de continuer à utiliser la clé du groupe).
- `lcck` : map :
  - _clé_ : `ni`, numéro d'invitation (aléatoire 4 bytes) obtenue à la création ou prise de contact.
    - un `ni` impair signifie que l'avatar est représentée par la partie (1) du couple, sinon c'est la partie (2).
  - _valeur_ : cryptée par la clé K du compte de la clé du couple `cc`.
- `vsh`

La lecture de `avatar` permet d'obtenir,
- la liste des groupes dont il est membre,
- la liste des couples dont il fait partie.

Sur GC quotidien sur `dds` : 
- mise à jour du statut `st` : jour (en négatif) de sa disparition logique.
- purge / suppression des rows `secret parrain rencontre avrsa` pour les disparus.

### Table `couple` : CP id. Couple de deux avatars
Deux avatars A1 et A2 peuvent décider de former un **couple** dès lors que A1 a pris contact avec A2 et que A2 a accepté :
- un couple constitué cesse d'exister quand :
  - les deux avatars sont détectés disparus,
  - l'un _puis_ l'autre ont décidé de rompre.
- dans le cas d'une rupture explicite de A1 (par exemple) ou de sa disparition, A2 reste le seul dans le couple : 
  - il conserve l'accès aux secrets du couple.
  - le couple disparaît si A2 décide de quitter le couple ou qu'il disparaît à son tour.
- A1 et A2 peuvent au cours du temps ou à un instant donné, former plus d'un couple (pourquoi pas un couple _amical_ et un couple _professionnel_).
- un couple qui a été formé (ou pris contact) entre 2 avatars A1 et A2 ne peut jamais se reformer avec un troisième avatar A3.

**Signature de début de session**  
En début de session l'avatar A1 (par exemple) signe son accès au couple qui restera donc vivant pendant N jours (les secrets sont conservés). Quand une signature est récente, une nouvelle session ne signe pas.

**Un couple partage :**
- une **ardoise** commune de quelques lignes (toujours active),
- des **secrets** de couple :
  - les deux parties peuvent a priori en créer et les mettre à jour, sauf décision d'exclusivité (voir les secrets).
  - si l'une ou l'autre partie _refuse le partage de secrets_, ceux existants restent lisibles mais il ne lui est plus possible de les mettre à jour, ni d'en créer de nouveaux.
  - les volumes d'un secret sont décomptés sur les deux comptes (du moins tant que le couple a toujours deux parties). Le couple conserve le total courant des volumes de secrets.

La partie (1) d'un couple est celle qui a pris l'initiative du contact : un couple peut donc avoir à instant donné,
- une partie (1) et une partie (2),
- une partie (1) seulement,
- une partie (2) seulement.

Un couple est déclaré avec :
- une clé `cc` (aléatoire de 32 bytes) cryptant les données communes dont les secrets du couple.
- une `id` qui est le hash de cette clé.

Un couple est connu dans chaque avatar A1 et A2 par une entrée dans leurs maps respectives `lcck` : les clés dans ces maps sont des numéros aléatoires dit _d'invitation_.

#### Prises de contact
Il y a 3 moyens pour A1 de prendre contact :
- standard: A1 connaît l'identification de A2, 
  - soit parce que A2 est un membre d'un groupe G dont A1 est membre aussi,
  - soit parce que A2 est membre d'un groupe G dont un autre avatar du compte de A1 est membre,
  - soit parce que A2 est en couple avec un autre avatar du compte de A1.
- par phrase de contact : déclarée par A1, elle permet,
  - à A1 d'identifier le couple potentiel qu'il va former avec A2 dans sa liste de couple,
  - à A2 de retrouver ce couple en saisissant la phrase,
  - par sécurité la phrase a une durée de vie limitée : faute d'avaoir été citée par A2 dans le délai imparti elle est caduque et le couple n'est pas confirmé.

Le contact par phrase de contact est utilisé dans les deux cas suivants :
- parrainage : de A2 par A1. A2 _est connu_ de A1 qui lui a créé son identification de compte et de premier avatar, mais rien ne dit que A2 va effectivement valider la création de son compte. 
- rencontre : 
  - soit A1 a rencontré A2 dans la vraie vie et ils ont convenu d'une phrase de contact,
  - soit un intermédiaire qui connaît A1 et A2 et leur a communiqué à chacun la même phrase de prise de contact. 

#### Phases de vie d'un couple
- **(1) prise de contact par A1**. A1 est bien connu mais A2 est, soit encore inconnu (_rencontre_), soit connu, et dans les deux cas n'a (encore) validé sa participation au couple.
  - le refus amène le couple en phase 2.
  - l'acceptation amène le couple en phase 3.
- **(2) fin de vie de A1 seul après refus de A2**. A1 et A2 se sont bien identifiés mais A2 a _refusé_ ce contact initial. A1 peut prendre connaissance de la cause de refus dans l'ardoise du couple puis quittera le couple. Cette phase est passive, le couple est figé.
- **(3) vie à deux**. A1 et A2 se connaissent et participent à la vie du couple :
  - en écrivant sur l'ardoise,
  - en créant et mettant à jour des secrets partagés si les deux l'acceptent.
  - la sortie de cette phase peut être causée par :
    - le fait que l'un des deux quitte le couple : phase 4.
    - le fait que l'un des deux disparaisse : phase 5
- **(4) vie de A1 OU A2 seul après _départ_ de l'autre**. Celui qui a quitté ne _connaît plus le couple_. Celui qui reste le connaît encore et peut :
  - continuer à faire vivre les secrets,
  - tenter une _reprise de contact_ avec celui qui a quitté (mais ce dernier n'est pas obligé d'accepter), ce qui ramènerait le couple en phase 3.
- **(5) vie de A1 OU A2 seul après _disparition_ de l'autre**. Celui qui reste connaît encore son identité (bien que disparu) mais plus sa carte de visite. Il peut continuer à faire vivre les secrets.
  - si celui qui reste quitte le couple, celui-ci est détruit.
  - si celui qui reste disparaît pour non activité, le couple s'auto-détruira au bout d'un certain temps (il n'est plus signé).

Dans certaines de ces phases il y a des états particuliers différents (sinon 0).
- **(1) prise de contact par A1**
  - (1) : prise de contact standard en cours
  - (2) : parrainage en cours
  - (3) : rencontre en cours
- **(4) vie de A1 OU A2 seul après _départ_ de l'autre**
  - (1) : reprise de contact en cours


#### Partage de secrets
**En phase 3** A1 et A2 partagent les secrets dont les volumes sont supportées par **les deux**.

Chacun peut fixer une limite maximale de v1 et v2 : les créations et mises à jour de secrets sont bloquées dès qu'elles risquent de dépasser la plus faible des deux limites.

#### Départ d'un couple et reprise de contact
En phase 3, le départ, par exemple de A1 a les conséquences suivantes :
- A1 récupère le volume courant du couple,
- A1 ne connaît plus le couple et ne peut plus ni lire ni accéder aux secrets du couple,
- les volumes maximum de A1 sont non significatifs (remis à 0)

En phase 4, une _reprise de contact_ (acceptée) par exemple de A1 a les conséquences suivantes :
- A1 se voit imputer les volumes courants,
- A1 refixe ses contraintes de volumes maximaux ce qui peut bloquer les créations et les mises à jour en expansion des secrets.

Table :

    CREATE TABLE "couple" (
    "id"   INTEGER,
    "v"  	INTEGER,
    "st" INTEGER,
    "dds" INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "mx11"  INTEGER,
    "mx21"  INTEGER,
    "mx12"  INTEGER,
    "mx22"  INTEGER,
    "dlv"	INTEGER,
    "datap"  BLOB,
    "infok1"	BLOB,
    "infok2"	BLOB,
    "mc1"	BLOB,
    "mc2"  BLOB,
    "ardc"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id"));
    CREATE INDEX "id_v_couple" ON "couple" ( "id", "v" );
    CREATE INDEX "st_couplet" ON "couple" ( "st" ) WHERE "st" < 0;

- `id` : id du couple
- `v` :
- `st` : 
  - _négatif_ : suppression logique au jour J par le GC.
  - _positif_ : deux chiffres `phase / état`
- `dds` : dernière date de signature de A1 ou A2 (maintient le couple envie).
- `v1 v2` : volumes actuels des secrets.
- `mx11 mx21` : maximum des volumes autorisés pour A1
- `mx12 mx22` : maximum des volumes autorisés pour A2
- `dlv` : date limite de validité éventuelle de la phase 1.
- `datac` : données cryptées par la clé `cc` du couple :
  - `nom1 rnd1 nom2 rnd2` : nom et clé d'accès à la carte de visite de A1 et A2.
  - `idc1 idc2` : id des comptes de A1 et A2 afin d'imputer les volumes des secrets.,
  - `ni1 ni2` : numéro d'invitation, clé d'entrée de la map `lcck` pour le couple dans les avatars A1 et A2.
  - `phrase` : phrase de contact en phases 1-2 et 1-3 (nécessite une phrase).
  - `f1 f2` : en phase 1-2 (parrainage), forfaits attribués par le parrain A1 à son filleul A2.
- `infok1 infok2` : commentaires cryptés par leur clé K, respectivement de A1 et A2.
- `mc1 mc2` : mots clé définis respectivement par A1 et A2.
- `ardc` : ardoise commune cryptée par la clé cc.
- `vsh` :

La **suppression (logique)** d'un couple consiste à ne laisser que les propriétés suivantes :
- `id`
- `v`
- `st` : contient en négatif le jour de suppression.
- toutes les autres sont null
- le row est désormais immuable (`v` ne changera plus).
- tous les row `secret` ayant pour id le couple supprimé sont physiquement supprimés à la suppression logique du couple

La **purge physique** d'un row supprimé logiquement intervient N2 jours après `st` (jour de suppression logique).

Quand c'est le GC qui a effectué le row `avatar` qui le référence dans `lcck` est mis à jour (opération `regulCC`),
- soit suite à une synchro,
- soit au prochain login,
- l'entrée dans `lcck` correspondant au couple supprimé est détruite.

### Table `contactstd` : CP `id ni`. Prise / reprise de contact standard de A1 avec A2
Les contacts standard en attente sont visibles en session pour l'avatar cible qui peut les afficher (en particulier les données du couple en attente), l'accepter ou la refuser.
- dans les deux cas le row `contactstd` est détruit.
- en cas de non réponse, le GC détruit le row après dépassement de la `dlv`.

Table :

    CREATE TABLE "contactstd" (
    "id"   INTEGER,
    "ni"  	INTEGER,
    "v" INTEGER,
    "dlv"	INTEGER,
    "ccp"  BLOB,
    PRIMARY KEY("id", "ni"));
    CREATE INDEX "dlv_contactstd" ON "contactstd" ( "dlv" );

- `id` : id de A2
- `ni` : ni de A2 dans le couple
- `v` :
- `dlv`
- `ccp` : clé du couple (donne son id) cryptée par la clé publique de A2

#### Prise de contact initiale par A1 avec A2
- A1 peut détruire physiquement son row avant acceptation / refus (remord).
- A1 peut prolonger la date-limite de la rencontre (encore en attente), sa `dlv` est augmentée.

**Si A2 refuse le contact :** 
- L'ardoise du `couple` contient une justification / remerciement du refus, la phase passe à 2.
- Le row `contactstd` est supprimé. 

**Si A2 ne fait rien à temps :** 
- Lors du GC sur la `dlv`, le row `contactstd` sera supprimé par GC de la `dlv`.
- la phase du couple sera automatiquement mutée à 2 (détection dans `couple` de `dlv` dépassée) lors d'un login de A1.

**Si A2 accepte le contact :** 
- le row `couple` est mis à jour (phase 3), l'ardoise renseignée, les volumes maximum sont fixées.

#### Reprise de contact par A1 avec A2
- A1 peut détruire physiquement son row avant acceptation / refus (remord).
- A1 peut prolonger la date-limite de la rencontre (encore en attente), sa `dlv` est augmentée.

**Si A2 refuse la reprise de contact :** 
- L'ardoise du `couple` contient une justification / remerciement du refus, la phase repasse à 4-0.
- Le row `contactstd` est supprimé. 

**Si A2 ne fait rien à temps :** 
- Lors du GC sur la `dlv`, le row `contactstd` sera supprimé par GC de la `dlv`.
- la phase du couple sera automatiquement mutée à 4-0 (détection dans `couple` de `dlv` dépassée) lors d'un login de A1.

**Si A2 accepte le contact :** 
- le row `couple` est mis à jour (phase 3), l'ardoise renseignée, les volumes maximum sont fixées.

### Table `contactphc` : CP `phh`. Prise de contact par phrase de contact de A2 par A1
Les rows `contactphc` ne sont pas synchronisés en session : ils sont,
- lus sur demande par A2,
- supprimés physiquement éventuellement par A1 sur remord.

Ceci couvre les deux cas de parrainage et de rencontre.
- pour un parrainage c'est sur la page de login que le filleul peut accéder à son parrainage, l'accepter ou le refuser.
- pour une rencontre sur la page de l'avatar souhaitant la rencontre un bouton permet d'accéder à la rencontre et aux détails du couple pour accepter ou refuser.
- dans les deux cas (acceptation / refus) le row `contactphc` est détruit.
- en cas de non réponse, le GC détruit le row après dépassement de la `dlv`.

Table :

    CREATE TABLE "contactphc" (
    "phch"   INTEGER,
    "dlv"	INTEGER,
    "ccx"  BLOB,
    PRIMARY KEY("id", "ni"));
    CREATE INDEX "dlv_contactphc" ON "contactphc" ( "dlv" );

- `phch` : hash de la phrase de contact convenue entre le parrain A1 et son filleul A2 (s'il accepte)
- `dlv`
- `ccx` : clé du couple (donne son id) cryptée par le PBKFD de la phrase de contact

#### Parrainage
- Le parrain peut détruire physiquement son row avant acceptation / refus (remord).
- Le parrain peut prolonger la date-limite d'un parrainage** (encore en attente), sa `dlv` est augmentée.

**Si le filleul refuse le parrainage :** 
- L'ardoise du `couple` contient une justification / remerciement du refus, la phase passe à 2.
- Le row `contactphc` est supprimé. 

**Si le filleul ne fait rien à temps :** 
- Lors du GC sur la `dlv`, le row `contactphc` sera supprimé par GC de la `dlv`. 

**Si le filleul accepte le parrainage :** 
- Le filleul crée son compte et son premier avatar (il a dans couple l'id de son compte, `nom rnd ni` de son avatar).
- sa ligne `compta` est créée et crédités des forfaits attribués par le parrain.
- la ligne `compta` du parrain est mise à jour (total des forfaits et réserve).
- le row `couple` est mis à jour (phase 3), l'ardoise renseignée, les volumes maximum sont fixées.

#### Rencontre initiée par A1 avec A2
- A1 peut détruire physiquement son row avant acceptation / refus (remord).
- A1 peut prolonger la date-limite de la rencontre (encore en attente), sa `dlv` est augmentée.

**Si A2 refuse la rencontre :** 
- L'ardoise du `couple` contient une justification / remerciement du refus, la phase passe à 2.
- Le row `contactphc` est supprimé. 

**Si A2 ne fait rien à temps :** 
- Lors du GC sur la `dlv`, le row `contactphc` sera supprimé par GC de la `dlv`. 

**Si A2 accepte la rencontre :** 
- le row `couple` est mis à jour (phase 3), l'ardoise renseignée, les données `idc2 nom2 rnd2 ni2` sont fixées. Les volumes maximum sont fixées.

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
- tous les row `secret` et `membre` ayant pour id le groupe supprimé sont physiquement supprimés à la suppression logique du groupe

La **purge physique** d'un row supprimé logiquement intervient N2 jours après `st` (jour de suppression logique).

Tous les rows avatars qui le référencent dans `lgrk` seront mis à jour (opération `regulAv`), 
- soit suite à une synchro,
- soit au prochain login,
- les entrées dans `lgrk` correspondant au groupe supprimé seront détruites.

**Les membres d'un groupe** reçoivent lors de leur création (opération de création d'un contact d'un groupe) un indice membre `im` :
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
  - `x` : 0:envisagé, 1:invité, 2:actif (invitation acceptée), 3: inactif (invitation refusée), 4: inactif (résilié), 5: inactif (disparu).
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
- un membre _envisagé_ a un row `membre` de statut x `0`: (l'avatar ne le sait pas, n'a pas le groupe dans sa liste des groupes). Tous les membres commencent leur cycle de vie en tant que _envisagé_.
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
- (0) *secret personnel d'un avatar A* : la clé K de l'avatar.
- (1) *secret d'un couple d'avatars A et B* : leur clé `cc` de contact mutuel.
- (2) *secret d'un groupe G* : la clé du groupe G.

### Un secret a toujours un texte et possiblement des fichiers attachés
Le texte a une longueur maximale de 4000 caractères. L'aperçu d'un secret est constituée des N3 premiers caractères de son texte ou moins (première ligne au plus).
- le texte est stocké gzippé au delà d'une certaine taille.

**La liste des auteurs d'un secret donne les derniers auteurs:**
- dans l'ordre de modification, le plus récent en tête,
- sans doublon.

### Fichier attachés
Un secret _peut_ avoir plusieurs fichiers attachés, chacune identifiée par : `nom.ext|type|dh`.
- `nom.ext` est un _nom de fichier_, d'où un certain nombre de caractères interdits (dont le `/`). Pour un secret donné, ce nom est identifiant.
- `type` est le MIME type du fichier d'origine.
- `dh` est la date-heure d'enregistrement du fichier (pas de la création ou dernière modification de son fichier d'origine).
- un signe `$` à la fin indique que le contenu est gzippé en stockage.
- le volume retenu est le volume NON gzippé. Seuls les fichiers de types `text/...` sont gzippés.

Un fichier d'un nom donné peut être mise à jour / remplacé : le nouveau contenu peut avoir un type différent et aura par principe une date-heure différente d'enregistrement.

> **Le contenu d'un fichier sur stockage externe est crypté par la clé du secret.**

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

Un animateur de groupe a ces mêmes droits.

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
    "v" INTEGER,
    "st"  INTEGER,
    "ora" INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "mc"   BLOB,
    "txts"  BLOB,
    "mfas"  BLOB,
    "refs"  BLOB,
    "vsh" INTEGER,
    PRIMARY KEY("id", "ns");
    CREATE INDEX "id_v_secret" ON "secret" ("id", "v");
    CREATE INDEX "st_secret" ON "secret" ( "st" ) WHERE "st" < 0;

- `id` : id du groupe ou de l'avatar.
- `ns` : numéro du secret.
- `v` :
- `st` :
  - < 0 pour un secret _supprimé_.
  - `99999` pour un *permanent*.
  - `dlv` pour un _temporaire_.
- `xp` : _xxxp_ (`p` reste de la division par 10)
   - `xxx` : exclusivité : l'écriture et la gestion de la protection d'écriture sont restreintes au membre du groupe dont `im` est `x` (un animateur a toujours le droit de gestion de protection et de changement du `x`). Pour un secret de couple : 1 ou 2.
    - `p` : 0: pas protégé, 1: protégé en écriture.
- `v1` : volume du texte
- `v2` : volume total des fichiers attachés
- `mc` : 
  - secret personnel ou de couple : vecteur des index de mots clés.
  - secret de groupe : map sérialisée,
    - _clé_ : `im` de l'auteur (0 pour les mots clés du groupe),
    - _valeur_ : vecteur des index des mots clés attribués par le membre.
- `txts` : crypté par la clé du secret.
  - `d` : date-heure de dernière modification du texte
  - `l` : liste des auteurs (pour un secret de couple ou de groupe).
  - `t` : texte gzippé ou non
- `mfas` : sérialisation de la map des fichiers attachés.
- `refs` : couple `[id, ns]` crypté par la clé du secret référençant un autre secret (référence de voisinage qui par principe, lui, n'aura pas de `refs`).
- `vsh`

**Suppression d'un secret :**
`st` est mis en négatif : les sessions synchronisées suppriment d'elles-mêmes ces secrets en local avant `st` si elles elles se synchronise avant `st`, sinon ça sera fait à `st`.

**Map des fichiers attachés :**
- _clé_ : hash (court) de `nom.ext` en base64 URL. Permet d'effectuer des remplacements par une version ultérieure.
- _valeur_ : `[idc, taille]`
  - `idc` : id complète du fichier (`nom.ext|type|dh$`), cryptée par la clé du secret et en base64 URL.
  - `taille` : en bytes, avant gzip éventuel.

**Identifiant de stockage :** `org/sid@sns/cle@idc`  
- `org` : code de l'organisation.
- `sid` : id du secret en base64 URL.
- `sns` : ns du secret en base64 URL.
- `cle` : hash court en base64 URL de `nom.ext`
- `idc` : id complète de la pièce jointe, cryptée par la clé du secret et en base64 URL.

En imaginant un stockage sur file system, il y a un répertoire par secret : dans ce répertoire pour une valeur donnée de `cle@` il n'y a qu'un fichier. Le suffixe `idc` permet de gérer les états intermédiaires lors d'un changement de version).

_Une nouvelle version_ d'un fichier attaché est stockée sur support externe **avant** d'être enregistrée dans son secret.
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

# Gestion des disparitions / résilations
**Les ouvertures de session** *signent* dans les tables `compta avatar couple groupe`, colonne `dds`, les rows relatifs aux compte, avatars du compte, couples et groupes accédés par le compte. Cette signature toutefois n'a pas lieu si dans le row `compta` le groupe est marqué _en sursis_ ou si son parrain est lui-même _en sursis_.

**La fin d'hébergement d'un groupe** provoque l'inscription de la date du jour dans la propriété `dfh` du row groupe (sinon elle est à zéro).

## GC quotidien
Le GC quotidien effectue les activités de nettoyage suivantes :
- purge physique des rows `compte compta prefs` sur dépassement de la `dds` + N1 jours du row `compta`. Ceci empêche le login sur ces comptes.
- suppression logique des rows `avatar` sur dépassement de leur `dds` + N1 jours et purge physique des rows `secret avrsa` de même id.
- suppression logique des rows `couple` sur dépassement de leur `dds` + N1 jours et purge physique des rows `secret` de même id.
- suppression logique des rows `groupe` sur dépassement de leur `dds` + N1 jours ou de leur `dfh` + N2 jours et purge physique des rows `membre secret` de même id.
- suppression physique des rows `contactstd contactphc` ayant une date-limite de validité `dlv` dépassée.

**_Remarque_** : un compte est toujours détruit physiquement avant ses avatars puisqu'il apparaît plus ancien que ses avatars dans l'ordre des signatures. Le compte n'étant plus accessible, ses avatars ne seront plus signés ni les groupes et couples auxquels il accédait.

#### Rows `secret` et leurs fichiers attachés
Pour chaque secret détruit il faut aussi détruire ses fichiers attachés : ceci ne peut pas s'effectuer dans la même transaction puisque affectant un espace de stockage séparé non lés au commit de la base.
- un row portant l'identification du secret `[id, ns]` est inséré dans une table d'attente `supprfa` dès lors que son volume v2 n'est pas 0.
- le GC purge ensuite de l'espace secondaire tous les fichiers listés dans cette table.

#### Rows `couple membre` et le statut _disparu_
La disparition de A1 ou A2 d'un couple ou d'un membre est constaté en session quand sa carte de visite est demandée / rafraîchie : elle revient alors à `null` avec un statut _disparu_.
- cette constatation n'est pas pérenne sur le long terme: au bout d'un certain temps, la carte de visite ne revient pas du tout du serveur et il est impossible à une session de discerner si c'est parce qu'elle est inchangée ou disparue.
- chaque session constatant une carte de visite _disparu_ pour A1 / A2 d'un couple ou un membre d'un groupe, fait inscrire sur le serveur le statut _disparu_ sur le couple (passage en phase 5) ou le membre :
  - ceci évite aux autres sessions de procéder à la même opération.
  - les cartes de visite ne sont plus demandées par les sessions (ce qui réduit le trafic et les recherches inutiles en base centrale).

## Disparition _explicite_ d'un groupe
Il n'y a pas d'opération de destruction d'un groupe mais des résiliations et auto-résiliations : quand il ne reste plus de membres _actifs_ dans un groupe,
- il ne peut plus être signé au login : il disparaîtrait de lui-même, à minima sur dépassement de dds / dfh.
- cette disparition peut être _accélérée_ en fixant un `st` fictif -1 qui provoquera la disparition logique (et les effacements physique) au prochain GC.

## Disparition _explicite_ d'un avatar
C'est une opération _longue_ :
- fin / transfert d'hébergement sur tous les groupes hébergés par le compte de l'avatar :
  - soit un transfert sur un autre avatar du même compte pour autant qu'il y en ait un qui soit aussi membre du groupe.
  - soit une fin d'hébergement.
  - le choix (quand il y en un) est interactif.
- mise à jour de son statut `disparu` sur les groupes dont il est membre ou `st` à -1 s'il était le dernier membre actif.
- mise à jour de son statut phase 5 sur ses couples ou `st` à -1 s'il était seul dans le couple.

Le row avatar peut être mis en suppression logique : st à -1 pour éxécution effective au prochain GC.
