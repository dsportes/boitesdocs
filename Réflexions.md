# Maîtrise du volume des secrets : quotas et crédits

### Contrôler les volumes par des quotas
Si les comptes étaient laissés libres de créer autant de secrets et de pièces jointes que voulu sans limitation, l'application pourrait être saturée et inutilisable pour la majorité de ses comptes raisonnables du fait de l'utilisation déraisonnable de quelques uns.

Il y a trois axes à maîtriser :
- `v1` : **le volume des textes des secrets** qui mobilise un espace de base de données, coûteux et relativement limité.
- `v2` : **le volume de leurs pièces jointes** qui mobilise un espace de fichiers (ou équivalent), moins coûteux et pouvant être important.
- `tr` : **le volume transitant sur le réseau** qui est décompté,
  - _lors de l'ouverture d'une session par un compte_ pour charger les textes des secrets (juste ceux ayant changé depuis la dernière fois en mode _synchronisé_ ou tous en mode _incognito_) et les pièces jointes déclarées accessibles en mode avion sur le poste (incrémentalement en mode _synchronisé_),
  - _lors de la mise à jour d'un secret_ ou d'une de ses pièces jointes,
  - _lors du téléchargements d'une sélection de secrets sur disque local_ avec la remontée des pièces jointes non disponibles en mode _avion_ sur le poste.

>Les volumes `v1` et `v2` sont simplement le total des volumes occupés à l'instant t. Un quota de volume correspond à deux chiffres `max1` et `max2` tels que `v1` et `v2` ne doivent pas les dépasser.

>Le volume réseau `tr` est décompté sur le volume total échangé pour la semaine en cours et la précédente. Le quota réseau est le volume hebdomadaire maximal moyenné sur la semaine courante et la précédente.

La maîtrise des ressources globales et l'équilibre entre les usages de l'application par les comptes repose sur la contrainte de quota contraignant l'usage de l'application pour chaque compte.

### Contrôler la répartition entre les comptes : les lignes de crédit
Comment affecter des quotas aux comptes, à l'instant t et au cours du temps ?

Les organisations ont des profils différents et la politique de répartition ne peut pas être identique pour toutes. Exemples typiques.

##### Organisation uniforme figée et fiable
- il y a N comptes, tous égaux en droits et en obligations.
- les comptes sont fiables et supportent le coût d'hébergement de manière régulière, ou un généreux sponsor paie pour tout le monde sur le long terme.
- Solution simple : tout le monde a le même triplet de quotas sans limitation de durée.

Mais ce cas est virtuel et n'existe pas dans la vraie vie.

##### Organisation par _cotisation_
- chaque compte acquitte régulièrement une cotisation pour contribuer au coût global d'hébergement.
- selon ce que chacun paye (ses besoins), les quotas sont plus ou moins élevés.
- si un compte ne paye plus, il n'accède plus, s'il réduit sa cotisation (donc ses quotas) ses volumes doivent baisser ... sinon ...
- Tout le problème est dans le _sinon_ : comment passer d'une liberté totale à une interdiction de connexion en laissant au compte le temps de s'adapter / préparer sa sortie.

Ce cas est concret, même si le _paiement de cotisation_ peut aussi prendre des formes variées.
- c'est l'organisation qui paye les cotisations pour ses membres mais du coup c'est elle aussi qui détermine le montant des quotas associés et la date de validité de l'accès.
- c'est une activité _commerciale_ pure (indépendamment de l'aspect lucratif ou non), chaque compte payant selon son envie / besoins. Personne ne décide si un compte doit ou non avoir accès : tant que les cotisations rentrent, les comptes utilisent le service.

### Les _lignes de crédit_
C'est l'instrument qui va permettre de gérer l'évolution dans le temps des quotas attribués à chacun : ces lignes sont gérées par des **comptables** qui sont des comptes dont la phrase secrète (son hash) est enregistré dans la configuration de l'application.

**Chaque compte a une ligne de crédit dont le numéro est aléatoire et immuable pour le compte durant sa vie**. Personne, pas même les comptables, ne peut corréler un numéro de ligne de crédit et un compte, _sauf le titulaire du compte lui-même_. 

Une ligne de crédit fixe :
- 3 quotas :
  - `max1` : volume maximal total des **textes** des secrets.
  - `max2` : volume maximal total des **pièces jointes** aux secrets.
  - `maxt` : volume maximal total du **trafic réseau sur une semaine** :
    - des pièces jointes échangées (upload / download).
    - des textes des secrets téléchargés en début de session.
    - des textes des secrets mis à jour.
