local addonName, addon = ...
local L = addon.L

local eventFrame = CreateFrame("Frame")

local CLICK_NAMES = { L.CLICK_LEFT, L.CLICK_RIGHT, L.CLICK_MIDDLE }

addon.DEFAULT_BACKGROUND_COLOR = { r = 0.07, g = 0.08, b = 0.10, a = 0.92 }
addon.BACKGROUND_MODE_FULL = "full"
addon.BACKGROUND_MODE_FRAMES = "frames"
addon.BACKGROUND_MODE_NONE = "none"

local function InitializeSavedVariables()
    LafeeDecurseDB = LafeeDecurseDB or {}
    LafeeDecurseDB.minimap = LafeeDecurseDB.minimap or { hide = false, angle = 220 }
    if LafeeDecurseDB.showTitle == nil then LafeeDecurseDB.showTitle = true end
    if LafeeDecurseDB.showNames == nil then LafeeDecurseDB.showNames = true end
    if LafeeDecurseDB.backgroundMode ~= addon.BACKGROUND_MODE_FULL
        and LafeeDecurseDB.backgroundMode ~= addon.BACKGROUND_MODE_FRAMES
        and LafeeDecurseDB.backgroundMode ~= addon.BACKGROUND_MODE_NONE
    then
        LafeeDecurseDB.backgroundMode = LafeeDecurseDB.showBackground == false
            and addon.BACKGROUND_MODE_NONE
            or addon.BACKGROUND_MODE_FULL
    end
    if LafeeDecurseDB.useClassColors == nil then LafeeDecurseDB.useClassColors = false end
    if LafeeDecurseDB.horizontal == nil then LafeeDecurseDB.horizontal = false end
    if LafeeDecurseDB.testMode == nil then LafeeDecurseDB.testMode = false end

    local default = addon.DEFAULT_BACKGROUND_COLOR
    local color = LafeeDecurseDB.backgroundColor
    if type(color) ~= "table" then
        LafeeDecurseDB.backgroundColor = { r = default.r, g = default.g, b = default.b, a = default.a }
    else
        color.r = tonumber(color.r) or default.r
        color.g = tonumber(color.g) or default.g
        color.b = tonumber(color.b) or default.b
        color.a = tonumber(color.a) or default.a
    end
end

local function ApplySavedConfiguration()
    addon.mainFrame:EnableMouse(not LafeeDecurseDB.locked)
    addon.mainFrame:SetShown(not LafeeDecurseDB.frameHidden)
    addon:ApplyDisplaySettings()
    addon:SetTestMode(LafeeDecurseDB.testMode)
    if addon.minimapButton then
        addon.minimapButton:SetShown(not LafeeDecurseDB.minimap.hide)
    end
    addon:RefreshConfigurationPanel()
end

local function SavePosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    LafeeDecurseDB.position = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

function addon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff8de5ffLafee Decurse:|r " .. tostring(message))
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "LafeeDecurseFrame", UIParent)
    frame:SetSize(130, 175)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(not LafeeDecurseDB.locked)
    frame:RegisterForDrag("LeftButton")

    local position = LafeeDecurseDB.position
    if position then
        frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", -260, 0)
    end

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.025, 0.03, 0.04, 0.94)
    frame.Background = background

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -5)
    title:SetText("Lafee Decurse")
    frame.TitleText = title

    frame:SetScript("OnDragStart", function(self)
        if LafeeDecurseDB.locked or InCombatLockdown() then
            return
        end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)

    addon.mainFrame = frame
    frame:SetShown(not LafeeDecurseDB.frameHidden)
    return frame
end

function addon:SetLocked(locked)
    if InCombatLockdown() then
        self:Print(L.LOCK_COMBAT)
        return false
    end

    LafeeDecurseDB.locked = locked == true
    self.mainFrame:EnableMouse(not LafeeDecurseDB.locked)
    self:Print(LafeeDecurseDB.locked and L.FRAME_LOCKED or L.FRAME_UNLOCKED)
    self:RefreshConfigurationPanel()
    return true
end

function addon:ResetMainFramePosition()
    if InCombatLockdown() then
        self:Print(L.POSITION_COMBAT)
        return false
    end

    LafeeDecurseDB.position = nil
    self.mainFrame:ClearAllPoints()
    self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", -260, 0)
    self:Print(L.POSITION_RESET)
    return true
end

function addon:ToggleMainFrame()
    if InCombatLockdown() then
        self:Print(L.VISIBILITY_COMBAT)
        return false
    end

    local show = LafeeDecurseDB.frameHidden == true
    self.mainFrame:SetShown(show)
    LafeeDecurseDB.frameHidden = not show
    return true
