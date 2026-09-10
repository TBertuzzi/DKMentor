local ADDON_NAME, DKM = ...

-- Meta provider router.
--
-- DK Mentor always ships a reviewed built-in Archon/WCL snapshot in MetaData.lua.
-- If Archon Tooltip (or a compatible bridge) exposes an aggregate DK meta table,
-- DK Mentor can consume it without making HTTP requests.
--
-- The official Archon Tooltip dataset documented today is character/profile
-- oriented. Therefore an installed Archon addon can be detected while DK Mentor
-- still correctly falls back to the built-in aggregate snapshot.
--
-- This module deliberately does not read ArchonTooltipPrivate internals.
local Provider = {
    id = "builtin",
    externalSnapshots = {},
}

local REQUIRED_CONTEXTS = { "raid", "mythicplus", "highkeys" }
local REQUIRED_SPECS = { 250, 251, 252 }
local ARCHON_DB_ADDONS = {
    "ArchonTooltipDB",
    "ArchonTooltipDB_US",
    "ArchonTooltipDB_EU",
    "ArchonTooltipDB_KR",
    "ArchonTooltipDB_TW",
    "ArchonTooltipDB_CN",
}

local function IsFiniteNumber(value)
    value = tonumber(value)
    return value ~= nil and value == value and value ~= math.huge and value ~= -math.huge
end

local function IsNamedAddOnLoaded(name)
    if not name or name == "" then return false end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, name)
        if ok and loaded then return true end
    elseif IsAddOnLoaded then
        local ok, loaded = pcall(IsAddOnLoaded, name)
        if ok and loaded then return true end
    end
    return false
end

local function GetArchonState()
    local coreLoaded = type(_G.ArchonTooltip) == "table" or IsNamedAddOnLoaded("ArchonTooltip")
    local dbLoaded, dbName = false, nil

    for _, name in ipairs(ARCHON_DB_ADDONS) do
        if type(_G[name]) == "table" or IsNamedAddOnLoaded(name) then
            dbLoaded, dbName = true, name
            break
        end
    end

    -- Some Archon builds expose only private implementation state while the
    -- public ArchonTooltip table is still being initialized. Treat that as
    -- detection only; never consume the private table.
    local privateSeen = type(_G.ArchonTooltipPrivate) == "table"
    return {
        detected = coreLoaded or dbLoaded or privateSeen,
        coreLoaded = coreLoaded,
        dbLoaded = dbLoaded,
        dbName = dbName,
        privateSeen = privateSeen,
    }
end

local function ValidateSpecRow(row)
    if type(row) ~= "table" then return false end
    if type(row.role) ~= "string" or row.role == "" then return false end
    if not IsFiniteNumber(row.heroSpellID) or tonumber(row.heroSpellID) <= 0 then return false end
    if type(row.hero) ~= "string" or row.hero == "" then return false end
    if not IsFiniteNumber(row.heroUsage) then return false end
    if tonumber(row.heroUsage) < 0 or tonumber(row.heroUsage) > 100 then return false end

    if row.alternativeHero ~= nil then
        if type(row.alternativeHero) ~= "string" or row.alternativeHero == "" then return false end
        if not IsFiniteNumber(row.alternativeHeroSpellID) or tonumber(row.alternativeHeroSpellID) <= 0 then return false end
    end
    if row.alternativeUsage ~= nil and not IsFiniteNumber(row.alternativeUsage) then return false end
    if row.parses ~= nil and not IsFiniteNumber(row.parses) then return false end
    return true
end

function Provider:ValidateSnapshot(snapshot)
    if type(snapshot) ~= "table" then return false, "snapshot is not a table" end
    if type(snapshot.contexts) ~= "table" then return false, "contexts missing" end
    if type(snapshot.contextOrder) ~= "table" then return false, "contextOrder missing" end

    for _, contextKey in ipairs(REQUIRED_CONTEXTS) do
        local context = snapshot.contexts[contextKey]
        if type(context) ~= "table" or type(context.specs) ~= "table" then
            return false, contextKey .. " context missing"
        end
        for _, specID in ipairs(REQUIRED_SPECS) do
            if not ValidateSpecRow(context.specs[specID]) then
                return false, contextKey .. "/" .. tostring(specID) .. " row invalid or missing stable Hero Talent IDs"
            end
        end
    end

    return true
end

local function AddCandidate(candidates, sourceID, value, detail)
    if type(value) == "table" then
        candidates[#candidates + 1] = {
            sourceID = sourceID,
            snapshot = value,
            detail = detail,
        }
    end
end

