local addonName, addon = ...
local L = addon.L

local DISPLAY_ORDER = { 1, 3, 2 } -- Left, middle, right.
local HORIZONTAL_BUTTON_GAP = 2
local VERTICAL_WIDGET_WIDTH = 30
local VERTICAL_BAR_WIDTH = 12
local HORIZONTAL_WIDGET_HEIGHT = 16
local HORIZONTAL_LABEL_WIDTH = 18

local function GetShortClickLabel(clickIndex)
    if clickIndex == 1 then
        return L.CLICK_SHORT_LEFT or "L"
    elseif clickIndex == 2 then
        return L.CLICK_SHORT_RIGHT or "R"
    end
    return L.CLICK_SHORT_MIDDLE or "M"
end

local function CreateCooldownWidget(parent, clickIndex)
    local widget = CreateFrame("Frame", nil, parent)
    widget.clickIndex = clickIndex

    local label = widget:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetText(GetShortClickLabel(clickIndex))
    widget.Label = label

    local background = widget:CreateTexture(nil, "BACKGROUND")
    background:SetColorTexture(0.03, 0.04, 0.05, 0.88)
    widget.Background = background

    local bar = CreateFrame("StatusBar", nil, widget)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(0.55, 0.90, 1.00, 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetAlpha(0)
    widget.Bar = bar

    local barBackground = bar:CreateTexture(nil, "BACKGROUND")
    barBackground:SetAllPoints()
    barBackground:SetColorTexture(0.10, 0.11, 0.13, 0.95)
    barBackground:SetAlpha(0)
    widget.BarBackground = barBackground

    widget:Hide()
    return widget
end

function addon:CreateCooldownBars(parent)
    if self.cooldownBarContainer then
        return
    end

    local container = CreateFrame("Frame", "LafeeDecurseCooldownBars", parent)
    container:SetSize(1, 1)
    self.cooldownBarContainer = container
    self.cooldownBarWidgets = {}

    for clickIndex = 1, 3 do
        self.cooldownBarWidgets[clickIndex] = CreateCooldownWidget(container, clickIndex)
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    eventFrame:RegisterEvent("SPELLS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function()
        if addon.initialized or addon.cooldownBarContainer then
            addon:RefreshCooldownBars()
        end
    end)
    self.cooldownEventFrame = eventFrame

    self:UpdateCooldownBarLayout()
    self:RefreshCooldownBars()
end

local function ConfigureVerticalWidget(widget, height)
    widget:SetSize(VERTICAL_WIDGET_WIDTH, height)
    widget.Background:SetAllPoints(widget)

    widget.Label:ClearAllPoints()
    widget.Label:SetPoint("TOP", widget, "TOP", 0, -1)

    widget.Bar:ClearAllPoints()
    widget.Bar:SetPoint("TOP", widget, "TOP", 0, -12)
    widget.Bar:SetPoint("BOTTOM", widget, "BOTTOM", 0, 1)
    widget.Bar:SetWidth(VERTICAL_BAR_WIDTH)
    widget.Bar:SetOrientation("VERTICAL")
end

local function ConfigureHorizontalWidget(widget, width)
    widget:SetSize(width, HORIZONTAL_WIDGET_HEIGHT)
    widget.Background:SetAllPoints(widget)

    widget.Label:ClearAllPoints()
    widget.Label:SetPoint("LEFT", widget, "LEFT", 2, 0)
    widget.Label:SetWidth(HORIZONTAL_LABEL_WIDTH - 2)
    widget.Label:SetJustifyH("CENTER")

    widget.Bar:ClearAllPoints()
    widget.Bar:SetPoint("TOPLEFT", widget, "TOPLEFT", HORIZONTAL_LABEL_WIDTH, -2)
    widget.Bar:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", -2, 2)
    widget.Bar:SetOrientation("HORIZONTAL")
end

local function ApplyBackgroundMode(widget)
    local showBackground = LafeeDecurseDB
        and LafeeDecurseDB.backgroundMode == addon.BACKGROUND_MODE_FULL

    widget.Background:SetShown(showBackground == true)
    widget.BarBackground:SetShown(showBackground == true)
end

local function IsWidgetVisible(clickIndex)
    local spell = addon:GetConfiguredSpellForDisplay(clickIndex, addon.activeDispels)
    return spell and spell.isKnown and addon:IsCooldownBarEnabled(clickIndex)
end

local function UpdateWidgetVisibility()
    local anyVisible = false
    for _, clickIndex in ipairs(DISPLAY_ORDER) do
        local widget = addon.cooldownBarWidgets and addon.cooldownBarWidgets[clickIndex]
        local visible = widget and IsWidgetVisible(clickIndex)
        if widget then
            widget:SetShown(visible == true)
            ApplyBackgroundMode(widget)
        end
        if visible then
            anyVisible = true
        end
    end
    return anyVisible
end

function addon:UpdateCooldownBarLayout()
    local container = self.cooldownBarContainer
    if not container or not self.unitButtons or not self.unitButtons[1] then
        return
    end

    local anyVisible = UpdateWidgetVisibility()
    container:ClearAllPoints()

    if not anyVisible then
        container:SetSize(1, 1)
        container:Hide()
        return
    end

    container:Show()
    local firstButton = self.unitButtons[1]
    local growth = self:GetAuraGrowth()

    if LafeeDecurseDB.horizontal then
        local buttonWidth = firstButton:GetWidth()
        local tableWidth = (#self.unitButtons * buttonWidth)
            + ((#self.unitButtons - 1) * HORIZONTAL_BUTTON_GAP)
        local thirdWidth = tableWidth / 3
        container:SetSize(tableWidth, HORIZONTAL_WIDGET_HEIGHT)

        if growth == "DOWN" then
            container:SetPoint("BOTTOMLEFT", firstButton, "TOPLEFT", 0, 5)
        else
            container:SetPoint("TOPLEFT", firstButton, "BOTTOMLEFT", 0, -5)
        end

        for position, clickIndex in ipairs(DISPLAY_ORDER) do
            local widget = self.cooldownBarWidgets[clickIndex]
            ConfigureHorizontalWidget(widget, thirdWidth)
            widget:ClearAllPoints()
            widget:SetPoint("LEFT", container, "LEFT", (position - 1) * thirdWidth, 0)
        end
    else
        local tableHeight = #self.unitButtons * firstButton:GetHeight()
        local thirdHeight = tableHeight / 3
        container:SetSize(VERTICAL_WIDGET_WIDTH, tableHeight)

        if growth == "RIGHT" then
            container:SetPoint("TOPRIGHT", firstButton, "TOPLEFT", -5, 0)
        else
            container:SetPoint("TOPLEFT", firstButton, "TOPRIGHT", 5, 0)
        end

        for position, clickIndex in ipairs(DISPLAY_ORDER) do
            local widget = self.cooldownBarWidgets[clickIndex]
            ConfigureVerticalWidget(widget, thirdHeight)
            widget:ClearAllPoints()
            widget:SetPoint("TOP", container, "TOP", 0, -((position - 1) * thirdHeight))
        end
    end
end

local function ApplySpellDuration(widget, spellID)
    local duration = C_Spell.GetSpellChargeDuration(spellID)
        or C_Spell.GetSpellCooldownDuration(spellID, true)

    if not duration then
        widget.Bar:SetMinMaxValues(0, 1)
        widget.Bar:SetValue(0)
        widget.Bar:SetAlpha(0)
        widget.BarBackground:SetAlpha(0)
        return
    end

    widget.Bar:SetTimerDuration(
        duration,
        Enum.StatusBarInterpolation.Immediate,
        Enum.StatusBarTimerDirection.RemainingTime
    )

    -- IsActive() can reflect restricted cooldown state. Feed that boolean
    -- directly into secret-aware region APIs instead of branching on it in Lua.
    local isActive = duration:IsActive()
    widget.Bar:SetAlphaFromBoolean(isActive, 1, 0)
    widget.BarBackground:SetAlphaFromBoolean(isActive, 1, 0)
end

function addon:RefreshCooldownBars()
    if not self.cooldownBarWidgets then
        return
    end

    for clickIndex = 1, 3 do
        local widget = self.cooldownBarWidgets[clickIndex]
        local spell = self:GetConfiguredSpellForDisplay(clickIndex, self.activeDispels)
        if widget and spell and spell.isKnown and self:IsCooldownBarEnabled(clickIndex) then
            ApplySpellDuration(widget, spell.spellID)
        end
    end

    self:UpdateCooldownBarLayout()
end
