local DKM = { T = function(v, ...) if select('#', ...) > 0 then return string.format(v, ...) end return v end }
assert(loadfile('Builds.lua'))('DKMentor', DKM)

local bloodRaid = assert(DKM.Builds[250].raid)
assert(bloodRaid[1].sourceUpdated == '2026-09-21', 'Blood source date must reflect the current pre-tuning Wowhead page')
assert(bloodRaid[1].freshness == 'review' and bloodRaid[2].freshness == 'review', 'Blood post-tuning build ranking must be review pending')

local frostMplus = assert(DKM.Builds[251].mythicplus[1])
assert(frostMplus.freshness == 'review', 'Frost PvE must be review pending after September 22 tuning')
assert(#(frostMplus.treeKeyTalents or {}) == 4, 'Frost M+ thresholds/markers must remain intact')
local frostPvp = assert(DKM.Builds[251].pvp[1])
assert(frostPvp.freshness == 'current', 'Frost PvP should stay current because September 22 Frost buffs exclude PvP')

local unholyRaid = assert(DKM.Builds[252].raid)
assert(#unholyRaid == 2, 'Unholy Raid should expose Rider plus Sanlayn Blightfall review candidate')
local sanlaynRaid, riderRaid
for _, profile in ipairs(unholyRaid) do
    if profile.heroTalent == "San'layn" then sanlaynRaid = profile end
    if profile.heroTalent == 'Rider of the Apocalypse' then riderRaid = profile end
end
assert(sanlaynRaid and riderRaid, 'Unholy Raid must retain both Rider and Sanlayn directions')
assert(sanlaynRaid.treeCoverage == 'hero-only', 'Unholy Raid Sanlayn profile must not claim an exact third-party talent import')
local foundBlightfall = false
for _, entry in ipairs(sanlaynRaid.keyTalents or {}) do
    if entry.spellID == 1242616 then foundBlightfall = true end
end
assert(foundBlightfall, 'Sanlayn Raid profile must expose Blightfall as a key talent')

local sanlaynMplus
for _, profile in ipairs(assert(DKM.Builds[252].mythicplus)) do
    if profile.heroTalent == "San'layn" then sanlaynMplus = profile end
end
assert(sanlaynMplus, 'Sanlayn Mythic+ profile must remain available')
local mplusBlightfall = false
for _, entry in ipairs(sanlaynMplus.keyTalents or {}) do
    if entry.spellID == 1242616 then mplusBlightfall = true end
end
assert(mplusBlightfall, 'Sanlayn Mythic+ profile should expose Blightfall after the hotfix')

local unholyPvp = assert(DKM.Builds[252].pvp)
assert(unholyPvp[1].freshness == 'review' and unholyPvp[2].freshness == 'review', 'Unholy PvP must be review pending after direct Sanlayn PvP tuning')
assert(unholyPvp[1].badge == 'RECOMMENDED' and unholyPvp[1].heroTalent == 'Rider of the Apocalypse', 'Pet/Rider remains provisional recommendation')
assert(unholyPvp[2].badge == 'ALTERNATIVE' and unholyPvp[2].heroTalent == "San'layn", 'Disease/Sanlayn remains alternative pending Icy Veins refresh')
assert(unholyPvp[1].reviewedDate >= '2026-09-24', 'Build review date must not regress before 2026-09-24')

local VA = { T = DKM.T }
assert(loadfile('ValeeraData.lua'))('DKMentor', VA)
assert(VA.ValeeraData.reviewed >= '2026-09-24', 'Valeera review date must not regress')
assert(VA.ValeeraData.liveHotfixes[1].date == '2026-09-23', 'Valeera faction-change hotfix must be first')
assert((VA.ValeeraData.liveHotfixes[1].label or ''):find('Faction%-change'), 'Valeera faction-change hotfix label missing')
for specID = 250, 252 do
    local nemesis = assert(VA.ValeeraData.recommendations[specID].nemesis)
    assert(nemesis.role == 'healer' and nemesis.combat == 'bilespear' and nemesis.utility == 'dreamcatcher' and nemesis.poison == 'phantasmal', 'Nemesis preset must remain unchanged for all DK specs')
end

local GD = { T = DKM.T }
assert(loadfile('GearData.lua'))('DKMentor', GD)
assert(GD.GearData.reviewed == '2026-09-24', 'Gear review date must advance without target churn')

local PD = { T = DKM.T }
assert(loadfile('PreparationData.lua'))('DKMentor', PD)
assert(PD.PreparationData.reviewed == '2026-09-24', 'Preparation review date must advance')

local AD = { T = DKM.T }
assert(loadfile('AdvisorData.lua'))('DKMentor', AD)
assert(AD.AdvisorData.reviewed >= '2026-09-24', 'Advisor review date must not regress')
assert(AD.AdvisorData.freshness.builds[250] == 'review' and AD.AdvisorData.freshness.builds[251] == 'review', 'Blood/Frost build freshness must remain review-pending until their post-tuning guides consolidate')
assert(AD.AdvisorData.freshness.builds[252] == 'review' or AD.AdvisorData.freshness.builds[252] == 'current', 'Unholy build freshness must be a valid review/current state')
assert(AD.AdvisorData.freshness.gear[250] == 'current' or AD.AdvisorData.freshness.gear[250] == 'review', 'Gear freshness must remain a valid state')

print('DK Mentor 3.3.2 regression-boundary smoke test passed')
