-- Minimal out-of-client smoke test for the 3.0 Adaptive DK Coach module.
_G = _G or _ENV
Enum = { PowerType = { RunicPower = 6 } }
UIParent = {}

local createdFrames = {}
function CreateFrame()
    local frame = { scripts = {} }
    function frame:RegisterEvent(event)
        assert(event ~= "COMBAT_LOG_EVENT_UNFILTERED", "Midnight forbidden CLEU registration attempted")
    end
    function frame:RegisterUnitEvent() end
    function frame:SetScript(name, fn) self.scripts[name] = fn end
    createdFrames[#createdFrames + 1] = frame
    return frame
end

function UnitHealth() return 100 end
function UnitHealthMax() return 100 end
function UnitPower() return 95 end
function UnitPowerMax() return 100 end
function GetRuneCooldown() return 0, 0, true end
function UnitExists() return false end
function UnitGUID() return "Player-1" end
function GetTime() return 100 end

local addon = {}
function addon:GetAdaptiveCoachEntries(_, _, base) return base or {}, nil, nil end
function addon:UpdateCoach() end
function addon:UpdateAll() end
function addon:ShowHelp() end
function addon:HandleSlashCommand() end
function addon:GetSpecInfo() return 251, "Frost" end
function addon:DetectContext() return "world" end

local DKM = {
    Addon = addon,
    Data = {
        spells = { MIND_FREEZE = 47528, ANTI_MAGIC_SHELL = 48707, ICEBOUND_FORTITUDE = 48792, DEATH_STRIKE = 49998 },
        contextNames = { world = "World" },
        procGlowMappings = {},
    },
    T = function(value, ...)
        if select("#", ...) > 0 then return string.format(value, ...) end
        return value
    end,
}

local chunk = assert(loadfile("MentorEngine.lua"))
chunk("DKMentor", DKM)
assert(DKM.MentorEngine, "MentorEngine was not exported")
assert(type(addon.GetAdaptiveCoachEntries) == "function", "Adaptive coach override missing")
assert(type(DKM.MentorEngine.ResetSettings) == "function", "Mentor reset helper missing")
assert(type(DKM.MentorEngine.TestAlerts) == "function", "Mentor alert preview helper missing")
assert(type(DKM.MentorEngine.GetState) == "function", "3.0 Mentor state bridge missing")
assert(type(DKM.MentorEngine.AddTimelineEvent) == "function", "3.0 timeline bridge missing")

local sourceFile = assert(io.open("MentorEngine.lua", "r"))
local source = sourceFile:read("*a")
sourceFile:close()
assert(source:find("BUILD GHOULS", 1, true), "Midnight Unholy Lesser Ghoul coaching missing")
assert(source:find("SUMMON GHOUL", 1, true), "Midnight Unholy Lesser Ghoul consumer coaching missing")
assert(not source:find("and not breathActive", 1, true), "Old Breath Runic Power suppression returned")

local entries = addon:GetAdaptiveCoachEntries(251, "world", {})
assert(#entries >= 1 and entries[1].spellID == 49143, "Mentor mode should surface Frost Strike near Runic Power cap")

DKMentorDB.mentor.mode = "essential"
entries = addon:GetAdaptiveCoachEntries(251, "world", {})
assert(#entries == 0, "Essential mode should not surface non-urgent Runic Power coaching")


-- 3.0.6: the first card can mirror Blizzard Assisted Combat without replacing
-- the rest of the Mentor context.
C_AssistedCombat = {
    GetNextCastSpell = function(checkForVisibleButton)
        assert(checkForVisibleButton == false, "Pinned Mentor card should request Blizzard's recommendation without requiring a visible action button")
        return 49020 -- Obliterate
    end,
}
DKMentorDB.mentor.mode = "essential"
DKMentorDB.mentor.pinNextAction = true
entries = addon:GetAdaptiveCoachEntries(251, "world", {})
assert(#entries == 1, "Essential + pinned next action should show the Blizzard recommendation even with no urgent Mentor warning")
assert(entries[1].spellID == 49020, "Pinned card 1 should use C_AssistedCombat.GetNextCastSpell")
assert(entries[1].title == "NEXT", "Pinned card 1 should have the NEXT label")
assert(entries[1].kind == "rotation", "Pinned card 1 should use the rotation presentation kind")

UnitHealth = function() return 20 end
entries = addon:GetAdaptiveCoachEntries(251, "world", {})
assert(entries[1] and entries[1].spellID == 49020, "Urgent survival must not displace the fixed Blizzard card 1")
assert(entries[2] and entries[2].spellID == 48792, "Urgent defensive guidance should continue in the remaining Mentor cards")
UnitHealth = function() return 100 end

DKMentorDB.mentor.pinNextAction = false
entries = addon:GetAdaptiveCoachEntries(251, "world", {})
assert(#entries == 0, "Disabling pinned next action should restore Essential urgent-only behavior")
C_AssistedCombat = nil

DKMentorDB.mentor.postCombat = false
DKMentorDB.mentor.lastReport = { score = 77 }
DKM.MentorEngine.ResetSettings()
assert(DKMentorDB.mentor.mode == "mentor", "Reset should restore Mentor mode")
assert(DKMentorDB.mentor.postCombat == true, "Reset should restore post-combat popup default")
assert(DKMentorDB.mentor.lastReport and DKMentorDB.mentor.lastReport.score == 77, "Reset should preserve last combat report")

print("DK Mentor 3.0.9 MentorEngine smoke test passed")
