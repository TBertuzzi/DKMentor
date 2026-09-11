local ADDON_NAME, DKM = ...

-- DK Mentor build guidance. PvE profiles reference current Wowhead guides;
-- PvP profiles reference current Icy Veins guides where available. DK Mentor
-- does not bundle third-party prose, artwork, or talent import strings. The Build
-- Mentor may clone an already-aligned player loadout into Blizzard's saved loadout
-- list, but it never auto-purchases guide nodes or silently changes the active build.
-- Context automation remains the responsibility of Loadout Pilot.
local T = DKM.T or function(value) return value end

local REVIEWED_PATCH = "12.1.0"
local REVIEWED_DATE = "2026-09-11"

local HERO_SUBTREE_BY_SPELL = {
    [433895] = 31, -- San'layn
    [444040] = 32, -- Rider of the Apocalypse
    [434765] = 33, -- Deathbringer
}

local SOURCES = {
    bloodPve = { name="Wowhead", url="https://www.wowhead.com/guide/classes/death-knight/blood/talent-builds-pve-tank", author="Mandl", updated="2026-08-20", freshness="current" },
    frostPve = { name="Wowhead", url="https://www.wowhead.com/guide/classes/death-knight/frost/talent-builds-pve-dps", author="khazakdk", updated="2026-09-05", freshness="current" },
    unholyPve = { name="Wowhead", url="https://www.wowhead.com/guide/classes/death-knight/unholy/talent-builds-pve-dps", author="Taeznak", updated="2026-09-05", freshness="current" },
    bloodPvp = { name="Icy Veins", url="https://www.icy-veins.com/wow/blood-death-knight-pve-tank-spec-builds-talents", author="Mandl / Panthea", updated="2026-08-10", freshness="current" },
    frostPvp = { name="Icy Veins", url="https://www.icy-veins.com/wow/frost-death-knight-pvp-talents-and-builds", author="Keator", updated="2026-08-10", freshness="current" },
    unholyPvp = { name="Icy Veins", url="https://www.icy-veins.com/wow/unholy-death-knight-pvp-talents-and-builds", author="Keator", updated="2026-08-10", freshness="current" },
}

local function sourced(sourceKey, name, note, pvp, meta)
    local s = SOURCES[sourceKey]
    local profile = {
        name = T(name),
        note = T(note),
        -- Keep source metadata separate so the "guide updated" label can be
        -- localized at render time after the user's DK Mentor language is known.
        source = string.format("%s • %s • guide updated %s", s.name, s.author, s.updated),
        sourceURL = s.url,
        sourceName = s.name,
        sourceAuthor = s.author,
        sourceUpdated = s.updated,
        freshness = s.freshness or "current",
        code = "",
        reviewedPatch = REVIEWED_PATCH,
        reviewedDate = REVIEWED_DATE,
        pvp = pvp and T(pvp) or pvp,
    }
    if meta then
        for key, value in pairs(meta) do profile[key] = value end
    end
    if profile.heroSpellID and not profile.heroSubTreeID then
        profile.heroSubTreeID = HERO_SUBTREE_BY_SPELL[profile.heroSpellID]
    end
    return profile
end

local BLOOD_CORE = {
    { spellID = 49028 },  -- Dancing Rune Weapon
    { spellID = 195182 }, -- Marrowrend
    { spellID = 49998 },  -- Death Strike
    { spellID = 50842 },  -- Blood Boil
    { spellID = 55233 },  -- Vampiric Blood
}

local FROST_CORE = {
    { spellID = 51271 },   -- Pillar of Frost
    { spellID = 207230 },  -- Frostscythe
    { spellID = 194913 },  -- Glacial Advance
    { spellID = 196770 },  -- Remorseless Winter
    { spellID = 1249658 }, -- Breath of Sindragosa
}

-- Lower-friction Frost presentation used by the optional SBA-friendly view.
-- It intentionally omits Breath of Sindragosa from the key-icon row and does
-- not claim that every listed ability is handled by Blizzard's assistant.
local FROST_SBA_CORE = {
    { spellID = 51271 },   -- Pillar of Frost
    { spellID = 207230 },  -- Frostscythe
    { spellID = 194913 },  -- Glacial Advance
    { spellID = 196770 },  -- Remorseless Winter
}