- 3 volumes à l'instant t :
  - `v1` : volume total des **textes** des secrets.
  - `v2` : volume total des **pièces jointes** aux secrets.
  - `tr` : **trafic réseau sur une semaine**. Concrètement c'est calculé depuis 3 compteurs : le numéro de la semaine N du dernier enregistrement et les cumuls sur la semaine N-1 et N.
- `dlv` : date limite de validité du _contrat_, le service est _normalement_ assuré au moins jusqu'à cette date, et bloqué au delà.
- `dbx` : date de blocage exceptionnelle du compte.
- `dbq` : date limite de respect des quotas : au delà, si les quotas ne sont toujours pas respectés, le compte est bloqué.
- `dds` : date de dernière signature du compte.
- `en sursis` : calculé : quand il y a plusieurs raisons, c'est la plus forte qui est indiquée.
  - 0 : pas en sursis
  - 1 : en sursis pour excès de v1
  - 2 : en sursis pour excès de v2
- `bloqué` : calculé, raison du blocage.
  - 0 : pas bloqué.
  - 1 : dépassement de la `dlv`,
  - 2 : dépassement de la `dbq` **et** le compte ne respecte toujours pas ses quotas de volume.
  - 3 : dépassement de `dbx`.

L'application renseigne les _volumes_ et la dernière date de connexion : les quotas et autres dates sont renseignées par les comptables selon les règles en vigueur dans l'organisation.

La ligne de crédit d'un compte est affichable en session de ce compte sur demande.

>Une organisation qui souhaiterait valoriser en unités monétaires le coût d'usage / immobilisation des ressources de son application n'a plus qu'à appliquer la formule de conversion de son choix depuis les compteurs d'une ligne de crédit (quitte à utiliser des historiques externes tirés des lignes).

### Mise à jour des lignes de crédit selon les opérations sur les secrets
Les opérations concernées sont :
- la synchronisation des secrets en ouverture de session : elle impute le volume `tr` de la ligne de crédit du compte.
- la mise à jour **d'un secret personnel ou de couple** (texte et pièce jointe):
  - elle impute la variation de volume sur les compteurs `v1 / v2` de la ligne de crédit du compte demandeur, selon que c'est le texte ou la pièce jointe,
  - elle impute le volume transféré (texte ou pièce jointe) sur le compteur `tr` du compte demandeur.
  - le téléchargement sur disque local d'une sélection de secrets. Elle impute le volume transféré des pièces jointes sur le compteur `tr` du compte demandeur.

#### Gestion des secrets des groupes
- un groupe est _supporté_ par la ligne de crédit d'un de ses membres (qui peut changer), son _hébergeur_.
- un groupe dispose de compteurs `max1 / max2` fixés par le compte hébergeur du groupe et les volumes `v1 / v2` des secrets du groupe.

Le volume de _transfert réseau_ associé à une opération est décompté sur la ligne de crédit du compte demandeur. Un groupe n'a aucun compteur / quota lié au transfert réseau.
- la variation de volume liée à une mise à jour de texte ou de pièce jointe d'un secret,
  - est décomptée une première fois sur le groupe lui-même,
  - est décompté une seconde fois sur la ligne de crédit du compte hébergeur du groupe.

>La mise à jour d'un secret d'un groupe entraîne la mise à jour, dans le cas général, a) de la ligne de crédit du demandeur pour le coût de transfert, b) de la ligne de crédit de l'hébergeur du groupe pour les volumes, c) du groupe lui-même pour les volumes afin que les membres aient conscience de son importance.

La ou les deux lignes de crédit impactées dans une opération sur un secret sont retournée en résultat de l'opération, ce qui est particulièrement utile si l'opération a échoué en raison de quotas insuffisants (sur une ligne et / ou au niveau du groupe).

