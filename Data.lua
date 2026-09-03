local ADDON_NAME, DKM = ...

DKM.Data = DKM.Data or {}
local Data = DKM.Data
local T = DKM.T or function(value) return value end

Data.addonName = ADDON_NAME
Data.version = "3.1.6"
Data.interface = 120100
Data.dataVersion = "2026-09-03"
Data.patch = "12.1.0"

Data.specNames = {
    [250] = "Blood",
    [251] = "Frost",
    [252] = "Unholy",
}

Data.contextOrder = { "world", "delve", "dungeon", "mythicplus", "raid", "pvp" }
Data.contextNames = {
    auto = "Auto",
    world = "World",
    delve = "Delve",
    dungeon = "Dungeon",
    mythicplus = "Mythic+",
    raid = "Raid",
    pvp = "PvP",
}

-- Permanent Death Knight Runeforge enchant IDs used by Retail.
-- These are read only from the player's own equipped weapon item links.
Data.runeforges = {
    [3368] = { spellID = 53344, fallbackName = T("Rune of the Fallen Crusader") },
    [3370] = { spellID = 53343, fallbackName = T("Rune of Razorice") },
    [3847] = { spellID = 62158, fallbackName = T("Rune of the Stoneskin Gargoyle") },
    [6241] = { spellID = 326805, fallbackName = T("Rune of Sanguination") },
    [6242] = { spellID = 326855, fallbackName = T("Rune of Spellwarding") },
    [6243] = { spellID = 326911, fallbackName = T("Rune of Hysteria") },
    [6244] = { spellID = 326977, fallbackName = T("Rune of Unending Thirst") },
    [6245] = { spellID = 327082, fallbackName = T("Rune of the Apocalypse") },
}

-- Midnight 12.1 uses a new Raise Dead spell ID, while older clients/builds
-- can still expose the legacy ID. The Ghoul Guard checks both safely.
Data.raiseDeadSpellIDs = { 1242866, 46584 }

Data.spells = {
    DEATH_STRIKE = 49998,
    ANTI_MAGIC_SHELL = 48707,
    ICEBOUND_FORTITUDE = 48792,
    DEATH_PACT = 48743,
    ANTI_MAGIC_ZONE = 51052,
    DEATHS_ADVANCE = 48265,
    LICHBORNE = 49039,
    MIND_FREEZE = 47528,
    ASPHYXIATE = 221562,
    BLINDING_SLEET = 207167,
    DEATH_GRIP = 49576,
    CHAINS_OF_ICE = 45524,
    RAISE_ALLY = 61999,
    VAMPIRIC_BLOOD = 55233,
    DANCING_RUNE_WEAPON = 49028,
    RUNE_TAP = 194679,
    MARROWREND = 195182,
    DEATH_AND_DECAY = 43265,
    GOREFIENDS_GRASP = 108199,
    BONE_SHIELD = 195181,
    COAGULATING_BLOOD = 463730,
    BLOOD_BOIL = 50842,
    HEART_STRIKE = 206930,
    OBLITERATE = 49020,
    FROSTSCYTHE = 207230,
    HOWLING_BLAST = 49184,
    FROST_STRIKE = 49143,
    FESTERING_STRIKE = 85948,
    SCOURGE_STRIKE = 55090,
    FESTERING_WOUND = 194310,
    OUTBREAK = 77575,
    VIRULENT_PLAGUE = 191587,
    DEATH_COIL = 47541,
    EPIDEMIC = 207317,
    LESSER_GHOUL = 1254252,
    DARK_TRANSFORMATION = 1233448,
    PUTREFY = 1247378,
    DREAD_PLAGUE = 1240996,
}

local S = Data.spells

local function Tip(spellID, tag, text, optional, fallbackName)
    return {
        spellID = spellID,
        tag = tag,
        text = text,
        optional = optional == true,
        fallbackName = fallbackName,
    }
end

