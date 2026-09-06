local ADDON_NAME, DKM = ...

local T = DKM.T or function(value) return value end

local Codex = {
    patch = "12.1.0",
    season = T("Midnight Season 2"),
    reviewed = "2026-09-03",
    sectionOrder = { "overview", "advisor", "stats", "builds", "valeera", "rotation", "survival", "utility", "check" },
    sectionLabels = {
        overview = T("Overview"),
        advisor = T("Stats & Folio"),
        builds = T("Builds"),
        valeera = T("Valeera"),
        stats = T("Gear Mentor"),
        rotation = T("Rotation"),
        survival = T("Survival"),
        utility = T("Utility"),
        check = T("Character Check"),
    },
}

Codex.common = {
    overview = {
        {
            heading = T("DK mechanics — Runes"),
            body = T("Death Knights have six Runes, but only three can regenerate at the same time. Spending from different Rune pairs keeps regeneration moving; sitting on too many ready Runes wastes future resource generation."),
        },
        {
            heading = T("DK mechanics — Runic Power"),
            body = T("Runic Power is generated mainly by spending Runes and fuels damage spenders plus Death Strike. Avoid capping it, but in dangerous solo, PvP, or tank situations keep enough available for emergency recovery."),
        },
        {
            heading = T("DK mechanics — Death Strike"),
            body = T("Death Strike is strongest after meaningful incoming damage. Blood plans much of its active mitigation around that timing; Frost and Unholy should treat it as a survival conversion of Runic Power instead of a normal damage button."),
        },
        {
            heading = T("How to use this Codex"),
            body = T("Use the Codex as a fast in-game reference, not as a replacement for simulation or encounter-specific strategy. Stat values, Hero Talent tuning, trinkets, and exact openers can shift with hotfixes even inside the same patch."),
        },
    },
    survival = {
        {
            heading = T("Universal survival toolkit"),
            body = T("Anti-Magic Shell is best used before predictable magic damage or magic control. Icebound Fortitude is the major emergency defensive and also helps against dangerous stuns. Lichborne, Death Pact, and Anti-Magic Zone depend on your talent choices but can add powerful personal or group survival."),
        },
        {
            heading = T("Physical vs. magic damage"),
            body = T("Do not press Anti-Magic Shell into a purely physical hit. Use Icebound Fortitude or spec-specific mitigation for heavy physical pressure, and save Anti-Magic Shell for mechanics it can actually absorb or prevent."),
        },
        {
            heading = T("Resource planning saves lives"),
            body = T("A DK at zero Runic Power has fewer recovery options. Before a dangerous pull or enemy burst, avoid spending every point of Runic Power if you expect to need Death Strike immediately afterward."),
        },
    },
    utility = {
        {
            heading = T("Interrupt and crowd control handbook"),
            body = T("Mind Freeze is your primary interrupt. Death Grip can stop or reposition many movable casters, Asphyxiate provides a stun when talented, Blinding Sleet can disrupt groups, and Chains of Ice is excellent for controlling dangerous movement. A well-timed control effect often prevents more damage than a late defensive."),
        },
        {
            heading = T("Death Grip etiquette"),
            body = T("Grip is powerful group utility, but moving an enemy can break tank positioning or pull it out of ground effects. Use it deliberately: bring a caster into the pack, rescue positioning, or stop a dangerous cast when a normal interrupt is unavailable."),
        },
        {
            heading = T("Movement and group tools"),
            body = T("Death's Advance is valuable against slows and forced movement. Anti-Magic Zone can protect the group from shared magic damage, and Raise Ally gives every DK a combat resurrection when the encounter allows it."),
        },
    },
}

