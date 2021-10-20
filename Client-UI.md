# Boîtes à secrets - Client

## Données en IDB
En IDB on trouve la réplication de sélections selon l'id d'un compte, avatar ou groupe des rows des tables en base :
- `compte` : le row du compte. Donne la liste des ids `ida` des avatars du compte et leur nom complet (donc clé).
- pour chaque `ida`, les rows de clé `ida` des tables :
  - `invitgr` : invitations reçues par `ida` à être membre d'un groupe. L'union donne la **liste des groupes `idg` (id, clé, nom)** des comptes accédés.
  - `avatar` : entête de l'avatar.
  - `contact` : contacts de `ida`. Donne la **liste de ses contacts** avec leur nom complet (donc clé) pour les cartes de visite.
  - `invitct` : invitations reçues par `ida` à être contact fort et encore en attente.
  - `rencontre` : rencontres initiées par `ida`.
  - `parrain` : parrainages accordés par `ida`.
  - `secret` : secrets de `ida`.
- les rows dont la clé `idg` fait partie de la liste des groupes d'un des `ida` :
  - `groupe` : entête du groupe.
  - `membre` : détails des membres de `idg`. Donne la **liste des membres** avec leur nom complet (donc clé) pour les cartes de visite.
  - `secret` : secrets du groupe `idg`.
- `cv` (issue de `avatar`, `st cva` seulement) : statut et carte de visite des rows dont la clé `id` est, soit un des contacts d'un des `ida`, soit un des membres des groupes `idg`.

Les rows reçus par synchro ou par chargement explicite sur un POST :
- sont décryptés à réception. 
  - pour les données des groupes (`groupe membre secret`), la clé du groupe a été obtenu depuis les rows `invitgr` qui sont toujours obtenus / chargés avant.
  - pour les secrets des contacts, la clé `cc` est obtenue depuis les rows `contact` qui sont obtenus / chargés avant.
- les objets en mémoire sont donc en clair dès leur réception depuis le serveur.

En IDB les contenus des tables sont formés :
- d'une clé simple `id` ou `x`, ou d'un couple de clé `id+y`.
- d'un contenu `data` qui est l'objet en clair sérialisé PUIS crypté par,
  - la clé K du compte pour tous les rows sauf `compte`,
  - la clé X issue de la phrase secrète pour **le** row `compte`.

## Structure en mémoire
Elle comporte :
- un objet `compte`;
- une map d'objets `avatars`, la clé étant l'id de chaque avatar du compte en base 64. La valeur est un objet de classe `Avatar` (voir plus loin).
- une map d'objets `groupes` , la clé étant l'id de chaque groupe en base 64.
La valeur est un objet de classe `Groupe` (voir plus loin).
- une map d'objets `cvs`, la clé étant l'id en base 64 de chaque avatar référencé (avatar du compte, contact d'un avatar du compte, membre d'un groupe). La valeur est un objet de classe `Cv` (voir plus loin).

## Phases d'une session
### Phase A d'authentification du compte
Soit par donnée de la phrase secrète, soit par création d'un compte : au retour de cette phase le row `compte` correspondant est connu et en mémoire, le nom de la base IDB est également connu.

### Phase C de chargement de IDB : mode _avion_ et _synchronisé_ seulement
Toute la base IDB est lue en mémoire dans une map temporaire `idb`, mais pas _compilée_.  
La structure en mémoire compilée est juste amorcée avec :
- l'objet singleton `compte`, 
- la map `avatars` avec juste l'entête des avatars du compte (nom complet, clé),
- les maps `groupes cvs` sont vides. 

Cette lecture mémorise dans une map `versions` une entrée par avatar / groupe.
La valeur est une table de  N éléments : pour un avatar par exemple ce sont 7 compteurs donnant pour cet avatar / groupe la version la plus haute des tables `invitegr avatar contact invitct rencontre parrain secret`.

Par exemple :

    {
    av1 : [436, 512, 434, 418, 517, 718, 932],
    av2 : ... ,
    gr1 : [65, 66, 933],
    ...
    }

Cette map permet de savoir que pour remettre à niveau la table `contact` (la troisième) de `av1` il faut demander tous les rows de versions postérieures à 434.

### Phase R _remise à niveau_ : mode _synchronisé_ et _incognito_ seulement
Elle consiste à obtenir du serveur les rows des tables mis à jour postérieurement à la version connue en IDB.

La session n'est pas opérable durant cette phase.

Après l'étape _amorce_, il y a autant d'étapes _avatar / groupe_ dans cette phase que, 
- d'avatars `avc` du compte cités dans le row compte.
- de groupes accédés `gra` cités dans les rows `invitgr` relatifs à chaque avatar avc. 