Data.tips = {
    general = {
        world = {
            Tip(S.DEATH_STRIKE, "HEAL", "Use after meaningful damage. Avoid spending all Runic Power when a dangerous fight is about to begin."),
            Tip(S.ANTI_MAGIC_SHELL, "MAGIC", "Use shortly before predictable magic damage, a magic debuff, or magic crowd control."),
            Tip(S.ICEBOUND_FORTITUDE, "EMERGENCY", "Use against very high damage, during a dangerous stun, or when remaining exposed would be lethal."),
            Tip(S.DEATH_PACT, "STRONG HEAL", "Emergency healing when Death Strike will not be enough.", true),
            Tip(S.MIND_FREEZE, "INTERRUPT", "Stopping a dangerous cast is usually better than taking the damage and spending a defensive cooldown."),
            Tip(S.BLINDING_SLEET, "CONTROL", "Stop several enemies or a cast when your interrupt is unavailable.", true),
        },
        delve = {
            Tip(S.DEATH_STRIKE, "HEAL", "Use after a heavy hit and preserve Runic Power before elites or large groups."),
            Tip(S.ANTI_MAGIC_SHELL, "MAGIC", "Anticipate bursts and magic effects. Using it before the effect is usually more valuable than using it afterward."),
            Tip(S.ICEBOUND_FORTITUDE, "EMERGENCY", "Use on large pulls, during dangerous stuns, or when your companion cannot stabilize the fight."),
            Tip(S.DEATH_PACT, "PANIC BUTTON", "A final healing option to survive until the next Death Strike.", true),
            Tip(S.MIND_FREEZE, "INTERRUPT", "Prioritize enemy heals, crowd control, and high-damage casts."),
            Tip(S.DEATHS_ADVANCE, "POSITION", "Use against knockbacks, pulls, and slows, or to leave a dangerous area safely."),
        },
        dungeon = {
            Tip(S.MIND_FREEZE, "INTERRUPT", "Stop the priority cast. Preventing damage reduces pressure on the healer."),
            Tip(S.ANTI_MAGIC_SHELL, "PERSONAL", "Use before a targeted magic mechanic or a preventable magic debuff."),
            Tip(S.ANTI_MAGIC_ZONE, "GROUP", "Use when several party members will take magic damage at the same time.", true),
            Tip(S.ICEBOUND_FORTITUDE, "EMERGENCY", "Use during focused damage, a dangerous stun, or when the healer is under pressure."),
            Tip(S.DEATH_STRIKE, "RECOVER", "Use after the damage spike. Avoid compromising your rotation when healing is not needed."),
            Tip(S.BLINDING_SLEET, "STOP PACK", "Interrupt several enemy actions when Mind Freeze is on cooldown.", true),
        },
        raid = {
            Tip(S.ANTI_MAGIC_SHELL, "MECHANIC", "Use before predictable magic damage or when the shield can prevent a debuff."),
            Tip(S.ANTI_MAGIC_ZONE, "RAID", "Place it on the group before a major source of magic damage.", true),
            Tip(S.ICEBOUND_FORTITUDE, "EMERGENCY", "Reserve it for a dangerous overlap, a stun, or potentially lethal damage."),
            Tip(S.DEATH_STRIKE, "SELF-HEAL", "Recover after a spike to reduce pressure on healers."),
            Tip(S.DEATHS_ADVANCE, "MOVEMENT", "Use to resist forced movement or cross a movement window safely."),
            Tip(S.RAISE_ALLY, "UTILITY", "Use combat resurrection only when the group call justifies spending the charge."),
        },
        pvp = {
            Tip(S.ANTI_MAGIC_SHELL, "MAGIC / CC", "Use before incoming magic crowd control or a caster burst window, not after the control has landed."),
            Tip(S.ICEBOUND_FORTITUDE, "STUN / BURST", "Use during a dangerous stun or the enemy team's highest pressure window."),
            Tip(S.DEATH_STRIKE, "SUSTAIN", "Use after heavy damage. Preserve Runic Power when you are likely to be the next target."),
            Tip(S.DEATH_PACT, "PANIC BUTTON", "Use when you are in real danger and the next Death Strike will not arrive in time.", true),
            Tip(S.LICHBORNE, "CONTROL", "Use according to the selected talent to deny the appropriate crowd-control effects.", true),
            Tip(S.CHAINS_OF_ICE, "SURVIVE", "Reduce pressure by creating distance. Combine with Death Grip to protect yourself or an ally."),
        },
    },
    [250] = {
        world = {
            Tip(S.MARROWREND, "PREPARE", "Enter combat with Bone Shield and refresh it before the stacks are exhausted."),
            Tip(S.DEATH_STRIKE, "CORE", "Use after damage instead of merely because it is available. It is your primary active recovery tool."),
            Tip(S.RUNE_TAP, "BEFORE", "Use before a heavy hit or before taking damage from several enemies.", true),
            Tip(S.VAMPIRIC_BLOOD, "HEALTH / HEAL", "Activate before a dangerous window or to amplify recovery when your health begins to fall."),
            Tip(S.DANCING_RUNE_WEAPON, "LARGE PACK", "Use early in a dangerous pull to gain control and stability."),
            Tip(S.ANTI_MAGIC_SHELL, "MAGIC", "Anticipate important magic damage and magic effects."),
        },
        delve = {
            Tip(S.MARROWREND, "BONE SHIELD", "Maintain stacks before engaging elites and large groups."),
            Tip(S.DEATH_STRIKE, "AFTER DAMAGE", "Wait for the damage spike and convert Runic Power into recovery."),
            Tip(S.RUNE_TAP, "BEFORE DAMAGE", "Reduce a telegraphed hit or the opening damage of a large pull.", true),
            Tip(S.DANCING_RUNE_WEAPON, "OPEN PACK", "Use early in dangerous encounters. Holding it until you are almost dead wastes much of its value."),
            Tip(S.VAMPIRIC_BLOOD, "EMERGENCY", "Use before or during a window that will require several consecutive heals."),
            Tip(S.ANTI_MAGIC_SHELL, "MAGIC", "Protect yourself from predictable bursts, debuffs, and magic crowd control."),
        },
        dungeon = {
            Tip(S.MARROWREND, "BONE SHIELD", "Do not begin an important pull unprepared. Keep your stacks stable."),
            Tip(S.DEATH_STRIKE, "AFTER THE HIT", "Absorb the hit, then recover at the correct moment."),
            Tip(S.RUNE_TAP, "TANK BUSTER", "Use before predictable physical damage or when entering a large pack.", true),
            Tip(S.DANCING_RUNE_WEAPON, "HARD PULL", "Use at the beginning of pulls that truly threaten you, not as a late panic button."),
            Tip(S.VAMPIRIC_BLOOD, "AMPLIFY", "Use when sustained damage will require more maximum health and stronger incoming healing."),
            Tip(S.ANTI_MAGIC_ZONE, "GROUP", "Help the group during shared magic damage when positioning allows it.", true),
        },
        raid = {
            Tip(S.MARROWREND, "BONE SHIELD", "Maintain mitigation before taking the boss or performing a tank swap."),
            Tip(S.DEATH_STRIKE, "RECOVER", "Use after the heavy attack and plan Runic Power for each boss hit."),
            Tip(S.RUNE_TAP, "BEFORE", "Reduce a predictable tank buster before it lands.", true),
            Tip(S.VAMPIRIC_BLOOD, "PLANNED", "Pair it with a known hit or damage sequence instead of waiting only for low health."),
            Tip(S.DANCING_RUNE_WEAPON, "STRONG WINDOW", "Use as a planned cooldown for tank damage and offensive generation."),
            Tip(S.ANTI_MAGIC_SHELL, "MAGIC", "Anticipate magic damage and effects that can be absorbed."),
        },
        pvp = {
            Tip(S.DEATH_STRIKE, "SUSTAIN", "Preserve Runic Power and use it after the enemy damage window."),
            Tip(S.ANTI_MAGIC_SHELL, "MAGIC / CC", "Use before magic crowd control and burst."),
            Tip(S.ICEBOUND_FORTITUDE, "STUN / BURST", "Use during the largest pressure window or a dangerous stun."),
            Tip(S.VAMPIRIC_BLOOD, "AMPLIFY", "Buy time for several heals and support from your group."),
            Tip(S.DEATH_PACT, "PANIC BUTTON", "Use as a last resort when normal recovery will not arrive in time.", true),
            Tip(S.CHAINS_OF_ICE, "CONTROL", "Reduce pressure on yourself or an ally by limiting enemy mobility."),
        },
    },
}

