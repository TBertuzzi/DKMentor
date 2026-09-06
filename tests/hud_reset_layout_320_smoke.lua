-- DK Mentor 3.2 starter/reset HUD layout regression smoke test.
local file = assert(io.open("Core.lua", "r"))
local core = file:read("*a")
file:close()

local defaultsStart = assert(core:find("local DEFAULTS = {", 1, true), "DEFAULTS missing")
local defaultsEnd = assert(core:find("local function GetSpellData", defaultsStart, true), "DEFAULTS end missing")
local defaults = core:sub(defaultsStart, defaultsEnd - 1)

for _, snippet in ipairs({
    'point = "BOTTOM",\n        relativePoint = "BOTTOM",\n        x = 0,\n        y = 250,',
    'x = -220,\n        y = 395,',
    'x = 0,\n        y = 395,',
    'x = 220,\n        y = 395,',
    'x = 0,\n        y = 175,',
    'x = 0,\n        y = 95,',
}) do
    assert(defaults:find(snippet, 1, true), "starter HUD default missing: " .. snippet)
end

assert(core:find('ResetFramePosition("coach", DEFAULTS.coach)', 1, true), "Reset HUDs must restore coach starter position")
assert(core:find('ResetFramePosition("buffBar", DEFAULTS.buffBar)', 1, true), "Reset HUDs must restore DK buff starter position")
assert(core:find('ResetFramePosition("externalBuffBar", DEFAULTS.externalBuffBar)', 1, true), "Reset HUDs must restore external buff starter position")
assert(core:find('ResetFramePosition("debuffBar", DEFAULTS.debuffBar)', 1, true), "Reset HUDs must restore debuff starter position")
assert(core:find('ResetFramePosition("abilityBar", DEFAULTS.abilityBar)', 1, true), "Reset HUDs must restore ability starter position")
assert(core:find('Combat HUD positions restored to the starter layout.', 1, true), "starter-layout reset confirmation missing")

-- Layout intent: resource (95) -> abilities (175) -> coach (250) -> aura row (395).
-- Aura HUDs share one Y band but are spread horizontally at -220 / 0 / +220.
assert(95 + 66 < 175, "resource and ability starter bands overlap")
assert(175 + 54 < 250, "ability and coach starter bands overlap")
assert(250 + 128 < 395, "large coach and aura starter bands overlap")
assert((-220 + 102) < (0 - 102), "left and center aura bars overlap")
assert((0 + 102) < (220 - 102), "center and right aura bars overlap")

print("DK Mentor 3.2 starter/reset HUD layout smoke test passed")
