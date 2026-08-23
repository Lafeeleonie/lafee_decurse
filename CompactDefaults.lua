local _, addon = ...

local COOLDOWN_TITLE_GAP = 21

local function ApplyCompactDefaults(profile)
    if type(profile) ~= "table" then
        return
    end

    -- Only fill missing values. Existing character/spec profiles keep every
    -- explicit choice the player has already made.
    if profile.showNames == nil then
        profile.showNames = false
    end
    if profile.showAuras == nil then
        profile.showAuras = false
    end
    if profile.auraGlow == nil then
        profile.auraGlow = true
    end
    if profile.useClassColors == nil then
        profile.useClassColors = true
    end

    -- Preserve legacy showBackground migrations when that key still exists.
    -- Truly new profiles start with backgrounds on the unit frames only.
    if profile.backgroundMode == nil and profile.showBackground == nil then
        profile.backgroundMode = addon.BACKGROUND_MODE_FRAMES
    end
end

local BaseActivateCurrentProfile = addon.ActivateCurrentProfile
function addon:ActivateCurrentProfile(...)
    local profile = BaseActivateCurrentProfile(self, ...)
    ApplyCompactDefaults(profile)
    return profile
end

local BaseInitializeProfileStorage = addon.InitializeProfileStorage
function addon:InitializeProfileStorage(...)
    local profile = BaseInitializeProfileStorage(self, ...)
    ApplyCompactDefaults(profile)
    return profile
end

local BaseGetCurrentActionProfile = addon.GetCurrentActionProfile
function addon:GetCurrentActionProfile(defaultDispels)
    local profile = self:GetCurrentProfile() or self:ActivateCurrentProfile()

    if profile and profile.clickActionsInitialized ~= true then
        -- New profiles start with the primary detected dispel on left click.
        -- Right and middle click remain empty until the player assigns them.
        profile.clickSpells = {}
        profile.cooldownBars = {}
        local primaryDispel = defaultDispels and defaultDispels[1]
        profile.clickSpells[1] = primaryDispel and primaryDispel.spellID or nil
        for clickIndex = 1, 3 do
            profile.cooldownBars[clickIndex] = false
        end
        profile.clickActionsInitialized = true
        self.currentActionProfile = profile
        return profile
    end

    return BaseGetCurrentActionProfile(self, defaultDispels)
end

local function HasVisibleCooldownBar(addonObject)
    if not addonObject.GetConfiguredSpellForDisplay or not addonObject.IsCooldownBarEnabled then
        return false
    end

    for clickIndex = 1, 3 do
        local spell = addonObject:GetConfiguredSpellForDisplay(clickIndex, addonObject.activeDispels)
        if spell and spell.isKnown and addonObject:IsCooldownBarEnabled(clickIndex) then
            return true
        end
    end
    return false
end

local BaseApplyDisplaySettings = addon.ApplyDisplaySettings
function addon:ApplyDisplaySettings(...)
    local applied = BaseApplyDisplaySettings(self, ...)
    if applied ~= true or InCombatLockdown() then
        return applied
    end

    local db = self.db
    if not db
        or db.horizontal ~= true
        or db.showTitle == false
        or self:GetAuraGrowth() ~= "DOWN"
        or not HasVisibleCooldownBar(self)
    then
        return applied
    end

    -- Horizontal cooldown bars grow above the first row when auras grow down.
    -- Reserve their 16 px height plus the existing 5 px gap so they no longer
    -- occupy the same strip as the addon title.
    for _, button in ipairs(self.unitButtons or {}) do
        local point, relativeTo, relativePoint, x, y = button:GetPoint(1)
        if point then
            button:ClearAllPoints()
            button:SetPoint(point, relativeTo, relativePoint, x or 0, (y or 0) - COOLDOWN_TITLE_GAP)
        end
    end

    if self.mainFrame then
        self.mainFrame:SetHeight(self.mainFrame:GetHeight() + COOLDOWN_TITLE_GAP)
    end

    return applied
end
