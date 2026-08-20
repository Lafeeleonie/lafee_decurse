local addonName, addon = ...
local L = addon.L

local CLICK_LABELS = {
    L.CLICK_LEFT,
    L.CLICK_RIGHT,
    L.CLICK_MIDDLE,
}

local function CreateCard(parent, topOffset, height, titleText)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, topOffset)
    card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -24, topOffset)
    card:SetHeight(height)
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    card:SetBackdropColor(0.035, 0.045, 0.065, 0.92)
    card:SetBackdropBorderColor(0.16, 0.28, 0.40, 0.95)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -14)
    title:SetText(titleText)
    title:SetTextColor(0.55, 0.90, 1)
    return card
end

local function CreateCheckbox(card, y, labelText, onClick)
    local checkbox = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", card, "TOPLEFT", 14, y)
    checkbox:SetScript("OnClick", function(self)
        onClick(self:GetChecked() == true)
    end)

    local label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetText(labelText)
    checkbox.Label = label
    return checkbox
end

local function CreateFieldLabel(card, x, y, labelText)
    local label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", card, "TOPLEFT", x, y)
    label:SetText(labelText)
    return label
end

local function CreateDropdown(card, x, y, width, defaultText)
    local dropdown = CreateFrame("DropdownButton", nil, card, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", card, "TOPLEFT", x, y)
    dropdown:SetWidth(width)
    dropdown:SetDefaultText(defaultText)
    return dropdown
end

local function CreateClickRow(card, index)
    local row = CreateFrame("Frame", nil, card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -42 - ((index - 1) * 48))
    row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -42 - ((index - 1) * 48))
    row:SetHeight(40)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    row:SetBackdropColor(0.07, 0.085, 0.11, 0.9)

    local badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    badge:SetSize(24, 24)
    badge:SetPoint("LEFT", row, "LEFT", 10, 0)
    badge:SetText(index)
    badge:SetTextColor(0.55, 0.90, 1)

    local clickLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clickLabel:SetPoint("LEFT", badge, "RIGHT", 8, 8)
    clickLabel:SetText(CLICK_LABELS[index])

    local spellIcon = row:CreateTexture(nil, "ARTWORK")
    spellIcon:SetSize(28, 28)
    spellIcon:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    spellIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local spellName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellName:SetPoint("LEFT", badge, "RIGHT", 8, -8)
    spellName:SetPoint("RIGHT", spellIcon, "LEFT", -8, -8)
    spellName:SetJustifyH("LEFT")

    row.SpellIcon = spellIcon
    row.SpellName = spellName
    return row
end

local function CreateColorButton(card, y, labelText, onColorChanged)
    local button = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    button:SetSize(180, 26)
    button:SetPoint("TOPLEFT", card, "TOPLEFT", 16, y)

    local swatch = button:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(18, 18)
    swatch:SetPoint("LEFT", button, "LEFT", 5, 0)
    button.Swatch = swatch

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    label:SetText(labelText)

    button:SetScript("OnClick", function()
        local color = LafeeDecurseDB.backgroundColor
        local oldR, oldG, oldB, oldA = color.r, color.g, color.b, color.a
        local function ColorChanged()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            onColorChanged(r, g, b, ColorPickerFrame:GetColorAlpha())
        end
        ColorPickerFrame:SetupColorPickerAndShow({
            r = oldR,
            g = oldG,
            b = oldB,
            opacity = oldA,
            hasOpacity = true,
            swatchFunc = ColorChanged,
            opacityFunc = ColorChanged,
            cancelFunc = function()
                onColorChanged(oldR, oldG, oldB, oldA)
            end,
        })
    end)
    return button
end

local function RefreshDropdown(dropdown)
    if dropdown and dropdown.GenerateMenu then
        dropdown:GenerateMenu()
    end
end

