local ADDON_NAME, DKM = ...

local T = DKM.T or function(value) return value end

local ValeeraData = {
    patch = "12.1.0",
    season = T("Midnight Season 2"),
    reviewed = "2026-09-06",
    sourceName = "Icy Veins + Wowhead + Blizzard",
    sourceNote = T("Season 2 live guidance keeps Corrosive Bilespear + Soul-Cracking Dreamcatcher as the all-role Curio baseline. Blizzard has restored Valeera XP from Mislaid Curiosities; DK Mentor's Leveling preset uses Dundun's Favor for that farm."),

    liveHotfixes = {
        {
            date = "2026-09-04",
            label = T("Darkway curiosity spawn fixed"),
            text = T("Mislaid Curiosities now spawn correctly in The Darkway's Eggsplosive Growth variant, removing a blocker from the Valeera XP route."),
        },
        {
            date = "2026-09-01",
            label = T("Valeera XP restored"),
            text = T("Blizzard restored Valeera experience from Mislaid Curiosities. Dundun's Favor is useful again for companion leveling and curiosity farming."),
        },
        {
            date = "2026-08-18",
            label = T("Dundun group looting fixed"),
            text = T("Dundun's Favor no longer prevents multiple party members from looting the same Mislaid Curiosity."),
        },
        {
            date = "2026-08-17",
            label = T("Bilespear higher ranks fixed"),
            text = T("Corrosive Bilespear now procs correctly at higher ranks, reinforcing it as the current all-role Combat Curio baseline."),
        },
        {
            date = "2026-08-21",
            label = T("Poison cleanup fixed"),
            text = T("Frostheart Venom and Phantasmal Spore Toxin are now removed correctly when leaving a Delve."),
        },
    },

    presets = {
        auto = {
            label = T("Auto"),
            short = T("DK Mentor pick"),
            spellID = 1784, -- Stealth / Valeera flavor
        },
        safe = {
            label = T("Safe"),
            short = T("More sustain"),
            spellID = 48792, -- Icebound Fortitude
        },
        balanced = {
            label = T("Balanced"),
            short = T("Default mix"),
            spellID = 49998, -- Death Strike
        },
        fast = {
            label = T("Fast"),
            short = T("Faster clears"),
            spellID = 2983, -- Sprint
        },
        high = {
            label = T("High Tier"),
            short = T("Hard Delves / Nemesis"),
            spellID = 48707, -- Anti-Magic Shell
        },
        leveling = {
            label = T("Leveling"),
            short = T("Valeera XP farm"),
            spellID = 2983, -- Sprint
        },
    },

    presetOrder = { "auto", "safe", "balanced", "fast", "high", "leveling" },

    roles = {
        dps = {
            label = T("Damage Dealer"),
            short = T("DPS"),
            spellID = 196819, -- Eviscerate
            tooltipSpell = false,
            description = T("Maximizes Valeera's damage contribution. DK Mentor prefers this with Blood for normal farming because Blood already supplies tanking and self-sustain."),
        },
        healer = {
            label = T("Healer"),
            short = T("HEALER"),
            spellID = 185311, -- Crimson Vial
            tooltipSpell = false,
            description = T("Adds healing and defensive support while the DK keeps attacking. DK Mentor uses this as the default safety pairing for Frost and Unholy."),
        },
        tank = {
            label = T("Tank"),
            short = T("TANK"),
            spellID = 1966, -- Feint
            tooltipSpell = false,
            description = T("Lets Valeera hold the front line. Situational for DKs: useful if you specifically want an NPC tank, but not DK Mentor's normal default for Season 2."),
        },
    },

    roleOrder = { "dps", "healer", "tank" },

    combatCurios = {
        bilespear = {
            fallbackName = "Corrosive Bilespear",
            spellID = 1248877,
            tag = T("Guide baseline"),
            description = T("Strong direct damage Curio and the current general recommendation across Valeera roles. Blizzard fixed its higher-rank proc issue on August 17."),
        },
        essence = {
            fallbackName = "Essence Trap",
            spellID = 1288788,
            tag = T("Control"),
            description = T("Control-oriented alternative that slows and stuns enemies when traps trigger."),
        },
        ouroboric = {
            fallbackName = "Ouroboric Curse",
            spellID = 1248859,
            tag = T("Emergency"),
            description = T("Defensive emergency alternative for difficult runs when survival matters more than the default damage Curio."),
        },
    },

    combatOrder = { "bilespear", "essence", "ouroboric" },

    utilityCurios = {
        dreamcatcher = {
            fallbackName = "Soul-Cracking Dreamcatcher",
            spellID = 1248899,
            tag = T("Guide baseline"),
            description = T("Rewards interrupts and crowd control on Elite enemies, which pairs naturally with the DK control toolkit."),
        },
        dundun = {
            fallbackName = "Dundun's Favor",
            spellID = 1248894,
            tag = T("Leveling / farm"),
            description = T("Leveling and farm option: Mislaid Curiosities grant Valeera XP again, while Dundun's Favor helps collect them and fires Volatile Sprites."),
        },
        venom = {
            fallbackName = "Venom Infusion",
            spellID = 1305688,
            tag = T("Aggressive"),
            description = T("Aggressive movement and Haste-oriented alternative with a health tradeoff. Use deliberately rather than as the default."),
        },
    },

    utilityOrder = { "dreamcatcher", "dundun", "venom" },

    poisons = {
        bloodcrypt = {
            fallbackName = "Bloodcrypt Toxin",
            spellID = 1251111,
            tag = T("Defense"),
            description = T("Reduces enemy damage and Haste after your poisoned attacks connect. DK Mentor's safest general poison."),
        },
        forgotten = {
            fallbackName = "Poison of the Forgotten Master",
            spellID = 1248517,
            tag = T("Damage if untouched"),
            description = T("Builds a strong damage bonus while you avoid taking damage, but all stacks are lost when the wielder is hit."),
        },
        soulthirst = {
            fallbackName = "Soulthirst Venom",
            spellID = 1250808,
            tag = T("Sustain"),
            description = T("Adds Leech, Avoidance, and Speed. A simple comfort option when you want passive sustain and mobility."),
        },
        bursting = {
            fallbackName = "Bursting Toad Toxin",
            spellID = 1305904,
            tag = T("AoE damage"),
            description = T("Adds periodic poison bursts around enemies. DK Mentor uses it for faster general clearing."),
        },
        frostheart = {
            fallbackName = "Frostheart Venom",
            spellID = 1298137,
            tag = T("Control"),
            description = T("Slows movement and attack/cast speed, giving melee DKs more control over dangerous packs."),
        },
        phantasmal = {
            fallbackName = "Phantasmal Spore Toxin",
            spellID = 1298149,
            tag = T("Interrupt / fear"),
            description = T("Adds a short interrupt and fear proc. Useful when extra disruption is more valuable than raw damage or mitigation."),
        },
    },

    poisonOrder = { "bloodcrypt", "forgotten", "soulthirst", "bursting", "frostheart", "phantasmal" },

    recommendations = {
        [250] = { -- Blood
            auto = {
                role = "dps", combat = "bilespear", utility = "dreamcatcher", poison = "bursting",
                reason = T("Blood already tanks and self-heals extremely well, so Valeera can stay in DPS while Bursting Toad Toxin helps clear packs faster."),
            },
            safe = {
                role = "healer", combat = "bilespear", utility = "dreamcatcher", poison = "bloodcrypt",
                reason = T("Use Healer Valeera plus Bloodcrypt when a Delve is actually threatening your survival or you are learning a difficult mechanic."),
            },
            balanced = {
                role = "dps", combat = "bilespear", utility = "dreamcatcher", poison = "bursting",
                reason = T("Balanced Blood keeps Valeera in DPS: you supply the tanking, she supplies extra damage, and Dreamcatcher rewards your frequent DK control."),
            },
            fast = {
                role = "dps", combat = "bilespear", utility = "dreamcatcher", poison = "bursting",
                reason = T("Speed-farm setup: maximize Valeera damage and add AoE poison pressure while Blood handles the incoming damage."),
            },
            high = {
                role = "dps", combat = "bilespear", utility = "dreamcatcher", poison = "bloodcrypt",
                reason = T("For high-tier Blood, keep Valeera in DPS but switch to Bloodcrypt for a meaningful defensive layer on enemies you are actively hitting."),
            },
            leveling = {
                role = "dps", combat = "bilespear", utility = "dundun", poison = "soulthirst",
                reason = T("Valeera leveling preset: Blood handles combat safely while Dundun's Favor turns Mislaid Curiosities into an efficient XP route again; Soulthirst adds movement speed and passive sustain."),
            },
        },
        [251] = { -- Frost
            auto = {
                role = "healer", combat = "bilespear", utility = "dreamcatcher", poison = "frostheart",
                reason = T("Frost gains a comfortable solo pairing from Healer Valeera. Frostheart adds control while you stay aggressive in melee."),
            },
            safe = {
                role = "healer", combat = "bilespear", utility = "dreamcatcher", poison = "bloodcrypt",
                reason = T("Safest Frost setup: Healer Valeera plus Bloodcrypt lowers incoming pressure while you keep Runic Power available for emergency Death Strikes."),
            },
            balanced = {
                role = "healer", combat = "bilespear", utility = "dreamcatcher", poison = "frostheart",
                reason = T("Balanced Frost uses Healer Valeera and Frostheart control, leaving you free to focus on Obliterate/Frostscythe pressure and interrupts."),
            },
            fast = {
                role = "dps", combat = "bilespear", utility = "dreamcatcher", poison = "bursting",
                reason = T("When the Delve is easy, switch Valeera to DPS and Bursting Toad Toxin to shorten pulls and move faster between packs."),
            },
            high = {
                role = "healer", combat = "bilespear", utility = "dreamcatcher", poison = "bloodcrypt",
                reason = T("High-tier Frost favors consistency: Healer Valeera and Bloodcrypt smooth damage intake while Dreamcatcher turns your interrupts and control into extra Elite damage."),
            },
            leveling = {
                role = "healer", combat = "bilespear", utility = "dundun", poison = "soulthirst",
                reason = T("Valeera leveling preset: keep Healer support for comfortable pulls, use Dundun's Favor for Mislaid Curiosity XP, and Soulthirst for extra speed while moving between curiosities."),
            },
        },
        [252] = { -- Unholy
            auto = {
                role = "healer", combat = "bilespear", utility = "dreamcatcher", poison = "bloodcrypt",
                reason = T("Unholy can keep its damage engine rolling while Healer Valeera and Bloodcrypt reduce the punishment from extended melee pulls."),
            },
            safe = {
                role = "healer", combat = "bilespear", utility = "dreamcatcher", poison = "bloodcrypt",
                reason = T("Safe Unholy keeps Valeera healing and uses Bloodcrypt to lower enemy damage and Haste during longer or more dangerous fights."),
            },
            balanced = {
                role = "healer", combat = "bilespear", utility = "dreamcatcher", poison = "bloodcrypt",
                reason = T("Balanced Unholy prioritizes steady uptime: your pets and diseases provide pressure while Valeera stabilizes you and Dreamcatcher rewards DK crowd control."),
            },
            fast = {
                role = "dps", combat = "bilespear", utility = "dreamcatcher", poison = "bursting",
                reason = T("For easy farming, DPS Valeera plus Bursting Toad Toxin adds more pack damage while Unholy spreads its normal AoE pressure."),
            },
            high = {
                role = "healer", combat = "bilespear", utility = "dreamcatcher", poison = "bloodcrypt",
                reason = T("High-tier Unholy keeps the safer Healer + Bloodcrypt pairing so you can preserve offensive momentum without overusing Death Strike."),
            },
            leveling = {
                role = "healer", combat = "bilespear", utility = "dundun", poison = "soulthirst",
                reason = T("Valeera leveling preset: Healer support keeps Unholy moving, Dundun's Favor benefits the restored Mislaid Curiosity XP route, and Soulthirst adds speed and sustain."),
            },
        },
    },
}

DKM.ValeeraData = ValeeraData
