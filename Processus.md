# Boîtes à Secrets - Procédures


## Création d'un nouveau compte, avatar

### Enregistrement d'un parrainage

**Client**
- Construction du row `parrain`.
- Construction du row `avcontact`.
- Maj du row `avidc1` pour y ajouter le filleul.
- *Argument de l'opération*
  - `sid` : id de la session.
  - `idp` : avatar parrain. (figure dans les 2 av...)

**Opération**
- vérification d'unicité sur le début de la phrase de reconnaissance.
- Stockage / maj des rows.

**Synchronisation** 
- Rows av... transmis aux sessions dont `idp` est l'un des avatars du compte.

### Modification / annulation d'un parrainage
(todo)

### Création d'un nouveau compte sur invitation
**Client**  

**Phase 1 : obtention du row `parrain` sur opération de lecture**
- `dpb` : PBKFD2 du début de la phrase de reconnaissance.
- `pcbs` : SHA du PBKFD2 de la phrase de reconnaissance complète.

**Phase 2 : acceptation**
- Maj du row `parrain` : 
  - `st` : (1) passe à 1. (3) passe à 0 ou 1
- Tirage d'un couple de clés RSA.
- Maj du row `avcontact` de P : pseudo et réponse
- Création du row `compte` : la liste des avatars est réduite à 1.
- Création des row `avcontact avidc1 avrsa` de F.
- *Argument de l'opération*
  - `sid dpb pcbs` : id de la session et données d'authentification.
  - `idap` de l'avatar du parrain.
  - `idcf` du compte du filleul.
  - `idaf` de l'avatar du filleul.
  - `q1 q2 qm1 qm2` : quotas.

**Phase 2 : refus**
- Maj du row `parrain` : `st` : (1) passe à 2.
- Maj du row `avcontact` de P : réponse
- *Argument de l'opération*
  - `sid dpb pcbs` : id de la session et données d'authentification.
  - `idap` de l'avatar du parrain.

**Opération : acceptation**
- maj du row `avcontact` du parrain.
- Insertion des rows `compte avidc1 avcontact avrsa`.
- insertion du row `avgrvq` de `idaf` avec les quotas
- maj du du row `avgrvq` de `idap`
- insertion des deux signatures dans `sga sgc`

**Synchronisation**
- `avcontact` du _parrain_ transmis.
- si acceptation création d'une nouvelle session `sid` : `idcf, idaf`
- `avcontact` : row transmis à `sid`.
- `avidc1` : row transmis à `sid`.
- `compte` : row transmis à `sid`.

### Création d'un nouveau compte privilégié
**Client**  
- construction d'un row `compte` et `avidc1` (vide mais crypté).
- *Argument de l'opération*
  - `sid` : id de la session
  - `pcb` : phrase complète d'administration.
  - `idc` : id du compte.
  - `ida` : id de son avatar.
  - `q1 q2 qm1 qm2` : quotas.

**Opération**
- insertion du row `compte` et `avidc1`.
  - insertion du row `avgrvq` de `ida` avec les quotas.
  - maj du du row `avgrvq` de la banque.
  - insertion des deux signatures dans `sga sgc`.

**Synchronisation**
- création d'une nouvelle session `sid` : `idc, ida`.
- `compte` : row transmis à `sid`.
- `avidc1` : row transmis à `sid`.

### Changement de phrase secrète
**Client**
- constitution du row `compte` avec la nouvelle phrase secrète.
- saisie de l'antivol ?
- *Argument de l'opération*
  - `sid` : id de la session.

**Opération**
- maj du row `compte`.

**Synchronisation**
- compte : row transmis à `sid`.
- envoi d'un message de fermeture de session pour cause de changement de phrase secrète aux sessions du compte `idc`. Moyen de bloquer les sessions d'éventuels hackers ayant récupéré la phrase ... mais aussi possibilité pour un hacker de voler un compte ??? Enregistrement d'une question / réponse _antivol_ ?

**Client : synchronisation de compte**
- si session *synchro*, maj du *LocalStorage*. Traitement aussi à prévoir dans le processus de connexion.

### Nouvel avatar
**Client**
- maj du row `compte`
- *Argument de l'opération*
  - `sid` : id de la session.
  - `idc` : id du compte.
  - `ida` : id de son avatar.
  - `idq` : id de l'avatar du compte offrant les quotas.
  - `q1 q2 qm1 qm2` : quotas passés à l'avatar.

**Opération**
- stockage du row compte.
  - insertion du row `avgrvq` de `ida` avec les quotas.
  - maj du du row `avgrvq` de `idq`.

**Synchronisation**
- maj des sessions du compte `idc` avec ajout de `ida` dans le contexte de session.
- `compte` : row transmis à toute sessions du compte `idc`.

### Maj des mots clés du compte (et _antivol_ ?)
(todo)

### Création / mise à jour d'une carte de visite

### Modification de quotas pour un compte privilégié
(todo)

### Don de quotas
(todo)

## Création d'un groupe, invitation

