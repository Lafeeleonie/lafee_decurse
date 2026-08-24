local _, addon = ...
local L = addon.L

local function CreateRaidSettingsCard(content, panel)
    if panel.RaidSettingsCard then
        return
    end

    local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
    local previousCard = panel.GroupOrderCard or panel.GlowSettingsCard
    if previousCard then
        card:SetPoint("TOPLEFT", previousCard, "BOTTOMLEFT", 0, -16)
        card:SetPoint("TOPRIGHT", previousCard, "BOTTOMRIGHT", 0, -16)
    else
        card:SetPoint("TOPLEFT", content, "TOPLEFT", 24, -904)
        card:SetPoint("TOPRIGHT", content, "TOPRIGHT", -24, -904)
    end
    card:SetHeight(112)
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    card:SetBackdropColor(0.035, 0.045, 0.065, 0.92)
    card:SetBackdropBorderColor(0.16, 0.28, 0.40, 0.95)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -12)
    title:SetText(L.SECTION_RAID or "Raid")
    title:SetTextColor(0.55, 0.90, 1)

    local label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", card, "TOPLEFT", 16, -50)
    label:SetText(L.RAID_GROUP_NUMBER_SIDE or "Raid group number")

    local dropdown = CreateFrame("DropdownButton", nil, card, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", card, "TOPLEFT", 245, -34)
    dropdown:SetWidth(285)
    dropdown:SetDefaultText(L.RAID_GROUP_NUMBER_SIDE or "Raid group number")
    dropdown:SetupMenu(function(_, rootDescription)
        local options = {
            { value = addon.RAID_GROUP_NUMBER_LEFT, text = L.GROWTH_LEFT or "Left" },
            { value = addon.RAID_GROUP_NUMBER_RIGHT, text = L.GROWTH_RIGHT or "Right" },
        }

        local function IsSelected(value)
            return addon:GetRaidGroupNumberSide() == value
        end

        local function SetSelected(value)
            if not addon:SetRaidGroupNumberSide(value) then
                addon:RefreshConfigurationPanel()
            end
        end

        for _, option in ipairs(options) do
            rootDescription:CreateRadio(option.text, IsSelected, SetSelected, option.value)
        end
    end)

    local testCheckbox = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
    testCheckbox:SetPoint("TOPLEFT", card, "TOPLEFT", 14, -72)
    testCheckbox:SetScript("OnClick", function(self)
        if not addon:SetRaidTestMode(self:GetChecked() == true) then
            addon:RefreshConfigurationPanel()
        end
    end)

    local testLabel = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    testLabel:SetPoint("LEFT", testCheckbox, "RIGHT", 4, 0)
    testLabel:SetText(L.RAID_TEST_MODE or "Raid test mode")

    panel.RaidSettingsCard = card
    panel.RaidGroupNumberSideDropdown = dropdown
    panel.RaidTestCheckbox = testCheckbox
end

local function FindSettingsContent(panel)
    for _, child in ipairs({ panel:GetChildren() }) do
        if child:IsObjectType("ScrollFrame") and child.GetScrollChild then
            local content = child:GetScrollChild()
            if content then
                return content
            end
        end
    end
    return nil
end

local BaseCreateConfigurationPanel = addon.CreateConfigurationPanel
function addon:CreateConfigurationPanel(...)
    local result = BaseCreateConfigurationPanel(self, ...)
    local panel = self.configurationPanel
    if panel then
        local content = FindSettingsContent(panel)
        if content then
            content:SetHeight(math.max(content:GetHeight(), 1602))
            CreateRaidSettingsCard(content, panel)
            self:RefreshConfigurationPanel()
        end
    end
    return result
end

local BaseRefreshConfigurationPanel = addon.RefreshConfigurationPanel
function addon:RefreshConfigurationPanel(...)
    local result = BaseRefreshConfigurationPanel(self, ...)
    local panel = self.configurationPanel
    if not panel then
        return result
    end

    local dropdown = panel.RaidGroupNumberSideDropdown
    if dropdown and dropdown.GenerateMenu then
        dropdown:GenerateMenu()
    end

    if panel.RaidTestCheckbox then
        panel.RaidTestCheckbox:SetChecked(self:IsRaidTestModeEnabled())
        panel.RaidTestCheckbox:SetEnabled(not IsInRaid() and not InCombatLockdown())
    end

    return result
end
