# Lafee Decurse

[GitHub — github.com/lafeeleonie](https://github.com/lafeeleonie) · [Twitch — twitch.tv/lafeeleonie](https://www.twitch.tv/lafeeleonie) · [Buy Me a Coffee / Donation](https://buymeacoffee.com/lafeeleonie)

Minimalist secure party utility and dispel frame for World of Warcraft Retail 12.1+.

## Overview

The addon displays five permanent buttons assigned to the fixed units `player`, `party1`, `party2`, `party3`, and `party4`. Each unit's role icon is displayed before its name. Names and the addon title can be hidden for a compact role-only layout.

Every character specialization has one complete profile. The same profile table stores position, minimap, layout, background, aura display, dispel glow, click actions, and cooldown-bar choices. Switching specialization therefore switches the complete Lafee Decurse configuration, not only the assigned spells.

SavedVariables are stored as `LafeeDecurseDB.profiles[character][specID]`. Older alpha layouts are migrated automatically: global display settings, the temporary per-character settings format from the early PR #7 draft, and the previous `characterProfiles[character][specID]` click-action store are merged into the new unified specialization profile without intentionally discarding existing settings.

Each mouse button can be assigned a known active spell that can target an allied player from the current character specialization:

1. left click;
2. right click;
3. middle click.

A new character/specialization profile is initialized with the same friendly dispel spells that Lafee Decurse previously assigned automatically. After that, the player can replace any click with another compatible allied-player spellbook ability, such as a friendly utility spell or resurrection. Offensive actions, auto attack, passive abilities, self-only abilities, and ground-target abilities are excluded from the selector.

Target compatibility is classified outside combat. Lafee Decurse ignores the actual in-range/out-of-range result and only uses whether Blizzard supports a unit range check for the spell. Dead-player resurrection spells are kept as explicit friendly-target exceptions because probing them against a living unit can be invalid.

The aura display remains independent from these configurable click actions. Blizzard-managed `CustomAuraContainerTemplate` frames determine which `HARMFUL|RAID_PLAYER_DISPELLABLE` auras are visible using only the dispel types the character can actually remove. The addon's Lua code never reads active aura data.

Aura count is configurable from one to five, and aura size always matches the unit-button height. Vertical party layouts can grow auras left or right; horizontal layouts can grow them up or down.

A dedicated Blizzard-managed aura slot can also drive a dispel glow without exposing active aura state to addon Lua. Aura icons and this glow can be enabled independently, so the frame can run in a compact “glow means dispel” mode. The glow appearance is configurable with three styles — pulse, marching ants, and solid — plus color, animation speed, and border thickness. `/ldec test` reproduces the same selected glow appearance without reading any real aura state.

Up to three optional cooldown/recharge bars can be shown for the configured click spells. They are placed opposite the aura side. Vertical party layouts use vertical bars in one column; horizontal layouts use horizontal bars in one row. Cooldown animation is driven directly by Blizzard `LuaDurationObject` values rather than Lua arithmetic on cooldown timestamps.

## Commands

- `/ldec`: displays help;
- `/ldec lock`: locks or unlocks frame movement;
- `/ldec test`: toggles visual-only test auras and the configured test glow while out of combat;
- `/ldec config`: opens the native configuration panel;
- `/ldec minimap`: shows or hides the minimap button.

Left-clicking the minimap button shows or hides the main frame. Right-clicking opens the configuration panel. The button can be dragged around the minimap.

## Architecture

- `Profiles.lua`: unified character/specialization profile selection plus migration of older SavedVariables layouts;
- `Core.lua`: startup, profile application, events, commands, and state coordination;
- `DispelSpells.lua`: detection of the character's real friendly dispel capabilities;
- `ClickActions.lua`: allied-player spellbook choices stored directly in the active specialization profile;
- `SecureFrames.lua`: five secure buttons assigned to fixed units and configured spell IDs;
- `AuraDisplay.lua`: Blizzard-managed aura icons, managed dispel glow slot, and visual glow styles;
- `CooldownBars.lua`: optional cooldown/recharge bars driven by Blizzard duration objects;
- `Config.lua`: modern panel integrated into the WoW settings interface;
- `GlowConfig.lua`: glow style, color, speed, and thickness controls;
- `Minimap.lua`: standalone minimap button with per-profile position/visibility;
- `Locales/`: one localization table per supported language plus the locale loader.

Spell and specialization changes received during combat are deferred until `PLAYER_REGEN_ENABLED`. Secure click assignments, layout changes, and glow appearance changes are accepted only out of combat.

## Prototype limitations

- Warlock pet dispels are not supported;
- Private Auras are neither inspected nor displayed;
- the managed glow still requires in-game Retail 12.1 validation across combat transitions to confirm the absence of taint, forbidden-object errors, or secret-value issues;
- in-game Retail 12.1 testing is still required to validate secure behavior and confirm the absence of taint.

## Localization

Localization files live under `Locales/` for deDE, enUS/enGB, esES/esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, and zhTW. `enGB` reuses `enUS`, `esMX` reuses `esES`, and missing keys fall back to English.

## License

This project is released under a restrictive proprietary license. Reproduction, redistribution, modification, and reuse are prohibited without prior written permission from the copyright holder. See [LICENSE.md](LICENSE.md).
