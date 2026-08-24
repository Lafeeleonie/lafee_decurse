local addonName, addon = ...
local L = addon.L

addon.auraContainers = {}
addon.glowAuraContainers = {}
addon.glowVisuals = {}

addon.GLOW_STYLE_PULSE = "PULSE"
addon.GLOW_STYLE_ANTS = "ANTS"
addon.GLOW_STYLE_SOLID = "SOLID"
addon.DEFAULT_AURA_GLOW_COLOR = { r = 0.55, g = 0.90, b = 1.00 }
addon.DEFAULT_AURA_GLOW_SPEED = 0.45
addon.MIN_AURA_GLOW_SPEED = 0.20
addon.MAX_AURA_GLOW_SPEED = 1.50
addon.DEFAULT_AURA_GLOW_THICKNESS = 2
addon.MIN_AURA_GLOW_THICKNESS = 1
addon.MAX_AURA_GLOW_THICKNESS = 4

local AURA_FILTER = "HARMFUL|RAID"
local GROUP_KEY = "dispellable"
local GLOW_SLOT_KEY = "dispellable-glow"
local AURA_SPACING = 2
local MAX_HORIZONTAL_ANTS = 24
local MAX_VERTICAL_ANTS = 8

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function GetAuraSize()
    return addon.UNIT_BUTTON_HEIGHT or 30
end

local function GetAuraCount()
    return addon:GetAuraCount()
end

function addon:GetAuraGlowStyle()
    local style = LafeeDecurseDB and LafeeDecurseDB.auraGlowStyle
    if style == self.GLOW_STYLE_ANTS or style == self.GLOW_STYLE_SOLID then
        return style
    end
    return self.GLOW_STYLE_PULSE
end

function addon:GetAuraGlowColor()
    local default = self.DEFAULT_AURA_GLOW_COLOR
    local color = LafeeDecurseDB and LafeeDecurseDB.auraGlowColor or nil
    return {
        r = Clamp(tonumber(color and color.r) or default.r, 0, 1),
        g = Clamp(tonumber(color and color.g) or default.g, 0, 1),
        b = Clamp(tonumber(color and color.b) or default.b, 0, 1),
    }
end

function addon:GetAuraGlowSpeed()
    local speed = tonumber(LafeeDecurseDB and LafeeDecurseDB.auraGlowSpeed)
        or self.DEFAULT_AURA_GLOW_SPEED
    return Clamp(speed, self.MIN_AURA_GLOW_SPEED, self.MAX_AURA_GLOW_SPEED)
end

function addon:GetAuraGlowThickness()
    local thickness = tonumber(LafeeDecurseDB and LafeeDecurseDB.auraGlowThickness)
        or self.DEFAULT_AURA_GLOW_THICKNESS
    thickness = math.floor(thickness + 0.5)
    return Clamp(thickness, self.MIN_AURA_GLOW_THICKNESS, self.MAX_AURA_GLOW_THICKNESS)
end

local function GetGroupLayout()
    local size = GetAuraSize()
    return {
        elementWidth = size,
        elementHeight = size,
        elementSpacing = AURA_SPACING,
        lineSpacing = AURA_SPACING,
        elementSpacingX = AURA_SPACING,
        elementSpacingY = AURA_SPACING,
    }
end

local function InitializeAuraButton(auraButton)
    -- Aura buttons can become forbidden while aura data is secret. Every
    -- region is therefore created and registered in this initializer.
    local size = GetAuraSize()
    auraButton:SetSize(size, size)
    auraButton:EnableMouse(false)

    local icon = auraButton:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    auraButton:SetIcon(icon)

    local cooldown = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(false)
    cooldown:SetHideCountdownNumbers(false)
    auraButton:SetDurationCooldown(cooldown)

    local border = auraButton:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    auraButton:SetAuraBorder(border, {
        showWhenHarmful = true,
        showWhenHelpful = false,
        style = Enum.CustomAuraButtonDispelTypeTextureStyle.Border,
    })
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

