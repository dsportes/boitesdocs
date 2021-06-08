# Boîtes à Secrets - Procédures


## Invitation / création d'un nouveau compte, avatar, groupe
### Enregistrement d'une invitation
**Client**
- Construction du row `avinvit`.
  - si le parrain refuse d'être un contact `base pseudo` n'est pas communiqué.
- *Argument de l'opération*
  - `sid` : id de la session.
  - `ida` : avatar demandeur.

**Opération**
- vérification d'unicité sur le début de la phrase de reconnaissance.
- Simple stockage du row.

**Synchronisation** 
- Row transmis aux sessions dont `ida` de l'argument est l'un des avatars du compte.

### Modification d'une invitation
(todo)

### Création d'un nouveau compte sur invitation
**Client**  

**Phase 1 : obtention du row `avinvit` sur opération de lecture**
- `dpb` : PBKFD2 du début de la phrase de reconnaissance.
- `pcbs` : SHA du PBKFD2 de la phrase de reconnaissance complète.

**Phase 2 : acceptation**
- Maj du row `avinvit` : 
  - `st` : (1) passe à 1. (3) passe à 2 ou 3
  - `ni` : réponse.
- Création du row `avlstavgr` (liste vide ou avec un terme si le contact est à établir).
- Création du row `avcontact` : seulement si le contact est à établir.
- Création du row `compte`
  - la liste des avatars est réduite à 1.
- Création du row `avnotif` : seulement si le contact est à établir.
- *Argument de l'opération*
  - `sid dpb pcbs` : id de la session et données d'authentification.
  - `st` (3)
  - `idap` de l'avatar du parrain.
  - `idcf` du compte du filleul.
  - `idaf` de l'avatar du filleul.
  - `q1 q2 qm1 qm2` : quotas.

**Phase 2 : refus**
- Maj du row `avinvit` : 
  - `st` : (1) passe à 2.
  - `ni` : réponse.
- *Argument de l'opération*
  - `sid` : id de la session.
  - `dhc` : du row `avinvit` pour contrôle de réponse parallèle.
  - `st` (3)
  - `idap` de l'avatar du parrain.

**Opération**
- vérification de `dhc` de `avinvit`.
- Simple stockage des rows `compte` et `avlstavgr` (toujours), `avcontact` et `avnotif` quand ils sont présents.
- Si acceptation :
  - insertion du row `avgrvq` de `idaf` avec les quotas
  - maj du du row `avgrvq` de `idap`
  - insertion des deux signatures dans `sga sgc`

**Synchronisation**
- si acceptation création d'une nouvelle session `sid` : `dhc, idcf, idaf`
- `avnotif` : row transmis aux sessions dont `idap` en argument est l'un des avatars du compte.
- `avcontact` : row transmis à `sid`.
- `avlstavgr` : row transmis à `sid`.
- `compte` : row transmis à `sid` (permet à la session de récupérer `dhc`, aka `dhds`).

### Création d'un nouveau compte privilégié
**Client**  
- construction d'un row `compte` et `avlstavgr` (vide mais crypté).
- *Argument de l'opération*
  - `sid` : id de la session
  - `pcb` : phrase complète d'administration.
  - `idc` : id du compte.
  - `ida` : id de son avatar.
  - `q1 q2 qm1 qm2` : quotas.

**Opération**
- stockage du row compte.
  - insertion du row `avgrvq` de `ida` avec les quotas.
  - maj du du row `avgrvq` de la banque.
  - insertion des deux signatures dans `sga sgc`.

**Synchronisation**
- création d'une nouvelle session `sid` : `dhc, idc, ida`.
- `compte` : row transmis à `sid` (permet à la session de récupérer `dhc`, aka `dhds`).
- `avlstavgr` : row transmis à `sid`.

### Changement de phrase secrète
**Client**
- constitution du row `compte` avec la nouvelle phrase secrète.
- *Argument de l'opération*
  - `sid` : id de la session.

**Opération**
- contrôle de la `dhc` du compte.
- stockage du row `compte`.

**Synchronisation**
- compte : row transmis à `sid`.
- envoi d'un message de fermeture de session pour cause de changement de phrase secrète aux sessions du compte `idc`.

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

### Maj des mots clés du compte
(todo)

### Création / mise à jour d'une carte de visite

### Modification de quotas pour un compte privilégié
(todo)

### Don de quotas
(todo)

### Nouveau groupe
**Client**
- maj de `avlstavgr`
- création d'un `avcontact`
- création de `grlmg`
- création d'un `grmembre`.
- *Argument de l'opération*
  - `sid` : de la session.
  - `idc` :
  - `ida` :
  - `idg` : id du groupe créé
  - `q1 q2`: quotas donnés (par `ida`)

**Opération**
- vérification de `dhc` sur `avlstavgr`.
- stockage des rows.
- maj des quotas entre `idg` et `ida`.
- signature du groupe `idg` dans `sgg`.

**Synchronisation**
- mise à jour des sessions des groupes (compte `idc`) avec ajout du groupe `idg`.
- `avlstavgr`
- `avcontact`
- `grlmg`
- `grmembre`

## Invitation à être contact, mise à jour
### Nouveau contact
Soit il s'agit de l'initiative de A de créer un contact C, soit A intervient suite à une notification émise par C à A (C vient de créer A comme contact pour lui) et créé le contact.  
Sur notification le principe est de créer le contact à réception de la notification : la session cliente marque comme *nouveau* le contact C et ça sera à A de changer le statut / répondre, voire de supprimer le contact.

**Client**  
- Récupération de *base pseudo* d'un membre d'un groupe ou d'un contact d'un autre avatar du compte ou de la notification.
- maj du row `avlstavgr`
- création d'un row `avcontact`
- création d'un row `avnotif`
- *Argument de l'opération*
  - `sid` : de la session.
  - `idc` : id du contact
  - `ida` :

**Opération**
- vérification de `dhc` sur `avlstavgr`.
- stockage des rows.

**Synchronisation**
- mise à jour des sessions des groupes (compte `idc`) avec ajout du contact `idc` dans leur liste de contacts pour carte de visite.
- `avlstavgr`
- `avcontact`
- `avnotif`

### Mise à jour du statut d'un contact C / tweet / information / mots clés
**Client**  
- maj du row `avcontact`
- création d'un row `avnotif`
- *Argument de l'opération*
  - `sid` : de la session.
  - `idc` : id du contact
  - `ida` :

**Opération**
- vérification de `dhc` sur `avlstavgr`.
- stockage des rows.

**Synchronisation**
- `avcontact`
- `avnotif`

### Suppression d'un contact C
**Client**  
- maj du row `avlstavgr`
- création d'un row `avnotif`
- *Argument de l'opération*
  - `sid` : de la session.
  - `idc` : id du contact
  - `ida` :

**Opération**
- vérification de `dhc` sur `avlstavgr`.
- stockage des rows, suppression de `avcontact`.

**Synchronisation**
- `avlstavgr`
- `avcontact` (suppression)
- `avnotif`

## Invitation à être membre d'un groupe

### Focus sur un groupe ???
Pour mettre à jour la liste des membres en session dont la carte de visite est synchronisée.  
Ou sur un avatar ?  
Avec maj à l'occasion de création de contact ?  


## Création, mise à jour et partage de secrets

## Suppressions d'un avatar, d'un compte

## GC



