local ADDON_NAME, DKM = ...

-- DK Mentor Gear Mentor data.
-- This module intentionally stores guidance rather than simulated DPS values.
-- The player-facing renderer resolves item names from the WoW client when
-- possible, so localized clients can use localized item names. Priority labels
-- describe farming value only and are never presented as a guaranteed upgrade.

local GearData = {
    patch = "12.1.0",
    season = "Midnight Season 2",
    reviewed = "2026-09-08",
    sourceName = "Wowhead",
    sourceNote = "Guide-backed targets are a farming reference, not a replacement for simming your character.",
    specs = {},
}

local function Target(itemID, fallbackName, slot, source, priority, reason)
    return {
        itemID = itemID,
        fallbackName = fallbackName,
        slot = slot,
        source = source,
        priority = priority,
        reason = reason,
    }
end

local function CraftTarget(itemID, fallbackName, slot, priority, embellishment, reason)
    return {
        itemID = itemID,
        fallbackName = fallbackName,
        slot = slot,
        source = "Crafting",
        priority = priority,
        embellishment = embellishment,
        reason = reason,
        craft = true,
    }
end

GearData.tierSet = {
    setID = 2055,
    fallbackName = "Baleful Grave-Knight's Crucible",
    sourceURL = "https://www.wowhead.com/item-set=2055/baleful-grave-knights-crucible",
    pieces = {
        { itemID = 271474, fallbackName = "Baleful Grave-Knight's Casque", slot = "Head", inventorySlot = 1 },
        { itemID = 271472, fallbackName = "Baleful Grave-Knight's Gibbets", slot = "Shoulders", inventorySlot = 3 },
        { itemID = 271477, fallbackName = "Baleful Grave-Knight's Breastplate", slot = "Chest", inventorySlot = 5 },
        { itemID = 271475, fallbackName = "Baleful Grave-Knight's Deathgrips", slot = "Hands", inventorySlot = 10 },
        { itemID = 271473, fallbackName = "Baleful Grave-Knight's Greaves", slot = "Legs", inventorySlot = 7 },
    },
    bonuses = {
        [250] = {
            twoPiece = "Death Strike builds Blood Debt. At 10 stacks, Marrowrend converts it into a strong Strength window.",
            fourPiece = "Consuming Blood Debt empowers Marrowrend, adds Bone Shield charges, and deals heavy nearby Shadow damage.",
        },
        [251] = {
            twoPiece = "Remorseless Winter builds Freezing Tempest, increasing attack speed and Icy Death Torrent damage.",
            fourPiece = "Remorseless Winter deals damage more frequently and Freezing Tempest lasts longer.",
        },
        [252] = {
            twoPiece = "Magus of the Dead and Lord of the Dead replace their basic bolts with Necrotic Bolt and Withering Grasp.",
            fourPiece = "Necrotic Bolt and Withering Grasp deal substantially more damage to enemies below 35% health.",
        },
    },
}

