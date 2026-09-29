local DKM = { T = function(v, ...) if select('#', ...) > 0 then return string.format(v, ...) end return v end }
assert(loadfile('Builds.lua'))('DKMentor', DKM)
assert(loadfile('Guides.lua'))('DKMentor', DKM)

local unholy = assert(DKM.Builds[252])
assert(unholy.world[1].heroTalent == 'Rider of the Apocalypse' and unholy.world[1].badge == 'RECOMMENDED', 'Open World should keep Rider as the current Best direction')
assert(unholy.world[1].freshness == 'current', 'Unholy PvE source should be current after recommendation consolidation')

for _, context in ipairs({ 'delve', 'dungeon', 'mythicplus', 'raid' }) do
    local profiles = assert(unholy[context], 'Missing Unholy context: ' .. context)
    assert(profiles[1].heroTalent == "San'layn" and profiles[1].badge == 'RECOMMENDED', context .. ' should promote Sanlayn')
    assert(profiles[2].heroTalent == 'Rider of the Apocalypse' and profiles[2].badge == 'ALTERNATIVE', context .. ' should retain Rider as alternative')
    assert(profiles[1].reviewedDate == '2026-09-26', context .. ' review date must be 2026-09-26')
    local blightfall = false
    for _, entry in ipairs(profiles[1].keyTalents or {}) do
        if entry.spellID == 1242616 then blightfall = true end
    end
    assert(blightfall, context .. ' Sanlayn profile must expose Blightfall')
end

assert(unholy.raid[1].treeCoverage == 'hero-only', 'Raid recommendation must stay Hero-only rather than claiming a full guide import')
assert(unholy.mythicplus[1].treeCoverage == 'context-markers', 'Mythic+ Sanlayn should use current context markers')
assert(unholy.delve[1].treeCoverage == 'context-markers', 'Delve Sanlayn should use current context markers')
assert(unholy.mythicplus[2].sbaFriendly == true, 'Rider should remain the SBA-friendly Unholy alternative')
assert(unholy.mythicplus[1].sbaFriendly == false, 'Sanlayn should not be mislabeled SBA-friendly')

local pvp = assert(unholy.pvp)
assert(pvp[1].heroTalent == 'Rider of the Apocalypse' and pvp[1].badge == 'RECOMMENDED', 'PvP ordering must remain unchanged pending a post-tuning Icy Veins refresh')
assert(pvp[1].freshness == 'review' and pvp[2].freshness == 'review', 'Unholy PvP must remain review-pending')

local guideText = ''
for _, section in ipairs(assert(DKM.Guides[252].sections)) do
    guideText = guideText .. ' ' .. tostring(section.heading or '') .. ' ' .. tostring(section.body or '')
end
assert(guideText:find("San'layn / Blightfall timing", 1, true), 'Unholy guide must expose Sanlayn/Blightfall timing')
assert(guideText:find('Soul Reaper', 1, true) and guideText:find('Putrefy', 1, true), 'Blightfall timing must include Soul Reaper and Putrefy alignment')

local AD = { T = DKM.T }
assert(loadfile('AdvisorData.lua'))('DKMentor', AD)
assert(AD.AdvisorData.freshness.builds[250] == 'review' and AD.AdvisorData.freshness.builds[251] == 'review', 'Blood/Frost must remain review pending')
assert(AD.AdvisorData.freshness.builds[252] == 'current', 'Unholy PvE build freshness should now be current')

local VA = { T = DKM.T }
assert(loadfile('ValeeraData.lua'))('DKMentor', VA)
for specID = 250, 252 do
    local nemesis = assert(VA.ValeeraData.recommendations[specID].nemesis)
    assert(nemesis.role == 'healer' and nemesis.combat == 'bilespear' and nemesis.utility == 'dreamcatcher' and nemesis.poison == 'phantasmal', 'Valeera Nemesis preset must not churn in 3.3.3')
end

print('DK Mentor 3.3.3 Unholy meta consolidation smoke test passed')
