# Boîtes à secrets - Client

## Session d'un compte
Une session est associée à un compte connecté (ou en connexion). Elle dispose de données :
- en mémoire store/db, toujours,
- sur IDB, seulement si la session est synchronisé ou avion.

Les tables suivantes se retrouvent :
- trois singletons dont la clé est l'id du compte : `compte prefs compta`. L'id en IDB est par convention 1.
- trois collections d'objets _maîtres_:
  - les objets `avatar` cités dans le compte : la propriété `mack` donne leur nom / clé (donc id).
  - les objets `couple` cités dans les avatars cités ci-dessus: la propriété lcpk donne leur clé (donc id).
  - les objets `groupe`  cités dans les avatars cités ci-dessus: la propriété lgrk donne leur nom / clé (donc id).
- des collections d'objets secondaires : leur propriété id est l'id d'un objet maître et ils ont une seconde partie de clé pour les distinguer :
  - objets `membre` secondaires de `groupe`, clé secondaire `im` (indice membre).
  - objets `secret` secondaires de `avatar, couple, groupe`, clé secondaire `ns` (numéro de secret).

Les objets `invitgr` secondaires de `avatar` sont transients en session : récupérés en synchronisation ils déclenchent une opération de mise à jour de leur avatar pour qu'il référence le groupe dans `lgrk`. Ces objets ne sont ni mémorisés, ni en store/db, ni en IDB.

Les objets contact sont demandés explicitement par une vue et ne sont ni mémorisés, ni en store/db, ni en IDB.

#### Les cartes de visite
Tout objet maître `avatar / groupe / couple` a un objet `cv` de même id :
- ils sont créés simultanément.
- la propriété `x` de `cv` quand elle est > 0, indique que l'objet maître est _disparu_ et a été purgé.

### Structure en mémoire : store/db
Son `state` (vuex) détient:
- les singletons : `compte prefs compta`
- les collections d'objets maîtres : une map de clé id pour donner l'objet correspondant
  - `avatars[1234]` : donne l'avatar d'id `1234`
- les collections d'objets secondaires secret membre
  - `secrets@1234[56]` donne le secret d'id `1234, 56`
  - `secrets@1234` donne la map de tous les secrets du même maître `1234`
- un singleton particulier `repertoire` (voir plus loin) qui est une map de toutes les cvs des `avatar / groupe / couple`.
- un singleton particulier `sessionsync` (voir plus loin)).

Son state détient aussi des _objets courants_ dans les vues :
- `avatar`: l'avatar courant
- `groupe`: le groupe courant
- `groupeplus`: le couple courant [groupe, membre] ou membre est celui de l'avatar courant
- `couple`: le couple courant
- `secret`: le secret courant

Si par exemple l'objet du groupe d'id `123` change,
- `groupes[123]` change et référence la nouvelle valeur de l'objet,
- `groupe` change et référence la nouvelle valeur de l'objet.

#### Répertoire des CVs
La classe `Repertoire` est une simple map avec entrée par carte de visite (de clé id de la carte de site).

Chaque entrée a des propriétés additionnelles par rapport à cv :
- **pour une cv d'avatar:**
  - `na`: son `NomAvatar` (couple non / clé),
  - `lgr`: la liste des ids des groupes dont l'avatar est membre,
  - `lcp`: la liste des ids des couples dont l'avatar est, soit le conjoint _interne_ (avatar du compte), soit le conjoint _externe_ (l'avatar n'est pas un avatar du compte).
  - `avc`: `true` si c'est un avatar du compte
- **pour une cv de groupe:**
  - `na`: son `NomAvatar` (couple non / clé)
  - `lmb`: la liste des ids des avatars qui en sont membre.
- **pour une cv de couple:**
  - `na`: son `NomAvatar` (couple non / clé). Son nom est construit depuis ceux de son ou ses conjoints.
  - `idE`: l'id du conjoint externe (s'il est connu),
  - `idI`: l'id du conjoint interne.

**La session détient un objet `rep` qui est l'image, non réactive** (de travail) du répertoire.

