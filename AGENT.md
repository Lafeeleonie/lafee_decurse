# AGENTS.md

## Project

This repository contains a World of Warcraft Retail addon targeting WoW 12.1+.

The addon is intended to provide a lightweight Decursive-like dispel interface while respecting the new aura privacy, secret-value, secure-action, and combat-lockdown restrictions introduced in modern WoW.

The primary goal is correctness in-game.

A smaller implementation that respects Blizzard's API is always preferable to a more feature-rich implementation relying on forbidden, deprecated, speculative, or tainted behavior.


# General rules

## Never invent APIs

Do not invent:
- WoW API functions;
- frame templates;
- mixins;
- events;
- enum members;
- aura filters;
- secure attributes;
- callback signatures.

Before using an unfamiliar or recently changed WoW API, verify it against the current WoW 12.1 UI source or API documentation.

If an API cannot be verified, explicitly state that instead of guessing.

Do not write speculative compatibility wrappers around APIs that may not exist.


## Research before implementation

For WoW 12.1-specific behavior, inspect the current Blizzard UI source before implementing the feature.

Prefer, in this order:

1. Blizzard API documentation / generated API documentation;
2. Blizzard FrameXML / UI source;
3. known working current addons such as ElvUI or Plater as implementation references;
4. older addon code only for conceptual reference.

Third-party addon code must never override what the current Blizzard API actually supports.


## WoW version

Target:
- World of Warcraft Retail;
- interface/API 12.1 and newer.

Do not add compatibility code for Classic, Cataclysm Classic, or older Retail versions unless explicitly requested.

Do not carry obsolete compatibility layers merely because older addons used them.


# Aura handling

## Critical rule

Lua code in this addon must NOT determine whether a unit currently has a dispellable aura by inspecting protected/secret aura data.

The addon must rely on Blizzard-managed aura display mechanisms whenever aura information is secret.


## Forbidden aura scanning

Do not implement aura scanning using patterns such as:

    C_UnitAuras.GetDebuffDataByIndex(...)
    C_UnitAuras.GetAuraDataByIndex(...)
    C_UnitAuras.GetAuraDataByAuraInstanceID(...)

when their purpose is to inspect active secret/protected auras.

Do not reimplement the historical UnitDebuff scanning model used by old versions of Decursive.


## Forbidden decision logic

Do not write logic equivalent to:

    if unitHasDispellableDebuff then
        ...
    end

when unitHasDispellableDebuff was derived from inspecting active aura data.

Do not use active aura information in Lua to:

- select a dispel target;
- sort units;
- hide/show unit buttons;
- change secure attributes;
- prioritize players;
- choose a spell;
- trigger sounds;
- change colors;
- move frames;
- build a dispel queue.


## No side-channel extraction

Do not attempt to recover secret aura state indirectly.

For example, do not query the visibility, size, state, texture, child count, or other properties of Blizzard-managed aura frames merely to reconstruct:

"this unit currently has a dispellable debuff."

The managed aura display is for the player to see, not for addon Lua to convert back into combat information.


## Managed aura display

Prefer the official WoW 12.1 managed/custom aura container system.

Investigate and use the current public equivalent of:

- ManagedAuraContainer;
- CustomAuraContainer;
- supported aura processing policies;
- supported dispellable aura filters.

For player-dispellable debuffs, prefer Blizzard-provided filtering such as:

    HARMFUL|RAID_PLAYER_DISPELLABLE

only after confirming that the exact filter is supported in the target 12.1 API.

The addon should ask Blizzard to display eligible auras.

Lua should not fetch an aura and decide afterward whether to display it.


# Secure actions

## Fixed unit buttons

Party unit buttons must correspond to fixed units:

    player
    party1
    party2
    party3
    party4

Do not dynamically assign the next dispellable player to a button.


## Human choice

The player chooses which unit to dispel by clicking its corresponding frame.

Never implement:

- automatic target selection;
- automatic dispelling;
- "first dispellable unit";
- rotating targets;
- smart target selection based on debuffs.


## Secure casting

Use the appropriate Blizzard secure-action system for spell casting.

Prefer a secure button architecture equivalent to:

    button:SetAttribute("type1", "spell")
    button:SetAttribute("spell1", dispelSpell)
    button:SetAttribute("unit", unit)

but verify the exact implementation against the current Retail 12.1 API before relying on it.


# Combat lockdown and taint

Treat combat lockdown as a core architectural constraint, not an edge case.

Never modify protected attributes in combat.

Before performing operations on secure/protected frames, consider:

    InCombatLockdown()

If an update cannot safely occur during combat:

1. mark it pending;
2. perform it after PLAYER_REGEN_ENABLED.


## Avoid in combat

Unless explicitly documented as safe, do not in combat:

- change secure attributes;
- change a secure unit assignment;
- change a secure spell assignment;
- reparent protected frames;
- create/rebuild secure unit frames;
- change protected frame anchoring;
- change protected frame layout.


## Taint

Avoid hooking Blizzard or ElvUI protected functions unless absolutely necessary.

Do not modify Blizzard frames when an independent implementation can provide the feature.

Prefer isolated addon-owned frames.

When a taint or forbidden-object error occurs, investigate the source rather than suppressing the error.


# Dispel spell detection

Determine the player's available friendly dispel outside combat using supported spellbook/known-spell APIs.

Reevaluate when relevant events occur, for example:

- login;
- specialization change;
- talent changes;
- spell availability changes.

Do not infer current spell IDs from old addon code.

Verify spell IDs and API usage for Retail 12.1 before adding them.


# Architecture

Keep the display system and casting system independent.

