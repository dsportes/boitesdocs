# Boîtes à secrets - Client

## Données en IDB et en mémoire
En IDB on trouve la réplication telle quelle de sélections des rows tables en base :
- `compte` : le row du compte donne le liste des ids `ida` des avatars du compte.
- les rows de clé `ida` des avatars du compte des tables :
  - 0 - `avidcc` : ce row donne la liste des contacts de `ida` (avatars contacts et groupes accédés par `ida`).
  - 1 - `avcontact` : détails des contacts de `ida`.
  - 2 - `avinvitct` : invitations reçues par `ida` à être contact fort et encore en attente.
  - 3 - `avinvitgr` : invitations reçues par `ida` à être membre d'un groupe et encore en attente.
  - 4 - `rencontre` : rencontres initiées par `ida`.
  - 5 - `secret` : secrets de `ida`.
  - 6 - `cvsg` : le row carte de visite de `ida`.
- les rows dont la clé `idg` fait partie de la liste des groupes contacts d'un des `ida` :
  - 0 - `grlmg` : ce row donne la liste des membres du groupe (`id` et `nc` numéro de contact).
  - 1 - `grmembre` : détails des membres de `idg`.
  - 2 - `secret` : secrets du groupe `idg`.
  - 3 - `cvsg` : le row carte de visite de `idg`.
- `cvsg` : les rows dont la clé `id` est, soit un avatar / groupe contact d'un des `ida`, soit un des membres des groupes `idg`.

En IDB les contenus sont l'image en base, donc cryptés.

En mémoire les rows sont décryptés / compilés.

### Map en mémoire `maxv`
Cette map mémorise pour, le compte, chaque { avatar / groupe }, les cartes de visite, la plus haute version du ou des rows changés en mémoire pour chacune des 1, 7 ou 4 tables. Elle est donc initialisée en début de session, soit vide (mode avion), soit depuis le contenu de IDB chargé en mémoire.

Lorsque la mémoire locale est resynchronisée, par exemple pour la table `avcontact` de l'avatar ida, le résultat retourne les rows sélectés de version postérieure à celle de dernière synchronisation pour cette table et cet avatar.  
On en déduit le numéro de version max de cet id / table.

Cette map comporte,
- une entrée pour le compte ("0"), 
- une pour chaque avatars de la liste des avatars du compte,
- une par groupe de la liste des groupes accédés par un des avatars du compte, 
- plus une de clé 1 pour les cartes de visite. 

La valeur est une table de  N éléments : pour un avatar par exemple représentant les 7 compteurs max correspondant aux dernières synchronisation des tables `avidcc avcontact avinvitgct avinvitegr rencontre secret cvsg`.

Par exemple :

    {
    "0" : [203],
    av1 : [434, 436, 512, 434, 418, 718, 932],
    av2 : ... ,
    gr1 : [65, 66, 65, 933],
    ...
    "1" : [987]
    }

Cette map permet de savoir que s'il faut resynchroniser la table `avcontact` (la seconde) de `av1` il faut redemander tous les rows de versions postérieures à 436 : on en obtiendra le numéro par exemple 732 de la plus haute version de mise à jour d'un `avcontact` de `av1`.

## Principes de synchronisation
L'état de synchronisation est mémorisé en mémoire et en IDB et se fait par éléments à synchroniser :
- un élément pour le compte,
- deux éléments par avatars : un pour toutes les tables sauf secret et l'autre pour secret.
- deux éléments par groupes : un pour toutes les tables sauf secret et l'autre pour secret.
- un élément pour les cartes de visites des avatars contacts d'un avatar du compte et des membres des groupes.

Une session est une succession de phases de synchronisation : si tout se passe bien il n'y a qu'une phase mais si une rupture de synchronisation apparaît (clôture du Web Socket) une nouvelle phase est relancée. En IDB l'image courante de la phase courante est sauvegardée.

Une phase de synchronisation a plusieurs étapes :
- **I - initialisation** : la liste des compte, avatars, groupes est en construction. Requêtes :
  - 1 - obtention du row compte -> liste des avatars du compte.
  - 2 - obtention des entêtes (et cartes de visites) de ces avatars : -> liste des groupes
  - 3 - enregistrement au serveur de la liste des avatars du compte et des groupes dont il faut notifier les mises à jour par les autres sessions parallèles.
