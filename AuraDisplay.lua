local addonName, addon = ...
local L = addon.L

addon.auraContainers = {}

local AURA_FILTER = "HARMFUL|RAID_PLAYER_DISPELLABLE"
local GROUP_KEY = "dispellable"
local MAX_AURAS = 3
local AURA_SIZE = 24
local AURA_SPACING = 2

local function GetGroupLayout()
    return {
        elementWidth = AURA_SIZE,
        elementHeight = AURA_SIZE,
        elementSpacing = AURA_SPACING,
        lineSpacing = AURA_SPACING,
        elementSpacingX = AURA_SPACING,
        elementSpacingY = AURA_SPACING,
    }
end

local function InitializeAuraButton(auraButton)
    -- Aura buttons can become forbidden while aura data is secret. Every
    -- region is therefore created and registered in this secure initializer.
    auraButton:SetSize(24, 24)
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
    local container = CreateFrame(
        "AuraContainer",
        "LafeeDecurseAuraContainer" .. index,
        button,
        "CustomAuraContainerTemplate"
    )
    container:SetSize((AURA_SIZE * MAX_AURAS) + (AURA_SPACING * (MAX_AURAS - 1)), AURA_SIZE)
    container:SetUnit(button.fixedUnit)

    container:AddAuraGroup(GROUP_KEY, AURA_FILTER, {
        initializeFrame = InitializeAuraButton,
        maxFrameCount = MAX_AURAS,
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

    local totalSize = (AURA_SIZE * MAX_AURAS) + (AURA_SPACING * (MAX_AURAS - 1))
    for index, container in ipairs(self.auraContainers) do
        local button = self.unitButtons[index]
        container:ClearAllPoints()
        if LafeeDecurseDB.horizontal then
            container:SetSize(AURA_SIZE, totalSize)
            container:SetPoint("TOP", button, "BOTTOM", 0, -3)
            container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
            container:SetFlowLayoutAnchorPoint("TOP")
        else
            container:SetSize(totalSize, AURA_SIZE)
            container:SetPoint("LEFT", button, "RIGHT", 3, 0)
            container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
            container:SetFlowLayoutAnchorPoint("LEFT")
        end
        container:SetFlowLayoutGrowthDirection(
            AnchorUtil.FlowDirection.Right,
            AnchorUtil.FlowDirection.Down
        )
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
