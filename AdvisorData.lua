local ADDON_NAME, DKM = ...

-- DK Mentor 3.2 advisor data.
-- Canonical English strings are localized at render time. This file stores
-- compact, guide-backed direction only; it intentionally does not embed
-- third-party talent strings, prose, artwork, or addon code.

local AdvisorData = {
    patch = "12.1.0",
    season = "Midnight Season 2",
    reviewed = "2026-09-06",
    folioTreeID = 1186,
    specs = {},
}

AdvisorData.diminishingReturns = {
    crit = { 1380, 1840, 2300 },
    haste = { 1320, 1760, 2200 },
    mastery = { 1380, 1840, 2300 },
    versatility = { 1620, 2160, 2700 },
}

AdvisorData.statLabels = {
    crit = "Critical Strike",
    haste = "Haste",
    mastery = "Mastery",
    versatility = "Versatility",
}

AdvisorData.heroMarkers = {
    [250] = {
        { name = "Deathbringer", spellIDs = { 434765 } },
        { name = "San'layn", spellIDs = { 433895 } },
    },
    [251] = {
        { name = "Deathbringer", spellIDs = { 434765 } },
        { name = "Rider of the Apocalypse", spellIDs = { 444040, 444010 } },
    },
    [252] = {
        { name = "Rider of the Apocalypse", spellIDs = { 444040, 444010 } },
        { name = "San'layn", spellIDs = { 433895 } },
    },
}

-- Spell IDs are used only for native WoW icon/tooltips and optional read-only
-- selection detection. C_Traits tree detection remains the primary path.
AdvisorData.folioRunes = {
    unleashedFire = { name = "Rune of Unleashed Fire", spellIDs = { 1279599 } },
    voidTouchedOrbs = { name = "Rune of Void-Touched Orbs", spellIDs = { 1279596 } },
    selfMending = { name = "Rune of Self-Mending", spellIDs = { 1279603 } },
    voidTaintedShell = { name = "Rune of Void-Tainted Shell", spellIDs = { 1279604 } },
    lingering = { name = "Rune of Lingering", spellIDs = { 1287555, 1287663, 1287665 } },
    criticalPower = { name = "Rune of Critical Power", spellIDs = { 1279609, 1287772 } },
    masterfulCunning = { name = "Rune of Masterful Cunning", spellIDs = { 1279612, 1287771 } },
    overload = { name = "Rune of Overload", spellIDs = { 1279614 } },
    echoes = { name = "Rune of Echoes", spellIDs = { 1279616, 1289063, 1303048, 1303071 } },
}

-- Used only by the optional spell-known fallback. A fallback selection is
-- accepted only when exactly one known rune can be identified in every row;
-- ambiguous rows are treated as NOT DETECTED rather than guessed.
AdvisorData.folioRowCandidates = {
    { "unleashedFire", "voidTouchedOrbs" },
    { "selfMending", "voidTaintedShell" },
    { "lingering" },
    { "criticalPower", "masterfulCunning" },
    { "overload", "echoes" },
}

local function Folio(rows, sourceURL, sourceUpdated, note)
    return {
        rows = rows,
        sourceName = "Icy Veins",
        sourceURL = sourceURL,
        sourceUpdated = sourceUpdated,
        note = note,
        freshness = "current",
    }
end

local PVE_DPS_FOLIO = {
    { row = 1, rune = "unleashedFire" },
    { row = 2, rune = "voidTaintedShell" },
    { row = 3, rune = "lingering", fixed = true },
    { row = 4, rune = "criticalPower" },
    { row = 5, rune = "overload" },
}

local PVP_DPS_FOLIO = {
    { row = 1, rune = "voidTouchedOrbs" },
    { row = 2, rune = "voidTaintedShell" },
    { row = 3, rune = "lingering", fixed = true },
    { row = 4, rune = "masterfulCunning" },
    { row = 5, rune = "echoes" },
}

local BLOOD_PVE_FOLIO = {
    { row = 1, rune = "unleashedFire" },
    { row = 2, rune = "selfMending" },
    { row = 3, rune = "lingering", fixed = true },
    { row = 4, rune = "criticalPower" },
    { row = 5, rune = "overload" },
}

AdvisorData.specs[250] = {
    stats = {
        pve = {
            sourceName = "Icy Veins",
            sourceURL = "https://www.icy-veins.com/wow/blood-death-knight-pve-tank-stat-priority",
            sourceUpdated = "2026-08-10",
            freshness = "current",
            default = {
                priority = "Strength > Crit > Mastery > Versatility > Haste",
                note = "Deathbringer baseline: item level and Strength first; Crit is the preferred secondary, with Haste intentionally last.",
            },
            hero = {
                ["Deathbringer"] = {
                    priority = "Strength > Crit > Mastery > Versatility > Haste",
                    note = "Deathbringer strongly favors Critical Strike and gets less direct value from Haste than San'layn.",
                },
                ["San'layn"] = {
                    priority = "Strength > Haste > Crit > Mastery > Versatility",
                    note = "San'layn strongly favors Haste up to roughly 30% unbuffed, but the exact target depends on your gear and should be simulated.",
                },
            },
        },
        pvp = {
            sourceName = "DK Mentor / Icy Veins Blood reference",
            sourceURL = "https://www.icy-veins.com/wow/blood-death-knight-pve-tank-stat-priority",
            sourceUpdated = "2026-08-10",
            freshness = "current",
            default = {
                priority = "Item Level / Strength > survivability needs > secondary optimization",
                note = "Blood has no dedicated arena stat baseline in the embedded sources. DK Mentor keeps the Blood PvE defensive baseline and treats PvP optimization as niche/advisory.",
            },
        },
    },
    folio = {
        pve = Folio(BLOOD_PVE_FOLIO, "https://www.icy-veins.com/wow/blood-death-knight-pve-tank-spec-builds-talents", "2026-08-10", "General Blood recommendation; row 4 can move with your current gear balance."),
        pvp = Folio(BLOOD_PVE_FOLIO, "https://www.icy-veins.com/wow/blood-death-knight-pve-tank-spec-builds-talents", "2026-08-10", "Blood PvP uses the general Blood Folio baseline because there is no dedicated arena Folio recommendation embedded."),
    },
}

