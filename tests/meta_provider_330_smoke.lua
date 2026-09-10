-- DK Mentor 3.3 optional Archon provider/fallback smoke test.
local DKM = {}

-- Minimal addon API stub used by provider detection.
local loaded = {}
C_AddOns = {
    IsAddOnLoaded = function(name) return loaded[name] == true end,
}

assert(loadfile("MetaData.lua"))("DKMentor", DKM)
assert(loadfile("MetaProvider.lua"))("DKMentor", DKM)

local provider = assert(DKM.MetaProvider, "MetaProvider missing")
local builtIn = assert(DKM.MetaData, "built-in MetaData missing")

_G.ArchonTooltip = nil
_G.ArchonTooltipPrivate = nil
_G.ArchonTooltipMetaData = nil
_G.ArchonTooltipMetaSnapshot = nil
_G.DKMentorArchonMeta = nil
_G.ArchonTooltipDB_US = nil

local snapshot, status = provider:GetActiveSnapshot()
assert(snapshot == builtIn, "No Archon should use built-in snapshot")
assert(status.kind == "builtin" and not status.archonDetected, "No Archon status mismatch")

-- Core-only Archon: detected, but profile-only data must fall back.
loaded.ArchonTooltip = true
_G.ArchonTooltip = {}
snapshot, status = provider:GetActiveSnapshot()
assert(snapshot == builtIn, "Profile-only Archon must safely fall back")
assert(status.kind == "builtin" and status.archonDetected and status.archonCoreLoaded and not status.compatible, "Loaded Archon fallback status mismatch")

-- Region DB detection must be visible even though it is not aggregate meta data.
loaded.ArchonTooltipDB_US = true
snapshot, status = provider:GetActiveSnapshot()
assert(snapshot == builtIn, "Archon DB alone must not replace built-in aggregate data")
assert(status.archonDBLoaded and status.archonDBName == "ArchonTooltipDB_US", "Archon region DB detection mismatch")

local IDS = { A = 434765, B = 433895, C = 444040, Other = 444040 }
local function row(hero, usage)
    return {
        role = "DPS",
        hero = hero,
        heroSpellID = IDS[hero],
        heroUsage = usage,
        alternativeHero = "Other",
        alternativeHeroSpellID = IDS.Other,
        alternativeUsage = 100 - usage,
        parses = 100,
    }
end
local live = {
    patch = "12.1.0",
    reviewed = "2099-01-01",
    sourceName = "Archon test aggregate",
    contextOrder = { "raid", "mythicplus", "highkeys" },
    contexts = {
        raid = { specs = { [250] = row("A", 90), [251] = row("B", 90), [252] = row("C", 90) } },
        mythicplus = { specs = { [250] = row("A", 91), [251] = row("B", 91), [252] = row("C", 91) } },
        highkeys = { specs = { [250] = row("A", 92), [251] = row("B", 92), [252] = row("C", 92) } },
    },
}

_G.ArchonTooltip.MetaSnapshot = live
snapshot, status = provider:GetActiveSnapshot()
assert(snapshot == live, "Compatible Archon aggregate snapshot should win")
assert(status.kind == "archon" and status.compatible, "Compatible Archon status mismatch")

-- A name-only snapshot must be rejected: identity contract is stable IDs.
local invalidNameOnly = {
    contextOrder = { "raid", "mythicplus", "highkeys" },
    contexts = {
        raid = { specs = { [250] = { role="DPS", hero="A", heroUsage=90 }, [251] = { role="DPS", hero="B", heroUsage=90 }, [252] = { role="DPS", hero="C", heroUsage=90 } } },
        mythicplus = { specs = { [250] = { role="DPS", hero="A", heroUsage=90 }, [251] = { role="DPS", hero="B", heroUsage=90 }, [252] = { role="DPS", hero="C", heroUsage=90 } } },
        highkeys = { specs = { [250] = { role="DPS", hero="A", heroUsage=90 }, [251] = { role="DPS", hero="B", heroUsage=90 }, [252] = { role="DPS", hero="C", heroUsage=90 } } },
    },
}
_G.ArchonTooltip.MetaSnapshot = invalidNameOnly
snapshot, status = provider:GetActiveSnapshot()
assert(snapshot == builtIn and status.kind == "builtin", "Name-only Archon data must fail closed to built-in")

_G.ArchonTooltip.MetaSnapshot = live
local ok, reason = _G.DKMentorMetaBridge.RegisterSnapshot("test-bridge", live, 100)
assert(ok == true and reason == nil, "Bridge registration failed")
snapshot, status = provider:GetActiveSnapshot()
assert(snapshot == live and status.kind == "external" and status.id == "test-bridge", "Registered external provider should win")
_G.DKMentorMetaBridge.ClearSnapshot("test-bridge")

print("DK Mentor 3.3 Meta provider fallback smoke test passed")
