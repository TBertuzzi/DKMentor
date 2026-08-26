-- Minimal out-of-client smoke test for the 2.0.11 Adaptive DK Coach module.
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

local entries = addon:GetAdaptiveCoachEntries(251, "world", {})
assert(#entries >= 1 and entries[1].spellID == 49143, "Mentor mode should surface Frost Strike near Runic Power cap")

DKMentorDB.mentor.mode = "essential"
entries = addon:GetAdaptiveCoachEntries(251, "world", {})
assert(#entries == 0, "Essential mode should not surface non-urgent Runic Power coaching")

DKMentorDB.mentor.postCombat = false
DKMentorDB.mentor.lastReport = { score = 77 }
DKM.MentorEngine.ResetSettings()
assert(DKMentorDB.mentor.mode == "mentor", "Reset should restore Mentor mode")
assert(DKMentorDB.mentor.postCombat == true, "Reset should restore post-combat popup default")
assert(DKMentorDB.mentor.lastReport and DKMentorDB.mentor.lastReport.score == 77, "Reset should preserve last combat report")

print("DK Mentor 2.0.11 MentorEngine smoke test passed")
