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

#### Compte
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

#### Avatar 
- `id` : entier **pair** depuis 5 bytes aléatoires.
- `pseudo` : nom lisible et immuable, entre 6 et 20 caractères.
- `clé` : SHA id + 8 bytes aléatoires + pseudo. Permet de lire la carte de visite.
- c1 : clé de cryptage des

#### Groupe
- `id` : entier **impair** depuis 5 bytes aléatoires.  
- `code` : lisible (comme un nom de fichier) et immuable.
- `clé` : SHA id + 8 bytes aléatoires + code. Permet d'accéder à la liste des membres du groupe.

#### Secret
- `id` : entier depuis 6 bytes aléatoires.  
- `clé` : SHA de id + 15 bytes aléatoires.

### Attributs génériques
- `v` : version, entier.
- `dds` : date de dernière signature, en nombre de jours depuis le 1/1/2021. Signale que ce jour-là, l'avatar, le compte, le groupe, le secret était *vivant / utile / référencé*. Pour éviter des rapprochements entre eux, la *vraie* date de signature peut être entre 0 et 30 jours *avant*.  Permet de distinguer des seuils d'alerte :
   - aucune : vivant encore récemment.
   - alerte : des mois sans signe de vie, sera considéré comme disparu dans les 2 mois qui suivent.
   - disparu
- `dlv` : date limite de validité, en nombre de jours depuis le 1/1/2021.

Les comptes sont censés avoir au maximum N semaines entre 2 connexions faute de quoi ils sont considérés comme disparus. En foi de quoi les *suppressions* d'objet doivent continuer à apparaître avec un état *supprimé / résilié* au moins N semaines : ils ne sont *purgés* (effectivement détruits) que quand leur `dhc` avec un état détruit a plus de N semaines.

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
- `avinvitct` () (idb) : invitation adressée à B à lier un contact avec A  
- `avinvitgr` () (idm) : invitation à M à devenir membre d'un groupe G
- `rencontre` (dpbh) ida : communication par A de son identifications complète à un compte inconnu
- `grlmg` (idg) : liste des id + nc des membres du groupe  
- `grmembre` (idg, nm) : données d'un membre du groupe
- `secret` (id, ns) : données d'un secret d'un avatar ou groupe

### Singleton d'état global du serveur
Ce singleton est un JSON où le serveur peut stocker des données persistantes à propos de son état global : par exemple les date-heures d'exécution des derniers traitements GC, la dhc du dernier backup de la base...

	CREATE TABLE "etat" ("data"	BLOB);

### Table `versions` - CP : `id`

Au lieu d'un compteur par avatar / groupe / compte on a N compteurs (par exemple 99), un compteur pour plusieurs avatars / groupe (le reste d'une division de l'id + 1).  
L'avantage est qu'on a une table à un seul row compact avec en data un array d'entiers.

Le compteur 0 est par convention le compteur de la _séquence universelle_.

>Le nombre de collisions n'est pas vraiment un problème : détecter des proximités entre avatars / groupes dans ce cas devient un exercice très incertain (fiabilité de 1 sur 99).

L'id 0 correspondant à l'état courant et l'id 1 à la dernière sauvegarde.

	CREATE TABLE "versions" (
  "id"  INTEGER,
  "v"  BLOB
  PRIMARY KEY("id")
  ) WITHOUT ROWID;

### Avatars et Groupes : volumes et quotas
Pour chaque avatar et liste, par convention la *banque centrale* est l'avatar d'id 1, 
- `v1 v2` : les volumes utilisés augmentent quand des secrets sont rendus persistants ou mis à jour en augmentation et diminuent quand ils sont supprimés ou mis à jour en réduction : ce sont des actions qui peuvent être déclenchées par d'autres comptes (maj d'un secret déjà persistant).
- `vm1 vm2` : volumes consommés dans le mois. Le changement de mois remet à 0 `vm1` et `vm2`.
- `q1 q2 qm1 qm2` : quotas donnés à une liste / avatar par une liste / avatar / banque. En cas de GC d'un avatar / groupe, ils sont retournés à la banque. Pour un groupe il n'y a pas de `qm1 qm2`.

Les transferts de quotas entre avatars / groupes / banque se font sous la forme d'un débit / crédit.
- *Normalement* les sommes des quotas doivent être nulles.
- *Normalement* les volumes doivent être inférieurs à leur quotas.