function addon:RefreshConfigurationPanel()
    local panel = self.configurationPanel
    if not panel or not LafeeDecurseDB then
        return
    end

    panel.LockCheckbox:SetChecked(LafeeDecurseDB.locked == true)
    panel.MinimapCheckbox:SetChecked(not LafeeDecurseDB.minimap.hide)
    panel.TestCheckbox:SetChecked(LafeeDecurseDB.testMode == true)
    panel.TitleCheckbox:SetChecked(LafeeDecurseDB.showTitle == true)
    panel.NamesCheckbox:SetChecked(LafeeDecurseDB.showNames == true)
    panel.ClassColorCheckbox:SetChecked(LafeeDecurseDB.useClassColors == true)
    panel.HorizontalCheckbox:SetChecked(LafeeDecurseDB.horizontal == true)

    RefreshDropdown(panel.BackgroundModeDropdown)
    RefreshDropdown(panel.AuraGrowthDropdown)

    local color = LafeeDecurseDB.backgroundColor
    panel.ColorButton.Swatch:SetColorTexture(color.r, color.g, color.b, color.a)
    panel.ColorButton:SetEnabled(LafeeDecurseDB.backgroundMode ~= addon.BACKGROUND_MODE_NONE)

    if panel.AuraCountSlider then
        panel.AuraCountSlider.ignoreValueChanged = true
        panel.AuraCountSlider:SetValue(addon:GetAuraCount())
        panel.AuraCountSlider.ignoreValueChanged = nil
    end

    for index, row in ipairs(panel.ClickRows) do
        local dispel = self.activeDispels and self.activeDispels[index]
        if dispel then
            local iconID = C_Spell.GetSpellTexture(dispel.spellID)
            row.SpellName:SetText(dispel.spellName)
            row.SpellName:SetTextColor(1, 0.82, 0)
            row.SpellIcon:SetTexture(iconID)
            row.SpellIcon:Show()
        else
            row.SpellName:SetText(L.UNASSIGNED)
            row.SpellName:SetTextColor(0.55, 0.58, 0.64)
            row.SpellIcon:Hide()
        end
    end
end

