-- DK Mentor 3.3 Meta Pulse data + guide-alignment smoke test.
local DKM = {
    T = function(value, ...)
        if select("#", ...) > 0 then return string.format(value, ...) end
        return value
    end,
}

assert(loadfile("Builds.lua"))("DKMentor", DKM)
assert(loadfile("MetaData.lua"))("DKMentor", DKM)

local meta = assert(DKM.MetaData, "MetaData missing")
assert(meta.patch == "12.1.0", "Unexpected Meta patch")
assert(meta.reviewed == "2026-09-08", "Meta review date missing")
assert(#meta.contextOrder == 3, "Expected Raid, Mythic+, and High Keys Meta contexts")
assert(meta.contextOrder[1] == "raid" and meta.contextOrder[2] == "mythicplus" and meta.contextOrder[3] == "highkeys", "Unexpected Meta context order")

local raid = assert(meta.contexts.raid, "Raid Meta context missing")
local plus = assert(meta.contexts.mythicplus, "Mythic+ Meta context missing")
local high = assert(meta.contexts.highkeys, "High Keys Meta context missing")

assert(raid.specs[251].hero == "Deathbringer" and raid.specs[251].heroUsage == 96.8, "Frost Raid Meta snapshot mismatch")
assert(raid.specs[252].hero == "Rider of the Apocalypse" and raid.specs[252].heroUsage == 54.2, "Unholy Raid Meta snapshot mismatch")
assert(plus.specs[250].hero == "San'layn" and plus.specs[250].heroUsage == 87.9, "Blood M+ Meta snapshot mismatch")
assert(plus.specs[251].hero == "Deathbringer" and plus.specs[251].heroUsage == 97.4, "Frost M+ Meta snapshot mismatch")
assert(plus.specs[252].hero == "San'layn" and plus.specs[252].heroUsage == 53.3, "Unholy M+ Meta snapshot mismatch")
assert(high.specs[250].heroUsage == 98.5, "Blood High Keys Meta snapshot mismatch")
assert(high.specs[251].heroUsage == 99.5, "Frost High Keys Meta snapshot mismatch")
assert(high.specs[252].hero == "San'layn" and high.specs[252].heroUsage == 80.9, "Unholy High Keys Meta snapshot mismatch")
assert(high.specs[251].weaponUsage == 48.9, "Frost High Keys observed weapon snapshot mismatch")
assert(high.specs[251].heroSpellID == meta.heroSpellIDs["Deathbringer"], "Frost High Keys observed Hero Talent ID mismatch")
assert(high.specs[252].heroSpellID == meta.heroSpellIDs["San'layn"], "Unholy High Keys observed Hero Talent ID mismatch")
assert(high.specs[251].alternativeHeroSpellID == meta.heroSpellIDs["Rider of the Apocalypse"], "Frost alternative Hero Talent ID mismatch")
assert(meta.heroSpellIDs["Deathbringer"] == 434765, "Deathbringer stable spell ID missing")
assert(meta.heroSpellIDs["San'layn"] == 433895, "San'layn stable spell ID missing")
assert(meta.heroSpellIDs["Rider of the Apocalypse"] == 444040, "Rider stable spell ID missing")
assert(DKM.Builds[251].mythicplus[1].heroSpellID == meta.heroSpellIDs[high.specs[251].hero], "Frost High Keys should align by spell ID")

assert(DKM.Builds[250].mythicplus[1].heroTalent == "Deathbringer", "Blood guide default changed unexpectedly")
assert(DKM.Builds[251].mythicplus[1].heroTalent == "Deathbringer", "Frost guide default changed unexpectedly")
assert(DKM.Builds[252].mythicplus[1].heroTalent == "Rider of the Apocalypse", "Unholy guide default changed unexpectedly")

print("DK Mentor 3.3 Meta Pulse smoke test passed")