AdvisorData.specs[251] = {
    stats = {
        pve = {
            sourceName = "Wowhead + Icy Veins",
            sourceURL = "https://www.wowhead.com/guide/classes/death-knight/frost/stat-priority-pve-dps",
            sourceUpdated = "2026-08-12",
            freshness = "current",
            default = {
                priority = "Strength > Crit > Mastery > Haste > Versatility",
                note = "Wowhead currently ranks Crit first with Mastery then Haste; Icy Veins ranks Crit then Haste then Mastery. Treat Mastery/Haste as the close secondary band and sim important choices.",
            },
            hero = {
                ["Deathbringer"] = {
                    priority = "Strength > Crit > Mastery > Haste > Versatility",
                    note = "Current Wowhead Deathbringer baseline, re-reviewed after the September 1 Frost tuning. The stat order remains unchanged; sim close Mastery/Haste choices for your character.",
                },
                ["Rider of the Apocalypse"] = {
                    priority = "Strength > Crit > Mastery > Haste > Versatility",
                    note = "Current Wowhead Rider baseline; practical Rider setups can value Haste strongly, so sim close Mastery/Haste choices. Re-reviewed after the September 1 Frost tuning.",
                },
            },
        },
        pvp = {
            sourceName = "Icy Veins",
            sourceURL = "https://www.icy-veins.com/wow/frost-death-knight-pvp-stat-priority-gear-and-trinkets",
            sourceUpdated = "2026-08-20",
            freshness = "current",
            default = {
                priority = "Item Level > Versatility > Mastery > Haste > Critical Strike",
                note = "General PvP target: about 15% Haste as Deathbringer or 20% as Rider. Dual-wield Long Winter setups can lean toward roughly 12-15% Crit; 2H leans more toward Mastery.",
            },
        },
    },
    folio = {
        pve = Folio(PVE_DPS_FOLIO, "https://www.icy-veins.com/wow/frost-death-knight-pve-dps-spec-builds-talents", "2026-08-10", "Current Patch 12.1 Frost PvE Folio baseline."),
        pvp = Folio(PVP_DPS_FOLIO, "https://www.icy-veins.com/wow/frost-death-knight-pvp-talents-and-builds", "2026-08-10", "Current Patch 12.1 Frost PvP Folio baseline."),
    },
}

AdvisorData.specs[252] = {
    stats = {
        pve = {
            sourceName = "Wowhead + Icy Veins",
            sourceURL = "https://www.wowhead.com/guide/classes/death-knight/unholy/stat-priority-pve-dps",
            sourceUpdated = "2026-08-17",
            freshness = "current",
            default = {
                priority = "Strength > Crit > Mastery > Haste > Versatility",
                note = "Crit, Mastery, and Haste form Unholy's useful secondary group; Versatility is generally the weakest damage secondary. Item-level upgrades usually win.",
            },
            hero = {
                ["Rider of the Apocalypse"] = {
                    priority = "Strength > Crit > Mastery > Haste > Versatility",
                    note = "Current general Unholy stat baseline; use simulations for close Crit/Mastery/Haste tradeoffs.",
                },
                ["San'layn"] = {
                    priority = "Strength > Crit > Mastery > Haste > Versatility",
                    note = "Current general Unholy stat baseline; use simulations for close Crit/Mastery/Haste tradeoffs.",
                },
            },
        },
        pvp = {
            sourceName = "Icy Veins",
            sourceURL = "https://www.icy-veins.com/wow/unholy-death-knight-pvp-stat-priority-gear-and-trinkets",
            sourceUpdated = "2026-08-20",
            freshness = "current",
            default = {
                priority = "Item Level > Versatility > Mastery > Haste > Critical Strike",
                note = "Versatility is the clear PvP baseline, followed by Mastery. Haste supports burst cadence and resource flow; exact balance remains composition and gear dependent.",
            },
        },
    },
    folio = {
        pve = Folio(PVE_DPS_FOLIO, "https://www.icy-veins.com/wow/unholy-death-knight-pve-dps-spec-builds-talents", "2026-08-10", "Current Patch 12.1 Unholy PvE Folio baseline."),
        pvp = Folio(PVP_DPS_FOLIO, "https://www.icy-veins.com/wow/unholy-death-knight-pvp-talents-and-builds", "2026-08-10", "Current Patch 12.1 Unholy PvP Folio baseline."),
    },
}

AdvisorData.freshness = {
    builds = { [250] = "current", [251] = "current", [252] = "current" },
    gear = { [250] = "current", [251] = "current", [252] = "current" },
}

DKM.AdvisorData = AdvisorData
