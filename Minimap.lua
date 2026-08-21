local addonName, addon = ...
local L = addon.L

local BROKER_NAME = "LafeeDecurse"
local ICON_TEXTURE = "Interface\\Icons\\Spell_Holy_DispelMagic"
local MINIMAP_RADIUS = 80

local fallbackButton
local brokerDataObject
local brokerIconLib
local brokerBoundDB
local brokerRegistered = false
local minimapInitialized = false

local function GetMinimapDB()
    local profile = addon.db
    if not profile then
        return nil
    end

    profile.minimap = type(profile.minimap) == "table" and profile.minimap or {}
    local db = profile.minimap

    if db.hide == nil then
        db.hide = false
    end

    -- LibDBIcon stores its angle in minimapPos. Preserve the position used by
    -- older Lafee Decurse profiles and keep angle for the standalone fallback.
    if tonumber(db.minimapPos) == nil then
        db.minimapPos = tonumber(db.angle) or 220
    end
    if tonumber(db.angle) == nil then
        db.angle = tonumber(db.minimapPos) or 220
    end

    return db
end

local function HandleClick(_, mouseButton)
    if mouseButton == "LeftButton" then
        addon:ToggleMainFrame()
    elseif mouseButton == "RightButton" then
        addon:OpenConfiguration()
    end
end

local function PopulateTooltip(tooltip)
    if not tooltip or not tooltip.AddLine then
        return
    end

    tooltip:AddLine("Lafee Decurse", 0.55, 0.90, 1)
    tooltip:AddLine(L.MINIMAP_TOGGLE, 1, 1, 1)
    tooltip:AddLine(L.MINIMAP_CONFIG, 1, 1, 1)
    tooltip:AddLine(L.MINIMAP_DRAG, 0.7, 0.7, 0.7)
end

local function UpdateFallbackPosition(button)
    local db = GetMinimapDB()
    if not db then
        return
    end

    local angle = math.rad(tonumber(db.minimapPos) or tonumber(db.angle) or 220)
    button:ClearAllPoints()
    button:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(angle) * MINIMAP_RADIUS,
        math.sin(angle) * MINIMAP_RADIUS
    )
end

local function UpdateFallbackDragPosition(button)
    local db = GetMinimapDB()
    if not db then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local centerX, centerY = Minimap:GetCenter()
    if not centerX or not centerY or not scale or scale == 0 then
        return
    end

    local angle = math.deg(math.atan2((cursorY / scale) - centerY, (cursorX / scale) - centerX)) % 360
    db.minimapPos = angle
    db.angle = angle
    UpdateFallbackPosition(button)
end

local function CreateFallbackButton()
    if fallbackButton then
        return fallbackButton
    end

    -- Standalone fallback: Lafee Decurse must keep working with no LibStub,
    -- LibDataBroker, LibDBIcon, ElvUI, or any other third-party addon loaded.
    local button = CreateFrame("Button", "LafeeDecurseMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture(ICON_TEXTURE)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button:SetScript("OnClick", HandleClick)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", UpdateFallbackDragPosition)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        PopulateTooltip(GameTooltip)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    fallbackButton = button
    UpdateFallbackPosition(button)
    return button
end

local function GetOptionalBrokerLibraries()
    local libStub = _G.LibStub
    if not libStub then
        return nil, nil
    end

    local ldb = libStub("LibDataBroker-1.1", true)
    local dbIcon = libStub("LibDBIcon-1.0", true)
    return ldb, dbIcon
end

local function EnsureBrokerDataObject(ldb)
    if brokerDataObject then
        return brokerDataObject
    end

    brokerDataObject = ldb:NewDataObject(BROKER_NAME, {
        type = "launcher",
        text = "Lafee Decurse",
        icon = ICON_TEXTURE,
        OnClick = HandleClick,
        OnTooltipShow = PopulateTooltip,
    })
    addon.minimapDataObject = brokerDataObject
    return brokerDataObject
