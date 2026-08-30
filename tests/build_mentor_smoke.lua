local DKM = {
    T = function(value, ...)
        if select("#", ...) > 0 then return string.format(value, ...) end
        return value
    end,
}

assert(loadfile("Builds.lua"))("DKMentor", DKM)
assert(type(DKM.Builds) == "table", "Builds table missing")

local contexts = { "world", "delve", "dungeon", "mythicplus", "raid", "pvp" }
for _, specID in ipairs({ 250, 251, 252 }) do
    local spec = assert(DKM.Builds[specID], "Missing build data for spec " .. tostring(specID))
    for _, context in ipairs(contexts) do
        local profiles = assert(spec[context], "Missing " .. context .. " build context for spec " .. tostring(specID))
        assert(#profiles >= 1, "Empty " .. context .. " build context for spec " .. tostring(specID))
        for _, profile in ipairs(profiles) do
            assert(type(profile.name) == "string" and profile.name ~= "", "Build profile name missing")
            assert(type(profile.note) == "string" and profile.note ~= "", "Build profile note missing")
            assert(type(profile.focus) == "string" and profile.focus ~= "", "Build profile focus missing")
            assert(type(profile.keyTalents) == "table" and #profile.keyTalents >= 4, "Key talents missing")
            assert(type(profile.sourceURL) == "string" and profile.sourceURL ~= "", "Build source URL missing")
            assert(profile.code == "", "DK Mentor must not bundle or apply talent import codes")
        end
    end
end

assert(DKM.Builds[251].delve[1].heroTalent == "Deathbringer", "Frost Delve default should be Deathbringer")
assert(#DKM.Builds[250].mythicplus >= 2, "Blood Mythic+ should expose primary and alternative profiles")
assert(#DKM.Builds[252].mythicplus >= 2, "Unholy Mythic+ should expose Rider and San'layn profiles")

local coreFile = assert(io.open("Core.lua", "r"))
local core = coreFile:read("*a")
coreFile:close()
assert(core:find('codexBuildContext = "auto"', 1, true), "Build Mentor auto context default missing")
assert(core:find('function addon:SetCodexBuildContext(contextKey)', 1, true), "Build Mentor context setter missing")
assert(core:find('function addon:RenderBuildMentorVisual(specID, contextKey, autoDetected)', 1, true), "Visual Build Mentor renderer missing")
assert(core:find('function addon:AcquireBuildTalentCard(root)', 1, true), "Build talent icon pool missing")
assert(core:find('GameTooltip.SetSpellByID', 1, true), "Native spell tooltip support missing")

print("DK Mentor 3.0.17 Build Mentor smoke test passed")