local function CreateGlowVisual(parent)
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

    addon.glowVisuals[#addon.glowVisuals + 1] = glow
    ApplyGlowVisualSettings(glow)
    return glow
end

function addon:ApplyAuraGlowSettings()
    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        return false
    end

    for _, glow in ipairs(self.glowVisuals or {}) do
        ApplyGlowVisualSettings(glow)
    end
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
    self:RefreshConfigurationPanel()
    return true
end

local function InitializeGlowAuraButton(auraButton)
    -- This frame is shown and hidden only by Blizzard's managed aura-slot
    -- assignment. Lua never queries its visibility or aura contents.
    auraButton:SetAllPoints()
    auraButton:EnableMouse(false)

    local glow = CreateGlowVisual(auraButton)
    auraButton.GlowFrame = glow
end

local function CreateAuraContainer(button, index)
    local size = GetAuraSize()
    local maxAuras = GetAuraCount()
    local container = CreateFrame(
        "AuraContainer",
        "LafeeDecurseAuraContainer" .. index,
        button,
        "CustomAuraContainerTemplate"
    )
    container:SetSize((size * maxAuras) + (AURA_SPACING * (maxAuras - 1)), size)
    container:SetUnit(button.fixedUnit)

    container:AddAuraGroup(GROUP_KEY, AURA_FILTER, {
        initializeFrame = InitializeAuraButton,
        maxFrameCount = maxAuras,
        sortMethod = AuraContainerSortMethod.Expiration,
        sortDirection = AuraContainerSortDirection.Normal,
        layout = GetGroupLayout(),
    })
    container:SetEnabled(true)
    container:Show()
    return container
end

local function CreateGlowAuraContainer(button, index)
    local container = CreateFrame(
        "AuraContainer",
        "LafeeDecurseGlowAuraContainer" .. index,
        button,
        "CustomAuraContainerTemplate"
    )
    container:SetAllPoints(button)
    container:SetUnit(button.fixedUnit)

    container:AddAuraSlot(GLOW_SLOT_KEY, AURA_FILTER, {
        initializeFrame = InitializeGlowAuraButton,
        sortMethod = AuraContainerSortMethod.Expiration,
        sortDirection = AuraContainerSortDirection.Normal,
    })
    container:SetEnabled(true)
    container:Show()
    return container
end

function addon:ApplyAuraVisibility()
    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        return false
    end

    local showAuraIcons = LafeeDecurseDB.showAuras ~= false and not self.testMode
    local glowEnabled = LafeeDecurseDB.auraGlow ~= false
    local showGlow = glowEnabled and not self.testMode
    local showTestGlow = glowEnabled and self.testMode

    for _, container in ipairs(self.auraContainers or {}) do
        container:SetEnabled(showAuraIcons)
        container:SetShown(showAuraIcons)
    end

    for _, container in ipairs(self.glowAuraContainers or {}) do
        container:SetEnabled(showGlow)
        container:SetShown(showGlow)
    end

    -- Test glow is a purely visual simulation driven only by test mode and the
    -- user's glow setting. It never mirrors or inspects managed aura state.
    for _, button in ipairs(self.unitButtons or {}) do
        if button.TestAuraGlow then
            button.TestAuraGlow:SetShown(showTestGlow)
        end
    end

    return true
end

function addon:SetAuraIconsVisible(visible)
    if InCombatLockdown() then
        self:Print(L.DISPLAY_COMBAT)
        return false
    end

    LafeeDecurseDB.showAuras = visible == true
    self:ApplyAuraVisibility()
    self:ApplyDisplaySettings()
    return true
end

function addon:SetAuraGlowEnabled(enabled)
    if InCombatLockdown() then
        self:Print(L.DISPLAY_COMBAT)
        return false
    end

    LafeeDecurseDB.auraGlow = enabled == true
    self:ApplyAuraVisibility()
    self:RefreshConfigurationPanel()
    return true
end

function addon:UpdateAuraDisplayLayout()
    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        return false
    end

    local size = GetAuraSize()
    local count = GetAuraCount()
    local totalSize = (size * count) + (AURA_SPACING * (count - 1))
    local growth = self:GetAuraGrowth()

    for index, container in ipairs(self.auraContainers) do
        local button = self.unitButtons[index]
        container:ClearAllPoints()
        container:SetAuraGroupMaxFrameCount(GROUP_KEY, count)

        if LafeeDecurseDB.horizontal then
            container:SetSize(size, totalSize)
            container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
            if growth == "UP" then
                container:SetPoint("BOTTOM", button, "TOP", 0, 3)
                container:SetFlowLayoutAnchorPoint("BOTTOM")
                container:SetFlowLayoutGrowthDirection(
                    AnchorUtil.FlowDirection.Right,
                    AnchorUtil.FlowDirection.Up
                )
            else
                container:SetPoint("TOP", button, "BOTTOM", 0, -3)
                container:SetFlowLayoutAnchorPoint("TOP")
                container:SetFlowLayoutGrowthDirection(
                    AnchorUtil.FlowDirection.Right,
                    AnchorUtil.FlowDirection.Down
                )
            end
        else
            container:SetSize(totalSize, size)
            container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
            if growth == "LEFT" then
                container:SetPoint("RIGHT", button, "LEFT", -3, 0)
                container:SetFlowLayoutAnchorPoint("RIGHT")
                container:SetFlowLayoutGrowthDirection(
                    AnchorUtil.FlowDirection.Left,
                    AnchorUtil.FlowDirection.Down
                )
            else
                container:SetPoint("LEFT", button, "RIGHT", 3, 0)
                container:SetFlowLayoutAnchorPoint("LEFT")
                container:SetFlowLayoutGrowthDirection(
                    AnchorUtil.FlowDirection.Right,
                    AnchorUtil.FlowDirection.Down
                )
            end
        end

        container:SetAuraGroupLayout(GROUP_KEY, GetGroupLayout())
    end
    return true
end

function addon:CreateAuraDisplays()
    if InCombatLockdown() then
        self.pendingInitialization = true
        return false
    end

    if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        local loaded, reason = C_AddOns.LoadAddOn("Blizzard_AuraContainer")
        if not loaded then
            self:Print(string.format(L.AURA_CONTAINER_FAILED, tostring(reason)))
            return false
        end
    end

    for index, button in ipairs(self.unitButtons) do
        self.auraContainers[index] = CreateAuraContainer(button, index)
        self.glowAuraContainers[index] = CreateGlowAuraContainer(button, index)

        -- Managed glow is disabled during visual test mode, so each fixed unit
        -- also gets a harmless visual-only copy for /ldec test.
        if not button.TestAuraGlow then
            button.TestAuraGlow = CreateGlowVisual(button)
            button.TestAuraGlow:Hide()
        end
    end

    self:UpdateAuraDisplayLayout()
    self:ApplyAuraGlowSettings()
    self:ApplyAuraVisibility()
    if self.CaptureManagedAuraGlowSettings then
        self:CaptureManagedAuraGlowSettings()
    end

    return true
end

function addon:RefreshAuraDispelDisplay()
    if InCombatLockdown() then
        self.pendingDispelRefresh = true
        return false
    end

    for _, container in ipairs(self.auraContainers) do
        -- HARMFUL|RAID is evaluated by Blizzard against the current player's
        -- dispel capabilities. Refresh after spell or talent changes without
        -- exposing active aura data to addon Lua.
        container:UpdateAllAuras()
    end

    for _, container in ipairs(self.glowAuraContainers) do
        container:UpdateAllAuras()
    end

    return true
end
