local DKM = {
    T = function(value, ...)
        if select("#", ...) > 0 then return string.format(value, ...) end
        return value
    end,
}

assert(loadfile("ValeeraData.lua"))("DKMentor", DKM)
local data = assert(DKM.ValeeraData, "ValeeraData missing")
assert(data.patch == "12.1.0", "Unexpected Valeera patch")
assert(data.reviewed == "2026-09-06", "Valeera review date missing")
assert(#data.presetOrder == 6, "Expected six Valeera presets including Leveling")
assert(#data.roleOrder == 3, "Expected three Valeera roles")
assert(#data.combatOrder == 3, "Expected three Combat Curios")
assert(#data.utilityOrder == 3, "Expected three Utility Curios")
assert(#data.poisonOrder == 6, "Expected six Valeera poisons")
for _, specID in ipairs({250, 251, 252}) do
    local spec = assert(data.recommendations[specID], "Missing Valeera recommendations for " .. tostring(specID))
    for _, preset in ipairs(data.presetOrder) do
        local row = assert(spec[preset], "Missing Valeera preset " .. preset .. " for " .. tostring(specID))
        assert(data.roles[row.role], "Unknown role " .. tostring(row.role))
        assert(data.combatCurios[row.combat], "Unknown combat Curio " .. tostring(row.combat))
        assert(data.utilityCurios[row.utility], "Unknown utility Curio " .. tostring(row.utility))
        assert(data.poisons[row.poison], "Unknown poison " .. tostring(row.poison))
    end
end
assert(data.recommendations[250].auto.role == "dps", "Blood Auto should pair with DPS Valeera")
assert(data.recommendations[251].auto.role == "healer", "Frost Auto should pair with Healer Valeera")
assert(data.recommendations[252].auto.role == "healer", "Unholy Auto should pair with Healer Valeera")
assert(data.recommendations[251].auto.poison == "frostheart", "Frost Auto should use Frostheart")
assert(data.recommendations[252].auto.poison == "bloodcrypt", "Unholy Auto should use Bloodcrypt")
assert(type(data.liveHotfixes) == "table" and #data.liveHotfixes >= 3, "Valeera live hotfix notes missing")
assert(data.recommendations[250].leveling.utility == "dundun", "Blood Leveling should use Dundun's Favor")
assert(data.recommendations[251].leveling.utility == "dundun", "Frost Leveling should use Dundun's Favor")
assert(data.recommendations[252].leveling.utility == "dundun", "Unholy Leveling should use Dundun's Favor")
assert(data.recommendations[250].leveling.poison == "soulthirst", "Blood Leveling should use Soulthirst")
assert(data.recommendations[251].leveling.poison == "soulthirst", "Frost Leveling should use Soulthirst")
assert(data.recommendations[252].leveling.poison == "soulthirst", "Unholy Leveling should use Soulthirst")
print("Valeera 3.2 data smoke test passed")
