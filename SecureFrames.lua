local addonName, addon = ...

addon.UNITS = { "player", "party1", "party2", "party3", "party4" }
addon.unitButtons = {}

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
    button:SetSize(120, 30)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, -20 - ((index - 1) * 30))
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

    local testIcon = button:CreateTexture(nil, "OVERLAY")
    testIcon:SetSize(24, 24)
    testIcon:SetPoint("RIGHT", button, "RIGHT", -3, 0)
    testIcon:SetTexture("Interface\\Icons\\Spell_Holy_DispelMagic")
    testIcon:Hide()
    button.TestIcon = testIcon

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

function addon:UpdateUnitNames()
    if InCombatLockdown() then
        self.pendingNameRefresh = true
        return
    end

    for _, button in ipairs(self.unitButtons) do
        local name = UnitName(button.fixedUnit)
        button.NameText:SetText(name or button.fixedUnit)
        button:SetAlpha(UnitExists(button.fixedUnit) and 1 or 0.45)

        local roleAtlas = ROLE_ATLASES[GetDisplayedRole(button.fixedUnit)]
        button.NameText:ClearAllPoints()
        if roleAtlas then
            button.RoleIcon:SetAtlas(roleAtlas)
            button.RoleIcon:Show()
            button.NameText:SetPoint("LEFT", button.RoleIcon, "RIGHT", 3, 0)
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

    self.testMode = enabled
    for _, button in ipairs(self.unitButtons) do
        button.TestIcon:SetShown(enabled)
    end
    return true
end