Enfin l'étape _finalisation_ vient clore la phase de remise à niveau.

On entre alors dans la phase S _synchrone_ ou l'état des données est au plus près du dernier état cohérent des données en base (par principe possiblement légèrement retardée). Si un incident interrompt cette phase, une nouvelle phase de remise à niveau est lancée, la session n'étant plus opérable jusqu'à la fin de la remise à niveau.

#### État de synchronisation
- `dhsync` : si 0, une remise à niveau est en cours (la map `etapes` existe), sinon on est en phase _synchronisée_ et c'est la date-heure de la dernière transaction sur le serveur que les données reflète.
- `dhv` :  date-heure de vie. Si `dhsync` est non 0, c'est la dernière date-heure de vie constatée de la session, toujours postérieure ou égale à `dhsync`.
- `etapes` : map avec une entrée par avatar / groupe dont la valeur est :
  - 0 : si l'avatar ou le groupe n'a pas encore été remis à niveau;
  - la date-heure de la transaction de remise à niveau si l'étape est passée.

Le triplet `dhsync dhv etapes` est stocké en IDB, c'est un singleton. Quand `etapes` existe, ceci indique,
- à la session courante que la remise à niveau est _en cours_ et son degré d'avancement.
- à une session ultérieure en mode _avion_ que l'interprétation des données est sujette à caution, tous les avatars / groupes ne sont pas connus au même niveau de fraîcheur, certaines cartes de visite peuvent être retardées, voire manquantes.

#### Étape _amorce_
Le décryptage du row `compte` lors de l'authentification a donné la liste des avatars du compte.

Envoi de 2 requêtes :
- 1 - obtention des rows `invitgr` de ces avatars : le décryptage en session de ces rows donne la liste des groupes (et leur clé de groupe).
- 2 - ouverture avec le serveur d'un contexte de synchronisation comportant :
  - le compte avec signature,
  - la liste des avatars du compte avec signature,
  - la liste des groupes accédés avec signature.
  
Après cette requête le Web Socket envoie des notifications dès que des rows sont changés en base de données et relatifs à un de ces éléments d'après leur id. Les listes des avatars du compte et des groupes accédés par le compte sont fixées et suivies.

*Remarque* : 
- la requête 2 commence par vérifier si la version du compte est toujours celle obtenue à l'authentification et si pour chaque avatar du compte, la version est inchangée (donc pas de changement des `invitgr` relatifs à ces avatars).
- s'il y a eu des mises à jour de ces listes, l'étape _amorce_ est reprise.

**IDB est purgée des rows des avatars et groupes** qui sont présents dans IDB en mémoire mais n'apparaissent plus dans les deux listes d'avatars du compte et groupes accédés. Dans la même transaction, le triplet de l'état de synchronisation est stocké (marque le début de la remise à niveau).

#### Déroulement d'une étape _avatar_ pour un `avc` 
Une requête est envoyée au serveur pour récupérer les rows des tables `avatar contact invitct rencontre parrain secret` changés postérieurement aux versions connues en IDB.

Les rows (venant de IDB en mémoire ou récupérés par la requête) sont compilés dans la structure en mémoire.

La complétion de l'étape donne lieu à **une transaction unique** en IDB :
- mise à jour de IDB par insertion, mise à jour, parfois suppression des rows de ces tables.
- mémorisation de l'état de synchronisation.

#### Déroulement d'une étape _groupe_ `gra` 
Comme pour une étape _avatar_ avec les tables `groupe membre secret`.

#### Étape de _finalisation_
Son objet est de récupérer toutes les cartes de visites pour tous les contacts des `avc` et tous les groupes des `gra` :
- liste 1 : liste des ids des avc / gra, dont la carte de visite est absente.
- liste 2 : liste des ids des avc / gra, dont la carte de visite est présente et obtention de la variable `maxvcv`, la plus haute des versions de ces cartes de visite `vcv`.

Envoi d'une requête :
- obtention des cartes de visites de la liste 1 sans condition de `vcv`.
- obtention des cartes de visites de la liste 2 avec `vcv > maxvcv`.
- enregistrement dans le contexte de session de l'union des listes 1 et 2.

Désormais le serveur notifie les mises à jour des cartes de visites intéressant la session.

**Enregistrement en une transaction IDB** des cartes de visites mises à jour et suppression des cartes de visite non référencées.

A cet instant :
- la structure en mémoire est complète et compilée.
- la structure temporaire des rows lus de IDB est détruite.
- l'état n'est pas encore cohérent : des transactions parallèles ont pu effectuer des mises à jour qui sont disponibles dans la queue des notifications du Web Socket.

