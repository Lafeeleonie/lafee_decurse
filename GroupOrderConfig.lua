local _, addon = ...
local L = addon.L

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

local function GetRoleLabel(role)
    if role == "TANK" then
        return _G.TANK or "Tank"
    elseif role == "HEALER" then
        return _G.HEALER or "Healer"
    elseif role == "DAMAGER" then
        return _G.DAMAGER or _G.DAMAGE or "Damage"
    end
    return role or "?"
end

function addon:RefreshGroupOrderConfigurationPanel()
    local panel = self.configurationPanel
    if not panel or not panel.GroupOrderCard then
        return
    end

    for _, dropdown in ipairs(panel.GroupOrderDropdowns or {}) do
        RefreshDropdown(dropdown)
    end
end

local OriginalRefreshConfigurationPanel = addon.RefreshConfigurationPanel
function addon:RefreshConfigurationPanel()
    OriginalRefreshConfigurationPanel(self)
    self:RefreshGroupOrderConfigurationPanel()
end

local OriginalCreateConfigurationPanel = addon.CreateConfigurationPanel
function addon:CreateConfigurationPanel()
    OriginalCreateConfigurationPanel(self)

    local panel = self.configurationPanel
    if not panel or panel.GroupOrderCard then
        return
    end

    local content = FindSettingsContent(panel)
    if not content then
        return
    end

    local card = CreateCard(content, 0, 260, L.SECTION_ROLE or L.SECTION_GROUP_ORDER)
    panel.GroupOrderCard = card

    local description = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", card, "TOPLEFT", 16, -45)
    description:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -45)
    description:SetJustifyH("LEFT")
    description:SetJustifyV("TOP")
    description:SetText(L.GROUP_ORDER_DESC)

    panel.GroupOrderDropdowns = {}
    for slot = 1, #addon.DEFAULT_ROLE_ORDER do
        local slotIndex = slot
        local y = -86 - ((slotIndex - 1) * 45)

        local label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", card, "TOPLEFT", 16, y - 15)
        label:SetWidth(160)
        label:SetJustifyH("LEFT")
        label:SetText(string.format(L.GROUP_ORDER_POSITION, slotIndex))

        local dropdown = CreateFrame("DropdownButton", nil, card, "WowStyle1DropdownTemplate")
        dropdown:SetSize(330, 30)
        dropdown:SetPoint("TOPLEFT", card, "TOPLEFT", 190, y)
        dropdown:SetDefaultText(string.format(L.GROUP_ORDER_POSITION, slotIndex))
        dropdown:SetupMenu(function(_, rootDescription)
            for _, role in ipairs(addon.DEFAULT_ROLE_ORDER) do
                local candidateRole = role
                rootDescription:CreateRadio(
                    GetRoleLabel(candidateRole),
                    function(candidate)
                        return addon:GetRoleOrderRole(slotIndex) == candidate
                    end,
                    function(candidate)
                        if not addon:SetRoleOrderSlot(slotIndex, candidate) then
                            addon:RefreshConfigurationPanel()
                        end
                    end,
                    candidateRole
                )
            end
        end)

        panel.GroupOrderDropdowns[slotIndex] = dropdown
    end

    local resetButton = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    resetButton:SetSize(180, 26)
    resetButton:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -16, 14)
    resetButton:SetText(L.GROUP_ORDER_RESET)
    resetButton:SetScript("OnClick", function()
        if not addon:ResetRoleOrder() then
            addon:RefreshConfigurationPanel()
        end
    end)

    self:LayoutConfigurationCards()
    self:RefreshGroupOrderConfigurationPanel()
end
