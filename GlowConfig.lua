local addonName, addon = ...
local L = addon.L

local colorPickerHooked = false

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

local function SetColorPickerOnHide(callback)
    if not colorPickerHooked then
        ColorPickerFrame:HookScript("OnHide", function(frame)
            local handler = frame.LafeeDecurseGlowOnHide
            frame.LafeeDecurseGlowOnHide = nil
            if handler then
                handler()
            end
        end)
        colorPickerHooked = true
    end
    ColorPickerFrame.LafeeDecurseGlowOnHide = callback
end

local function CreateGlowColorButton(card, y)
    local button = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    button:SetSize(220, 26)
    button:SetPoint("TOPLEFT", card, "TOPLEFT", 16, y)

    local swatch = button:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(18, 18)
    swatch:SetPoint("LEFT", button, "LEFT", 5, 0)
    button.Swatch = swatch

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    label:SetText(L.GLOW_COLOR)

    button:SetScript("OnClick", function()
        local color = addon:GetAuraGlowColor()
        local oldR, oldG, oldB = color.r, color.g, color.b
        local selectedR, selectedG, selectedB = oldR, oldG, oldB
        local cancelled = false

        local function PreviewColor()
            selectedR, selectedG, selectedB = ColorPickerFrame:GetColorRGB()
            button.Swatch:SetColorTexture(selectedR, selectedG, selectedB, 1)
        end

        local function CancelColor()
            cancelled = true
            button.Swatch:SetColorTexture(oldR, oldG, oldB, 1)
        end

        SetColorPickerOnHide(function()
            if cancelled then
                addon:RefreshGlowConfigurationPanel()
                return
            end
            addon:SetAuraGlowColor(selectedR, selectedG, selectedB)
        end)

        ColorPickerFrame:SetupColorPickerAndShow({
            r = oldR,
            g = oldG,
            b = oldB,
            hasOpacity = false,
            swatchFunc = PreviewColor,
            cancelFunc = CancelColor,
        })
    end)
    return button
end

local function FindSettingsContent(panel)
    local children = { panel:GetChildren() }
    for _, child in ipairs(children) do
        if child.GetScrollChild then
            local content = child:GetScrollChild()
            if content then
                return content
            end
        end
    end
end

local function RefreshDropdown(dropdown)
    if dropdown and dropdown.GenerateMenu then
        dropdown:GenerateMenu()
    end
end

function addon:RefreshGlowConfigurationPanel()
    local panel = self.configurationPanel
    if not panel or not panel.GlowSettingsCard then
        return
    end

    RefreshDropdown(panel.GlowStyleDropdown)

    if panel.AuraGlowCheckbox then
        panel.AuraGlowCheckbox:SetChecked(not self.db or self.db.auraGlow ~= false)
    end

    local color = self:GetAuraGlowColor()
    panel.GlowColorButton.Swatch:SetColorTexture(color.r, color.g, color.b, 1)

    panel.GlowSpeedSlider.ignoreValueChanged = true
    panel.GlowSpeedSlider:SetValue(self:GetAuraGlowSpeed())
    panel.GlowSpeedSlider.ignoreValueChanged = nil

    panel.GlowThicknessSlider.ignoreValueChanged = true
    panel.GlowThicknessSlider:SetValue(self:GetAuraGlowThickness())
    panel.GlowThicknessSlider.ignoreValueChanged = nil
end

local OriginalRefreshConfigurationPanel = addon.RefreshConfigurationPanel
function addon:RefreshConfigurationPanel()
    OriginalRefreshConfigurationPanel(self)
    self:RefreshGlowConfigurationPanel()
end

