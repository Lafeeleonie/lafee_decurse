Je veux créer un addon World of Warcraft Retail 12.1+ servant de remplaçant minimaliste à Decursive / RL Decurse, compatible avec les nouvelles restrictions sur les auras secrètes de Midnight 12.1.

OBJECTIF

Créer un prototype fonctionnel de mini-partyframe dédié au dispel :

- 5 cadres maximum :
  - player
  - party1
  - party2
  - party3
  - party4
- chaque cadre correspond à une unité fixe ;
- chaque cadre doit pouvoir afficher visuellement les debuffs que le joueur courant est réellement capable de dissiper ;
- cliquer sur le cadre lance le sort de dispel approprié sur cette unité ;
- le fonctionnement doit rester compatible avec le combat et les restrictions secure/taint de WoW 12.1.

IMPORTANT : NE PAS recréer l'ancien fonctionnement de Decursive.

WoW 12.1 empêche désormais les addons d'inspecter librement les données des auras en combat.

Il est donc INTERDIT d'implémenter une logique basée sur :

- C_UnitAuras.GetDebuffDataByIndex()
- C_UnitAuras.GetAuraDataByIndex()
- récupération du spellId actif
- récupération du dispelName d'une aura active
- traitement de UNIT_AURA permettant à Lua de déterminer qui doit être dispellé
- boucle de scan des debuffs
- détection Lua du type Magic / Curse / Poison / Disease d'une aura présente
- IsShown() ou tout autre moyen détourné servant à récupérer en Lua l'information "cette unité a quelque chose à dispel"
- tri dynamique des unités selon la présence d'un debuff
- choix automatique de la cible à dispel.

L'addon ne doit JAMAIS avoir besoin de savoir en Lua quel debuff est présent.

ARCHITECTURE À UTILISER

Je veux explorer et utiliser les nouvelles API d'affichage d'auras introduites pour WoW 12.1, notamment :

- CustomAuraContainer
- ManagedAuraContainer
- les Aura Processing Policies associées
- les filtres Blizzard tels que :
  HARMFUL|RAID_PLAYER_DISPELLABLE

Ne suppose pas aveuglément le nom ou la signature exacte des API.

AVANT de coder :
1. inspecte le code/API Blizzard Retail 12.1 disponible dans wow-ui-source ;
2. cherche comment Blizzard utilise ManagedAuraContainer / CustomAuraContainer ;
3. regarde éventuellement les implémentations Retail 12.1 actuelles de Plater et/ou ElvUI uniquement comme références techniques ;
4. détermine quelle API publique est réellement destinée aux addons ;
5. utilise uniquement une solution valide pour WoW Retail 12.1.

Si CustomAuraContainer n'est pas directement utilisable par un addon, trouve le mécanisme public équivalent prévu par Blizzard.

Ne contourne pas les restrictions des Secret Values.

AFFICHAGE DES AURAS

Pour chaque unité :

- créer un conteneur d'auras géré par Blizzard ;
- demander uniquement l'affichage des debuffs dispellables par le joueur ;
- idéalement utiliser :
  HARMFUL|RAID_PLAYER_DISPELLABLE
  ou l'équivalent officiel 12.1 ;
- limiter le prototype à 1 aura visible par unité ;
- afficher l'icône du debuff directement dans le cadre ;
- afficher cooldown/durée uniquement si le composant Blizzard le permet naturellement sans exposer de Secret Value à notre Lua.

Notre Lua ne doit pas recevoir les données de l'aura pour ensuite décider de l'afficher.

C'est le conteneur Blizzard qui doit faire cette décision.

CLIC DE DISPEL

Chaque cadre doit être un bouton sécurisé ou contenir un bouton sécurisé.

Utiliser l'architecture SecureActionButtonTemplate / SecureUnitButtonTemplate appropriée.

Exemple conceptuel :

button:SetAttribute("type1", "spell")
button:SetAttribute("spell1", dispelSpell)
button:SetAttribute("unit", "party1")

Mais adapte cela aux API Retail 12.1 réellement valides.

Les unités doivent être fixes :

- player
- party1
- party2
- party3
- party4

Ne jamais modifier leurs attributs secure en combat.

Si une modification est nécessaire pendant le combat :
- la mettre en attente ;
- l'appliquer sur PLAYER_REGEN_ENABLED.

Le clic gauche doit lancer le dispel sur l'unité correspondante.

Pour le MVP, un seul sort de dispel actif est suffisant.

DÉTECTION DU SORT DE DISPEL

Déterminer quel sort de dispel le personnage peut utiliser.

Cette détection peut être faite :
- au chargement ;
- au changement de spécialisation ;
- hors combat.

Utiliser les API de spellbook/known spells autorisées.

Créer une table claire des capacités de dispel par classe/spécialisation si nécessaire.

IMPORTANT :
ne suppose pas les spell IDs actuels si tu ne les as pas vérifiés dans l'API Retail 12.1.

Pour une première version, il est acceptable de supporter uniquement les classes/spécialisations possédant un dispel allié standard, à condition que l'architecture soit extensible.

INTERFACE MVP

Créer un cadre principal déplaçable contenant cinq petites cases.

Disposition par défaut verticale :

[player]
[party1]
[party2]
[party3]
[party4]

