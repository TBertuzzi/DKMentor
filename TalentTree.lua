local ADDON_NAME, DKM = ...

local addon = DKM.Addon
local T = DKM.T or function(value, ...)
    if select('#', ...) > 0 then return string.format(value, ...) end
    return value
end

if not addon then return end

local QUESTION_MARK_ICON = 134400
local TREE_HEIGHT = 575
local HEADER_HEIGHT = 105
local GROUP_GAP = 10
local NODE_SIZE = 28
local NODE_PADDING = 16
local MAX_SAVED_BUILDS = 20
local TREE_ACTION_BUTTON_HEIGHT = 28
local TREE_ACTION_BUTTON_GAP = 6
local TREE_ACTION_BUTTON_PAD_X = 24

local function SafeNumber(value)
    if type(value) == 'number' then return value end
    local ok, converted = pcall(tonumber, value)
    if ok then return converted end
    return nil
end


local function GetSavedBuildStore()
    _G.DKMentorDB = _G.DKMentorDB or {}
    if type(_G.DKMentorDB.savedTalentBuilds) ~= 'table' then
        _G.DKMentorDB.savedTalentBuilds = {}
    end
    return _G.DKMentorDB.savedTalentBuilds
end

local function GetCurrentSpecID()
    if addon.GetSpecInfo then
        local ok, specID = pcall(function() return select(1, addon:GetSpecInfo()) end)
        if ok then return SafeNumber(specID) end
    end
    return nil
end

local function GetSpecNameSafe(specID)
    specID = SafeNumber(specID)
    if specID and GetSpecializationInfoByID then
        local ok, _, name = pcall(GetSpecializationInfoByID, specID)
        if ok and type(name) == 'string' and name ~= '' then return name end
    end
    return tostring(specID or T('Unknown'))
end

local function GenerateComparedLoadoutString(specID, configID)
    specID = SafeNumber(specID)
    configID = SafeNumber(configID)
    if not specID or not configID then
        return nil, T('No compared Blizzard loadout is available to export.')
    end
    if GetCurrentSpecID() ~= specID then
        return nil, T('Switch to this specialization before exporting so Blizzard generates a valid import string for the correct specialization.')
    end
    if not C_Traits or not C_Traits.GenerateImportString then
        return nil, T('This client does not expose Blizzard talent export yet.')
    end
    local ok, importString = pcall(C_Traits.GenerateImportString, configID)
    if not ok or type(importString) ~= 'string' or importString == '' then
        return nil, T('Blizzard could not generate the talent import string yet.')
    end
    return importString
end

local SPEC_LOADOUT_NAME = {
    [250] = 'Blood',
    [251] = 'Frost',
    [252] = 'Unholy',
}

local CONTEXT_LOADOUT_NAME = {
    world = 'World',
    delve = 'Delve',
    dungeon = 'Dungeon',
    mythicplus = 'M+',
    raid = 'Raid',
    pvp = 'PvP',
}

local HERO_LOADOUT_NAME = {
    [31] = 'SL',
    [32] = 'Rider',
    [33] = 'DB',
}

local pendingLoadoutCreate
local loadoutCreateEventFrame

