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
- sa transformée par PBKFD2 donne la clé X, ne sort jamais de la session cliente et n'est jamais  stockée de manière permanente.

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

#### Attributs génériques
- `v` : version, entier.
- `dds` : date de dernière signature, en nombre de jours depuis le 1/1/2021. Signale que ce jour-là, l'avatar, le compte, le groupe, le secret était *vivant / utile / référencé*. Pour éviter des rapprochements entre eux, la *vraie* date de signature peut être entre 0 et 30 jours *avant*.  Permet de distinguer des seuils d'alerte :
   - aucune : vivant encore récemment.
   - alerte : des mois sans signe de vie, sera considéré comme disparu dans les 2 mois qui suivent.
   - disparu
- `dlv` : date limite de validité, en nombre de jours depuis le 1/1/2021.

Les comptes sont censés avoir au maximum N semaines entre 2 connexions faute de quoi ils sont considérés comme disparus. En foi de quoi les *suppressions* d'objet doivent continuer à apparaître avec un état *supprimé / résilié* au moins N semaines : ils ne sont *purgés* (effectivement détruits) que quand leur `dhc` avec un état détruit a plus de N semaines.

##### Version des rows
Les rows des tables devant être présents sur les clients ont une version, de manière à pouvoir être chargés sur les postes clients de manière incrémentale : la version est donc croissante avec le temps et figure dans tous les rows de ces tables.  
- utiliser une date-heure présente l'inconvénient de laisser une meta-donnée intelligible en base ;
- utiliser un compteur universel a l'inconvénient de facilement deviner des liaisons entre objets : par exemple tous les secrets paratagés entre N avatars d'un même groupe vont avoir la même version (ou très proches selon l'option). Crypter l'appartenance d'un avatar à un groupe alors qu'on peut la lire de facto dans les versions est un problème.
- utiliser un compteur par objet rend complexe la génération de SQL avec des filtres qui associent chaque objet à sa dernière version connue.

Or il apparaît que les transactions portant sur plusieurs objets avatars / groupes / secrets ne sont pas si fréquentes, d'où l'option suivante :
- _chaque avatar a son compteur de version spécifique_, tous les rows des tables identifiées par un avatar partagent ce même espace de comptage. De ce fait les relations à l'occasion de créations de liens privilégiés entre avatars par exemple, ou à lors du paratge d'un secret, entre avatars ne laissent pas de traces interprétables en bases de données.
- _tous les autres objets peuvent partager un même compteur_ : ils n'ont pas de transactions de mises à jour entre eux (pas entre groupes, ni entre groupe et secrets). Les cartes de visite et quelques autres objets (invitations ...) n'ont aussi des transactions que portant sur eux-mêmes et peuvent donc utiliser le compteur universel.

##### Table `version` - CP : `id`

	CREATE TABLE "version" (
	"id"	INTEGER,
	"v"		INTEGER,
	PRIMARY KEY("id")
	) WITHOUT ROWID;

L'id est celui d'un avatar : par convention l'id 0 est celui du compteur générique.  
Il y donc un incrément de v à chaque transaction.

>_Remarque_ : on peut aussi imaginer qu'au lieu d'un compteur par avatar on ait N compteurs (par exemple 349 -premier-, plus un pour l'universel), un compteur pour plusieurs avatars, typiquement le reste de la division de leur id par N afin de réduire la table. Dans ce cas l'avantage est qu'on a une table à un seul row avec en data un array d'entiers sur 4 bytes.
>Le nombre de collisions n'est pas un problème et détecter des proximités entre avatars dans ce cas devient un exercice très incertain (fiabilité de 1 sur 350).

	CREATE TABLE "versions" ("data"  BLOB);

## Tables

### Singleton d'état global du serveur
Ce singleton est un JSON où le serveur peut stocker des données persistantes à propos de son état global : par exemple les date-heures d'exécution des derniers traitements GC, la dhc du dernier backup de la base...

	CREATE TABLE "etat" ("data"	BLOB);


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

### Comptes, avatars, groupes, secrets : signatures 
A chaque connexion d'un compte, si ça fait plus de 20 jours qu'il n'a pas signé, le compte signe pour lui-même, ses avatars et les groupes que ses avatars ont en *contact* :
- la date de signature du compte est aléatoirement celle d'un jour dans les 10 à 20 derniers jours,
- la signature de ses avatars sont tirées aléatoirement dans les 10 derniers jours.
- la signature de ses groupes sont tirées aléatoirement dans les derniers 10 jours à condition que la dernière signature sur la liste ait plus de 20 jours.

Le GC met à jour sur les tables `sga` le flag alerte/disparu. Pour les autres il n'y a que le niveau *disparu* :
- *alerte* : le compte / avatar est resté plusieurs mois sans connexion.
- *disparu* : le compte / avatar / boîte doit être considéré comme disparu.

**Tables `sga sgc sgg sgc` : CP `id`:**

      CREATE TABLE "sgx" (
      "id"  INTEGER,
      "dds"  INTEGER,
      "ad"  INTEGER,
      PRIMARY KEY("id")
      ) WITHOUT ROWID;
      CREATE INDEX "ad_dds_sgx" ON "sgx" ( "ad", "dds" )

- `id` : du compte ou de l'avatar ...
- `dds` : date (jour) de dernière signature.
- `ad` : 0:OK, 1:alerte, 2:disparu

###### GC des comptes, avatars, groupes
La détection par `dds` trop ancienne d'un `compte` 
- détruit le row dans `compte`. 
- un compte est toujours détruit physiquement avant ses avatars puisqu'il apparaît plus ancien que ses avatars.

La détection par `dds` trop ancienne d'un avatar,
- détruit son row dans toutes les tables `av...`.
- transfert ses quotas dans son row `avgrvq` sur la banque et détruit son row `avgrvq`.

La détection par `dds` trop ancienne d'un groupe,
- détruit son row dans toutes les tables `gr...`.
- transfert de ses quotas dans son row `avgrvq` sur la banque et détruit son row `avgrvq`.

Les *disparus* depuis plus d'un an sont détruit par le GC.

###### GC des secrets
Une fois connecté et synchronisé une session de compte dispose de la liste de tous ses secrets.   Si ça plus de X jours qu'il ne l'a pas fait, il pose sa signature sur tous les secrets qu'il référence et qui n'ont pas été signés au cours des X derniers jours.

Le GC détruit tous les secrets non signés (non référencés) dans les N derniers mois.

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
	"lack"  BLOB,
	"mck"	BLOB,
	PRIMARY KEY("id")
	) WITHOUT ROWID;
	CREATE UNIQUE INDEX "dpbh_compte" ON "compte" ( "dpbh" )
	
- `v` : espace des avatars
- `dpbh` : pour la connexion, l'id du compte n'étant pas connu de l'utilisateur.
- `pcbsh` : hash du SHA du PBKFD2 de la phrase complète pour quasi-authentifier une connexion.
- `kx` : clé K du compte, crypté par la X (phrase secrète courante).
- `mck` {} : cryptées par la clé K, map des mots clés déclarés par le compte.
    - *clé* : id du mot clé de 1 à 255.
    - *valeur* : libellé du mot clé.
- `lack` { } : liste des avatars du compte, cryptée par la clé K, 
    - *clé* : id de l'avatar du compte
    - *valeur* :
        - `cle` : clé de l'avatar.
        - `pseudo` : de l'avatar.
        - `clepriv` : clé privée asymétrique.

**Remarques :** 
- un row `compte` ne peut être modifié que par une transaction du compte.
- il est synchronisé lorsqu'il y a deux sessions ouvertes en parallèle sur le même compte depuis 2 browsers.
- chaque mise à jour vérifie que `v` actuellement en base est bien celle à partir de laquelle l'édition a été faite.

### Avatars / groupes : carte de visite
Cette table donne la carte de visite de chaque avatar ou groupe, cryptée par leur clé.

**Table `avgrcv` : CP `id`**

    CREATE TABLE "avgrcv" (
    "id"	INTEGER,
    "v"	INTEGER,
    "cvag"	BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "dhc_avcv" ON "avcv" ( "dhc" )
	
- `id` : id de l'avatar ou du groupe.
- `v` : espace universel. Les transactions ne modifie qu'une seule carte à la fois.
- `cvag` : carte de visite cryptée par la clé de l'avatar ou du groupe. 
  - `photo` : photo ou icône.
  - `info` : court texte informatif.

### Avatars : clé publique RSA
Cette table donne la clé RSA (publique) obtenue à la création de l'avatar : elle permet d'inviter un avatar à être contact lié ou à devenir membre d'un groupe.

**Table `avgrcv` : CP `id`**

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
	- **libre** : A a B pour contact `15` et B peut avoir ou non A pour contact `57`, ces situations sont autonomes l'une de l'autre et ni A ni B ne savent rien du contact éventuel de l'autre. A peut décider de perdre B comme contact et B peut décider de perdre A comme contact, puis éventuellement de reprendre B pour contact sous un nouveau numéro `18`.
	- **lié** : A a B pour contact `15`, B a A pour contact `57` : ces numéros de contacts mutuels sont connus et immuables de part et d'autre. A restreindre la nature de ses échanges avec B mais ne peut plus les rompre tant que B n'a pas disparu.
- soit un groupe G : si A est membre du groupe G sous un numéro de contact 25, il le restera toujours, même résilié ???

A chaque numéro de contact `nc` est associée :
- une première clé de cryptage `c1` pour les secrets éventuellement partagés entre A et son contact B (pour un avatar) ou G (pour un groupe). 
	- si B partage un secret S avec A, la clé et l'identifiant de S sont communiqués à A cryptés par cette clé `c1`.
	- si un membre de G partage un secret S avec A, la clé et l'identifiant de S sont communiqués à A cryptés par cette clé `c1`.
- une seconde clé de cryptage `c2` :
	- si A partage un secret S avec B, la clé et l'identifiant de S sont communiqués à B cryptés par cette clé `c2`.
	- si le contact est un groupe G, `c2` est la clé du groupe.

Dans un contact d'avatar *lié*, il y a deux clés. 
- dans les tables `avc1` et `avcontact`, la clé 1 est toujours celle de l'avatar. 
- quand un avatar A partage un secret avec un avatar B, il crypte *son* exemplaire avec sa clé `c1` et crypte *l'autre* exemplaire pour B avec la clé `c2`.

**Table `avidc1` : CP `ida`:**  
Cette table donne les couples `id + c1` pour chacun des `nc`. Elle énumère tous les avatars et groupes en contact (avec leur `c1` d'accès aux secrets).

    CREATE TABLE "avidc1" (
    "ida"   INTEGER,
    "v"		INTEGER,
    "idc1k"  BLOB,
    PRIMARY KEY("ida")
    ) WITHOUT ROWID;
    CREATE INDEX "ida_v_avcontact" ON "avcontact" ( "ida", "v" )

- `ida` : id de l'avatar A.
- `v` : espace de l'avatar.
- `idc1k` [ ] : table donnant la clé de cryptage `id + c1` tirée aléatoirement pour chaque `nc` (qui est l'index dans cette table). `id` est une redondance puisqu'on le retrouve dans `avcontact` mais ça permet à l'avatar d'avoir la liste de ses contacts en une fois.

**Table : CP `ida nc`:**

    CREATE TABLE "avcontact" (
    "ida"   INTEGER,
    "nc"	INTEGER,
    "v"  	INTEGER,
    "datac1"	BLOB,
    "datak"	BLOB,
    PRIMARY KEY("ida", "nc")
    );
    CREATE INDEX "ida_v_avcontact" ON "avcontact" ( "ida", "v" )

- `ida` : id de l'avatar A
- `nc` : numéro de contact.
- `v` : espace de l'avatar.
- `st` : statut.
	- contact libre avec un avatar : 0
	- contact lié avec un avatar : 2xyz
		- x : 1: en attente, 2:accepté, 3:refusé, 8:résilié, 9:disparu.
		- y : 0/1: A accepte les partages de B.
		- z : 0/1: B accepte les partages de A.
	- contact de groupe : 1xyz
		- x : 2:accepté, 3:refusé, 8:résilié, 9:disparu.
		- y : 1:lecteur, 2:auteur, 3:administrateur.
		- z : plus haut y jamais atteint.
- `datac1` : information cryptée par la clé `c1` associée au `nc`.
	- `id` : `id` de l'avatar ou du groupe.
	- `cle` : suffixe aléatoire (accès à la carte de visite).
	- `nom` : *pseudo de l'avatar* ou *code* du groupe. Pour un parrainage de compte, c'est la phrase complète de reconnaissance (d'où A pourra retrouver le row de parrainage).
	- *pour un contact lié avec un avatar*
		- `c2` : clé `c2`. C'est la clé `c1` de B pour son contact avec A.
		- `dna` : dernière note écrite par A pour B.
		- `dnb` : dernière note écrite par B pour A.
	  - `q1 q2 qm1 qm2` : balance des quotas donnés / reçus par l'avatar à son contact avatar.
  - *pour un contact groupe*
    - `c2` : clé du groupe.
    - `q1 q2` : balance des quotas donnés / reçus par l'avatar au groupe.
- `datak` : information cryptée par la clé K de A.
  - `info` : information libre donnée par A à propos du contact.
  - `mc` : liste des mots clés associés au contact.

Un *contact lié* permet d'échanger un court texte entre A et B pour justifier d'un changement de statut ou n'importe quoi d'autre : en particulier quand A n'accepte pas le partage de secrets avec B, c'est le seul moyen de passer une courte information mutuelle qui n'encombre pas leurs volumes respectifs.

#### Invitation par A de B à lier leurs contacts
C'est requis pour qu'ils puissent partager des secrets et se donner des quotas.

    CREATE TABLE "avinvit" (
    "idb"   INTEGER,
    "dlv"	INTEGER,
    "datapub"  BLOB
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_avinvit" ON "avinvit" ( "dlv" );
    CREATE INDEX "idb_avinvit" ON "avinvit" ( "idb" );

- `idb` : id de B.
- `dlv` :
- `datapub` : crypté par la clé publique de B.
	- `ida` : id de A.
	- `cle` : de A.
	- `pseudo` : de A.
	- `c1` : clé `c1` de A pour ce contact.
	- `nc` : numéro du contact de A (pour que B inscrive le statut ...).

B peut créer un contact chez lui, ou récupérer celui existant chez lui pour A s'il l'avait déjà en contact libre, et inscrire les données de A comme contact *lié* chez lui et réciproquement inscrire sa propre clé `c1` en clé `c2` de A.

### Avatar : parrainage par P de la création d'un compte F (pour un *inconnu* n'ayant pas de compte)

Comme il va y avoir un don de quotas du *parrain* vers son *filleul*, ces deux-là vont avoir un contact *lié* (si F accepte). Toutefois,
- P peut indiquer que son contact est restreint à une simple note (sans partage de secrets).
- F pourra indiquer que son contact est restreint à une simple note (sans partage de secrets).

Un parrainage est identifié par `dpbh` le hash du PBKFD2 du début de la phrase de reconnaissance.

    CREATE TABLE "parrain" (
    "dpbh"  INTEGER,
    "dlv"  INTEGER,
    "st"  TEXT,
    "pbcsh"  BLOB,
    "datax"  BLOB,
    PRIMARY KEY("dpbh")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_parrain" ON "parrain" ( "dlv" )

- `dpbh` : hash du PBKFD2 du début de la phrase secrète de parrainage.
- `dlv` : la date limite de validité permettant de purger les parrainages.
- `st` : trois chiffres : 
  - (1) : 0: invitation lancée, 1: acceptée, 9: refusée
  - (2) : en cas d'acceptation : le parrain accepte (1) ou refuse (0) le partage de secrets avec son filleul.
  - (3) : en cas d'acceptation : le filleul accepte (1) ou refuse (0) le partage de secrets avec son parrain.
- `pcbsh` : hash du SHA de X (PBKFD2 de la phrase complète) pour que l'invité puisse être quasi-authentifié. Le filleul doit se rappeler qu'il a une proposition qui l'attend identifiée par une phrase de contact.
- `datax` : données de l'invitation cryptées par la clé X.
  - `id cle pseudo` : de l'avatar P.
  - `c1` : de P.
  - `nc` : de P.
  - `q1 q2 qm1 qm2` : quotas proposés par le parrain.

**La parrain créé un contact *lié* pour le filleul** dont le pseudo est encore inconnu à ce stade mais il a préparé une `id`, une `clé`, et la clé `c2`.  
La phrase complète est mise à la place du *pseudo*, ce qui permet le cas échéant au parrain de la retrouver (voire d'adapter son invitation).

**Si le filleul ne fait rien à temps** : le GC s'effectuera sur la `dlv` par simple *delete*.

**Si le filleul refuse le parrainage** : le row de P dans `avcontact` est mis à jour et le parrain y lit la raison et le statut. Le row `parrain` est détruit.

**Si le filleul accepte le parrainage :**  
Le filleul crée son compte et son premier avatar dont il donne le pseudo. Les quotas sont prélevés à ce moment. Le row `parrain` est détruit.

### Avatar : rencontre entre A et B
A et B se sont rencontrés dans la *vraie* vie mais ni l'un ni l'autre n'a les coordonnées de l'autre pour,
- soit s'inviter à créer un contact *lié*,
- soit pour B inviter A à participer à un groupe.

Une rencontre est juste un row qui va permettre à A de transmettre à B son `id / clé / pseudo` en utilisant une phrase de rencontre convenue entre eux.  
En accédant à cette rencontre B peut ainsi inscrire A comme contact *libre* : ensuite il pourra normalement l'inviter à un contact *lié* ou l'inviter à un groupe.

Une rencontre est identifiée par `dpbh` le hash du PBKFD2 du début de la phrase de reconnaissance.

    CREATE TABLE "rencontre" (
    "dpbh"  INTEGER,
    "dlv"  INTEGER,
    "pbcsh"  BLOB,
    "datax"  BLOB,
    PRIMARY KEY("dpbh")
    ) WITHOUT ROWID;
    CREATE INDEX "dlv_rencontre" ON "rencontre" ( "dlv" )

- `dpbh` : hash du PBKFD2 du début de la phrase secrète de rencontre.
- `dlv` : la date limite de validité permettant de purger les rencontres.
- `pcbsh` : hash du SHA de X (PBKFD2 de la phrase complète) pour que B puisse être quasi-authentifié.
- `datax` : données de l'invitation cryptées par la clé X.
  - `id cle pseudo` : de A.

### Groupe : liste et détail des membres
- `id` : entier depuis 5 bytes aléatoires.  
- `code` : lisible (comme un nom de fichier) et immuable.
- `cg` : SHA id + 8 bytes aléatoires + code. Permet d'accéder à la liste des membres du groupe

Un groupe est caractérisé par :
- sa carte de visite dans `avgrcv`,
- ses quotas et volumes dans `avgrvq`,
- sa date de dernière signature dans `sgg`,
- la liste des clés `c1` de ses membres dans `grentete`.
- le détail de ses membres dans `grmembre`.
- la liste de ses secrets dans `avsecrets`.

**Table `grlmg` : CP: `idg`**

    CREATE TABLE "grentete" (
    "idg"   INTEGER,
    "v"  INTEGER,
    "st"	INTEGER,
    "mcg" BLOB,
    "idclg"  BLOB,
    PRIMARY KEY("idg")
    ) WITHOUT ROWID;
    CREATE INDEX "idg_v_grentete" ON "grentete" ( "idg", "v" )

- `idg` : id du groupe.
- `v` : espace générique
- `st` : statut : 1)ouvert, 2)fermé, 3)ré-ouverture en vote, 4)archivé 
- `mcg` : liste des mots clés prédéfinis pour le groupe.
- `idclg` [`idm + nc + c1`]: liste indexée par le numéro de membre cryptée par la clé du groupe `cg`. Pour chaque membre actif `nm`, ce qu'il faut pour lui partager un secret :
	- `idm` : l'id du membre.
	- `nc` : son numéro de contact qui lui permettra de retrouver la clé `c1` associée.
	- `c1` : clé pour crypter les données du secrets pour `idm`.

Pour partager un secret avec tous les memebres d'un groupe, une session cliente d'un des membres peut ainsi constituer une _liste de diffusion_ pour créer / mettre à jour les rows `avsecret` (l'idm du membre, son nc et le cryptage de la clé du secret par la clé du groupe).

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
    - changer les statut des membres non animateurs.
    - détruire le groupe.
    - attribuer un statut *permanent* à un secret partagé par le groupe.
- les avatars membres du groupe peuvent s'ils sont auteur / animateur :
	- partager un secret avec le groupe,
	- modifier un secret du groupe selon le statut du secret : 
		- *ouvert* : tous les *auteurs / animateurs* peuvent le modifier.
		- *restreint* : seul le dernier auteur peut le modifier.
		- *archivé* : le secret ne peut plus changer (jamais).
- un nouveau membre peut récupérer la liste de tous les secrets actuels du groupe, le dernier état de tous les secrets non supprimés partagés avec le groupe.
- un animateur peut lancer quand il veut un nettoyage pour détecter les membres qui auraient disparus *et* ne seraient plus auteurs d'aucuns secrets.

#### Invitation par I de M à un groupe G

    CREATE TABLE "grinvit" (
    "idm"   INTEGER,
    "dlv"	INTEGER,
    "datapub"  BLOB);
    CREATE INDEX "dlv_grinvit" ON "grinvit" ( "dlv" );
    CREATE INDEX "idm_grinvit" ON "grinvit" ( "idm" );

- `idm` : id du membre invité.
- `dlv` :
- `datapub` : crypté par la clé publique du membre invité.
	- `idg cle code` : du groupe.
	- `nm` : numéro de membre.
	

### Secrets
- `id` : entier depuis 6 bytes aléatoires. Le reste de la division par 3 indique si c'est un secret personnel, de couple ou de groupe. 
- `cs` : SHA de id + 15 bytes aléatoires. Le contenu d'un secret est crypté par la clé `cs` spécifique de chaque secret.

`cs` est stockée dans le row cryptée selon le cas :
- (0) *secret personnel d'un avatar A* : par la clé K de l'avatar.
- (1) *secret d'un couple d'avatars A et B* : A et B connaissent leurs clé `c1` réciproques, l'une comme l'autre pourrait être employée pour crypter `cs`. Par convention on prend `c1` de l'avatar dont l'id est le plus petit.
- (2) *secret d'un groupe G* : par la clé du groupe G.

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
    "ids"   INTEGER,
    "v"		INTEGER,
    "nsc"	INTEGER,
    "cs"	BLOB,
    "txts"	BLOB,
    "datas"	BLOB,
    PRIMARY KEY("ids")
    ) WITHOUT ROWID;
    CREATE INDEX "ids_dhc_secret" ON "secret" ( "ids", "dhc" )
    CREATE INDEX "nsc_secret" ON "secret" ( "nsc" )

- `ids` : id du secret.
- `v` : espace générique.
- `nsc` : numéro de semaine de création ou 9999 pour un *permanent*.
- `cs` : clé du secret cryptée par la clé K, celle du groupe ou `c1` d'un des deux avatars d'un couple.
- `txts` : texte complet gzippé crypté par la clé du secret. 
- `aps` : données d'aperçu du secret cryptées par la clé du secret.
  - `la` [] : liste des ids des auteurs.
  - `ap` : texte d'aperçu.
  - `st` : 5 bytes donnant :
    - 0:ouvert, 1:restreint, 2:archivé
    - la taille du texte : 0 pas de texte, 1, 2, ... (convention) 
    - la taille de la pièce jointe : 0 pas de pièce, 1, 2 ... (convention)
    - type de la pièce jointe : 0 inconnu, 1, 2 ... selon une liste prédéfinie.
    - version de la pièce jointe afin que l'upload de la version suivante n'écrase pas la précédente.
  - `r` : référence à un autre secret.

### Avatars et groupes : aperçu des secrets
Tout secret a son aperçu (et les références d'accès au secret complet) distribué chez autant d'avatars qu'ayant accès :
- un seul pour un secret personnel,
- deux avatars pour un secret de couple,
- de 1 à N avatars pour un groupe plus l'exemplaire de référence du groupe.

**Table : CP: `ida, idcls`**

    CREATE TABLE "avsecret" (
    "id"	INTEGER,
    "idcs"	BLOB,
    "nc"	INTEGER,
    "v"		INTEGER,
    "nsc"	INTEGER,
    "datas"	BLOB,
    PRIMARY KEY("id", idcls")
    );
    CREATE INDEX "ida_v_avsecret" ON "avsecret" ( "ida", "v" );
    CREATE INDEX "nsc_avsecret" ON "avsecret" ( "nsc" );

- `id` : id de l'avatar ou du groupe.
- `idcs` : `id + cs` id du secret + clé du secret, crypté par la clé `c1` (ou `c2/cg`) du contact `nc` de `id`. Un même secret a donc autant d'identifiants et de clé d'accès à sa clé que d'avatars le partageant.
- `v` : espace de l'avatar.
- `nc` : numéro de contact chez cet avatar
  - pour un couple d'avatar ou un groupe : lui permet de retrouver la clé avec laquelle `idcls` est crypté. 
  - 0 pour l'exemplaire de référence du groupe (c'est toujours la clé du groupe).
  - 0 pour un secret personnel d'avatar (c'est toujours la clé k).
- `nsc` : numéro de semaine de création ou 9999 pour un *permanent*.
- `aps` : données d'aperçu du secret cryptées par la clé du secret.

Pour un secret *supprimé* par son avatar :
- `nsc` vaut -1 par convention.
- `v` donne la version de suppression.
- toutes les autres colonnes sont absentes.

# Todo
### Secret pour un avatar : à ajuster
- mots dièse, flags, path, commentaires
- *suppression* de l'exemplaire d'un avatar

Comment A déclare détruire un secret sans que ceci affecte B ? De même pour un groupe ? Mettre `nc` à -1 dans `avsecret` ? Remettre un statut / mot clé / flags / path dans `avsecret` ? flags : *à lire*, *lu*, *favori* ... ? annotation personnelle ?

### Synchro des cartes de visite :
- la synchro peut être ouverte dès que le contexte de session est prêt.
- au pire il va remonter des CV qu'on n'a pas encore chargées.
- opération de lecture :
    - sur backup : si dhds trop vieille
    - sur vivant :
    - remonte des CV qui *peuvent* être moins récentes que celles connues (remontées par synchro). Simplement les ignorer.

### Sessions
- compte c
- avatars de compte { ac }
  - contacts avatars { a }
  - contacts groupes { g }

**Remontées :**
- compte -> c
- avnotif : -> a (les N4 remontent toujours avec leur secret)
- grmembre -> g
- avinvit -> a
- avcontact -> a
- avgrcv -> ac a g

### Serveurs vivant et de backup
Le serveur de backup est l'image de la base la veille au soir.
- il est accessible en lecture seule.
- sa dhc est une dhc *minimale* : sauvée avant le backup dans l'état il se peut qu'il y ait des rws postérieurs à cette date.

En début de session un compte *peut* avoir des jours / semaines / mois à rattraper, voire tout si la session est en mode incognito : une grande masse de rows peuvent être lus depuis le backup sans bloquer le serveur vivant. Si la dhds de la session cliente est postérieure à la dhc du serveur de backup, ça se passe directement sur le serveur vivant.

La vraie connexion / synchronisation se fait sur le serveur vivant pour avoir les tous derniers mais ça devrait être très légers.

### Connexion
- (1) remonter compte : avatars de compte ac 
- (2) pour chaque ac :
  - contacts
  - invits

Dès que les selects de phase 1 et 2 ne remontent plus rien, on ouvre la synchro mais les  notifs reçues sont mises en attente.
- (3) membres de tous les contacts groupes
- (4) secrets (au moins entêtes)

(5) Début du mode normal : on traite toutes celles en attente et celles au fil de l'eau.

Entête de secrets : par groupe ?  
Secrets complets : par groupe.  
Cartes de visites des contacts : à *l'ouverture* de l'avatar du compte.  
Cartes de visite des membres d'un groupe : à *l'ouverture* du groupe.  
Autant de dhs à gérer dans le client : on peut simplifier en laissant remonter toutes les synchros. Avantage : si un autre compte met à jour sa carte on la voit tout de suite. 

Remontées des volumes / quotas ? Fenêtre spécifique de refresh / affichage
- les quotas changent peu souvent
- les volumes c'est permanent