local UNHOLY_CORE = {
    { spellID = 42650 },  -- Army of the Dead
    { spellID = 63560 },  -- Dark Transformation
    { spellID = 85948 },  -- Festering Strike
    { spellID = 55090 },  -- Scourge Strike
    { spellID = 207317 }, -- Epidemic
}

-- 3.3 visual-tree guidance. These are context-specific markers confirmed by
-- the current guide text, not a pretend copy of an entire third-party build.
-- r10 deliberately stopped assigning one generic spec-wide marker set to every
-- context because Raid, Mythic+, Delves and Open World can use different paths.
local BLOOD_RAID_KEYS = {
    { spellID = 49028, fallbackName = "Dancing Rune Weapon", reason = "Current Blood raid guidance is built around Dancing Rune Weapon throughput; utility points remain encounter-flexible." },
}

local BLOOD_MPLUS_KEYS = {
    { spellID = 391517, fallbackName = "Umbilicus Eternus", reason = "Current Mythic+ guide explicitly provides an Umbilicus Eternus option as a low-cost ease-of-use defensive choice." },
    { spellID = 374598, fallbackName = "Blood Draw", reason = "Current Mythic+ guidance recommends retaining Blood Draw because its Death Strike Runic Power reduction is meaningful." },
    { spellID = 317610, fallbackName = "Relish in Blood", reason = "Current Mythic+ default keeps Relish in Blood, with Foul Bulwark documented as an EHP trade-in." },
}

local BLOOD_DELVE_KEYS = {
    { spellID = 391517, fallbackName = "Umbilicus Eternus", reason = "The current Delve build is derived from the Mythic+ shell with group-only elements removed; this is a confirmed low-friction marker, not a full-tree claim." },
    { spellID = 374598, fallbackName = "Blood Draw", reason = "Retained as a current defensive/resource marker from the solo-friendly Mythic+ shell." },
}

local FROST_RAID_MPLUS_KEYS = {
    { spellID = 1230301, fallbackName = "Frostreaper", reason = "Current Wowhead Raid/Mythic+ build keeps Frostreaper for boss and priority damage; Northwinds is the documented encounter-specific swap." },
    { spellID = 435005, fallbackName = "Smothering Offense", reason = "Current Wowhead guidance says Smothering Offense carries Frost AoE in Mythic+, which builds the same as Raid." },
    { spellID = 207230, spellIDs = { 1237388 }, fallbackName = "Frostscythe", reason = "Current guide uses Frostscythe at 2+ targets in the Raid/Mythic+ shell." },
    { spellID = 194913, spellIDs = { 281491 }, fallbackName = "Glacial Advance", reason = "Current guide uses Glacial Advance at 3+ targets in the Raid/Mythic+ shell." },
}

-- Wowhead exposes a separate Delve recommendation for Frost and explicitly
-- anchors it on Deathbringer/Reaper's Mark. Until the exact full import string
-- is embedded and version-verified, r10 validates the Hero tree only instead of
-- incorrectly reusing Raid/Mythic+ spec markers.
local FROST_DELVE_KEYS = {}

local UNHOLY_RIDER_AOE_KEYS = {
    { spellID = 207317, fallbackName = "Epidemic", reason = "Current Wowhead Mythic+/Delve guidance explicitly switches the Runic Power spender to Epidemic at 3+ targets." },
    { spellID = 390196, fallbackName = "Magus of the Dead", reason = "The current Rider Mythic+ profile focuses on strengthening and summoning Magi for sustained AoE." },
}

local UNHOLY_SANLAYN_AOE_KEYS = {
    { spellID = 207317, fallbackName = "Epidemic", reason = "Current Mythic+/Delve gameplay uses Epidemic for multi-target Runic Power spending." },
    { spellID = 1242616, fallbackName = "Blightfall", reason = "The current San'layn Mythic+ alternative is the disease-focused Blightfall profile." },
}

-- Current Wowhead marks Rider as the Single Target/Open World direction but the
-- extractor does not expose a stable full import string for those rows. Keep
-- those contexts Hero-only rather than validating unrelated generic spec nodes.
local UNHOLY_SINGLE_TARGET_KEYS = {}

