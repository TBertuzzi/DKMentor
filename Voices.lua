local ADDON_NAME, DKM = ...
local T = DKM.T or function(value) return value end

-- Lich King commentary uses FileDataIDs that point to voice resources already
-- installed by World of Warcraft. DK Mentor never bundles or extracts Blizzard
-- audio. The client resolves the resource that is available for its locale.
local GREETINGS = { 554073, 554123, 554099, 554181 }
local WHISPERS = {
    554107, 554160, 554122, 554105, 554186, 553992, 554135, 553987,
    553996, 554145, 554110, 554087, 553993, 554096, 553998, 554064,
}
local ATTACKS = { 554037, 554171, 554070, 554031, 554130, 554124, 554106, 554108, 554182, 554142 }
local SHOUTS = {
    554016, 554113, 554054, 554165, 554005, 554141, 553983, 554102,
    554177, 554033, 554117, 554083, 554115, 553988, 554074, 553990,
}
local VICTORY = { 554001, 554069, 554014, 554068, 554078 }
local FAREWELLS = { 553997, 554088, 554159, 554089, 554172, 554085 }
local RAISE = { 554126, 554073, 554123, 554099, 554181 }

local pools = {
    preview = GREETINGS,
    login = GREETINGS,
    zone = { 554073, 554123, 554107, 554160, 554122, 554105 },
    combatStart = ATTACKS,
    combatVictory = VICTORY,
    encounterStart = SHOUTS,
    encounterVictory = VICTORY,
    death = FAREWELLS,
    resurrection = RAISE,
    mount = { 554107, 554160, 554122, 554105, 554186 },
    hearthstone = { 554107, 554160, 554122, 554105, 553992, 553987 },
    afkStart = { 554107, 554122, 553992, 553987 },
    afkEnd = GREETINGS,
    petSummon = { 554126, 554107, 554160, 554122 },
    control = { 554037, 554171, 554070, 554031, 554130 },
    majorOffense = { 554016, 554113, 554054, 554165, 554005, 554141 },
    deathGate = { 554107, 554160, 554122, 554105, 554186 },
    defensive = WHISPERS,
}

-- Spell-specific categories let players choose a different voice for each
-- situation without storing quote text in the addon. They intentionally reuse
-- the curated resource pools above.
pools.raiseDead = pools.petSummon
pools.raiseAlly = RAISE
pools.armyOfDead = pools.majorOffense
pools.darkTransformation = pools.majorOffense
pools.deathsAdvance = pools.control
pools.deathGrip = pools.control
pools.deathAndDecay = pools.control
pools.asphyxiate = pools.control
pools.blindingSleet = pools.control
pools.mindFreeze = pools.control
pools.chainsOfIce = pools.control
pools.pillarOfFrost = pools.majorOffense
pools.breathOfSindragosa = pools.majorOffense
pools.frostwyrmsFury = pools.majorOffense
pools.apocalypse = pools.majorOffense

