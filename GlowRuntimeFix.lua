local _, addon = ...
local L = addon.L

local AURA_FILTER = "HARMFUL|RAID_PLAYER_DISPELLABLE"
local GLOW_SLOT_KEY = "dispellable-glow"
local MAX_HORIZONTAL_ANTS = 24
local MAX_VERTICAL_ANTS = 8
local rebuildSerial = 0

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function CreateColoredTexture(parent)
    return parent:CreateTexture(nil, "OVERLAY")
end

local function CreateAntTextureSet(parent, horizontalCount, verticalCount)
    local set = {
        top = {},
        bottom = {},
        left = {},
        right = {},
    }

    for index = 1, horizontalCount do
        set.top[index] = CreateColoredTexture(parent)
        set.bottom[index] = CreateColoredTexture(parent)
    end
    for index = 1, verticalCount do
        set.left[index] = CreateColoredTexture(parent)
        set.right[index] = CreateColoredTexture(parent)
    end

    return set
end

local function CreateAlphaAnimation(frame, fromAlpha, toAlpha)
    local group = frame:CreateAnimationGroup()
    group:SetLooping("BOUNCE")
    local alpha = group:CreateAnimation("Alpha")
    alpha:SetFromAlpha(fromAlpha)
    alpha:SetToAlpha(toAlpha)
    alpha:SetDuration(addon.DEFAULT_AURA_GLOW_SPEED)
    alpha:SetSmoothing("IN_OUT")
    return group, alpha
end

local function SetTextureSetColor(set, r, g, b)
    for _, side in pairs(set) do
        for _, texture in ipairs(side) do
            texture:SetColorTexture(r, g, b, 1)
        end
    end
end

local function LayoutAntSide(textures, parent, side, edgeLength, dashLength, thickness, startOffset)
    for index, texture in ipairs(textures) do
        local offset = startOffset + ((index - 1) * dashLength * 2)
        local visible = offset < edgeLength
        texture:SetShown(visible)
        if visible then
            local length = math.min(dashLength, edgeLength - offset)
            texture:ClearAllPoints()
            if side == "TOP" then
                texture:SetPoint("TOPLEFT", parent, "TOPLEFT", offset, 0)
                texture:SetSize(length, thickness)
            elseif side == "BOTTOM" then
                texture:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", offset, 0)
                texture:SetSize(length, thickness)
            elseif side == "LEFT" then
                texture:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -offset)
                texture:SetSize(thickness, length)
            else
                texture:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -offset)
                texture:SetSize(thickness, length)
            end
        end
    end
end

local function LayoutAntSet(set, parent, width, height, dashLength, thickness, startOffset)
    LayoutAntSide(set.top, parent, "TOP", width, dashLength, thickness, startOffset)
    LayoutAntSide(set.bottom, parent, "BOTTOM", width, dashLength, thickness, startOffset)
    LayoutAntSide(set.left, parent, "LEFT", height, dashLength, thickness, startOffset)
    LayoutAntSide(set.right, parent, "RIGHT", height, dashLength, thickness, startOffset)
end

