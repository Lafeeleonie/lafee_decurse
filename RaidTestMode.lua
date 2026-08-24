local _, addon = ...

local BUTTON_SIZE = addon.UNIT_BUTTON_HEIGHT or 30
local BUTTON_GAP = 2
local GROUP_GAP = 6
local MAX_GROUPS = 8
local GROUP_NUMBER_WIDTH = 18
local GROUP_NUMBER_GAP = 4

-- Deliberately irregular roster: this exercises full, partial and single-member
-- subgroups in one glance without requiring a real raid. Every Blizzard raid
-- subgroup is represented so the vertical stacking and group labels are visible.
local TEST_GROUP_SIZES = {
    [1] = 5,
    [2] = 3,
    [3] = 4,
    [4] = 1,
    [5] = 2,
    [6] = 1,
    [7] = 1,
    [8] = 5,
}

local TEST_CLASSES = {
    "WARRIOR",
    "PRIEST",
    "MAGE",
    "DRUID",
    "PALADIN",
    "SHAMAN",
    "HUNTER",
    "ROGUE",
    "WARLOCK",
    "MONK",
    "DEMONHUNTER",
    "DEATHKNIGHT",
    "EVOKER",
}

local TEST_ROLES = {
    "TANK",
    "HEALER",
    "DAMAGER",
    "DAMAGER",
    "DAMAGER",
}

local ROLE_ATLASES = {
    TANK = "roleicon-tiny-tank",
    HEALER = "roleicon-tiny-healer",
    DAMAGER = "roleicon-tiny-dps",
}

addon.raidTestMode = false
addon.raidTestButtons = addon.raidTestButtons or {}
addon.raidTestGroupLabels = addon.raidTestGroupLabels or {}

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

local function CreateTestButton(parent)
    local button = CreateFrame("Frame", nil, parent)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:EnableMouse(false)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.07, 0.08, 0.10, 0.92)
    button.Background = background
    CreateBorder(button)

    local roleIcon = button:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(16, 16)
    roleIcon:SetPoint("CENTER")
    button.RoleIcon = roleIcon

    button:Hide()
    return button
end

local function EnsureTestFrames()
    local parent = addon.mainFrame
    if not parent or addon.raidTestButtons[1] then
        return
    end

    local total = 0
    for groupIndex = 1, MAX_GROUPS do
        total = total + (TEST_GROUP_SIZES[groupIndex] or 0)
    end

    for index = 1, total do
        addon.raidTestButtons[index] = CreateTestButton(parent)
    end

    for groupIndex = 1, MAX_GROUPS do
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetWidth(GROUP_NUMBER_WIDTH)
        label:SetJustifyH("CENTER")
        label:SetText(tostring(groupIndex))
        label:SetTextColor(0.55, 0.90, 1)
        label:Hide()
        addon.raidTestGroupLabels[groupIndex] = label
    end
end

local function HideRaidTestFrames()
    for _, button in ipairs(addon.raidTestButtons or {}) do
        button:Hide()
    end
    for _, label in ipairs(addon.raidTestGroupLabels or {}) do
        label:Hide()
    end
end

local function HideLiveUnitFrames()
    for _, button in ipairs(addon.unitButtons or {}) do
        button:Hide()
    end
    for _, button in ipairs(addon.raidUnitButtons or {}) do
        button:Hide()
    end
    for _, label in ipairs(addon.raidGroupLabels or {}) do
        label:Hide()
    end
end

