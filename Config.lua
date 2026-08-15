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

function addon:RefreshConfigurationPanel()
    local panel = self.configurationPanel
    if not panel or not LafeeDecurseDB then
        return
    end

    panel.LockCheckbox:SetChecked(LafeeDecurseDB.locked == true)
    panel.MinimapCheckbox:SetChecked(not LafeeDecurseDB.minimap.hide)

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
    local panel = CreateFrame("Frame", "LafeeDecurseConfigurationPanel")
    panel:SetSize(640, 620)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -24)
    title:SetText("Lafee Decurse")
    title:SetTextColor(0.55, 0.90, 1)

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText(L.CONFIG_SUBTITLE)

    local generalCard = CreateCard(panel, -82, 142, L.SECTION_INTERFACE)
    panel.LockCheckbox = CreateCheckbox(generalCard, -42, L.LOCK_FRAME, function(checked)
        if not addon:SetLocked(checked) then
            addon:RefreshConfigurationPanel()
        end
    end)
    panel.MinimapCheckbox = CreateCheckbox(generalCard, -78, L.SHOW_MINIMAP, function(checked)
        addon:SetMinimapVisible(checked)
    end)

    local resetButton = CreateFrame("Button", nil, generalCard, "UIPanelButtonTemplate")
    resetButton:SetSize(150, 24)
    resetButton:SetPoint("BOTTOMRIGHT", generalCard, "BOTTOMRIGHT", -14, 14)
    resetButton:SetText(L.RESET_POSITION)
    resetButton:SetScript("OnClick", function()
        addon:ResetMainFramePosition()
    end)

    local clickCard = CreateCard(panel, -240, 250, L.CLICK_ASSIGNMENTS)
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
