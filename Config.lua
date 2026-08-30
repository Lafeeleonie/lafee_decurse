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

local function RefreshDropdown(dropdown)
    if dropdown and dropdown.GenerateMenu then
        dropdown:GenerateMenu()
    end
end

function addon:LayoutConfigurationCards()
    local panel = self.configurationPanel
    local content = panel and panel.SettingsContent
    if not content then
        return
    end

    local cards = {
        panel.GeneralSettingsCard,
        panel.SpellSettingsCard,
        panel.PartySettingsCard,
        panel.RaidSettingsCard,
        panel.GroupOrderCard,
        panel.GlowSettingsCard,
    }
    local previousCard
    local totalHeight = 0
    for index = 1, 6 do
        local card = cards[index]
        if card then
            card:ClearAllPoints()
            if previousCard then
                card:SetPoint("TOPLEFT", previousCard, "BOTTOMLEFT", 0, -16)
                card:SetPoint("TOPRIGHT", previousCard, "BOTTOMRIGHT", 0, -16)
                totalHeight = totalHeight + 16
            else
                card:SetPoint("TOPLEFT", content, "TOPLEFT", 24, 0)
                card:SetPoint("TOPRIGHT", content, "TOPRIGHT", -24, 0)
            end
            totalHeight = totalHeight + card:GetHeight()
            previousCard = card
        end
    end

    content:SetHeight(math.max(620, totalHeight + 24))
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
    panel.PartyRoleIconsCheckbox:SetChecked(addon:ArePartyRoleIconsShown())
    panel.ClassColorCheckbox:SetChecked(LafeeDecurseDB.useClassColors == true)
    panel.HorizontalCheckbox:SetChecked(LafeeDecurseDB.horizontal == true)
    panel.ShowAurasCheckbox:SetChecked(LafeeDecurseDB.showAuras ~= false)
    if panel.AuraGlowCheckbox then
        panel.AuraGlowCheckbox:SetChecked(LafeeDecurseDB.auraGlow ~= false)
    end

    RefreshDropdown(panel.FrameAnchorDropdown)
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

    if panel.PartyScaleSlider then
        panel.PartyScaleSlider.ignoreValueChanged = true
        panel.PartyScaleSlider:SetValue(addon:GetPartyFrameScale())
        panel.PartyScaleSlider.ignoreValueChanged = nil
    end

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
        RefreshDropdown(row.SpellDropdown)
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
    content:SetSize(600, 620)
    scrollFrame:SetScrollChild(content)

    local generalCard = CreateCard(content, 0, 340, L.SECTION_GENERAL)
    panel.LockCheckbox = CreateCheckbox(generalCard, -42, L.LOCK_FRAME, function(checked)
        if not addon:SetLocked(checked) then
            addon:RefreshConfigurationPanel()
        end
    end)
    panel.MinimapCheckbox = CreateCheckbox(generalCard, -78, L.SHOW_MINIMAP, function(checked)
        addon:SetMinimapVisible(checked)
    end)
    panel.TitleCheckbox = CreateCheckbox(generalCard, -110, L.SHOW_TITLE, function(checked)
        if not addon:SetDisplayOption("showTitle", checked) then addon:RefreshConfigurationPanel() end
    end)
    panel.ClassColorCheckbox = CreateCheckbox(generalCard, -144, L.CLASS_COLORS, function(checked)
        if not addon:SetDisplayOption("useClassColors", checked) then addon:RefreshConfigurationPanel() end
    end)

    CreateFieldLabel(generalCard, 16, -187, L.BACKGROUND_MODE)
    panel.BackgroundModeDropdown = CreateDropdown(generalCard, 245, -170, 285, L.BACKGROUND_MODE)
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

    panel.ColorButton = CreateColorButton(generalCard, -218, L.BACKGROUND_COLOR, function(r, g, b, a)
        addon:SetBackgroundColor(r, g, b, a)
    end)

    local resetColorButton = CreateFrame("Button", nil, generalCard, "UIPanelButtonTemplate")
    resetColorButton:SetSize(150, 26)
    resetColorButton:SetPoint("LEFT", panel.ColorButton, "RIGHT", 12, 0)
    resetColorButton:SetText(L.RESET_COLOR)
    resetColorButton:SetScript("OnClick", function()
        addon:ResetBackgroundColor()
    end)

    CreateFieldLabel(generalCard, 16, -267, L.FRAME_ANCHOR)
    panel.FrameAnchorDropdown = CreateDropdown(generalCard, 245, -250, 285, L.FRAME_ANCHOR)
    panel.FrameAnchorDropdown:SetupMenu(function(_, rootDescription)
        local labels = {
            TOPLEFT = L.ANCHOR_TOPLEFT,
            TOP = L.ANCHOR_TOP,
            TOPRIGHT = L.ANCHOR_TOPRIGHT,
            LEFT = L.ANCHOR_LEFT,
            CENTER = L.ANCHOR_CENTER,
            RIGHT = L.ANCHOR_RIGHT,
            BOTTOMLEFT = L.ANCHOR_BOTTOMLEFT,
            BOTTOM = L.ANCHOR_BOTTOM,
            BOTTOMRIGHT = L.ANCHOR_BOTTOMRIGHT,
        }
        local function IsSelected(anchor)
            return addon:GetMainFrameAnchor() == anchor
        end
        local function SetSelected(anchor)
            if not addon:SetMainFrameAnchor(anchor) then
                addon:RefreshConfigurationPanel()
            end
        end
        for _, anchor in ipairs(addon.FRAME_ANCHORS) do
            rootDescription:CreateRadio(labels[anchor] or anchor, IsSelected, SetSelected, anchor)
        end
    end)

    local resetButton = CreateFrame("Button", nil, generalCard, "UIPanelButtonTemplate")
    resetButton:SetSize(150, 24)
    resetButton:SetPoint("BOTTOMRIGHT", generalCard, "BOTTOMRIGHT", -14, 14)
    resetButton:SetText(L.RESET_POSITION)
    resetButton:SetScript("OnClick", function()
        addon:ResetMainFramePosition()
    end)

    local partyCard = CreateCard(content, -656, 350, L.SECTION_PARTY)
    panel.TestCheckbox = CreateCheckbox(partyCard, -42, L.TEST_MODE, function(checked)
        if not addon:SetTestMode(checked) then
            addon:Print(L.TEST_COMBAT)
            addon:RefreshConfigurationPanel()
        end
    end)
    panel.NamesCheckbox = CreateCheckbox(partyCard, -76, L.SHOW_NAMES, function(checked)
        if not addon:SetDisplayOption("showNames", checked) then addon:RefreshConfigurationPanel() end
    end)
    panel.PartyRoleIconsCheckbox = CreateCheckbox(partyCard, -110, L.SHOW_PARTY_ROLE_ICONS, function(checked)
        if not addon:SetPartyRoleIconsVisible(checked) then addon:RefreshConfigurationPanel() end
    end)
    panel.HorizontalCheckbox = CreateCheckbox(partyCard, -144, L.HORIZONTAL_LAYOUT, function(checked)
        if not addon:SetDisplayOption("horizontal", checked) then addon:RefreshConfigurationPanel() end
    end)

    CreateFieldLabel(partyCard, 16, -187, L.PARTY_FRAME_SCALE)
    panel.PartyScaleSlider = CreateFrame("Frame", nil, partyCard, "MinimalSliderWithSteppersTemplate")
    panel.PartyScaleSlider:SetSize(250, 40)
    panel.PartyScaleSlider:SetPoint("TOPLEFT", partyCard, "TOPLEFT", 260, -168)
    panel.PartyScaleSlider:Init(
        addon:GetPartyFrameScale(),
        addon.MIN_PARTY_FRAME_SCALE,
        addon.MAX_PARTY_FRAME_SCALE,
        15,
        {
            [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
                return string.format("%d%%", math.floor((value * 100) + 0.5))
            end,
            [MinimalSliderWithSteppersMixin.Label.Min] = function()
                return "50%"
            end,
            [MinimalSliderWithSteppersMixin.Label.Max] = function()
                return "200%"
            end,
        }
    )
    panel.PartyScaleSlider.Slider:HookScript("OnValueChanged", function(_, value)
        if panel.PartyScaleSlider.ignoreValueChanged then
            return
        end
        local scale = math.floor((value * 10) + 0.5) / 10
        if math.abs(scale - addon:GetPartyFrameScale()) > 0.001 then
            addon:SetPartyFrameScale(scale)
        end
    end)

    CreateFieldLabel(partyCard, 16, -230, L.AURA_COUNT)
    panel.AuraCountSlider = CreateFrame("Frame", nil, partyCard, "MinimalSliderWithSteppersTemplate")
    panel.AuraCountSlider:SetSize(250, 40)
    panel.AuraCountSlider:SetPoint("TOPLEFT", partyCard, "TOPLEFT", 260, -211)
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

    CreateFieldLabel(partyCard, 16, -273, L.AURA_GROWTH)
    panel.AuraGrowthDropdown = CreateDropdown(partyCard, 245, -256, 285, L.AURA_GROWTH)
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

    panel.ShowAurasCheckbox = CreateCheckbox(partyCard, -310, L.SHOW_AURAS, function(checked)
        if not addon:SetAuraIconsVisible(checked) then addon:RefreshConfigurationPanel() end
    end)

    local clickCard = CreateCard(content, -356, 284, L.SECTION_SPELLS)
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
    panel.SettingsContent = content
    panel.GeneralSettingsCard = generalCard
    panel.SpellSettingsCard = clickCard
    panel.PartySettingsCard = partyCard
    self.settingsCategoryID = category:GetID()
    self:LayoutConfigurationCards()
    self:RefreshConfigurationPanel()
end

function addon:OpenConfiguration()
    if self.settingsCategoryID then
        Settings.OpenToCategory(self.settingsCategoryID)
    end
end
