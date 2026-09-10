-- Static/data smoke test for DK Mentor 3.0.16 Gear Mentor.
local DKM = {}
assert(loadfile("GearData.lua"))("DKMentor", DKM)
assert(type(DKM.GearData) == "table", "GearData table missing")
assert(DKM.GearData.patch == "12.1.0", "GearData patch mismatch")
assert(DKM.GearData.reviewed == "2026-09-08", "GearData review date mismatch")

local tier = assert(DKM.GearData.tierSet, "Season 2 tier set data missing")
assert(tier.setID == 2055, "Death Knight Season 2 set ID mismatch")
assert(type(tier.pieces) == "table" and #tier.pieces == 5, "Death Knight Season 2 tier must expose five pieces")
local tierIDs = {}
for _, piece in ipairs(tier.pieces) do tierIDs[piece.itemID] = true end
for _, itemID in ipairs({271474, 271472, 271477, 271475, 271473}) do
    assert(tierIDs[itemID], "Missing Season 2 tier item " .. tostring(itemID))
end
assert(type(tier.bonuses[250]) == "table" and type(tier.bonuses[251]) == "table" and type(tier.bonuses[252]) == "table", "Tier bonus summaries missing")

for _, specID in ipairs({250, 251, 252}) do
    local spec = assert(DKM.GearData.specs[specID], "Missing Gear Mentor spec " .. tostring(specID))
    assert(type(spec.sourceURL) == "string" and spec.sourceURL:find("wowhead%.com"), "Missing current Wowhead guide source URL for spec " .. tostring(specID))
    assert(type(spec.targets) == "table" and #spec.targets >= 5, "Not enough tracked targets for spec " .. tostring(specID))
    assert(type(spec.trinkets) == "table" and #spec.trinkets >= 2, "Trinket plan incomplete for spec " .. tostring(specID))
    assert(type(spec.crafting) == "table" and #spec.crafting >= 2, "Crafting plan incomplete for spec " .. tostring(specID))
    assert(type(spec.craftTargets) == "table" and #spec.craftTargets >= 3, "Visual craft targets incomplete for spec " .. tostring(specID))
    assert(type(spec.upgrades) == "table" and #spec.upgrades >= 2, "Upgrade plan incomplete for spec " .. tostring(specID))
    assert(type(spec.catalyst) == "table" and #spec.catalyst == 5, "Catalyst plan incomplete for spec " .. tostring(specID))
end

local function hasTarget(specID, itemID)
    for _, target in ipairs(DKM.GearData.specs[specID].targets or {}) do
        if target.itemID == itemID then return true end
    end
    return false
end
assert(hasTarget(251, 268209), "Frost Aman'muso target missing")
assert(hasTarget(251, 268202), "Frost Jaw target missing")
assert(hasTarget(250, 268213), "Blood Maze-roa target missing")
assert(hasTarget(252, 268213), "Unholy Maze-roa target missing")
assert(hasTarget(252, 268249), "Unholy Vile Alchemist's Band target missing")
assert(hasTarget(252, 252258), "Unholy Sickening Signet of Atroxus target missing")
assert(hasTarget(250, 270175) and hasTarget(251, 270175) and hasTarget(252, 270175), "Voracious Heart should be tracked for all three specs")

local function hasCraftTarget(specID, itemID)
    for _, target in ipairs(DKM.GearData.specs[specID].craftTargets or {}) do
        if target.itemID == itemID then return true end
    end
    return false
end
assert(hasCraftTarget(250, 237834), "Blood Spellbreaker's Bracers craft missing")
assert(hasCraftTarget(250, 240949), "Blood Masterwork Sin'dorei Band craft missing")
assert(hasCraftTarget(251, 237839), "Frost Spellbreaker's Blade craft missing")
assert(hasCraftTarget(251, 251513), "Frost Loa Worshiper's Band craft missing")
assert(hasCraftTarget(252, 237846), "Unholy Blood Knight's Warblade craft missing")

local coreFile = assert(io.open("Core.lua", "r"))
local core = coreFile:read("*a")
coreFile:close()
local buildsFile = assert(io.open("Builds.lua", "r"))
local builds = buildsFile:read("*a")
buildsFile:close()

for _, needle in ipairs({
    'function addon:GetGearMentorReport(specID, viewKey)',
    'function addon:GetGearTargetState(target)',
    'function addon:SetCodexGearView(viewKey)',
    'guide.gearViewButtons',
    '{ key = "sources", label = T("Sources") },',
    'AddHeader("Loot sources")',
    'Gear Mentor dashboard',
    'AddHeader("Next target")',
    'if success and DB and DB.codexSection == "stats" and mainFrame and mainFrame:IsShown() then',
    'function addon:GetGearTargetIcon(target)',
    'C_Item.GetItemIconByID',
    'function addon:RenderGearMentorVisual(specID, viewKey)',
    'function addon:ConfigureGearItemCard(card, target, width, height)',
    'GameTooltip.SetHyperlink',
    '"item:" .. tostring(itemID)',
    '{ key = "targets", label = T("Gear") },',
    '{ key = "crafting", label = T("Crafting") },',
    '{ key = "upgrades", label = T("Upgrades") },',
    'T("Hover for item details")',
    'AddSectionLabel("Recommended crafts")',
    'local craftTargets = spec.craftTargets or {}',
    'target.craft and T("CRAFT") or T("TARGET")',
    'card.name:SetWordWrap(true)',
    'card.status:SetWordWrap(true)',
    'self.currentGearVisualHeight = self:RenderGearMentorVisual(specID, gearView)',
    'function addon:GetEquippedTierSetState()',
    'function addon:HideGearTooltip(owner)',
    'root:SetScript("OnUpdate"',
    'function addon:AcquireGearTierCard(root)',
    'function addon:AcquireGearBonusCard(root)',
    'AddSectionLabel("Season 2 tier set")',
    'AddSectionLabel("Catalyst plan")',
}) do
    assert(core:find(needle, 1, true), "Gear Mentor Core feature missing: " .. needle)
end
assert(builds:find('for key, value in pairs(meta) do profile[key] = value end', 1, true), "Build metadata merge missing")
assert(builds:find('heroTalent="Deathbringer"', 1, true), "Build hero-talent metadata missing")
assert(builds:find('focus="', 1, true), "Build focus metadata missing")

-- Gear Mentor must remain advisory: never equip, upgrade, socket, enchant or buy anything.
for _, forbidden in ipairs({
    'C_EquipmentSet.UseEquipmentSet',
    'EquipItemByName',
    'PickupInventoryItem',
    'UseContainerItem',
}) do
    assert(not core:find(forbidden, 1, true), "Gear Mentor must not automate gear: " .. forbidden)
end

print("DK Mentor 3.2 Gear Mentor smoke test passed")
