local addonName, addon = ...
local L = addon.L

addon.auraContainers = {}

local AURA_FILTER = "HARMFUL|RAID_PLAYER_DISPELLABLE"
local SLOT_KEY = "dispellable"

local function InitializeAuraButton(auraButton)
    -- Aura buttons can become forbidden while aura data is secret. Every
    -- region is therefore created and registered in this secure initializer.
    auraButton:SetSize(24, 24)
    auraButton:EnableMouse(false)
    auraButton:ClearAllPoints()
    auraButton:SetPoint("CENTER", auraButton:GetParent(), "CENTER")

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
    container:SetSize(24, 24)
    container:SetPoint("RIGHT", button, "RIGHT", -3, 0)
    container:SetUnit(button.fixedUnit)

    container:AddAuraSlot(SLOT_KEY, AURA_FILTER, {
        initializeFrame = InitializeAuraButton,
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
        container:SetAuraSlotCandidateFilters(SLOT_KEY, {
            includeDispelTypes = dispelTypes or {},
        })
    end

    return true
end
