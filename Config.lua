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

local function IsConfiguredSpell(clickIndex, spellID)
    local configured = addon:GetConfiguredSpellForDisplay(clickIndex, addon.activeDispels)
    local configuredID = configured and configured.spellID or 0
    return configuredID == spellID
end

local function SetConfiguredSpell(clickIndex, spellID)
    addon:SetConfiguredSpell(clickIndex, spellID)
end

local function CreateClickRow(card, index)
    local row = CreateFrame("Frame", nil, card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -42 - ((index - 1) * 54))
    row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -42 - ((index - 1) * 54))
    row:SetHeight(46)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    row:SetBackdropColor(0.07, 0.085, 0.11, 0.9)

    local clickLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clickLabel:SetPoint("LEFT", row, "LEFT", 10, 0)
    clickLabel:SetWidth(86)
    clickLabel:SetJustifyH("LEFT")
    clickLabel:SetText(CLICK_LABELS[index])

    local spellIcon = row:CreateTexture(nil, "ARTWORK")
    spellIcon:SetSize(28, 28)
    spellIcon:SetPoint("LEFT", row, "LEFT", 96, 0)
    spellIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetSize(300, 30)
    dropdown:SetPoint("LEFT", spellIcon, "RIGHT", 8, 0)
    dropdown:SetDefaultText(L.UNASSIGNED)
    dropdown:SetupMenu(function(_, rootDescription)
        rootDescription:CreateRadio(
            L.UNASSIGNED,
            function(spellID) return IsConfiguredSpell(index, spellID) end,
            function(spellID) SetConfiguredSpell(index, spellID) end,
            0
        )

        local spells = addon:GetAssignableSpells()
        if #spells > 0 then
            rootDescription:CreateDivider()
        end
        for _, spell in ipairs(spells) do
            rootDescription:CreateRadio(
                spell.spellName,
                function(spellID) return IsConfiguredSpell(index, spellID) end,
                function(spellID) SetConfiguredSpell(index, spellID) end,
                spell.spellID
            )
        end
    end)

    local cooldownCheckbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cooldownCheckbox:SetPoint("RIGHT", row, "RIGHT", -66, 0)
    cooldownCheckbox:SetScript("OnClick", function(self)
        if not addon:SetCooldownBarEnabled(index, self:GetChecked() == true) then
            addon:RefreshConfigurationPanel()
        end
    end)

    local cooldownLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cooldownLabel:SetPoint("LEFT", cooldownCheckbox, "RIGHT", 2, 0)
    cooldownLabel:SetText(L.COOLDOWN_BAR)

    row.SpellIcon = spellIcon
    row.SpellDropdown = dropdown
    row.CooldownCheckbox = cooldownCheckbox
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

    local modeLabels = {
        [addon.BACKGROUND_MODE_FULL] = L.BACKGROUND_MODE_FULL,
        [addon.BACKGROUND_MODE_FRAMES] = L.BACKGROUND_MODE_FRAMES,
        [addon.BACKGROUND_MODE_NONE] = L.BACKGROUND_MODE_NONE,
    }
    panel.BackgroundModeButton:SetText(L.BACKGROUND_MODE .. ": " .. modeLabels[LafeeDecurseDB.backgroundMode])

    local color = LafeeDecurseDB.backgroundColor
    panel.ColorButton.Swatch:SetColorTexture(color.r, color.g, color.b, color.a)
    panel.ColorButton:SetEnabled(LafeeDecurseDB.backgroundMode ~= addon.BACKGROUND_MODE_NONE)

    panel.AuraCountButton:SetText(L.AURA_COUNT .. ": " .. tostring(addon:GetAuraCount()))
    local growthLabels = {
        LEFT = L.GROWTH_LEFT,
        RIGHT = L.GROWTH_RIGHT,
        UP = L.GROWTH_UP,
        DOWN = L.GROWTH_DOWN,
    }
    panel.AuraGrowthButton:SetText(L.AURA_GROWTH .. ": " .. growthLabels[addon:GetAuraGrowth()])

    for index, row in ipairs(panel.ClickRows) do
        local spell = self:GetConfiguredSpellForDisplay(index, self.activeDispels)
        if spell then
            row.SpellIcon:SetTexture(spell.iconID)
            row.SpellIcon:SetDesaturated(not spell.isKnown)
            row.SpellIcon:Show()
        else
            row.SpellIcon:Hide()
        end

        row.CooldownCheckbox:SetChecked(self:IsCooldownBarEnabled(index))
        row.CooldownCheckbox:SetEnabled(spell ~= nil and spell.isKnown == true)
        if row.SpellDropdown.GenerateMenu then
            row.SpellDropdown:GenerateMenu()
        end
    end
end

function addon:CreateConfigurationPanel()
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
    content:SetSize(600, 850)
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
    panel.BackgroundModeButton = CreateFrame("Button", nil, appearanceCard, "UIPanelButtonTemplate")
    panel.BackgroundModeButton:SetSize(280, 26)
    panel.BackgroundModeButton:SetPoint("TOPLEFT", appearanceCard, "TOPLEFT", 16, -110)
    panel.BackgroundModeButton:SetScript("OnClick", function()
        local nextMode = {
            [addon.BACKGROUND_MODE_FULL] = addon.BACKGROUND_MODE_FRAMES,
            [addon.BACKGROUND_MODE_FRAMES] = addon.BACKGROUND_MODE_NONE,
            [addon.BACKGROUND_MODE_NONE] = addon.BACKGROUND_MODE_FULL,
        }
        if not addon:SetBackgroundMode(nextMode[LafeeDecurseDB.backgroundMode]) then
            addon:RefreshConfigurationPanel()
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

    panel.AuraCountButton = CreateFrame("Button", nil, appearanceCard, "UIPanelButtonTemplate")
    panel.AuraCountButton:SetSize(220, 26)
    panel.AuraCountButton:SetPoint("TOPLEFT", appearanceCard, "TOPLEFT", 16, -258)
    panel.AuraCountButton:SetScript("OnClick", function()
        local nextCount = addon:GetAuraCount() + 1
        if nextCount > addon.MAX_AURA_COUNT then nextCount = 1 end
        if not addon:SetAuraCount(nextCount) then addon:RefreshConfigurationPanel() end
    end)

    panel.AuraGrowthButton = CreateFrame("Button", nil, appearanceCard, "UIPanelButtonTemplate")
    panel.AuraGrowthButton:SetSize(260, 26)
    panel.AuraGrowthButton:SetPoint("LEFT", panel.AuraCountButton, "RIGHT", 12, 0)
    panel.AuraGrowthButton:SetScript("OnClick", function()
        local current = addon:GetAuraGrowth()
        local nextGrowth
        if LafeeDecurseDB.horizontal then
            nextGrowth = current == "DOWN" and "UP" or "DOWN"
        else
            nextGrowth = current == "RIGHT" and "LEFT" or "RIGHT"
        end
        if not addon:SetAuraGrowth(nextGrowth) then addon:RefreshConfigurationPanel() end
    end)

    local clickCard = CreateCard(content, -500, 284, L.ACTION_ASSIGNMENTS)
    panel.ClickRows = {}
    for index = 1, 3 do
        panel.ClickRows[index] = CreateClickRow(clickCard, index)
    end

    local note = clickCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", clickCard, "TOPLEFT", 16, -222)
    note:SetPoint("TOPRIGHT", clickCard, "TOPRIGHT", -16, -222)
    note:SetJustifyH("LEFT")
    note:SetJustifyV("TOP")
    note:SetText(L.ACTION_NOTE)
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