end

local function ApplyBrokerVisibility(db)
    if not brokerRegistered or not brokerIconLib then
        return
    end

    if db.hide then
        brokerIconLib:Hide(BROKER_NAME)
    else
        brokerIconLib:Show(BROKER_NAME)
    end

    local button = brokerIconLib:GetMinimapButton(BROKER_NAME)
    if button then
        addon.minimapButton = button
    end
end

local function TryEnableBrokerIntegration()
    if not minimapInitialized then
        return false
    end

    local db = GetMinimapDB()
    if not db then
        return false
    end

    local ldb, dbIcon = GetOptionalBrokerLibraries()
    if not ldb then
        return false
    end

    local dataObject = EnsureBrokerDataObject(ldb)
    if not dbIcon then
        -- LDB-only displays can still discover the launcher. Keep the native
        -- minimap button as the standalone fallback until LibDBIcon exists.
        return false
    end

    brokerIconLib = dbIcon
    if not dbIcon:IsRegistered(BROKER_NAME) then
        dbIcon:Register(BROKER_NAME, dataObject, db)
    end

    brokerRegistered = dbIcon:IsRegistered(BROKER_NAME)
    if not brokerRegistered then
        return false
    end

    brokerBoundDB = db
    ApplyBrokerVisibility(db)

    if fallbackButton then
        fallbackButton:Hide()
        fallbackButton:EnableMouse(false)
    end

    return true
end

function addon:RefreshMinimapPosition()
    local db = GetMinimapDB()
    if not db then
        return
    end

    if brokerRegistered and brokerIconLib then
        -- Refresh only when the active character/spec profile changes. Re-running
        -- LibDBIcon positioning after every zone transition makes external
        -- minimap-button managers fight the source button unnecessarily.
        if brokerBoundDB ~= db then
            brokerIconLib:Refresh(BROKER_NAME, db)
            brokerBoundDB = db
            ApplyBrokerVisibility(db)
        end

        local button = brokerIconLib:GetMinimapButton(BROKER_NAME)
        if button then
            addon.minimapButton = button
        end
        return
    end

    if TryEnableBrokerIntegration() then
        return
    end

    local button = CreateFallbackButton()
    addon.minimapButton = button
    UpdateFallbackPosition(button)
    button:SetShown(not db.hide)
end

function addon:SetMinimapVisible(visible)
    local db = GetMinimapDB()
    if not db then
        return
    end

    db.hide = not visible

    if brokerRegistered and brokerIconLib then
        ApplyBrokerVisibility(db)
    elseif TryEnableBrokerIntegration() then
        ApplyBrokerVisibility(db)
    else
        local button = CreateFallbackButton()
        addon.minimapButton = button
        button:SetShown(visible)
    end

    self:RefreshConfigurationPanel()
end

function addon:CreateMinimapButton()
    minimapInitialized = true

    local db = GetMinimapDB()
    if not db then
        return
    end

    local button = CreateFallbackButton()
    addon.minimapButton = button
    button:SetShown(not db.hide)

    -- Upgrade immediately when another loaded addon already provides the
    -- optional broker libraries. Otherwise the ADDON_LOADED listener below will
    -- retry as later addons become available.
    TryEnableBrokerIntegration()
end

-- Lafee Decurse intentionally does not bundle LibStub/LDB/LibDBIcon. Some UI
-- suites load those libraries after us, so retry optional integration as addons
-- finish loading. Once LibDBIcon registration succeeds, the listener can stop.
local integrationFrame = CreateFrame("Frame")
integrationFrame:RegisterEvent("ADDON_LOADED")
integrationFrame:RegisterEvent("PLAYER_LOGIN")
integrationFrame:SetScript("OnEvent", function(self, event)
    if minimapInitialized and TryEnableBrokerIntegration() then
        self:UnregisterEvent("ADDON_LOADED")
    end

    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
