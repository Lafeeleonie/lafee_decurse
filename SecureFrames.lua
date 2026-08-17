local addonName, addon = ...

addon.UNITS = { "player", "party1", "party2", "party3", "party4" }
addon.unitButtons = {}

local BUTTON_HEIGHT = 30
local BUTTON_WIDTH_WITH_NAME = 120
local BUTTON_WIDTH_ROLE_ONLY = 30
local AURA_SIZE = 24
local AURA_SPACING = 2
local TEST_AURA_TEXTURES = {
    "Interface\\Icons\\Spell_Holy_DispelMagic",
    "Interface\\Icons\\Spell_Nature_NullifyDisease",
    "Interface\\Icons\\Spell_Nature_RemoveCurse",
}

local ROLE_ATLASES = {
    TANK = "roleicon-tiny-tank",
    HEALER = "roleicon-tiny-healer",
    DAMAGER = "roleicon-tiny-dps",
}

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

local function CreateUnitButton(parent, unit, index)
    local button = CreateFrame(
        "Button",
        "LafeeDecurseUnitButton" .. index,
        parent,
        "SecureActionButtonTemplate"
    )
    button:SetSize(BUTTON_WIDTH_WITH_NAME, BUTTON_HEIGHT)
    -- Register both phases: SecureActionButtonTemplate chooses the correct one
    -- from ActionButtonUseKeyDown and executes exactly one secure action.
    button:RegisterForClicks("AnyDown", "AnyUp")

    -- Protected attributes are assigned to a permanent unit outside combat.
    -- Neither the aura display nor any combat event ever changes this unit.
    button:SetAttribute("unit", unit)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.07, 0.08, 0.10, 0.92)
    button.Background = background
    CreateBorder(button)

    local roleIcon = button:CreateTexture(nil, "OVERLAY")
    roleIcon:SetSize(14, 14)
    roleIcon:SetPoint("LEFT", button, "LEFT", 6, 0)
    roleIcon:Hide()
    button.RoleIcon = roleIcon

    local name = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", roleIcon, "RIGHT", 3, 0)
    name:SetPoint("RIGHT", button, "RIGHT", -32, 0)
    name:SetJustifyH("LEFT")
    name:SetText(unit)
    button.NameText = name

    button.TestAuraIcons = {}
    for auraIndex, texture in ipairs(TEST_AURA_TEXTURES) do
        local testIcon = button:CreateTexture(nil, "OVERLAY")
        testIcon:SetSize(AURA_SIZE, AURA_SIZE)
        testIcon:SetTexture(texture)
        testIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        testIcon:Hide()
        button.TestAuraIcons[auraIndex] = testIcon
    end

    button.fixedUnit = unit
    return button
end

function addon:CreateSecureUnitButtons(parent)
    if InCombatLockdown() then
        self.pendingInitialization = true
        return false
    end

    for index, unit in ipairs(self.UNITS) do
        self.unitButtons[index] = CreateUnitButton(parent, unit, index)
    end

    return true
end

function addon:ApplyDispelSpells(dispels)
    if InCombatLockdown() then
        self.pendingDispelRefresh = true
        return false
    end

    for _, button in ipairs(self.unitButtons) do
        -- Changing secure action attributes in combat is forbidden. This
        -- function is only called after the lockdown guard above.
        for clickIndex = 1, 3 do
            local dispel = dispels and dispels[clickIndex]
            if dispel then
                button:SetAttribute("type" .. clickIndex, "spell")
                button:SetAttribute("spell" .. clickIndex, dispel.spellName)
            else
                button:SetAttribute("type" .. clickIndex, nil)
                button:SetAttribute("spell" .. clickIndex, nil)
            end
        end
    end

    self.activeDispels = dispels or {}
    return true
end

local function GetDisplayedRole(unit)
    local role = UnitGroupRolesAssigned(unit)
    if role == "NONE" and unit == "player" then
        local specialization = GetSpecialization()
        if specialization then
            role = GetSpecializationRole(specialization)
        end
    end
    return role
end

local function GetButtonWidth()
    return LafeeDecurseDB.showNames and BUTTON_WIDTH_WITH_NAME or BUTTON_WIDTH_ROLE_ONLY
end

local function GetBackgroundColor(unit)
    if LafeeDecurseDB.backgroundMode == addon.BACKGROUND_MODE_NONE then
        return 0, 0, 0, 0
    end

    local backgroundColor = LafeeDecurseDB.backgroundColor or addon.DEFAULT_BACKGROUND_COLOR
    local alpha = backgroundColor.a or addon.DEFAULT_BACKGROUND_COLOR.a

    if LafeeDecurseDB.useClassColors and UnitExists(unit) then
        local _, class = UnitClass(unit)
        local color = class and RAID_CLASS_COLORS[class]
        if color then
            return color.r, color.g, color.b, alpha
        end
    end

    return backgroundColor.r, backgroundColor.g, backgroundColor.b, alpha
end

local function UpdateMainFrameBackground()
    local color = LafeeDecurseDB.backgroundColor or addon.DEFAULT_BACKGROUND_COLOR
    local alpha = LafeeDecurseDB.backgroundMode == addon.BACKGROUND_MODE_FULL
        and (color.a or addon.DEFAULT_BACKGROUND_COLOR.a)
        or 0
    addon.mainFrame.Background:SetColorTexture(color.r, color.g, color.b, alpha)
end

local function LayoutTestAuras(button)
    for index, icon in ipairs(button.TestAuraIcons) do
        icon:ClearAllPoints()
        if LafeeDecurseDB.horizontal then
            icon:SetPoint("TOP", button, "BOTTOM", 0, -3 - ((index - 1) * (AURA_SIZE + AURA_SPACING)))
        else
            icon:SetPoint("LEFT", button, "RIGHT", 3 + ((index - 1) * (AURA_SIZE + AURA_SPACING)), 0)
        end
    end