GearData.specs[250] = {
    sourceURL = "https://www.wowhead.com/guide/classes/death-knight/blood/bis-gear",
    sourceUpdated = "2026-08-20",
    summary = "Blood gearing should protect the tanking loop first: weapon value, strong trinkets, useful cantrip pieces, and clean setup hygiene matter more than chasing a universal secondary-stat score.",
    weaponNote = "Blood normally plans around a two-handed Strength weapon. Maze-roa is a headline Season 2 target; a crafted weapon is a fallback when your current weapon is far behind.",
    targets = {
        Target(268213, "Maze-roa, Warlord's Fury", "Weapon", "Coiled Altar - Venomous Abyss", "VERY HIGH", "Headline cantrip weapon and one of the most valuable Blood targets this season."),
        Target(270175, "Voracious Heart of Ula'tek", "Trinket", "Ula'tek - Venomous Abyss", "VERY HIGH", "High-item-level on-use trinket that lines up well with major Blood damage windows."),
        Target(270173, "Zul'jin's Guillotine Technique", "Trinket", "Coiled Altar - Venomous Abyss", "VERY HIGH", "Strong passive trinket; gains extra value when paired with the Zul'jan weapon set."),
        Target(268265, "Aqirbane Reliquary", "Neck", "Ula'tek - Venomous Abyss", "HIGH", "Cantrip neck with a socket and unusual secondary-stat effect; especially attractive from high tracks."),
        Target(271878, "Chausses of Unbound Rancor", "Legs", "Ula'tek - Venomous Abyss", "HIGH", "High-item-level cantrip legs and a strong long-term raid target."),
    },
    trinkets = {
        "Preferred offensive pair: Voracious Heart of Ula'tek + Zul'jin's Guillotine Technique when using Maze-roa.",
        "Merektha's Fang is a notable damage alternative, especially when its channel is practical for the encounter.",
        "Defensive trinkets are situational tools, not the default answer; use them when they solve a real survival requirement.",
    },
    crafting = {
        "Spellbreaker's Bracers with Arcanoweave Lining are a strong stable craft.",
        "For single target, Masterwork Sin'dorei Band with Prismatic Focusing Iris can be attractive; for Mythic+, a second Arcanoweave Lining on Spellbreaker's March is a practical direction.",
        "If your weapon is significantly behind and Maze-roa is not realistically obtainable yet, a crafted two-handed weapon can be a temporary high-value step.",
    },
    craftTargets = {
        CraftTarget(237846, "Blood Knight's Warblade", "Weapon", "VERY HIGH", "Hunter's Ritual Stone / Darkmoon Sigil: Hunt", "Early-season weapon bridge when Maze-roa is not realistically obtainable yet and your current weapon is significantly behind; current guidance treats either embellishment as a viable option."),
        CraftTarget(237834, "Spellbreaker's Bracers", "Wrist", "VERY HIGH", "Arcanoweave Lining", "A strong long-term crafted slot for Blood once the urgent weapon question is solved."),
        CraftTarget(240949, "Masterwork Sin'dorei Band", "Finger", "HIGH", "Prismatic Focusing Iris", "Strong single-target crafted ring option when it fits your current gear and embellishment plan."),
        CraftTarget(237828, "Spellbreaker's March", "Feet", "HIGH", "Arcanoweave Lining", "Practical Mythic+ or alternative crafted slot when boots are a better upgrade than the ring."),
    },
    catalyst = {
        { slot = "Head", source = "Nek'zali the Soulcoiler" },
        { slot = "Shoulders", source = "Temple of Sethraliss" },
        { slot = "Chest", source = "The Coiled Altar" },
        { slot = "Hands", source = "King's Rest" },
        { slot = "Legs", source = "Ula'tek" },
    },
    upgrades = {
        "General Crest priority: Weapon > Trinkets > Head/Chest/Legs > Shoulders/Gloves/Belt/Boots.",
        "Do not spend limited high-tier Crests blindly on a slot you expect to replace immediately from raid, Vault, or a targeted Voidcore.",
        "Get the 4-piece tier bonus early; Midnight Season 2 Catalyst behavior gives more flexibility in which underlying secondary stats you keep.",
    },
}

