local addonName, addon = ...
local L = addon.L

local eventFrame = CreateFrame("Frame")

local CLICK_NAMES = { L.CLICK_LEFT, L.CLICK_RIGHT, L.CLICK_MIDDLE }

addon.DEFAULT_BACKGROUND_COLOR = { r = 0.07, g = 0.08, b = 0.10, a = 0.92 }
addon.BACKGROUND_MODE_FULL = "full"
addon.BACKGROUND_MODE_FRAMES = "frames"
addon.BACKGROUND_MODE_NONE = "none"

local function InitializeSavedVariables()
    local db = addon.db
    if not db then
        return
    end

    db.minimap = type(db.minimap) == "table" and db.minimap or { hide = false, angle = 220 }
    if db.minimap.hide == nil then db.minimap.hide = false end
    db.minimap.angle = tonumber(db.minimap.angle) or 220

    if db.locked == nil then db.locked = false end
    if db.frameHidden == nil then db.frameHidden = false end
    if db.showTitle == nil then db.showTitle = true end
    if db.showNames == nil then db.showNames = true end
    if db.backgroundMode ~= addon.BACKGROUND_MODE_FULL
        and db.backgroundMode ~= addon.BACKGROUND_MODE_FRAMES
        and db.backgroundMode ~= addon.BACKGROUND_MODE_NONE
    then
        db.backgroundMode = db.showBackground == false
            and addon.BACKGROUND_MODE_NONE
            or addon.BACKGROUND_MODE_FULL
    end
    if db.useClassColors == nil then db.useClassColors = false end
    if db.horizontal == nil then db.horizontal = false end
    if db.testMode == nil then db.testMode = false end

    local default = addon.DEFAULT_BACKGROUND_COLOR
    local color = db.backgroundColor
    if type(color) ~= "table" then
        db.backgroundColor = { r = default.r, g = default.g, b = default.b, a = default.a }
    else
        color.r = tonumber(color.r) or default.r
        color.g = tonumber(color.g) or default.g
        color.b = tonumber(color.b) or default.b
        color.a = tonumber(color.a) or default.a
    end

    local auraCount = math.floor(tonumber(db.auraCount) or 3)
    db.auraCount = math.max(1, math.min(addon.MAX_AURA_COUNT or 5, auraCount))
    if db.auraGrowthVertical ~= "LEFT" and db.auraGrowthVertical ~= "RIGHT" then
        db.auraGrowthVertical = "RIGHT"
    end
    if db.auraGrowthHorizontal ~= "UP" and db.auraGrowthHorizontal ~= "DOWN" then
        db.auraGrowthHorizontal = "DOWN"
    end
    if db.showAuras == nil then db.showAuras = true end
    if db.auraGlow == nil then db.auraGlow = true end

    if db.auraGlowStyle ~= addon.GLOW_STYLE_PULSE
        and db.auraGlowStyle ~= addon.GLOW_STYLE_ANTS
        and db.auraGlowStyle ~= addon.GLOW_STYLE_SOLID
    then
        db.auraGlowStyle = addon.GLOW_STYLE_PULSE
    end

    local glowDefault = addon.DEFAULT_AURA_GLOW_COLOR or { r = 0.55, g = 0.90, b = 1.00 }
    local glowColor = db.auraGlowColor
    if type(glowColor) ~= "table" then
        db.auraGlowColor = { r = glowDefault.r, g = glowDefault.g, b = glowDefault.b }
    else
        glowColor.r = math.max(0, math.min(1, tonumber(glowColor.r) or glowDefault.r))
        glowColor.g = math.max(0, math.min(1, tonumber(glowColor.g) or glowDefault.g))
        glowColor.b = math.max(0, math.min(1, tonumber(glowColor.b) or glowDefault.b))
    end

    local minGlowSpeed = addon.MIN_AURA_GLOW_SPEED or 0.20
    local maxGlowSpeed = addon.MAX_AURA_GLOW_SPEED or 1.50
    local glowSpeed = tonumber(db.auraGlowSpeed) or addon.DEFAULT_AURA_GLOW_SPEED or 0.45
    db.auraGlowSpeed = math.max(minGlowSpeed, math.min(maxGlowSpeed, glowSpeed))

    local minThickness = addon.MIN_AURA_GLOW_THICKNESS or 1
    local maxThickness = addon.MAX_AURA_GLOW_THICKNESS or 4
    local thickness = math.floor((tonumber(db.auraGlowThickness) or addon.DEFAULT_AURA_GLOW_THICKNESS or 2) + 0.5)
    db.auraGlowThickness = math.max(minThickness, math.min(maxThickness, thickness))

    db.clickSpells = type(db.clickSpells) == "table" and db.clickSpells or {}
    db.cooldownBars = type(db.cooldownBars) == "table" and db.cooldownBars or {}
