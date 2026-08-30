-- Regression smoke test for the Blizzard-like ordered visual Rune pool.
local file = assert(io.open("Core.lua", "r"))
local core = file:read("*a")
file:close()

for _, needle in ipairs({
    'local function BuildOrderedRuneDisplayStates(now)',
    'if a.ready ~= b.ready then return a.ready end',
    'if a.progress ~= b.progress then return a.progress > b.progress end',
    'local states = BuildOrderedRuneDisplayStates(GetNow())',
    'local state = states[displayIndex]',
}) do
    assert(core:find(needle, 1, true), "Ordered Rune display feature missing: " .. needle)
end
assert(core:find('available Runes stay on the left, spending', 1, true), "Rune visual-order intent must be documented")
assert(core:find('consumes from the right', 1, true), "Right-to-left spending visual intent missing")

-- Validate the intended ordering independently with fake states: ready Runes first,
-- then charging Runes from most-complete to least-complete.
local states = {
    { runeID=1, ready=true, progress=1.00 },
    { runeID=2, ready=false, progress=0.25 },
    { runeID=3, ready=false, progress=0.80 },
    { runeID=4, ready=true, progress=1.00 },
    { runeID=5, ready=true, progress=1.00 },
    { runeID=6, ready=false, progress=0.05 },
}
table.sort(states, function(a, b)
    if a.ready ~= b.ready then return a.ready end
    if a.progress ~= b.progress then return a.progress > b.progress end
    return a.runeID < b.runeID
end)
assert(states[1].ready and states[2].ready, "Ready Runes must stay left")
assert(states[4].progress == 0.80 and states[5].progress == 0.25 and states[6].progress == 0.05, "Charging Runes must recharge visually left-to-right")
assert(states[#states].progress == 0.05, "Most recently spent/emptiest Rune should be visually rightmost")

print("DK Mentor 3.0.11 ordered Rune display smoke test passed")
