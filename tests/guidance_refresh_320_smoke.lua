-- DK Mentor 3.2.0 r11 guidance refresh regression smoke test.
local DKM = { T = function(v, ...) if select("#", ...) > 0 then return string.format(v, ...) end return v end }
assert(loadfile("Builds.lua"))("DKMentor", DKM)
assert(loadfile("PreparationData.lua"))("DKMentor", DKM)
assert(loadfile("AdvisorData.lua"))("DKMentor", DKM)
assert(loadfile("GearData.lua"))("DKMentor", DKM)

local frostMplus = assert(DKM.Builds[251].mythicplus[1], "Frost M+ profile missing")
assert(frostMplus.heroTalent == "Deathbringer", "Frost M+ Deathbringer default changed unexpectedly")
assert(frostMplus.note:find("Smothering Offense", 1, true), "Frost M+ Smothering Offense note missing")
assert(frostMplus.note:find("Frostbane", 1, true), "Frost M+ Frostbane de-recommendation note missing")
assert(frostMplus.freshness == "current", "Frost M+ guidance should be current after r11 review")
assert(frostMplus.sourceUpdated == "2026-09-05", "Frost M+ source date should reflect the September 5 guide refresh")
assert(DKM.Builds[252].mythicplus[1].freshness == "current", "Unholy M+ guidance should be current after r11 review")

local frost = assert(DKM.PreparationData.specs[251], "Frost Preparation missing")
assert(frost.consumables.combatPotion[1].itemID == 241288, "Potion of Recklessness must be Frost recommended potion")
assert(frost.consumables.combatPotion[2].itemID == 241308, "Light's Potential must be Frost alternative potion")
local hasShatteringRazorice, hasOtherDwStoneskin, hasOld2H = false, false, false
for _, entry in ipairs(frost.runeforge) do
    if entry.enchantID == 3370 and entry.mode == "dual" and entry.conditionSpellID == 207057 then hasShatteringRazorice = true end
    if entry.enchantID == 3847 and entry.mode == "dual" and entry.inverseConditionSpellID == 207057 then hasOtherDwStoneskin = true end
    if entry.mode == "twohand" and entry.enchantID == 3370 then hasOld2H = true end
end
assert(hasShatteringRazorice, "Shattering Blade Razorice rule missing")
assert(hasOtherDwStoneskin, "Non-Shattering dual-wield Stoneskin rule missing")
assert(not hasOld2H, "Obsolete two-hand Razorice alternative returned")

assert(DKM.AdvisorData.reviewed == "2026-09-06", "Advisor review date mismatch")
assert(DKM.AdvisorData.freshness.builds[251] == "current", "Frost build freshness should be current")
assert(DKM.AdvisorData.freshness.builds[252] == "current", "Unholy build freshness should be current")
assert(DKM.GearData.reviewed == "2026-09-08", "Gear review date mismatch")
assert(DKM.GearData.specs[251].sourceUpdated == "2026-09-02", "Frost gear source date mismatch")
assert(DKM.GearData.specs[252].sourceUpdated == "2026-09-08", "Unholy gear source date mismatch")

local dataFile = assert(io.open("Data.lua", "r"))
local dataText = dataFile:read("*a")
dataFile:close()
assert(dataText:find("Frostbane", 1, true), "Frostbane tracking should remain available")

local coreFile = assert(io.open("Core.lua", "r"))
local core = coreFile:read("*a")
coreFile:close()
assert(core:find("ready = mainEnchant == 3368", 1, true), "Frost 2H Ready Check must require Fallen Crusader")
assert(not core:find("Two%-Hand Breathbane"), "Obsolete Breathbane Ready Check text returned")

print("DK Mentor 3.2.0 r11 guidance refresh smoke test passed")
