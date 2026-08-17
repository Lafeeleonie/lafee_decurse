# Lafee Decurse

[GitHub — github.com/lafeeleonie](https://github.com/lafeeleonie) · [Twitch — twitch.tv/lafeeleonie](https://www.twitch.tv/lafeeleonie) · [Buy Me a Coffee / Donation](https://buymeacoffee.com/lafeeleonie)

Minimalist dispel frame prototype for World of Warcraft Retail 12.1+.

## Overview

The addon displays five permanent buttons assigned to the fixed units `player`, `party1`, `party2`, `party3`, and `party4`. Each unit's role icon is displayed before its name. Names and the addon title can be hidden for a compact role-only layout.

Up to three distinct friendly dispel spells are assigned automatically:

1. left click;
2. right click;
3. middle click, only when a third spell is available.

Each button contains a Blizzard `CustomAuraContainerTemplate` configured with a managed `AuraGroup` limited to three icons. Blizzard alone determines whether to display an aura matching the `HARMFUL|RAID_PLAYER_DISPELLABLE` filter and the dispel types supported by the assigned spells. The addon's Lua code never reads active aura data.

The native settings panel provides a three-aura visual test, vertical or horizontal player layouts, three background modes (full frame, player frames only, or hidden), class-colored frames or a custom background with adjustable opacity, title/name visibility, frame locking, minimap visibility, and position/color reset controls. In horizontal mode, player buttons run from left to right and their auras grow downward.

## Commands

- `/ldec`: displays help;
- `/ldec lock`: locks or unlocks frame movement;
- `/ldec test`: toggles three visual-only test auras while out of combat;
- `/ldec config`: opens the native configuration panel;
- `/ldec minimap`: shows or hides the minimap button.

Left-clicking the minimap button shows or hides the main frame. Right-clicking opens the configuration panel. The button can be dragged around the minimap.

## Architecture

- `Core.lua`: startup, events, commands, and state coordination;
- `SecureFrames.lua`: five secure buttons assigned to fixed units;
- `AuraDisplay.lua`: integration with Blizzard-managed aura containers;
- `DispelSpells.lua`: out-of-combat detection of up to three dispel spells;
- `Config.lua`: modern panel integrated into the WoW settings interface;
- `Minimap.lua`: standalone minimap button with no external dependency;
- `Localization.lua`: runtime localization strings.

Spell and specialization changes received during combat are deferred until `PLAYER_REGEN_ENABLED`. Layout changes are accepted only out of combat because they reposition secure buttons.

## Prototype limitations

- a maximum of three distinct spells can be assigned to clicks;
- Warlock pet dispels are not supported;
- Private Auras are neither inspected nor displayed by this MVP;
- in-game Retail 12.1 testing is still required to validate secure behavior and confirm the absence of taint.

## Localization

The interface, tooltips, commands, and messages are localized at runtime through `Localization.lua` for deDE, enUS/enGB, esES, esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, and zhTW.

## License

This project is released under a restrictive proprietary license. Reproduction, redistribution, modification, and reuse are prohibited without prior written permission from the copyright holder. See [LICENSE.md](LICENSE.md).
