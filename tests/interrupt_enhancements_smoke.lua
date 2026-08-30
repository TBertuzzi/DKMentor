-- Static smoke test for DK Mentor 3.0.9 interrupt presentation enhancements.
local coreFile = assert(io.open("Core.lua", "r"))
local core = coreFile:read("*a")
coreFile:close()
local studioFile = assert(io.open("MentorStudio.lua", "r"))
local studio = studioFile:read("*a")
studioFile:close()
local engineFile = assert(io.open("MentorEngine.lua", "r"))
local engine = engineFile:read("*a")
engineFile:close()

local coreRequired = {
    'actionGlow = true',
    'function addon:RefreshInterruptActionGlowTargets()',
    'C_ActionBar.FindSpellActionButtons',
    '_G.ActionBarButtonEventsFrame',
    'GetMacroSpell',
    'actionType == "macro"',
    'function addon:_CreateInterruptGlowFrame(button)',
    'function addon:_SetInterruptActionGlowFromNotInterruptible(glow, notInterruptible)',
    'pcall(glow.SetAlphaFromBoolean, glow, notInterruptible, 0, 1)',
    'function addon:UpdateInterruptActionGlows(hasCast, rawNotInterruptible, cooldownInfo, usable)',
    'local stillMindFreeze = self:_ActionSlotContainsMindFreeze(entry.slot, nil)',
    'self:UpdateInterruptActionGlows(hasCast, rawNotInterruptible, cooldownInfo, usable)',
    'function addon:SetInterruptActionGlowEnabled(enabled)',
    'function addon:SetInterruptSoundEnabled(enabled)',
    'Interrupt options...',
    'interruptAction == "glow"',
    'interruptAction == "sound"',
    'interruptAction == "options"',
}
for _, snippet in ipairs(coreRequired) do
    assert(core:find(snippet, 1, true), "Core interrupt enhancement missing: " .. snippet)
end

local studioRequired = {
    'if cfg.kinds[kind].sound==nil then cfg.kinds[kind].sound=false end',
    'SOUNDKIT.RAID_WARNING',
    'f.interruptGlow=Button',
    'Action glow: ON',
    'Action glow: OFF',
    'function Studio.OpenInterrupt(parentFrame)',
    'selectedKind = "interrupt"',
    'addon:UpdateInterruptActionGlows(true, false, nil, true)',
}
for _, snippet in ipairs(studioRequired) do
    assert(studio:find(snippet, 1, true), "Studio interrupt enhancement missing: " .. snippet)
end

assert(engine:find('local isNewWindow = state.targetCast.interruptKey ~= castKey', 1, true), 'one-window interrupt notification guard missing')
assert(engine:find('if isNewWindow then', 1, true), 'interrupt new-window guard missing')
assert(engine:find('addon:NotifyMentorKind("interrupt")', 1, true), 'interrupt sound/pulse notification bridge missing')

assert(not core:find('ActionButton_ShowOverlayGlow', 1, true), 'DK Mentor must not take ownership of Blizzard native proc overlay glows')
assert(not core:find('ActionButton_HideOverlayGlow', 1, true), 'DK Mentor must not hide Blizzard native proc overlay glows')
assert(not core:find('PlaySoundFile(', 1, true), 'Core interrupt enhancement must not bundle/play external sound files')

print("DK Mentor 3.0.9 interrupt enhancements smoke test passed")
