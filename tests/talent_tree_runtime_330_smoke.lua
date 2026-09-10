-- DK Mentor 3.3 runtime talent-tree inspection smoke test.
local DKM = {
    Addon = {},
    T = function(value, ...)
        if select('#', ...) > 0 then return string.format(value, ...) end
        return value
    end,
}

function DKM.Addon:GetSpecInfo() return 251 end

Constants = { TraitConsts = { VIEW_TRAIT_CONFIG_ID = 999 } }
C_ClassTalents = {
    GetActiveConfigID = function() return 100 end,
}

local nodeInfo = {
    [1] = { posX=100, posY=100, entryIDs={101}, maxRanks=1, currentRank=1, activeEntryID=101, visibleEdges={{targetNode=2,isActive=true}} },
    [2] = { posX=500, posY=200, entryIDs={102}, maxRanks=1, currentRank=0, visibleEdges={} },
    -- Hero selection is a SubTreeSelection choice and can report rank 0 while selected.
    [3] = { posX=300, posY=150, entryIDs={103,105}, maxRanks=1, type=3, currentRank=0, activeEntryID=103, visibleEdges={} },
    [4] = { posX=650, posY=300, entryIDs={104}, maxRanks=1, currentRank=1, activeEntryID=104, visibleEdges={} },
}
local spellByEntry = { [101]=47528, [102]=1230301, [104]=194913 }

C_Traits = {
    GetConfigInfo = function(configID)
        assert(configID == 100)
        return { treeIDs={200}, name='Mock Frost' }
    end,
    GetTreeNodes = function(treeID)
        assert(treeID == 200)
        return {1,2,3,4}
    end,
    GetNodeInfo = function(configID, nodeID)
        assert(configID == 100)
        return nodeInfo[nodeID]
    end,
    GetEntryInfo = function(configID, entryID)
        assert(configID == 100)
        if entryID == 103 then return { definitionID=nil, maxRanks=1, subTreeID=33 } end
        if entryID == 105 then return { definitionID=nil, maxRanks=1, subTreeID=32 } end
        return { definitionID=1000+entryID, maxRanks=1 }
    end,
    GetDefinitionInfo = function(definitionID)
        local entryID = definitionID - 1000
        return { spellID=spellByEntry[entryID] }
    end,
    GetSubTreeInfo = function(_, subTreeID)
        return { ID=subTreeID, name=(subTreeID == 33 and 'Deathbringer' or 'Rider'), iconElementID='mock-atlas' }
    end,
}

assert(loadfile('TalentTree.lua'))('DKMentor', DKM)
local reader = assert(DKM.TalentTree and DKM.TalentTree.ReadTreeRuntime, 'TalentTree runtime reader missing')
local profile = {
    heroTalent='Deathbringer',
    heroSpellID=434765,
    heroSubTreeID=33,
    keyTalents={ {spellID=999999} }, -- Must be ignored when treeKeyTalents exists.
    treeKeyTalents={ {spellID=1230301, fallbackName='Frostreaper', reason='mock reason'} },
}
local runtime, err = reader(251, profile)
assert(runtime, err or 'runtime missing')
assert(runtime.totalKeys == 2, 'treeKeyTalents should replace compact keyTalents and add the Hero subtree key')
assert(runtime.mappedKeys == 2, 'guide talent plus Hero subtree should map onto Blizzard nodes')
assert(runtime.selectedKeys == 1, 'selected Hero subtree must count even when Blizzard reports rank 0')
assert(#runtime.groups.hero == 1, 'hero subtree grouping failed')
assert(#runtime.groups.class >= 1 and #runtime.groups.spec >= 1, 'class/spec grouping failed')
assert(runtime.nodeByID[2].recommendedSpellID == 1230301, 'Frostreaper key mapping failed')
assert(runtime.nodeByID[2].recommendedTalent.reason == 'mock reason', 'guide reason metadata lost')
assert(runtime.nodeByID[3].recommendedSubTreeID == 33, 'Hero subtree ID mapping failed')
assert(runtime.nodeByID[3].recommendedEntryID == 103, 'Hero subtree entry mapping failed')
print('DK Mentor 3.3 talent-tree runtime smoke test passed')
