local _, addon = ...

local function GetProfile()
    return addon.db or LafeeDecurseDB
end

local function RefreshSettingsPanel()
    if addon.RefreshConfigurationPanel then
        addon:RefreshConfigurationPanel()
    end
end

-- These two settings are profile values first and protected AuraContainer changes
-- second. Persist the requested value immediately, then defer only the protected
-- visual update when combat lockdown prevents us from touching the containers.
function addon:SetAuraIconsVisible(visible)
    local profile = GetProfile()
    if not profile then
        return false
    end

    profile.showAuras = visible == true

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