#### Changement _du compte hébergeur_ d'un groupe
Un membre animateur (auteur s'il n'y a plus d'animateurs) peut se déclarer _hébergeur_ du groupe en inscrivant son numéro de ligne de crédit à la place de celle actuelle :
- il débite sa ligne de crédit des volumes actuels `v1` et `v2` occupés par les secrets du groupe et leurs pièces jointes et crédite d'autant la ligne de crédit actuelle.
- il peut alors modifier les limites `max1 / max2` du groupe.

Le compte _hébergeur_ dont la ligne de crédit est celle du groupe peut la retirer : **le groupe n'a plus de ligne de crédit associée**. 
- **l'accès à ses secrets est suspendu** jusqu'à ce qu'un animateur y mette la sienne.
- le groupe n'étant plus accédé, si personne ne s'est manifesté pour en reprendre la charge, il va finir par s'auto-dissoudre au bout d'un an.

>Dans l'entête du groupe le numéro de la ligne de crédit est crypté par la clé du groupe. Seuls ses membres peuvent en avoir connaissance.

## Disparition et blocage des comptes
### Disparition par inactivité d'un compte
Des ressources sont immobilisées par les comptes (partagées pour les groupes) : l'application doit les libérer quand les comptes sont _présumés disparus_, c'est à dire sans s'être connecté depuis plus d'un an.
- mais pour préserver la confidentialité, toutes les ressources liées à un compte ne sont pas reliées au compte par des données lisibles dans la base de données mais cryptées et seulement lisibles en session.
- à la connexion, un compte va _signer_, 
  - par une estampille datée approximativement dans chacun de ses avatars et chacun des groupes auxquels il participe, ainsi que dans le compte lui-même.
  - par la date du jour dans sa ligne de crédit.
  - la disparition est entérinée 400 jours après la plus récente date de signature.

Un traitement ramasse miettes tourne chaque jour, détecte les comptes / avatars / groupes pas signés depuis plus d'un an et efface les données correspondantes.

Les comptables peuvent lire dans les lignes de crédit si la date de dernière signature (dds) du compte a ou non plus d'un an. Ils ont ainsi une photo à tout instant des ressources effectivement utiles, ce qui leur permet de satisfaire les demandes de ressources par récupération des volumes libérés.

### Disparition par décision comptable
Si un compte n'acquitte plus sa cotisation, quitte l'organisation, etc. bref doit impérativement cesser son activité, il n'est pas techniquement possible d'effacer toutes ses données,
- la ligne de crédit n'indique pas le compte correspondant par nécessaire confidentialité,
- même la connaissance du compte ne donne pas, pour les mêmes raisons de confidentialité, quels avatars et quels groupes font partie de son environnement.

#### Compte _en sursis_
Un compte est _en sursis_ dès lors que l'état de sa ligne de crédit **l'empêche de signer sa preuve d'activité** lors de l'ouverture d'une session dans ses avatars et les groupes auxquels il participe.

Un tel compte reste **en sursis** pendant pratiquement un an avant sa disparition effective et pendant ce temps peut vivre, le cas échéant avec des restrictions d'activité selon ce qu'indique sa ligne de crédit et les compteurs des groupes auxquels il participe.

#### Compte _bloqué_
Un compte _bloqué_ n'a plus aucun droit d'accès à son compte, sauf pour,
- lire sa ligne de crédit,
- dialoguer avec un comptable.

Le blocage peut intervenir de plusieurs façons :
- _normalement_ quand **la date de validité du contrat est dépassée**. Dans certaines organisations, cette date peut être fixée par convention à la fin du siècle. C'est l'objet du champ `dlv` de la ligne de crédit.
- _exceptionnellement_, soit **pour des raisons réglementaires ou de justice** (si elles s'appliquent à l'organisation). C'est l'objet du champ `dbx` de la ligne de crédit.
- _par dépassement du délai_ **à respecter ses volumes maximaux v1 et v2**. C'est l'objet du champ `dbq` de la ligne de crédit.

>La raison majeure d'un blocage est indiquée dans la ligne de crédit : un blocage ne peut être levé que par une action d'un comptable (par principe ! le compte ne peut plus rien faire).

>L'état _en sursis_ est _déduit_ des autres données de la ligne de crédit : excès de volume v1 ou v2.

>un compte bloqué ne _signe_ plus son activité puisque justement il n'en n'a plus : le délai d'un an avant disparition pour inactivité commence donc à courir à sa date de blocage.

### Raisons d'un sursis et restrictions de vie en sursis
#### Respect des quotas, révisions à la baisse
En vie courante, les quotas sont toujours respectés puisque toute action susceptible de les enfreindre est bloquée.

Mais ce n'est plus le cas en cas de _restrictions_ de quota par rapport à une situation existante :
- **la restriction du quota de transfert réseau ne s'applique pas à l'ouverture d'une session** (sauf pour les pièces jointes des secrets déclarées disponibles en mode avion). Bref même avec une réduction de quotas de transfert réseau à 0, un compte peut ouvrir une session et consulter ses secrets, mais seulement certaines de leurs pièces jointes (pas forcément à jour).
- **la restriction des quotas portant sur les volumes v1 et v2**. Un blocage complet d'écriture est trop contraignant : il faut laisser au compte le temps de résoudre cette restriction imposée par un comptable (même si elle est totalement justifiée) alors que jusqu'à présent il était en règle.

_Typiquement,_
- c'est le cas d'un compte souscrivant un forfait inférieur dont les quotas sont inférieurs aux volumes qu'il occupe actuellement.
- ça peut être aussi le cas d'un compte ayant changé de fonctions dans l'organisation ne lui ouvrant pas droit à des quotas aussi importants et que le comptable ramène au niveau idoine.
- ça peut être aussi une règle contractuelle laissant au compte N mois pour revenir au niveau que son adhésion / souscription prévoit.

Pour retrouver une consommation en phase avec des quotas revus à la baisse, une date limite à cet état de _sursis_ est fixée : à la date indiquée dans la ligne de crédit `dbq`, le compte est _bloqué_. 

D'où la règle : tout compte dont la ligne de crédit fait apparaître des volumes supérieurs à ses quotas est implicitement _en sursis_.
- il sort de facto de cet état quand il est revenu dans ses quotas : normalement il ne peut plus alors les dépasser (sauf si un comptable les réduit à nouveau ensuite).
- si cet état persiste au delà de la date limite `dbq`, il est automatiquement bloqué. Ne pouvant plus agir sur son compte pour réduire son volume, le déblocage ne peut venir que d'une action d'un comptable.
- in fine au bout d'un an en sursis / bloqué, il disparaît définitivement.

#### Conséquences pratiques de l'état de _sursis_ consécutif à une baisse de quota de volume
Toute action risquant d'augmenter le volume est bloquée :
- sur une restriction de `v1`, les secrets ne peuvent être que modifiés en restriction de taille ou supprimés.
- sur une restriction de `v2`, les pièces jointes des secrets ne peuvent être que modifiées en restriction de taille ou supprimées.
- en cas de double restriction `v1` et `v2` les deux règles ci-dessus se cumulent.

>La lecture reste possible : le téléchargement d'une sélection de secrets est soumis au quota de transfert, pas à celles sur les quotas de volume.

#### Restreindre un compte à la lecture seule des secrets.
Le comptable attribue des quotas de volume à 0 mais ne l'assortit pas d'un délai pour y parvenir.

## Comptables de l'organisation
Ce sont des comptes normaux mais dont les phrases secrètes (leur hash du moins) sont enregistrées dans la configuration de l'application (avec un code court) ce qui leur confère quelques possibilités d'actions :
- se créer eux-mêmes sans être parrainés (et se sont attribuer eux-mêmes des quotas).
- attribuer des quotas forfaitaires prédéfinis à une ligne de crédit.
- modifier ces quotas (potentiellement en mettant le compte correspondant en sursis) et fixer des dates limites de validité.
- fixer les dates de _blocage_.
- consulter toutes les lignes de crédit et les télécharger.
- consulter et répondre aux messages des compte.
- consulter le journal des actions des comptables

Une mise à jour note dans la ligne de crédit, la date-heure de la mise à jour et leur code court afin de permettre un audit sommaire éventuel (quel est le dernier qui a fait quoi, quand).

### Journal des actions des comptables
Chaque action est enregistrée dans un journal chronologique qui note aussi le justificatif donné par le comptable (ce justificatif ne figure pas dans la ligne de crédit elle-même).
- quand, qui, numéro de la ligne de crédit, états avant et après l'action, justification.

### Analyse statistique et historisation
L'ensemble des lignes de crédit peuvent être téléchargées par un comptable dans un tableur pour analyse globale et pouvoir détecter la marge de manœuvre dont il dispose pour gérer le site.

Depuis de tels extraits, il est possible, par un traitement externe, de construire et de maintenir un historique donnant les évolutions des lignes de crédit sur une période longue.

### Échanges textuels courts entre les comptables et les titulaires des comptes
Ces conversations sont enregistrées _par ligne de crédit_ avec pour chaque échange :
- sa date-heure,
- qui l'a émis (le compte ou un des comptables repéré par son numéro de mot de passe),
- son texte de moins de 140 signes.

La conversation conserve les échanges dans l'ordre chronologique inverse,
- ceux ayant moins de 6 semaines,
- au plus les 20 derniers.

Le titulaire d'un compte peut consulter sa conversation avec les comptables.

C'est par ce moyen que le titulaire d'un compte peut communiquer a minima avec les comptables en particulier pour leur demander un accroissement de ses quotas.

>Un compte peut toujours réduire de lui-même ses quotas (le cas échéant en dessous de ses volumes actuels ce qui enclenchera un état de _sursis_).

## Création de compte
### Compte parrainé
Le parrain prélève un pourcentage de son choix sur ses propres quotas : ceci permet au filleul un démarrage avec une ligne de crédit minimale mais existante.

Le parrain peut aussi fixer une date de validité mais qui ne peut pas être plus lointaine que la sienne.

### Compte non parrainé
Le compte a un pouvoir _comptable_ déclaré dans la configuration d'installation du site et peut se créer / gérer lui-même sa ligne de crédit.

>Manifestement les **comptables** ont le moyen de privilégier une ligne de crédit (voire la leur), et de _brimer_ une autre : c'est de l'organisation humaine que peut venir le contrôle d'éventuelles dérives et pressions et le respect des règles fixées par l'organisation.  
En tout état de cause, les comptables n'ont aucun moyen d'accéder aux contenus, ni même d'interpréter les meta données de la base qui est structurée de manière à crypter les liens entre comptes / avatars / groupes.

### Transfert de quotas
Un compte peut enregistrer un transfert de quotas à destination d'un de ses contacts : si une session du destinataire est ouverte ceci s'opère sur l'instant, sinon ça sera effectif à la prochaine ouverture de session du destinataire.

## Contrôle éthique ... ou non
Ce sujet ne concerne que les organisations ayant un objet social / politique : ses membres utilisent l'application pour les servir. 

Un comptable ne peut jamais lire le contenu des secrets : il peut certes bloquer des lignes de crédit, mais à quel titre ?
- supposons un avatar A partageant avec B des secrets que B considère comme contraire à l'objet de l'organisation. B n'a pas accès au numéro de ligne de crédit de A et ne peut donc pas demander à un comptable de la désactiver. Tout ce que B peut faire est de cesser le partage de secrets avec A.
- supposons un groupe G où se partagent des secrets sans rapport ou contraires à l'objet de l'organisation. 
  - un animateur du groupe peut résilier un membre perturbateur (s'il n'est pas animateur).
  - le numéro de ligne de crédit du groupe est connu des membres qui peuvent demander à un comptable d'intervenir sur cette ligne : au pire ceci peut aboutir à un blocage d'accès aux secrets du compte hébergeur du groupe (et au groupe lui-même).
  - mais n'importe quel animateur peut aussi changer la ligne de crédit du groupe, en prendre en charge l'hébergement et rien ne l'empêche de reconstituer un autre groupe, de récupérer les textes des secrets et leurs pièces jointes et d'y inviter ... presque tous les membres de l'ancien.

>Le pouvoir d'exclusion d'une telle organisation est restreint du fait de l'impossibilité de connaître les liens entre lignes de crédit, comptes, avatars et groupes. Toutefois l'organisation a au moins la possibilité d'inhiber les lignes de crédits des membres quittant l'organisation et d'éviter ainsi de continuer à héberger gratuitement l'activité de ceux qui la quitte.

#### Organisation totalement agnostique, _par cotisation_
La question _éthique_ ne se pose pas à une organisation par cotisation payante (même sans but lucratif) : tant qu'un compte acquitte ses cotisations, il n'a pas à subir de blocage / restriction, ni à respecter aucune règle de contenu que ce soit. C'est la simple application de la liberté de penser et de s'exprimer en privé.

Le titulaire d'un compte d'une telle organisation fait parvenir à la comptabilité de l'organisation des virements portant l'identifiant de sa ligne de crédit. 

Un des comptables met à jour la ligne de crédit correspondante avec une limite de validité correspondant au montant du virement reçu et au niveau des quotas souhaités.

>Les virements _pouvant_ être obscurs ou passer par un intermédiaire, il peut être quasi impossible de corréler (avec des moyens légaux) une personne physique ou morale à une ligne de crédit. In fine il est toujours complètement impossible ensuite de savoir quels avatars, groupes et secrets lui sont associés.

>Une telle organisation n'est pas obligatoirement à but lucratif : elle peut simplement proposer un service d'hébergement qui sera maintenu **tant que les comptes supportent effectivement la juste part** des coûts d'hébergement. Ce peut être une association citoyenne qui gère, sans profit, un hébergement mutualisé de secrets ou chaque membre cotise pour en supporter les frais.

>La publicité ciblée étant de facto impensable, le sponsoring reste, éventuellement, la seule source externe de financement (quoi que).

**L'application est agnostique vis à vis des contenus des secrets** qui peuvent être n'importe quoi, en bien ou en mal ... et selon ce que chacun considère comme bien ou mal: c'est une application qui reste du niveau de la communication / mémorisation **personnelle et/ou privée**, comme celle que peut avoir un groupe restreint d'amis discutant librement entre eux dans un domicile privé.  
C'est aussi pour cette raison qu'un groupe a une taille limitée, telle qu'il soit raisonnable de juger qu'il n'est pas public, et où tout le monde en contact se connaît et a été coopté.

>Ce n'est pas une application _libertaire_ mais _privée_. Être libertaire supposerait un accès public sans restriction ce qui n'est pas le cas.
