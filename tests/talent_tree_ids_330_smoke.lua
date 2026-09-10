-- Regression for localized/overridden talent IDs and rank-0 choice nodes.
local DKM = {
    Addon = {},
    T = function(value, ...)
        if select('#', ...) > 0 then return string.format(value, ...) end
        return value
    end,
}
function DKM.Addon:GetSpecInfo() return 251 end

C_ClassTalents = { GetActiveConfigID = function() return 100 end }
C_Traits = {
    GetConfigInfo = function() return { treeIDs={200}, name='ID regression' } end,
    GetTreeNodes = function() return {1,2,3} end,
    GetNodeInfo = function(_, nodeID)
        if nodeID == 1 then
            return { posX=100, posY=100, type=2, entryIDs={101,102}, currentRank=0, activeEntryID=101, visibleEdges={} }
        elseif nodeID == 2 then
            return { posX=300, posY=120, type=3, entryIDs={201,202}, currentRank=0, activeEntryID=201, visibleEdges={} }
        end
        return { posX=600, posY=200, type=0, entryIDs={301}, currentRank=1, activeEntryID=301, visibleEdges={} }
    end,
    GetEntryInfo = function(_, entryID)
        if entryID == 201 then return { subTreeID=33, maxRanks=1 } end
        if entryID == 202 then return { subTreeID=32, maxRanks=1 } end
        return { definitionID=1000+entryID, maxRanks=1 }
    end,
    GetDefinitionInfo = function(definitionID)
        local entryID = definitionID - 1000
        if entryID == 101 then
            -- Guide stores the overridden/base ID while the client exposes another primary ID.
            return { spellID=2001, overriddenSpellID=1001 }
        elseif entryID == 102 then
            return { spellID=2002, overriddenSpellID=1002 }
        end
        return { spellID=9000+entryID }
    end,
    GetSubTreeInfo = function(_, subTreeID)
        return { ID=subTreeID, name=(subTreeID == 33 and 'Deathbringer' or 'Rider'), iconElementID='mock-atlas' }
    end,
}

assert(loadfile('TalentTree.lua'))('DKMentor', DKM)
local reader = assert(DKM.TalentTree.ReadTreeRuntime)
local runtime, err = reader(251, {
    heroTalent='Deathbringer',
    heroSpellID=434765,
    heroSubTreeID=33,
    treeKeyTalents={ { spellID=1001, fallbackName='Localized choice' } },
})
assert(runtime, err or 'runtime missing')
assert(runtime.totalKeys == 2, 'expected one talent key plus Hero subtree')
assert(runtime.mappedKeys == 2, 'stable ID aliases/subtree IDs must map both keys')
assert(runtime.selectedKeys == 2, 'rank-0 Selection/SubTreeSelection must count as selected by entry ID')
assert(runtime.isAligned == true, 'fully selected ID-based build should be aligned')
assert(runtime.nodeByID[1].recommendedEntryID == 101, 'overridden spell alias did not map')
assert(runtime.nodeByID[2].recommendedSubTreeID == 33, 'Hero subtree stable ID did not map')
print('DK Mentor 3.3 stable talent ID smoke test passed')
