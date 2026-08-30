-- DK Mentor 3.0.9 modal-navigation regression smoke test.
local function read(name)
    local f = assert(io.open(name, "r"))
    local text = f:read("*a")
    f:close()
    return text
end

local engine = read("MentorEngine.lua")
local review = read("MentorReview.lua")
local studio = read("MentorStudio.lua")

for _, snippet in ipairs({
    'DKM.MentorReview.Open("overview", frame)',
    'DKM.MentorStudio.Open(frame)',
    'DKM.MentorStudio.OpenSetup(frame)',
}) do
    assert(engine:find(snippet, 1, true), "Mentor Intelligence child-modal guard missing: " .. snippet)
end

for _, snippet in ipairs({
    'local reviewReturnFrame',
    'function Review.Open(tab, parentFrame)',
    'if parent.IsShown and parent:IsShown() then parent:Hide() end',
    'RestoreReviewParent()',
    'frame:SetFrameLevel(300)',
    'frame:SetToplevel(true)',
}) do
    assert(review:find(snippet, 1, true), "Review modal guard missing: " .. snippet)
end

for _, snippet in ipairs({
    'local studioTransitionInProgress = false',
    'local setupTransitionInProgress = false',
    'local studioReturnFrame',
    'local setupReturnFrame',
    'function Studio.Open(parentFrame)',
    'function Studio.OpenSetup(parentFrame)',
    'studioTransitionInProgress = true',
    'ShowModalParent(parent)',
    'f:SetFrameLevel(280)',
    'f:SetToplevel(true)',
    'Studio.Open(f)',
    'f:SetScript("OnHide", function()',
}) do
    assert(studio:find(snippet, 1, true), "Studio/Setup modal guard missing: " .. snippet)
end

assert(not studio:find('returnToSetupAfterStudio', 1, true), "Old one-off setup return flag must stay removed")
print("DK Mentor 3.0.9 modal navigation smoke test passed")