local function Coach(spellID, title, when, optional, fallbackName)
    return {
        spellID = spellID,
        title = title,
        when = when,
        optional = optional == true,
        fallbackName = fallbackName,
    }
end

Data.coach = {
    general = {
        world = {
            Coach(S.DEATH_STRIKE, "RECOVER", "after damage"),
            Coach(S.ANTI_MAGIC_SHELL, "MAGIC", "before the effect"),
            Coach(S.ICEBOUND_FORTITUDE, "EMERGENCY", "burst / stun"),
        },
        delve = {
            Coach(S.DEATH_STRIKE, "HEAL", "after the hit"),
            Coach(S.ANTI_MAGIC_SHELL, "MAGIC", "before the burst"),
            Coach(S.ICEBOUND_FORTITUDE, "EMERGENCY", "large pack / stun"),
        },
        dungeon = {
            Coach(S.MIND_FREEZE, "PREVENT", "interrupt first"),
            Coach(S.ANTI_MAGIC_SHELL, "PERSONAL", "magic on you"),
            Coach(S.DEATH_STRIKE, "RECOVER", "after the spike"),
        },
        raid = {
            Coach(S.ANTI_MAGIC_SHELL, "PERSONAL", "before mechanic"),
            Coach(S.ANTI_MAGIC_ZONE, "GROUP", "magic damage", true),
            Coach(S.ICEBOUND_FORTITUDE, "EMERGENCY", "lethal overlap"),
        },
        pvp = {
            Coach(S.ANTI_MAGIC_SHELL, "CC / MAGIC", "use before"),
            Coach(S.ICEBOUND_FORTITUDE, "STUN / BURST", "use at peak"),
            Coach(S.DEATH_STRIKE, "SUSTAIN", "after damage"),
        },
    },
    [250] = {
        world = {
            Coach(S.RUNE_TAP, "MITIGATE", "before the hit", true),
            Coach(S.VAMPIRIC_BLOOD, "MAX HEALTH", "dangerous window"),
            Coach(S.DEATH_STRIKE, "RECOVER", "after damage"),
        },
        delve = {
            Coach(S.DANCING_RUNE_WEAPON, "OPEN PACK", "use early"),
            Coach(S.VAMPIRIC_BLOOD, "DANGER", "amplify healing"),
            Coach(S.DEATH_STRIKE, "RECOVER", "after the hit"),
        },
        dungeon = {
            Coach(S.RUNE_TAP, "BEFORE", "tank buster", true),
            Coach(S.VAMPIRIC_BLOOD, "SEQUENCE", "sustained damage"),
            Coach(S.DEATH_STRIKE, "AFTER", "recover the hit"),
        },
        raid = {
            Coach(S.RUNE_TAP, "BEFORE", "predicted hit", true),
            Coach(S.VAMPIRIC_BLOOD, "PLAN", "strong window"),
            Coach(S.DEATH_STRIKE, "AFTER", "recover the hit"),
        },
        pvp = {
            Coach(S.ANTI_MAGIC_SHELL, "CC / MAGIC", "use before"),
            Coach(S.ICEBOUND_FORTITUDE, "STUN / BURST", "use at peak"),
            Coach(S.DEATH_STRIKE, "SUSTAIN", "preserve resource"),
        },
    },
}

