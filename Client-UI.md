# Boîtes à secrets - Client

## Classes en mémoire
### global - non persistant
Champs:
- `pcb` : PBKFD2 de la phrase complète **saisie** en session - clé X
- `dpbh` : Hash du PBKFD2 du début de la phrase **saisie** en session.

En mode *avion* dans le localStorage une clé `dpbh` donne le numéro de compte (nom de la base IDB).

### `clekx` - singleton
C'est la clé K crypté par la phrase secrète du compte.  
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

