-- Regression: Codex sidebar must use distinct native WoW icons instead of
-- repeating the current/spec class icon across multiple sections.
local f = assert(io.open("Core.lua", "r"))
local core = f:read("*a")
f:close()

local expected = {
    overview = "133743", -- book
    stats = "132736",    -- equipment chest
    builds = "132222",   -- planning / build target
    meta = "132767",     -- crown / ranking
    rotation = "132306", -- action sequence
}

assert(core:find("advisor = { spellID = 1279609 }", 1, true), "Stats & Folio must keep the native Omnium Folio icon")

for key, texture in pairs(expected) do
    local pattern = key .. "%s*=%s*{%s*texture%s*=%s*" .. texture
    assert(core:match(pattern), "Missing distinct native icon for Codex section: " .. key)
end

assert(core:find('check = { texture = "Interface\\\\RaidFrame\\\\ReadyCheck%-Ready"', 1, false),
    "Character Check must use Blizzard Ready Check icon")
assert(not core:find('builds = { dynamic = "spec" }', 1, true),
    "Builds must not reuse the current specialization icon")
assert(not core:find('meta = { texture = "Interface\\\\Icons\\\\spell_deathknight_classicon" }', 1, true),
    "Meta must not reuse the Death Knight class icon")
assert(not core:find('overview = { texture = "Interface\\\\Icons\\\\spell_deathknight_classicon" }', 1, true),
    "Overview must not reuse the Death Knight class icon")

print("DK Mentor 3.3 Codex native icon smoke test passed")
