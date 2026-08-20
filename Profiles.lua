local _, addon = ...

local SCHEMA_VERSION = 2
local ROOT_KEYS = {
    profiles = true,
    schemaVersion = true,
    -- Legacy roots kept here only so the compatibility proxy never redirects
    -- them into an active profile while a migration is in progress.
    characterProfiles = true,
    profileVersion = true,
}

local function CopyValue(value, seen)
    if type(value) ~= "table" then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[CopyValue(key, seen)] = CopyValue(child, seen)
    end
    return copy
end

local function CopyMissing(target, source)
    if type(source) ~= "table" then
        return
    end

    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = CopyValue(value)
        end
    end
end

local function GetCharacterKey()
    local guid = UnitGUID("player")
    if guid then
        return guid
    end

    local name = UnitName("player") or "player"
    local realm = GetRealmName() or "realm"
    return name .. "-" .. realm
end

local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then
        return 0
    end

    return GetSpecializationInfo(specIndex) or 0
end

local function EnsureCharacterProfiles(profiles, characterKey)
    local characterProfiles = profiles[characterKey]
    if type(characterProfiles) ~= "table" then
        characterProfiles = {}
        profiles[characterKey] = characterProfiles
    end
    return characterProfiles
end

local function EnsureSpecProfile(profiles, characterKey, specID)
    local characterProfiles = EnsureCharacterProfiles(profiles, characterKey)
    local profile = characterProfiles[specID]
    if type(profile) ~= "table" then
        -- A profile created before specialization data was available is kept as
        -- slot 0. Adopt it when the real specialization becomes known.
        if specID ~= 0 and type(characterProfiles[0]) == "table" then
            profile = characterProfiles[0]
            characterProfiles[0] = nil
        else
            profile = {}
        end
        characterProfiles[specID] = profile
    end
    return profile
end

local function LooksLikeSpecMap(value)
    if type(value) ~= "table" then
        return false
    end

    for key, child in pairs(value) do
        if type(key) == "number" and type(child) == "table" then
            return true
        end
    end
    return false
end

local function CollectLegacyGlobalSettings(root)
    local settings = {}
    for key, value in pairs(root) do
        if not ROOT_KEYS[key] then
            settings[key] = CopyValue(value)
        end
    end
    return settings
end

local function CopyLegacyActionProfile(target, legacyActionProfile)
    if type(legacyActionProfile) ~= "table" then
        return
    end

    if target.clickSpells == nil then
        target.clickSpells = CopyValue(legacyActionProfile.clickSpells or {})
    end
    if target.cooldownBars == nil then
        target.cooldownBars = CopyValue(legacyActionProfile.cooldownBars or {})
    end
    if target.clickActionsInitialized == nil then
        target.clickActionsInitialized = legacyActionProfile.clickActionsInitialized == true
            or legacyActionProfile.initialized == true
    end
end

local function MigrateLegacyStorage(root)
    local legacyGlobalSettings = CollectLegacyGlobalSettings(root)
    local legacyCharacterSettings = rawget(root, "profiles")
    local legacyActionProfiles = rawget(root, "characterProfiles")
    local profiles = {}

    -- Main before PR #7 stored all display settings globally and click actions
    -- separately at character/spec level. The first PR #7 draft briefly stored
    -- display settings per character. Support both shapes so testers do not lose
    -- anything while this branch evolves.
    if type(legacyActionProfiles) == "table" then
        for characterKey, specs in pairs(legacyActionProfiles) do
            if type(specs) == "table" then
                local characterSettings = type(legacyCharacterSettings) == "table"
                    and legacyCharacterSettings[characterKey]
                    or nil
                if LooksLikeSpecMap(characterSettings) then
                    characterSettings = nil
                end

                for specID, legacyActionProfile in pairs(specs) do
                    if type(specID) == "number" and type(legacyActionProfile) == "table" then
                        local target = EnsureSpecProfile(profiles, characterKey, specID)
                        CopyMissing(target, characterSettings or legacyGlobalSettings)
                        CopyLegacyActionProfile(target, legacyActionProfile)
                    end
                end
            end
        end
    end

    if type(legacyCharacterSettings) == "table" then
        for characterKey, oldProfile in pairs(legacyCharacterSettings) do
            if LooksLikeSpecMap(oldProfile) then
                for specID, oldSpecProfile in pairs(oldProfile) do
                    if type(specID) == "number" and type(oldSpecProfile) == "table" then
                        CopyMissing(EnsureSpecProfile(profiles, characterKey, specID), oldSpecProfile)
                    end
                end
            elseif type(oldProfile) == "table" then
                local characterProfiles = EnsureCharacterProfiles(profiles, characterKey)
                if next(characterProfiles) == nil then
                    characterProfiles[0] = CopyValue(oldProfile)
                else
                    for _, target in pairs(characterProfiles) do
                        CopyMissing(target, oldProfile)
                    end
                end
            end
        end
    end

    local currentCharacter = GetCharacterKey()
    local currentSpec = GetCurrentSpecID()
    local currentProfile = EnsureSpecProfile(profiles, currentCharacter, currentSpec)
    local oldCurrentSettings = type(legacyCharacterSettings) == "table"
        and legacyCharacterSettings[currentCharacter]
        or nil
    if not LooksLikeSpecMap(oldCurrentSettings) then
        CopyMissing(currentProfile, oldCurrentSettings or legacyGlobalSettings)
    end

    for key in pairs(legacyGlobalSettings) do
        rawset(root, key, nil)
    end
    rawset(root, "profiles", profiles)
    rawset(root, "characterProfiles", nil)
    rawset(root, "profileVersion", nil)
    rawset(root, "schemaVersion", SCHEMA_VERSION)

    return profiles
end

local function InstallCompatibilityProxy(root)
    setmetatable(root, {
        __index = function(_, key)
            local profile = addon.db
            return profile and profile[key] or nil
        end,
        __newindex = function(tableObject, key, value)
            if ROOT_KEYS[key] then
                rawset(tableObject, key, value)
                return
            end

            local profile = addon.db
            if profile then
                profile[key] = value
            else
                rawset(tableObject, key, value)
            end
        end,
    })
end

function addon:GetCurrentCharacterKey()
    return GetCharacterKey()
end

function addon:GetCurrentSpecID()
    return GetCurrentSpecID()
end

function addon:GetCurrentProfile()
    return self.db
end

function addon:ActivateCurrentProfile()
    local root = self.dbRoot or LafeeDecurseDB
    if type(root) ~= "table" then
        return nil
    end

    local profiles = rawget(root, "profiles")
    if type(profiles) ~= "table" then
        profiles = {}
        rawset(root, "profiles", profiles)
    end

    local characterKey = GetCharacterKey()
    local specID = GetCurrentSpecID()
    local profile = EnsureSpecProfile(profiles, characterKey, specID)

    self.dbRoot = root
    self.db = profile
    self.profileKey = characterKey
    self.profileSpecID = specID
    self.currentActionProfile = nil
    return profile
end

function addon:InitializeProfileStorage()
    LafeeDecurseDB = type(LafeeDecurseDB) == "table" and LafeeDecurseDB or {}
    local root = LafeeDecurseDB

    -- SavedVariables do not persist metatables, but remove any in-session proxy
    -- before examining raw legacy keys during a reload/migration path.
    setmetatable(root, nil)

    if rawget(root, "schemaVersion") ~= SCHEMA_VERSION
        or type(rawget(root, "profiles")) ~= "table"
    then
        MigrateLegacyStorage(root)
    end

    self.dbRoot = root
    InstallCompatibilityProxy(root)
    return self:ActivateCurrentProfile()
end
