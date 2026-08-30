local _, addon = ...

local PARTY_MODE = "party"
local RAID_MODE = "raid"
local ANCHOR_FACTORS = {
    TOPLEFT = { x = 0, y = 1 },
    TOP = { x = 0.5, y = 1 },
    TOPRIGHT = { x = 1, y = 1 },
    LEFT = { x = 0, y = 0.5 },
    CENTER = { x = 0.5, y = 0.5 },
    RIGHT = { x = 1, y = 0.5 },
    BOTTOMLEFT = { x = 0, y = 0 },
    BOTTOM = { x = 0.5, y = 0 },
    BOTTOMRIGHT = { x = 1, y = 0 },
}

addon.FRAME_ANCHORS = {
    "TOPLEFT",
    "TOP",
    "TOPRIGHT",
    "LEFT",
    "CENTER",
    "RIGHT",
    "BOTTOMLEFT",
    "BOTTOM",
    "BOTTOMRIGHT",
}

local DEFAULT_POSITION = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = -260,
    y = 0,
}

local function CopyPosition(position)
    if type(position) ~= "table" or not position.point or not position.relativePoint then
        return nil
    end

    return {
        point = position.point,
        relativePoint = position.relativePoint,
        x = tonumber(position.x) or 0,
        y = tonumber(position.y) or 0,
    }
end

local function DefaultPosition()
    return CopyPosition(DEFAULT_POSITION)
end

local function GetPositionMode()
    if IsInRaid() == true or addon.raidTestMode == true then
        return RAID_MODE
    end
    return PARTY_MODE
end

local function EnsurePositionStorage()
    local db = addon.db
    if type(db) ~= "table" then
        return nil
    end

    if type(db.positions) ~= "table" then
        db.positions = {}
    end

    local positions = db.positions
    local legacy = CopyPosition(db.position)
    if legacy then
        -- Preserve the historical frame position as the party position. The
        -- initial raid position starts at the same coordinates so upgrading the
        -- addon never causes the frame to jump unexpectedly.
        if not CopyPosition(positions.party) then
            positions.party = CopyPosition(legacy)
        end
        if not CopyPosition(positions.raid) then
            positions.raid = CopyPosition(legacy)
        end
        db.position = nil
    end

    positions.party = CopyPosition(positions.party)
    positions.raid = CopyPosition(positions.raid)
    return positions
end

local function GetPositionForMode(mode)
    local positions = EnsurePositionStorage()
    if not positions then
        return DefaultPosition()
    end

    if mode == RAID_MODE and not positions.raid then
        -- New profiles only snapshot a raid position when raid/test mode is
        -- first used. From then on party and raid positions are independent.
        positions.raid = CopyPosition(positions.party) or DefaultPosition()
    end

    return CopyPosition(positions[mode]) or DefaultPosition()
end

local function GetConfiguredAnchor()
    local db = addon.db
    if type(db) ~= "table" then
        return "CENTER"
    end
    if ANCHOR_FACTORS[db.frameAnchor] then
        return db.frameAnchor
    end

    local positions = EnsurePositionStorage()
    local partyPosition = positions and positions.party
    local raidPosition = positions and positions.raid
    local anchor = partyPosition and partyPosition.point
        or raidPosition and raidPosition.point
        or "CENTER"
    db.frameAnchor = ANCHOR_FACTORS[anchor] and anchor or "CENTER"
    return db.frameAnchor
end

local SavePosition

local function ApplyPosition(mode)
    local frame = addon.mainFrame
    if not frame then
        return false
    end

    mode = mode or GetPositionMode()
    local position = GetPositionForMode(mode)
    frame:ClearAllPoints()
    frame:SetPoint(
        position.point,
        UIParent,
        position.relativePoint,
        position.x,
        position.y
    )

    local anchor = GetConfiguredAnchor()
    if position.point ~= anchor or position.relativePoint ~= anchor then
        return SavePosition(frame, mode, anchor)
    end
    return true
end