local function BuildSuggestedLoadoutName(specID, profile, fallbackLabel)
    local specPart = SPEC_LOADOUT_NAME[SafeNumber(specID)] or GetSpecNameSafe(specID)
    local contextPart = CONTEXT_LOADOUT_NAME[profile and profile.contextKey] or nil
    local heroPart = HERO_LOADOUT_NAME[SafeNumber(profile and profile.heroSubTreeID)] or nil
    local parts = { 'DKM', specPart }
    if contextPart then parts[#parts + 1] = contextPart end
    if heroPart then parts[#parts + 1] = heroPart end
    if #parts <= 2 and fallbackLabel and fallbackLabel ~= '' then parts[#parts + 1] = fallbackLabel end
    return table.concat(parts, ' ')
end

local function GetUniqueLoadoutName(specID, baseName)
    baseName = tostring(baseName or 'DKM Build')
    local used = {}
    if C_ClassTalents and C_ClassTalents.GetConfigIDsBySpecID and C_Traits and C_Traits.GetConfigInfo then
        local okIDs, configIDs = pcall(C_ClassTalents.GetConfigIDsBySpecID, SafeNumber(specID))
        if okIDs and type(configIDs) == 'table' then
            for _, configID in ipairs(configIDs) do
                local okInfo, info = pcall(C_Traits.GetConfigInfo, configID)
                if okInfo and type(info) == 'table' and type(info.name) == 'string' then used[info.name] = true end
            end
        end
    end
    if not used[baseName] then return baseName end
    for suffix = 2, 99 do
        local candidate = string.format('%s %d', baseName, suffix)
        if not used[candidate] then return candidate end
    end
    return string.format('%s %d', baseName, (GetServerTime and GetServerTime()) or 100)
end

local function FinishPendingLoadoutCreate(configInfo)
    local pending = pendingLoadoutCreate
    if not pending or type(configInfo) ~= 'table' then return end
    if type(configInfo.name) == 'string' and configInfo.name ~= '' and configInfo.name ~= pending.name then return end
    local configID = SafeNumber(configInfo.ID)
    if not configID then return end

    -- Clear first: TRAIT_CONFIG_CREATED is synchronous and other talent events can
    -- fire while ImportLoadout populates the new config.
    pendingLoadoutCreate = nil
    local okImport, success, importError = pcall(C_ClassTalents.ImportLoadout, configID, {}, pending.name, pending.importString)
    if not okImport or success == false then
        if C_ClassTalents.DeleteConfig then pcall(C_ClassTalents.DeleteConfig, configID) end
        if addon.Print then addon:Print(T('Could not import the loadout into Blizzard Talents: %s', tostring(importError or T('Unknown error')))) end
        return
    end
    if C_ClassTalents.SaveConfig then pcall(C_ClassTalents.SaveConfig, configID) end
    if addon.Print then addon:Print(T('Created Blizzard talent loadout: %s', pending.name)) end
end

local function EnsureLoadoutCreateEventFrame()
    if loadoutCreateEventFrame then return loadoutCreateEventFrame end
    if type(CreateFrame) ~= 'function' then return nil end
    local frame = CreateFrame('Frame')
    frame:RegisterEvent('TRAIT_CONFIG_CREATED')
    frame:SetScript('OnEvent', function(_, event, configInfo)
        if event == 'TRAIT_CONFIG_CREATED' then FinishPendingLoadoutCreate(configInfo) end
    end)
    loadoutCreateEventFrame = frame
    return frame
end

local function CreateBlizzardLoadoutFromImportString(specID, baseName, importString)
    specID = SafeNumber(specID)
    if not specID or type(importString) ~= 'string' or importString == '' then
        return false, T('No valid Blizzard talent import string is available.')
    end
    if GetCurrentSpecID() ~= specID then
        return false, T('Switch to this specialization before creating a Blizzard talent loadout.')
    end
    if InCombatLockdown and InCombatLockdown() then
        return false, T('Cannot create talent loadouts in combat.')
    end
    if not C_ClassTalents or not C_ClassTalents.RequestNewConfig or not C_ClassTalents.ImportLoadout then
        return false, T('Blizzard talent loadout creation is not available on this client.')
    end
    if C_ClassTalents.CanCreateNewConfig then
        local okCanCreate, canCreate = pcall(C_ClassTalents.CanCreateNewConfig)
        if okCanCreate and canCreate == false then return false, T("You have reached Blizzard's saved loadout limit.") end
    end
    if pendingLoadoutCreate then return false, T('A Blizzard talent loadout is already being created.') end
    if not EnsureLoadoutCreateEventFrame() then return false, T('Blizzard talent loadout creation is not available on this client.') end

    local name = GetUniqueLoadoutName(specID, baseName)
    pendingLoadoutCreate = { specID = specID, name = name, importString = importString }
    if addon.Print then addon:Print(T('Creating Blizzard talent loadout: %s...', name)) end
    local okRequest, requested = pcall(C_ClassTalents.RequestNewConfig, name)
    if not okRequest or requested == false then
        pendingLoadoutCreate = nil
        return false, T('Could not create Blizzard talent loadout.')
    end
    return true, name
end

local function BuildGuideSpellSnapshot(profile)
    local result = {}
    local seen = {}
    local function Add(spellID)
        spellID = SafeNumber(spellID)
        if spellID and not seen[spellID] then
            seen[spellID] = true
            result[#result + 1] = spellID
        end
    end
    Add(profile and profile.heroSpellID)
    for _, talent in ipairs((profile and (profile.treeKeyTalents or profile.keyTalents)) or {}) do
        Add(talent.spellID)
    end
    return result
end

local function SavedBuildKey(specID, profile)
    return string.format('%s|%s|%s', tostring(specID or 0), tostring(profile and profile.name or ''), tostring(profile and profile.heroSpellID or 0))
end

local function GetSpellNameSafe(spellID, fallback)
    spellID = SafeNumber(spellID)
    if spellID and C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and type(name) == 'string' and name ~= '' then return name end
    end
    if spellID and GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok and type(name) == 'string' and name ~= '' then return name end
    end
    return fallback or T('Talent')
end

local function GetSpellTextureSafe(spellID)
    spellID = SafeNumber(spellID)
    if spellID and C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    if spellID and GetSpellTexture then
        local ok, texture = pcall(GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    return QUESTION_MARK_ICON
end

local function GetCommittedEntryID(nodeInfo)
    if type(nodeInfo) ~= 'table' then return nil end
    if type(nodeInfo.entryIDsWithCommittedRanks) == 'table' then
        for _, entryID in ipairs(nodeInfo.entryIDsWithCommittedRanks) do
            entryID = SafeNumber(entryID)
            if entryID and entryID > 0 then return entryID end
        end
    end
    if type(nodeInfo.activeEntry) == 'table' then
        local entryID = SafeNumber(nodeInfo.activeEntry.entryID)
        if entryID and entryID > 0 then return entryID end
    end
    local activeEntryID = SafeNumber(nodeInfo.activeEntryID)
    if activeEntryID and activeEntryID > 0 then return activeEntryID end
    return nil
end

local function GetNodeRank(nodeInfo)
    if type(nodeInfo) ~= 'table' then return 0 end
    local rank = SafeNumber(nodeInfo.currentRank) or SafeNumber(nodeInfo.activeRank) or SafeNumber(nodeInfo.ranksPurchased) or 0
    return math.max(0, math.floor(rank))
end

local function ReadEntry(configID, entryID)
    if not C_Traits or not C_Traits.GetEntryInfo then return nil end
    entryID = SafeNumber(entryID)
    if not entryID then return nil end
    local okEntry, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID)
    if not okEntry or type(entryInfo) ~= 'table' then return nil end
    local candidate = {
        entryID = entryID,
        definitionID = SafeNumber(entryInfo.definitionID),
        subTreeID = SafeNumber(entryInfo.subTreeID),
        maxRanks = SafeNumber(entryInfo.maxRanks) or 1,
        spellIDs = {},
    }

    local function AddSpellAlias(spellID)
        spellID = SafeNumber(spellID)
        if not spellID then return end
        candidate.spellIDs[spellID] = true
        if not candidate.spellID then candidate.spellID = spellID end
    end

    if candidate.definitionID and C_Traits.GetDefinitionInfo then
        local okDef, defInfo = pcall(C_Traits.GetDefinitionInfo, candidate.definitionID)
        if okDef and type(defInfo) == 'table' then
            -- Keep both IDs. Choice/override nodes can expose a base spell ID and
            -- a different overridden ID; comparing only one of them caused valid
            -- selected talents to be reported as missing in 3.3 r7.
            AddSpellAlias(defInfo.spellID)
            AddSpellAlias(defInfo.overriddenSpellID)
            candidate.overrideName = defInfo.overrideName
            candidate.overrideIcon = defInfo.overrideIcon
        end
    end

    -- Hero Talent selectors are not normal spell entries. Blizzard stores the
    -- selected Hero tree as a SubTreeSelection entry, whose definitionID is nil.
    if candidate.subTreeID and C_Traits.GetSubTreeInfo then
        local okSubTree, subTreeInfo = pcall(C_Traits.GetSubTreeInfo, configID, candidate.subTreeID)
        if okSubTree and type(subTreeInfo) == 'table' then
            candidate.subTreeName = subTreeInfo.name
            if type(subTreeInfo.iconElementID) == 'string' and subTreeInfo.iconElementID ~= '' then
                candidate.atlas = subTreeInfo.iconElementID
            end
        end
    end

    return candidate
end

local function EntryHasSpell(candidate, spellID)
    spellID = SafeNumber(spellID)
    return spellID ~= nil and type(candidate) == 'table' and type(candidate.spellIDs) == 'table' and candidate.spellIDs[spellID] == true
end

local function NodeHasSelection(node)
    if type(node) ~= 'table' or not node.selectedEntryID then return false end
    if (node.selectedRank or 0) > 0 then return true end
    -- Blizzard explicitly documents rank 0 for single choice entries. Selection
    -- and SubTreeSelection nodes are selected by entry ID, not by positive rank.
    return node.type == 2 or node.type == 3
end

local function NodeMatchesRecommendation(node)
    if type(node) ~= 'table' or not node.recommendedEntryID or not NodeHasSelection(node) then return false end
    if node.selectedEntryID == node.recommendedEntryID then return true end
    if node.recommendedSubTreeID and node.selectedSubTreeID == node.recommendedSubTreeID then return true end
    if node.recommendedSpellID and EntryHasSpell(node.selectedEntry, node.recommendedSpellID) then return true end
    if type(node.recommendedSpellIDs) == 'table' and type(node.selectedEntry) == 'table' then
        for spellID in pairs(node.recommendedSpellIDs) do
            if EntryHasSpell(node.selectedEntry, spellID) then return true end
        end
    end
    return false
end

local function ResolveSavedConfig(specID)
    if not C_ClassTalents or not C_Traits then return nil, nil end
    local currentSpecID = addon.GetSpecInfo and select(1, addon:GetSpecInfo()) or nil
    if currentSpecID == specID and C_ClassTalents.GetActiveConfigID then
        local ok, configID = pcall(C_ClassTalents.GetActiveConfigID)
        if ok and type(configID) == 'number' then
            local okInfo, info = pcall(C_Traits.GetConfigInfo, configID)
            if okInfo and type(info) == 'table' then return configID, T('active loadout') end
        end
    end

    if C_ClassTalents.GetLastSelectedSavedConfigID then
        local ok, configID = pcall(C_ClassTalents.GetLastSelectedSavedConfigID, specID)
        if ok and type(configID) == 'number' and configID > 0 then
            local okInfo, info = pcall(C_Traits.GetConfigInfo, configID)
            if okInfo and type(info) == 'table' then
                return configID, (type(info.name) == 'string' and info.name ~= '' and info.name) or T('saved loadout')
            end
        end
    end

    if C_ClassTalents.GetConfigIDsBySpecID then
        local ok, configIDs = pcall(C_ClassTalents.GetConfigIDsBySpecID, specID)
        if ok and type(configIDs) == 'table' then
            for _, configID in ipairs(configIDs) do
                if type(configID) == 'number' and configID > 0 then
                    local okInfo, info = pcall(C_Traits.GetConfigInfo, configID)
                    if okInfo and type(info) == 'table' then
                        return configID, (type(info.name) == 'string' and info.name ~= '' and info.name) or T('saved loadout')
                    end
                end
            end
        end
    end
    return nil, nil
end

local function ResolveViewConfig(specID)
    if not C_ClassTalents or not C_Traits or not C_ClassTalents.InitializeViewLoadout or not C_ClassTalents.ViewLoadout then return nil end
    local traitConsts = Constants and Constants.TraitConsts
    local viewConfigID = traitConsts and traitConsts.VIEW_TRAIT_CONFIG_ID
    if type(viewConfigID) ~= 'number' then return nil end
    local level = 90
    if UnitLevel then
        local okLevel, playerLevel = pcall(UnitLevel, 'player')
        if okLevel and type(playerLevel) == 'number' and playerLevel > 0 then level = playerLevel end
    end
    local okInit = pcall(C_ClassTalents.InitializeViewLoadout, specID, level)
    if not okInit then return nil end
    local okView, success = pcall(C_ClassTalents.ViewLoadout, {})
    if not okView or success == false then return nil end
    local okInfo, info = pcall(C_Traits.GetConfigInfo, viewConfigID)
    if not okInfo or type(info) ~= 'table' then return nil end
    return viewConfigID
end

local function ResolveTreeConfig(specID)
    local configID, loadoutLabel = ResolveSavedConfig(specID)
    if configID then return configID, configID, loadoutLabel end
    local viewID = ResolveViewConfig(specID)
    if viewID then return viewID, nil, nil end
    return nil, nil, nil
end

local function ReadTreeRuntime(specID, profile)
    if not C_Traits or not C_Traits.GetConfigInfo or not C_Traits.GetTreeNodes or not C_Traits.GetNodeInfo then
        return nil, T('This client does not expose the talent tree inspection API.')
    end

    local structureConfigID, selectionConfigID, loadoutLabel = ResolveTreeConfig(specID)
    if not structureConfigID then return nil, T('Talent tree data is not available yet.') end

    local okConfig, configInfo = pcall(C_Traits.GetConfigInfo, structureConfigID)
    if not okConfig or type(configInfo) ~= 'table' or type(configInfo.treeIDs) ~= 'table' or not configInfo.treeIDs[1] then
        return nil, T('Talent tree structure is not available yet.')
    end
    local treeID = configInfo.treeIDs[1]
    local okNodes, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
    if not okNodes or type(nodeIDs) ~= 'table' then return nil, T('Talent nodes are not available yet.') end

    local guideTreeTalents = profile.treeKeyTalents or profile.keyTalents or {}
    local guideKeys = {}
    local guideKeySeen = {}

    local function AddGuideKey(key)
        if type(key) ~= 'table' or not key.key or guideKeySeen[key.key] then return end
        guideKeySeen[key.key] = true
        guideKeys[#guideKeys + 1] = key
    end

    for index, talent in ipairs(guideTreeTalents) do
        local nodeID = SafeNumber(talent.nodeID)
        local entryID = SafeNumber(talent.entryID)
        local spellID = SafeNumber(talent.spellID)
        local aliases = {}
        local function AddGuideSpellAlias(alias)
            alias = SafeNumber(alias)
            if not alias then return end
            aliases[alias] = true
            -- Resolve the current/base spell pair by ID as an additional safety
            -- net. This is still ID-based; localized spell names are never used.
            if C_Spell and C_Spell.GetBaseSpell then
                local okBase, baseSpellID = pcall(C_Spell.GetBaseSpell, alias, specID)
                baseSpellID = okBase and SafeNumber(baseSpellID) or nil
                if baseSpellID then aliases[baseSpellID] = true end
            end
            if C_Spell and C_Spell.GetOverrideSpell then
                local okOverride, overrideSpellID = pcall(C_Spell.GetOverrideSpell, alias, specID, false)
                overrideSpellID = okOverride and SafeNumber(overrideSpellID) or nil
                if overrideSpellID then aliases[overrideSpellID] = true end
            end
        end
        AddGuideSpellAlias(spellID)
        if type(talent.spellIDs) == 'table' then
            for _, alias in ipairs(talent.spellIDs) do AddGuideSpellAlias(alias) end
        end
        local stablePart = nodeID or entryID or spellID or index
        AddGuideKey({
            key = 'talent:' .. tostring(stablePart),
            kind = 'talent',
            talent = talent,
            nodeID = nodeID,
            entryID = entryID,
            spellID = spellID,
            spellIDs = aliases,
        })
    end

    local heroSubTreeID = SafeNumber(profile.heroSubTreeID)
    if heroSubTreeID then
        AddGuideKey({
            key = 'hero:' .. tostring(heroSubTreeID),
            kind = 'hero',
            subTreeID = heroSubTreeID,
            talent = {
                fallbackName = profile.heroTalent,
                reason = T('Recommended Hero Talent for this build context.'),
                hero = true,
            },
        })
    end

    local runtime = {
        specID = specID,
        profile = profile,
        treeID = treeID,
        structureConfigID = structureConfigID,
        selectionConfigID = selectionConfigID,
        loadoutLabel = loadoutLabel,
        totalKeys = #guideKeys,
        guideTreeTalents = guideTreeTalents,
        guideKeys = guideKeys,
        mappedKeys = 0,
        selectedKeys = 0,
        mappedGuideKeys = {},
        selectedGuideKeys = {},
        guideNodeByKey = {},
        nodes = {},
        nodeByID = {},
        groups = { class = {}, hero = {}, spec = {} },
    }

    local function CandidateMatchesGuideKey(nodeID, candidate, guideKey)
        if guideKey.kind == 'hero' then
            return candidate.subTreeID ~= nil and candidate.subTreeID == guideKey.subTreeID
        end
        if guideKey.nodeID and nodeID ~= guideKey.nodeID then return false end
        if guideKey.entryID and candidate.entryID ~= guideKey.entryID then return false end
        if guideKey.nodeID or guideKey.entryID then return true end
        for spellID in pairs(guideKey.spellIDs or {}) do
            if EntryHasSpell(candidate, spellID) then return true end
        end
        return false
    end

    for _, rawNodeID in ipairs(nodeIDs) do
        local nodeID = SafeNumber(rawNodeID)
        if nodeID then
            local okNode, nodeInfo = pcall(C_Traits.GetNodeInfo, structureConfigID, nodeID)
            if okNode and type(nodeInfo) == 'table' and nodeInfo.isVisible ~= false then
                local posX = SafeNumber(nodeInfo.posX)
                local posY = SafeNumber(nodeInfo.posY)
                if posX and posY and type(nodeInfo.entryIDs) == 'table' and #nodeInfo.entryIDs > 0 then
                    local node = {
                        nodeID = nodeID,
                        posX = posX,
                        posY = posY,
                        maxRanks = SafeNumber(nodeInfo.maxRanks) or 1,
                        type = SafeNumber(nodeInfo.type) or 0,
                        subTreeID = SafeNumber(nodeInfo.subTreeID),
                        entries = {},
                        edges = {},
                    }

                    for _, entryID in ipairs(nodeInfo.entryIDs) do
                        local candidate = ReadEntry(structureConfigID, entryID)
                        if candidate then
                            node.entries[#node.entries + 1] = candidate
                            if candidate.subTreeID then node.isHero = true end
                            if not node.recommendedEntryID then
                                for _, guideKey in ipairs(guideKeys) do
                                    if not runtime.mappedGuideKeys[guideKey.key] and CandidateMatchesGuideKey(nodeID, candidate, guideKey) then
                                        node.recommendedEntryID = candidate.entryID
                                        node.recommendedTalent = guideKey.talent
                                        node.recommendedGuideKey = guideKey.key
                                        node.recommendedSubTreeID = guideKey.subTreeID
                                        node.recommendedSpellID = guideKey.spellID
                                        node.recommendedSpellIDs = guideKey.spellIDs
                                        runtime.mappedGuideKeys[guideKey.key] = true
                                        runtime.guideNodeByKey[guideKey.key] = node
                                        runtime.mappedKeys = runtime.mappedKeys + 1
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if node.subTreeID then node.isHero = true end
                    if node.type == 3 then node.isHero = true end

                    if selectionConfigID then
                        local okSelected, selectedInfo = pcall(C_Traits.GetNodeInfo, selectionConfigID, nodeID)
                        if okSelected and type(selectedInfo) == 'table' then
                            node.selectedRank = GetNodeRank(selectedInfo)
                            node.selectedEntryID = GetCommittedEntryID(selectedInfo)
                            if node.selectedEntryID then
                                node.selectedEntry = ReadEntry(selectionConfigID, node.selectedEntryID)
                                node.selectedSpellID = node.selectedEntry and node.selectedEntry.spellID or nil
                                node.selectedSubTreeID = node.selectedEntry and node.selectedEntry.subTreeID or nil
                            end
                        end
                    else
                        node.selectedRank = 0
                    end

                    if node.recommendedGuideKey and NodeMatchesRecommendation(node) and not runtime.selectedGuideKeys[node.recommendedGuideKey] then
                        runtime.selectedGuideKeys[node.recommendedGuideKey] = true
                        runtime.selectedKeys = runtime.selectedKeys + 1
                    end

                    if type(nodeInfo.visibleEdges) == 'table' then
                        for _, edge in ipairs(nodeInfo.visibleEdges) do
                            local targetNode = SafeNumber(edge and edge.targetNode)
                            if targetNode then node.edges[#node.edges + 1] = { targetNode = targetNode, active = edge.isActive == true } end
                        end
                    end

                    runtime.nodes[#runtime.nodes + 1] = node
                    runtime.nodeByID[nodeID] = node
                end
            end
        end
    end

    local baseNodes = {}
    for _, node in ipairs(runtime.nodes) do
        if node.isHero then
            runtime.groups.hero[#runtime.groups.hero + 1] = node
            node.group = 'hero'
        else
            baseNodes[#baseNodes + 1] = node
        end
    end

    if #baseNodes > 0 then
        table.sort(baseNodes, function(a, b) return a.posX < b.posX end)
        local minX = baseNodes[1].posX
        local maxX = baseNodes[#baseNodes].posX
        local splitX = (minX + maxX) / 2
        local largestGap = -1
        for index = 1, #baseNodes - 1 do
            local gap = baseNodes[index + 1].posX - baseNodes[index].posX
            if gap > largestGap then
                largestGap = gap
                splitX = (baseNodes[index + 1].posX + baseNodes[index].posX) / 2
            end
        end
        for _, node in ipairs(baseNodes) do
            if node.posX <= splitX then
                runtime.groups.class[#runtime.groups.class + 1] = node
                node.group = 'class'
            else
                runtime.groups.spec[#runtime.groups.spec + 1] = node
                node.group = 'spec'
            end
        end
        if #runtime.groups.class == 0 or #runtime.groups.spec == 0 then
            runtime.groups.class = {}
            runtime.groups.spec = {}
            for _, node in ipairs(baseNodes) do
                if node.posX <= (minX + maxX) / 2 then
                    runtime.groups.class[#runtime.groups.class + 1] = node
                    node.group = 'class'
                else
                    runtime.groups.spec[#runtime.groups.spec + 1] = node
                    node.group = 'spec'
                end
            end
        end
    end

    runtime.isAligned = runtime.totalKeys > 0 and runtime.mappedKeys == runtime.totalKeys and runtime.selectedKeys == runtime.totalKeys
    runtime.missingKeys = {}
    runtime.guideStatus = {}
    for _, guideKey in ipairs(guideKeys) do
        local mapped = runtime.mappedGuideKeys[guideKey.key] == true
        local selected = runtime.selectedGuideKeys[guideKey.key] == true
        local node = runtime.guideNodeByKey[guideKey.key]
        local state
        if not mapped then
            state = 'unmapped'
            runtime.missingKeys[#runtime.missingKeys + 1] = guideKey.key
        elseif selected then
            state = 'ok'
        elseif node and NodeHasSelection(node) then
            state = 'swap'
        else
            state = 'missing'
        end
        local fallbackName = guideKey.talent and guideKey.talent.fallbackName or nil
        local name
        if guideKey.kind == 'hero' then
            name = (guideKey.talent and guideKey.talent.fallbackName) or profile.heroTalent or T('Hero Talent')
        else
            name = GetSpellNameSafe(guideKey.spellID, fallbackName or T('Talent'))
        end
        runtime.guideStatus[#runtime.guideStatus + 1] = {
            key = guideKey.key,
            kind = guideKey.kind,
            name = name,
            state = state,
            mapped = mapped,
            selected = selected,
            node = node,
        }
    end

    return runtime
end

local function ResetLine(line)
    if line then line:Hide() end
end

local function ResetNodeButton(button)
    if not button then return end
    button:Hide()
    button.nodeData = nil
    button.spellID = nil
    button.fallbackName = nil
    button.guideReason = nil
end

local GUIDE_STATUS_COLORS = {
    ok = '|cff69ff9b',
    missing = '|cffffc54d',
    swap = '|cffff944d',
    unmapped = '|cffff6666',
}

local GUIDE_STATUS_LABELS = {
    ok = 'OK',
    missing = 'MISSING',
    swap = 'SWAP',
    unmapped = 'NOT MAPPED',
}

local function BuildGuideStatusText(runtime)
    local parts = {}
    for _, item in ipairs((runtime and runtime.guideStatus) or {}) do
        local color = GUIDE_STATUS_COLORS[item.state] or '|cffffffff'
        local label = T(GUIDE_STATUS_LABELS[item.state] or 'CHECK')
        parts[#parts + 1] = string.format('%s[%s] %s|r', color, label, tostring(item.name or T('Talent')))
    end
    return table.concat(parts, '   ')
end

local function BuildCoverageText(profile)
    local coverage = profile and profile.treeCoverage or nil
    if coverage == 'context-markers' then
        return T('Coverage: current guide context markers; this is not a full imported guide tree.')
    elseif coverage == 'derived-markers' then
        return T('Coverage: context markers derived from the nearest current guide profile; this is not a full imported guide tree.')
    elseif coverage == 'hero-only' then
        return T('Coverage: Hero Talent direction only; the exact full guide tree is not embedded for this context.')
    end
    return T('Coverage: DK Mentor key nodes only; flex and pathing choices are not judged.')
end

local function BuildCreateBlockerText(runtime)
    if not runtime then return T('Talent tree data is not available yet.') end
    local unmapped, missing, swaps = {}, {}, {}
    for _, item in ipairs(runtime.guideStatus or {}) do
        if item.state == 'unmapped' then
            unmapped[#unmapped + 1] = tostring(item.name or T('Talent'))
        elseif item.state == 'missing' then
            missing[#missing + 1] = tostring(item.name or T('Talent'))
        elseif item.state == 'swap' then
            swaps[#swaps + 1] = tostring(item.name or T('Talent'))
        end
    end
    local parts = {}
    if #unmapped > 0 then
        parts[#parts + 1] = T('DK Mentor could not map: %s. This is a guide-data mapping issue, not proof that your talent choice is wrong.', table.concat(unmapped, ', '))
    end
    if #missing > 0 then
        parts[#parts + 1] = T('Missing from the compared loadout: %s.', table.concat(missing, ', '))
    end
    if #swaps > 0 then
        parts[#parts + 1] = T('Different choice from the guide: %s.', table.concat(swaps, ', '))
    end
    if #parts == 0 then return T('Align all mapped DK Mentor key nodes before creating the Blizzard loadout.') end
    return table.concat(parts, ' ')
end

local function CreateTreeActionButton(parent, minWidth, labelKey)
    local button
    if DKM and DKM.CreateActionButton then
        button = DKM.CreateActionButton(parent, minWidth or 80, TREE_ACTION_BUTTON_HEIGHT, labelKey)
    else
        button = CreateFrame('Button', nil, parent, 'BackdropTemplate')
        button:SetSize(minWidth or 80, TREE_ACTION_BUTTON_HEIGHT)
        button:SetBackdrop(addon.ACTION_BUTTON_BACKDROP or {
            bgFile = 'Interface\\Buttons\\WHITE8X8',
            edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        button:SetBackdropColor(0.025, 0.075, 0.10, 0.94)
        button:SetBackdropBorderColor(0.15, 0.42, 0.54, 0.88)
        local fontString = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        fontString:SetPoint('LEFT', button, 'LEFT', 8, 0)
        fontString:SetPoint('RIGHT', button, 'RIGHT', -8, 0)
        fontString:SetJustifyH('CENTER')
        fontString:SetJustifyV('MIDDLE')
        button:SetFontString(fontString)
        button.label = fontString
        button:SetText(labelKey and T(labelKey) or '')
    end
    button.__dkTreeMinWidth = minWidth or 80
    return button
end

local function MeasureTreeActionButton(button)
    if not button then return 0 end
    local fontString = button.GetFontString and button:GetFontString() or button.label
    local textWidth = 0
    if fontString and fontString.GetStringWidth then
        local ok, width = pcall(fontString.GetStringWidth, fontString)
        if ok and type(width) == 'number' then textWidth = width end
    end
    return math.max(button.__dkTreeMinWidth or 80, math.ceil(textWidth) + TREE_ACTION_BUTTON_PAD_X)
end

local function RefreshTreeActionButtonStyle(button)
    if DKM and DKM.StyleActionButton then DKM.StyleActionButton(button) end
end

local function SetTreeActionButtonEnabled(button, enabled)
    if not button then return end
    button:SetEnabled(enabled == true)
    RefreshTreeActionButtonStyle(button)
end

local function LayoutTreeActionButtons(frame)
    if not frame then return end
    local buttons = { frame.openButton, frame.createButton, frame.exportButton, frame.saveButton, frame.savedButton }
    local previous
    for _, button in ipairs(buttons) do
        if button then
            button:SetHeight(TREE_ACTION_BUTTON_HEIGHT)
            button:SetWidth(MeasureTreeActionButton(button))
            button:ClearAllPoints()
            if previous then
                button:SetPoint('RIGHT', previous, 'LEFT', -TREE_ACTION_BUTTON_GAP, 0)
            else
                button:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -8, -6)
            end
            RefreshTreeActionButtonStyle(button)
            previous = button
        end
    end

    if frame.title then
        frame.title:ClearAllPoints()
        frame.title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -8)
        if frame.savedButton then
            frame.title:SetPoint('TOPRIGHT', frame.savedButton, 'TOPLEFT', -10, -2)
        else
            frame.title:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -10, -8)
        end
        frame.title:SetHeight(18)
    end
end

local function EnsureTreeFrame(root)
    root.buildTreePool = root.buildTreePool or {}
    root.buildTreeUsed = (root.buildTreeUsed or 0) + 1
    local frame = root.buildTreePool[root.buildTreeUsed]
    if frame then
        frame:Show()
        return frame
    end

    frame = CreateFrame('Frame', nil, root, 'BackdropTemplate')
    frame:SetBackdrop(addon.GEAR_VISUAL_BACKDROP or {
        bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 1,
    })
    frame:SetBackdropColor(0.010, 0.030, 0.042, 0.96)
    frame:SetBackdropBorderColor(0.14, 0.42, 0.54, 0.90)

    frame.title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    frame.title:SetHeight(18)
    frame.title:SetJustifyH('LEFT')
    frame.title:SetTextColor(0.60, 0.90, 1.00)

    frame.openButton = CreateTreeActionButton(frame, 104, 'Open Talents')
    frame.openButton:SetScript('OnClick', function()
        if addon.OpenBlizzardTalents then addon:OpenBlizzardTalents() end
    end)

    frame.createButton = CreateTreeActionButton(frame, 108, 'Clone in WoW')
    frame.createButton:SetScript('OnClick', function(self)
        local owner = self:GetParent()
        if addon.CreateAlignedTalentLoadout then addon:CreateAlignedTalentLoadout(owner) end
    end)

    frame.exportButton = CreateTreeActionButton(frame, 76, 'Export')
    frame.exportButton:SetScript('OnClick', function(self)
        local owner = self:GetParent()
        if addon.ShowBuildExportPanel then addon:ShowBuildExportPanel(owner) end
    end)

    frame.saveButton = CreateTreeActionButton(frame, 72, 'Save')
    frame.saveButton:SetScript('OnClick', function(self)
        local owner = self:GetParent()
        if addon.SaveBuildTalentSnapshot then addon:SaveBuildTalentSnapshot(owner) end
    end)

    frame.savedButton = CreateTreeActionButton(frame, 94, 'Saved (0)')
    frame.savedButton:SetScript('OnClick', function(self)
        local owner = self:GetParent()
        if addon.ToggleSavedTalentBuildsPanel then addon:ToggleSavedTalentBuildsPanel(owner) end
    end)

    LayoutTreeActionButtons(frame)

    frame.status = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    frame.status:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -29)
    frame.status:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -10, -29)
    frame.status:SetHeight(18)
    frame.status:SetJustifyH('LEFT')
    frame.status:SetTextColor(0.82, 0.89, 0.94)

    frame.keyStatus = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    frame.keyStatus:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -47)
    frame.keyStatus:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -10, -47)
    frame.keyStatus:SetHeight(34)
    frame.keyStatus:SetJustifyH('LEFT')
    frame.keyStatus:SetJustifyV('TOP')
    frame.keyStatus:SetTextColor(0.88, 0.92, 0.95)

    frame.legend = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    frame.legend:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -84)
    frame.legend:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -10, -84)
    frame.legend:SetHeight(18)
    frame.legend:SetJustifyH('LEFT')
    frame.legend:SetTextColor(0.72, 0.80, 0.86)

    frame.groups = {}
    for _, key in ipairs({ 'class', 'hero', 'spec' }) do
        local group = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
        group:SetBackdrop({
            bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 1,
        })
        group:SetBackdropColor(0.012, 0.040, 0.055, 0.92)
        group:SetBackdropBorderColor(0.10, 0.31, 0.40, 0.85)
        group.title = group:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        group.title:SetPoint('TOPLEFT', group, 'TOPLEFT', 7, -5)
        group.title:SetPoint('TOPRIGHT', group, 'TOPRIGHT', -7, -5)
        group.title:SetHeight(16)
        group.title:SetJustifyH('CENTER')
        group.title:SetTextColor(0.82, 0.91, 0.96)
        group.empty = group:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        group.empty:SetPoint('CENTER', group, 'CENTER', 0, 0)
        group.empty:SetWidth(150)
        group.empty:SetJustifyH('CENTER')
        group.empty:SetTextColor(0.55, 0.63, 0.69)
        group.nodePool = {}
        group.linePool = {}
        frame.groups[key] = group
    end

    root.buildTreePool[root.buildTreeUsed] = frame
    return frame
end

local function AcquireNodeButton(group)
    group.nodeUsed = (group.nodeUsed or 0) + 1
    local button = group.nodePool[group.nodeUsed]
    if button then
        button:Show()
        return button
    end
    button = CreateFrame('Button', nil, group, 'BackdropTemplate')
    button:SetSize(NODE_SIZE, NODE_SIZE)
    button:SetBackdrop({
        bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 2,
    })
    button.icon = button:CreateTexture(nil, 'ARTWORK')
    button.icon:SetPoint('TOPLEFT', button, 'TOPLEFT', 3, -3)
    button.icon:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -3, 3)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.badge = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    button.badge:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 3, -1)
    button.badge:SetJustifyH('RIGHT')
    button.badge:SetTextColor(1, 1, 1)
    button:SetScript('OnEnter', function(self)
        if addon.ShowBuildTreeNodeTooltip then addon:ShowBuildTreeNodeTooltip(self) end
    end)
    button:SetScript('OnLeave', function(self)
        if addon.HideBuildTooltip then addon:HideBuildTooltip(self) end
    end)
    button:SetScript('OnHide', function(self)
        if addon.HideBuildTooltip then addon:HideBuildTooltip(self) end
    end)
    group.nodePool[group.nodeUsed] = button
    return button
end

local function AcquireLine(group)
    group.lineUsed = (group.lineUsed or 0) + 1
    local line = group.linePool[group.lineUsed]
    if line then
        line:Show()
        return line
    end
    if group.CreateLine then
        line = group:CreateLine(nil, 'BACKGROUND')
        if line.SetThickness then line:SetThickness(1.5) end
        if line.SetColorTexture then line:SetColorTexture(0.24, 0.52, 0.62, 0.58) end
        group.linePool[group.lineUsed] = line
        return line
    end
    return nil
end

local function ResetGroup(group)
    group.nodeUsed = 0
    group.lineUsed = 0
    for _, button in ipairs(group.nodePool or {}) do ResetNodeButton(button) end
    for _, line in ipairs(group.linePool or {}) do ResetLine(line) end
    if group.empty then group.empty:Hide() end
end

function addon:ResetBuildTalentTreeVisual(root)
    if not root then return end
    root.buildTreeUsed = 0
    for _, frame in ipairs(root.buildTreePool or {}) do
        frame:Hide()
        for _, group in pairs(frame.groups or {}) do ResetGroup(group) end
    end
end

local function CandidateForDisplay(node)
    if node.recommendedEntryID then
        for _, candidate in ipairs(node.entries or {}) do
            if candidate.entryID == node.recommendedEntryID then return candidate end
        end
    end
    if node.selectedEntryID then
        for _, candidate in ipairs(node.entries or {}) do
            if candidate.entryID == node.selectedEntryID then return candidate end
        end
    end
    return node.entries and node.entries[1] or nil
end

local function ConfigureNodeButton(button, node)
    local candidate = CandidateForDisplay(node)
    local spellID = candidate and candidate.spellID or nil
    local selected = NodeHasSelection(node)
    local recommended = node.recommendedEntryID ~= nil
    local matched = recommended and NodeMatchesRecommendation(node)
    local mismatch = recommended and selected and not matched

    button.nodeData = node
    button.spellID = spellID
    button.fallbackName = (node.recommendedTalent and node.recommendedTalent.fallbackName) or (candidate and (candidate.subTreeName or candidate.overrideName)) or nil
    button.guideReason = node.recommendedTalent and node.recommendedTalent.reason or nil

    if candidate and candidate.atlas and button.icon.SetAtlas then
        button.icon:SetTexCoord(0, 1, 0, 1)
        local okAtlas = pcall(button.icon.SetAtlas, button.icon, candidate.atlas)
        if not okAtlas then
            button.icon:SetTexture((candidate and candidate.overrideIcon) or GetSpellTextureSafe(spellID))
            button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    else
        button.icon:SetTexture((candidate and candidate.overrideIcon) or GetSpellTextureSafe(spellID))
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    button.icon:SetDesaturated(not selected and not recommended)
    button:SetAlpha((selected or recommended) and 1.0 or 0.42)

    if matched then
        button:SetBackdropColor(0.035, 0.16, 0.11, 0.98)
        button:SetBackdropBorderColor(0.30, 0.95, 0.58, 1.00)
    elseif recommended then
        button:SetBackdropColor(mismatch and 0.18 or 0.12, mismatch and 0.055 or 0.085, 0.015, 0.98)
        button:SetBackdropBorderColor(1.00, 0.73, 0.18, 1.00)
    elseif selected then
        button:SetBackdropColor(0.02, 0.10, 0.16, 0.98)
        button:SetBackdropBorderColor(0.28, 0.72, 1.00, 0.98)
    else
        button:SetBackdropColor(0.025, 0.035, 0.045, 0.96)
        button:SetBackdropBorderColor(0.28, 0.34, 0.38, 0.82)
    end

    local rank = node.selectedRank or 0
    if matched then
        local shownRank = (node.type == 2 or node.type == 3) and 1 or math.max(1, rank)
        button.badge:SetText(string.format('%d/%d', shownRank, math.max(1, node.maxRanks or 1)))
        button.badge:SetTextColor(0.48, 1.00, 0.66)
    elseif mismatch then
        button.badge:SetText(T('SWAP'))
        button.badge:SetTextColor(1.00, 0.78, 0.25)
    elseif recommended then
        button.badge:SetText(T('KEY'))
        button.badge:SetTextColor(1.00, 0.78, 0.25)
    elseif selected then
        local shownRank = (node.type == 2 or node.type == 3) and 1 or rank
        button.badge:SetText(string.format('%d/%d', shownRank, math.max(1, node.maxRanks or 1)))
        button.badge:SetTextColor(0.55, 0.88, 1.00)
    else
        button.badge:SetText('')
    end
end

local function SetBuildActionTooltip(button, title, body)
    if not button then return end
    button.tooltipTitle = title
    button.tooltipBody = body
    button:SetScript('OnEnter', function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, 'ANCHOR_TOP')
        GameTooltip:SetText(T(self.tooltipTitle or 'Build action'))
        if self.tooltipBody and self.tooltipBody ~= '' then
            GameTooltip:AddLine(T(self.tooltipBody), 0.82, 0.90, 0.96, true)
        end
        GameTooltip:Show()
    end)
    button:SetScript('OnLeave', function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

local function EnsureExportPanel(frame)
    if frame.exportPanel then return frame.exportPanel end
    local panel = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    panel:SetHeight(118)
    panel:SetPoint('TOPLEFT', frame, 'TOPLEFT', 20, -96)
    panel:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -20, -96)
    panel:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 1 })
    panel:SetBackdropColor(0.01, 0.025, 0.035, 0.99)
    panel:SetBackdropBorderColor(0.22, 0.65, 0.78, 1.00)
    panel:SetFrameLevel(frame:GetFrameLevel() + 25)
    panel:Hide()

    panel.title = panel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    panel.title:SetPoint('TOPLEFT', panel, 'TOPLEFT', 12, -10)
    panel.title:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -80, -10)
    panel.title:SetJustifyH('LEFT')
    panel.title:SetTextColor(0.62, 0.92, 1.00)

    panel.help = panel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    panel.help:SetPoint('TOPLEFT', panel, 'TOPLEFT', 12, -31)
    panel.help:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -12, -31)
    panel.help:SetHeight(30)
    panel.help:SetJustifyH('LEFT')
    panel.help:SetTextColor(0.78, 0.86, 0.91)

    panel.editBox = CreateFrame('EditBox', nil, panel, 'InputBoxTemplate')
    panel.editBox:SetPoint('BOTTOMLEFT', panel, 'BOTTOMLEFT', 12, 14)
    panel.editBox:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -12, 14)
    panel.editBox:SetHeight(24)
    panel.editBox:SetAutoFocus(false)
    panel.editBox:SetScript('OnEscapePressed', function(self) self:ClearFocus(); panel:Hide() end)
    panel.editBox:SetScript('OnEnterPressed', function(self) self:HighlightText() end)

    panel.close = CreateTreeActionButton(panel, 66, 'Close')
    panel.close:SetSize(66, 24)
    panel.close:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -10, -8)
    panel.close:SetText(T('Close'))
    panel.close:SetScript('OnClick', function() panel:Hide() end)

    frame.exportPanel = panel
    return panel
end

local function ShowExportText(frame, title, importString)
    local panel = EnsureExportPanel(frame)
    panel.title:SetText(title or T('Talent loadout export'))
    panel.help:SetText(T('This exports the compared Blizzard loadout. Gold guide nodes that are not selected are not applied automatically. Press Ctrl+C to copy, then import it in Blizzard Talents.'))
    panel.editBox:SetText(importString or '')
    panel:Show()
    panel.editBox:SetFocus()
    panel.editBox:HighlightText()
end

local function EnsureSavedPanel(frame)
    if frame.savedPanel then return frame.savedPanel end
    local panel = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    panel:SetHeight(330)
    panel:SetPoint('TOPLEFT', frame, 'TOPLEFT', 20, -90)
    panel:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -20, -90)
    panel:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 1 })
    panel:SetBackdropColor(0.01, 0.025, 0.035, 0.995)
    panel:SetBackdropBorderColor(0.22, 0.65, 0.78, 1.00)
    panel:SetFrameLevel(frame:GetFrameLevel() + 24)
    panel:Hide()

    panel.title = panel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    panel.title:SetPoint('TOPLEFT', panel, 'TOPLEFT', 12, -10)
    panel.title:SetText(T('Saved talent snapshots'))
    panel.title:SetTextColor(0.62, 0.92, 1.00)

    panel.subtitle = panel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    panel.subtitle:SetPoint('TOPLEFT', panel, 'TOPLEFT', 12, -36)
    panel.subtitle:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -12, -36)
    panel.subtitle:SetHeight(28)
    panel.subtitle:SetJustifyH('LEFT')
    panel.subtitle:SetText(T('Saved snapshots keep the Blizzard import string plus the DK Mentor guide reference used when you saved it.'))
    panel.subtitle:SetTextColor(0.72, 0.82, 0.88)

    panel.close = CreateTreeActionButton(panel, 66, 'Close')
    panel.close:SetSize(66, 24)
    panel.close:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -10, -8)
    panel.close:SetText(T('Close'))
    panel.close:SetScript('OnClick', function() panel:Hide() end)

    panel.rows = {}
    for index = 1, 7 do
        local row = CreateFrame('Frame', nil, panel, 'BackdropTemplate')
        row:SetHeight(32)
        row:SetPoint('TOPLEFT', panel, 'TOPLEFT', 12, -70 - ((index - 1) * 35))
        row:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', -12, -70 - ((index - 1) * 35))
        row:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8X8', edgeFile = 'Interface\\Buttons\\WHITE8X8', edgeSize = 1 })
        row:SetBackdropColor(0.025, 0.050, 0.062, 0.95)
        row:SetBackdropBorderColor(0.12, 0.28, 0.34, 0.85)
        row.label = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        row.label:SetPoint('LEFT', row, 'LEFT', 8, 0)
        row.label:SetPoint('RIGHT', row, 'RIGHT', -246, 0)
        row.label:SetJustifyH('LEFT')
        row.label:SetWordWrap(false)

        row.copy = CreateTreeActionButton(row, 66, 'Copy')
        row.copy:SetSize(66, 24)
        row.copy:SetPoint('RIGHT', row, 'RIGHT', -152, 0)
        row.copy:SetText(T('Copy'))
        row.copy:SetScript('OnClick', function(self)
            local entry = self:GetParent().entry
            if entry and entry.importString then
                panel:Hide()
                ShowExportText(frame, T('Saved loadout — %s', entry.label or T('Build')), entry.importString)
            end
        end)

        row.create = CreateTreeActionButton(row, 66, 'Create')
        row.create:SetSize(66, 24)
        row.create:SetPoint('RIGHT', row, 'RIGHT', -80, 0)
        row.create:SetText(T('Create'))
        row.create:SetScript('OnClick', function(self)
            local entry = self:GetParent().entry
            if entry and addon.CreateSavedTalentLoadout then addon:CreateSavedTalentLoadout(entry) end
        end)

        row.delete = CreateTreeActionButton(row, 66, 'Delete')
        row.delete:SetSize(66, 24)
        row.delete:SetPoint('RIGHT', row, 'RIGHT', -8, 0)
        row.delete:SetText(T('Delete'))
        row.delete:SetScript('OnClick', function(self)
            local entry = self:GetParent().entry
            if not entry then return end
            local store = GetSavedBuildStore()
            for i = #store, 1, -1 do
                if store[i] == entry or store[i].key == entry.key then table.remove(store, i) end
            end
            if addon.RefreshSavedTalentBuildsPanel then addon:RefreshSavedTalentBuildsPanel(frame) end
        end)
        row:Hide()
        panel.rows[index] = row
    end

    panel.openTalents = CreateTreeActionButton(panel, 130, 'Open Talents')
    panel.openTalents:SetSize(130, 24)
    panel.openTalents:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -12, 10)
    panel.openTalents:SetText(T('Open Talents'))
    panel.openTalents:SetScript('OnClick', function()
        if addon.OpenBlizzardTalents then addon:OpenBlizzardTalents() end
    end)

    panel.empty = panel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    panel.empty:SetPoint('CENTER', panel, 'CENTER', 0, 0)
    panel.empty:SetText(T('No saved talent snapshots yet.'))
    panel.empty:SetTextColor(0.62, 0.70, 0.76)
    panel.empty:Hide()

    frame.savedPanel = panel
    return panel
