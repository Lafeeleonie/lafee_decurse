local _, addon = ...

local COOLDOWN_TITLE_GAP = 21
local DEATH_ICON_TEXTURE = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"

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

local function UpdateDeathIndicator(button)
    if not button or not button.DeathIcon or not button.fixedUnit then
        return
    end

    button.DeathIcon:SetShown(UnitIsDeadOrGhost(button.fixedUnit) == true)
end

local function UpdateAllDeathIndicators()
    for _, button in ipairs(addon.unitButtons or {}) do
        UpdateDeathIndicator(button)
    end
end

local BaseCreateSecureUnitButtons = addon.CreateSecureUnitButtons
function addon:CreateSecureUnitButtons(parent)
    local created = BaseCreateSecureUnitButtons(self, parent)
    if created ~= true then
        return created
    end

    for _, button in ipairs(self.unitButtons or {}) do
        if not button.DeathIcon then
            local deathIcon = button:CreateTexture(nil, "OVERLAY", nil, 7)
            deathIcon:SetTexture(DEATH_ICON_TEXTURE)
            deathIcon:SetSize(18, 18)
            deathIcon:SetPoint("CENTER", button, "CENTER", 0, 0)
            deathIcon:Hide()
            button.DeathIcon = deathIcon
        end
        UpdateDeathIndicator(button)
    end

    return created
end

local deathEventFrame = CreateFrame("Frame")
deathEventFrame:RegisterEvent("UNIT_HEALTH")
deathEventFrame:RegisterEvent("UNIT_FLAGS")
deathEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
deathEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
deathEventFrame:RegisterEvent("PLAYER_DEAD")
deathEventFrame:RegisterEvent("PLAYER_ALIVE")
deathEventFrame:RegisterEvent("PLAYER_UNGHOSTED")
deathEventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_HEALTH" or event == "UNIT_FLAGS" then
        for _, button in ipairs(addon.unitButtons or {}) do
            if button.fixedUnit == unit then
                UpdateDeathIndicator(button)
                return
            end
        end
        return
    end

    UpdateAllDeathIndicators()
end)

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
