# Boîtes à secrets - Client

## Données en IDB
En IDB on trouve la réplication de sélections selon l'id d'un compte, avatar ou groupe des rows des tables en base :
- `compte` : LE row du compte. Donne la liste des ids `ida` des avatars du compte et leur nom complet (donc clé).
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
- sont décryptés à réception et transformés en objets dont tous les champs sont en clair. 
  - pour les données des groupes (`groupe membre secret`), la clé du groupe a été obtenu depuis les rows `invitgr` qui sont toujours obtenus / chargés avant.
  - pour les secrets des contacts, la clé `cc` est obtenue depuis les rows `contact` qui sont obtenus / chargés avant.
- les objets en mémoire sont donc en clair dès leur réception depuis le serveur.

En IDB les contenus des tables sont formés :
- d'une clé simple `id` ou `x`, ou d'un couple de clé `id+y`.
- d'un numéro de version `vs` du schéma de data. Pour chaque objet, data est dé-sérialisé à la lecture, puis si la version actuelle du schéma est supérieure, l'objet est transformé dans le dernier schéma. Il est toujours écrit en IDB selon la version la plus récente.
- d'un contenu `data` qui est l'objet en clair sérialisé PUIS crypté par,
  - la clé K du compte pour tous les rows sauf `compte`,
  - la clé X issue de la phrase secrète pour **le** row `compte`.

## Structure en mémoire
C'est un _store_ (vuex) de nom `db` :

    {
    compte: null,
    avatars: {},
    contacts: {},
    invitcts: {},
    invitgrs: {},
    groupes: {},
    membres: {},
    secrets: {},
    parrains: {},
    rencontres: {},
    cvs: {}
    }

- `compte` : un objet dont la clé IDB est par convention 1 (et non l'id du compte).
- `avatars` : une map d'objets, la clé étant l'id de chaque avatar du compte en base 64. La valeur est un objet de classe `Avatar` (voir plus loin).
- `groupes` : une map d'objets , la clé étant l'id de chaque groupe en base 64. La valeur est un objet de classe `Groupe` (voir plus loin).
- `cvs` : une map d'objets, la clé étant l'id en base 64 de chaque avatar référencé (avatar du compte, contact d'un avatar du compte, membre d'un groupe). La valeur est un objet de classe `Cv` (voir plus loin).
- `contacts invitcts invitgrs secrets` : la map comporte un premier niveau par id de l'avatar et pour chaque id une map par l'identifiant complémentaire (ic ni ni ns).
- `membres secrets` : la map comporte un premier niveau par id du groupe et pour chaque id une map par l'identifiant complémentaire (im ns).

## Pages
### Org : `/`
Page racine permettant de choisir son organisation.  
On revient à cette page si dans l'URL on n'indique pas de code organisation ou un code non reconnu.

### Login : `/_org_`
Page de connexion à un compte ou de création d'un nouveau compte.

### Synchro : `/_org_/synchro`
Dès l'identification d'un compte, cette page s'affiche. Elle ne permet pas d'action mais affiche l'état de chargement / synchronisation du compte.  
Elle enchaîne, 
- a) soit sur la page `Compte` an cas de succès, 
- b) soit en retour vars la page `Login` en cas de déconnexion.

### Compte : `/_org_/compte`
Dès que les données du compte sont charhgées, voire partiellement, cette page s'affiche et donne la synthèse du compte, la liste de ses avatars et des groupes auxquels il accède.

Navigations possible :
- `Login` : en cas de déconnexion
- `Avatar` : vers l'avatar _sélectionné_
- `Groupe` : vers le groupe _sélectionné_

### Avatar : `/_org_/avatar`
Détail d'un avatar du compte.

Navigations possibles :
- `Login` : en cas de déconnexion
- `Compte` : retour à la synthèse du compte.

### Groupe : `/_org_/groupe`
Détail d'un groupe accédé par le compte.

Navigations possibles :
- `Login` : en cas de déconnexion
- `Compte` : retour à la synthèse du compte.

### Panneaux latéraux
#### Menu
Infos et boutons d'actions (affichage de boîtes de dialogue, etc.)

#### Répertoire des contacts
Tous les avatars connus en tant que contact ou membre participant aux groupes accédés par le compte.

## Actions et opérations
### Actions
Elles n'affectent que l'affichage, la visualisation des données. Elles ne changent pas l'état des données du compte, ni sur IDB ni sur le serveur central.

