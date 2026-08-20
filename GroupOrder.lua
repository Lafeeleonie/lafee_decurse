local _, addon = ...
local L = addon.L

addon.DEFAULT_GROUP_UNITS = { "player", "party1", "party2", "party3", "party4" }
addon.DEFAULT_ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }

local VALID_ROLES = {
    TANK = true,
    HEALER = true,
    DAMAGER = true,
}

local function CopyDefaultRoleOrder()
    local order = {}
    for index, role in ipairs(addon.DEFAULT_ROLE_ORDER) do
        order[index] = role
    end
    return order
end

local function GetProfile()
    return addon.db or LafeeDecurseDB
end

local function GetUnitRole(unit)
    local role = UnitGroupRolesAssigned(unit)
    if role == "NONE" and unit == "player" then
        local specialization = GetSpecialization()
        if specialization then
            role = GetSpecializationRole(specialization)
        end
    end

    if VALID_ROLES[role] then
        return role
    end
    return "NONE"
end

function addon:GetRoleOrder()
    local profile = GetProfile()
    local source = profile and profile.roleOrder
    local order = {}
    local seen = {}

    if type(source) == "table" then
        for index = 1, #self.DEFAULT_ROLE_ORDER do
            local role = source[index]
            if VALID_ROLES[role] and not seen[role] then
                order[#order + 1] = role
                seen[role] = true
            end
        end
    end

    for _, role in ipairs(self.DEFAULT_ROLE_ORDER) do
        if not seen[role] then
            order[#order + 1] = role
            seen[role] = true
        end
    end

    if profile then
        profile.roleOrder = order
        -- The first draft of PR #8 stored a manual fixed-unit order. It is no
        -- longer used now that sorting is role-driven.
        profile.groupOrder = nil
    end
    return order
end

function addon:GetRoleOrderRole(slot)
    return self:GetRoleOrder()[slot]
end

function addon:SetRoleOrderSlot(slot, role)
    if InCombatLockdown() then
        self:Print(L.DISPLAY_COMBAT)
        return false
    end

    slot = tonumber(slot)
    if not slot or slot < 1 or slot > #self.DEFAULT_ROLE_ORDER or not VALID_ROLES[role] then
        return false
    end

    local order = self:GetRoleOrder()
    local currentRole = order[slot]
    if currentRole == role then
        return true
    end

    local otherSlot
    for index, candidate in ipairs(order) do
        if candidate == role then
            otherSlot = index
            break
        end
    end

    order[slot] = role
    if otherSlot then
        order[otherSlot] = currentRole
    end

    local profile = GetProfile()
    if not profile then
        return false
    end
    profile.roleOrder = order

    self:ApplyDisplaySettings()
    return true
end

function addon:ResetRoleOrder()
    if InCombatLockdown() then
        self:Print(L.DISPLAY_COMBAT)
        return false
    end

    local profile = GetProfile()
    if not profile then
        return false
    end

    profile.roleOrder = CopyDefaultRoleOrder()
    self:ApplyDisplaySettings()
    return true
end

function addon:GetOrderedUnitButtons()
    local rolePriority = {}
    for index, role in ipairs(self:GetRoleOrder()) do
        rolePriority[role] = index
    end

    local unitPriority = {}
    for index, unit in ipairs(self.DEFAULT_GROUP_UNITS) do
        unitPriority[unit] = index
    end

    local orderedButtons = {}
    for _, button in ipairs(self.unitButtons or {}) do
        if button.fixedUnit then
            orderedButtons[#orderedButtons + 1] = button
        end
    end

    table.sort(orderedButtons, function(a, b)
        local roleA = GetUnitRole(a.fixedUnit)
        local roleB = GetUnitRole(b.fixedUnit)
        local roleRankA = rolePriority[roleA] or 99
        local roleRankB = rolePriority[roleB] or 99

        if roleRankA ~= roleRankB then
            return roleRankA < roleRankB
        end

        return (unitPriority[a.fixedUnit] or 99) < (unitPriority[b.fixedUnit] or 99)
    end)

    return orderedButtons
end