##### Traitement des notifications reçues par Web Socket
Pendant toute le phase de remise à niveau des notifications de mises à jour ont pu être reçues : elles sont traitées.
- prétraitement des cartes de visites : des contacts et des membres ont pu être ajoutés et n'ont pas (en général) de cartes de visites. Celles-ci sont demandées au serveur qui les ajoutent à la liste des cartes à notifier.
- une seule transaction IDB 
  - met à jour les rows reçus (et la structure en mémoire). 
  - met à jour l'état de synchronisation :
    - `dhsync` contient est la date-heure de la dernière requête / notification reçue.
    - `ddv` = `dhsync`
    - `etapes` est null.

Désormais la session passe en phase _synchrone_.

### Phase _synchrone_
L'utilisateur peut effectuer des actions et naviguer.

La session évolue selon :
- les actions déclenchées par l'utilisateur qui vont envoyer des requêtes au serveur.
- les notifications reçues du Web Socket comportant les rows mis à jour par les transactions du serveur et intéressant la session.

L'état interne de la structure en mémoire reflète le dernier état de notification traité : la date-heure `dhsync` est mise à jour en IDB (avec `dds` = `dhsync`).

Le traitement d'un bloc de notifications s'effectue en deux étapes :
- prétraitement éventuel pour demander les cartes de visite manquantes,
- traitement effectif en mémoire et mise à jour de IDB en une seule transaction.

_**Remarques :**_
- quand un traitement de notification débute, il récupère tous les blocs de notification reçus et an attente de traitement : les suivants sont accumulés en queue pour le traitement ultérieur.
- quand il n'y a pas eu de traitement de notification pendant 5s, `ddv` est écrite en IDB avec la date-heure courante.

### Interruption de synchronisation
- Les actions de l'utilisateur sont bloquées, la requête en cours au serveur est ignorée.
- La queue des notifications est détruite.
- La phase de _remise à niveau_ est enclenchée : la structure en mémoire est détruite, IDB relue.

## `localStorage` et IDB
**En mode *avion*** dans le `localStorage` les clés `monorg-hhh` donne chacune le numéro de compte `ccc` associé à la phrase de connexion dont le hash est `hhh` : `monorg-ccc` est le nom de la base IDB qui contient les données de la session de ce compte pour l'organisation `monorg` dans ce browser.

**En mode *synchronisé***, il se peut que la phrase secrète actuelle enregistrée dans le serveur (dont le hash est `hhh`) ait changé depuis la dernière session synchronisée exécutée pour ce compte :
- si la clé `monorg-hhh` n'existe pas : elle est créée avec pour valeur `monorg-ccc` (le nom de la base pour le compte `ccc`).
- si la base `monorg-ccc` n'existe pas elle est créée.
- l'ancienne clé, désormais obsolète, pointe bien vers le même compte mais ne permet plus d'accéder à ce compte, dont la clé K a été ré-encryptée par la nouvelle phrase.

## Classes

### `global` - singleton
- `compte` :
  - `pcb` : PBKFD2 de la phrase complète **saisie** en session - clé X
  - `pcbh` : Hash de pcb.
  - `idc` : id du compte (après connexion).
  - `clek` : clé K du compte, décryptée par la clé X (après connexion).
- `avatars` : map de clé id de l'avatar
- `groupes` : map de clé id du groupe
- `cvs` : : map de clé id de l'avatar
- `versions` :
- `idb` : map de clé id majeure. Valeur : par table, un row ou une map de rows par id mineure.

### Classe `Compte` - singleton
Image décryptée du row de la table Compte du compte de la session.

### Classe Avatar
Instances stockées dans la map avatars :
- clé : id de l'avatar
- valeur : objet Avatar.

Propriétés - Chacune est un row (singleton) ou une map contenant les rows de la table de même nom dont l'id majeure est celle de l'avatar.
- avidcc : singleton de la classe Avidcc.
- cvsg : singleton de la classe Cvsg, carte de visite de l'avatar. 
- avcontact : map d'instances de la classe Avcontact. La clé est l'index nc du contact.
- `avinvitct` : map des invitations reçues par l'avatar à être contact fort et encore en attente. La clé est l'id de l'invitant (data.ida).
- `avinvitgr` : map des invitations reçues par l'avatar à être membre d'un groupe et encore en attente. La clé est l'id du groupe (datapub.idg).
- `rencontre` : map des rencontres initiées par l'avatar et encore en attente. La clé est prh (hash de la phrase de rencontre).
  - 5 - `secret` : secrets de `ida`.



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

