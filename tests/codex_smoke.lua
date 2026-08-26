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
assert(#DKM.Codex.sectionOrder == 7, "Expected seven Codex sections")
assert(DKM.Codex.sectionOrder[2] == "builds", "Build recommendations must be a first-class Codex section")
assert(DKM.Codex.sectionLabels.builds == "Builds", "Builds section label missing")

for _, specID in ipairs({ 250, 251, 252 }) do
    local spec = assert(DKM.Codex.specs[specID], "Missing Codex spec " .. tostring(specID))
    assert(#spec.overview >= 3, "Overview incomplete for " .. tostring(specID))
    assert(#spec.stats >= 5, "Stats/Gear incomplete for " .. tostring(specID))
    assert(#spec.rotation >= 4, "Rotation incomplete for " .. tostring(specID))
    assert(#spec.survival >= 2, "Survival incomplete for " .. tostring(specID))
    assert(#spec.utility >= 1, "Utility incomplete for " .. tostring(specID))
    assert(DKM.Codex.checkNotes[specID], "Character Check note missing for " .. tostring(specID))
end

print("DK Codex 2.0 smoke test passed")
