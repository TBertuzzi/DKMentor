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
    GetConfigInfo = function() return { treeIDs={200}, name='Diagnostic regression' } end,
    GetTreeNodes = function() return {1,2} end,
    GetNodeInfo = function(_, nodeID)
        if nodeID == 1 then
            return { posX=100, posY=100, type=0, entryIDs={101}, currentRank=1, activeEntryID=101, visibleEdges={} }
        end
        return { posX=300, posY=120, type=3, entryIDs={201,202}, currentRank=0, activeEntryID=201, visibleEdges={} }
    end,
    GetEntryInfo = function(_, entryID)
        if entryID == 201 then return { subTreeID=33, maxRanks=1 } end
        if entryID == 202 then return { subTreeID=32, maxRanks=1 } end
        return { definitionID=1000+entryID, maxRanks=1 }
    end,
    GetDefinitionInfo = function(definitionID)
        local entryID = definitionID - 1000
        if entryID == 101 then return { spellID=1111 } end
        return { spellID=9000+entryID }
    end,
    GetSubTreeInfo = function(_, subTreeID)
        return { ID=subTreeID, name=(subTreeID == 33 and 'Deathbringer' or 'Rider'), iconElementID='mock-atlas' }
    end,
}
C_Spell = {
    GetSpellName = function(spellID)
        if spellID == 1111 then return 'Mapped talent' end
        if spellID == 2222 then return 'Unmapped talent' end
        return nil
    end,
}

assert(loadfile('TalentTree.lua'))('DKMentor', DKM)
local reader = assert(DKM.TalentTree and DKM.TalentTree.ReadTreeRuntime)
local runtime, err = reader(251, {
    heroTalent='Deathbringer',
    heroSpellID=434765,
    heroSubTreeID=33,
    treeKeyTalents={
        { spellID=1111, fallbackName='Mapped talent' },
        { spellID=2222, fallbackName='Unmapped talent' },
    },
})
assert(runtime, err or 'runtime missing')
assert(runtime.totalKeys == 3, 'expected two talent keys plus Hero subtree')
assert(runtime.mappedKeys == 2, 'one guide key should remain unmapped')
assert(runtime.selectedKeys == 2, 'mapped keys should be selected')
assert(runtime.isAligned == false, 'unmapped guide key must block aligned state')

local byName = {}
for _, item in ipairs(runtime.guideStatus or {}) do byName[item.name] = item end
assert(byName['Mapped talent'] and byName['Mapped talent'].state == 'ok', 'mapped selected talent must report OK')
assert(byName['Unmapped talent'] and byName['Unmapped talent'].state == 'unmapped', 'unmapped talent must be named explicitly')
assert(byName['Deathbringer'] and byName['Deathbringer'].state == 'ok', 'Hero subtree must report OK')

local f = assert(io.open('TalentTree.lua', 'r'))
local tree = f:read('*a')
f:close()
assert(tree:find("local keyText = BuildGuideStatusText(runtime)", 1, true), 'visible per-key diagnostic line missing')
assert(tree:find("BuildCoverageText(profile)", 1, true), 'source-coverage explanation missing')
assert(tree:find("DK Mentor could not map: %s", 1, true), 'blocked-create tooltip must identify mapper failures')
assert(tree:find("local HEADER_HEIGHT = 105", 1, true), 'diagnostic header spacing regression')

print('DK Mentor 3.3 talent-tree diagnostic smoke test passed')
