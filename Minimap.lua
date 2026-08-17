local addonName, addon = ...
local L = addon.L

local MINIMAP_RADIUS = 80

local function UpdatePosition(button)
    local angle = math.rad(LafeeDecurseDB.minimap.angle or 220)
    button:ClearAllPoints()
    button:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(angle) * MINIMAP_RADIUS,
        math.sin(angle) * MINIMAP_RADIUS
    )
end

local function UpdateDragPosition(button)
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local centerX, centerY = Minimap:GetCenter()
    local angle = math.deg(math.atan2((cursorY / scale) - centerY, (cursorX / scale) - centerX))
    LafeeDecurseDB.minimap.angle = angle
    UpdatePosition(button)
end

function addon:SetMinimapVisible(visible)
    LafeeDecurseDB.minimap.hide = not visible
    if self.minimapButton then
        self.minimapButton:SetShown(visible)
    end
    self:RefreshConfigurationPanel()
end

function addon:CreateMinimapButton()
    -- Keep the button as a Minimap child so managers such as WindTools can
    -- include it in their minimap-button bar.
    local button = CreateFrame("Button", "LafeeDecurseMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\Spell_Holy_DispelMagic")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            addon:ToggleMainFrame()
        elseif mouseButton == "RightButton" then
            addon:OpenConfiguration()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", UpdateDragPosition)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Lafee Decurse", 0.55, 0.90, 1)
        GameTooltip:AddLine(L.MINIMAP_TOGGLE, 1, 1, 1)
        GameTooltip:AddLine(L.MINIMAP_CONFIG, 1, 1, 1)
        GameTooltip:AddLine(L.MINIMAP_DRAG, 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    self.minimapButton = button
    UpdatePosition(button)
    button:SetShown(not LafeeDecurseDB.minimap.hide)
end
