-- Static/data smoke test for DK Mentor 3.1 Preparation / Ready Check.
local DKM = {}
assert(loadfile("PreparationData.lua"))("DKMentor", DKM)

local data = assert(DKM.PreparationData, "PreparationData table missing")
assert(data.patch == "12.1.0", "PreparationData patch mismatch")
assert(data.reviewed == "2026-09-11", "PreparationData review date mismatch")
assert(type(data.commonEnchants) == "table" and #data.commonEnchants >= 5, "Common enchant guidance missing")

local function hasItem(entries, itemID)
    for _, entry in ipairs(entries or {}) do
        if entry.itemID == itemID then return true end
    end
    return false
end

for _, specID in ipairs({250, 251, 252}) do
    local spec = assert(data.specs[specID], "Missing preparation data for spec " .. tostring(specID))
    assert(type(spec.runeforge) == "table" and #spec.runeforge >= 1, "Runeforge guidance missing")
    assert(type(spec.gems) == "table" and #spec.gems >= 2, "Gem guidance missing")
    assert(type(spec.consumables) == "table", "Consumable guidance missing")
    for _, key in ipairs({"flask", "combatPotion", "healthPotion", "weaponBuff", "augmentRune", "food"}) do
        assert(type(spec.consumables[key]) == "table" and #spec.consumables[key] >= 1, "Missing consumable category " .. key)
    end
end

-- Current Season 2 headline recommendations reviewed for 3.1.
assert(hasItem(data.specs[250].gems, 240908), "Blood Masterful Garnet baseline missing")
assert(hasItem(data.specs[250].gems, 240890), "Blood Deadly Peridot San'layn alternative missing")
assert(data.specs[251].runeforge[1].enchantID == 3368, "Frost Fallen Crusader direction missing")
assert(hasItem(data.specs[251].consumables.flask, 241326), "Frost Shattered Sun flask missing")

local frost = data.specs[251]
assert(frost.consumables.combatPotion[1].itemID == 241288 and frost.consumables.combatPotion[1].priority == "RECOMMENDED", "Frost Potion of Recklessness recommendation missing")
assert(frost.consumables.combatPotion[2].itemID == 241308 and frost.consumables.combatPotion[2].priority == "ALTERNATIVE", "Frost Light's Potential alternative missing")
for _, entry in ipairs(frost.runeforge) do
    assert(entry.slot ~= "Two-Hand (Breathbane)", "Obsolete two-hand Breathbane Runeforge alternative must not return")
end
assert(hasItem(data.specs[252].consumables.flask, 241322), "Unholy Magisters flask missing")
assert(hasItem(data.specs[252].consumables.healthPotion, 241304), "Unholy Silvermoon Health Potion missing")
assert(hasItem(data.specs[252].consumables.food, 255845), "Unholy Silvermoon Parade feast missing")
assert(hasItem(data.specs[252].gems, 240967), "Unholy Powerful Eversong Diamond alternative missing")
assert(hasItem(data.specs[252].consumables.flask, 241324), "Unholy Blood Knights situational flask missing")
assert(hasItem(data.specs[252].consumables.weaponBuff, 237371), "Unholy Refulgent Whetstone alternative missing")
assert(hasItem(data.specs[252].consumables.weaponBuff, 237369), "Unholy Refulgent Weightstone alternative missing")

local coreFile = assert(io.open("Core.lua", "r"))
local core = coreFile:read("*a")
coreFile:close()
for _, needle in ipairs({
    'function addon:GetPreparationReadyStatus(specID)',
    'function addon:GetRecommendedRuneforgeStatus(specID)',
    'function addon:RenderGearMentorVisual(specID, viewKey)',
    'elseif viewKey == "preparation" then',
    '{ key = "preparation", label = T("Preparation") },',
    'T("Read-only checklist: DK Mentor never applies enchants, gems, runes, or consumables automatically.")',
    'function addon:GetPermanentEnchantState(slotID)',
    'C_TooltipInfo.GetInventoryItem',
    'slot="Main hand"',
    'slot="Off hand"',
}) do
    assert(core:find(needle, 1, true), "3.1 Preparation Core feature missing: " .. needle)
end

-- Preparation remains advisory and must not automate inventory changes.
for _, forbidden in ipairs({
    'UseContainerItem',
    'PickupInventoryItem',
    'C_Item.SocketItemToSlot',
}) do
    assert(not core:find(forbidden, 1, true), "Preparation must not automate character changes: " .. forbidden)
end

print("DK Mentor 3.1 Preparation smoke test passed")