-- Compact HUD tracking lists. Spell names and icons come from the game client,
-- so they automatically follow the player's WoW language. Unknown or
-- untalented spells are hidden from the bars.
-- Combat-safe fallback rules for buffs that are triggered by player casts.
-- Midnight can hide exact aura identity/state from third-party addons in combat.
-- These rules keep the visual tracker responsive using safe player spell events;
-- direct aura data and Blizzard Cooldown Viewer mirrors remain authoritative when
-- they are available.
-- Some class abilities have received new spell IDs in Midnight while older
-- IDs still resolve as base/legacy spell references. Track the current aura IDs
-- as aliases, but keep one canonical slot so the HUD layout stays stable.
Data.buffAuraAliases = {
    [152279] = { 1249658 }, -- Breath of Sindragosa: current 12.1 spell/aura ID
    [1229310] = { 1229311 }, -- Frostbane proc aura variants in 12.1
    [434157] = { 434159, 461130 }, -- Visceral Strength: Unholy/Blood active aura variants
    [1233448] = { 63560 }, -- Dark Transformation: Midnight current / legacy reference
}

-- Curated Cooldown Manager profile IDs from the current Midnight 12.1
-- Wowhead imports. These are cooldown IDs (NOT spell IDs). DK Mentor never
-- imports or changes the player's Blizzard layout; it only uses these IDs as
-- a read-only allow-list against Blizzard's already-materialized CDM data.
-- Category names mirror the player-facing Cooldown Manager concepts.
Data.cooldownManagerProfiles = {
    [250] = { -- Blood: Luxthos + Wowhead Quick Start
        trackedBuffCooldownIDs = { 90603, 90611, 90606, 90610, 50002, 9039 },
        trackedBarCooldownIDs = { 92535, 92533 },
        essentialCooldownIDs = { 5868 },
    },
    [251] = { -- Frost: Wowhead Max Buff Tracking + Khazak tracked bar complement
        trackedBuffCooldownIDs = {
            92575, 86579, 92577, 86281, 50939, 27652, 86136,
            105181, 86538, 140055, 99984, 86099, 92573, 27648,
        },
        trackedBarCooldownIDs = { 104640 },
    },
    [252] = { -- Unholy: Taeznak + Luxthos essential complement
        trackedBuffCooldownIDs = { 90617 },
        trackedBarCooldownIDs = { 92923, 70805, 70806, 103071, 70807 },
        essentialCooldownIDs = { 70761 },
    },
}

