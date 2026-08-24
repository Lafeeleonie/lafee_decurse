local _, addon = ...

local BUTTON_SIZE = addon.UNIT_BUTTON_HEIGHT or 30
local BUTTON_GAP = 2
local GROUP_GAP = 6
local MAX_RAID_MEMBERS = 40
local MAX_GROUPS = 8
local GROUP_NUMBER_WIDTH = 18
local GROUP_NUMBER_GAP = 4

addon.RAID_GROUP_NUMBER_LEFT = "LEFT"
addon.RAID_GROUP_NUMBER_RIGHT = "RIGHT"
addon.RAID_GROUP_NUMBER_NONE = "NONE"

local ROLE_ATLASES = {
    TANK = "roleicon-tiny-tank",
    HEALER = "roleicon-tiny-healer",
    DAMAGER = "roleicon-tiny-dps",
}

local ROLE_ORDER = {
    TANK = 1,
    HEALER = 2,
    DAMAGER = 3,
    NONE = 4,
}

addon.raidUnitButtons = addon.raidUnitButtons or {}
addon.raidGroupLabels = addon.raidGroupLabels or {}
addon.raidModeActive = false

function addon:GetRaidGroupNumberSide()
    local side = self.db and self.db.raidGroupNumberSide
    if side == self.RAID_GROUP_NUMBER_RIGHT then
        return self.RAID_GROUP_NUMBER_RIGHT
    elseif side == self.RAID_GROUP_NUMBER_NONE then
        return self.RAID_GROUP_NUMBER_NONE
    end
    return self.RAID_GROUP_NUMBER_LEFT
end

function addon:SetRaidGroupNumberSide(side)
    if InCombatLockdown() then
        self:Print(self.L.DISPLAY_COMBAT)
        return false
    end
    if side ~= self.RAID_GROUP_NUMBER_LEFT
        and side ~= self.RAID_GROUP_NUMBER_RIGHT
        and side ~= self.RAID_GROUP_NUMBER_NONE
    then
        return false
    end

    local profile = self.db or self:ActivateCurrentProfile()
    if not profile then
        return false
    end
    profile.raidGroupNumberSide = side
    return self:ApplyDisplaySettings()
end

local function CreateBorder(frame)
    local color = { 0.28, 0.30, 0.34, 1 }
    local thickness = 1

    local top = frame:CreateTexture(nil, "BORDER")
    top:SetColorTexture(unpack(color))
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(thickness)

    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetColorTexture(unpack(color))
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetHeight(thickness)

    local left = frame:CreateTexture(nil, "BORDER")
    left:SetColorTexture(unpack(color))
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(thickness)

    local right = frame:CreateTexture(nil, "BORDER")
    right:SetColorTexture(unpack(color))
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(thickness)
end

local function CreateRaidButton(parent, index)
    local unit = "raid" .. index
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:RegisterForClicks("AnyDown", "AnyUp")
    button:SetAttribute("unit", unit)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.07, 0.08, 0.10, 0.92)
    button.Background = background
    CreateBorder(button)

    local roleIcon = button:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(16, 16)
    roleIcon:SetPoint("CENTER")
    roleIcon:Hide()
    button.RoleIcon = roleIcon

    button.fixedUnit = unit
    button.raidIndex = index
    button:Hide()
    return button
end

local function CreateRaidButtons(parent)
    if addon.raidUnitButtons[1] then
        return
    end

    for index = 1, MAX_RAID_MEMBERS do
        addon.raidUnitButtons[index] = CreateRaidButton(parent, index)
    end

    for groupIndex = 1, MAX_GROUPS do
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetWidth(GROUP_NUMBER_WIDTH)
        label:SetJustifyH("CENTER")
        label:SetText(tostring(groupIndex))
        label:SetTextColor(0.55, 0.90, 1)
        label:Hide()
        addon.raidGroupLabels[groupIndex] = label
    end
end

local function ApplySpellsToRaidButtons(spells)
    for _, button in ipairs(addon.raidUnitButtons or {}) do
        for clickIndex = 1, 3 do
            local spell = spells and spells[clickIndex]
            if spell then
                button:SetAttribute("type" .. clickIndex, "spell")
                button:SetAttribute("spell" .. clickIndex, spell.spellID)
            else
                button:SetAttribute("type" .. clickIndex, nil)
                button:SetAttribute("spell" .. clickIndex, nil)
            end
        end
    end