local function ApplyTestButtonVisual(button, testIndex, position)
    local class = TEST_CLASSES[((testIndex - 1) % #TEST_CLASSES) + 1]
    local color = RAID_CLASS_COLORS[class]
    if color then
        button.Background:SetColorTexture(color.r, color.g, color.b, 0.92)
    else
        button.Background:SetColorTexture(0.07, 0.08, 0.10, 0.92)
    end

    local role = TEST_ROLES[((position - 1) % #TEST_ROLES) + 1]
    local atlas = ROLE_ATLASES[role]
    if atlas then
        button.RoleIcon:SetAtlas(atlas)
        button.RoleIcon:Show()
    else
        button.RoleIcon:Hide()
    end
end

local function LayoutRaidTest()
    local mainFrame = addon.mainFrame
    if not mainFrame then
        return
    end

    EnsureTestFrames()
    HideRaidTestFrames()
    HideLiveUnitFrames()

    local db = addon.db or {}
    local titleOffset = db.showTitle == false and 5 or 20
    local numberSide = addon:GetRaidGroupNumberSide()
    local numberInset = numberSide == addon.RAID_GROUP_NUMBER_NONE
        and 0
        or (GROUP_NUMBER_WIDTH + GROUP_NUMBER_GAP)
    local buttonsStartX = numberSide == addon.RAID_GROUP_NUMBER_LEFT and (5 + numberInset) or 5
    local visibleRows = 0
    local maxVisibleMembers = 0
    local testIndex = 0

    for groupIndex = 1, MAX_GROUPS do
        local memberCount = TEST_GROUP_SIZES[groupIndex] or 0
        if memberCount > 0 then
            visibleRows = visibleRows + 1
            maxVisibleMembers = math.max(maxVisibleMembers, memberCount)
            local rowY = -titleOffset - ((visibleRows - 1) * (BUTTON_SIZE + GROUP_GAP))
            local firstButton
            local lastButton

            for position = 1, memberCount do
                testIndex = testIndex + 1
                local button = addon.raidTestButtons[testIndex]
                ApplyTestButtonVisual(button, testIndex, position)
                button:ClearAllPoints()
                button:SetPoint(
                    "TOPLEFT",
                    mainFrame,
                    "TOPLEFT",
                    buttonsStartX + ((position - 1) * (BUTTON_SIZE + BUTTON_GAP)),
                    rowY
                )
                button:Show()
                firstButton = firstButton or button
                lastButton = button
            end

            local label = addon.raidTestGroupLabels[groupIndex]
            if label and firstButton and lastButton
                and numberSide ~= addon.RAID_GROUP_NUMBER_NONE
            then
                label:ClearAllPoints()
                if numberSide == addon.RAID_GROUP_NUMBER_RIGHT then
                    label:SetPoint("LEFT", lastButton, "RIGHT", GROUP_NUMBER_GAP, 0)
                else
                    label:SetPoint("RIGHT", firstButton, "LEFT", -GROUP_NUMBER_GAP, 0)
                end
                label:Show()
            elseif label then
                label:Hide()
            end
        end
    end

    local columns = math.max(1, maxVisibleMembers)
    local buttonsWidth = (columns * BUTTON_SIZE) + ((columns - 1) * BUTTON_GAP)
    local width = 10 + buttonsWidth + numberInset
    local rowsHeight = visibleRows > 0
        and (visibleRows * BUTTON_SIZE) + ((visibleRows - 1) * GROUP_GAP)
        or 0
    mainFrame:SetSize(width, titleOffset + rowsHeight + 5)

    if mainFrame.Background then
        mainFrame.Background:SetColorTexture(0, 0, 0, 0)
    end
    if addon.cooldownBarContainer then
        addon.cooldownBarContainer:Hide()
    end
end

function addon:IsRaidTestModeEnabled()
    return self.raidTestMode == true
end

function addon:SetRaidTestMode(enabled)
    if InCombatLockdown() then
        self:Print(self.L.DISPLAY_COMBAT)
        return false
    end

    if enabled == true and IsInRaid() then
        self.raidTestMode = false
        self:Print(self.L.RAID_TEST_IN_RAID or "Raid test mode is unavailable while in a real raid.")
        self:RefreshConfigurationPanel()
        return false
    end

    self.raidTestMode = enabled == true
    return self:ApplyDisplaySettings()
end

local BaseApplyDisplaySettings = addon.ApplyDisplaySettings
function addon:ApplyDisplaySettings(...)
    local applied = BaseApplyDisplaySettings(self, ...)
    if applied ~= true or InCombatLockdown() then
        return applied
    end

    if IsInRaid() then
        -- Never allow a simulated roster to cover real raidN buttons.
        self.raidTestMode = false
        HideRaidTestFrames()
    elseif self.raidTestMode then
        LayoutRaidTest()
    else
        HideRaidTestFrames()
    end

    return true
end