end

function addon:ApplyDisplaySettings()
    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        return false
    end

    local buttonWidth = GetButtonWidth()
    local titleOffset = LafeeDecurseDB.showTitle and 20 or 5
    local auraExtent = (AURA_SIZE * 3) + (AURA_SPACING * 2)

    self.mainFrame.TitleText:SetShown(LafeeDecurseDB.showTitle)
    UpdateMainFrameBackground()
    for index, button in ipairs(self.unitButtons) do
        button:SetSize(buttonWidth, BUTTON_HEIGHT)
        button:ClearAllPoints()
        if LafeeDecurseDB.horizontal then
            button:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 5 + ((index - 1) * (buttonWidth + 2)), -titleOffset)
        else
            button:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 5, -titleOffset - ((index - 1) * BUTTON_HEIGHT))
        end
        LayoutTestAuras(button)
    end

    if LafeeDecurseDB.horizontal then
        self.mainFrame:SetSize(10 + (#self.unitButtons * buttonWidth) + ((#self.unitButtons - 1) * 2), titleOffset + BUTTON_HEIGHT + auraExtent + 8)
    else
        self.mainFrame:SetSize(8 + buttonWidth + auraExtent, titleOffset + (#self.unitButtons * BUTTON_HEIGHT) + 5)
    end

    self:UpdateUnitNames()
    if self.UpdateAuraDisplayLayout then
        self:UpdateAuraDisplayLayout()
    end
    self:RefreshConfigurationPanel()
    return true
end

function addon:SetDisplayOption(key, value)
    if InCombatLockdown() then
        self:Print(addon.L.DISPLAY_COMBAT)
        return false
    end

    LafeeDecurseDB[key] = value == true
    return self:ApplyDisplaySettings()
end

function addon:SetBackgroundMode(mode)
    if InCombatLockdown() then
        self:Print(addon.L.DISPLAY_COMBAT)
        return false
    end

    if mode ~= self.BACKGROUND_MODE_FULL
        and mode ~= self.BACKGROUND_MODE_FRAMES
        and mode ~= self.BACKGROUND_MODE_NONE
    then
        return false
    end

    LafeeDecurseDB.backgroundMode = mode
    LafeeDecurseDB.showBackground = mode ~= self.BACKGROUND_MODE_NONE
    return self:ApplyDisplaySettings()
end

function addon:SetBackgroundColor(r, g, b, a)
    if InCombatLockdown() then
        self:Print(addon.L.DISPLAY_COMBAT)
        return false
    end

    local currentAlpha = (LafeeDecurseDB.backgroundColor and LafeeDecurseDB.backgroundColor.a)
        or self.DEFAULT_BACKGROUND_COLOR.a
    LafeeDecurseDB.backgroundColor = {
        r = math.max(0, math.min(1, tonumber(r) or self.DEFAULT_BACKGROUND_COLOR.r)),
        g = math.max(0, math.min(1, tonumber(g) or self.DEFAULT_BACKGROUND_COLOR.g)),
        b = math.max(0, math.min(1, tonumber(b) or self.DEFAULT_BACKGROUND_COLOR.b)),
        a = math.max(0, math.min(1, tonumber(a) or currentAlpha)),
    }
    UpdateMainFrameBackground()
    self:UpdateUnitNames()
    self:RefreshConfigurationPanel()
    return true
end

function addon:ResetBackgroundColor()
    local color = self.DEFAULT_BACKGROUND_COLOR
    return self:SetBackgroundColor(color.r, color.g, color.b, color.a)
end

function addon:UpdateUnitNames()
    if InCombatLockdown() then
        self.pendingNameRefresh = true
        return
    end

    for _, button in ipairs(self.unitButtons) do
        local name = UnitName(button.fixedUnit)
        button.NameText:SetText(name or button.fixedUnit)
        button:SetAlpha((UnitExists(button.fixedUnit) or self.testMode) and 1 or 0.45)
        button.Background:SetColorTexture(GetBackgroundColor(button.fixedUnit))

        local roleAtlas = ROLE_ATLASES[GetDisplayedRole(button.fixedUnit)]
        button.NameText:SetShown(LafeeDecurseDB.showNames)
        button.NameText:ClearAllPoints()
        if roleAtlas then
            button.RoleIcon:SetAtlas(roleAtlas)
            button.RoleIcon:Show()
            if LafeeDecurseDB.showNames then
                button.RoleIcon:ClearAllPoints()
                button.RoleIcon:SetPoint("LEFT", button, "LEFT", 6, 0)
                button.NameText:SetPoint("LEFT", button.RoleIcon, "RIGHT", 3, 0)
            else
                button.RoleIcon:ClearAllPoints()
                button.RoleIcon:SetPoint("CENTER", button, "CENTER", 0, 0)
            end
        else
            button.RoleIcon:Hide()
            button.NameText:SetPoint("LEFT", button, "LEFT", 7, 0)
        end
        button.NameText:SetPoint("RIGHT", button, "RIGHT", -32, 0)
    end
end

function addon:SetTestMode(enabled)
    if InCombatLockdown() then
        return false
    end

    self.testMode = enabled == true
    LafeeDecurseDB.testMode = self.testMode
    for _, button in ipairs(self.unitButtons) do
        for _, icon in ipairs(button.TestAuraIcons) do
            icon:SetShown(self.testMode)
        end
        button:SetAlpha((UnitExists(button.fixedUnit) or self.testMode) and 1 or 0.45)
    end
    for _, container in ipairs(self.auraContainers or {}) do
        container:SetEnabled(not self.testMode)
        container:SetShown(not self.testMode)
    end
    self:RefreshConfigurationPanel()
    return true
end
