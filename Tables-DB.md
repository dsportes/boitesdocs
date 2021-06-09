`versions` (id) : table des prochains numéros de versions (actuel et dernière sauvegarde)  
`etat` (singleton) : état courant permanent du serveur  
`avgrvq` (id) : volumes et quotas d'un avatar ou groupe  
`sga` (ida) : signature d'un avatar  
`sgg` (idg) : signature d'un groupe  
`sgc` (idc) : signature d'un compte
`sgs` (ids) : signature d'un secret  
`compte` (idc) : authentification et données d'un compte  
`avgrcv` (id) : carte de visite d'un avatar ou groupe  
`avrsa` (ida) : clé publique d'un avatar  
`avidc1` (ida) : identifications et clés c1 des contacts d'un avatar  
`avcontact` (ida, nc) : données d'un contact d'un avatar    
`avinvit` () (idb) : invitation adressée à B à lier un contact avec A  
`parrain` (dpbh) : offre de parrainage d'un avatar A pour la création d'un compte inconnu  
`rencontre` (dpbh) : communication par A de son identifications complète à un compte inconnu  
`grlmg` (idg) : liste des id + nc + c1 des membres du groupe  
`grmembre` (idg, nm) : données d'un membre du groupe  
`grinvit` () (idm) : invitation à M à devenir membre d'un groupe  
`secret` (ids) : données d'un secret
`avsecret` (ida, idcs) : aperçu d'un secret pour un avatar (ou référence de son groupe)  
