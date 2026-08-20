local addonName, addon = ...
local L = addon.L

addon.auraContainers = {}
addon.glowAuraContainers = {}

local AURA_FILTER = "HARMFUL|RAID_PLAYER_DISPELLABLE"
local GROUP_KEY = "dispellable"
local GLOW_SLOT_KEY = "dispellable-glow"
local AURA_SPACING = 2

local function GetAuraSize()
    return addon.UNIT_BUTTON_HEIGHT or 30
end

local function GetAuraCount()
    return addon:GetAuraCount()
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

local function CreateGlowEdge(parent)
    local texture = parent:CreateTexture(nil, "OVERLAY")
    texture:SetColorTexture(0.55, 0.90, 1.00, 1)
    return texture
end

local function InitializeGlowAuraButton(auraButton)
    -- This frame is shown and hidden only by Blizzard's managed aura-slot
    -- assignment. Lua never queries its visibility or aura contents.
    auraButton:SetAllPoints()
    auraButton:EnableMouse(false)

    local glow = CreateFrame("Frame", nil, auraButton)
    glow:SetPoint("TOPLEFT", auraButton, "TOPLEFT", -3, 3)
    glow:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT", 3, -3)

    local top = CreateGlowEdge(glow)
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(2)

    local bottom = CreateGlowEdge(glow)
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetHeight(2)

    local left = CreateGlowEdge(glow)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(2)

    local right = CreateGlowEdge(glow)
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(2)

    glow:SetAlpha(0.30)
    local pulse = glow:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local alpha = pulse:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.30)
    alpha:SetToAlpha(1.00)
    alpha:SetDuration(0.45)
    alpha:SetSmoothing("IN")
    pulse:Play()

    auraButton.GlowFrame = glow
    auraButton.GlowAnimation = pulse
end

local function CreateAuraContainer(button, index, dispelTypes)
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
        candidateFilters = {
            includeDispelTypes = dispelTypes or {},
        },
        sortMethod = AuraContainerSortMethod.Expiration,
        sortDirection = AuraContainerSortDirection.Normal,
        layout = GetGroupLayout(),
    })
    container:SetEnabled(true)
    container:Show()
    return container
end

local function CreateGlowAuraContainer(button, index, dispelTypes)
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

function addon:ApplyAuraVisibility()
    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        return false
    end

    local showAuraIcons = LafeeDecurseDB.showAuras ~= false and not self.testMode
    local showGlow = LafeeDecurseDB.auraGlow ~= false and not self.testMode

    for _, container in ipairs(self.auraContainers or {}) do
        container:SetEnabled(showAuraIcons)
        container:SetShown(showAuraIcons)
    end

    for _, container in ipairs(self.glowAuraContainers or {}) do
        container:SetEnabled(showGlow)
        container:SetShown(showGlow)
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

function addon:CreateAuraDisplays(dispelTypes)
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
        self.auraContainers[index] = CreateAuraContainer(button, index, dispelTypes)
        self.glowAuraContainers[index] = CreateGlowAuraContainer(button, index, dispelTypes)
    end

    self:UpdateAuraDisplayLayout()
    self:ApplyAuraVisibility()

    return true
end

function addon:ApplyAuraDispelTypes(dispelTypes)
    if InCombatLockdown() then
        self.pendingDispelRefresh = true
        return false
    end

    for _, container in ipairs(self.auraContainers) do
        -- Blizzard evaluates the aura's dispel type inside its managed
        -- container. Addon Lua receives no active aura data.
        container:SetAuraGroupCandidateFilters(GROUP_KEY, {
            includeDispelTypes = dispelTypes or {},
        })
    end

    for _, container in ipairs(self.glowAuraContainers) do
        -- The glow slot is another Blizzard-managed view of the same filter.
        -- Its aura frame is shown/hidden by the container itself; addon Lua
        -- never inspects that state.
        container:SetAuraSlotCandidateFilters(GLOW_SLOT_KEY, {
            includeDispelTypes = dispelTypes or {},
        })
    end

    return true
end