-- Blizzard proc-glow events report the action that should light up, not always
-- the underlying aura that caused it. Map the action back to the high-value
-- rotational state so DK Mentor can show the proc rather than a duplicate
-- ability icon. These are visual-only mappings; no action is ever executed.
-- Mythic+ uses the dungeon survival guidance unless a spec receives a dedicated
-- Mythic+ set later. Loadout mappings themselves remain fully independent.
for _, contextTips in pairs(Data.tips or {}) do
    if type(contextTips) == "table" and contextTips.dungeon and not contextTips.mythicplus then
        contextTips.mythicplus = contextTips.dungeon
    end
end

Data.procGlowMappings = {
    [250] = {
        [43265] = 81141,   -- Death and Decay -> Crimson Scourge
        [50842] = 1265790, -- Blood Boil -> Boiling Point
        [206930] = 433895, -- Heart Strike -> Vampiric Strike availability
    },
    [251] = {
        [49020] = 51124,    -- Obliterate -> Killing Machine
        [207230] = 51124,   -- Frostscythe -> Killing Machine
        [49184] = 59052,    -- Howling Blast -> Rime
        [49143] = 1229310,  -- Frost Strike proc glow/override -> Frostbane
        [1228433] = 1229310,
        [1228436] = 1229310,
        [1228443] = 1229310,
    },
    [252] = {
        [47541] = 81340,   -- Death Coil -> Sudden Doom
        [207317] = 81340,  -- Epidemic -> Sudden Doom
    },
}

Data.buffRuntimeRules = {
    [S.ANTI_MAGIC_SHELL] = { buffSpellID = S.ANTI_MAGIC_SHELL, duration = 5 },
    [S.ICEBOUND_FORTITUDE] = { buffSpellID = S.ICEBOUND_FORTITUDE, duration = 8 },
    [S.DEATHS_ADVANCE] = { buffSpellID = S.DEATHS_ADVANCE, duration = 10 },
    [S.LICHBORNE] = { buffSpellID = S.LICHBORNE, duration = 10 },

    [S.VAMPIRIC_BLOOD] = { buffSpellID = S.VAMPIRIC_BLOOD, duration = 10 },
    [S.DANCING_RUNE_WEAPON] = { buffSpellID = 81256, duration = 8 },
    [S.MARROWREND] = { buffSpellID = 195181, duration = 30 },
    [195292] = { buffSpellID = 195181, duration = 30 }, -- Death's Caress

    [51271] = { buffSpellID = 51271, duration = 12 }, -- Pillar of Frost
    [152279] = { buffSpellID = 152279, duration = 8 },
    [1249658] = { buffSpellID = 152279, duration = 8 },

    [1233448] = { buffSpellID = 1233448, duration = 15 }, -- Dark Transformation (Midnight)
    [63560] = { buffSpellID = 1233448, duration = 15 }, -- legacy/reference fallback
}

