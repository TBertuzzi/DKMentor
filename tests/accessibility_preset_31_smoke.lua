-- Static/data smoke test for DK Mentor 3.1 SBA-friendly guidance, presets and portrait.
local DKM = {
    T = function(value, ...)
        if select("#", ...) > 0 then return string.format(value, ...) end
        return value
    end,
}
assert(loadfile("Builds.lua"))("DKMentor", DKM)

assert(DKM.Builds[251].pvp[1].heroTalent == "Rider of the Apocalypse", "Frost PvP Rider baseline missing")
assert(DKM.Builds[251].pvp[1].sbaFriendly == true, "Frost PvP Rider should be SBA-friendly")
assert(DKM.Builds[251].pvp[2].sbaFriendly == false, "Frost PvP Deathbringer should remain the manual burst alternative")
assert(type(DKM.Builds[251].raid[1].sbaKeyTalents) == "table", "Frost SBA key-talents missing")
assert(DKM.Builds[252].world[1].sbaFriendly == true, "Unholy Rider should be SBA-friendly")

local coreFile = assert(io.open("Core.lua", "r"))
local core = coreFile:read("*a")
coreFile:close()

for _, needle in ipairs({
    'codexBuildMode = "standard"',
    'function addon:GetCodexBuildMode()',
    'function addon:SetCodexBuildMode(mode)',
    'T("SBA-friendly")',
    'profile.sbaFriendly == true',
    'local sourceOrder = {}',
    'function addon:ExportLayoutPreset()',
    'function addon:ImportLayoutPreset(text)',
    'not text:match("^DKM31;")',
    '#text > 12000',
    'DB.hudLocked = true',
    'function addon:CreateUI()',
    'addon.lichKingPortraitFrame = addon.CreateLichKingPortraitFrame()',
    'addon.LICH_KING_CREATURE_ID = 36597',
    'addon.LICH_KING_FALLBACK_ICON = "Interface\\\\Icons\\\\Achievement_Boss_LichKing"',
    'function addon:SetLichKingPortraitTalking(talking)',
    'model.SetAnimation, model, animationID',
    'local animationID = talking and 60 or 0',
    'function addon:ShowLichKingPortrait(preview)',
    'self:ShowLichKingPortrait()',
}) do
    assert(core:find(needle, 1, true), "3.1 accessibility/preset/portrait feature missing: " .. needle)
end

assert(not core:find("loadstring", 1, true), "Preset import must never evaluate Lua source")
assert(not core:find("RunScript", 1, true), "Preset import must never execute script text")

print("DK Mentor 3.1 accessibility/preset smoke test passed")

local chunkLocals = 0
for line in core:gmatch("[^\n]+") do
    if line:match("^local function ") then
        chunkLocals = chunkLocals + 1
    elseif line:match("^local ") then
        local declaration = line:match("^local%s+([^=]+)") or ""
        for name in declaration:gmatch("[A-Za-z_][A-Za-z0-9_]*") do chunkLocals = chunkLocals + 1 end
    end
end
assert(chunkLocals <= 190, "Core.lua local-variable safety budget exceeded: " .. tostring(chunkLocals))