GearData.specs[251] = {
    sourceURL = "https://www.wowhead.com/guide/classes/death-knight/frost/bis-gear",
    sourceUpdated = "2026-09-02",
    summary = "Frost currently rewards dual-wield weapon quality, a strong active/passive trinket pairing, and high-value Venomous Abyss cantrip pieces. Close upgrades should still be simulated.",
    weaponNote = "Dual-wield is the current Season 2 baseline. Blizzard's current item restriction keeps Aman'muso Main Hand-only, so DK Mentor preserves Aman'muso in the main hand with Jaw of the Shackled Goddess in the off hand even if a guide table labels the slots inconsistently. Two-handed remains playable, but the current Season 2 PvE gearing baseline favors dual-wield.",
    targets = {
        Target(268209, "Aman'muso, Warlord's Vengeance", "Main Hand", "Coiled Altar - Venomous Abyss", "VERY HIGH", "Main Hand-only cantrip weapon under Blizzard's current item restriction; DK Mentor keeps the slot assignment authoritative even if a guide table is inconsistent."),
        Target(268202, "Jaw of the Shackled Goddess", "Off Hand", "Ula'tek - Venomous Abyss", "VERY HIGH", "High-value one-handed weapon used in the off hand alongside Aman'muso in the current practical dual-wield pairing."),
        Target(270175, "Voracious Heart of Ula'tek", "Trinket", "Ula'tek - Venomous Abyss", "VERY HIGH", "Best-in-class on-use target for current Frost burst timings according to current guide guidance."),
        Target(270173, "Zul'jin's Guillotine Technique", "Trinket", "Coiled Altar - Venomous Abyss", "VERY HIGH", "Headline passive trinket and a natural pairing with Aman'muso."),
        Target(268265, "Aqirbane Reliquary", "Neck", "Ula'tek - Venomous Abyss", "HIGH", "High-item-level cantrip neck with a socket and a flexible secondary-stat effect."),
    },
    trinkets = {
        "Preferred pair: Voracious Heart of Ula'tek (active) + Zul'jin's Guillotine Technique (passive).",
        "Seed of the Devouring Wild is a reasonable active fallback; Gebbo's Bottomless Bag is a practical passive fallback.",
        "Frost burst timings make active-trinket alignment important, so compare cooldown alignment as well as raw item level.",
    },
    crafting = {
        "Early season: craft Spellbreaker's Blade if your one-handed weapons are far behind; Hunter's Ritual Stone is an optional weapon embellishment.",
        "Loa Worshiper's Band is the current long-term centerpiece craft when your gem setup supports its preferred effect.",
        "Late season: Spellbreaker's Bracers with Stabilizing Gemstone Bandolier complements the Loa Worshiper's Band embellishment plan.",
    },
    craftTargets = {
        CraftTarget(237839, "Spellbreaker's Blade", "One-Hand", "VERY HIGH", "Hunter's Ritual Stone (optional)", "Early-season weapon craft when your available one-handed weapons are well below the track you can craft."),
        CraftTarget(251513, "Loa Worshiper's Band", "Finger", "VERY HIGH", "Loa Worshiper's Band effect", "Current long-term Frost crafting priority when your gem setup can support its preferred effect."),
        CraftTarget(237834, "Spellbreaker's Bracers", "Wrist", "VERY HIGH", "Stabilizing Gemstone Bandolier", "High-value Frost crafted wrist option that complements the current ring-focused embellishment plan."),
    },
    catalyst = {
        { slot = "Head", source = "Voidscar Arena" },
        { slot = "Shoulders", source = "Nymrissa Wavecaller" },
        { slot = "Chest", source = "The Coiled Altar" },
        { slot = "Hands", source = "The Twin Fangs" },
        { slot = "Legs", source = "Ula'tek" },
    },
    upgrades = {
        "Weapon quality is the first general upgrade concern; dual-wield means both weapon slots matter.",
        "After the core weapon and trinket targets, use Raidbots Top Gear for exact Crest spending instead of forcing a fixed slot order.",
        "Use the Catalyst to secure 4-piece early, then optimize the retained secondary stats as stronger base pieces arrive.",
    },
}

