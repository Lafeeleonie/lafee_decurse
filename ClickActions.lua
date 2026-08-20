local addonName, addon = ...
local L = addon.L

local PLAYER_SPELL_BANK = Enum.SpellBookSpellBank.Player

local function GetCharacterKey()
    local guid = UnitGUID("player")
    if guid then
        return guid
    end

    local name = UnitName("player") or "player"
    local realm = GetRealmName() or "realm"
    return name .. "-" .. realm
end

local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then
        return 0
    end

    return GetSpecializationInfo(specIndex) or 0
end

function addon:GetCurrentActionProfile(defaultDispels)
    LafeeDecurseDB.characterProfiles = LafeeDecurseDB.characterProfiles or {}

    local characterKey = GetCharacterKey()
    local characterProfiles = LafeeDecurseDB.characterProfiles[characterKey]
    if not characterProfiles then
        characterProfiles = {}
        LafeeDecurseDB.characterProfiles[characterKey] = characterProfiles
    end

    local specID = GetCurrentSpecID()
    local profile = characterProfiles[specID]
    if not profile then
        profile = {
            clickSpells = {},
            cooldownBars = {},
            initialized = false,
        }
        characterProfiles[specID] = profile
    end

    profile.clickSpells = profile.clickSpells or {}
    profile.cooldownBars = profile.cooldownBars or {}

    if not profile.initialized then
        for clickIndex = 1, 3 do
            local dispel = defaultDispels and defaultDispels[clickIndex]
            profile.clickSpells[clickIndex] = dispel and dispel.spellID or nil
            profile.cooldownBars[clickIndex] = false
        end
        profile.initialized = true
    end

    self.currentActionProfile = profile
    return profile
end

local function BuildSpellEntry(spellID)
    if not spellID then
        return nil
    end

    local spellName = C_Spell.GetSpellName(spellID)
    if not spellName then
        return nil
    end

    return {
        spellID = spellID,
        spellName = spellName,
        iconID = C_Spell.GetSpellTexture(spellID),
        isKnown = C_SpellBook.IsSpellKnown(spellID) == true,
    }
end

local function IsAssignableSpell(spellID)
    if not spellID then
        return false
    end

    local slotIndex, spellBank = C_SpellBook.FindSpellBookSlotForSpell(
        spellID,
        false,
        false,
        false,
        false
    )
    if not slotIndex or spellBank ~= PLAYER_SPELL_BANK then
        return false
    end

    if C_SpellBook.IsSpellBookItemPassive(slotIndex, spellBank) then
        return false
    end

    return C_SpellBook.IsSpellBookItemHelpful(slotIndex, spellBank) == true
end

local function GetProfile(addonObject, defaultDispels)
    return addonObject.currentActionProfile or addonObject:GetCurrentActionProfile(defaultDispels)
end

function addon:GetConfiguredSpells(defaultDispels)
    local profile = self:GetCurrentActionProfile(defaultDispels)
    local spells = {}

    for clickIndex = 1, 3 do
        local spellID = profile.clickSpells[clickIndex]
        local entry = BuildSpellEntry(spellID)
        if entry and entry.isKnown and IsAssignableSpell(spellID) then
            spells[clickIndex] = entry
        elseif spellID then
            -- Remove stale selections that are no longer valid click actions,
            -- including ground-target abilities saved by earlier alpha builds.
            profile.clickSpells[clickIndex] = nil
            profile.cooldownBars[clickIndex] = false
        end
    end

    return spells
end

function addon:GetConfiguredSpellForDisplay(clickIndex, defaultDispels)
    local profile = GetProfile(self, defaultDispels)
    local spellID = profile.clickSpells[clickIndex]
    if not IsAssignableSpell(spellID) then
        return nil
    end
    return BuildSpellEntry(spellID)
end

function addon:SetConfiguredSpell(clickIndex, spellID)
    if InCombatLockdown() then
        self:Print(L.ACTION_COMBAT or L.DISPLAY_COMBAT)
        return false
    end

    if clickIndex < 1 or clickIndex > 3 then
        return false
    end

    if spellID == 0 then
        spellID = nil
    elseif not IsAssignableSpell(spellID) then
        return false
    end

    local profile = self:GetCurrentActionProfile(self.activeDispels or self:DetectDispelSpells())
    profile.clickSpells[clickIndex] = spellID
    self:RefreshDispelConfiguration()
    return true
end

function addon:IsCooldownBarEnabled(clickIndex)
    local profile = GetProfile(self, self.activeDispels)
    return profile.cooldownBars[clickIndex] == true
end

function addon:SetCooldownBarEnabled(clickIndex, enabled)
    if InCombatLockdown() then
        self:Print(L.ACTION_COMBAT or L.DISPLAY_COMBAT)
        return false
    end

    if clickIndex < 1 or clickIndex > 3 then
        return false
    end

    local profile = self:GetCurrentActionProfile(self.activeDispels or self:DetectDispelSpells())
    profile.cooldownBars[clickIndex] = enabled == true
    self:ApplyDisplaySettings()
    if self.RefreshCooldownBars then
        self:RefreshCooldownBars()
    end
    return true
end

function addon:GetAssignableSpells()
    local spells = {}
    local seen = {}
    local numSkillLines = C_SpellBook.GetNumSpellBookSkillLines()

    for skillLineIndex = 1, numSkillLines do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
        if skillLineInfo
            and not skillLineInfo.shouldHide
            and not skillLineInfo.offSpecID
            and skillLineInfo.itemIndexOffset
            and skillLineInfo.numSpellBookItems
        then
            for itemOffset = 1, skillLineInfo.numSpellBookItems do
                local slotIndex = skillLineInfo.itemIndexOffset + itemOffset
                local itemType, _, spellID = C_SpellBook.GetSpellBookItemType(slotIndex, PLAYER_SPELL_BANK)
                if itemType == Enum.SpellBookItemType.Spell
                    and spellID
                    and not seen[spellID]
                    and not C_SpellBook.IsSpellBookItemPassive(slotIndex, PLAYER_SPELL_BANK)
                    and C_SpellBook.IsSpellBookItemHelpful(slotIndex, PLAYER_SPELL_BANK)
                then
                    -- Only spells Blizzard classifies as helpful are offered.
                    -- This keeps unit-target dispels and friendly utility while
                    -- excluding offensive actions, auto attack, and ground-target
                    -- abilities that would open a placement reticle.
                    local entry = BuildSpellEntry(spellID)
                    if entry and entry.isKnown then
                        seen[spellID] = true
                        spells[#spells + 1] = entry
                    end
                end
            end
        end
    end

    table.sort(spells, function(a, b)
        if a.spellName == b.spellName then
            return a.spellID < b.spellID
        end
        return a.spellName < b.spellName
    end)

    return spells
end
