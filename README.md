# Lafee Decurse

Prototype minimaliste de cadres de dissipation pour World of Warcraft Retail 12.1+.

## Principe

L’addon affiche cinq boutons permanents associés aux unités fixes `player`, `party1`, `party2`, `party3` et `party4`. L’icône du rôle est affichée avant le nom de chaque unité.

Jusqu’à trois sorts de dissipation alliés distincts sont attribués automatiquement :

1. clic gauche ;
2. clic droit ;
3. clic molette, uniquement lorsqu’un troisième sort est disponible.

Chaque bouton contient un `CustomAuraContainerTemplate` Blizzard configuré avec un unique `AuraSlot`. Blizzard décide seul si une aura correspondant au filtre `HARMFUL|RAID_PLAYER_DISPELLABLE` et aux types que le sort actif peut dissiper doit être affichée. Le Lua de l’addon ne lit jamais les auras actives.

## Commandes

- `/ldec` : affiche l’aide ;
- `/ldec lock` : verrouille ou déverrouille le déplacement ;
- `/ldec test` : active un indicateur purement visuel, uniquement hors combat.
- `/ldec config` : ouvre le panneau de configuration natif ;
- `/ldec minimap` : affiche ou masque le bouton de minimap.

Le bouton de minimap permet d’afficher ou masquer le cadre avec le clic gauche et d’ouvrir la configuration avec le clic droit. Il peut être déplacé autour de la minimap.

## Architecture

- `Core.lua` : démarrage, événements, commandes et état ;
- `SecureFrames.lua` : cinq boutons sécurisés à unités fixes ;
- `AuraDisplay.lua` : intégration au conteneur d’auras géré par Blizzard ;
- `DispelSpells.lua` : détection hors combat de trois sorts de dissipation au maximum ;
- `Config.lua` : panneau moderne intégré aux paramètres de WoW ;
- `Minimap.lua` : bouton de minimap autonome, sans bibliothèque externe.

Les changements de sort, de spécialisation et de configuration protégée reçus en combat sont différés jusqu’à `PLAYER_REGEN_ENABLED`.

## Limites du prototype

- trois sorts distincts au maximum sont attribués aux clics ;
- les sorts de familiers du démoniste ne sont pas pris en charge ;
- les Private Auras ne sont ni inspectées ni affichées par ce MVP ;
- une validation en jeu Retail 12.1 reste indispensable pour confirmer le comportement secure et l’absence de taint.

## Localisations

L’interface, les infobulles, les commandes et les messages sont localisés à l’exécution par `Localization.lua` pour deDE, enUS/enGB, esES, esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN et zhTW. Les tableaux de référence restent disponibles dans `locales/`.

## Licence

Ce projet est publié sous une licence propriétaire restrictive. La reproduction, redistribution, modification et réutilisation ne sont pas autorisées sans accord écrit préalable du titulaire des droits. Consulter [LICENSE.md](LICENSE.md).