**store/db détient la propriété `repertoire`, image réactive du répertoire, stable**, celle qui a été fixée par l'opération commit() du répertoire rep de la session.

### La base locale IDB
Il y a une base par compte.

Elle contient les tables `compte prefs compta avatar groupe couple secret cv` :
- la clé primaire de chacun est,
  - pour les singletons `compte prefs compta` : `1`
  - pour les objets maîtres `avatar groupe couple` le cryptage par la clé K du compte de leur id en base64.
  - pour les objets secondaires le couple `id id2`:
    - `id` : le cryptage par la clé K du compte de l'id en base64 de son maître.
    - `id2` : le cryptage par la clé K du compte de son id relative (`ns` ou `im`) à son maître.
- la propriété `data` est le cryptage par la clé K du compte de la sérialisation de l'objet.

Les tables ont donc deux 2 propriétés `id data` ou 3 propriétés `id, id2,  data`.

**IDB est toujours cohérente** : les opérations spéciales de mise à jour accumulent dans leur traitement les mises à jour pour IDB dans leur objet `OpBuf` et un seul commitRows() intervient à la fin pour enregistrer toutes les mises à jour en attente dans `OpBuf`.

#### La table `sessionsync`
Cette table enregistre les date-heures,
- de la session synchronisée précédente correctement connectée puis terminée : `dhdebut dhfin`
- de la session synchronisée en cours : 
  - `dhlogin` : dh de fin de login,
  - `dhsync` : date-heure de fin de la dernière opération de synchronisation,
  - `dhpong` : date-heure de réception du dernier _pong_ reçu sur le websocket attestant que celui-ci n'est pas déconnecté.

Cet objet est disponible dans store/db `sessionsync`, uniquement quand la session courante est _synchronisée_.

## Opérations et cohérence des états store/db et IDB
#### Trois opérations d'initialisation
Il y a 3 opérations d'initialisation des données de session :
- **`ConnexionCompte`**
  - elle reconstitue en mémoire l'état des données du compte depuis,
    - IDB si c'est une session _synchronisée_ ou _avion_,
    - et le serveur si c'est une session _synchronisée_ ou _incognito_,
    - l'état est cohérent et les objets inutiles ont été purgés,
    - l'état des données est transcrit sur IDB par une unique transaction (commitRows()) et sur store/db par un unique appel de fonction.
- **`CreationCompte`** (sans parrain) et **`AcceptationParrainage`** (avec parrain).
  - elles sont plus simples puisqu'il n'y a par définition aucun état antérieur à prendre en compte et très peu d'objets à commiter dans IDB et store/db.

La propriété state/ui `statutsession` vaut
- 0 : avant exécution de ces initialisations de sessions,
- 1 : pendant l'exécution de celles-ci,
- 2 : après la fin de l'exécution (succès, sinon retour à 0 et pas de session)
- 0 : en cas de déconnexion accidentelle ou explicite (plus de session).

#### Unique opération de mise à jour : ProcessQueue
Il n'y a qu'une seule opération de mise à jour (après initialisation), ProcessQueue :
- elle ne s'exécute que quand l'initialisation complète de la session est faite (statutseesion à 2).
- les messages de mise à jour reçus sur WebSocket sont stockées en queue dans l'ordre d'arrivée.
- la queue est traitée (si elle n'est pas vide),
  - dès que le statut de session passe à 2
  - dès qu'un message de synchronisation est reçu et que le statut de session est 2.
Comme pour les opérations d'initialisation, les modifications sont stockées dans OpBuf et validées en un seul appel à la fin.

#### Autres opérations
Aucune autre opération ne fait de mises à jour des données store/db et IDB, ni ne lit IDB.

> _Remarque_ : les objets courants de navigation store/db avatar groupe ... peuvent changer au gré des navigations mais sans mise à jour de leur contenu.

En conséquence les actions UI peuvent accéder à tout instant à un état cohérent des données en store/db qui n'évolue que par le commit de ProcessQueue (d'état cohérent en état cohérent).