function Provider:FindArchonAggregateSnapshot()
    local archon = type(_G.ArchonTooltip) == "table" and _G.ArchonTooltip or nil
    local candidates = {}

    -- Public/explicit aggregate-table probes only. No undocumented function
    -- calls and no traversal of ArchonTooltipPrivate provider internals.
    AddCandidate(candidates, "archon-tooltip-meta", archon and archon.MetaData, "ArchonTooltip.MetaData")
    AddCandidate(candidates, "archon-tooltip-snapshot", archon and archon.MetaSnapshot, "ArchonTooltip.MetaSnapshot")
    AddCandidate(candidates, "archon-global-meta", _G.ArchonTooltipMetaData, "ArchonTooltipMetaData")
    AddCandidate(candidates, "archon-global-snapshot", _G.ArchonTooltipMetaSnapshot, "ArchonTooltipMetaSnapshot")

    -- Archon data modules are region-specific in some installations. Probe only
    -- explicit aggregate fields if those modules expose a public global table.
    for _, name in ipairs(ARCHON_DB_ADDONS) do
        local db = type(_G[name]) == "table" and _G[name] or nil
        AddCandidate(candidates, "archon-db-meta:" .. name, db and db.MetaData, name .. ".MetaData")
        AddCandidate(candidates, "archon-db-snapshot:" .. name, db and db.MetaSnapshot, name .. ".MetaSnapshot")
    end

    -- Optional bridge contract for a future Archon-compatible data module.
    AddCandidate(candidates, "archon-bridge", _G.DKMentorArchonMeta, "DKMentorArchonMeta bridge")

    for _, candidate in ipairs(candidates) do
        local valid = self:ValidateSnapshot(candidate.snapshot)
        if valid then
            return candidate.snapshot, candidate.sourceID, candidate.detail
        end
    end
    return nil
end

function Provider:RegisterExternalSnapshot(sourceID, snapshot, priority)
    sourceID = tostring(sourceID or "external")
    local valid, reason = self:ValidateSnapshot(snapshot)
    if not valid then return false, reason end
    self.externalSnapshots[sourceID] = {
        snapshot = snapshot,
        priority = tonumber(priority) or 50,
    }
    return true
end

function Provider:ClearExternalSnapshot(sourceID)
    self.externalSnapshots[tostring(sourceID or "external")] = nil
end

function Provider:GetBestRegisteredSnapshot()
    local bestID, best
    for sourceID, entry in pairs(self.externalSnapshots) do
        if not best or entry.priority > best.priority then
            bestID, best = sourceID, entry
        end
    end
    if best then return best.snapshot, bestID end
    return nil
end

function Provider:GetActiveSnapshot()
    local archonState = GetArchonState()
    local registered, registeredID = self:GetBestRegisteredSnapshot()
    if registered then
        return registered, {
            id = registeredID,
            kind = "external",
            label = "External meta provider",
            detail = registeredID,
            archonDetected = archonState.detected,
            archonLoaded = archonState.detected,
            archonCoreLoaded = archonState.coreLoaded,
            archonDBLoaded = archonState.dbLoaded,
            archonDBName = archonState.dbName,
            compatible = true,
        }
    end

    if archonState.detected then
        local snapshot, sourceID, detail = self:FindArchonAggregateSnapshot()
        if snapshot then
            return snapshot, {
                id = sourceID,
                kind = "archon",
                label = "Archon addon data",
                detail = detail,
                archonDetected = true,
                archonLoaded = true,
                archonCoreLoaded = archonState.coreLoaded,
                archonDBLoaded = archonState.dbLoaded,
                archonDBName = archonState.dbName,
                compatible = true,
            }
        end
    end

    return DKM.MetaData, {
        id = "builtin",
        kind = "builtin",
        label = "Built-in snapshot",
        detail = archonState.detected and "Archon detected, but no compatible aggregate meta feed is exposed" or "Archon Tooltip not detected",
        archonDetected = archonState.detected,
        archonLoaded = archonState.detected,
        archonCoreLoaded = archonState.coreLoaded,
        archonDBLoaded = archonState.dbLoaded,
        archonDBName = archonState.dbName,
        compatible = false,
    }
end

function Provider:GetStatus()
    local snapshot, status = self:GetActiveSnapshot()
    status.reviewed = snapshot and snapshot.reviewed or nil
    status.sourceName = snapshot and snapshot.sourceName or nil
    return status
end

function Provider:GetArchonState()
    return GetArchonState()
end

DKM.MetaProvider = Provider

-- Small stable bridge surface for optional companion/data addons. This is not
-- required by Archon Tooltip and does not make it a dependency.
_G.DKMentorMetaBridge = _G.DKMentorMetaBridge or {}
_G.DKMentorMetaBridge.RegisterSnapshot = function(sourceID, snapshot, priority)
    return Provider:RegisterExternalSnapshot(sourceID, snapshot, priority)
end
_G.DKMentorMetaBridge.ClearSnapshot = function(sourceID)
    Provider:ClearExternalSnapshot(sourceID)
end