end

function addon:RefreshSavedTalentBuildsPanel(frame)
    if not frame then return end
    local panel = EnsureSavedPanel(frame)
    local store = GetSavedBuildStore()
    local visibleCount = math.min(#store, #panel.rows)
    panel.empty:SetShown(visibleCount == 0)
    for index, row in ipairs(panel.rows) do
        local entry = store[index]
        if entry then
            row.entry = entry
            local suffix = entry.reviewedDate and string.format(' • %s %s', T('guide'), entry.reviewedDate) or ''
            row.label:SetText(string.format('%s • %s%s', entry.specName or tostring(entry.specID or ''), entry.label or T('Build'), suffix))
            if row.create then
                local canCreateSaved = GetCurrentSpecID() == SafeNumber(entry.specID) and type(entry.importString) == 'string' and entry.importString ~= '' and C_ClassTalents and C_ClassTalents.RequestNewConfig and C_ClassTalents.ImportLoadout
                SetTreeActionButtonEnabled(row.create, canCreateSaved and true or false)
            end
            row:Show()
        else
            row.entry = nil
            row:Hide()
        end
    end
    if frame.savedButton then
        frame.savedButton:SetText(T('Saved (%d)', #store))
        LayoutTreeActionButtons(frame)
    end
end

function addon:ToggleSavedTalentBuildsPanel(frame)
    if not frame then return end
    local panel = EnsureSavedPanel(frame)
    if panel:IsShown() then
        panel:Hide()
        return
    end
    if frame.exportPanel then frame.exportPanel:Hide() end
    self:RefreshSavedTalentBuildsPanel(frame)
    panel:Show()
end

function addon:CreateAlignedTalentLoadout(frame)
    if not frame or not frame.runtime or not frame.profile then return end
    local runtime = frame.runtime
    if not runtime.isAligned then
        if addon.Print then addon:Print(T('Align all mapped DK Mentor key nodes before creating the Blizzard loadout.')) end
        return
    end
    local importString, errorText = GenerateComparedLoadoutString(frame.specID, runtime.selectionConfigID)
    if not importString then
        if addon.Print then addon:Print(errorText or T('No valid Blizzard talent import string is available.')) end
        return
    end
    local name = BuildSuggestedLoadoutName(frame.specID, frame.profile, frame.profile.name)
    local ok, createError = CreateBlizzardLoadoutFromImportString(frame.specID, name, importString)
    if not ok and addon.Print then addon:Print(createError or T('Could not create Blizzard talent loadout.')) end
end

function addon:CreateSavedTalentLoadout(entry)
    if type(entry) ~= 'table' then return end
    local name = BuildSuggestedLoadoutName(entry.specID, {
        contextKey = entry.contextKey,
        heroSubTreeID = entry.heroSubTreeID,
    }, entry.label)
    local ok, createError = CreateBlizzardLoadoutFromImportString(entry.specID, name, entry.importString)
    if not ok and addon.Print then addon:Print(createError or T('Could not create Blizzard talent loadout.')) end
end

function addon:ShowBuildExportPanel(frame)
    if not frame or not frame.runtime then return end
    local importString, errorText = GenerateComparedLoadoutString(frame.specID, frame.runtime.selectionConfigID)
    if not importString then
        if addon.Print then addon:Print(errorText or T('Talent export is not available.')) end
        return
    end
    if frame.savedPanel then frame.savedPanel:Hide() end
    ShowExportText(frame, T('Talent loadout export — %s', frame.profile and frame.profile.name or T('Build')), importString)
end

function addon:SaveBuildTalentSnapshot(frame)
    if not frame or not frame.runtime or not frame.profile then return end
    local importString, errorText = GenerateComparedLoadoutString(frame.specID, frame.runtime.selectionConfigID)
    if not importString then
        if addon.Print then addon:Print(errorText or T('Talent snapshot could not be saved.')) end
        return
    end

    local store = GetSavedBuildStore()
    local profile = frame.profile
    local key = SavedBuildKey(frame.specID, profile)
    local now = (GetServerTime and GetServerTime()) or (time and time()) or 0
    local entry = {
        key = key,
        specID = frame.specID,
        specName = GetSpecNameSafe(frame.specID),
        label = profile.name or T('Build'),
        heroSpellID = SafeNumber(profile.heroSpellID),
        heroSubTreeID = SafeNumber(profile.heroSubTreeID),
        heroTalent = profile.heroTalent,
        contextKey = profile.contextKey,
        guideSpellIDs = BuildGuideSpellSnapshot(profile),
        reviewedDate = profile.reviewedDate,
        sourceName = profile.sourceName,
        sourceUpdated = profile.sourceUpdated,
        importString = importString,
        savedAt = now,
    }

    local existingIndex
    for index, saved in ipairs(store) do
        if saved.key == key then existingIndex = index; break end
    end
    if existingIndex then table.remove(store, existingIndex) end
    table.insert(store, 1, entry)
    while #store > MAX_SAVED_BUILDS do table.remove(store) end

    self:RefreshSavedTalentBuildsPanel(frame)
    if addon.Print then addon:Print(T('Talent snapshot saved: %s', entry.label)) end
end

function addon:ShowBuildTreeNodeTooltip(owner)
    if not owner or not owner.nodeData or not GameTooltip then return end
    local node = owner.nodeData
    local candidate = CandidateForDisplay(node)
    local spellID = candidate and candidate.spellID or owner.spellID
    GameTooltip:SetOwner(owner, 'ANCHOR_RIGHT')
    local shown = false
    if spellID and GameTooltip.SetSpellByID then
        local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, spellID)
        shown = ok == true
    end
    if not shown then GameTooltip:SetText(GetSpellNameSafe(spellID, owner.fallbackName or T('Talent'))) end
    GameTooltip:AddLine(' ')
    if node.recommendedSpellID then
        GameTooltip:AddLine(T('Guide key talent'), 1.00, 0.78, 0.25, true)
        if owner.guideReason and owner.guideReason ~= '' then
            GameTooltip:AddLine(T('Why: %s', T(owner.guideReason)), 0.82, 0.91, 0.96, true)
        end
        if node.selectedSpellID == node.recommendedSpellID and (node.selectedRank or 0) > 0 then
            GameTooltip:AddLine(T('Already selected in your loadout.'), 0.42, 1.00, 0.62, true)
        elseif node.selectedSpellID and node.selectedSpellID ~= node.recommendedSpellID then
            GameTooltip:AddLine(T('Your current choice differs from the guide key talent.'), 1.00, 0.62, 0.30, true)
        else
            GameTooltip:AddLine(T('Not selected in the compared loadout.'), 1.00, 0.78, 0.25, true)
        end
    elseif (node.selectedRank or 0) > 0 then
        GameTooltip:AddLine(T('Selected in your compared loadout.'), 0.48, 0.84, 1.00, true)
        GameTooltip:AddLine(T('Not marked as a required guide key talent; this may be a flex or pathing point.'), 0.72, 0.80, 0.86, true)
    else
        GameTooltip:AddLine(T('Available talent node. DK Mentor does not claim this flex node is required.'), 0.62, 0.70, 0.76, true)
    end
    GameTooltip:Show()
    local root = owner:GetParent() and owner:GetParent():GetParent() and owner:GetParent():GetParent():GetParent()
    if root then root.tooltipOwner = owner end
end

local function RenderGroup(group, nodes, nodeByID, label, groupKey)
    ResetGroup(group)
    group.title:SetText(T(label))
    if #nodes == 0 then
        group.empty:SetText(T('No nodes available'))
        group.empty:Show()
        return
    end

    local displayX = {}
    local rawMinX, rawMaxX
    for _, node in ipairs(nodes) do
        rawMinX = rawMinX and math.min(rawMinX, node.posX) or node.posX
        rawMaxX = rawMaxX and math.max(rawMaxX, node.posX) or node.posX
        displayX[node.nodeID] = node.posX
    end

    -- Hero subtree selector/root nodes can use slightly different Blizzard X
    -- coordinates even when they visually belong to one vertical spine. Center
    -- the first two singleton rows so the selector and its first hero node line
    -- up cleanly without altering the real trait-node data.
    if groupKey == 'hero' and #nodes > 0 then
        local rowsByY, rowYs = {}, {}
        for _, node in ipairs(nodes) do
            local rowKey = tostring(node.posY)
            if not rowsByY[rowKey] then
                rowsByY[rowKey] = { y = node.posY, nodes = {} }
                rowYs[#rowYs + 1] = rowKey
            end
            rowsByY[rowKey].nodes[#rowsByY[rowKey].nodes + 1] = node
        end
        table.sort(rowYs, function(a, b) return rowsByY[a].y < rowsByY[b].y end)
        local centerX = ((rawMinX or 0) + (rawMaxX or 0)) / 2
        for index = 1, math.min(2, #rowYs) do
            local row = rowsByY[rowYs[index]]
            if row and #row.nodes == 1 then displayX[row.nodes[1].nodeID] = centerX end
        end
    end

    local minX, maxX, minY, maxY
    for _, node in ipairs(nodes) do
        local x = displayX[node.nodeID] or node.posX
        minX = minX and math.min(minX, x) or x
        maxX = maxX and math.max(maxX, x) or x
        minY = minY and math.min(minY, node.posY) or node.posY
        maxY = maxY and math.max(maxY, node.posY) or node.posY
    end

    local width = math.max(80, (group:GetWidth() or 180) - (NODE_PADDING * 2) - NODE_SIZE)
    local height = math.max(80, (group:GetHeight() or 250) - 38 - NODE_SIZE)
    local spanX = math.max(1, (maxX or 1) - (minX or 0))
    local spanY = math.max(1, (maxY or 1) - (minY or 0))

    -- The Blizzard trait tree is considerably taller than it is wide. Using one
    -- uniform scale made the vertical span dictate the horizontal spacing too,
    -- which packed adjacent columns together. Give each axis its own fit scale
    -- so the preview consumes the full panel width and the taller r6 canvas.
    local scaleX = width / spanX
    local scaleY = height / spanY
    local usedW = spanX * scaleX
    local usedH = spanY * scaleY
    local offsetX = NODE_PADDING + math.max(0, (width - usedW) / 2)
    local offsetY = 28 + math.max(0, (height - usedH) / 2)
    local buttonByNodeID = {}

    for _, node in ipairs(nodes) do
        local button = AcquireNodeButton(group)
        ConfigureNodeButton(button, node)
        local x = offsetX + (((displayX[node.nodeID] or node.posX) - minX) * scaleX)
        local y = -(offsetY + ((node.posY - minY) * scaleY))
        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', group, 'TOPLEFT', x, y)
        buttonByNodeID[node.nodeID] = button
    end

    for _, node in ipairs(nodes) do
        local sourceButton = buttonByNodeID[node.nodeID]
        if sourceButton then
            for _, edge in ipairs(node.edges or {}) do
                local targetNode = nodeByID[edge.targetNode]
                local targetButton = targetNode and targetNode.group == node.group and buttonByNodeID[edge.targetNode] or nil
                if targetButton then
                    local line = AcquireLine(group)
                    if line and line.SetStartPoint and line.SetEndPoint then
                        if line.SetColorTexture then
                            if edge.active then line:SetColorTexture(0.78, 0.64, 0.18, 0.78)
                            else line:SetColorTexture(0.22, 0.40, 0.48, 0.52) end
                        end
                        if line.ClearAllPoints then pcall(line.ClearAllPoints, line) end
                        local okStart = pcall(line.SetStartPoint, line, 'CENTER', sourceButton, 'CENTER', 0, 0)
                        local okEnd = pcall(line.SetEndPoint, line, 'CENTER', targetButton, 'CENTER', 0, 0)
                        if okStart and okEnd then line:Show() else line:Hide() end
                    end
                end
            end
        end
    end
end

function addon:OpenBlizzardTalents()
    local function TryCall(func, ...)
        if type(func) ~= 'function' then return false end
        local ok, result = pcall(func, ...)
        if not ok then return false end
        return result == nil or result ~= false
    end
    if TryCall(_G.TogglePlayerSpellsFrame) then return true end
    if _G.PlayerSpellsMicroButton and TryCall(_G.PlayerSpellsMicroButton.Click, _G.PlayerSpellsMicroButton) then return true end
    if _G.TalentMicroButton and TryCall(_G.TalentMicroButton.Click, _G.TalentMicroButton) then return true end
    if _G.ShowUIPanel and _G.PlayerSpellsFrame and TryCall(_G.ShowUIPanel, _G.PlayerSpellsFrame) then return true end
    if addon.Print then addon:Print(T('Could not open Blizzard Talents automatically on this client.')) end
    return false
end

function addon:RenderBuildTalentTreePreview(root, specID, profile, width, y, profileIndex)
    if not root or not profile or profileIndex ~= 1 then return 0 end
    local frame = EnsureTreeFrame(root)
    frame:ClearAllPoints()
    frame:SetPoint('TOPLEFT', root, 'TOPLEFT', 2, y)
    frame:SetSize(width or 560, TREE_HEIGHT)
    frame.title:SetText(T('Talent tree — source check'))
    frame.openButton:SetText(T('Open Talents'))
    frame.createButton:SetText(T('Clone in WoW'))
    frame.exportButton:SetText(T('Export'))
    frame.saveButton:SetText(T('Save'))
    self:RefreshSavedTalentBuildsPanel(frame)
    LayoutTreeActionButtons(frame)
    frame.legend:SetText(T('Gold = recommended key • Blue = selected • Green = recommended + selected • Gray = flex / pathing'))

    local runtime, errorText = ReadTreeRuntime(specID, profile)
    frame.specID = specID
    frame.profile = profile
    frame.runtime = runtime
    if not runtime then
        frame.status:SetText(errorText or T('Talent tree data is not available yet.'))
        frame.keyStatus:SetText('')
        frame.status:SetTextColor(1.00, 0.72, 0.30)
        SetTreeActionButtonEnabled(frame.createButton, false)
        SetTreeActionButtonEnabled(frame.exportButton, false)
        SetTreeActionButtonEnabled(frame.saveButton, false)
        self:RefreshSavedTalentBuildsPanel(frame)
        for _, key in ipairs({ 'class', 'hero', 'spec' }) do
            local group = frame.groups[key]
            group:Hide()
        end
        frame:SetHeight(82)
        return 82
    end

    local compareText
    if runtime.selectionConfigID then
        compareText = T('Comparing against: %s', runtime.loadoutLabel or T('saved loadout'))
    else
        compareText = T('No saved loadout found for comparison')
    end
    frame.status:SetText(T('Context check: %d/%d mapped • %d/%d selected • %s', runtime.mappedKeys, runtime.totalKeys, runtime.selectedKeys, runtime.totalKeys, compareText))
    frame.status:SetTextColor(0.82, 0.89, 0.94)
    local coverageText = BuildCoverageText(profile)
    local keyText = BuildGuideStatusText(runtime)
    if keyText ~= '' then
        frame.keyStatus:SetText(coverageText .. '\n' .. keyText)
    else
        frame.keyStatus:SetText(coverageText)
    end

    local canExport = runtime.selectionConfigID ~= nil and GetCurrentSpecID() == SafeNumber(specID) and C_Traits and C_Traits.GenerateImportString
    local inCombat = InCombatLockdown and InCombatLockdown() or false
    local canCreateAligned = canExport and runtime.isAligned and not inCombat and C_ClassTalents and C_ClassTalents.RequestNewConfig and C_ClassTalents.ImportLoadout
    SetTreeActionButtonEnabled(frame.createButton, canCreateAligned and true or false)
    SetTreeActionButtonEnabled(frame.exportButton, canExport and true or false)
    SetTreeActionButtonEnabled(frame.saveButton, canExport and true or false)
    local createTooltipBody
    if canCreateAligned then
        createTooltipBody = T('Clone the Blizzard loadout currently being compared. This does not claim to recreate the full third-party guide unless an exact guide import is embedded and verified. Flex/pathing points are preserved; the new loadout is not activated automatically.')
    elseif not canExport then
        createTooltipBody = T('Switch to this specialization and load a saved Blizzard loadout before creating it directly in Blizzard Talents.')
    elseif inCombat then
        createTooltipBody = T('Cannot create talent loadouts in combat.')
    else
        createTooltipBody = BuildCreateBlockerText(runtime)
    end
    SetBuildActionTooltip(frame.createButton, 'Clone compared loadout in Blizzard Talents', createTooltipBody)
    SetBuildActionTooltip(frame.exportButton, 'Export compared loadout', canExport and 'Generate Blizzard\'s import string for the loadout currently being compared. Gold guide-only nodes are not auto-applied.' or 'Switch to this specialization and load a saved Blizzard loadout before exporting.')
    SetBuildActionTooltip(frame.saveButton, 'Save talent snapshot', canExport and 'Save the compared Blizzard loadout plus the current DK Mentor guide reference so you can copy it again later.' or 'Switch to this specialization and load a saved Blizzard loadout before saving a reusable snapshot.')
    SetBuildActionTooltip(frame.savedButton, 'Saved talent snapshots', 'Open your DK Mentor talent snapshot library. Copy a saved Blizzard import string, create it directly in Blizzard Talents, or delete old snapshots.')
    self:RefreshSavedTalentBuildsPanel(frame)

    local totalWidth = width or 560
    local innerWidth = totalWidth - 20
    local distributableWidth = math.max(240, innerWidth - (GROUP_GAP * 2))
    -- Class/spec trees carry considerably more nodes than the Hero tree.
    -- Give them 40% each and keep Hero at 20% so the dense trees gain room.
    local classWidth = math.floor(distributableWidth * 0.40)
    local heroWidth = math.floor(distributableWidth * 0.20)
    local specWidth = distributableWidth - classWidth - heroWidth
    local groupHeight = TREE_HEIGHT - HEADER_HEIGHT - 10

    local classGroup = frame.groups.class
    local heroGroup = frame.groups.hero
    local specGroup = frame.groups.spec
    for _, group in ipairs({ classGroup, heroGroup, specGroup }) do group:Show(); group:ClearAllPoints(); group:SetHeight(groupHeight) end
    classGroup:SetPoint('TOPLEFT', frame, 'TOPLEFT', 8, -HEADER_HEIGHT)
    classGroup:SetWidth(classWidth)
    heroGroup:SetPoint('LEFT', classGroup, 'RIGHT', GROUP_GAP, 0)
    heroGroup:SetWidth(heroWidth)
    specGroup:SetPoint('LEFT', heroGroup, 'RIGHT', GROUP_GAP, 0)
    specGroup:SetPoint('RIGHT', frame, 'RIGHT', -8, 0)

    RenderGroup(classGroup, runtime.groups.class, runtime.nodeByID, 'Class tree', 'class')
    RenderGroup(heroGroup, runtime.groups.hero, runtime.nodeByID, 'Hero tree', 'hero')
    RenderGroup(specGroup, runtime.groups.spec, runtime.nodeByID, 'Spec tree', 'spec')

    return TREE_HEIGHT
end

DKM.TalentTree = DKM.TalentTree or {}
DKM.TalentTree.ReadTreeRuntime = ReadTreeRuntime
DKM.TalentTree.CreateBlizzardLoadoutFromImportString = CreateBlizzardLoadoutFromImportString
DKM.TalentTree.FinishPendingLoadoutCreate = FinishPendingLoadoutCreate