### Création d'un groupe
**Client**
- maj de `avidc1`
- création d'un `avcontact`
- création de `grlmg`
- création d'un `grmembre`.
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida` :
  - `idg` : id du groupe créé
  - `q1 q2`: quotas donnés (par `ida`)

**Opération**
- vérification de `v` sur `avidc1`.
- stockage des rows.
- maj des quotas entre `idg` et `ida`.
- signature du groupe `idg` dans `sgg`.

**Synchronisation**
- mise à jour des sessions des groupes (compte `idc`) avec ajout du groupe `idg`.
- `avidc1` sur ida
- `avcontact` sur ida
- `grlmg` sur idg
- `grmembre` sur idg

### Invitation à être membre d'un groupe
**Client**
- maj de `grlmg` pour `idm` - `nc c1` sont inconnus.
- création d'un row `grmembre` pour idm
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida` :
  - `idm ncm` :
  - `idg nm` : id du groupe

**Opération**
- vérification de `v` sur `grlmg`.
- stockage des rows `grlmg` `grmembre`.

**Synchronisation**
- mise à jour des sessions des groupes (compte `idc`) avec ajout du membre `idm` pour les cartes de visite à synchroniser.
- `grlmg` sur idg sur `ida` **et** sur `idm`. 
- `grmembre` sur idg sur `ida` **et** sur `idm`.
- ces deux rows vont apparaître comme nouveau en session, avec le statut d'invité pour l'avatar idm, d'où l'incitation à ce qu'il réponde.

### Acceptation de l'invitation à être membre
**Client**
- maj `avidc1` pour le groupe (ncg) et génération d'un c1
- maj `grlmg` pour ajouter `ncg + c1` à l'entrée correspondant à idm.
- maj du row `grmembre` pour idm (statut et dnb)
- *Argument de l'opération*
  - `sid` : de la session.
  - `idm ncm` :
  - `idg nm` : id du groupe

**Opération**
- vérification de `v` sur `grlmg avidc1 grmembre`.
- stockage des rows `grlmg avidc1 grmembre`.

**Synchronisation**
- `avidc1` sur idm
- `grlmg` sur idg
- `grmembre` sur idg

### Résiliation, changement de statut, notification par l'animateur 

### Auto résiliation d'un membre

## Invitation à être contact, mise à jour

### Création d'un contact simple
**Client**  
Le triplet `id cle pseudo` a été récupéré, soit sur un membre de groupe dont A est membre, soit sur une rencontre.  
- maj du row `avidc1` après génération d'un `c1`.
- création d'un row `avcontact`
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida` :
  - `idb` :

**Opération**
- vérification de `v` sur `avidc1`.
- stockage des rows.

**Synchronisation**
- mise à jour des sessions des groupes (compte `idc`) avec ajout du contact `idb` dans leur liste de contacts pour carte de visite.
- `avidc1`
- `avcontact`

### Invitation par A de B à lier leurs contacts
**Client**
Création d'un row `avinvit`.
- *Argument de l'opération*
  - `sid` : de la session.
  - `idb` :

**Opération**
- stockage du row `avinvit`.

**Synchronisation**
- `avinvit` sur idb.

### Acceptation par A de lier son contact avec B
**Client**
B n'était pas un contact de A
- création d'un row `avcontact` pour B
- création d'un nc / c1 pour B et maj `avidc1` pour le nc de B

B était déjà contact de A
- récupération de son nc et c1
- maj de `avidc1` 
- maj du avcontact de B avec en c2 le c1 communiqué par B

Lecture du row `avcontact` (nc de A dans B) de B et maj avec cryptage du `datac1` avec c2 valant le c1 de A.  
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida ncb` :
  - `idb nca` :

**Opération**
- stockage des row `avidc1 avcontact` de A.
- stockage des row `avidc1 avcontact` de B.

**Synchronisation**
- `avidc1 avcontact` (de A) sur ida.
- `avidc1 avcontact` (de B) sur idb.

### Mise à jour du statut d'un contact C statut / tweet
**Client**  
- lecture du row `avcontact` (nc de A dans B) de B
- maj du row `avcontact` (nc de B dans A) de A
- maj du row `avcontact` (nc de A dans B) de B
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida nb` : 
  - `idb nca` :

**Opération**
- vérification de `v` sur les `avcontact`.
- stockage des rows.

**Synchronisation**
- `avcontact` de A
- `avcontact` de B

### Suppression d'un contact simple C
**Client**  
- maj du row `avidc1`
- suppression du row `avcontact`.
- *Argument de l'opération*
  - `sid` : de la session.
  - `idc` : id du contact
  - `ida` :

**Opération**
- vérification de `v` sur `avidc1`.
- stockage de `avidc1`, suppression de `avcontact`.

**Synchronisation**
- `avidc1`
- `avcontact` (suppression)

### Focus sur un groupe ???
Pour mettre à jour la liste des membres en session dont la carte de visite est synchronisée.  
Ou sur un avatar ?  
Avec maj à l'occasion de création de contact ?  


## Création, mise à jour et partage de secrets

## Suppressions d'un avatar, d'un compte

## GC



