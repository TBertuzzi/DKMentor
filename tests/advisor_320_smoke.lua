-- Static/data smoke test for DK Mentor 3.2 Stats & Folio / Gear Targets 2.0.
local DKM = {
    T = function(value, ...)
        if select("#", ...) > 0 then return string.format(value, ...) end
        return value
    end,
}

assert(loadfile("AdvisorData.lua"))("DKMentor", DKM)
local data = assert(DKM.AdvisorData, "AdvisorData table missing")
assert(data.patch == "12.1.0", "AdvisorData patch mismatch")
assert(data.reviewed == "2026-09-06", "AdvisorData review date mismatch")
assert(data.folioTreeID == 1186, "Omnium Folio tree ID mismatch")

for _, stat in ipairs({"crit", "haste", "mastery", "versatility"}) do
    local dr = assert(data.diminishingReturns[stat], "Missing DR data for " .. stat)
    assert(#dr == 3 and dr[1] < dr[2] and dr[2] < dr[3], "Invalid DR thresholds for " .. stat)
end

for _, specID in ipairs({250, 251, 252}) do
    local spec = assert(data.specs[specID], "Missing Advisor data for spec " .. tostring(specID))
    for _, bucket in ipairs({"pve", "pvp"}) do
        assert(spec.stats[bucket] and spec.stats[bucket].default, "Missing stats bucket " .. bucket)
        local folio = assert(spec.folio[bucket], "Missing Folio bucket " .. bucket)
        assert(type(folio.rows) == "table" and #folio.rows == 5, "Folio must expose five rows")
    end
end

assert(data.specs[250].stats.pve.hero["Deathbringer"], "Blood Deathbringer stat direction missing")
assert(data.specs[250].stats.pve.hero["San'layn"], "Blood San'layn stat direction missing")
assert(data.specs[251].stats.pve.freshness == "current", "Frost post-hotfix stat review should be current")
assert(data.specs[252].stats.pve.freshness == "current", "Unholy post-hotfix stat review should be current")

local advisorFile = assert(io.open("Advisor.lua", "r"))
local advisor = advisorFile:read("*a")
advisorFile:close()
for _, needle in ipairs({
    'function addon:RenderDKAdvisorVisual(specID)',
    'function addon:GetDKAdvisorContextMode()',
    'function addon:SetDKAdvisorContextMode(mode)',
    'function addon:GetOmniumFolioSelectedSpellSet()',
    'function addon:GetOmniumFolioRuntimeRows(folio)',
    'function addon:ApplyDKAdvisorFolioDraft(root)',
    'traits.SetSelection',
    'traits.CommitConfig',
    'Folio quick editor',
    'AdvisorData.folioTreeID',
    'C_Traits',
    'TooltipDataProcessor.AddTooltipPostCall',
    'Collection status: %s',
    'iconSpellID = 47568',
    'button.icon:SetTexture(GetSpellTextureSafe(choice.iconSpellID))',
    'function addon:HideDKAdvisorVisualPools(root)',
}) do
    assert(advisor:find(needle, 1, true), "3.2 Advisor feature missing: " .. needle)
end

local gearFile = assert(io.open("GearData.lua", "r"))
local gear = gearFile:read("*a")
gearFile:close()
for _, needle in ipairs({
    'Nek\'zali the Soulcoiler',
    'Nymrissa Wavecaller',
    'Voidscar Arena',
    'Murder Row',
    'catalyst = {',
    "Target(268209, \"Aman'muso, Warlord's Vengeance\", \"Main Hand\"",
    "Target(268202, \"Jaw of the Shackled Goddess\", \"Off Hand\"",
}) do
    assert(gear:find(needle, 1, true), "3.2 Catalyst data missing: " .. needle)
end

local prepFile = assert(io.open("PreparationData.lua", "r"))
local prep = prepFile:read("*a")
prepFile:close()
for _, needle in ipairs({
    'itemID=241288, fallbackName="Potion of Recklessness"',
    'mode="dual"',
}) do
    assert(prep:find(needle, 1, true), "3.2 Frost Runeforge guidance missing: " .. needle)
end

local coreFile = assert(io.open("Core.lua", "r"))
local core = coreFile:read("*a")
coreFile:close()
for _, needle in ipairs({
    'codexAdvisorContext = "auto"',
    'advisor = "Stats & Folio"',
    'self:RenderDKAdvisorVisual(specID)',
    'self:RegisterGearTargetTooltipIntegration()',
    'AddSectionLabel("Catalyst plan")',
    'command == "advisor" or command == "statsfolio" or command == "folio"',
    'local codexSectionMenuIcons = {',
    'advisor = { spellID = 1279609 }',
    'survival = { spellID = 48792 }',
    'utility = { spellID = 49576 }',
    'SetFlatTabButtonIcon(button, iconTexture, 17)',
    'button.iconSpellID = choice.iconSpellID',
    'button.iconItemID = 270175',
    'if self.HideDKAdvisorVisualPools then self:HideDKAdvisorVisualPools(root) end',
    'frame:SetSize(1060, 780)',
    'guide.contentWidth = 780',
    'function addon:SetGearTextBlockHeight(fontString, width, textValue, minHeight)',
}) do
    assert(core:find(needle, 1, true), "3.2 Core integration missing: " .. needle)
end

print("DK Mentor 3.2 Stats/Folio/Gear Targets smoke test passed")