**Table : CP `id`:**

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

### Comptes, avatars, groupes : cartes de visites et signatures 
A chaque connexion d'un compte, le compte signe pour lui-même, ses avatars et les groupes que ses avatars ont en *contact* (dont l'accès n'est pas résilié):
- le jour de signature du compte est tiré aléatoirement entre j-28 et j-14.
- le jour de signature de ses avatars est tiré aléatoirement entre j-14 et j.
- le jour de signature des groupes accédés est tiré aléatoirement entre j-14 et j.

Le traitement quotidien met à jour le flag alerte/disparu.
- *alerte* : _l'avatar_ est resté plusieurs mois sans connexion.
- *disparu* : _l'avatar_ doit être considéré comme disparu (c'est définitif).

**Table `cvsg` : CP `id`**

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
- `v` : séquence universelle.
- `dds` : date (jour) de dernière signature.
- `ad` : 0:OK, 1:alerte, 2:disparu.
- `cvag` : carte de visite cryptée par la clé de l'avatar ou du groupe. 
  - `photo` : photo ou icône.
  - `info` : court texte informatif.

**Remarques**
- un row est systématiquement créé à la création d'un compte / avatar / groupe : v est 0.
- à la signature, `dds` est changée uniquement pour un avatar :
  - si ad était _OK_, `v` n'est pas changé,
  - si ad était _alerte_, `v` est changée.
- à la modification / création de la carte de visite, `v` est changée.
- mise à jour de `ad` : par le traitement journalier. Si changement (OK -> alerte, alerte -> disparu) mise à jour de `v`.
- l'état disparu est immuable, un avatar ne _renaît_ jamais, le row est définitivement figé, sa carte de visite mise à nul et le row sera simplement détruit un jour lointain (dans 3 ans par exemple).
- un avatar d'un compte régulièrement accédé sans carte de visite a une version à 0.
- si un avatar n'est jamais monté en alerte, v est la version de sa carte de visite.

###### GC des comptes et groupes
La détection par `dds` trop ancienne d'un **compte** 
- détruit le row dans `compte` et dans `cvsg`. 
- un compte est toujours détruit physiquement avant ses avatars puisqu'il apparaît plus ancien que ses avatars dans l'ordre des signatures.
- le compte n'étant plus accessible, ses avatars ne seront plus signés et les groupes auxquels il accédait non plus.

La détection par `dds` trop ancienne d'un **groupe**,
- détruit son row dans toutes les tables `grlmg grmembre secret cvsg`.
- transfert ses quotas de son row `avgrvq` sur la banque et détruit son row `avgrvq`.
- par construction un compte tombe en désuétude que lorsque *tous* les comptes susceptibles d'y accéder ont disparu. Il suffit donc de purger ses données que plus personne ne pointe. 
- par construction s'il existe encore un avatar dont l'accès au groupe n'est pas résilié, le groupe aurait été signé lors de la connexion du compte.
- **remarque** : la résiliation d'un accès pour un avatar provoque,
  - la mise à 0 de son slot dans `avidcc`.
  - la suppression physique de son row dans `avcontact`.
  - le contact résilié reste référencé en tant que résilié dans `grmembre` (mais son slot dans grlmg est 0).

Les *disparus* depuis plus d'un an sont détruit par le GC.

### Comptes : authentification et données d'un compte
Phrase secrète : un début de 16 caractères au moins et une fin de 16 caractères au moins.  
`pcb` : PBKFD2 de la phrase complète (clé X) - 32 bytes.  
`dpbh` : hashBin (53 bits) du PBKFD2 du début de la phrase secrète (32 bytes).

