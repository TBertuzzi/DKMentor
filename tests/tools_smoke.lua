-- Static smoke test for DK Mentor 3.0.9 DK Tools Midnight-safe boundaries.
local file = assert(io.open("DKTools.lua", "r"))
local text = file:read("*a")
file:close()
local required = {
    'DKMentorGroundTracker',
    'DKMentorMeleeWarning',
    'local DND_DURATION = 10',
    'C_Spell.GetSpellCharges',
    'C_Spell.IsSpellInRange',
    'IsSecretValue(raw)',
    'local MELEE_WARNING_DELAY = 0.30',
    'f:SetSize(136, 22)',
    'f.text:SetText(T("OUT OF RANGE"))',
    'f:SetShown((now - meleeOutSince) >= MELEE_WARNING_DELAY)',
    'C_Timer.After(4',
    'SPELL_UPDATE_CHARGES',
    'addon.hudEditSessionActive == true',
}
for _, snippet in ipairs(required) do
    assert(text:find(snippet, 1, true), "DK Tools guard missing: " .. snippet)
end
assert(not text:find("SetCooldown", 1, true), "DnD tracker must not use a cooldown swipe")
assert(not text:find("COMBAT_LOG_EVENT_UNFILTERED", 1, true), "DK Tools must not use CLEU")
print("DK Mentor 3.0.9 DK Tools smoke test passed")