Conceptually:

    UnitFrame
    |
    +-- Secure dispel button
    |     |
    |     +-- fixed unit
    |     +-- fixed known dispel spell
    |
    +-- Blizzard-managed aura display
          |
          +-- same unit
          +-- dispellable filter

The secure button must not depend on the aura container reporting whether an aura exists.

The aura container must not change the secure button's target or spell.


# Party frames

The initial implementation supports:

    player
    party1
    party2
    party3
    party4

Prefer five persistent frames rather than dynamically creating only afflicted units.

Group roster changes may update:

- name;
- class information;
- unit existence;
- non-protected visual information.

Any protected update must respect combat lockdown.


# UI

Keep the initial UI simple.

Prioritize:

1. correct aura display;
2. correct secure casting;
3. no taint;
4. reliable combat behavior;
5. readability.

Only then add configuration and cosmetic options.

Avoid introducing a large framework for trivial UI settings.


# Dependencies

The addon must work without:

- ElvUI;
- Ace3;
- LibStub;
- third-party libraries.

ElvUI may later be detected for optional skin integration only.

Core functionality must never depend on ElvUI.


# ElvUI / Plater references

ElvUI and Plater may be inspected to understand how actively maintained addons interact with WoW 12.1 APIs.

Do not copy large blocks of their implementation.

Extract the API usage pattern, then implement an original solution appropriate for this addon.

Respect upstream licenses.


# Private Auras

Do not attempt to inspect or bypass Private Auras.

If Blizzard provides a supported Private Aura display/anchor mechanism, it may be used only as intended.

Private Aura information must not be converted into Lua decision-making state.


# Code style

Use readable Lua.

Prefer local functions:

    local function UpdateSomething()
    end

over unnecessary global functions.

Avoid unnecessary globals.

Keep modules focused.

Suggested responsibilities:

    Core.lua
        startup, events, state coordination

    SecureFrames.lua
        secure unit buttons and combat-lockdown handling

    AuraDisplay.lua
        managed aura display integration

    DispelSpells.lua
        known friendly dispel definitions/detection

    Config.lua
        saved variables and configuration, if needed


## Namespacing

Do not pollute _G.

Use the addon namespace passed through:

    local addonName, addon = ...

Share functions/state through addon when appropriate.


## Defensive coding

Do not use pcall merely to hide invalid API usage.

Do not silence errors caused by forbidden APIs.

An API producing a secret-value or forbidden-object error means the architecture must be reconsidered.


# Scope control

Do not modify unrelated files.

Do not refactor unrelated working code while implementing a feature.

Do not perform mass formatting changes unless requested.

Keep patches focused on the requested task.


# Existing behavior

Before replacing an existing implementation:

1. understand what it does;
2. identify why it fails;
3. preserve working behavior where compatible;
4. replace only the portion made invalid by WoW 12.1.

Do not delete functioning features simply because rewriting them is easier unless the existing architecture is fundamentally incompatible.


# Debugging

When investigating a Lua error:

1. read the complete stack trace;
2. locate the first addon-owned frame/function involved;
3. determine whether the failure involves:
   - taint;
   - combat lockdown;
   - secret values;
   - forbidden objects;
   - removed API;
   - invalid frame lifecycle;
4. fix the root cause.

Do not blindly add:

    if not value then return end

unless the absence of the value is legitimately expected.


# Testing

Static inspection is not enough for secure WoW UI code.

After each meaningful change, identify what must be tested in-game.

At minimum test:

- login;
- reload UI;
- solo;
- joining a party;
- leaving a party;
- party roster changes;
- entering combat;
- leaving combat;
- receiving a dispellable debuff;
- clicking a unit while in combat;
- specialization changes;
- /reload while grouped when possible.


## Error testing

Check specifically for:

- Lua errors;
- blocked actions;
- forbidden object errors;
- secret-value errors;
- taint warnings;
- combat-lockdown errors.


# Static verification before completion

Before considering a task complete, search the modified code for:

    C_UnitAuras
    UnitAura
    UnitDebuff
    SetAttribute
    RegisterAttributeDriver
    InCombatLockdown
    PLAYER_REGEN_ENABLED

Review each relevant occurrence manually.

The presence of C_UnitAuras is not automatically forbidden, but any use that exposes active secret aura data for decision-making must be rejected.


# Completion criteria

Do not claim a feature works in-game unless it has actually been tested in-game.

If only static/code analysis was possible, explicitly say:

"Implementation complete; in-game validation still required."

At the end of a task, report:

1. files modified;
2. major technical decisions;
3. API assumptions verified;
4. remaining uncertainties;
5. exact in-game tests required.


# Git

Before making changes:

    git status

Understand the existing working tree.

Do not discard user changes.

Do not reset, clean, checkout, or overwrite unrelated modifications.

Never use destructive Git commands unless explicitly requested.


## Commits

Do not create commits unless explicitly requested.

Do not push unless explicitly requested.

Do not open a pull request unless explicitly requested.

When asked to commit:

- include only files belonging to the requested change;
- use a concise descriptive commit message.


# Documentation

Update README/documentation when behavior, commands, installation, or architecture materially changes.

Do not document speculative features as implemented.


# Priority order

When rules conflict, optimize for:

1. WoW API legality;
2. no taint / no forbidden actions;
3. correct behavior in combat;
4. maintainability;
5. usability;
6. cosmetics.


# Final principle

Never fight the WoW 12.1 secret-value system.

If Blizzard intentionally prevents addon Lua from learning a piece of combat information, redesign the feature so that Blizzard displays the information directly to the player instead.

The addon should provide:

- presentation;
- secure fixed-unit actions;
- configuration.

The human player must remain responsible for interpreting the displayed information and choosing the action.