#### Début et fin d'une session, inter-session
**Une session existe dès qu'une opération de connexion ou de création de compte débute :**
- l'état de session est disponible dans la variable `data` de `modele.mjs`et subsiste dure jusqu'à la **déconnexion**, explicite ou accidentelle.
- une session est caractérisée par un compte.
- dès que l'initialisation (connexion / création de compte) s'est bien terminée l'état de ses données est cohérent.
- le **traitement des notifications des mises à jour** du serveur par `ProcessQueue` maintient l'état store/db et IDB à jour et cohérent.

Une session a quelques propriétés traduisant son état interne, en plus des données _métier_ en store/db et IDB.

Durant une session les pages peuvent être : `synchro` (durant l'initialisation), puis `compte` ou `avatar`.

#### Inter-session
Entre 2 sessions, très peu d'information est disponible :
- `org` : l'organisation choisie (quand elle l'a été).
- `mode` : `synchronisé incognito avion` (quand il a été choisi).

En inters-session les pages ne peuvent être que `org` ou `login`.

#### Propriétés d'une session
### Objet OpBuf
Cet objet créé en début des opérations ci-dessus stocke les mises à jour en attente collectées pendant l'opération afin de pouvoir réaliser à la fin :
- une mise à jour de store/db en un seul appel,
- une écriture sur IDB en une seule transaction.

Ceci permet d'éviter de faire apparaître,
- en store/db des états intermédiaires incohérents propres à perturber l'affichage,
- en IDB un état fonctionnellement incohérent résultant d'une mise à jour partielle.

### Opération `ConnexionCompte`
Elle a pour objectifs :
- de s'assurer que le compte correspondant à la phrase secrète saisie existe,
- d'alimenter en store/db et en IDB toutes les données du périmètre du compte.

C'est la seule opération qui lit IDB afin de récupérer un maximum de données sans avoir à les obtenir du serveur.

Elle écrit sur IDB les données récupérées du serveur de manière à ce que son état soit cohérent et propre à être utilisé par une connexion ultérieure en mode _avion_.

Elle purge d'IDB les données _inutiles_ (obsolètes ou sorties du périmètre du compte).

- **suppression éventuelle de IDB** si c'est l'option demandée au login.
- si c'est une connexion en mode _avion_, vérifie qu'une propriété du `localstorage` donne le nom de la base du compte pour la phrase secrète saisie.
- **connexion effective :**
  - attribue à la session un `sessionId` aléatoire
  - ouverture de IDB (sauf en mode _incognito_)
  - création d'un websocket avec le serveur (sauf en mode _avion_), lancement du ping pong.
- **phase itérative 0,1,2**
  - tant que ces trois phases ne se sont pas déroulées sans incident, on boucle (5 fois avant exception).
  - **phase 0 : récupération de `compte / prefs / compta`** : ceci donne une liste d'avatars (dans `lgrk` de compte). Signature (dans compta) et abonnement au compte.
  - **phase 1 : pour tous les avatars cités dans le compte**
    - récupération de `avatar`
    - signature (dans cv) et abonnement
    - _si la version du compte a changé_, donc qu'il a pu avoir un avatar en plus ou en moins depuis la phase 0, échec et on reprend la phase 0-1-2
    - ceci donne la liste des groupes et couples du périmètre du compte.
  - **phase 2 : pour tous les groupes et comptes du périmètre,**
    - récupération du `couple groupe`
    - signature (dans cv) et abonnement
    - si l'une des versions, du compte ou d'un des avatars récupérés a changé (possibilité de groupe / couple en plus ou en moins), échec et on reprend la phase 0-1-2
