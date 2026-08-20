# Lafee Decurse

[GitHub — github.com/lafeeleonie](https://github.com/lafeeleonie) · [Twitch — twitch.tv/lafeeleonie](https://www.twitch.tv/lafeeleonie) · [Buy Me a Coffee / Donation](https://buymeacoffee.com/lafeeleonie)

Minimalist secure party utility and dispel frame for World of Warcraft Retail 12.1+.

## Overview

The addon displays five permanent buttons assigned to the fixed units `player`, `party1`, `party2`, `party3`, and `party4`. Each unit's role icon is displayed before its name. Names and the addon title can be hidden for a compact role-only layout.

Each mouse button can be assigned a known active spell that can target an allied player from the current character specialization:

1. left click;
2. right click;
3. middle click.

A new character/specialization profile is initialized with the same friendly dispel spells that Lafee Decurse previously assigned automatically. After that, the player can replace any click with another compatible allied-player spellbook ability, such as a friendly utility spell or resurrection. Offensive actions, auto attack, passive abilities, self-only abilities, and ground-target abilities are excluded from the selector.

Target compatibility is classified outside combat. Lafee Decurse ignores the actual in-range/out-of-range result and only uses whether Blizzard supports a unit range check for the spell. Dead-player resurrection spells are kept as explicit friendly-target exceptions because probing them against a living unit can be invalid.

The aura display remains independent from these configurable click actions. Blizzard-managed `CustomAuraContainerTemplate` frames determine which `HARMFUL|RAID_PLAYER_DISPELLABLE` auras are visible using only the dispel types the character can actually remove. The addon's Lua code never reads active aura data.

Aura count is configurable from one to five, and aura size always matches the unit-button height. Vertical party layouts can grow auras left or right; horizontal layouts can grow them up or down.

Up to three optional cooldown/recharge bars can be shown for the configured click spells. They are placed opposite the aura side. Vertical party layouts use vertical bars in one column; horizontal layouts use horizontal bars in one row. Cooldown animation is driven directly by Blizzard `LuaDurationObject` values rather than Lua arithmetic on cooldown timestamps.

## Commands

- `/ldec`: displays help;
- `/ldec lock`: locks or unlocks frame movement;
- `/ldec test`: toggles visual-only test auras while out of combat;
- `/ldec config`: opens the native configuration panel;
- `/ldec minimap`: shows or hides the minimap button.

Left-clicking the minimap button shows or hides the main frame. Right-clicking opens the configuration panel. The button can be dragged around the minimap.

## Architecture

- `Core.lua`: startup, events, commands, and state coordination;
- `DispelSpells.lua`: detection of the character's real friendly dispel capabilities;
- `ClickActions.lua`: per-character/per-specialization click profiles and allied-player spellbook choices;
- `SecureFrames.lua`: five secure buttons assigned to fixed units and configured spell IDs;
- `AuraDisplay.lua`: integration with Blizzard-managed aura containers;
- `CooldownBars.lua`: optional cooldown/recharge bars driven by Blizzard duration objects;
- `Config.lua`: modern panel integrated into the WoW settings interface;
- `Minimap.lua`: standalone minimap button with no external dependency;
- `Localization.lua` and `LocalizationOverrides.lua`: runtime localization strings pending the locale-folder refactor.

Spell and specialization changes received during combat are deferred until `PLAYER_REGEN_ENABLED`. Secure click assignments and layout changes are accepted only out of combat.

## Prototype limitations

- Warlock pet dispels are not supported;
- Private Auras are neither inspected nor displayed;
- in-game Retail 12.1 testing is still required to validate secure behavior and confirm the absence of taint.

## Localization

The interface, tooltips, commands, and messages support deDE, enUS/enGB, esES, esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, and zhTW. Localization files are being split into a dedicated folder in a follow-up change.

## License

This project is released under a restrictive proprietary license. Reproduction, redistribution, modification, and reuse are prohibited without prior written permission from the copyright holder. See [LICENSE.md](LICENSE.md).