end

local function ApplyMainFramePosition()
    local frame = addon.mainFrame
    if not frame then
        return
    end

    local position = addon.db and addon.db.position
    frame:ClearAllPoints()
    if type(position) == "table" and position.point and position.relativePoint then
        frame:SetPoint(
            position.point,
            UIParent,
            position.relativePoint,
            tonumber(position.x) or 0,
            tonumber(position.y) or 0
        )
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", -260, 0)
    end
end

local function ApplySavedConfiguration()
    local db = addon.db
    if not db or not addon.mainFrame then
        return
    end

    addon.mainFrame:EnableMouse(not db.locked)
    addon.mainFrame:SetShown(not db.frameHidden)
    ApplyMainFramePosition()
    addon:ApplyDisplaySettings()
    addon:SetTestMode(db.testMode)
    if addon.minimapButton then
        addon.minimapButton:SetShown(not db.minimap.hide)
    end
    if addon.RefreshMinimapPosition then
        addon:RefreshMinimapPosition()
    end
    if addon.RefreshCooldownBars then
        addon:RefreshCooldownBars()
    end
    addon:RefreshConfigurationPanel()
end

local function SavePosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    addon.db.position = {
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
    frame:EnableMouse(not addon.db.locked)
    frame:RegisterForDrag("LeftButton")

    addon.mainFrame = frame
    ApplyMainFramePosition()

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.025, 0.03, 0.04, 0.94)
    frame.Background = background

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -5)
    title:SetText("Lafee Decurse")
    frame.TitleText = title

    frame:SetScript("OnDragStart", function(self)
        if addon.db.locked or InCombatLockdown() then
            return
        end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)

    frame:SetShown(not addon.db.frameHidden)
    return frame
end

function addon:SetLocked(locked)
    if InCombatLockdown() then
        self:Print(L.LOCK_COMBAT)
        return false
    end

    self.db.locked = locked == true
    self.mainFrame:EnableMouse(not self.db.locked)
    self:Print(self.db.locked and L.FRAME_LOCKED or L.FRAME_UNLOCKED)
    self:RefreshConfigurationPanel()
    return true
end

function addon:ResetMainFramePosition()
    if InCombatLockdown() then
        self:Print(L.POSITION_COMBAT)
        return false
    end

    self.db.position = nil
    ApplyMainFramePosition()
    self:Print(L.POSITION_RESET)
    return true
end

function addon:ToggleMainFrame()
    if InCombatLockdown() then
        self:Print(L.VISIBILITY_COMBAT)
        return false
    end

    local show = self.db.frameHidden == true
    self.mainFrame:SetShown(show)
    self.db.frameHidden = not show
    return true
end

local function BuildClickSignature(spells)
    local signature = {}
    for index = 1, 3 do
        local spell = spells and spells[index]
        signature[index] = spell and tostring(spell.spellID) or "-"
    end
    return table.concat(signature, ":")
end

