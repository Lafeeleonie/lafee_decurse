local _, addon = ...
local L = addon.L

local BROKER_NAME = "LafeeDecurse"
local ICON_TEXTURE = "Interface\\Icons\\Spell_Holy_DispelMagic"

local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")
local brokerDataObject
local boundDB

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
    if tonumber(db.minimapPos) == nil then
        db.minimapPos = tonumber(db.angle) or 220
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
    tooltip:AddLine("Lafee Decurse", 0.55, 0.90, 1)
    tooltip:AddLine(L.MINIMAP_TOGGLE, 1, 1, 1)
    tooltip:AddLine(L.MINIMAP_CONFIG, 1, 1, 1)
    tooltip:AddLine(L.MINIMAP_DRAG, 0.7, 0.7, 0.7)
end

local function GetDataObject()
    if not brokerDataObject then
        brokerDataObject = LDB:NewDataObject(BROKER_NAME, {
            type = "launcher",
            text = "Lafee Decurse",
            icon = ICON_TEXTURE,
            OnClick = HandleClick,
            OnTooltipShow = PopulateTooltip,
        })
        addon.minimapDataObject = brokerDataObject
    end
    return brokerDataObject
end

local function ApplyVisibility(db)
    if db.hide then
        DBIcon:Hide(BROKER_NAME)
    else
        DBIcon:Show(BROKER_NAME)
    end
end

function addon:RefreshMinimapPosition()
    local db = GetMinimapDB()
    if not db or not DBIcon:IsRegistered(BROKER_NAME) then
        return
    end

    if boundDB ~= db then
        DBIcon:Refresh(BROKER_NAME, db)
        boundDB = db
    end
    addon.minimapButton = DBIcon:GetMinimapButton(BROKER_NAME)
end

function addon:SetMinimapVisible(visible)
    local db = GetMinimapDB()
    if not db then
        return
    end

    db.hide = not visible
    ApplyVisibility(db)
    self:RefreshConfigurationPanel()
end

function addon:CreateMinimapButton()
    local db = GetMinimapDB()
    if not db then
        return
    end

    if not DBIcon:IsRegistered(BROKER_NAME) then
        DBIcon:Register(BROKER_NAME, GetDataObject(), db)
    end
    boundDB = db
    ApplyVisibility(db)
    addon.minimapButton = DBIcon:GetMinimapButton(BROKER_NAME)
end