local OriginalCreateConfigurationPanel = addon.CreateConfigurationPanel
function addon:CreateConfigurationPanel()
    OriginalCreateConfigurationPanel(self)

    local panel = self.configurationPanel
    if not panel or panel.GlowSettingsCard then
        return
    end

    local content = FindSettingsContent(panel)
    if not content then
        return
    end

    local card = CreateCard(content, 0, 304, L.SECTION_GLOW or L.AURA_GLOW)
    panel.GlowSettingsCard = card

    local glowCheckbox = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
    glowCheckbox:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -42)
    glowCheckbox:SetScript("OnClick", function(self)
        if not addon:SetAuraGlowEnabled(self:GetChecked() == true) then
            addon:RefreshConfigurationPanel()
        end
    end)

    local glowLabel = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    glowLabel:SetPoint("LEFT", glowCheckbox, "RIGHT", 4, 0)
    glowLabel:SetText(L.AURA_GLOW)
    panel.AuraGlowCheckbox = glowCheckbox

    CreateFieldLabel(card, 16, -95, L.GLOW_STYLE)
    panel.GlowStyleDropdown = CreateDropdown(card, 245, -78, 285, L.GLOW_STYLE)
    panel.GlowStyleDropdown:SetupMenu(function(_, rootDescription)
        local options = {
            { value = addon.GLOW_STYLE_PULSE, text = L.GLOW_STYLE_PULSE },
            { value = addon.GLOW_STYLE_ANTS, text = L.GLOW_STYLE_ANTS },
            { value = addon.GLOW_STYLE_SOLID, text = L.GLOW_STYLE_SOLID },
        }
        local function IsSelected(value)
            return addon:GetAuraGlowStyle() == value
        end
        local function SetSelected(value)
            if not addon:SetAuraGlowStyle(value) then
                addon:RefreshConfigurationPanel()
            end
        end
        for _, option in ipairs(options) do
            rootDescription:CreateRadio(option.text, IsSelected, SetSelected, option.value)
        end
    end)

    panel.GlowColorButton = CreateGlowColorButton(card, -128)

    CreateFieldLabel(card, 16, -179, L.GLOW_SPEED)
    panel.GlowSpeedSlider = CreateFrame("Frame", nil, card, "MinimalSliderWithSteppersTemplate")
    panel.GlowSpeedSlider:SetSize(250, 40)
    panel.GlowSpeedSlider:SetPoint("TOPLEFT", card, "TOPLEFT", 260, -160)
    panel.GlowSpeedSlider:Init(
        addon:GetAuraGlowSpeed(),
        addon.MIN_AURA_GLOW_SPEED,
        addon.MAX_AURA_GLOW_SPEED,
        26,
        {
            [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
                return string.format("%.2f s", value)
            end,
            [MinimalSliderWithSteppersMixin.Label.Min] = function()
                return "0.20"
            end,
            [MinimalSliderWithSteppersMixin.Label.Max] = function()
                return "1.50"
            end,
        }
    )
    panel.GlowSpeedSlider.Slider:HookScript("OnValueChanged", function(_, value)
        if panel.GlowSpeedSlider.ignoreValueChanged then
            return
        end
        local speed = math.floor((value * 20) + 0.5) / 20
        if math.abs(speed - addon:GetAuraGlowSpeed()) > 0.001 then
            addon:SetAuraGlowSpeed(speed)
        end
    end)

    CreateFieldLabel(card, 16, -238, L.GLOW_THICKNESS)
    panel.GlowThicknessSlider = CreateFrame("Frame", nil, card, "MinimalSliderWithSteppersTemplate")
    panel.GlowThicknessSlider:SetSize(250, 40)
    panel.GlowThicknessSlider:SetPoint("TOPLEFT", card, "TOPLEFT", 260, -219)
    panel.GlowThicknessSlider:Init(
        addon:GetAuraGlowThickness(),
        addon.MIN_AURA_GLOW_THICKNESS,
        addon.MAX_AURA_GLOW_THICKNESS,
        addon.MAX_AURA_GLOW_THICKNESS - addon.MIN_AURA_GLOW_THICKNESS,
        {
            [MinimalSliderWithSteppersMixin.Label.Right] = function(value)
                return tostring(math.floor(value + 0.5)) .. " px"
            end,
            [MinimalSliderWithSteppersMixin.Label.Min] = function()
                return tostring(addon.MIN_AURA_GLOW_THICKNESS)
            end,
            [MinimalSliderWithSteppersMixin.Label.Max] = function()
                return tostring(addon.MAX_AURA_GLOW_THICKNESS)
            end,
        }
    )
    panel.GlowThicknessSlider.Slider:HookScript("OnValueChanged", function(_, value)
        if panel.GlowThicknessSlider.ignoreValueChanged then
            return
        end
        local thickness = math.floor(value + 0.5)
        if thickness ~= addon:GetAuraGlowThickness() then
            addon:SetAuraGlowThickness(thickness)
        end
    end)

    self:LayoutConfigurationCards()
    self:RefreshGlowConfigurationPanel()
end