-- Fallback spell IDs are intentionally curated around rotationally meaningful
-- Midnight 12.1 states. The Cooldown Manager profile resolver below augments
-- these dynamically with Blizzard's own linked/override spell data.
Data.buffTracking = {
    general = {
        53365,  -- Unholy Strength (Fallen Crusader runeforge proc)
        101568, -- Dark Succor proc
        S.ANTI_MAGIC_SHELL,
        S.ICEBOUND_FORTITUDE,
        S.DEATHS_ADVANCE,
        S.LICHBORNE,
    },
    [250] = {
        195181,  -- Bone Shield
        463730,  -- Coagulating Blood (Death Strike recent-damage pool)
        81141,   -- Crimson Scourge
        273947,  -- Hemostasis
        1265790, -- Boiling Point
        433895,  -- Vampiric Strike availability
        433925,  -- Essence of the Blood Queen
        434157,  -- Visceral Strength (aliases resolve Blood/Unholy aura variants)
        1310372, -- Blood Debt (Midnight Season 2 set; stacks to 10)
        1300369, -- Relentless Rider's Strength (10-sec Blood Debt payoff)
        S.VAMPIRIC_BLOOD,
        81256,   -- Dancing Rune Weapon aura
    },
    [251] = {
        51124,   -- Killing Machine
        59052,   -- Rime
        1229310, -- Frostbane
        1297365, -- Freezing Tempest
        194879,  -- Icy Talons
        377101,  -- Bonegrinder stacks
        377103,  -- Bonegrinder damage window
        1230916, -- Killing Streak
        1265630, -- Chosen of Frostbrood Haste window
        1265639, -- Chosen of Frostbrood recall window
        51271,   -- Pillar of Frost
        152279,  -- Breath of Sindragosa canonical slot
    },
    [252] = {
        81340,   -- Sudden Doom
        1254252, -- Lesser Ghoul ready stack
        51460,   -- Runic Corruption
        194879,  -- Icy Talons (important Unholy attack-speed maintenance buff)
        1242223, -- Forbidden Knowledge window
        433895,  -- Vampiric Strike availability (San'layn)
        433925,  -- Essence of the Blood Queen
        434157,  -- Visceral Strength
        1233448, -- Dark Transformation (Midnight)
    },
}

Data.abilityTracking = {
    general = {
        S.DEATH_STRIKE,
        S.MIND_FREEZE,
        S.DEATH_GRIP,
        S.ANTI_MAGIC_SHELL,
        S.ICEBOUND_FORTITUDE,
        S.DEATHS_ADVANCE,
        S.DEATH_PACT,
    },
    [250] = {
        S.VAMPIRIC_BLOOD,
        S.DANCING_RUNE_WEAPON,
        439843, -- Reaper's Mark (Deathbringer)
        S.RUNE_TAP,
        S.GOREFIENDS_GRASP,
    },
    [251] = {
        51271,   -- Pillar of Frost
        47568,   -- Empower Rune Weapon
        196770,  -- Remorseless Winter
        279302,  -- Frostwyrm's Fury
        439843,  -- Reaper's Mark (Deathbringer)
        1249658, -- Breath of Sindragosa (Midnight current)
    },
    [252] = {
        1233448, -- Dark Transformation (Midnight current)
        1247378, -- Putrefy
        42650,   -- Army of the Dead
        343294,  -- Soul Reaper
        46585,   -- Raise Dead
    },
}

-- Blizzard Assisted Combat can briefly expose stale or cross-spec entries while
-- the spellbook/talent state is refreshing. Keep explicit Midnight spec ownership
-- for abilities that must never be required by another specialization.
Data.assistedCombatSpecRestrictions = {
    [343294] = 252, -- Soul Reaper: Unholy-only in Midnight 12.1.
}

