local addonName, addon = ...
local L = addon.L

local DISPLAY_ORDER = { 1, 3, 2 } -- Left, middle, right.
local GAP = 4
local VERTICAL_WIDGET_WIDTH = 30
local VERTICAL_WIDGET_HEIGHT = 38
local VERTICAL_BAR_WIDTH = 12
local VERTICAL_BAR_HEIGHT = 26
local HORIZONTAL_WIDGET_WIDTH = 92
local HORIZONTAL_WIDGET_HEIGHT = 16
local HORIZONTAL_BAR_WIDTH = 72
local HORIZONTAL_BAR_HEIGHT = 12

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
    bar:SetValue(1)
    widget.Bar = bar

    local barBackground = bar:CreateTexture(nil, "BACKGROUND")
    barBackground:SetAllPoints()
    barBackground:SetColorTexture(0.10, 0.11, 0.13, 0.95)

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

local function ConfigureVerticalWidget(widget)
    widget:SetSize(VERTICAL_WIDGET_WIDTH, VERTICAL_WIDGET_HEIGHT)
    widget.Background:SetAllPoints(widget)

    widget.Label:ClearAllPoints()
    widget.Label:SetPoint("TOP", widget, "TOP", 0, 0)

    widget.Bar:ClearAllPoints()
    widget.Bar:SetSize(VERTICAL_BAR_WIDTH, VERTICAL_BAR_HEIGHT)
    widget.Bar:SetPoint("BOTTOM", widget, "BOTTOM", 0, 0)
    widget.Bar:SetOrientation("VERTICAL")
end

local function ConfigureHorizontalWidget(widget)
    widget:SetSize(HORIZONTAL_WIDGET_WIDTH, HORIZONTAL_WIDGET_HEIGHT)
    widget.Background:SetAllPoints(widget)

    widget.Label:ClearAllPoints()
    widget.Label:SetPoint("LEFT", widget, "LEFT", 2, 0)

    widget.Bar:ClearAllPoints()
    widget.Bar:SetSize(HORIZONTAL_BAR_WIDTH, HORIZONTAL_BAR_HEIGHT)
    widget.Bar:SetPoint("RIGHT", widget, "RIGHT", -2, 0)
    widget.Bar:SetOrientation("HORIZONTAL")
end

local function GetVisibleWidgets()
    local widgets = {}
    for _, clickIndex in ipairs(DISPLAY_ORDER) do
        local spell = addon:GetConfiguredSpellForDisplay(clickIndex, addon.activeDispels)
        local widget = addon.cooldownBarWidgets and addon.cooldownBarWidgets[clickIndex]
        local visible = widget and spell and spell.isKnown and addon:IsCooldownBarEnabled(clickIndex)
        if widget then
            widget:SetShown(visible == true)
        end
        if visible then
            widgets[#widgets + 1] = widget
        end
    end
    return widgets
end

function addon:UpdateCooldownBarLayout()
    local container = self.cooldownBarContainer
    if not container or not self.unitButtons or not self.unitButtons[1] then
        return
    end

    local widgets = GetVisibleWidgets()
    container:ClearAllPoints()

    if #widgets == 0 then
        container:SetSize(1, 1)
        container:Hide()
        return
    end

    container:Show()
    local firstButton = self.unitButtons[1]
    local growth = self:GetAuraGrowth()

    if LafeeDecurseDB.horizontal then
        local width = (#widgets * HORIZONTAL_WIDGET_WIDTH) + ((#widgets - 1) * GAP)
        container:SetSize(width, HORIZONTAL_WIDGET_HEIGHT)

        if growth == "DOWN" then
            container:SetPoint("BOTTOMLEFT", firstButton, "TOPLEFT", 0, 5)
        else
            container:SetPoint("TOPLEFT", firstButton, "BOTTOMLEFT", 0, -5)
        end

        for position, widget in ipairs(widgets) do
            ConfigureHorizontalWidget(widget)
            widget:ClearAllPoints()
            widget:SetPoint("LEFT", container, "LEFT", (position - 1) * (HORIZONTAL_WIDGET_WIDTH + GAP), 0)
        end
    else
        local height = (#widgets * VERTICAL_WIDGET_HEIGHT) + ((#widgets - 1) * GAP)
        container:SetSize(VERTICAL_WIDGET_WIDTH, height)

        if growth == "RIGHT" then
            container:SetPoint("TOPRIGHT", firstButton, "TOPLEFT", -5, 0)
        else
            container:SetPoint("TOPLEFT", firstButton, "TOPRIGHT", 5, 0)
        end

        for position, widget in ipairs(widgets) do
            ConfigureVerticalWidget(widget)
            widget:ClearAllPoints()
            widget:SetPoint("TOP", container, "TOP", 0, -((position - 1) * (VERTICAL_WIDGET_HEIGHT + GAP)))
        end
    end
end

local function ApplySpellDuration(widget, spellID)
    local duration = C_Spell.GetSpellChargeDuration(spellID)
        or C_Spell.GetSpellCooldownDuration(spellID, true)

    if duration then
        widget.Bar:SetTimerDuration(
            duration,
            Enum.StatusBarInterpolation.Immediate,
            Enum.StatusBarTimerDirection.ElapsedTime
        )
    else
        widget.Bar:SetMinMaxValues(0, 1)
        widget.Bar:SetValue(1)
    end
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