- **RNI - remise à niveau incrémentale *élément par élément***. Pour chaque élément,
  - 1 - requête d'obtention des rows postérieurs aux versions détenues en session.
  - l'élément est marqué synchrone, les notifications reçues par Web Socket le concernant sont désormais prises en compte en session.
- **CV - (re)mise à niveau des cartes de visite** des contacts et membres. Cette liste est transmise au serveur par une requête qui,
  - retourne les cartes de visites,
  - enregistre les ids dont l changement de carte de visite est à notifier.
  - cette étape n'est enclenchée que quand aucun élément n'est plus à remettre à niveau.
- **Sync - quand il n'y a plus d'éléments à remettre à niveau** la session est *synchrone* : l'image en IDB et en mémoire est complète et synchronisée avec  celle du serveur. Les notifications de changement par Web Socket sont traitées et maintiennent cette synchronisation. 

Si au cours de la session il y a par exemple un groupe supplémentaire, la liste des éléments change : un ou plusieurs éléments se retrouvent en état RNI, la session n'est plus OK mais en RNI.

#### `dhsync` : date heure de synchronisation
Cette date-heure est la plus récente de :
- celle de la dernière requête de remise à niveau,
- celle du dernier traitement des notifications reçues par Web Socket,
- de la date-heure courante à 5s près.

Tous les éléments qui sont en état *synchrone* peuvent être considérés comme étant à jour à `dhsync` (puisqu'aucune notifications non traitées n'est pendante).

### `etatsync` : état de synchronisation
Cet objet contient :
- `dhsync` :
- `nbnws` (mémoire seulement, pas IDB): nombre de notifications Web Socket reçues et en attente de traitement. 0 à l'initialisation.
- `nbeltrn` (mémoire seulement, pas IDB): nombre d'élément à remettre à niveau. Ils sont comptés à l'initialisation.
- `eltsync` : une map avec une entrée par élément à synchroniser et pour valeur un couple de date-heures :
  - la première pour l'état général de l'élément,
  - la seconde pour les secrets.
  - une valeur de 0 signifie que la mémoire est vide pour cet élément,
  - une valeur `dh1` signifie que cet élément a été mis à niveau à cette date-heure mais n'est pas synchronisé (il est donc en retard),
  - une valeur de 1 signifie que cet élément est *synchrone*, donc supposé être à niveau de la date-heure `dhsync`.

### Étape d'initialisation
L'état de synchronisation est lu depuis IDB : 
- toutes les date-heures des éléments marqués 1 sont mis à la valeur `dhsync`. Ils ne sont plus synchrones.
- les date-heures des nouveaux éléments après les trois requêtes d'initialisation sont mises à 0 : ces éléments n'ont pas encore été chargés.
- les éléments qui ne sont plus cités après les requêtes d'initialisation sont supprimés de IDB et de `etatsync`.
- à la fin de cette étape, aucun élément n'est *synchrone*, tous sont soit pas chargés du tout, soit en retard, bref à remettre à niveau.

### Remises à niveau
Les remises à niveaux des éléments interviennent élément par élément :
- `dhsync` est mise à la date-heure de la requête de mise à niveau,
- la date-heure de l'élément est mise à 1 (il est *synchrone*), les notifications par Web Socket le concernant sont traitées au fil de l'eau (et enregistrées dans IDB).