local function withTalents(base, extra)
    local result = {}
    for _, entry in ipairs(base or {}) do result[#result + 1] = entry end
    for _, entry in ipairs(extra or {}) do result[#result + 1] = entry end
    return result
end

DKM.Builds = {
    [250] = {
        world = {
            sourced("bloodPve", "Blood — Open World / Solo", "Deathbringer is the comfortable solo default: frequent Reaper's Mark windows, strong defensive value, and less setup friction between pulls.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Solo sustain and flexible utility", badge="RECOMMENDED", keyTalents=BLOOD_CORE,
            }),
        },
        delve = {
            sourced("bloodPve", "Blood — Delves", "For Delves, favor the low-friction Deathbringer direction so travel and non-combat gaps do not punish your Hero Talent setup.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Delve survival and frequent pulls", badge="RECOMMENDED", keyTalents=BLOOD_CORE,
            }),
        },
        dungeon = {
            sourced("bloodPve", "Blood — Dungeon", "Use the Mythic+ style Deathbringer baseline for general dungeons: reliable defensive value, easy pull-to-pull setup, and flexible control points.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Dungeon tanking, control, and planned defensives", badge="RECOMMENDED", keyTalents=BLOOD_CORE,
            }),
        },
        mythicplus = {
            sourced("bloodPve", "Blood — Mythic+ / Deathbringer", "Deathbringer is the safer default for Mythic+: it is easier to execute consistently and brings strong defensive advantages while keeping Reaper's Mark on a compact cadence.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Mythic+ tanking, control, and planned defensives", badge="RECOMMENDED", keyTalents=BLOOD_CORE,
            }),
            sourced("bloodPve", "Blood — Mythic+ / San'layn", "San'layn remains a throughput-oriented alternative when you can commit Dancing Rune Weapon aggressively and maintain its haste-driven loop across pulls.", nil, {
                heroTalent="San'layn", heroSpellID=433895, focus="Higher-throughput alternative with stricter setup", badge="ALTERNATIVE", keyTalents=BLOOD_CORE,
            }),
        },
        raid = {
            sourced("bloodPve", "Blood — Raid / San'layn", "San'layn is the high-throughput raid direction when encounter timing lets you commit Dancing Rune Weapon and maintain Essence of the Blood Queen cleanly.", nil, {
                heroTalent="San'layn", heroSpellID=433895, focus="Boss tanking and throughput", badge="RECOMMENDED", keyTalents=BLOOD_CORE,
            }),
            sourced("bloodPve", "Blood — Raid / Deathbringer", "Deathbringer is the simpler raid alternative when you value predictable Reaper's Mark windows and its defensive package over San'layn's tighter maintenance loop.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Predictable burst and defensive consistency", badge="ALTERNATIVE", keyTalents=BLOOD_CORE,
            }),
        },
        pvp = { sourced("bloodPvp", "Blood — War Mode / World PvP", "Icy Veins does not maintain a dedicated Blood arena guide; this points to the current Blood talent guide and its War Mode/PvP talent guidance.", "War Mode reference. Blood is not presented here as an arena-meta specialization.", { heroTalent="War Mode reference", focus="Survival and control", badge="REFERENCE", keyTalents=BLOOD_CORE }) },
    },
    [251] = {
        world = {
            sourced("frostPve", "Frost — Open World / Solo", "Deathbringer is a strong general-purpose baseline with frequent Reaper's Mark windows and plenty of burst for tougher open-world enemies.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Solo burst, mobility, and recovery flexibility", badge="RECOMMENDED", keyTalents=FROST_CORE,
            }),
        },
        delve = {
            sourced("frostPve", "Frost — Delves / Deathbringer", "Wowhead currently recommends Deathbringer in Delves because Reaper's Mark gives you a frequent cooldown for the sturdier enemies in each pack.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Delve burst and cleave", badge="RECOMMENDED", keyTalents=FROST_CORE,
            }),
        },
        dungeon = {
            sourced("frostPve", "Frost — Dungeon", "Frost stays very close to the raid setup. Smothering Offense now carries the AoE profile; Frostbane is no longer a recommended competitive pick, while Frostscythe and Glacial Advance cover higher target counts.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Dungeon damage, cleave, and utility", badge="RECOMMENDED", keyTalents=FROST_CORE,
            }),
        },
        mythicplus = {
            sourced("frostPve", "Frost — Mythic+ / Deathbringer", "Frost currently builds almost the same in Mythic+ as in raid. Deathbringer remains the practical default; Smothering Offense carries the AoE profile, and Frostbane is no longer a recommended competitive option.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Mythic+ damage, cleave, and utility", badge="RECOMMENDED", keyTalents=FROST_CORE,
            }),
        },
        raid = {
            sourced("frostPve", "Frost — Raid / Deathbringer", "Deathbringer is the default raid direction: Reaper's Mark lines up naturally with Pillar of Frost and Exterminate adds valuable cleave without changing the core rotation much.", nil, {
                heroTalent="Deathbringer", heroSpellID=434765, focus="Boss damage and frequent burst windows", badge="RECOMMENDED", keyTalents=FROST_CORE,
            }),
            sourced("frostPve", "Frost — Raid / Rider", "Rider is a viable alternative for very stable single-target encounters and adds excellent mobility without introducing another active burst button.", nil, {
                heroTalent="Rider of the Apocalypse", heroSpellID=444040, focus="Stable single target and mobility", badge="ALTERNATIVE", keyTalents=withTalents(FROST_CORE, { { spellID=444010 } }),
            }),
        },
        pvp = {
            sourced("frostPvp", "Frost PvP — Rider", "Current Icy Veins 3v3 baseline uses Rider for sustained pressure and mobility.", "Current 12.1 PvP guide. PvP talents remain matchup-dependent.", { heroTalent="Rider of the Apocalypse", heroSpellID=444040, focus="Sustained pressure and mobility", badge="RECOMMENDED", keyTalents=withTalents(FROST_CORE, { { spellID=444010 } }) }),
            sourced("frostPvp", "Frost PvP — Deathbringer", "Deathbringer remains the coordinated one-shot / concentrated Pillar of Frost burst alternative.", "Current 12.1 PvP guide. PvP talents remain matchup-dependent.", { heroTalent="Deathbringer", heroSpellID=434765, focus="Coordinated one-shot burst", badge="ALTERNATIVE", keyTalents=FROST_CORE }),
        },
    },
    [252] = {
        world = {
            sourced("unholyPve", "Unholy — Open World / Rider", "Rider is the clean open-world default: strong pet pressure, excellent mobility, and a simple loop that does not ask you to maintain a fragile Hero Talent window between packs.", nil, {
                heroTalent="Rider of the Apocalypse", heroSpellID=444040, focus="Solo setup, pets, and recovery", badge="RECOMMENDED", keyTalents=withTalents(UNHOLY_CORE, { { spellID=444010 } }),
            }),
        },
        delve = {
            sourced("unholyPve", "Unholy — Delves / Rider", "Wowhead recommends the Rider-style Mythic+ build for Delves as the simpler sustained-AoE option, with the same core loop and excellent mobility.", nil, {
                heroTalent="Rider of the Apocalypse", heroSpellID=444040, focus="Sustained AoE and minion setup", badge="RECOMMENDED", keyTalents=withTalents(UNHOLY_CORE, { { spellID=444010 } }),
            }),
            sourced("unholyPve", "Unholy — Delves / San'layn", "San'layn remains viable in Delves if you prefer the disease-focused Blightfall / Vampiric Strike rhythm and are comfortable managing its timing.", nil, {
                heroTalent="San'layn", heroSpellID=433895, focus="Disease windows and burst setup", badge="ALTERNATIVE", keyTalents=UNHOLY_CORE,
            }),
        },
        dungeon = {
            sourced("unholyPve", "Unholy — Dungeon / Rider", "Use the Rider Mythic+ direction as the default dungeon profile: the core single-target loop stays intact and Epidemic takes over as packs reach meaningful AoE size.", nil, {
                heroTalent="Rider of the Apocalypse", heroSpellID=444040, focus="Dungeon AoE, pets, and cooldown planning", badge="RECOMMENDED", keyTalents=withTalents(UNHOLY_CORE, { { spellID=444010 } }),
            }),
        },
        mythicplus = {
            sourced("unholyPve", "Unholy — Mythic+ / Rider", "Rider focuses on sustained minion pressure and is the simpler Mythic+ recommendation. Keep the single-target loop and swap to Epidemic at 3+ targets.", nil, {
                heroTalent="Rider of the Apocalypse", heroSpellID=444040, focus="Mythic+ sustained AoE and minions", badge="RECOMMENDED", keyTalents=withTalents(UNHOLY_CORE, { { spellID=444010 } }),
            }),
            sourced("unholyPve", "Unholy — Mythic+ / San'layn", "San'layn is the viable alternative, leaning into Blightfall and disease extension during Gift of the San'layn windows before consuming the setup for a larger payoff.", nil, {
                heroTalent="San'layn", heroSpellID=433895, focus="Disease extension and burst payoff", badge="ALTERNATIVE", keyTalents=UNHOLY_CORE,
            }),
        },
        raid = {
            sourced("unholyPve", "Unholy — Single Target / Rider", "Rider is the straightforward raid baseline for the current single-target build, reinforcing Unholy's major minion windows without adding another active Hero Talent button.", nil, {
                heroTalent="Rider of the Apocalypse", heroSpellID=444040, focus="Single-target setup and major minion windows", badge="RECOMMENDED", keyTalents=UNHOLY_CORE,
            }),
        },
        pvp = {
            sourced("unholyPvp", "Unholy PvP — Pet", "Icy Veins' explanatory text says the Disease build is currently weaker than the Pet build. DK Mentor therefore treats Pet as the practical default while the same source still labels Disease as its Best 3v3 heading.", "Current 12.1 PvP guide. PvP talents should be adjusted for the opposing composition; the source currently contains contradictory Pet/Disease ranking text.", { heroTalent="Rider of the Apocalypse", heroSpellID=444040, focus="Pet damage and single-target pressure", badge="RECOMMENDED", keyTalents=UNHOLY_CORE }),
            sourced("unholyPvp", "Unholy PvP — Disease", "Disease remains the rot-pressure alternative. Icy Veins labels it Best 3v3 in the page heading, but the explanatory text says it is currently weaker than the Pet build.", "Current 12.1 PvP guide. PvP talents should be adjusted for the opposing composition; the source currently contains contradictory Pet/Disease ranking text.", { heroTalent="San'layn", heroSpellID=433895, focus="3v3 rot pressure and spread damage", badge="ALTERNATIVE", keyTalents=UNHOLY_CORE }),
        },
    },
}