local function GetAnchoredOffsets(frame, anchor)
    local factor = ANCHOR_FACTORS[anchor]
    if not frame or not factor or not frame.GetRect or not UIParent.GetRect then
        return nil
    end

    local left, bottom, width, height = frame:GetRect()
    local parentLeft, parentBottom, parentWidth, parentHeight = UIParent:GetRect()
    if not left or not bottom or not width or not height
        or not parentLeft or not parentBottom or not parentWidth or not parentHeight
    then
        return nil
    end

    local parentScale = UIParent:GetEffectiveScale()
    local frameScale = frame:GetEffectiveScale()
    local scaleRatio = frameScale / parentScale
    left = left * scaleRatio
    bottom = bottom * scaleRatio
    width = width * scaleRatio
    height = height * scaleRatio

    local anchorX = left + (width * factor.x)
    local anchorY = bottom + (height * factor.y)
    local relativeX = parentLeft + (parentWidth * factor.x)
    local relativeY = parentBottom + (parentHeight * factor.y)
    return anchorX - relativeX, anchorY - relativeY
end

SavePosition = function(frame, mode, anchor)
    local positions = EnsurePositionStorage()
    if not positions or not frame then
        return false
    end

    if ANCHOR_FACTORS[anchor] then
        local x, y = GetAnchoredOffsets(frame, anchor)
        if x and y then
            positions[mode or GetPositionMode()] = {
                point = anchor,
                relativePoint = anchor,
                x = x,
                y = y,
            }
            addon.db.position = nil
            frame:ClearAllPoints()
            frame:SetPoint(anchor, UIParent, anchor, x, y)
            return true
        end
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if not point or not relativePoint then
        return false
    end

    positions[mode or GetPositionMode()] = {
        point = point,
        relativePoint = relativePoint,
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
    }
    addon.db.position = nil
    return true
end

local function InstallDragHandlers()
    local frame = addon.mainFrame
    if not frame or frame.lafeePositionModeDragInstalled then
        return
    end

    frame:SetScript("OnDragStart", function(self)
        if not addon.db or addon.db.locked or InCombatLockdown() then
            return
        end

        addon.positionDragMode = GetPositionMode()
        addon.positionDragAnchor = GetConfiguredAnchor()
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local mode = addon.positionDragMode or GetPositionMode()
        local anchor = addon.positionDragAnchor
        addon.positionDragMode = nil
        addon.positionDragAnchor = nil
        if InCombatLockdown() then
            return
        end

        SavePosition(self, mode, anchor)
    end)

    frame.lafeePositionModeDragInstalled = true
end

function addon:GetMainFramePositionMode()
    return GetPositionMode()
end

function addon:GetMainFrameAnchor()
    return GetConfiguredAnchor()
end

function addon:SetMainFrameAnchor(anchor)
    if InCombatLockdown() then
        self:Print(self.L.POSITION_COMBAT)
        return false
    end
    if not ANCHOR_FACTORS[anchor] or not self.mainFrame then
        return false
    end

    local previousAnchor = GetConfiguredAnchor()
    self.db.frameAnchor = anchor
    if not SavePosition(self.mainFrame, GetPositionMode(), anchor) then
        self.db.frameAnchor = previousAnchor
        return false
    end
    self:RefreshConfigurationPanel()
    return true
end

function addon:ApplyMainFrameModePosition()
    if InCombatLockdown() then
        self.pendingDisplayRefresh = true
        return false
    end

    InstallDragHandlers()
    return ApplyPosition(GetPositionMode())
end

function addon:ResetMainFramePosition()
    if InCombatLockdown() then
        self:Print(self.L.POSITION_COMBAT)
        return false
    end

    local positions = EnsurePositionStorage()
    if not positions then
        return false
    end

    positions[GetPositionMode()] = DefaultPosition()
    self.db.position = nil
    ApplyPosition(GetPositionMode())
    self:Print(self.L.POSITION_RESET)
    return true
end

local BaseApplyDisplaySettings = addon.ApplyDisplaySettings
function addon:ApplyDisplaySettings(...)
    local applied = BaseApplyDisplaySettings(self, ...)
    if applied ~= true or InCombatLockdown() then
        return applied
    end

    -- RaidMode and RaidTestMode have already settled the active presentation by
    -- the time this wrapper runs, so use the matching independent position.
    self:ApplyMainFrameModePosition()
    return true
end