function addon:CreateConfigurationPanel()
    if not C_AddOns.IsAddOnLoaded("Blizzard_Menu") then
        C_AddOns.LoadAddOn("Blizzard_Menu")
    end

    local panel = CreateFrame("Frame", "LafeeDecurseConfigurationPanel")
    panel:SetSize(640, 620)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -24)
    title:SetText("Lafee Decurse")
    title:SetTextColor(0.55, 0.90, 1)

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText(L.CONFIG_SUBTITLE)

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -82)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(600, 820)
    scrollFrame:SetScrollChild(content)

    local generalCard = CreateCard(content, 0, 142, L.SECTION_INTERFACE)
    panel.LockCheckbox = CreateCheckbox(generalCard, -42, L.LOCK_FRAME, function(checked)
        if not addon:SetLocked(checked) then
            addon:RefreshConfigurationPanel()
        end
    end)
    panel.MinimapCheckbox = CreateCheckbox(generalCard, -78, L.SHOW_MINIMAP, function(checked)
        addon:SetMinimapVisible(checked)
    end)
    panel.TestCheckbox = CreateCheckbox(generalCard, -110, L.TEST_MODE, function(checked)
        if not addon:SetTestMode(checked) then
            addon:Print(L.TEST_COMBAT)
            addon:RefreshConfigurationPanel()
        end
    end)

    local resetButton = CreateFrame("Button", nil, generalCard, "UIPanelButtonTemplate")
    resetButton:SetSize(150, 24)
    resetButton:SetPoint("BOTTOMRIGHT", generalCard, "BOTTOMRIGHT", -14, 14)
    resetButton:SetText(L.RESET_POSITION)
    resetButton:SetScript("OnClick", function()
        addon:ResetMainFramePosition()
    end)

    local appearanceCard = CreateCard(content, -158, 326, L.SECTION_APPEARANCE)
    panel.TitleCheckbox = CreateCheckbox(appearanceCard, -42, L.SHOW_TITLE, function(checked)
        if not addon:SetDisplayOption("showTitle", checked) then addon:RefreshConfigurationPanel() end
    end)
    panel.NamesCheckbox = CreateCheckbox(appearanceCard, -76, L.SHOW_NAMES, function(checked)
        if not addon:SetDisplayOption("showNames", checked) then addon:RefreshConfigurationPanel() end
    end)

    CreateFieldLabel(appearanceCard, 16, -121, L.BACKGROUND_MODE)
    panel.BackgroundModeDropdown = CreateDropdown(appearanceCard, 245, -104, 285, L.BACKGROUND_MODE)
    panel.BackgroundModeDropdown:SetupMenu(function(_, rootDescription)
        local options = {
            { value = addon.BACKGROUND_MODE_FULL, text = L.BACKGROUND_MODE_FULL },
            { value = addon.BACKGROUND_MODE_FRAMES, text = L.BACKGROUND_MODE_FRAMES },
            { value = addon.BACKGROUND_MODE_NONE, text = L.BACKGROUND_MODE_NONE },
        }
        local function IsSelected(value)
            return LafeeDecurseDB.backgroundMode == value
        end
        local function SetSelected(value)
            if not addon:SetBackgroundMode(value) then
                addon:RefreshConfigurationPanel()
            end
        end
        for _, option in ipairs(options) do
            rootDescription:CreateRadio(option.text, IsSelected, SetSelected, option.value)
        end
    end)

    panel.ClassColorCheckbox = CreateCheckbox(appearanceCard, -144, L.CLASS_COLORS, function(checked)
        if not addon:SetDisplayOption("useClassColors", checked) then addon:RefreshConfigurationPanel() end
    end)
    panel.HorizontalCheckbox = CreateCheckbox(appearanceCard, -178, L.HORIZONTAL_LAYOUT, function(checked)
        if not addon:SetDisplayOption("horizontal", checked) then addon:RefreshConfigurationPanel() end
    end)

    panel.ColorButton = CreateColorButton(appearanceCard, -218, L.BACKGROUND_COLOR, function(r, g, b, a)
        addon:SetBackgroundColor(r, g, b, a)
    end)

    local resetColorButton = CreateFrame("Button", nil, appearanceCard, "UIPanelButtonTemplate")
    resetColorButton:SetSize(150, 26)
    resetColorButton:SetPoint("LEFT", panel.ColorButton, "RIGHT", 12, 0)
    resetColorButton:SetText(L.RESET_COLOR)
    resetColorButton:SetScript("OnClick", function()
        addon:ResetBackgroundColor()
    end)

    CreateFieldLabel(appearanceCard, 16, -261, L.AURA_COUNT)
    panel.AuraCountSlider = CreateFrame("Frame", nil, appearanceCard, "MinimalSliderWithSteppersTemplate")
    panel.AuraCountSlider:SetSize(250, 40)
    panel.AuraCountSlider:SetPoint("TOPLEFT", appearanceCard, "TOPLEFT", 260, -242)
    local sliderFormatters = {
        [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
            return tostring(math.floor(value + 0.5))
        end,
        [MinimalSliderWithSteppersMixin.Label.Min] = function()
            return "1"
        end,
        [MinimalSliderWithSteppersMixin.Label.Max] = function()
            return tostring(addon.MAX_AURA_COUNT)
        end,
    }
    panel.AuraCountSlider:Init(
        addon:GetAuraCount(),
        1,
        addon.MAX_AURA_COUNT,
        addon.MAX_AURA_COUNT - 1,
        sliderFormatters
    )
    panel.AuraCountSlider.Slider:HookScript("OnValueChanged", function(_, value)
        if panel.AuraCountSlider.ignoreValueChanged then
            return
        end

        local count = math.floor(value + 0.5)
        if count ~= addon:GetAuraCount() and not addon:SetAuraCount(count) then
            addon:RefreshConfigurationPanel()
        end
    end)

    CreateFieldLabel(appearanceCard, 16, -304, L.AURA_GROWTH)
    panel.AuraGrowthDropdown = CreateDropdown(appearanceCard, 245, -287, 285, L.AURA_GROWTH)
    panel.AuraGrowthDropdown:SetupMenu(function(_, rootDescription)
        local options
        if LafeeDecurseDB.horizontal then
            options = {
                { value = "UP", text = L.GROWTH_UP },
                { value = "DOWN", text = L.GROWTH_DOWN },
            }
        else
            options = {
                { value = "LEFT", text = L.GROWTH_LEFT },
                { value = "RIGHT", text = L.GROWTH_RIGHT },
            }
        end

        local function IsSelected(value)
            return addon:GetAuraGrowth() == value
        end
        local function SetSelected(value)
            if not addon:SetAuraGrowth(value) then
                addon:RefreshConfigurationPanel()
            end
        end
        for _, option in ipairs(options) do
            rootDescription:CreateRadio(option.text, IsSelected, SetSelected, option.value)
        end
    end)

    local clickCard = CreateCard(content, -500, 250, L.CLICK_ASSIGNMENTS)
    panel.ClickRows = {}
    for index = 1, 3 do
        panel.ClickRows[index] = CreateClickRow(clickCard, index)
    end

    local note = clickCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", clickCard, "TOPLEFT", 16, -204)
    note:SetPoint("TOPRIGHT", clickCard, "TOPRIGHT", -16, -204)
    note:SetJustifyH("LEFT")
    note:SetJustifyV("TOP")
    note:SetText(L.THIRD_CLICK_NOTE)
    note:SetTextColor(0.65, 0.69, 0.75)

    panel.OnRefresh = function()
        addon:RefreshConfigurationPanel()
    end

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Lafee Decurse")
    Settings.RegisterAddOnCategory(category)

    self.configurationPanel = panel
    self.settingsCategoryID = category:GetID()
    self:RefreshConfigurationPanel()
end

function addon:OpenConfiguration()
    if self.settingsCategoryID then
        Settings.OpenToCategory(self.settingsCategoryID)
    end
end
