local ADDON_NAME, DKM = ...

-- DK Mentor build guidance. PvE profiles reference current Wowhead guides;
-- PvP profiles reference current Icy Veins guides where available. DK Mentor
-- does not bundle third-party prose, artwork, or talent import strings and does
-- not create, select, or switch WoW loadouts. Automation belongs to Loadout Pilot.
local T = DKM.T or function(value) return value end

local REVIEWED_PATCH = "12.1.0"
local REVIEWED_DATE = "2026-08-22"

local SOURCES = {
    bloodPve = { name="Wowhead", url="https://www.wowhead.com/guide/classes/death-knight/blood/talent-builds-pve-tank", author="Mandl", updated="2026-08-20" },
    frostPve = { name="Wowhead", url="https://www.wowhead.com/guide/classes/death-knight/frost/talent-builds-pve-dps", author="khazakdk", updated="2026-08-12" },
    unholyPve = { name="Wowhead", url="https://www.wowhead.com/guide/classes/death-knight/unholy/talent-builds-pve-dps", author="Taeznak", updated="2026-08-12" },
    bloodPvp = { name="Icy Veins", url="https://www.icy-veins.com/wow/blood-death-knight-pve-tank-spec-builds-talents", author="Mandl / Panthea", updated="2026-08-10" },
    frostPvp = { name="Icy Veins", url="https://www.icy-veins.com/wow/frost-death-knight-pvp-talents-and-builds", author="Keator", updated="2026-08-10" },
    unholyPvp = { name="Icy Veins", url="https://www.icy-veins.com/wow/unholy-death-knight-pvp-talents-and-builds", author="Keator", updated="2026-08-10" },
}

local function sourced(sourceKey, name, note, pvp)
    local s = SOURCES[sourceKey]
    return {
        name = T(name),
        note = T(note),
        -- Keep source metadata separate so the "guide updated" label can be
        -- localized at render time after the user's DK Mentor language is known.
        source = string.format("%s • %s • guide updated %s", s.name, s.author, s.updated),
        sourceURL = s.url,
        sourceName = s.name,
        sourceAuthor = s.author,
        sourceUpdated = s.updated,
        code = "",
        reviewedPatch = REVIEWED_PATCH,
        reviewedDate = REVIEWED_DATE,
        pvp = pvp and T(pvp) or pvp,
    }
end

DKM.Builds = {
    [250] = {
        world = { sourced("bloodPve", "Blood — Open World / Solo", "Use the current Blood PvE guide as the baseline, then favor comfort, self-sustain, and utility for solo pulls.") },
        delve = { sourced("bloodPve", "Blood — Delves", "Use the guide's current Delve-oriented direction, emphasizing self-sustain and practical defensive coverage.") },
        dungeon = { sourced("bloodPve", "Blood — Dungeon / Mythic+", "Use the current Mythic+ recommendation as the dungeon baseline, with encounter-specific utility adjusted as needed.") },
        raid = { sourced("bloodPve", "Blood — Raid", "Use the current raid recommendation for boss tanking, then move flexible utility points for encounter mechanics.") },
        pvp = { sourced("bloodPvp", "Blood — War Mode / World PvP", "Icy Veins does not maintain a dedicated Blood arena guide; this points to the current Blood talent guide and its War Mode/PvP talent guidance.", "War Mode reference. Blood is not presented here as an arena-meta specialization.") },
    },
    [251] = {
        world = { sourced("frostPve", "Frost — Open World / Solo", "Use the current Frost PvE recommendation as a starting point, retaining utility and Runic Power flexibility for solo survival.") },
        delve = { sourced("frostPve", "Frost — Delves (Deathbringer)", "The current guide recommends Deathbringer for Delves, giving frequent power for tougher enemies while retaining strong cleave.") },
        dungeon = { sourced("frostPve", "Frost — Dungeon / Mythic+", "Use the current Mythic+ recommendation. The guide currently keeps Frost's overall direction close to its raid setup with limited swaps.") },
        raid = { sourced("frostPve", "Frost — Raid", "Use the current raid recommendation for boss damage and adjust utility or cleave options for encounter needs.") },
        pvp = {
            sourced("frostPvp", "Frost PvP — Deathbringer", "Current Icy Veins PvP guide option focused on stronger burst setup and coordinated pressure.", "Current 12.1 PvP guide. PvP talents remain matchup-dependent."),
            sourced("frostPvp", "Frost PvP — Rider", "Current Icy Veins PvP alternative focused more on sustained pressure and a less all-in burst profile.", "Current 12.1 PvP guide. PvP talents remain matchup-dependent."),
        },
    },
    [252] = {
        world = { sourced("unholyPve", "Unholy — Open World", "Use the guide's current Open World recommendation for questing and solo play, preserving enough resources to recover with Death Strike when pressured.") },
        delve = { sourced("unholyPve", "Unholy — Delves / Sustained AoE", "The current guide points Delve players toward its Mythic+ builds, with a simpler sustained-AoE direction suitable for general Delve play.") },
        dungeon = {
            sourced("unholyPve", "Unholy — Mythic+ / Dungeon", "Use the current Mythic+ recommendation as the default dungeon profile."),
            sourced("unholyPve", "Unholy — Mythic+ Alternate", "Use the guide's alternate current Mythic+ direction when you prefer that playstyle and its timing requirements."),
        },
        raid = { sourced("unholyPve", "Unholy — Single Target / Raid", "Use the current Single Target recommendation as the raid baseline.") },
        pvp = {
            sourced("unholyPvp", "Unholy PvP — Pet", "Current Icy Veins PvP option focused on pet damage and single-target pressure.", "Current 12.1 PvP guide. PvP talents should be adjusted for the opposing composition."),
            sourced("unholyPvp", "Unholy PvP — Disease", "Current Icy Veins PvP alternative for rot pressure; the guide currently describes it as weaker than the pet setup.", "Current 12.1 PvP guide. PvP talents should be adjusted for the opposing composition."),
        },
    },
}