### Vie courante synchrone
Tous les éléments sont en état *synchrone*. Des événements peuvent survenir :
- arrivée d'un bloc de notifications par Web Socket : les rows concernant des éléments en état *synchrone* sont enregistrés et `etatsync` est mis à jour en IDB avec pour `dhsync` la date-heure de la notification. L'état global reste *synchrone* (`nbeltrn` est toujours 0).
- une opération ou une notification fait apparaître un nouvel élément à synchroniser (par exemple l'inscription comme membre à un nouveau groupe) : le ou les éléments sont en remise à niveau, `nbeltrn` est incrémenté. La session n'est plus *synchrone*. 

#### Mise à jour des cartes de visite
Le statut *alerte* ou *disparu* est véhiculé avec la carte de visite.  
Les cartes de visite modifiées sont notifiées par Web Socket. Mais une notification ou une opération peut aussi augmenter la liste des ids dont la carte de visite est surveillé :
- une opération permet de la récupérer,
- cette opération enregistre l'id nouvelle à surveiller par le serveur pour la session afin que les mises à jour ultérieures soient notifiées par Web Socket.

## Classes en mémoire
### Global - non persistant
Champs:
- `pcb` : PBKFD2 de la phrase complète **saisie** en session - clé X
- `dpbh` : Hash du PBKFD2 du début de la phrase **saisie** en session.

En mode *avion* dans le `localStorage` les clés `monorg-hhh` donne chacune le numéro de compte `ccc` associé à la phrase de connexion dont le hash est `hhh` : `monorg-ccc` est le nom de la base IDB qui contient les données de la session de ce compte pour l'organisation `monorg` dans ce browser.

**En mode synchronisé**, il se peut que la phrase secrète actuelle enregistrée dans le serveur (dont le hash est `hhh`) ait changé depuis la dernière session synchronisée exécutée pour ce compte :
- si la clé `monorg-hhh` n'existe pas (cas 1): elle est créée avec pour valeur `monorg-ccc` (le nom de la base pour le compte `ccc`).
- si la base `monorg-ccc` n'existe pas elle est créée.
- idéalement dans le cas 1 il faudrait supprimer la clé `monorg-aaa` quand `aaa` est le hash de l'ancienne phrase secrète : par simplification la clé monorg-aaa restera mais sera inutilisable (aaa est donnée par l'ancienne phrase et la base est utilisable avec une phrase ultérieure).

### `clekx` - singleton
C'est la clé K cryptée par la clé X.  
En cas de changement de clé, soit émise sur cet appareil, soit reçu du serveur, ce singleton est réécrit.

### `etat` - singleton
Ce singleton est persistant crypté par la clé K et donne l'état de synchronisation initiale. 
**Données globales persistantes**
- `idc` : id du compte.
- `v` : version du compte.
- avatars { } : clé : id de l'avatar, valeur : version de sa mise à jour. 
- synchro des photos des contacts :
    - clé : id de l'avatar du compte
    - valeur : date-heure de dernière synchro par *ouverture* de l'avatar
- synchro des photos des membres :
    - clé : id du groupe
    - valeur : date-heure de dernière synchro par *ouverture* du groupe 
- liste des secrets d'avatars persistants :
	- clé : id de l'avatar.
	- valeur : date-heure de dernière synchronisation.
- liste des secrets de groupe persistants :
	- clé : id du groupe.
	- valeur : date-heure de dernière synchronisation.

### `cptvq` - singleton
C'est une map avec une entrée par avatar du compte / groupe du compte donnant ses compteurs de volume et ses quotas.

### `compte` - singleton
Sa clé est 1 et c'est le seul objet crypté par la clé
**Données du compte**
- `id` :
- `v` :
- `dhc`
- `pcbs` : Permet de détecter si la phrase complète a été changée sur le serveur. En *avion* permet d'authentifier le compte en vérifiant la concordance entre `pcb` (global) et `pcbs`.
- `k` : clé du compte.
- `mcs` {} : map des mots clés déclarés par le compte.
    - clé : id du mot clé (2c).
    - valeur : libellé du mot clé.
- `avatars` [] : liste des noms longs des avatars du compte.
- `la` (calculés au chargement): liste des ids des avatars du compte.

### `carte` - clé : id de l'avatar
Les objets sont persistants cryptés par la clé k du compte. 
- `dhc`
- `photo`
- `info`
- `alerte` : orange / rouge : de nombreux mois sans connexion.

### Index des avatars (non persisté)
Cette map a une entrée par avatar *externes*, construite par redondance de `avatar.contacts` et `groupe.membres`.
- `nc` : nom complet
- `cle` :
- `lc` [] : liste des avatars du compte dont il est contact
- `lg` [] : liste des groupes du compte dont il est membre

