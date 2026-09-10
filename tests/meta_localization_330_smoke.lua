-- Regression: Meta alignment must not compare localized Hero Talent labels.
_G = _G or _ENV
DKMentorDB = nil
function GetLocale() return "ptBR" end

local DKM = {}
assert(loadfile("Localization.lua"))("DKMentor", DKM)
assert(loadfile("Builds.lua"))("DKMentor", DKM)
assert(loadfile("MetaData.lua"))("DKMentor", DKM)

-- Reproduce the real ptBR runtime state from the screenshot: static build data
-- is localized, while MetaData remains canonical English observational data.
DKM.SetLocaleOverride("ptBR")
DKM.RefreshStaticLocalization()

local frostGuide = assert(DKM.Builds[251].mythicplus[1], "Frost M+ guide missing")
local frostMeta = assert(DKM.MetaData.contexts.highkeys.specs[251], "Frost High Keys meta missing")
assert(frostGuide.heroTalent == "Mortífero", "Expected localized Frost Hero Talent label")
assert(frostMeta.hero == "Deathbringer", "Meta snapshot must remain canonical")
assert(frostGuide.heroSpellID == frostMeta.heroSpellID, "Frost must align by stable Hero Talent spell ID")

local bloodGuide = assert(DKM.Builds[250].mythicplus[1], "Blood M+ guide missing")
local bloodMeta = assert(DKM.MetaData.contexts.highkeys.specs[250], "Blood High Keys meta missing")
assert(bloodGuide.heroSpellID ~= bloodMeta.heroSpellID, "Blood High Keys should remain a genuine meta difference")

local unholyGuide = assert(DKM.Builds[252].mythicplus[1], "Unholy M+ guide missing")
local unholyMeta = assert(DKM.MetaData.contexts.highkeys.specs[252], "Unholy High Keys meta missing")
assert(unholyGuide.heroSpellID ~= unholyMeta.heroSpellID, "Unholy High Keys should remain a genuine meta difference")

print("DK Mentor 3.3 localized Meta alignment smoke test passed")