**Table : `compte` CP `idc`**

	CREATE TABLE "compte" (
	"id"	INTEGER,
	"v"		INTEGER,
	"dpbh"	INTEGER,
	"pcbsh"	INTEGER,
	"kx"   BLOB,
	"mack"  BLOB,
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
  - *clé* : id du mot clé de 1 à 255.
  - *valeur* : libellé du mot clé.
- `mack` [] : map des avatars du compte, cryptée par la clé K, 
  - *clé* : id de l'avatar du compte en b64
  - *valeur* :
    - `cle` : clé de l'avatar.
    - `pseudo` : de l'avatar.
    - `cpriv` : clé privée asymétrique.

**Remarques :** 
- un row `compte` ne peut être modifié que par une transaction du compte.
- il est synchronisé lorsqu'il y a deux sessions ouvertes en parallèle sur le même compte depuis 2 browsers.
- chaque mise à jour vérifie que `v` actuellement en base est bien celle à partir de laquelle l'édition a été faite.

### Avatars : clé publique RSA
Cette table donne la clé RSA (publique) obtenue à la création de l'avatar : elle permet d'inviter un avatar à être contact lié ou à devenir membre d'un groupe.

**Table `avrsa` : CP `id`**

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
	- **libre** (statut 0) : A a B pour contact `15` et B peut avoir ou non A pour contact `57`, ces situations sont autonomes l'une de l'autre et ni A ni B ne savent rien du contact éventuel de l'autre. A peut décider de perdre B comme contact et B peut décider de perdre A comme contact, puis éventuellement de reprendre B pour contact sous un nouveau numéro `18`.
	- **lié** : A a B pour contact `15`, B a A pour contact `57` : ces numéros de contacts mutuels sont connus et immuables de part et d'autre. A peut restreindre la nature de ses échanges avec B mais ne peut plus les rompre tant que B n'a pas disparu.
- **soit un groupe G** : si A est membre du groupe G sous un numéro de contact 25, il le restera jusqu'à sa résiliation (volontaire ou par un animateur).

A chaque numéro de contact `nc` est associée :
- si le contact est un avatar B :
    - la clé de cryptage `cv` de la carte de visite de B.
    - la clé de cryptage de contact `cc` pour les secrets / notifications partagés entre A et son contact avatar lié B.
- si le contact est un groupe G dont A est membre :
    - la clé de cryptage du groupe `cg` pour les secrets du groupe G et sa carte de visite.

**Table `avidcc` : CP `ida`:**  
Cette table donne les couples `id + cc/cg` pour chacun des `nc`. Elle énumère tous les avatars et groupes en contact (avec leur clé d'accès aux secrets).

    CREATE TABLE "avidcc" (
    "ida"   INTEGER,
    "v"		INTEGER,
    "idc1k"  BLOB,
    PRIMARY KEY("ida")
    ) WITHOUT ROWID;
    CREATE INDEX "ida_v_avidcc" ON "avidcc" ( "ida", "v" )

- `ida` : id de l'avatar A.
- `v` : 
- `idcck` [ ] : table donnant la clé de cryptage `id + cc/cg` pour chaque `nc` (qui est l'index dans cette table). 
  - `id` est une redondance puisqu'on le retrouve dans `avcontact` mais ça permet à l'avatar d'avoir la liste de ses contacts en une fois.
  - pour un groupe G le terme d'index `nc` est mis à 0 à la _résiliation_ de A du groupe G.
  - pour un avatar B, le terme d'index `nc` est supprimé lors du constat de la _disparition_ de B.
  - chaque terme est crypté par la clé K. Ceci permet à un _animateur de groupe_ de mettre à 0 le terme `nc` à la résiliation sans avoir besoin de décrypter toute la liste (ce qu'il ne peut pas faire, n'ayant pas la clé K des membres).
  - idcck permet de récupérertoutes les ids des avatars non disparus et des groupes dont l'accès n'est pas résilié.

**Table : CP `ida nc`:**

    CREATE TABLE "avcontact" (
    "ida"   INTEGER,
    "nc"	INTEGER,
    "v"  	INTEGER,
    "datac"	BLOB,
    "datak"	BLOB,
    PRIMARY KEY("ida", "nc")
    );
    CREATE INDEX "ida_v_avcontact" ON "avcontact" ( "ida", "v" )

- `ida` : id de l'avatar A
- `nc` : numéro de contact.
- `v` : 
- `st1` : statut
  - 1 - contact _libre_ avec un avatar
  - 2 - demande en attente de contact _lié_
  - 3 - demande refusée de contact _lié_ avec un avatar
  - 4 - parrainage en attente
  - 5 - parrainage refusé 
  - 6 - contact _lié_ avec un avatar actif
  - 7 - contact _lié_ avec un avatar, disparu
  - 8 - membre actif du groupe
  - 9 - membre résilié du groupe
- `st2` :  statut `zt`
  - _contact _lié_ avec un avatar_ : 4 valeurs (00 01 10 11)
	  - z : A accepte (ou non) les partages de B.
    - t : B accepte (ou non) les partages de A.
	- _contact de groupe_ : 6 valeurs (11 12 13 22 23 33)
		- z : 1:lecteur, 2:auteur, 3:administrateur.
		- t : plus haut z jamais atteint.
- `q1 q2 qm1 qm2` : balance des quotas donnés / reçus par l'avatar A au groupe G ou à l'avatar B.
- `datac` : information cryptée par la clé `cc` associée au `nc` pour un contact avec un avatar :
  - `par` : parrainage :
    - `dlv` : dalimite de validité du parrainage.
    - `pc` : phrase complète de contact.
	- `dna` : dernière note écrite par A pour B (ou message de parrainage).
	- `dnb` : dernière note écrite par B pour A (ou remerciement du filleul).
- `datak` : information cryptée par la clé K de A.
	- `id` : de l'avatar B ou du groupe G.
	- `cle` : suffixe aléatoire (accès à la carte de visite pour un avatar).
	- `nom` : *pseudo de l'avatar* ou *code* du groupe.
  - `info` : information libre donnée par A à propos du contact.
  - `mc` : liste des mots clés associés au contact.

Un *contact lié* permet d'échanger un court texte entre A et B pour justifier d'un changement de statut ou n'importe quoi d'autre : en particulier quand A n'accepte pas le partage de secrets avec B, c'est le seul moyen de passer une courte information mutuelle qui n'encombre pas leurs volumes respectifs.

**Remarques :**
- un contact invité _en attente de réponse_ ou avec une réponse de refus, redevient un simple contact _libre_.
- le row `avcontact` d'un groupe dont l'accès est résilié pour A reste pour information historique. La carte de visite du groupe n'est plus accessible (et éventuellement n'existe plus).
- le row `avcontact` d'un avatar disparu reste pour information historique. La carte de visite de l'avatar n'est plus accessible (et d'ailleurs n'existe plus).
- dans ces deux derniers cas, l'utilisateur peut demander la suppression ce row d'information historique.


#### Invitation par A de B à lier leurs contacts
C'est requis pour qu'ils puissent partager des secrets et se donner des quotas.

    CREATE TABLE "avinvitct" (
    "idb"   INTEGER,
    "dlv"	INTEGER,
    "datapub"  BLOB
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_avinvitct" ON "avinvitct" ( "dlv" );
    CREATE INDEX "idb_avinvitct" ON "avinvitct" ( "idb" );

- `idb` : id de B.
- `dlv` :
- `ccpub` : clé `cc` de ce contact définie par A cryptée par la clé publique de B.
- `datac` : données cryptées par la clé cc.
	- `ida` : id de A.
	- `cle` : de A.
	- `pseudo` : de A.
	- `nc` : numéro du contact de A pour B (pour que B inscrive le statut ...). 
  - `msga` : message de sollicitation écrit par A pour B.
  - `repb` : réponse de B.
  - `ok` : 0: en attente, 1: acceptation, 2 : refus

En cas d'acceptation, B peut soit créer un contact chez lui pour A, soit récupérer celui existant chez lui pour A s'il l'avait déjà en contact libre, et inscrire les données de A comme contact *lié* chez lui (`statut dna dnb`). Chez A il y a mise à jour de `statut dna dnb`.

En cas de refus, le contact `nc` chez A redevient un contact _libre_.

En cas d'acceptation, `msga repb` sont inscrits par B dans `dna dnb`.

#### Invitation par A de M à un groupe G
L'invitant peut retrouver en session la liste des invitations en cours qu'il a faites : un membre de G avec `ida` comme invitant et un statut en attente.

    CREATE TABLE "avinvitgr" (
    "idm"   INTEGER,
    "dlv"	INTEGER,
    "datapub"  BLOB);
    CREATE INDEX "dlv_grinvitgr" ON "grinvitgr" ( "dlv" );
    CREATE INDEX "idm_grinvitgr" ON "grinvitgr" ( "idm" );

- `idm` : id du membre invité.
- `dlv` :
- `datapub` : crypté par la clé publique du membre invité.
	- `idg code` : du groupe.
  - `cg` : clé du groupe.
	- `nm` : numéro de membre de l'invité.

### Parrainage par P de la création d'un compte F (pour un *inconnu* n'ayant pas de compte)

Comme il va y avoir un don de quotas du *parrain* vers son *filleul*, ces deux-là vont avoir un contact *lié* (si F accepte). Toutefois,
- P peut indiquer que son contact est restreint à une simple note (sans partage de secrets).
- F pourra indiquer que son contact est restreint à une simple note (sans partage de secrets).

Le parrain fixe l'avatar filleul (mais pas son compte), donc son pseudo : le contact lié est préétabli dans `avidcc avcontact` de P. Le filleul établira le sien, s'il accepte.

La parrain retrouve la liste de ses parrainages dans ses `avcontact`.

Un parrainage est identifié par `dpbh` le hash du PBKFD2 du début de la phrase de reconnaissance.

    CREATE TABLE "parrain" (
    "dpbh"  INTEGER,
    "dlv"  INTEGER,
    "pbcsh"  BLOB,
    "datax"  BLOB,
    PRIMARY KEY("dpbh")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_parrain" ON "parrain" ( "dlv" );
    CREATE INDEX "idp_parrain" ON "parrain" ( "idp" )

- `dpbh` : hash du PBKFD2 du début de la phrase secrète de parrainage.
- `dlv` : la date limite de validité permettant de purger les parrainages.
- `pcbsh` : hash du SHA de X (PBKFD2 de la phrase complète) pour que l'invité puisse être quasi-authentifié. Le filleul doit se rappeler qu'il a une proposition qui l'attend identifiée par une phrase de contact.
- `datax` : données de l'invitation cryptées par la clé X.
  - `cle pseudo` : de l'avatar P.
  - `cc` : de P.
  - `nc` : de P.
  - `idf clef pseudof` : avatar du filleul.

**La parrain créé un contact *lié* pour le filleul**  

**Si le filleul ne fait rien à temps** : le GC s'effectuera sur la `dlv` par simple *delete*.

**Si le filleul refuse le parrainage** : le row de P dans `avcontact` est mis à jour et le parrain y lit la raison et le statut. Le row `parrain` est détruit.

**Si le filleul accepte le parrainage :**  
Le filleul crée son compte et son premier avatar (dont il a reçu l'id, la clé et le pseudo de P). Les quotas sont prélevés à ce moment. Le row `parrain` est détruit.

### Avatar : rencontre entre A et B
A et B se sont rencontrés dans la *vraie* vie mais ni l'un ni l'autre n'a les coordonnées de l'autre pour,
- soit s'inviter à créer un contact *lié*,
- soit pour B inviter A à participer à un groupe.

Une rencontre est juste un row qui va permettre à A de transmettre à B son `id / clé / pseudo` en utilisant une phrase de rencontre convenue entre eux.  
En accédant à cette rencontre B peut ainsi inscrire A comme contact *libre* : ensuite il pourra normalement l'inviter à un contact *lié* (ou l'inviter à un groupe).

Une rencontre est identifiée par `dpbh` le hash du PBKFD2 du début de la phrase de reconnaissance.

    CREATE TABLE "rencontre" (
    "dpbh"  INTEGER,
    "ida"   INTEGER,
    "dlv"   INTEGER,
    "pbcsh" BLOB,
    "datak" BLOB,
    "datax" BLOB,
    PRIMARY KEY("dpbh")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_rencontre" ON "rencontre" ( "dlv" )
    CREATE INDEX "ida_rencontre" ON "renconstre" ( "ida" )

- `dpbh` : hash du PBKFD2 du début de la phrase secrète de rencontre.
- `ida` : id de l'avatar A initiant la rencontre.
- `dlv` : la date limite de validité permettant de purger les rencontres.
- `pcbsh` : hash du SHA de X (PBKFD2 de la phrase complète) pour que B puisse être quasi-authentifié.
- `datak` : phrase de rencontre cryptée par la clé K du compte (pour que P la retrouve).
- `datax` : données de l'invitation cryptées par la clé X.
  - `cle pseudo` : de A.

### Groupe : liste et détail des membres
- `id` : entier depuis 5 bytes aléatoires.  
- `code` : lisible (comme un nom de fichier) et immuable.
- `cg` : 15 bytes aléatoires. Permet d'accéder à la liste des membres du groupe et à la carte de visite du groupe.

Un groupe est caractérisé par :
- sa carte de visite dans `cvsg`,
- ses quotas et volumes dans `avgrvq`,
- la liste de ses membres dans `grmlg`.
- le détail de ses membres dans `grmembre`.
- la liste de ses secrets dans `secrets`.

**Table `grlmg` : CP: `idg`**

    CREATE TABLE "grentete" (
    "idg"   INTEGER,
    "v"  INTEGER,
    "st"	INTEGER,
    "mcg" BLOB,
    "idncg"  BLOB,
    PRIMARY KEY("idg")
    ) WITHOUT ROWID;
    CREATE INDEX "idg_v_grentete" ON "grentete" ( "idg", "v" )

- `idg` : id du groupe.
- `v` : espace générique
- `st` : statut : 1)ouvert, 2)fermé, 3)ré-ouverture en vote, 4)archivé 
- `mcg` : liste des mots clés prédéfinis pour le groupe.
- `idncg` [`idm + nc`]: liste indexée par le numéro de membre (cryptée par la clé du groupe `cg`). Pour chaque membre actif `nm`, la référence de son contact :
	- `idm` : l'id du membre.
	- `nc` : son numéro de contact qui permet au membre de retrouver la clé `cg` du groupe (dans `avidcc`).

Quand un membre est résilié ou a disparu, son slot dans la liste est 0 : la liste des membres actifs s'obitent de cette liste.

##### Détail de chaque membre
Chaque membre d'un groupe a une entrée pour le groupe identifiée par un numéro de membre `nm` attribué en séquence.   
Les données relatives aux membres sont cryptées par la clé du groupe.

**Table `grmembre` : CP `idg nm`**

    CREATE TABLE "grmembre" (
    "idg"   INTEGER,
    "nm"	INTEGER,
    "v"		INTEGER,
    "st"	TEXT,
    "datag"	BLOB,
    PRIMARY KEY("id", "nm"));
    CREATE INDEX "id_v_avlab" ON "grmembre" ( "idg", "v" )

- `idg` : id du groupe.
- `nm` : numéro du membre dans le groupe.
- `v` :
- `st` : statut.
- `datag` : données cryptées par la clé du groupe.
	- `idm cle pseudo` : de l'avatar membre.
	- `idi` : id du membre qui l'a invité.
	- `dna` : dernière note écrite au membre par un animateur (dont le texte d'invitation).
	- `dnb` : dernière note écrite par le membre (réponse à invitation).
  - `dlv` : date limite de validité de l'invitation.
	- `q1 q2` : balance des quotas donnés / reçus par le membre au groupe.
	- `vote` : de réouverture.

Le statut comporte trois chiffres `xyz` :
- x : 1:en attente, 2:accepté, 3:refusé, 8: résilié, 9:disparu.
- y : 1:lecteur, 2:auteur, 3:administrateur.
- z : plus haut y jamais atteint.

**Remarques**
- tous les membres se connaissent et ont un statut de lecteur / auteur / animateur.
- seuls les animateurs peuvent :
    - inviter d'autres avatars à rejoindre la liste.
    - changer les statuts des membres non animateurs.
    - détruire le groupe.
    - attribuer un statut *permanent* à un secret partagé par le groupe.
- les avatars membres du groupe peuvent s'ils sont auteur / animateur :
	- partager un secret avec le groupe,
	- modifier un secret du groupe selon le statut du secret : 
		- *ouvert* : tous les *auteurs / animateurs* peuvent le modifier.
		- *restreint* : seul le dernier auteur peut le modifier.
		- *archivé* : le secret ne peut plus changer (jamais).
- un animateur peut lancer quand il veut un nettoyage pour détecter les membres qui auraient disparus *et* ne seraient plus auteurs d'aucuns secrets.
- le row `grmembre` d'un membre subsiste quand il est résilié et / ou disparu pour information historique : la carte de visite n'est plus accessible.

### Secrets
Un secret est identifié par,
- id : l'id du groupe ou de l'avatar proriétaire.
- ns : un numéro aléatoire relatif à cet id.

La clé de cryptage du secret `cs` est selon le cas :
- (0) *secret personnel d'un avatar A* : la clé K de l'avatar.
- (1) *secret d'un couple d'avatars A et B* : A et B connaissent leur clé `cc` de contact réciproque.
- (2) *secret d'un groupe G* : la clé du groupe G.

###### Un secret a toujours un texte et possiblement une pièce jointe
Le texte a une longueur maximale de 4000 caractères. L'aperçu d'un secret est constituée des 140 premiers caractères de son texte.

*Le texte complet d'un secret* n'existe que lorsque le texte fait plus de 140 caractères : il est stocké gzippé.

Un secret peut avoir une pièce jointe,
- de taille limitée à quelques dizaines de Mo,
- ayant un type MIME,
- à chaque fois qu'une pièce jointe est changée elle a une version différente afin qu'à tout instant une pièce jointe puisse être lisible même durant son remplacement (son cryptage et son stockage peuvent prendre du temps).

###### Mise à jour d'un secret
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

Un secret créé par A partagé avec B (contact *lié* de A) peut être mis à jour :
- par A si le statut du secret est *ouvert* ou *restreint*.
- par B si statut est *ouvert*.
- par personne si le statut du secret est *archivé*.
- les seuls auteurs qui peuvent apparaître dans la liste des auteurs successifs du secret sont A et B.

Un compte peut faire une requête retournant la liste des avatars ayant accès à un des secrets partagés (ou non) de ses avatars et disposer de la liste des auteurs qui devraient tous lui être connus (dans un groupe et / ou en tant que contact).

###### Secret temporaire et permanent
Par défaut à sa création un secret est *temporaire* :
- son `nsc` *numéro de semaine de création* indique que S semaines plus tard il sera automatiquement détruit.
- un avatar Ai qui le partage peut le déclarer *permanent*, le secret ne sera plus détruit automatiquement :
  - l'avatar propriétaire pour un secret personnel.
  - les deux avatars pour un secret de couple.
  - un des animateurs pour un secret de groupe.

###### Décompte du volume des secrets et des pièces jointes
- il est décompté à la création sur le décompte de secrets *créés / modifiés dans le mois* de l'auteur.
- le décompte intervient à chaque modification en plus dans le mois de l'auteur.

Dès que le secret est *permanent* il est décompté (en plus ou en moins à chaque mise à jour) sur le volume du groupe.

**Table `secret` : CP `ids`**

    CREATE TABLE "secret" (
    "id"  INTEGER,
    "ns"  INTEGER,
    "v"		INTEGER,
    "nsc"	INTEGER,
    "txts"	BLOB,
    "mcs"   BLOB,
    "aps"	BLOB,
    "ncb"  INTEGER,
    "dups"	BLOB,
    PRIMARY KEY("id","ns"));
    CREATE INDEX "id_v_secret" ON "secret" ("id", "v")
    CREATE INDEX "nsc_secret" ON "secret" ( "nsc" )

- `id` : id du groupe ou de l'avatar.
- `ns` : numéro du secret relatif au groupe / avatar.
- `v` : 
- `nsc` : numéro de semaine de création ou 9999 pour un *permanent*.
- `txts` : texte complet gzippé crypté par la clé du secret. 
- `aps` : données d'aperçu du secret cryptées par la clé du secret.
  - `lmc` : liste des mots clés.
  - `la` [] : liste des auteurs (identifé par leur numéro de membre).
  - `ap` : texte d'aperçu.
  - `st` : 5 bytes donnant :
    - 0:ouvert, 1:restreint, 2:archivé
    - la taille du texte : 0 pas de texte, 1, 2, ... (convention) 
    - la taille de la pièce jointe : 0 pas de pièce, 1, 2 ... (convention)
    - type de la pièce jointe : 0 inconnu, 1, 2 ... selon une liste prédéfinie.
    - version de la pièce jointe afin que l'upload de la version suivante n'écrase pas la précédente.
  - `r` : référence à un autre secret.
- `ncb / dups` : pour un secret de couple A/B (sinon absent).

#### Secrets de couple, duplication
Dans le cas d'un secret partagés entre deux avarars A et B (contacts liés), le secret est dupliqué, une fois pour A et une fois pour B :
- la clé de cryptage du secret est celle du couple : dans l'exemplaire de A id est l'id de A et ncb est le numéro de contact pour B dans A. Cette clé crypte `txts aps dups`.
- dans `dups`, A va trouver `{idb, nsb}` :
  - `idb` : l'id de B
  - `nsb` : le numéro de secret de l'exemplaire pour B.
- A peut créer les deux exemplaires du secret en générant deux numéros relatifs à A et B afin que la relation entre A et B n'apparaisse pas dans la base.
- A comme B peuvent mettre à jour les deux exemplaires du secret.

#### Mots clés
Un secret peut apparaître avec plusieurs mots clés indiquant :
- des états : _lus, important, à cacher, à relire, favori ..._
- des éléments de classement fonctionnel : _énergie bio-diversité réchauffement ..._

Le texte d'un mot clé peut contenir en tête un emoji.

Les mots clés sont numérotés avec une conversion entre leur numéro et leur texte :
- 1-49 : pour ceux génériques de l'installation dans la configuration.
- 50-255 : pour ceux spécifiques de chaque compte dans `mc` de son row `cvsg` : la map est cryptée par la clé K du compte.
- 50-255 : pour ceux spécifiques de chaque groupe dans `mc` de son row `cvsg` : la map est cryptée par la clé G du groupe.

**Pour un secret d'un avatar**
- mc est simplement la suite des numéros de mots clés attachés par l'avatar au secret.

**Pour un secret de couple**
- le secret est dédoublé, dans chaque exemplaire mc est simplement la suite des numéros de mots clés attachés par l'avatar au secret.

**Pour un secret de groupe**
- c'est une map avec une entrée pour le groupe (les auteurs) et une pour chaque membre (identifié par son numéro de membre dans le goupe).
- chaque membre voit l'union des mots clés fixés pour le groupe avec les siens propres.

### Gestions des avatars disparus
La détection s'effectue par le GC quotidien sur recherche des `dds` trop ancienne d'un avatar.

Par principe un avatar est détecté disparu après la détection de la disparition de son compte. Il s'agit donc de purger les données.

#### Purge des données identifiées par l'id de l'avatar
- transfert de ses quotas depuis son row `avgrvq` sur la banque et détruction de son row `avgrvq`.
- destruction des rows les tables `avrsa avidcc avcontact avinvitct avinvitgr parrain rencontre secret`.
- son row dans `cvsg` est réduit, la carte de visite est effacée, son statut est _disparu_.

Dès cet instant le volume occupé est récupéré.

#### Mise à jour des références chez les autres comptes
L'avatar _disparu_ D est _référencé_ par des avatars et groupes :
- `avidcc avcontact` des autres avatars l'ayant en contact.
- `parrain rencontre` : la date limite de validité a déjà résolu la question, les rows ont été détruits.
- `grlmg grmembre` des groupes l'ayant pour membre.  

Quand une session d'un avatar A synchronise les cartes de visite elle a connaissance par la carte de visite de D que cet avatar a disparu :
- le row `avcontact` correspondant a son statut mis à jour. Mais il n'y a pas de raisons pour que les secrets disparaissent aussi.
- sur demande du compte, le contact peut être _oublié_ :
  - dans la liste de ses contacts `avidcc` le slot correspondant est mis à 0.
  - le row `avcontact` est supprimé.
  - tous les `secrets` de l'avatar portant ce numéro de contact sont détruits (et l'avatar crédité des volumes supprimés).
- pour chaque groupe accédé par l'avatar :
  - le slot correspondant dans `grlmg` est mis à 0 (ce qui évite à l'avanir d'aller rafraîchir sa carte de visite).
  - le row `grmembre` a son statut mis à jour. 
  - sur demande d'un compte animateur du groupe, le row pourra être supprimé pour _nettoyer_ la liste des membres.

Dans la session la carte de visite est supprimée, elle ne sera plus synchronisée.

Les références peuvent mettre longtemps a être mises à jour, tous les compte référençant l'avatar D ayant à être ouverte (ou disparaissant elles-mêmes).

## Base vivante et de backup ???
La base de backup est l'image de la base vivante la veille au soir.
- elle est accessible en lecture seule.
- la table versions permet de savoir jusqu'à quelles versions elle a été sauvée.

En début de session un compte *peut* avoir des jours / semaines / mois à rattraper, voire tout si la session est en mode incognito : une grande masse de rows peuvent être lus depuis le backup sans bloquer le serveur vivant. 

Comment savoir s'il est opportun de faire deux passes ou une seule directement sur la base vivante ?.

La vraie connexion / synchronisation se fait sur le serveur vivant pour avoir les toutes dernières mises à jour mais ça devrait être très léger.