### `avatar` - clé : id de l'avatar du compte
Les objets sont persistants cryptés par la clé k du compte.
- `id` :
- `v` :
- `nc` : obtenu du row `compte`
- `cle` (calculée depuis nc) : 
- `contacts` {} : obtenu des rows `contact` (depuis row / `datac` / `dataa` ou `datab`).
  - clé : id du contact
  - valeur {} : `dhc / nca ncb na nb s pc sta stb / cle infoa mca`. `cle` est la clé du contact.
- `membres` {} : obtenu des rows `membre`
  - clé : id du contact
  - valeur {} : `...`.
- `dctr` {} : demandes de contacts *reçues*
- `invgr` {} : invitations à un groupe *reçue*
- `cext` {} : demandes de contacts externes *émises*.


### `groupe` - clé : id du groupe
Les objets sont persistants cryptés par la clé k du compte.

Obtenu d'un row de `groupe` dont un des avatars du compte est membre
- `dhc`
- `mc` 
- `ferme`
- `arch`

Obtenu du row de `membre` dont l'un des avatars du compte est membre:
- `ncg` : nom complet du groupe
- `cleg` (calculée) : clé du groupe
- `lm` [] : liste des avatars d du compte membre de ce groupe. ?

Obtenu des rows `invg` dont un des membres est invitant :
- `invg` {} : invitations émises par un membre du groupe

Obtenu des rows `membre` de ce groupe :
`membres` {} :
	- clé : id du membre
	- valeur : 
		- `q1 q2 nca vote st`
		- si le membre est un des avatars du groupe : `info mc`

### secret - clé : id du secret
**Obtenu de secret :**
- idg
- perm
- suppr
- dhc
- mc
- ida
- vs
- vp
- t
- m
- r
- tc

**Obtenu de secretcc :**
- cc {} :
    - clé : id
    - valeur : { perm, mc }

## Opérations de mise à jour
L'état des consommations d'un compte est une requête spéciale, sans synchro et qui réintègre les quotas des avatars : ça peut se faire à la connexion pour disposer des ressources dans la session (à rafraîchir explicitement donc en cours de session).

#### Connexion et création de compte
Créé / retourne les objets compte et de ses avatars. En session, ça met à jour ces objets en IDB, hors de toute synchro qui démarre après la connexion.

Connexion  
Création d'un compte privilégié + avatar  
Acceptation d'un parrainage de création de compte + avatar -> cext du parrain
Refus d'un parrainage  

#### Compte
Enregistrement / maj d'un parrainage -> cext du parrain

Refus d'une proposition de contact externe -> cext du demandeur 
Refus d'une invitation groupe externe -> cext de l'invitant 

Changement de phrase secrète -> compte 
Maj des mots clés -> compte 
Don de quotas  
- à un avatar -> compte C + avatar A2
- à un groupe

Suppression du compte

#### Avatar
Nouvel avatar
Maj CV
Connexion, maj de DMA  
Destruction d'un avatar

***Proposition de contact interne***   
Proposition de contact  
Maj message / dlv d'une proposition  
Suppression d'une proposition  
Refus d'une proposition de contact  

***Proposition de contact externe***   
Proposition de contact  
Maj message / dlv d'une proposition  
Suppression d'une proposition  

***Invitation interne à un groupe***  
Invitation  
Maj message / dlv d'une invitation  
Suppression d'une invitation  
Refus d'invitation

***Invitation externe à un groupe***  
Invitation  
Maj message / dlv d'une invitation  
Suppression d'une invitation  

#### Contact
Acceptation d'une proposition de contact (création d'un contact)
Acceptation d'une proposition externe de contact (création d'un contact)

Maj d'un contact : info, notification, statut  
Disparition d'un contact  

#### Groupe
Création d'un groupe  
Fermeture d'un groupe  
Vote d'ouverture  
Archivage / désarchivage
Don de quota

***Membre***  
Acceptation d'une invitation interne (création d'un membre)  
Acceptation d'une invitation externe (création d'un membre)  

Changement de statut  
Maj de info, mots clés
Résiliation  

#### Secret
Création d'un secret de groupe  
Création d'un secret de groupe avec cc  
Création d'un secret personnel avec / sans cc

Maj du texte / pièce jointe  
Maj mots clés
Permanent groupe  
Permanent cc  

Destruction secret groupe
Destruction d'une copie

