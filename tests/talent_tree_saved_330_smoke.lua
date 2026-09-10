local DKM = {
    Addon = {},
    T = function(value, ...)
        if select('#', ...) > 0 then return string.format(value, ...) end
        return value
    end,
}

function DKM.Addon:GetSpecInfo() return 251 end
function DKM.Addon:Print(message) self.lastPrint = message end
C_Traits = {
    GenerateImportString = function(configID)
        assert(configID == 100, 'unexpected configID')
        return 'MOCK-BLIZZARD-IMPORT-STRING'
    end,
}

DKMentorDB = {}

assert(loadfile('TalentTree.lua'))('DKMentor', DKM)
assert(type(DKM.Addon.SaveBuildTalentSnapshot) == 'function', 'snapshot saver missing')
DKM.Addon.RefreshSavedTalentBuildsPanel = function() end

local frame = {
    specID = 251,
    runtime = { selectionConfigID = 100 },
    profile = {
        name = 'Frost — Mythic+',
        heroTalent = 'Deathbringer',
        heroSpellID = 434765,
        reviewedDate = '2026-09-06',
        sourceName = 'Wowhead',
        sourceUpdated = '2026-09-05',
        treeKeyTalents = {
            { spellID = 1230301 },
            { spellID = 435005 },
        },
    },
}

DKM.Addon:SaveBuildTalentSnapshot(frame)
assert(type(DKMentorDB.savedTalentBuilds) == 'table', 'saved talent library missing')
assert(#DKMentorDB.savedTalentBuilds == 1, 'snapshot was not stored')
local saved = DKMentorDB.savedTalentBuilds[1]
assert(saved.importString == 'MOCK-BLIZZARD-IMPORT-STRING', 'Blizzard import string not stored')
assert(saved.heroSpellID == 434765, 'Hero Talent ID not stored')
assert(#saved.guideSpellIDs == 3, 'guide spell snapshot should contain hero plus two guide nodes')

-- Saving the same guide should replace it instead of producing duplicates.
DKM.Addon:SaveBuildTalentSnapshot(frame)
assert(#DKMentorDB.savedTalentBuilds == 1, 'same guide snapshot should update in place')

print('DK Mentor 3.3 saved talent snapshot smoke test passed')