local function ApplyGlowVisualSettings(glow)
    if not glow or not glow.GlowParent then return end

    local style = addon:GetAuraGlowStyle()
    local color = addon:GetAuraGlowColor()
    local speed = addon:GetAuraGlowSpeed()
    local thickness = addon:GetAuraGlowThickness()
    local padding = thickness + 1

    glow:ClearAllPoints()
    glow:SetPoint("TOPLEFT", glow.GlowParent, "TOPLEFT", -padding, padding)
    glow:SetPoint("BOTTOMRIGHT", glow.GlowParent, "BOTTOMRIGHT", padding, -padding)

    for _, texture in pairs(glow.SolidEdges) do
        texture:SetColorTexture(color.r, color.g, color.b, 1)
    end
    glow.SolidEdges.top:SetHeight(thickness)
    glow.SolidEdges.bottom:SetHeight(thickness)
    glow.SolidEdges.left:SetWidth(thickness)
    glow.SolidEdges.right:SetWidth(thickness)

    SetTextureSetColor(glow.AntSetA, color.r, color.g, color.b)
    SetTextureSetColor(glow.AntSetB, color.r, color.g, color.b)

    local width = math.max(1, glow:GetWidth())
    local height = math.max(1, glow:GetHeight())
    local dashLength = math.max(3, thickness * 3)
    LayoutAntSet(glow.AntSetA, glow.AntFrameA, width, height, dashLength, thickness, 0)
    LayoutAntSet(glow.AntSetB, glow.AntFrameB, width, height, dashLength, thickness, dashLength)

    glow.PulseAlpha:SetDuration(speed)
    glow.AntAlphaA:SetDuration(speed)
    glow.AntAlphaB:SetDuration(speed)

    glow.PulseAnimation:Stop()
    glow.AntAnimationA:Stop()
    glow.AntAnimationB:Stop()

    if style == addon.GLOW_STYLE_ANTS then
        glow.SolidFrame:Hide()
        glow.AntFrameA:Show()
        glow.AntFrameB:Show()
        glow.AntFrameA:SetAlpha(1)
        glow.AntFrameB:SetAlpha(0.15)
        glow.AntAnimationA:Play()
        glow.AntAnimationB:Play()
    elseif style == addon.GLOW_STYLE_SOLID then
        glow.AntFrameA:Hide()
        glow.AntFrameB:Hide()
        glow.SolidFrame:Show()
        glow.SolidFrame:SetAlpha(1)
    else
        glow.AntFrameA:Hide()
        glow.AntFrameB:Hide()
        glow.SolidFrame:Show()
        glow.SolidFrame:SetAlpha(0.30)
        glow.PulseAnimation:Play()
    end
end

local function CreateManagedGlowVisual(parent)
    local glow = CreateFrame("Frame", nil, parent)
    glow.GlowParent = parent
    glow:EnableMouse(false)

    local solid = CreateFrame("Frame", nil, glow)
    solid:SetAllPoints()
    glow.SolidFrame = solid

    local top = CreateColoredTexture(solid)
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    local bottom = CreateColoredTexture(solid)
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    local left = CreateColoredTexture(solid)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    local right = CreateColoredTexture(solid)
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")

    glow.SolidEdges = {
        top = top,
        bottom = bottom,
        left = left,
        right = right,
    }

    glow.PulseAnimation, glow.PulseAlpha = CreateAlphaAnimation(solid, 0.30, 1.00)

    local antA = CreateFrame("Frame", nil, glow)
    antA:SetAllPoints()
    local antB = CreateFrame("Frame", nil, glow)
    antB:SetAllPoints()
    glow.AntFrameA = antA
    glow.AntFrameB = antB
    glow.AntSetA = CreateAntTextureSet(antA, MAX_HORIZONTAL_ANTS, MAX_VERTICAL_ANTS)
    glow.AntSetB = CreateAntTextureSet(antB, MAX_HORIZONTAL_ANTS, MAX_VERTICAL_ANTS)
    glow.AntAnimationA, glow.AntAlphaA = CreateAlphaAnimation(antA, 1.00, 0.15)
    glow.AntAnimationB, glow.AntAlphaB = CreateAlphaAnimation(antB, 0.15, 1.00)

    ApplyGlowVisualSettings(glow)
    return glow
end

local function InitializeManagedGlowAuraButton(auraButton)
    -- Blizzard can mark this managed aura button (and its descendants) forbidden
    -- after initialization. Configure the complete visual only in this callback.
    auraButton:SetAllPoints()
    auraButton:EnableMouse(false)
    auraButton.GlowFrame = CreateManagedGlowVisual(auraButton)
end

local function CreateManagedGlowContainer(button, dispelTypes)
    local container = CreateFrame("AuraContainer", nil, button, "CustomAuraContainerTemplate")
    container:SetAllPoints(button)
    container:SetUnit(button.fixedUnit)
    container:AddAuraSlot(GLOW_SLOT_KEY, AURA_FILTER, {
        initializeFrame = InitializeManagedGlowAuraButton,
        candidateFilters = {
            includeDispelTypes = dispelTypes or {},
        },
        sortMethod = AuraContainerSortMethod.Expiration,
        sortDirection = AuraContainerSortDirection.Normal,
    })
    container:SetEnabled(true)
    container:Show()
    return container
end

local function ApplyTestGlowSettings()
    -- TestAuraGlow lives directly under our secure unit button, not under a
    -- managed AuraButton, so it remains safe to restyle while out of combat.
    for _, button in ipairs(addon.unitButtons or {}) do
        if button.TestAuraGlow then
            ApplyGlowVisualSettings(button.TestAuraGlow)
        end
    end
end

