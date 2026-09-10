-- DK Mentor 3.2.1 Unholy gear data hotfix regression smoke test.
local DKM = {}
assert(loadfile("GearData.lua"))("DKMentor", DKM)

local gear = assert(DKM.GearData, "GearData missing")
local unholy = assert(gear.specs[252], "Unholy GearData missing")
assert(gear.reviewed == "2026-09-08", "GearData review date must be September 8")
assert(unholy.sourceUpdated == "2026-09-08", "Unholy source date must be September 8")

local targets = {}
for _, target in ipairs(unholy.targets or {}) do
    targets[target.itemID] = target
end

local vile = assert(targets[268249], "Vile Alchemist's Band target missing")
assert(vile.slot == "Finger", "Vile Alchemist's Band must be a Finger target")
assert(vile.source:find("Vashnik", 1, true), "Vile Alchemist's Band source must reference Vashnik")

local atroxus = assert(targets[252258], "Sickening Signet of Atroxus target missing")
assert(atroxus.slot == "Finger", "Sickening Signet of Atroxus must be a Finger target")
assert(atroxus.source:find("Atroxus", 1, true), "Sickening Signet source must reference Atroxus")

for _, target in ipairs(unholy.targets or {}) do
    assert(target.fallbackName ~= "Band of the Amani Warlord", "Obsolete Amani Warlord ring must not be a current Unholy target")
end

print("DK Mentor 3.2.1 Unholy gear hotfix smoke test passed")
