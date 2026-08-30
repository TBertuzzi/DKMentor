-- Static smoke test for DK Mentor 3.0.9 Alert Studio + modal navigation UX.
local file = assert(io.open("MentorStudio.lua", "r"))
local text = file:read("*a")
file:close()

local required = {
    'DKMentorStudioFrame',
    'DKMentorSetupWizard',
    'function addon:ApplyMentorCardStyle',
    'function Studio.PreviewKind',
    'local SETUP_VERSION = 301',
    'mentor.setupVersion=SETUP_VERSION',
    'f:SetSize(690,470)',
    'local OPTION_BUTTON_HEIGHT = 44',
    'fontString:SetWidth(math.max(40, width - 16))',
    'LayoutOptions(f,4,2)',
    'if self.autoAdvance then',
    'f.current:SetText(T("Current selection: %s"',
    'f.next:Hide()',
    'RunPreviewOutsideWizard(function()',
    'f:Hide()',
    'local PREVIEW_SECONDS = 4',
    'ShowPreviewNotice(seconds)',
    'C_Timer.After(seconds + 0.25',
    'local studioReturnFrame',
    'local setupReturnFrame',
    'local studioTransitionInProgress = false',
    'local setupTransitionInProgress = false',
    'function Studio.Open(parentFrame)',
    'function Studio.OpenSetup(parentFrame)',
    'Studio.Open(f)',
    'ShowModalParent(parent)',
    'local function PreviewSelectedFromStudio()',
    'studioPreviewInProgress = true',
    'C_Timer.After(PREVIEW_SECONDS + 0.25',
    'IsHUDLocked() and "Unlock HUDs" or "Lock HUDs"',
    'Resource HUD visibility',
    'Review and DK Tools',
    'local COACH_LAYOUT_ORDER = { "compact", "medium", "large" }',
    'compact = { frameHeight = 96, minWidth = 280, cardWidth = 102, cardHeight = 64',
    'cfg.layout=NormalizeCoachLayout(cfg.layout)',
    'function addon:ApplyMentorCoachLayout()',
    'local frameWidth = math.max(layout.minWidth, totalCardsWidth + 14)',
    'f.layout=Button(f,"Coach layout",160,function() CycleCoachLayout() end)',
    'f.layout:SetText(T("Coach layout: %s", CoachLayoutLabel(cfg.layout)))',
    'f.nextAction=Button(f,"Next action",155',
    'f.nextAction:SetText(T(mentor.pinNextAction ~= false and "Next action: ON" or "Next action: OFF"))',
    'f.interruptGlow=Button(f,"Action glow",145',
    'f.interruptGlow:SetText(T(interrupt.actionGlow ~= false and "Action glow: ON" or "Action glow: OFF"))',
    'function Studio.OpenInterrupt(parentFrame)',
}
for _, snippet in ipairs(required) do
    assert(text:find(snippet, 1, true), "Studio guard missing: " .. snippet)
end

assert(not text:find('card:SetBackdrop(', 1, true), "Layout module must not reapply card backdrops and reset them to white")
assert(not text:find('Keep current settings', 1, true), "Ambiguous old wizard footer action must stay removed")
assert(not text:find("CastSpell", 1, true), "Studio must never cast abilities")
assert(not text:find("TargetUnit", 1, true), "Studio must never target units")
print("DK Mentor 3.0.9 Studio smoke test passed")
