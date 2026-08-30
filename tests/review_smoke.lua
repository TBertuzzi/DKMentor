-- DK Mentor 3.0.9 Review/Patterns persistence + modal-return smoke test.
_G = _G or _ENV
DKMentorDB = { mentor = { historyLimit = 10, reviewEnabled = true } }

local addon = {}
function addon:HandleSlashCommand() end
function addon:GetRuntimeSpecLabel(specID) return ({[250]="Blood",[251]="Frost",[252]="Unholy"})[specID] or "?" end
function addon:GetRuntimeContextLabel(key) return ({world="World",delve="Delve",dungeon="Dungeon",mythicplus="Mythic+",raid="Raid",pvp="PvP"})[key] or key end

local DKM = {
    Addon = addon,
    Data = { specNames = {[250]="Blood",[251]="Frost",[252]="Unholy"}, contextNames = {world="World"} },
    T = function(value, ...)
        if select("#", ...) > 0 then return string.format(value, ...) end
        return value
    end,
}

assert(loadfile("MentorReview.lua"))("DKMentor", DKM)
local Review = assert(DKM.MentorReview, "MentorReview was not exported")

for i = 1, 12 do
    assert(Review.Record({
        score = 70 + i,
        duration = 30,
        specID = 251,
        context = "world",
        components = { resources = 90, procs = 100, survival = 100, interrupts = 100 },
        observations = {
            { key = "runes_idle", text = "Runes idle", confidence = "HIGH", severity = 3, penalized = true },
        },
        strengths = { "Every detected interrupt window was stopped." },
        timeline = {
            { t = 1.2, kind = "resource", text = "Five or more Runes became ready", confidence = "HIGH", severity = 2 },
        },
    }), "Review.Record rejected a valid report")
end

local history = Review.GetHistory()
assert(#history == 10, "Review history must retain exactly the newest 10 encounters")
assert(history[1].score == 82, "Newest encounter must be first")
assert(history[10].score == 73, "Oldest retained encounter is wrong")

local patterns = Review.GetPatterns(history)
assert(patterns.encounters == 10, "Pattern encounter count mismatch")
assert(#patterns.items >= 1 and patterns.items[1].key == "runes_idle", "Recurring rune pattern missing")
assert(patterns.items[1].count == 10, "Recurring rune pattern count mismatch")

local overview = Review.BuildOverview(history[1])
assert(overview:find("What went well", 1, true), "Overview must include positive feedback")
assert(overview:find("Key observations", 1, true), "Overview must include observations")
local timeline = Review.BuildTimeline(history[1])
assert(timeline:find("Five or more Runes became ready", 1, true), "Timeline event missing")
local patternText = Review.BuildPatterns(history)
assert(patternText:find("What keeps coming back", 1, true), "Pattern summary missing")

local reviewSourceFile = assert(io.open("MentorReview.lua", "r"))
local reviewSource = reviewSourceFile:read("*a")
reviewSourceFile:close()
assert(reviewSource:find("local reviewReturnFrame", 1, true), "Review modal return state missing")
assert(reviewSource:find("function Review.Open(tab, parentFrame)", 1, true), "Review.Open must accept a parent frame")
assert(reviewSource:find("RestoreReviewParent()", 1, true), "Review close must restore its caller")
assert(reviewSource:find('frame:SetToplevel(true)', 1, true), "Review must be top-level while visible")


assert(not reviewSource:find('→', 1, true), 'Review must not use the unsupported arrow glyph')
assert(reviewSource:find('Overview | Timeline | Patterns: learn from one fight, then from repeated habits.', 1, true), 'Review subtitle must use font-safe separators')

print("DK Mentor 3.0.9 Review smoke test passed")