-- Attach context-specific visual-tree audit data after the profile table is built.
-- `treeCoverage` is intentionally visible to TalentTree.lua so the UI can tell
-- the player whether it is validating a full guide import or only confirmed
-- context markers. r10 never calls a marker-only comparison an exact Wowhead build.
local TREE_GUIDANCE = {
    [250] = {
        world = { keys = BLOOD_DELVE_KEYS, coverage = "derived-markers", label = "Solo markers derived from the current Wowhead Delve direction" },
        delve = { keys = BLOOD_DELVE_KEYS, coverage = "context-markers", label = "Current Wowhead Delve markers" },
        dungeon = { keys = BLOOD_MPLUS_KEYS, coverage = "derived-markers", label = "Dungeon markers derived from the current Wowhead Mythic+ direction" },
        mythicplus = { keys = BLOOD_MPLUS_KEYS, coverage = "context-markers", label = "Current Wowhead Mythic+ markers" },
        raid = { keys = BLOOD_RAID_KEYS, coverage = "context-markers", label = "Current Wowhead Raid markers" },
    },
    [251] = {
        world = { keys = FROST_DELVE_KEYS, coverage = "hero-only", label = "Solo Hero Talent direction; full Open World tree is not claimed" },
        delve = { keys = FROST_DELVE_KEYS, coverage = "hero-only", label = "Current Wowhead Delve Hero Talent direction" },
        dungeon = { keys = FROST_RAID_MPLUS_KEYS, coverage = "derived-markers", label = "Dungeon markers derived from the current Wowhead Mythic+ build" },
        mythicplus = { keys = FROST_RAID_MPLUS_KEYS, coverage = "context-markers", label = "Current Wowhead Mythic+ markers (same build family as Raid)" },
        raid = { keys = FROST_RAID_MPLUS_KEYS, coverage = "context-markers", label = "Current Wowhead Raid markers" },
    },
    [252] = {
        world = { keys = UNHOLY_SINGLE_TARGET_KEYS, coverage = "hero-only", label = "Current Wowhead Open World Hero Talent direction" },
        delve = { byHero = { [31] = UNHOLY_SANLAYN_AOE_KEYS, [32] = UNHOLY_RIDER_AOE_KEYS }, coverage = "context-markers", label = "Current Wowhead Delve markers (same build families as Mythic+)" },
        dungeon = { byHero = { [31] = UNHOLY_SANLAYN_AOE_KEYS, [32] = UNHOLY_RIDER_AOE_KEYS }, coverage = "derived-markers", label = "Dungeon markers derived from the current Wowhead Mythic+ direction" },
        mythicplus = { byHero = { [31] = UNHOLY_SANLAYN_AOE_KEYS, [32] = UNHOLY_RIDER_AOE_KEYS }, coverage = "context-markers", label = "Current Wowhead Mythic+ markers" },
        raid = { keys = UNHOLY_SINGLE_TARGET_KEYS, coverage = "hero-only", label = "Current Wowhead Single Target/Raid Hero Talent direction" },
    },
}