function addon:RebuildManagedAuraGlowContainers()
    if InCombatLockdown() then
        self.pendingGlowRebuild = true
        return false
    end

    local dispelTypes = self.GetCombinedDispelTypes
        and self:GetCombinedDispelTypes(self.activeDispels or {})
        or {}

    -- Do not inspect or touch managed AuraButtons. Disable their containers and
    -- build fresh slots so Blizzard runs initializeFrame again with current style.
    for _, container in ipairs(self.glowAuraContainers or {}) do
        container:SetEnabled(false)
        container:Hide()
    end

    self.glowAuraContainers = {}
    for index, button in ipairs(self.unitButtons or {}) do
        self.glowAuraContainers[index] = CreateManagedGlowContainer(button, dispelTypes)
    end

    self.pendingGlowRebuild = nil
    if self.ApplyAuraVisibility then
        self:ApplyAuraVisibility()
    end
    return true
end

function addon:RequestManagedAuraGlowRebuild(delay)
    rebuildSerial = rebuildSerial + 1
    local serial = rebuildSerial

    local function Rebuild()
        if serial ~= rebuildSerial then return end
        if InCombatLockdown() then
            addon.pendingGlowRebuild = true
            return
        end
        addon:RebuildManagedAuraGlowContainers()
    end

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(math.max(0, tonumber(delay) or 0), Rebuild)
    else
        Rebuild()
    end
end

-- AuraDisplay.lua originally restyled every glow in addon.glowVisuals. That list
-- also contains descendants of managed AuraButtons, which may already be forbidden.
-- Only the harmless test visuals are changed in place; live managed visuals are
-- refreshed by rebuilding their container from user configuration alone.
function addon:ApplyAuraGlowSettings()
    if InCombatLockdown() then
        self.pendingGlowRebuild = true
        return false
    end
    ApplyTestGlowSettings()
    return true
end

function addon:SetAuraGlowStyle(style)
    if InCombatLockdown() then
        self:Print(L.DISPLAY_COMBAT)
        return false
    end
    if style ~= self.GLOW_STYLE_PULSE and style ~= self.GLOW_STYLE_ANTS and style ~= self.GLOW_STYLE_SOLID then
        return false
    end

    LafeeDecurseDB.auraGlowStyle = style
    self:ApplyAuraGlowSettings()
    self:RequestManagedAuraGlowRebuild(0)
    self:RefreshConfigurationPanel()
    return true
end

function addon:SetAuraGlowColor(r, g, b)
    if InCombatLockdown() then
        self:Print(L.DISPLAY_COMBAT)
        return false
    end

    LafeeDecurseDB.auraGlowColor = {
        r = Clamp(tonumber(r) or self.DEFAULT_AURA_GLOW_COLOR.r, 0, 1),
        g = Clamp(tonumber(g) or self.DEFAULT_AURA_GLOW_COLOR.g, 0, 1),
        b = Clamp(tonumber(b) or self.DEFAULT_AURA_GLOW_COLOR.b, 0, 1),
    }
    self:ApplyAuraGlowSettings()
    self:RequestManagedAuraGlowRebuild(0)
    self:RefreshConfigurationPanel()
    return true
end

function addon:SetAuraGlowSpeed(speed)
    if InCombatLockdown() then
        self:Print(L.DISPLAY_COMBAT)
        return false
    end

    LafeeDecurseDB.auraGlowSpeed = Clamp(
        tonumber(speed) or self.DEFAULT_AURA_GLOW_SPEED,
        self.MIN_AURA_GLOW_SPEED,
        self.MAX_AURA_GLOW_SPEED
    )
    self:ApplyAuraGlowSettings()
    self:RequestManagedAuraGlowRebuild(0.15)
    self:RefreshConfigurationPanel()
    return true
end

function addon:SetAuraGlowThickness(thickness)
    if InCombatLockdown() then
        self:Print(L.DISPLAY_COMBAT)
        return false
    end

    thickness = math.floor((tonumber(thickness) or self.DEFAULT_AURA_GLOW_THICKNESS) + 0.5)
    LafeeDecurseDB.auraGlowThickness = Clamp(
        thickness,
        self.MIN_AURA_GLOW_THICKNESS,
        self.MAX_AURA_GLOW_THICKNESS
    )
    self:ApplyAuraGlowSettings()
    self:RequestManagedAuraGlowRebuild(0.15)
    self:RefreshConfigurationPanel()
    return true
end
