local addonName, addon = ...
local L = addon.L

addon.auraContainers = {}

local AURA_FILTER = "HARMFUL|RAID_PLAYER_DISPELLABLE"
local GROUP_KEY = "dispellable"
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
    -- region is therefore created and registered in this secure initializer.
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
    end

    self:UpdateAuraDisplayLayout()

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

    return true
end