DKM.Voices = {
    dataVersion = "2026-08-22-v6",
    channel = "Dialog",

    frequencyOrder = { "low", "normal", "high" },
    frequencies = {
        low = { label = T("Low"), cooldown = 180, chance = 0.28 },
        normal = { label = T("Normal"), cooldown = 95, chance = 0.48 },
        high = { label = T("High"), cooldown = 50, chance = 0.72 },
    },

    categoryChance = {
        zone = 0.45,
        combatStart = 0.9,
        combatVictory = 0.75,
        encounterStart = 1.2,
        encounterVictory = 1.45,
        death = 1.0,
        resurrection = 0.8,
        defensive = 0.4,
        login = 0.9,
        mount = 1.0,
        hearthstone = 1.0,
        afkStart = 0.28,
        afkEnd = 0.45,
        petSummon = 0.65,
        control = 0.55,
        majorOffense = 0.9,
        deathGate = 0.85,
        raiseDead = 0.85,
        raiseAlly = 0.9,
        armyOfDead = 1.2,
        darkTransformation = 0.9,
        deathsAdvance = 0.45,
        deathGrip = 0.7,
        deathAndDecay = 0.4,
        asphyxiate = 0.85,
        blindingSleet = 0.85,
        mindFreeze = 0.95,
        chainsOfIce = 0.45,
        pillarOfFrost = 0.9,
        breathOfSindragosa = 1.15,
        frostwyrmsFury = 1.15,
        apocalypse = 1.05,
        preview = 1.0,
    },

    pools = pools,

    -- Order/labels used by the in-game Voice Mapping window. "Voice 1", etc.
    -- are intentionally generic; players can preview each installed line.
    selectionOrder = {
        "login", "zone", "combatStart", "combatVictory", "encounterStart",
        "encounterVictory", "death", "resurrection", "mount", "hearthstone",
        "afkStart", "afkEnd", "raiseDead", "raiseAlly", "armyOfDead",
        "darkTransformation", "deathsAdvance", "deathGrip", "deathAndDecay",
        "deathGate", "asphyxiate", "blindingSleet", "mindFreeze", "chainsOfIce",
        "pillarOfFrost", "breathOfSindragosa", "frostwyrmsFury", "apocalypse",
        "defensive",
    },
    categoryLabels = {
        login = T("Login / Reload"),
        zone = T("New zone"),
        combatStart = T("Combat starts"),
        combatVictory = T("Combat victory"),
        encounterStart = T("Boss starts"),
        encounterVictory = T("Boss defeated"),
        death = T("Player dies"),
        resurrection = T("Resurrection"),
        mount = T("Mounting"),
        hearthstone = T("Hearthstone"),
        afkStart = T("Going AFK"),
        afkEnd = T("Returning from AFK"),
        raiseDead = T("Raise Dead"),
        raiseAlly = T("Raise Ally"),
        armyOfDead = T("Army of the Dead"),
        darkTransformation = T("Dark Transformation"),
        deathsAdvance = T("Death's Advance"),
        deathGrip = T("Death Grip"),
        deathAndDecay = T("Death and Decay"),
        deathGate = T("Death Gate"),
        asphyxiate = T("Asphyxiate"),
        blindingSleet = T("Blinding Sleet"),
        mindFreeze = T("Mind Freeze"),
        chainsOfIce = T("Chains of Ice"),
        pillarOfFrost = T("Pillar of Frost"),
        breathOfSindragosa = T("Breath of Sindragosa"),
        frostwyrmsFury = T("Frostwyrm's Fury"),
        apocalypse = T("Apocalypse"),
        defensive = T("Major defensive"),
    },

    -- Direct spell IDs for the core Hearthstones. Additional cosmetic
    -- Hearthstone toys are discovered at runtime from their item IDs below.
    hearthstoneSpells = {
        [8690] = true,   -- Hearthstone
        [171253] = true, -- Garrison Hearthstone
        [224869] = true, -- Dalaran Hearthstone
        [278244] = true, -- Greatfather Winter's Hearthstone
        [278559] = true, -- Headless Horseman's Hearthstone
    },

    -- Common Hearthstone items/toys. C_Item.GetItemSpell resolves their current
    -- cast spell at runtime, which is safer than assuming every cosmetic uses
    -- the same spell ID across client builds.
    hearthstoneItems = {
        6948,   -- Hearthstone
        110560, -- Garrison Hearthstone
        140192, -- Dalaran Hearthstone
        64488,  -- The Innkeeper's Daughter
        162973, -- Greatfather Winter's Hearthstone
        163045, -- Headless Horseman's Hearthstone
        165669, -- Lunar Elder's Hearthstone
        165670, -- Peddlefeet's Lovely Hearthstone
        165802, -- Noble Gardener's Hearthstone
        166746, -- Fire Eater's Hearthstone
        166747, -- Brewfest Reveler's Hearthstone
        168907, -- Holographic Digitalization Hearthstone
        172179, -- Eternal Traveler's Hearthstone
        188952, -- Dominated Hearthstone
        193588, -- Timewalker's Hearthstone
        200630, -- Ohn'ir Windsage's Hearthstone
        206195, -- Path of the Naaru
        208704, -- Deepdweller's Earthen Hearthstone
        210455, -- Draenic Hologem
        235016, -- Redeployment Module
        250411, -- Timerunner's Hearthstone
        257736, -- Lightcalled Hearthstone
        265100, -- Corewarden's Hearthstone
    },

    defensiveSpells = {
        [48707] = true,  -- Anti-Magic Shell
        [48792] = true,  -- Icebound Fortitude
        [48743] = true,  -- Death Pact
        [51052] = true,  -- Anti-Magic Zone
        [49039] = true,  -- Lichborne
        [55233] = true,  -- Vampiric Blood
        [49028] = true,  -- Dancing Rune Weapon
        [194679] = true, -- Rune Tap
    },

    -- These categories are DK Mentor's own trigger mapping. No code or audio
    -- is copied from BetterDeathKnightExperience or any other addon.
    situationalSpells = {
        [46585] = { category = "raiseDead", chanceMultiplier = 1.2 },
        [61999] = { category = "raiseAlly", chanceMultiplier = 1.2 },
        [42650] = { category = "armyOfDead", chanceMultiplier = 1.6 },
        [63560] = { category = "darkTransformation", chanceMultiplier = 1.3 },
        [48265] = { category = "deathsAdvance", chanceMultiplier = 0.7 },
        [49576] = { category = "deathGrip", chanceMultiplier = 1.0 },
        [43265] = { category = "deathAndDecay", chanceMultiplier = 0.6 },
        [50977] = { category = "deathGate", chanceMultiplier = 1.5 },
        [108194] = { category = "asphyxiate", chanceMultiplier = 1.15 },
        [207167] = { category = "blindingSleet", chanceMultiplier = 1.15 },
        [47528] = { category = "mindFreeze", chanceMultiplier = 1.25 },
        [45524] = { category = "chainsOfIce", chanceMultiplier = 0.7 },
        [51271] = { category = "pillarOfFrost", chanceMultiplier = 1.2 },
        [152279] = { category = "breathOfSindragosa", chanceMultiplier = 1.5 },
        [279302] = { category = "frostwyrmsFury", chanceMultiplier = 1.5 },
        [275699] = { category = "apocalypse", chanceMultiplier = 1.4 },
    },
}
