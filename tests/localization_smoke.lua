-- Regression smoke test for the manual DK Mentor language override.
-- Simulates the common case: ptBR WoW client, static addon tables materialize
-- before SavedVariables are available, then the user-selected addon language
-- is applied at ADDON_LOADED.
_G = _G or _ENV
DKMentorDB = nil
function GetLocale() return "ptBR" end

local DKM = {}
assert(loadfile("Localization.lua"))("DKMentor", DKM)
assert(loadfile("Data.lua"))("DKMentor", DKM)
assert(loadfile("Builds.lua"))("DKMentor", DKM)
assert(loadfile("Guides.lua"))("DKMentor", DKM)
assert(loadfile("GearData.lua"))("DKMentor", DKM)
assert(loadfile("Codex.lua"))("DKMentor", DKM)
assert(loadfile("Voices.lua"))("DKMentor", DKM)

-- Critical context/spec/tip keys are now kept canonical until the user
-- override is known, while older static modules can still reflect ptBR.
assert(DKM.Data.contextNames.world == "World", "Context keys must remain canonical before override")
assert(DKM.Data.tips.general.world[1].tag == "HEAL", "Tip keys must remain canonical before override")
assert(DKM.Guides.general.title == "Fundamentos do Cavaleiro da Morte", "Expected provisional ptBR guide text")

-- Apply English override exactly where Core does it after SavedVariables load.
DKM.SetLocaleOverride("enUS")
DKM.RefreshStaticLocalization()
assert(DKM.T("Mundo") == "World", "Reverse ptBR -> English lookup failed")
assert(DKM.T("Gélido") == "Frost", "Reverse specialization lookup failed")
assert(DKM.Data.contextNames.world == "World", "World context did not relocalize to English")
assert(DKM.Data.contextNames.delve == "Delve", "Delve context did not relocalize to English")
assert(DKM.Data.contextNames.dungeon == "Dungeon", "Dungeon context did not relocalize to English")
assert(DKM.Data.contextNames.mythicplus == "Mythic+", "Mythic+ context did not relocalize to English")
assert(DKM.Data.contextNames.raid == "Raid", "Raid context did not relocalize to English")
assert(DKM.Data.contextNames.pvp == "PvP", "PvP context did not relocalize to English")
assert(DKM.Data.tips.general.world[1].tag == "HEAL", "Survival tag did not relocalize to English")
assert(DKM.Data.tips.general.world[1].text:match("meaningful damage"), "Survival text did not relocalize to English")
assert(DKM.Guides.general.title == "Death Knight fundamentals", "Guide static text did not relocalize to English")
assert(DKM.Codex.sectionLabels.survival == "Survival", "Codex static label did not relocalize to English")
assert(DKM.T("Gear Mentor") == "Gear Mentor", "Gear Mentor English label failed")
assert(DKM.T("Dashboard") == "Dashboard", "Gear Mentor dashboard English label failed")

-- The same tables must be reversible back to ptBR without rebuilding them.
DKM.SetLocaleOverride("ptBR")
DKM.RefreshStaticLocalization()
assert(DKM.Data.contextNames.world == "Mundo", "World context did not relocalize back to ptBR")
assert(DKM.Data.tips.general.world[1].tag == "CURA", "Survival tag did not relocalize back to ptBR")
assert(DKM.Guides.general.title == "Fundamentos do Cavaleiro da Morte", "Guide static text did not relocalize back to ptBR")
assert(DKM.Codex.sectionLabels.survival == "Sobrevivência", "Codex static label did not relocalize back to ptBR")
assert(DKM.T("Gear Mentor") == "Mentor de equipamento", "Gear Mentor ptBR label failed")
assert(DKM.T("Dashboard") == "Painel", "Gear Mentor dashboard ptBR label failed")

print("DK Mentor localization override smoke test passed")