- **phase 3. Récupération des membres et secrets** rattachés aux `avatar / couple / groupe` récupérés ci-dessus. Comme on est abonné à ces objets, s'ils changent les modifications seront traitées en synchronisation.
- **phase 4. Récupération des cv des objets maîtres et des membres rattachés.**
  - l'objet `sessionsync` a une propriété `vcv` qui donne la plus haute version des cv récupérées et stockées en IDB.
  - liste `vp` : ce sont les cv référencées dont on a déjà une copie (soit parce que son x indique une disparition, soit parce qu'une cv a été déclarée). On récupère du serveur celles ayant une version supérieure à `vcv`.
  - liste `vz` : ce sont les cv référencées dont on n'a jamais eu copie antérieurement. On récupère du serveur celles ayant une version non 0. Une cv avec une version 0 indique seulement que l'objet existe et qu'il n'a jamais eu de cv.
  - la plus haute version des cv récupérées donne le `vcv` pour la prochaine session.
- **phase 5. Récupération des fichiers attachés déclarés stockés localement**, manquants ou ayant changé de version.
- **phase 6. Récupération des invitations aux groupes (invitgr) concernant un des avatars du compte**. Ces objets ne sont pas stockés et donne lieu immédiatement à une requête pour modifier les avatars correspondants et leur faire référencer les avatars du compte.
- **finalisation :**
  - les mises à jour store/db sont validées,
  - les mises à jour dans IDB sont soumises et commitées en une seule opération.
  - la fin de la connexion est actée : la session passe en statutsession 2 (apte à fonctionner).

### Opération de synchronisation `ProcessQueue`
Chaque opération traite un ou plusieurs lots de notifications envoyées par le serveur sur websocket.
- tous les objets modifiés sont collectés et seule la plus haute version pour chaque id est conservée pour traitement.
- l'objectif est de mettre à jour :
  - store/db en une seule fois à la fin.
  - IDB en une seule transaction à la fin.

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
Dès que les données du compte sont complètement chargées, cette page s'affiche et donne la synthèse du compte, la liste de ses avatars...

Navigations possible :
- `Login` : en cas de déconnexion
- `Avatar` : vers l'avatar _sélectionné_

### Avatar : `/_org_/avatar`
Détail d'un avatar du compte.

Navigations possibles :
- `Login` : en cas de déconnexion
- `Compte` : retour à la synthèse du compte.

### Panneau latéral Menu
Infos et boutons d'actions (affichage de boîtes de dialogue, etc.)

## Actions et opérations
### Actions
Elles n'affectent que l'affichage, la visualisation des données. Elles ne changent pas l'état des données du compte, ni sur IDB ni sur le serveur central.

Elles ne font pas d'accès ni à IDB ni au réseau, sauf l'action spéciale de **ping** :
- _ping du serveur_ : pas en mode _avion_.
- _ping DB de la base de l'organisation sur le serveur_ : il faut que cette organisation soit connue, pas en mode _avion_.
- _sélectionné_ : il faut que le compte soit identifié, pas en mode _incognito_.

### Opérations
Seules les 4 opérations spéciales vues antérieurement modifient l'état des données du compte, en mémoire et **sur IDB et/ou le serveur**.

**Les opérations UI _standard_** ne changent pas létat store/db ni IDB : elles postent des requêtes au serveur.

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

La détection d'un de ces événements provoque une exception BREAK qui n'est traitée que sur le catch final de l'opération (en cas de _catch_ elle doit être re-propagée telle quelle).

Le traitement final du BREAK consiste à dégrader le mode de la session en **Avion** ou **Visio** ou **Incognito** selon les états IDB et NET (s'il ne l'a pas déjà été).

#### Opération `ProcessQueue` `WS` _WebSocket_ initiées par l'arrivée d'un message sur WebSocket
Une seule opération de ce type peut se dérouler à un instant donné.

Elles ne sont pas interruptibles, sauf de facto par la rupture de la liaison WebSocket (voire en conséquence d'une action de déconnexion).

Deux événements peuvent interrompre une opération WS :
- l'avis d'une rupture d'accès au réseau (WebSocket ou sur un accès POST / GET).
- l'avis d'une impossibilité d'accès à IDB.

La détection d'un de ces événements provoque une exception BREAK qui n'est traitée que sur le catch final de l'opération (en cas de _catch_ elle doit être re-propagée telle quelle sans traitement). 

Le traitement final du BREAK consiste à dégrader le mode de la session en **Avion** ou **Visio** selon les états IDB et NET (s'il ne l'a pas déjà été).

> In fine `ProcessQueue` ne sort jamais en exception.

### Boîtes de dialogue
##### Publiques
Elles peuvent être commandées d'ailleurs de la vue qui la contient : principalement celles du _layout_ mais aussi quelques autres.

**Leur affichage est toujours commandée par une variable de store/ui** : dans n'importe quel endroit du code il suffit donc de basculer leur variable d'affichage pour que la boîte apparaisse.

Sur la mutation `majstatutsession` avec un statut non 2 (ok), toutes les boîtes publiques sont fermées.

##### Spécifiques d'une vue
Chaque boîte dépend d'une variable définie au setup() par def() :
- la variable `sessionok` (ou plus `statutsession`) active est déclarée.
- `watch` permet de fermer toutes les boîtes.

    setup () {
    const mcledit = ref(false)
    const sessionok = computed(() => { return $store.state.ui.sessionok })
    watch(() => sessionok.value, (ap, av) => {
      if (ap) {
        mcledit.value = false
      }})

Ainsi :
- dans l'affichage des `v-if="sessionok"` permettent de ne rien afficher lors d'une fermeture de la vue quand les objets qu'elle affiche ont déjà disparu.
- les boîtes de dialogues se ferment automatiquement en cas de déconnexion.

## Modes
### Avion
- pas d'accès au réseau, pas de session WebSocket.
- les seules opérations possibles mettent à jour IDB : enregistrement de secrets pour mise à jour différée à la prochaine synchronisation.
- en cas de perte d'accès à IDB, le mode est dégradé en **Visio**.

### Incognito
- pas d'accès à IDB, session WebSocket ouverte.
- les seules opérations impossibles sont celles devant lire / écrire IDB (enregistrement de textes en attente, de fichiers à attacher plus tard et de fichiers attachés stockés localement).
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

## Gestion des fichiers disponibles en mode avion
- Chaque fichier est identifié par `idf` (grand nombre aléatoire).
- Chaque fichier est attaché à un **secret** identifié par `id ns`, ne peut en changer et est immuable.
- Un fichier peut être détruit, pas mis à jour.

### Cache des fichiers en IDB
Deux tables gèrent ce stockage en IDB :
- `fdata` : colonnes `idj, data`. Seulement insertion et suppression
  - `data` est crypté par la clé K du compte (pas la clé `idf`)
- `fetat` : colonnes `idf, data : {dhd, dhc, lg, nom, info}`. Insertion, suppression et mise à jour.
  - `dhd` : date-heure de demande de chargement.
  - `dhc` : date-heure de chargement.
  - `lg` : taille du fichier (source, son v2).
  - `nom info` : à titre d'information.

#### Transactions
- `fetat` peut subir une insertion sans mise à jour de `fdada`.
- `fetat` peut subir une suppression sans mise à jour de `fdata` si le row indique qu'il était encore en attente (`dhc` 0).
- `fetat` et `fdata` peuvent subir une suppression synchronisée.
- quand `fdata` subit une insertion, `fetat` subit dans la même transaction la mise à jour de `dhc`.

La table `fetat` est,
- lue à l'ouverture d'une session en modes _synchronisé_ et _avion_ (lecture seule),
- l'état _commité_ est disponible en mémoire durant toute la session.

#### Démon
En mode synchronisé un démon tourne en tâche de fond pour obtenir du serveur les fichiers requis pas encore disponibles en IDB.

Dans la barre de statut en haut, l'icône du mode synchronisé est en _warning_ quand il y a des fichiers en attente / chargement. Quand on clique sur cette icône, la liste `fetat` est lisible (avec l'indication en tête du fichier éventuellement _en cours de chargement_).

#### État de disponibilité pour le secret _courant_
Dans db/store, le state `dispofichiers` est synchronisé avec db/secret (le secret _courant_). Le démon maintient dans `dispofichiers` la liste des idf _en cours de chargement_ (en fait demandés mais pas encore chargés). La page des fichiers attachés du secret courant peut ainsi afficher si le fichier est disponible localement ou non :
- en mode _avion_ ceci indique si il sera ou non affichable,
- en mode _synchronisé_ ceci indique si son affichage est _gratuit_ (et immédiat).

## Objets Secret et AvSsecret
Les objets `Secret` sont ceux de classe `Secret` disponibles dans le store/db.
- Identifiant : `[id, ns]`
- Propriété `mfa` : c'est une map,
  - _clé_ : `idf`, l'identifiant d'un fichier attaché,
  - _valeur_ : `{ nom, lg, dh ... }`, nom externe et taille. Pour un nom donné pour un secret donné il y a donc plusieurs versions de fichier chacune identifiée par son idf et ayant une date-heure d'insertion dh. Pour un nom donné il y a donc un fichier _le plus récent_.

Un objet de classe `AvSecret` existe pour chaque secret pour lequel le compte a souhaité avoir au moins un des fichiers attachés disponible en mode avion.
- Identifiant : `[id, ns]`
- Propriétés :
  - `lidf` : liste des identifiants des fichiers explicitement cités par leur identifiant comme étant souhaité _hors ligne_.
  - `mnom` : une map ayant,
    - _clé_ : `nom` d'un fichier dont le compte a souhaité disposer de la _version la plus récente_ hors ligne.
    - _valeur_ : `idf`, identifiant de cette version constaté dans l'état le plus récent du secret.

Chaque objet de classe `AvSecret` est disponible dans db/store avec la même structure que pour secret :
- une entrée `avsecret@id` qui donne une map de clé `ns` pour chaque objet `AvSecret`.

`AvSecret` est maintenu en IDB à chaque changement :
- la clé primaire `id,id2` est comme de Secret cryptée par la clé K du compte.
- _data_ est la sérialisation de `{lidf, mnom}` cryptée par la clé K du compte.

En mode _synchronisé_ et _avion_ tous les `AvSecret` sont chargés en mémoire dans db/store.

### Mises à jour des AvSecret
Il y a deux sources de mise à jour :
-**(a) le compte fait évoluer ses souhaits**, modifie `lidf / mnom` : il peut en résulter,
  - une liste d'idf à ne plus conserver en IDB,
  - une seconde liste d'idf qui ne l'étaient pas et doivent désormais l'être. 
  - Ces deux listes sont calculées par comparaison entre la version _actuelle_ d'un `AvSecret` et sa version _future_ (désormais souhaitée).
-**(b) une mise à jour d'un `Secret`** peut faire apparaître des incohérences avec l'`AvSecret` correspondant (quand il y en a un) et qui doit se mettre en conformité:
  - des idf cités dans `lidf` n'existent plus : ils doivent être supprimés.
  - pour un nom dans `mnom`, l'idf cité n'est plus le plus récent (il doit être supprimé **et** un autre devient requis et _peut-être_ non stocké donc inscrit comme _à charger_).
  - des noms cités dans `mnom` n'existent plus, ce qui entraîne la disparition des idf correspondants (et de l'entrée `mnom`).
  - en conséquence il résulte de la comparaison entre un `Secret` et son `AvSecret` correspondant :
    - une liste d'idf à supprimer dans `fetat fdata` ce qui est fait sur l'instant.
    - une liste d'idf _à charger_ et noté dans `fetat` sur l'instant, le chargement effectif étant effectué à retardement par le démon.
    - une mise à jour de l'`AvSecret` pour tenir compte des contraintes du nouveau `Secret`, voire sa suppression si Secret est supprimé **ou** que `lidf` et `mnom` sont vides.

**Les traitements (a) sont effectués quand le compte en a exprimé le souhait par action UI**. Ils sont immédiats pour les suppressions mais les chargements de nouveaux idf seront traitées par le démon avec retard.

**Les traitements (b) sont effectués** :
- en fin d'initialisation de la session en mode _synchronisé_ quand tous les `Secret` sont chargés : il détecte,
  - les mises à jour éventuelles de chaque `AvSecret` pour chaque objet `Secret` existant correspondant.
  - les suppressions des `AvSecret` (et donc des idf dans `fdata / fetat`) pour chaque `AvSecret` pour lequel il n'existe plus de `Secret` (existant) associé.
- **à la synchronisation pour chaque mise à jour / suppression** d'un `Secret` entraînant le cas échéant une mise à jour ou une suppression de l'`AvSecret` correspondant.