end

local function UpdateRaidButtonVisual(button)
    local unit = button.fixedUnit
    local _, class = UnitClass(unit)
    local classColor = class and RAID_CLASS_COLORS[class]
    if classColor then
        button.Background:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.92)
    else
        button.Background:SetColorTexture(0.07, 0.08, 0.10, 0.92)
    end

    local role = UnitGroupRolesAssigned(unit)
    local atlas = ROLE_ATLASES[role]
    if atlas then
        button.RoleIcon:SetAtlas(atlas)
        button.RoleIcon:Show()
    else
        button.RoleIcon:Hide()
    end
end

local function GetRoleRank(button)
    return ROLE_ORDER[UnitGroupRolesAssigned(button.fixedUnit)] or ROLE_ORDER.NONE
end

local function BuildRaidGroups()
    local groups = {}
    for groupIndex = 1, MAX_GROUPS do
        groups[groupIndex] = {}
    end

    for index, button in ipairs(addon.raidUnitButtons or {}) do
        local name, _, subgroup = GetRaidRosterInfo(index)
        -- raid1..raid40 are permanent secure buttons, but only actual roster
        -- members participate in the visual layout. Empty secure slots stay
        -- hidden and therefore never create blank cells inside a subgroup row.
        if name and subgroup and groups[subgroup] and UnitExists(button.fixedUnit) then
            groups[subgroup][#groups[subgroup] + 1] = button
        end
    end

    for groupIndex = 1, MAX_GROUPS do
        table.sort(groups[groupIndex], function(a, b)
            local aRole = GetRoleRank(a)
            local bRole = GetRoleRank(b)
            if aRole ~= bRole then
                return aRole < bRole
            end
            return a.raidIndex < b.raidIndex
        end)
    end

    return groups
end

local function SetPartyButtonsShown(shown)
    for _, button in ipairs(addon.unitButtons or {}) do
        button:SetShown(shown)
    end
end

local function HideRaidButtons()
    for _, button in ipairs(addon.raidUnitButtons or {}) do
        button:Hide()
    end
    for _, label in ipairs(addon.raidGroupLabels or {}) do
        label:Hide()
    end
end

local function LayoutRaidButtons()
    local mainFrame = addon.mainFrame
    if not mainFrame then
        return
    end

    HideRaidButtons()
    local groups = BuildRaidGroups()
    local db = addon.db or {}
    local titleOffset = db.showTitle == false and 5 or 20
    local visibleRows = 0
    local maxVisibleMembers = 0
    local numberSide = addon:GetRaidGroupNumberSide()
    local numberInset = numberSide == addon.RAID_GROUP_NUMBER_NONE
        and 0
        or (GROUP_NUMBER_WIDTH + GROUP_NUMBER_GAP)
    local buttonsStartX = numberSide == addon.RAID_GROUP_NUMBER_LEFT and (5 + numberInset) or 5

    for groupIndex = 1, MAX_GROUPS do
        local group = groups[groupIndex]
        if #group > 0 then
            visibleRows = visibleRows + 1
            maxVisibleMembers = math.max(maxVisibleMembers, #group)
            local rowY = -titleOffset - ((visibleRows - 1) * (BUTTON_SIZE + GROUP_GAP))

            for position, button in ipairs(group) do
                UpdateRaidButtonVisual(button)
                button:ClearAllPoints()
                button:SetPoint(
                    "TOPLEFT",
                    mainFrame,
                    "TOPLEFT",
                    buttonsStartX + ((position - 1) * (BUTTON_SIZE + BUTTON_GAP)),
                    rowY
                )
                button:Show()
            end

            local label = addon.raidGroupLabels[groupIndex]
            if label and numberSide ~= addon.RAID_GROUP_NUMBER_NONE then
                label:ClearAllPoints()
                if numberSide == addon.RAID_GROUP_NUMBER_RIGHT then
                    label:SetPoint("LEFT", group[#group], "RIGHT", GROUP_NUMBER_GAP, 0)
                else
                    label:SetPoint("RIGHT", group[1], "LEFT", -GROUP_NUMBER_GAP, 0)
                end
                label:Show()
            elseif label then
                label:Hide()
            end
        end
    end

    -- Size the raid frame to the most populated visible subgroup instead of
    -- reserving five columns unconditionally. The group-number column follows
    -- the chosen side and is included without creating any placeholder cells.
    local columns = math.max(1, maxVisibleMembers)
    local buttonsWidth = (columns * BUTTON_SIZE) + ((columns - 1) * BUTTON_GAP)
    local width = 10 + buttonsWidth + numberInset
    local rowsHeight = visibleRows > 0
        and (visibleRows * BUTTON_SIZE) + ((visibleRows - 1) * GROUP_GAP)
        or 0
    mainFrame:SetSize(width, titleOffset + rowsHeight + 5)

    -- Raid mode intentionally uses the compact default presentation: no full
    -- panel background, no aura icons, class-colored role buttons and glow only.
    if mainFrame.Background then
        mainFrame.Background:SetColorTexture(0, 0, 0, 0)
    end
    if addon.cooldownBarContainer then
        addon.cooldownBarContainer:Hide()
    end
end

local BaseCreateSecureUnitButtons = addon.CreateSecureUnitButtons
function addon:CreateSecureUnitButtons(parent)
    local created = BaseCreateSecureUnitButtons(self, parent)
    if created then
        CreateRaidButtons(parent)
    end
    return created
end

local BaseApplyClickSpells = addon.ApplyClickSpells
function addon:ApplyClickSpells(spells)
    local applied = BaseApplyClickSpells(self, spells)
    if applied ~= true or InCombatLockdown() then
        return applied
    end

    ApplySpellsToRaidButtons(spells)
    return true
end

local BaseRebuildManagedAuraGlowContainers = addon.RebuildManagedAuraGlowContainers
function addon:RebuildManagedAuraGlowContainers()
    if InCombatLockdown() then
        self.pendingGlowRebuild = true
        return false
    end

    local partyButtons = self.unitButtons
    if self.raidModeActive and self.raidUnitButtons and self.raidUnitButtons[1] then
        self.unitButtons = self.raidUnitButtons
    end

    local rebuilt = BaseRebuildManagedAuraGlowContainers(self)
    self.unitButtons = partyButtons
    return rebuilt
end

local BaseApplyAuraVisibility = addon.ApplyAuraVisibility
function addon:ApplyAuraVisibility()
    local applied = BaseApplyAuraVisibility(self)
    if applied ~= true or InCombatLockdown() then
        return applied
    end

    if self.raidModeActive then
        -- Aura icons are intentionally omitted in the compact raid layout.
        for _, container in ipairs(self.auraContainers or {}) do
            container:SetEnabled(false)
            container:Hide()
        end
        -- The live dispel indication remains Blizzard-managed. Lua never reads
        -- the AuraButton or its visibility; it only enables the managed slots.
        for _, container in ipairs(self.glowAuraContainers or {}) do
            container:SetEnabled(true)
            container:Show()
        end
    end

    return true
end

local BaseUpdateCooldownBarLayout = addon.UpdateCooldownBarLayout
function addon:UpdateCooldownBarLayout(...)
    if self.raidModeActive then
        if self.cooldownBarContainer then
            self.cooldownBarContainer:Hide()
        end
        return
    end
    return BaseUpdateCooldownBarLayout(self, ...)
end

local function ApplyRaidModeState(active)
    if InCombatLockdown() then
        addon.pendingDisplayRefresh = true
        return false
    end

    if addon.raidModeActive ~= active then
        addon.raidModeActive = active
        -- The current glow container list represents only one unit set at a
        -- time. Rebuild it from configuration when switching party/raid mode;
        -- never inspect the old managed AuraButtons.
        addon:RebuildManagedAuraGlowContainers()
    end

    if active then
        SetPartyButtonsShown(false)
        LayoutRaidButtons()
        addon:ApplyAuraVisibility()
    else
        HideRaidButtons()
        SetPartyButtonsShown(true)
        addon:ApplyAuraVisibility()
        if addon.UpdateCooldownBarLayout then
            addon:UpdateCooldownBarLayout()
        end
    end

    return true
end

local BaseApplyDisplaySettings = addon.ApplyDisplaySettings
function addon:ApplyDisplaySettings(...)
    local applied = BaseApplyDisplaySettings(self, ...)
    if applied ~= true or InCombatLockdown() then
        return applied
    end

    ApplyRaidModeState(IsInRaid() == true)
    return true
end
