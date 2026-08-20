local _, addon = ...

local function GetProfile()
    return addon.db
end

local function ClearRootShadow(key)
    local root = addon.dbRoot or LafeeDecurseDB
    if type(root) == "table" and rawget(root, key) ~= nil then
        rawset(root, key, nil)
    end
end

local function AuraIconsEnabled()
    local profile = GetProfile()
    return not profile or profile.showAuras ~= false
end

local function AuraGlowEnabled()
    local profile = GetProfile()
    return not profile or profile.auraGlow ~= false
end

local function ApplyTestVisibility()
    local showIcons = AuraIconsEnabled() and addon.testMode
    local showGlow = AuraGlowEnabled() and addon.testMode
    local count = addon.GetAuraCount and addon:GetAuraCount() or 3

    for _, button in ipairs(addon.unitButtons or {}) do
        for index, icon in ipairs(button.TestAuraIcons or {}) do
            icon:SetShown(showIcons and index <= count)
        end
        if button.TestAuraGlow then
            button.TestAuraGlow:SetShown(showGlow)
        end
    end
end

function addon:ApplyAuraVisibility()
    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        return false
    end

    local showAuraIcons = AuraIconsEnabled() and not self.testMode
    local showGlow = AuraGlowEnabled() and not self.testMode

    for _, container in ipairs(self.auraContainers or {}) do
        container:SetEnabled(showAuraIcons)
        container:SetShown(showAuraIcons)
    end

    for _, container in ipairs(self.glowAuraContainers or {}) do
        container:SetEnabled(showGlow)
        container:SetShown(showGlow)
    end

    ApplyTestVisibility()
    return true
end

function addon:SetAuraIconsVisible(visible)
    local profile = GetProfile()
    if not profile then
        return false
    end

    profile.showAuras = visible == true
    ClearRootShadow("showAuras")

    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        self:RefreshConfigurationPanel()
        return true
    end

    self:ApplyAuraVisibility()
    if self.ApplyDisplaySettings then
        self:ApplyDisplaySettings()
    end
    return true
end

function addon:SetAuraGlowEnabled(enabled)
    local profile = GetProfile()
    if not profile then
        return false
    end

    profile.auraGlow = enabled == true
    ClearRootShadow("auraGlow")

    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        self:RefreshConfigurationPanel()
        return true
    end

    self:ApplyAuraVisibility()
    self:RefreshConfigurationPanel()
    return true
end

-- Load this file after Config/GlowConfig/GroupOrderConfig so the two checkbox
-- callbacks and final refresh wrapper always use the active profile directly.
local OriginalRefreshConfigurationPanel = addon.RefreshConfigurationPanel
function addon:RefreshConfigurationPanel()
    OriginalRefreshConfigurationPanel(self)

    local panel = self.configurationPanel
    local profile = GetProfile()
    if not panel or not profile then
        return
    end

    if panel.ShowAurasCheckbox then
        panel.ShowAurasCheckbox:SetChecked(profile.showAuras ~= false)
    end
    if panel.AuraGlowCheckbox then
        panel.AuraGlowCheckbox:SetChecked(profile.auraGlow ~= false)
    end
end

local OriginalCreateConfigurationPanel = addon.CreateConfigurationPanel
function addon:CreateConfigurationPanel()
    OriginalCreateConfigurationPanel(self)

    local panel = self.configurationPanel
    if not panel then
        return
    end

    if panel.ShowAurasCheckbox then
        panel.ShowAurasCheckbox:SetScript("OnClick", function()
            addon:SetAuraIconsVisible(not AuraIconsEnabled())
        end)
    end

    if panel.AuraGlowCheckbox then
        panel.AuraGlowCheckbox:SetScript("OnClick", function()
            addon:SetAuraGlowEnabled(not AuraGlowEnabled())
        end)
    end

    self:RefreshConfigurationPanel()
end