end

local function BuildDispelSignature(dispels)
    local signature = {}
    for index, dispel in ipairs(dispels) do
        signature[index] = tostring(dispel.spellID)
    end
    return table.concat(signature, ":")
end

local function PrintClickAssignments(dispels)
    if #dispels == 0 then
        addon:Print(L.NO_DISPEL)
        return
    end

    local assignments = {}
    for index, dispel in ipairs(dispels) do
        assignments[index] = CLICK_NAMES[index] .. " : " .. dispel.spellName
    end
    addon:Print(table.concat(assignments, " — "))
end

function addon:RefreshDispelConfiguration()
    if InCombatLockdown() then
        self.pendingDispelRefresh = true
        return
    end

    local dispels = self:DetectDispelSpells()
    local combinedTypes = self:GetCombinedDispelTypes(dispels)
    self:ApplyDispelSpells(dispels)
    self:ApplyAuraDispelTypes(combinedTypes)
    self.pendingDispelRefresh = nil

    local signature = BuildDispelSignature(dispels)
    if signature ~= self.dispelSignature then
        self.dispelSignature = signature
        PrintClickAssignments(dispels)
    end
    self:RefreshConfigurationPanel()
end

local function InitializeAddon()
    if addon.initialized then
        return
    end
    if InCombatLockdown() then
        addon.pendingInitialization = true
        return
    end

    InitializeSavedVariables()
    local mainFrame = CreateMainFrame()
    if not addon:CreateSecureUnitButtons(mainFrame) then
        return
    end

    local dispels = addon:DetectDispelSpells()
    local combinedTypes = addon:GetCombinedDispelTypes(dispels)
    addon:ApplyDispelSpells(dispels)
    if not addon:CreateAuraDisplays(combinedTypes) then
        addon:Print(L.AURA_DISPLAY_FAILED)
    end

    addon.activeDispels = dispels
    addon.dispelSignature = BuildDispelSignature(dispels)
    addon:CreateMinimapButton()
    addon:CreateConfigurationPanel()
    ApplySavedConfiguration()
    addon.initialized = true
    addon.pendingInitialization = nil

    PrintClickAssignments(dispels)
end

local function HandleSlashCommand(input)
    if not addon.initialized then
        addon:Print(L.INIT_DEFERRED)
        return
    end

    local command = strtrim(input or ""):lower()
    if command == "lock" then
        addon:SetLocked(not LafeeDecurseDB.locked)
    elseif command == "config" then
        addon:OpenConfiguration()
    elseif command == "minimap" then
        addon:SetMinimapVisible(LafeeDecurseDB.minimap.hide)
    elseif command == "test" then
        local enabled = not LafeeDecurseDB.testMode
        if addon:SetTestMode(enabled) then
            addon:Print(enabled and L.TEST_ENABLED or L.TEST_DISABLED)
        else
            addon:Print(L.TEST_COMBAT)
        end
    else
        addon:Print(L.HELP_LOCK)
        addon:Print(L.HELP_TEST)
        addon:Print(L.HELP_CONFIG)
        addon:Print(L.HELP_MINIMAP)
    end
end

SLASH_LAFEEDECURSE1 = "/ldec"
SlashCmdList.LAFEEDECURSE = HandleSlashCommand

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_NAME_UPDATE")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("ROLE_CHANGED_INFORM")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            InitializeAddon()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        if not addon.initialized then
            InitializeAddon()
        end
        if addon.initialized then
            ApplySavedConfiguration()
            addon:RefreshDispelConfiguration()
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if addon.pendingInitialization then
            InitializeAddon()
        end
        if addon.initialized and addon.pendingDispelRefresh then
            addon:RefreshDispelConfiguration()
        end
        if addon.initialized and addon.pendingNameRefresh then
            addon.pendingNameRefresh = nil
            addon:UpdateUnitNames()
        end
        if addon.initialized and addon.pendingDisplayRefresh then
            addon.pendingDisplayRefresh = nil
            addon:ApplyDisplaySettings()
        end
        return
    end

    if not addon.initialized then
        return
    end

    if event == "GROUP_ROSTER_UPDATE"
        or event == "UNIT_NAME_UPDATE"
        or event == "PLAYER_ROLES_ASSIGNED"
        or event == "ROLE_CHANGED_INFORM"
    then
        addon:UpdateUnitNames()
    else
        addon:RefreshDispelConfiguration()
    end
end)
