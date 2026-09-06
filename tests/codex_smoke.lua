local DKM = {
    T = function(value, ...)
        if select("#", ...) > 0 then
            return string.format(value, ...)
        end
        return value
    end,
}

assert(loadfile("Codex.lua"))("DKMentor", DKM)
assert(type(DKM.Codex) == "table", "Codex table missing")
assert(DKM.Codex.patch == "12.1.0", "Unexpected Codex patch")
assert(#DKM.Codex.sectionOrder == 9, "Expected nine Codex sections")
assert(DKM.Codex.sectionOrder[2] == "advisor", "Stats & Folio must be a first-class Codex section")
assert(DKM.Codex.sectionOrder[3] == "stats", "Gear Mentor must remain a first-class Codex section")
assert(DKM.Codex.sectionOrder[4] == "builds", "Build recommendations must remain a first-class Codex section")
assert(DKM.Codex.sectionOrder[5] == "valeera", "Valeera Delve Mentor must be a first-class Codex section")
assert(DKM.Codex.sectionLabels.advisor == "Stats & Folio", "Stats & Folio section label missing")
assert(DKM.Codex.sectionLabels.builds == "Builds", "Builds section label missing")
assert(DKM.Codex.sectionLabels.stats == "Gear Mentor", "Gear Mentor section label missing")
assert(DKM.Codex.sectionLabels.valeera == "Valeera", "Valeera section label missing")
local unholyText = ""
for _, row in ipairs(DKM.Codex.specs[252].rotation or {}) do unholyText = unholyText .. " " .. tostring(row.body or "") end
assert(unholyText:find("Lesser Ghoul", 1, true), "Unholy Codex must describe current Lesser Ghoul gameplay")
local frostText = ""
for _, row in ipairs(DKM.Codex.specs[251].rotation or {}) do frostText = frostText .. " " .. tostring(row.body or "") end
assert(frostText:find("continuous Runic Power drain", 1, true), "Frost Codex must document Midnight Breath resource model")

for _, specID in ipairs({ 250, 251, 252 }) do
    local spec = assert(DKM.Codex.specs[specID], "Missing Codex spec " .. tostring(specID))
    assert(#spec.overview >= 3, "Overview incomplete for " .. tostring(specID))
    assert(#spec.stats >= 5, "Stats/Gear incomplete for " .. tostring(specID))
    assert(#spec.rotation >= 4, "Rotation incomplete for " .. tostring(specID))
    assert(#spec.survival >= 2, "Survival incomplete for " .. tostring(specID))
    assert(#spec.utility >= 1, "Utility incomplete for " .. tostring(specID))
    assert(DKM.Codex.checkNotes[specID], "Character Check note missing for " .. tostring(specID))
end

print("DK Codex 3.2 smoke test passed")
