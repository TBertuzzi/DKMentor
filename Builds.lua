local ADDON_NAME, DKM = ...

-- DK Mentor build guidance. PvE profiles reference current Wowhead guides;
-- PvP profiles reference current Icy Veins guides where available. DK Mentor
-- does not bundle third-party prose, artwork, or talent import strings and does
-- not create, select, or switch WoW loadouts. Automation belongs to Loadout Pilot.
local T = DKM.T or function(value) return value end

local REVIEWED_PATCH = "12.1.0"
local REVIEWED_DATE = "2026-09-06"

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
            sourced("unholyPvp", "Unholy PvP — Disease", "Icy Veins currently labels the Disease setup as its Best 3v3 build, emphasizing rot pressure and spread damage.", "Current 12.1 PvP guide. PvP talents should be adjusted for the opposing composition.", { heroTalent="San'layn", heroSpellID=433895, focus="3v3 rot pressure and spread damage", badge="RECOMMENDED", keyTalents=UNHOLY_CORE }),
            sourced("unholyPvp", "Unholy PvP — Pet", "Pet remains the single-target and pet-damage alternative for compositions that want more focused pressure.", "Current 12.1 PvP guide. PvP talents should be adjusted for the opposing composition.", { heroTalent="Rider of the Apocalypse", heroSpellID=444040, focus="Pet damage and single-target pressure", badge="ALTERNATIVE", keyTalents=UNHOLY_CORE }),
        },
    },
}


-- DK Mentor 3.1 accessibility layer. This is deliberately recommendation-only:
-- Blizzard's native Single-Button Assistant owns the offensive sequence. DK
-- Mentor simply favors lower-friction profiles and reminds the player which
-- categories remain manual (defensives, interrupts, crowd control and utility).
for specID, specBuilds in pairs(DKM.Builds) do
    for contextKey, profiles in pairs(specBuilds) do
        for _, profile in ipairs(profiles) do
            if specID == 250 then
                profile.sbaFriendly = profile.heroTalent == "Deathbringer"
                if profile.sbaFriendly then
                    profile.sbaKeyTalents = BLOOD_CORE
                    profile.sbaNote = "SBA-friendly: Deathbringer is favored for lower setup friction. Blizzard SBA can handle supported offensive sequencing, while Death Strike decisions, defensives, interrupts, grips, crowd control, and utility remain manual."
                end
            elseif specID == 251 then
                profile.sbaFriendly = not (contextKey == "pvp" and profile.heroTalent == "Deathbringer")
                profile.sbaKeyTalents = FROST_SBA_CORE
                if profile.sbaFriendly then
                    profile.sbaNote = "SBA-friendly: favor the reduced-complexity Frost direction and avoid Breath of Sindragosa or Shattering Blade when the selected build allows it. Defensives, interrupts, crowd control, utility, and encounter-specific movement remain manual."
                else
                    profile.sbaNote = "This profile is kept as a manual burst alternative. SBA-friendly mode favors Rider in PvP because the Deathbringer one-shot setup asks for tighter manual coordination."
                end
            elseif specID == 252 then
                profile.sbaFriendly = profile.heroTalent == "Rider of the Apocalypse"
                profile.sbaKeyTalents = UNHOLY_CORE
                if profile.sbaFriendly then
                    profile.sbaNote = "SBA-friendly: Rider is favored for a simpler sustained loop with fewer fragile setup windows. Blizzard SBA handles only supported offensive sequencing; defensives, interrupts, crowd control, utility, pet positioning, and situational PvP decisions remain manual."
                end
            end
        end
    end
end