Elles ne font pas d'accès ni à IDB ni au réseau, sauf les actions spéciales de **ping** :
- _ping du serveur_ : pas en mode _avion_.
- _ping DB de la base de l'organisation sur le serveur_ : il faut que cette organisation soit connue, pas en mode _avion_.
- _sélectionné_ : il faut que le compte soit identifié, pas en mode _incognito_.

### Opérations
Une opération modifie l'état des données du compte, en mémoire et **sur IDB et/ou le serveur** : il y a donc des opérations sensibles à l'interruption d'accès au serveur, d'autres sensibles à l'indisponibilité de IDB et enfin d'autres sensibles aux deux.

Une opération s'exécute toujours dans le cadre d'une **session**, c'est à dire avec un **compte identifié ou en cours d'identification** (donc pas forcément encore authentifié ni créé).
- si la session est en mode synchronisé ou incognito, une session WebSocket est ouverte.
- si la session est en mode synchronisé ou avion, la base IDB est accessible et ouverte.

#### Opérations `UI` _standard_ initiées par UI
C'est le cas de l'immense majorité des opérations : elles sont interruptibles par l'utilisateur (quand il en a le temps) par appui sur un bouton.

Aucune action ou nouveau lancement d'opérations ne peut avoir lieu quand une opération UI est déjà en cours, sauf la demande d'interruption de celle-ci.

Trois événements peuvent interrompre une opération UI :
- l'avis d'une rupture d'accès au réseau (WebSocket ou sur un accès POST / GET).
- l'avis d'une impossibilité d'accès à IDB.
- une demande d'interruption de l'utilisateur.

La détection d'un de ces événements provoque une exception BREAK qui n'est traitée que sur le catch final de l'opération (elle doit être re-propagée telle quelle sans traitement sur les appels internes): dès détection l'opération ne fait rien qu'essayer d'en faire le moins possible - propager l'exception.

Le traitement final du BREAK consiste à dégrader le mode de la session en **Avion** ou **Visio** ou **Incognito** selon les états IDB et NET (s'il ne l'a pas déjà été).

##### Opérations de chargement / synchronisation
Ces opérations sont les premières à s'exécuter dans une session (et ne s'exécute plus dans la session). Elles ont deux phases :
- authentification un compte : en cas d'échec c'est la clôture de la session et le retour à la page de Login.
- chargement des données locales et / ou celles sur le serveur : en cas d'échec / interruption volontaire la session est dégradée.

Il y a donc un moment où les opérations ont un comportement normal vis à vis des interruptions alors qu'avant la seule issue est la déconnexion.

#### Opérations `WS` _WebSocket_ initiées par l'arrivée d'un message sur WebSocket
Une seule opération de ce type peut se dérouler à un instant donné.

