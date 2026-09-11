local DKM = { T = function(v, ...) if select('#', ...) > 0 then return string.format(v, ...) end return v end }
assert(loadfile('Builds.lua'))('DKMentor', DKM)

local frostDelve = assert(DKM.Builds[251].delve[1])
assert(frostDelve.heroTalent == 'Deathbringer', 'Frost Delve must keep current Wowhead Deathbringer direction')
assert(frostDelve.treeCoverage == 'hero-only', 'Frost Delve must not reuse Raid/M+ markers as if they were an exact Delve tree')
assert(#(frostDelve.treeKeyTalents or {}) == 0, 'Frost Delve should validate Hero Talent only until exact guide import is embedded')

local frostMplus = assert(DKM.Builds[251].mythicplus[1])
assert(frostMplus.treeCoverage == 'context-markers', 'Frost M+ should use current context markers')
assert(#frostMplus.treeKeyTalents == 4, 'Frost M+ current marker set should contain four confirmed guide nodes')

local bloodRaid = assert(DKM.Builds[250].raid[1])
local bloodMplus = assert(DKM.Builds[250].mythicplus[1])
assert(bloodRaid.treeKeyTalents ~= bloodMplus.treeKeyTalents, 'Blood Raid and M+ must not share one generic validation set')

local unholyRaid = assert(DKM.Builds[252].raid[1])
local unholyMplus = assert(DKM.Builds[252].mythicplus[1])
assert(unholyRaid.treeCoverage == 'hero-only', 'Unholy ST/Raid must stay conservative without an exact current Wowhead import')
assert(unholyMplus.treeCoverage == 'context-markers', 'Unholy M+ must use context-specific markers')
assert(#unholyMplus.treeKeyTalents >= 2, 'Unholy M+ Rider markers missing')

assert(frostMplus.reviewedDate == '2026-09-11', 'Build source audit date must be current')
local unholyPvp = assert(DKM.Builds[252].pvp)
assert(unholyPvp[1].badge == 'RECOMMENDED' and unholyPvp[1].heroTalent == 'Rider of the Apocalypse', 'Unholy PvP Pet/Rider should be the practical default after resolving source contradiction')
assert(unholyPvp[2].badge == 'ALTERNATIVE' and unholyPvp[2].heroTalent == "San'layn", "Unholy PvP Disease/San'layn should remain the rot alternative")
print('DK Mentor 3.3.1 guidance refresh smoke test passed')
