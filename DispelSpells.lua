local addonName, addon = ...

-- Friendly dispel IDs cross-checked with current Retail addon spell tables.
-- Runtime availability is verified through the Retail 12.1 spellbook API.
-- Detection only runs outside combat and never depends on active aura data.
local DISPEL_SPELLS = {
    DRUID = {
        { spellID = 88423, types = { Magic = true, Curse = true, Poison = true } }, -- Nature's Cure
        { spellID = 2782, types = { Curse = true, Poison = true } }, -- Remove Corruption
    },
    EVOKER = {
        { spellID = 360823, types = { Magic = true, Poison = true } }, -- Naturalize
        { spellID = 365585, types = { Poison = true } }, -- Expunge
        { spellID = 374251, types = { Curse = true, Disease = true, Poison = true } }, -- Cauterizing Flame
    },
    HUNTER = {
        { spellID = 459517, types = { Disease = true, Poison = true } }, -- Palliative Salve
    },
    MAGE = {
        { spellID = 412113, types = { Magic = true, Curse = true } }, -- Greater Remove Curse
        { spellID = 475, types = { Curse = true } }, -- Remove Curse
    },
    MONK = {
        { spellID = 115450, types = { Magic = true, Disease = true, Poison = true } }, -- Detox (Mistweaver)
        { spellID = 218164, types = { Disease = true, Poison = true } }, -- Detox
    },
    PALADIN = {
        { spellID = 4987, types = { Magic = true, Disease = true, Poison = true } }, -- Cleanse
        { spellID = 213644, types = { Disease = true, Poison = true } }, -- Cleanse Toxins
    },
    PRIEST = {
        { spellID = 527, types = { Magic = true }, diseasePassive = 390632 }, -- Purify
        { spellID = 213634, types = { Disease = true } }, -- Purify Disease
    },
    SHAMAN = {
        { spellID = 77130, types = { Magic = true, Curse = true } }, -- Purify Spirit
        { spellID = 51886, types = { Curse = true } }, -- Cleanse Spirit
    },
}

local function IsKnown(spellID)
    return C_SpellBook.IsSpellKnownOrInSpellBook(
        spellID,
        Enum.SpellBookSpellBank.Player,
        true
    )
end

local function GetDispelDefinition(spellID)
    local _, class = UnitClass("player")
    local definitions = class and DISPEL_SPELLS[class]
    if not definitions then
        return nil
    end

    -- Prefer an exact match. Some specialization dispels, notably the
    -- shaman's Purify Spirit, can report a related base spell without being
    -- an active override of that base spell.
    for _, definition in ipairs(definitions) do
        if definition.spellID == spellID then
            return definition
        end
    end

    -- Saved profiles may still contain an override identifier. Resolve its
    -- base only when no supported definition matched directly.
    local baseSpellID = C_SpellBook.FindBaseSpellByID(spellID) or spellID
    for _, definition in ipairs(definitions) do
        if definition.spellID == baseSpellID then
            return definition
        end
    end

    return nil
end

function addon:GetKnownFriendlyDispelSpellID(spellID)
    local definition = GetDispelDefinition(spellID)
    if not definition then
        return nil
    end

    local activeSpellID = C_SpellBook.FindSpellOverrideByID(definition.spellID) or definition.spellID
    if IsKnown(activeSpellID) or IsKnown(definition.spellID) then
        return activeSpellID
    end

    return nil
end

function addon:IsKnownFriendlyDispelSpell(spellID)
    return self:GetKnownFriendlyDispelSpellID(spellID) ~= nil
end

local function CopyTypes(definition)
    local types = {}
    for dispelType in pairs(definition.types) do
        types[dispelType] = true
    end

    if definition.diseasePassive and IsKnown(definition.diseasePassive) then
        types.Disease = true
    end

    return types
end

function addon:DetectDispelSpells()
    local _, class = UnitClass("player")
    local definitions = class and DISPEL_SPELLS[class]
    if not definitions then
        return {}
    end

    local dispels = {}
    local knownNames = {}
    for _, definition in ipairs(definitions) do
        local activeSpellID = self:GetKnownFriendlyDispelSpellID(definition.spellID)
        if activeSpellID then
            local spellName = C_Spell.GetSpellName(activeSpellID)
            if spellName and not knownNames[spellName] then
                knownNames[spellName] = true
                table.insert(dispels, {
                    spellID = activeSpellID,
                    spellName = spellName,
                    dispelTypes = CopyTypes(definition),
                })

                if #dispels == 3 then
                    break
                end
            end
        end
    end

    return dispels
end

function addon:GetCombinedDispelTypes(dispels)
    local combinedTypes = {}
    for _, dispel in ipairs(dispels or {}) do
        for dispelType in pairs(dispel.dispelTypes) do
            combinedTypes[dispelType] = true
        end
    end
    return combinedTypes
end