local function PrintClickAssignments(spells)
    local assignments = {}
    local hasAssignment = false
    for index = 1, 3 do
        local spell = spells and spells[index]
        if spell then
            assignments[#assignments + 1] = CLICK_NAMES[index] .. " : " .. spell.spellName
            hasAssignment = true
        end
    end

    if not hasAssignment then
        addon:Print(L.NO_ACTION or L.NO_DISPEL)
        return
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

    self.activeDispels = dispels
    self.currentActionProfile = nil
    local clickSpells = self:GetConfiguredSpells(dispels)

    self:ApplyClickSpells(clickSpells)
    self:ApplyAuraDispelTypes(combinedTypes)
    self.pendingDispelRefresh = nil

    local signature = BuildClickSignature(clickSpells)
    if signature ~= self.clickSpellSignature then
        self.clickSpellSignature = signature
        PrintClickAssignments(clickSpells)
    end

    if self.RefreshCooldownBars then
        self:RefreshCooldownBars()
    end
    self:RefreshConfigurationPanel()
end

local function ActivateAndApplyCurrentProfile()
    if InCombatLockdown() then
        addon.pendingProfileRefresh = true
        addon.pendingDispelRefresh = true
        return false
    end

    addon:ActivateCurrentProfile()
    InitializeSavedVariables()

    -- Refresh the new specialization's spells before applying appearance. The
    -- display layout also queries cooldown-bar settings, so doing this first
    -- prevents an uninitialized profile from inheriting the previous spec's
    -- detected dispels.
    addon:RefreshDispelConfiguration()
    ApplySavedConfiguration()
    addon.pendingProfileRefresh = nil
    return true
end

local function InitializeAddon()
    if addon.initialized then
        return
    end
    if InCombatLockdown() then
        addon.pendingInitialization = true
        return
    end

    addon:InitializeProfileStorage()
    InitializeSavedVariables()
    local mainFrame = CreateMainFrame()
    if not addon:CreateSecureUnitButtons(mainFrame) then
        return
    end

    local dispels = addon:DetectDispelSpells()
    addon.activeDispels = dispels
    addon.currentActionProfile = nil
    local clickSpells = addon:GetConfiguredSpells(dispels)
    local combinedTypes = addon:GetCombinedDispelTypes(dispels)

    addon:ApplyClickSpells(clickSpells)
    if not addon:CreateAuraDisplays(combinedTypes) then
        addon:Print(L.AURA_DISPLAY_FAILED)
    end

    addon.clickSpellSignature = BuildClickSignature(clickSpells)
    addon:CreateCooldownBars(mainFrame)
    addon:CreateMinimapButton()
    addon:CreateConfigurationPanel()
    ApplySavedConfiguration()
    addon.initialized = true
    addon.pendingInitialization = nil

    PrintClickAssignments(clickSpells)
end

local function HandleSlashCommand(input)
    if not addon.initialized then
        addon:Print(L.INIT_DEFERRED)
        return
    end

    local command = strtrim(input or ""):lower()
    if command == "lock" then
        addon:SetLocked(not addon.db.locked)
    elseif command == "config" then
        addon:OpenConfiguration()
    elseif command == "minimap" then
        addon:SetMinimapVisible(addon.db.minimap.hide)
    elseif command == "test" then
        local enabled = not addon.db.testMode
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
            ActivateAndApplyCurrentProfile()
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if addon.pendingInitialization then
            InitializeAddon()
        end
        if addon.initialized and addon.pendingProfileRefresh then
            ActivateAndApplyCurrentProfile()
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

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit and unit ~= "player" then
            return
        end

        ActivateAndApplyCurrentProfile()
        return
    end

    if event == "GROUP_ROSTER_UPDATE"
        or event == "UNIT_NAME_UPDATE"
        or event == "PLAYER_ROLES_ASSIGNED"
        or event == "ROLE_CHANGED_INFORM"
    then
        addon:UpdateUnitNames()
        return
    end

    if (event == "PLAYER_TALENT_UPDATE" or event == "SPELLS_CHANGED")
        and addon.profileSpecID ~= addon:GetCurrentSpecID()
    then
        ActivateAndApplyCurrentProfile()
    else
        addon:RefreshDispelConfiguration()
    end
end)
