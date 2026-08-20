local _, addon = ...

local function GetProfile()
    return addon.db or LafeeDecurseDB
end

local function ClearRootShadow(key)
    local root = addon.dbRoot or LafeeDecurseDB
    if type(root) == "table" and rawget(root, key) ~= nil then
        rawset(root, key, nil)
    end
end

local function RefreshSettingsPanel()
    if addon.RefreshConfigurationPanel then
        addon:RefreshConfigurationPanel()
    end
end

-- These two settings are profile values first and protected AuraContainer changes
-- second. Persist the requested value immediately, then defer only the protected
-- visual update when combat lockdown prevents us from touching the containers.
--
-- Older alpha builds could leave raw top-level SavedVariables behind. A raw root
-- key bypasses the profile compatibility proxy and would therefore immediately
-- make the checkbox appear enabled again even though the active profile contains
-- false. Clear that shadow whenever either setting changes.
function addon:SetAuraIconsVisible(visible)
    local profile = GetProfile()
    if not profile then
        return false
    end

    profile.showAuras = visible == true
    ClearRootShadow("showAuras")

    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        RefreshSettingsPanel()
        return true
    end

    if self.ApplyAuraVisibility then
        self:ApplyAuraVisibility()
    end
    if self.ApplyDisplaySettings then
        self:ApplyDisplaySettings()
    else
        RefreshSettingsPanel()
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
        RefreshSettingsPanel()
        return true
    end

    if self.ApplyAuraVisibility then
        self:ApplyAuraVisibility()
    end
    RefreshSettingsPanel()
    return true
end