Chaque case doit afficher au minimum :
- nom du joueur ;
- icône d'aura dispellable si Blizzard en fournit une ;
- bordure simple.

Dimensions par défaut par exemple :
120 x 30 px.

Ne crée pas encore une usine à gaz de configuration.

Commandes minimales :

/ldec
    affiche l'aide

/ldec lock
    verrouille/déverrouille le déplacement

/ldec test
    affiche éventuellement un mode de test VISUEL uniquement si cela peut être fait sans toucher au système secure/aura réel.

Nom temporaire de l'addon :
LafeeDecurse

Structure souhaitée :

LafeeDecurse/
├── LafeeDecurse.toc
├── Core.lua
├── SecureFrames.lua
├── AuraDisplay.lua
├── DispelSpells.lua
└── README.md

Tu peux adapter légèrement la structure si une autre séparation est plus logique.

AUCUNE DÉPENDANCE OBLIGATOIRE

L'addon doit fonctionner sans :
- ElvUI
- Ace3
- LibStub
- autres bibliothèques.

ElvUI pourra éventuellement être détecté plus tard uniquement pour du skin.

PRIVATE AURAS

Étudier également les Private Auras de WoW 12.1.

Si Blizzard propose un PrivateAuraAnchor ou mécanisme équivalent pouvant être attaché à nos cadres sans exposer les données à Lua :
- préparer l'architecture pour pouvoir l'ajouter ;
- mais ce n'est pas obligatoire pour le MVP.

Ne tente surtout pas de contourner les Private Auras.

TAINT / COMBAT LOCKDOWN

C'est un point critique.

Le code doit :
- éviter toute modification d'attribut secure en combat ;
- ne pas reparent/repositionner des secure frames en combat si interdit ;
- ne pas appeler une méthode protégée depuis du code tainted ;
- différer les mises à jour nécessaires jusqu'à PLAYER_REGEN_ENABLED ;
- éviter les hooks risqués sur Blizzard/ElvUI ;
- fonctionner indépendamment des partyframes Blizzard et ElvUI.

Ajouter des commentaires dans le code aux endroits où le combat lockdown est important.

CE QUE JE VEUX ABSOLUMENT ÉVITER

Pas de :

if unitHasDispellableDebuff then
    ...
end

si cette information provient de l'inspection d'une aura active.

Pas de :

for i = 1, 40 do
    local aura = C_UnitAuras.GetDebuffDataByIndex(...)
end

Pas de moteur de priorité.

Pas de "sélectionne automatiquement le premier joueur ayant besoin d'un dispel".

Pas de changement dynamique du bouton en fonction de l'aura.

Les cinq boutons existent en permanence et ciblent toujours leur unité fixe.

Le joueur voit l'indication Blizzard et choisit lui-même où cliquer.

LOGIQUE ATTENDUE

Conceptuellement :

                   LafeeDecurse
                        |
            +-----------+-----------+
            |                       |
     Secure Unit Button       Aura Container
            |                       |
       unit = party1       unit = party1
       spell = dispel      filter = dispellable
            |                       |
       clic humain          affichage Blizzard

Les deux systèmes doivent rester indépendants.

Notre addon associe simplement les deux éléments graphiquement.

PHASE 1 : RECHERCHE

Avant toute modification de fichiers, produis dans ta réponse une courte analyse avec :

1. les API Retail 12.1 exactes que tu as trouvées ;
2. le template/frame type que tu vas utiliser pour les auras ;
3. le mécanisme de filtre dispellable ;
4. le template sécurisé choisi pour le clic ;
5. les éventuelles limitations découvertes.

Si l'hypothèse "CustomAuraContainer + RAID_PLAYER_DISPELLABLE" est incorrecte, dis-le clairement et adapte l'architecture.

N'invente aucune API.

PHASE 2 : IMPLÉMENTATION

Implémente ensuite le MVP.

PHASE 3 : VÉRIFICATION

Après implémentation :

- inspecte tout le code à la recherche d'accès interdits aux auras ;
- cherche les appels C_UnitAuras ;
- cherche les modifications de secure attributes pouvant se produire en combat ;
- cherche les risques de taint ;
- vérifie que les cinq unités sont fixes ;
- vérifie qu'aucune logique Lua ne dépend de la présence d'un debuff.

Puis donne-moi :

- la liste des fichiers créés/modifiés ;
- les choix techniques effectués ;
- les éventuelles choses à tester impérativement en jeu.

CRITÈRES DE RÉUSSITE DU MVP

Le prototype est considéré comme réussi si :

1. je rejoins un groupe de 5 joueurs ;
2. LafeeDecurse affiche les cinq unités ;
3. un joueur reçoit un debuff que ma spécialisation peut dispel ;
4. une indication d'aura apparaît sur SA case grâce au système Blizzard ;
5. notre Lua n'a pas inspecté l'aura ;
6. je clique sur sa case ;
7. mon sort de dispel est lancé sur cette unité ;
8. cela fonctionne en combat ;
9. aucune erreur Lua de type secret value / forbidden object / taint n'apparaît.

Priorité absolue :
faire d'abord une preuve de concept techniquement correcte pour Retail 12.1.

L'esthétique et les options viendront après.