for specID, specBuilds in pairs(DKM.Builds) do
    for contextKey, profiles in pairs(specBuilds) do
        for _, profile in ipairs(profiles) do
            profile.contextKey = contextKey
            if profile.heroSpellID and not profile.heroSubTreeID then
                profile.heroSubTreeID = HERO_SUBTREE_BY_SPELL[profile.heroSpellID]
            end
            local guidance = TREE_GUIDANCE[specID] and TREE_GUIDANCE[specID][contextKey]
            if contextKey ~= "pvp" and guidance then
                local keys = guidance.keys
                if guidance.byHero then keys = guidance.byHero[profile.heroSubTreeID] or {} end
                profile.treeKeyTalents = keys or {}
                profile.treeCoverage = guidance.coverage
                profile.treeCoverageLabel = guidance.label
                profile.guideExactImport = false
            end
        end
    end
end

-- DK Mentor 3.1 accessibility layer. This is deliberately recommendation-only:
-- Blizzard's native Single-Button Assistant owns the offensive sequence. DK
-- Mentor simply favors lower-friction profiles and reminds the player which
-- categories remain manual (defensives, interrupts, crowd control and utility).
for specID, specBuilds in pairs(DKM.Builds) do
    for contextKey, profiles in pairs(specBuilds) do
        for _, profile in ipairs(profiles) do
            if specID == 250 then
                profile.sbaFriendly = profile.heroSubTreeID == 33
                if profile.sbaFriendly then
                    profile.sbaKeyTalents = BLOOD_CORE
                    profile.sbaNote = "SBA-friendly: Deathbringer is favored for lower setup friction. Blizzard SBA can handle supported offensive sequencing, while Death Strike decisions, defensives, interrupts, grips, crowd control, and utility remain manual."
                end
            elseif specID == 251 then
                profile.sbaFriendly = not (contextKey == "pvp" and profile.heroSubTreeID == 33)
                profile.sbaKeyTalents = FROST_SBA_CORE
                if profile.sbaFriendly then
                    profile.sbaNote = "SBA-friendly: favor the reduced-complexity Frost direction and avoid Breath of Sindragosa or Shattering Blade when the selected build allows it. Defensives, interrupts, crowd control, utility, and encounter-specific movement remain manual."
                else
                    profile.sbaNote = "This profile is kept as a manual burst alternative. SBA-friendly mode favors Rider in PvP because the Deathbringer one-shot setup asks for tighter manual coordination."
                end
            elseif specID == 252 then
                profile.sbaFriendly = profile.heroSubTreeID == 32
                profile.sbaKeyTalents = UNHOLY_CORE
                if profile.sbaFriendly then
                    profile.sbaNote = "SBA-friendly: Rider is favored for a simpler sustained loop with fewer fragile setup windows. Blizzard SBA handles only supported offensive sequencing; defensives, interrupts, crowd control, utility, pet positioning, and situational PvP decisions remain manual."
                end
            end
        end
    end
end