Elles ne sont pas interruptibles, sauf de facto par la rupture de la liaison WebSocket (voire en conséquence d'une action de déconnexion).

Deux événements peuvent interrompre une opération WS :
- l'avis d'une rupture d'accès au réseau (WebSocket ou sur un accès POST / GET).
- l'avis d'une impossibilité d'accès à IDB.

La détection d'un de ces événements provoque une exception BREAK qui n'est traitée que sur le catch final de l'opération (elle doit être re-propagée telle quelle sans traitement sur les appels internes). 

Le traitement final du BREAK consiste à dégrader le mode de la session en **Avion** ou **Visio** selon les états IDB et NET (s'il ne l'a pas déjà été).

#### Opérations avec demandes d'options à l'utilisateur
Une opération `UI` peut bloquer sur un `await` de demande d'option à l'utilisateur : l'opération est débloquée derrière `await` avec le choix fermé que l'utilisateur a opéré parmi ceux proposés.

> In fine les opérations ne sortent jamais en exception.

### Boîtes de dialogue
Leur affichage est toujours commandée par une variable _vuex_ : dans n'importe quel endroit du code il suffit donc de basculer leur variable d'affichage pour que la boîte apparaisse.

Leur contenu dépend pour l'essentiel de l'état de la session, en partie de son état dans _vuex_.

## Modes
### Avion
- pas d'accès au réseau, pas de session WebSocket.
- les seules opérations possibles mettent à jour IDB : enregistrement de secrets pour mise à jour différée à la prochaine synchronisation.
- en cas de perte d'accès à IDB, le mode est dégradé en **Visio**.

### Incognito
- pas d'accès à IDB, session WebSocket ouverte.
- les seules opérations impossibles sont celles devant lire / écrire IDB (gestion des secrets à mise à jour différé à la prochaine synchronisation).
- en cas de perte d'accès au réseau (session WS fermée), le mode est dégradé en **Visio**. 

### Synchronisé
- accès à IDB, session WebSocket ouverte.
- toutes opérations possibles.
- en cas de perte,
  - d'accès au réseau, le mode est dégradé en mode **Avion**.
  - d'accès à IDB, le mode est dégradé en mode **Incognito**.
  - des deux, le mode est dégradé en mode **Visio**.

### Visio : mode dégradé
- aucun accès, ni à IDB, ni au réseau, pas de session WebSocket.
- aucune opération possible
- on ne choisit jamais le mode Visio : il résulte d'une dégradation des trois autres modes.

En cas de tentative de reconnexion d'un compte, celle-ci s'effectue dans le mode initial choisi par l'utilisateur, pas dans le mode _dégradé_.

La session d'un compte comporte donc deux modes :
- le mode _initial_,
- le mode _courant_, qui s'il diffère du mode initial, résulte d'une dégradation.

### Dégradation d'un mode
Elle s'effectue automatiquement. Toutefois l'utilisateur reçoit un avis lui demandant s'il préfère,
- une déconnexion franche, 
- tenter une re-connexion,
- ou rester dans le mode dégradé.

## Session
Il y a ouverture de session dès qu'il y a une intention d'identification / création d'un compte : c'est une opération qui créé la session (en tout début).
- la session a une sessionId qui l'identifie (aléatoire sur 6 octets).
- la session a un compte : mais au début de l'opération créatrice il peut être vide.
- la session a deux statuts :
  - IDB : ok ou pas.
  - NET : ok ou pas.
- le mode courant de la session est invariant dans sa vie, son mode courant peut évoluer. En mode Visio aucune opération n'est possible.

Une session peut avoir au plus deux opérations en cours : une UI et une WS

Une session est détruite par une action de `deconnexion`.

L'action de `reconnexion` sur une session source recrée une autre session :
- la session source doit être en statut KO en IDB, NET ou les deux.
- la nouvelle session a le mode initial de la session source qui est détruite.
- la nouvelle session a pour compte le compte de la session initiale (donc authentifié).

## Phases d'une session

### Phase 0 : non connecté - Page Accueil
Aucun compte n'est authentifié. Possibilités :
- authentifier un compte existant
- créer un nouveau compte

En cas de succès, ces deux actions ouvrent la page Synchro (phase 1).

Aucune session WS.

### Phase 1 : chargement / synchronisation des données - Page Synchro
Les données sont obtenues localement (sauf mode incognito) puis depuis le serveur (sauf mode avions)

Sauf mode avion, une session WS est en cours:
- la page peut recevoir un appel `rupturesession` si la session courante est fermée sur erreur (ou volontairement à l'occasion d'une déconnexion explicite).
- les requêtes POST/GET sont interrompues et se terminent au plus vite en exception `RUPTURESESSION`.
- derrière chaque `await` les traitements testent l'état de la session et lancent un exception `RUPTURESESSION` pour se terminer au plus vite.

En cas de succès du traitement la page Compte est ouverte (phase 2) et selon le cas avec un état `modeleactif` à vrai ou faux (en cas d'interruption de cette phase par choix de l'utilisateur).

### Phase 2 : travail - Plusieurs pages
L'état `modeleactif` peut être :
- `vrai` : la page peut lancer des opérations (peu en mode avion) et les notifications sont reçues du serveur (sauf mode avion) et traitées.
- `faux` : la page est uniquement passive, navigation visualisation sans modification de l'état interne du modèle.

Des navigations sont possibles entre pages de phase 2.

Les pages gèrent les `rupturesession` (comme ci-dessus).

La sortie de ces pages de travail s'effectuent :
- sur demande de déconnexion : retour à la page `Accueil`,
  - explicite (j'ai fini),
  - après des erreurs répétitives,
  - suite à une _rupture de session_ avec demande de déconnexion.
- sur demande de reconnexion sur _rupture de session_ : retour à la page `Synchro`.

## Page Accueil : authentification / création d'un compte
Soit par donnée de la phrase secrète, soit par création d'un compte : au retour de cette phase le row `compte` correspondant est connu et en mémoire, le nom de la base IDB est également connu.

## Page Synchro 
On peut arriver sur cette page par deux chemins :
- juste après une authentification,
- suite à une reprise de synchronisation : dans ce cas le row compte peut être ancien.

Le row `compte` est relu (sauf mode avion) afin d'être certain d'avoir la dernière version.

### Map `versions`
La map `versions` comporte une entrée par avatar / groupe avec pour valeur une table de  N compteurs de version v : 
- pour un avatar 7 compteurs donnant la plus haute version disponible dans le modèle pour chacun des tables liées à l'avatar `secret invitegr avatar contact invitct rencontre parrain`.
- pour un groupe 3 compteurs donnant la plus haute version disponible dans le modèle pour chacun des tables liées au groupe `secret groupe membre`.

Par exemple :

    {
    av1 : [436, 512, 434, 418, 517, 718, 932],
    av2 : ... ,
    gr1 : [65, 66, 933],
    ...
    }

Cette map permet de savoir que pour remettre à niveau la table `contact` (la quatrième) de `av1` il faut demander tous les rows de versions postérieures à 418.

versions n'est pas sauvegardée en IDB mais reconstruite lors du chargement de iDB en mémoire.

### `vcv` : numéro de version des cartes de visite
La valeur est conservée en IDB depuis la session antérieure et signifie que toutes les cartes de visite de `vcv` inférieure à cette valeur sont stockées en IDB / modèle. En mode incognito elle n'est pas lue depuis IDB mais mise à 0.

A la fin complète de l'étape de chargement des cartes de visites, vcv est mise à jour avec la plus haute valeur reçue : toutes les cartes de visite sont en mémoire / IDB jusqu'à cette version. Sauf en mode incognito cette valeur est sauvegardée en IDB à ce moment là.

### `dhsyncok dhdebutsync`
`dhsyncok` : donne la date-heure de fin de la dernière synchronisation complète.
- elle est enregistrée en fin de la dernière étape de phase de synchro (sauf en mode avion).
- elle est remise à jour (sauf en mode avion) lors de la réception de chaque notification par WebSocket.
- elle est sauvegardée en IDB (mode synchro).

`dhdebutsync`
- elle est inscrite au début de la phase de synchro et mémorisée en IDB (en mode sync).
- elle est effacée en fin de la phase de synchro (si OK, pas interrompue).

Si la session du compte est rouverte en mode avion, on sait ainsi si la dernière synchronisation a été interrompue (et quand) et que les données peuvent être inconsistantes.  
Si `dhdebutsync` n'est pas présente, les données sont cohérentes à la date-heure `dhsyncok`.

Le **modèle est passif** si `dhdebutsync` est présente données partiellement synchronisées).

### Étape C :_chargement de IDB_ : mode _avion_ et _synchronisé_ seulement
Toute la base IDB est lue et inscrite dans le modèle (en mémoire).

Cette étape peut être interrompue,
- par un incident IDB (ou bug).
- par une rupture de session (sauf mode avion).
- dans les deux cas les choix laissés sont,
  - reprise de la phase chargement / synchronisation depuis le début (sans retourner à Accueil pour choisir / authentifier le compte).
  - déconnexion du compte, retour à Accueil (phase 0).

### Étape R : _remise à niveau_ : mode _synchronisé_ et _incognito_ seulement
Elle consiste à obtenir du serveur les rows des tables mis à jour postérieurement à la version connue en IDB.

#### Sous-étape _amorce_
Le décryptage du row `compte` lors de l'authentification a donné la liste des avatars du compte.

Envoi de 3 requêtes :
- 1 - relecture row `compte` en mode synchronisé (la lecture de IDB a pu être longue) afin d'être certain d'avoir la dernière version et la bonne liste des avatars. Au retour, nettoyage éventuel dans le modèle en mémoire et en IDB (mode synchro) des avatars obsolètes.
- 2 - obtention des rows `invitgr` de ces avatars : le décryptage en session de ces rows donne la liste des groupes (et leur clé de groupe). Au retour, nettoyage dans le modèle en mémoire et en IDB (mode synchro) des groupes obsolètes.
- 3 - ouverture avec le serveur d'un contexte de synchronisation comportant :
  - le compte avec signature de vie,
  - la liste des avatars du compte avec signature,
  - la liste des groupes accédés avec signature.
  
Après cette requête le Web Socket envoie des notifications dès que des rows sont changés en base de données et relatifs à un de ces éléments d'après leur id. Les listes des avatars du compte et des groupes accédés par le compte sont fixées et suivies.

#### Sous-étapes _avatar / groupe_
Il y a ensuite autant de sous étapes _avatar / groupe_ dans cette phase que, 
- d'avatars du compte cités dans le row compte.
- de groupes accédés cités dans les rows `invitgr` relatifs à chaque avatar avc. 

Cette étape peut être interrompue,
- par un incident IDB (ou bug).
- par une rupture de session.
- par demande explicite de l'utilisateur (prise en compte à chaque sous-étape)
- dans tous les deux cas les choix laissés sont,
  - reprise de la phase chargement / synchronisation depuis le début (sans retourner à Accueil pour choisir / authentifier le compte).
  - déconnexion du compte, retour à Accueil (phase 0).

### Étape CV : _synchronisation de cartes de visites_
A la fin de l'étape R on connaît la liste des cartes de visites requises :
- celles des avatars du compte, mais on les a déjà récupérées par principe.
- celles de tous leurs contacts,
- celles des membres des groupes accédés.

Par ailleurs on a déjà en mémoire lues depuis IDB un certain nombre de cartes de visite dont on sait qu'elles sont toutes connues à la version `vcv`. On obtient deux listes :
- celles des CV à rafraîchir si elles ont changé après `vcv`,
- celles à obtenir impérativement.

Cette requête :
- enregistre dans le contexte de la session sur le serveur la fusion de ces deux listes : les CV seront désormais synchronisées.
- récupère les CV de ces deux listes (après `vcv` et sans condition de version).

**Enregistrement en une transaction IDB** des cartes de visites mises à jour et suppression des cartes de visite non référencées.

A cet instant le modèle en mémoire est complet mais n'est pas encore cohérent : des transactions parallèles ont pu effectuer des mises à jour qui sont disponibles dans la queue des notifications du Web Socket.

Cette étape peut être interrompue,
- par un incident IDB (ou bug).
- par une rupture de session.
- dans les deux cas les choix laissés sont,
  - reprise de la phase chargement / synchronisation depuis le début (sans retourner à Accueil pour choisir / authentifier le compte).
  - déconnexion du compte, retour à Accueil (phase 0).

### Étape N : _traitement des notifications reçues par Web Socket_
Pendant toute le phase de remise à niveau des notifications de mises à jour ont pu être reçues : elles sont traitées.
- prétraitement des cartes de visites : des contacts et des membres ont pu être ajoutés et n'ont pas (en général) de cartes de visites. Celles-ci sont demandées par GET au serveur qui les ajoutent à la liste des cartes à notifier.
- une seule transaction IDB met à jour les rows reçus. 
- la nouvelle `vcv` est connue (retournée par le serveur),
- `dhsyncok` est fixée,
- `dhdebutsync` est effacée,
- cet état est sauvegardée en IDB (en mode synchro).

## Pages de travail (phase 2)
L'utilisateur peut effectuer des actions (si `modeleactif` est vrai) et naviguer.

La session évolue selon :
- les actions déclenchées par l'utilisateur qui vont envoyer des requêtes au serveur.
- les notifications reçues du Web Socket comportant les rows mis à jour par les transactions du serveur et intéressant la session.

Si `modeleactif` est vrai, l'état interne de la structure en mémoire reflète le dernier état de notification traité : la date-heure `dhsyncok` et `vcv` sont mises à jour en modèle mémoire et en IDB.

Le traitement d'un bloc de notifications peut demander par GET des cartes de visite manquantes (nouveau contact ou nouveau membre)

_**Remarques :**_
- quand un traitement de notification débute, il récupère tous les blocs de notification reçus et an attente de traitement : les suivants sont accumulés en queue pour le traitement ultérieur.
- quand il n'y a pas eu de traitement de notification pendant 5s, `dhsyncok` est écrite en IDB avec la date-heure courante.

## `localStorage` et IDB
**En mode *avion*** dans le `localStorage` les clés `monorg-hhh` donne chacune le numéro de compte `ccc` associé à la phrase de connexion dont le hash est `hhh` : `monorg-ccc` est le nom de la base IDB qui contient les données de la session de ce compte pour l'organisation `monorg` dans ce browser.

**En mode *synchronisé***, il se peut que la phrase secrète actuelle enregistrée dans le serveur (dont le hash est `hhh`) ait changé depuis la dernière session synchronisée exécutée pour ce compte :
- si la clé `monorg-hhh` n'existe pas : elle est créée avec pour valeur `monorg-ccc` (le nom de la base pour le compte `ccc`).
- si la base `monorg-ccc` n'existe pas elle est créée.
- l'ancienne clé, désormais obsolète, pointe bien vers le même compte mais ne permet plus d'accéder à ce compte, dont la clé K a été ré-encryptée par la nouvelle phrase.

## Barre de titre
A droite :
- icône menu : ouvre le menu
- icône home : provoque le retour à Accueil mais demande confirmation de la déconnexion.
- icône et nom de l'organisation

A gauche :
- icône donnant le mode _synchronisé incognito avion_ : un clic explique ce que signifient les modes.
- icône donnant la phase :
  - pas connecté (carré blanc)
  - en synchro (flèches tournantes)
  - en travail :
    - rond vert : mode actif
    - verrou rouge : mode passif (mise à jour interdite).
  - un clic explique ce que signifie l'état

## Classes

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