Codex.specs = {
    [250] = {
        name = T("Blood Death Knight"),
        overview = {
            {
                heading = T("Playstyle identity"),
                body = T("Blood is a reactive tank built around preparing mitigation, taking a hit, and recovering with Death Strike. Large health swings are normal; the goal is to control them with Bone Shield, Runic Power planning, and proactive cooldowns."),
            },
            {
                heading = T("Hero Talents — San'layn"),
                body = T("San'layn emphasizes Vampiric Strike, Essence of the Blood Queen, and strong Dancing Rune Weapon windows. In Patch 12.1 it is a very attractive default for content with frequent multi-target combat and rewards maintaining its haste-oriented gameplay loop."),
            },
            {
                heading = T("Hero Talents — Deathbringer"),
                body = T("Deathbringer centers on Reaper's Mark and more compact burst windows. It is straightforward to plan around and remains competitive when encounter timing or single-target focus favors its damage profile."),
            },
        },
        stats = {
            {
                heading = T("PvE stat priority — San'layn"),
                body = T("Higher item level first; among secondaries, Haste (to roughly the first diminishing-return breakpoint) >= Critical Strike > Mastery > Versatility. San'layn values Haste strongly, but close choices should still be simulated."),
            },
            {
                heading = T("PvE stat priority — Deathbringer"),
                body = T("Higher item level first; among secondaries, Critical Strike >= Mastery > Versatility >= Haste. Deathbringer generally avoids Haste compared with San'layn, so compare gear in the context of the tree you actually play."),
            },
            {
                heading = T("Runeforge"),
                body = T("Current Patch 12.1 guidance uses Rune of Sanguination for San'layn and for Deathbringer single target, while Rune of the Fallen Crusader is the Deathbringer high-target AoE direction (roughly 10+ targets). DK Mentor's Ready Check only requires a valid DK Runeforge; the Codex recommendation is informational."),
            },
            {
                heading = T("Gems"),
                body = T("Use Indecipherable Eversong Diamond as the unique epic gem. Flawless Masterful Garnet is a strong Deathbringer-friendly Crit/Mastery direction, while Flawless Deadly Peridot matches San'layn's Haste/Crit needs well. Sim your current stat distribution."),
            },
            {
                heading = T("Enchants"),
                body = T("Current general recommendations: Head — Empowered Blessing of Speed; Shoulders — Akil'zon's Swiftness; Chest — Mark of the Worldsoul; Legs — Forest Hunter's Armor Kit; Feet — Farstrider's Hunt; Rings — Nature's Fury. Eyes of the Eagle is the damage-oriented ring alternative."),
            },
            {
                heading = T("Consumables"),
                body = T("Use Thalassian Phoenix Oil. Flask of the Blood Knights and Flask of the Shattered Sun are the current default flask directions; Thalassian Resistance is a situational defensive option. Potion of Recklessness is the standard combat potion, with Concentrated Silvermoon Health Potion, Blooming Feast or Harandar Celebration, and Void-Touched Augment Rune rounding out preparation."),
            },
        },
        rotation = {
            {
                heading = T("Cheat sheet"),
                body = T("Keep Bone Shield active. Do not cap Runes. Build and preserve enough Runic Power for Death Strike. Use Death Strike after meaningful damage. Keep Blood Boil working on packs, and use your major cooldowns before the pull becomes a crisis."),
            },
            {
                heading = T("Beginner opener"),
                body = T("A safe general pattern is: pre-place Death and Decay when useful, prepare Bone Shield/Death's Caress, apply your Hero Talent burst such as Reaper's Mark when available, activate Dancing Rune Weapon for the dangerous opening window, establish Blood Boil coverage, then settle into your normal Rune/Runic Power and Death Strike priority. Exact sequencing changes with talents."),
            },
            {
                heading = T("Cooldown handbook — burst"),
                body = T("Dancing Rune Weapon is both offensive and defensive and should usually be used early enough to gain its full value. Deathbringer players align Reaper's Mark with planned damage windows; San'layn players care strongly about their Vampiric Strike / Essence of the Blood Queen window."),
            },
            {
                heading = T("Cooldown handbook — defense"),
                body = T("Vampiric Blood amplifies your health and recovery, Rune Tap helps before predictable hits when talented, Icebound Fortitude covers major physical or stun pressure, and Anti-Magic Shell should be planned around magic mechanics."),
            },
        },
        survival = {
            {
                heading = T("Blood survival priority"),
                body = T("Prepare Bone Shield before dangerous contact, avoid entering a tank buster with no Runic Power, use mitigation before the hit, then use Death Strike after the hit. Do not wait until nearly zero health to press every major cooldown at once."),
            },
            {
                heading = T("Large pulls"),
                body = T("Open difficult packs with a plan: establish threat and diseases quickly, position casters with Grip, use Dancing Rune Weapon or another planned cooldown early, and rotate defensives instead of overlapping everything. Save enough Runic Power to recover from the first real spike."),
            },
        },
        utility = {
            {
                heading = T("Blood-specific control"),
                body = T("Gorefiend's Grasp is one of the strongest positioning tools a tank can bring. Use it to consolidate enemies for your group, but avoid dragging mobs through dangerous areas or disrupting carefully placed crowd control."),
            },
        },
    },
    [251] = {
        name = T("Frost Death Knight"),
        overview = {
            {
                heading = T("Playstyle identity"),
                body = T("Frost converts Runes into heavy weapon attacks and uses Runic Power on Frost spenders while reacting to Killing Machine and Rime. Strong play is about keeping resources moving and entering major cooldown windows prepared."),
            },
            {
                heading = T("Hero Talents — Rider of the Apocalypse"),
                body = T("Rider adds Horsemen/minion pressure and excellent mobility through Death Charge. It is especially comfortable for movement-heavy or solo content and remains a strong raid option in current Patch 12.1 tuning."),
            },
            {
                heading = T("Hero Talents — Deathbringer"),
                body = T("Deathbringer adds Reaper's Mark and concentrated burst windows. It is a strong Mythic+ option in current 12.1 tuning, but both Frost Hero Talent trees are viable and their relative value can change with hotfixes and encounter shape."),
            },
        },
        stats = {
            {
                heading = T("PvE stat priority"),
                body = T("Strength > Critical Strike > Mastery > Haste > Versatility. Current Wowhead guidance gives Deathbringer and Rider the same general order; exact values still change with your gear, so simulate close upgrades."),
            },
            {
                heading = T("PvP stat priority"),
                body = T("Item Level > Versatility > Mastery > Haste > Critical Strike is the current general PvP direction. Exact Haste goals can differ between Rider and Deathbringer builds."),
            },
            {
                heading = T("Runeforge"),
                body = T("Season 2 PvE currently favors dual-wield. Aman'muso is Main Hand-only after Blizzard's August 20 hotfix, so pair it with Jaw of the Shackled Goddess in the off hand when using that headline setup. For dual-wield, keep Rune of the Fallen Crusader on the off hand; use Rune of Razorice on the main hand only with Shattering Blade, and Rune of the Stoneskin Gargoyle on the main hand for all other dual-wield builds because Glacial Advance supplies Razorice. Standard two-handed setups use Fallen Crusader. Thalassian Phoenix Oil remains the temporary weapon buff."),
            },
            {
                heading = T("Gems"),
                body = T("Use Indecipherable Eversong Diamond as the unique epic gem. Flawless Masterful Garnet is the current default secondary gem direction, but gem colors and exact secondary balance can still change with embellishments and your simulation."),
            },
            {
                heading = T("Enchants"),
                body = T("Current general recommendations: Head — Empowered Blessing of Speed; Shoulders — Akil'zon's Swiftness; Chest — Mark of the Worldsoul; Legs — Forest Hunter's Armor Kit; Boots — Farstrider's Hunt; Rings — Eyes of the Eagle."),
            },
            {
                heading = T("Consumables"),
                body = T("Flask of the Shattered Sun is the current default. Potion of Recklessness is the recommended combat potion, with Light's Potential as the current alternative. Carry Silvermoon Health Potion, Royal Roast, Thalassian Phoenix Oil, and Void-Touched Augment Rune."),
            },
        },
        rotation = {
            {
                heading = T("Cheat sheet"),
                body = T("Keep Runes cycling. React to Killing Machine and Rime without creating resource waste. Avoid capping Runic Power. For Midnight Breath of Sindragosa, extending the window is driven by consuming Killing Machine and Rime procs rather than a continuous Runic Power drain. Keep attacking during burst instead of spending the whole window repositioning."),
            },
            {
                heading = T("Beginner opener"),
                body = T("A current general single-target pattern is: Empower Rune Weapon, establish an Obliterate, apply Reaper's Mark if Deathbringer, activate Remorseless Winter, then start your major Pillar of Frost / Breath of Sindragosa burst package and use Frostwyrm's Fury in the planned window. Exact order changes with your saved build, weapon style, and Hero Talents."),
            },
            {
                heading = T("Cooldown handbook — burst"),
                body = T("Pillar of Frost defines your main damage window. Align it intelligently with Breath of Sindragosa, Frostwyrm's Fury, Reaper's Mark, trinkets, and potion according to your build. Avoid drifting major cooldowns without a reason."),
            },
            {
                heading = T("Cooldown handbook — resources"),
                body = T("Empower Rune Weapon is not just a damage button: it stabilizes the resources that make your burst work. Use it where the extra resources actually feed your next damage window instead of overcapping. In Midnight Breath builds, do not treat Runic Power as the old continuous Breath fuel model."),
            },
        },
        survival = {
            {
                heading = T("Frost survival priority"),
                body = T("Frost does not want to spend damage resources on Death Strike unnecessarily, but staying alive is always a DPS gain. When pressure is coming, preserve enough Runic Power for one or more Death Strikes and use Anti-Magic Shell before predictable magic damage."),
            },
            {
                heading = T("Do not die during Pillar"),
                body = T("A burst window is not permission to ignore mechanics. Pre-position, use Death's Advance for forced movement when appropriate, and use defensives early enough that you can keep attacking instead of losing the entire window to emergency recovery."),
            },
        },
        utility = {
            {
                heading = T("Frost-specific control"),
                body = T("Frost has the same excellent DK baseline toolkit: Mind Freeze, Death Grip, Chains of Ice, Asphyxiate/Blinding Sleet when talented, Anti-Magic Zone, and Raise Ally. Rider can add particularly convenient movement through Death Charge."),
            },
        },
    },
    [252] = {
        name = T("Unholy Death Knight"),
        overview = {
            {
                heading = T("Playstyle identity"),
                body = T("Midnight Unholy combines diseases, Lesser Ghouls, summoned minions, Rune spenders, and Runic Power spenders. Its damage rewards setup: prepare your disease/minion state first, then commit major cooldowns instead of pressing them into an empty setup."),
            },
            {
                heading = T("Hero Talents — Rider of the Apocalypse"),
                body = T("Rider is a strong default minion-oriented option in current Patch 12.1 guidance. It adds Horsemen pressure and Death Charge mobility and fits naturally with Unholy's pet-focused burst windows."),
            },
            {
                heading = T("Hero Talents — San'layn"),
                body = T("San'layn shifts more of the gameplay toward Vampiric Strike, plague/direct-damage interactions, and maintaining Essence of the Blood Queen. It offers a different rhythm and remains viable; exact preference can change by content and tuning."),
            },
        },
        stats = {
            {
                heading = T("PvE stat priority"),
                body = T("Strength > Critical Strike > Mastery > Haste > Versatility. Item-level upgrades are usually valuable, Crit tends to lead Mastery with Haste close behind, and Versatility is generally the weakest secondary; simulate close upgrades."),
            },
            {
                heading = T("PvP stat priority"),
                body = T("Item Level > Versatility > Mastery > Haste > Critical Strike is the current general PvP direction."),
            },
            {
                heading = T("Runeforge"),
                body = T("Rune of the Apocalypse plus Thalassian Phoenix Oil is the current Wowhead PvE recommendation for Unholy in Patch 12.1. DK Mentor still treats other valid DK Runeforges as informational rather than a hard setup failure."),
            },
            {
                heading = T("Gems"),
                body = T("Indecipherable Eversong Diamond is the current unique epic choice. Flawless Masterful Garnet and Flawless Deadly Amethyst are the common secondary-gem directions; simulate your exact balance."),
            },
            {
                heading = T("Enchants"),
                body = T("Current general recommendations: Head — Empowered Blessing of Speed; Shoulders — Akil'zon's Swiftness; Chest — Mark of the Worldsoul; Legs — Forest Hunter's Armor Kit; Boots — Farstrider's Hunt; Rings — Eyes of the Eagle."),
            },
            {
                heading = T("Consumables"),
                body = T("Flask of the Magisters is the safe default when you need more Mastery to keep it as your highest secondary rating; use Flask of the Shattered Sun when your existing Mastery is already high enough. Potion of Recklessness is the standard combat potion. Carry Silvermoon Health Potion, Silvermoon Parade or Royal Roast, Thalassian Phoenix Oil, and Void-Touched Augment Rune."),
            },
        },
        rotation = {
            {
                heading = T("Cheat sheet"),
                body = T("Keep your disease state healthy when it is readable. Build Lesser Ghouls with Festering Strike and convert them with Scourge Strike, avoid capping Runic Power, and spend procs promptly. Coordinate Army of the Dead and Dark Transformation with your planned burst package; use Putrefy when your build and pet window call for it, and use Epidemic instead of Death Coil when target count makes it appropriate."),
            },
            {
                heading = T("Beginner opener"),
                body = T("A current beginner-friendly pattern is: establish your disease, build Lesser Ghoul stacks with Festering Strike, commit Army of the Dead + Dark Transformation with your planned cooldowns, then convert Lesser Ghouls through Scourge Strike and Putrefy when appropriate while spending Runic Power with Death Coil or Epidemic. Exact sequencing changes with Hero Talents and target count."),
            },
            {
                heading = T("Cooldown handbook — burst"),
                body = T("Army of the Dead and Dark Transformation define major Unholy setup windows. Plan them around encounter timing and add waves instead of pressing them just before targets disappear. Rider emphasizes minion pressure; San'layn shifts more value into its Vampiric Strike / plague loop."),
            },
            {
                heading = T("Cooldown handbook — spenders"),
                body = T("Death Coil is the normal single-target Runic Power spender and Epidemic takes over in meaningful AoE. Do not cap Runic Power, but remember that Death Strike uses the same resource when survival becomes more important than damage."),
            },
        },
        survival = {
            {
                heading = T("Unholy survival priority"),
                body = T("Keep your ghoul and setup stable, but do not sacrifice your character to protect the rotation. Preserve Runic Power when danger is approaching, use Anti-Magic Shell proactively, and Death Strike after a real damage spike when necessary."),
            },
            {
                heading = T("Pet awareness"),
                body = T("Unholy loses meaningful value when its permanent ghoul is unexpectedly missing. DK Mentor's Ready Check already watches this when Raise Dead is part of your current setup; the Character Check repeats the state as a quick diagnostic."),
            },
        },
        utility = {
            {
                heading = T("Unholy-specific utility"),
                body = T("Your baseline control suite is just as important as your damage setup. Use Grip to bring casters into disease/AoE coverage, Mind Freeze priority spells, Chains of Ice dangerous movers, and keep Raise Ally ready for group recovery."),
            },
        },
    },
}

Codex.checkNotes = {
    [250] = T("Blood: the checker verifies a DK Runeforge, common enchantable slots, sockets when item data is available, and a live stat snapshot. It does not fail you for using a different valid Runeforge because Blood recommendations depend on Hero Talents and encounter shape."),
    [251] = T("Frost: the checker verifies setup hygiene, but it does not mark Razorice/Fallen Crusader combinations wrong because the correct pairing depends on two-handed vs dual-wield and the active build."),
    [252] = T("Unholy: the checker also reports ghoul state when your current setup exposes Raise Dead. Rune of the Apocalypse is the current PvE baseline recommendation, but the checker treats other valid DK Runeforges as informational rather than a hard failure."),
}

Codex.sourceNote = T("Patch 12.1 guidance reviewed 2026-09-06 from current Death Knight theorycraft/guide references and WoW client data. The post-September-1 Frost/Unholy review is complete: Frost Mythic+ no longer presents Frostbane as a recommended competitive option, while Unholy build direction remains stable. Use Raidbots or another current simulator for exact personal gear/stat optimization.")

DKM.Codex = Codex