GearData.specs[252] = {
    sourceURL = "https://www.wowhead.com/guide/classes/death-knight/unholy/bis-gear",
    sourceUpdated = "2026-09-08",
    summary = "Unholy gearing prioritizes weapon power, the current active/passive trinket pair, and strong Venomous Abyss cantrip pieces while keeping Crit/Mastery-oriented crafted options flexible.",
    weaponNote = "Maze-roa is the headline two-handed target. A crafted two-handed weapon with Darkmoon Sigil: Hunt can be a strong early-season bridge when your weapon is far behind.",
    targets = {
        Target(268213, "Maze-roa, Warlord's Fury", "Weapon", "Coiled Altar - Venomous Abyss", "VERY HIGH", "Headline two-handed cantrip weapon and a major long-term Unholy target."),
        Target(270175, "Voracious Heart of Ula'tek", "Trinket", "Ula'tek - Venomous Abyss", "VERY HIGH", "Powerful on-use trinket that aligns naturally with Unholy's major cooldown package."),
        Target(270173, "Zul'jin's Guillotine Technique", "Trinket", "Coiled Altar - Venomous Abyss", "HIGH", "Excellent in 1-2 target scenarios, but current guidance ranks stat trinkets ahead of it in meaningful AoE."),
        Target(268265, "Aqirbane Reliquary", "Neck", "Ula'tek - Venomous Abyss", "HIGH", "Cantrip neck with a socket and a flexible secondary-stat effect."),
        Target(268249, "Vile Alchemist's Band", "Finger", "Vashnik - Venomous Abyss", "HIGH", "Current Unholy Best-in-Slot ring target in the September 8 Wowhead gear refresh."),
        Target(252258, "Sickening Signet of Atroxus", "Finger", "Atroxus - Voidscar Arena", "HIGH", "Current companion Best-in-Slot ring target for Unholy alongside Vile Alchemist's Band."),
        Target(271878, "Chausses of Unbound Rancor", "Legs", "Ula'tek - Venomous Abyss", "HIGH", "High-item-level cantrip legs and a valuable raid target."),
    },
    trinkets = {
        "Voracious Heart of Ula'tek is the standout on-use target and its 1.5-minute cooldown aligns naturally with Unholy's burst windows.",
        "Zul'jin's Guillotine Technique completes the BiS pair for 1-2 target scenarios, but it loses priority as target count rises.",
        "For Mythic+, Delves, and other frequent-AoE content, stat trinkets such as Gebbo's Bottomless Bag or Bellowstone can outperform Zul'jin's; keep one active and one passive option in mind.",
    },
    crafting = {
        "Early season: consider Blood Knight's Warblade with Darkmoon Sigil: Hunt if you do not have a near-max weapon.",
        "Spellbreaker's Bracers with Arcanoweave Lining are a strong stable craft.",
        "Spellbreaker's March with Arcanoweave Lining becomes attractive once weapon pressure is solved and Sparks are less constrained.",
    },
    craftTargets = {
        CraftTarget(237846, "Blood Knight's Warblade", "Weapon", "VERY HIGH", "Darkmoon Sigil: Hunt", "Early-season weapon bridge when you do not have a near-max two-handed weapon."),
        CraftTarget(237834, "Spellbreaker's Bracers", "Wrist", "VERY HIGH", "Arcanoweave Lining", "One of the strongest long-term Unholy crafted slots once weapon pressure is under control."),
        CraftTarget(237828, "Spellbreaker's March", "Feet", "HIGH", "Arcanoweave Lining", "Late-season complementary craft after the weapon problem is solved and Sparks are less constrained."),
    },
    catalyst = {
        { slot = "Head", source = "Murder Row" },
        { slot = "Shoulders", source = "Murder Row" },
        { slot = "Chest", source = "The Coiled Altar" },
        { slot = "Hands", source = "King's Rest" },
        { slot = "Legs", source = "Ula'tek" },
    },
    upgrades = {
        "Current general upgrade order: Weapon > strong trinkets > lowest item-level pieces.",
        "Weapon item level is the standout priority because Unholy's damage package scales heavily with weapon damage.",
        "Secure 4-piece early; later Catalyst choices can optimize the secondary stats retained from the original item.",
    },
}

DKM.GearData = GearData
