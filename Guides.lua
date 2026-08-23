local ADDON_NAME, DKM = ...

local T = DKM.T or function(value) return value end

DKM.Guides = {
    general = {
        title = T("Death Knight fundamentals"),
        sections = {
            {
                heading = T("Runes and Runic Power"),
                body = T("Your abilities spend Runes to create Runic Power, then spend Runic Power on finishers and recovery. Avoid wasting either resource: keep Runes cycling and leave enough Runic Power for Death Strike when survival matters."),
            },
            {
                heading = T("Death Strike is your universal recovery tool"),
                body = T("For Frost and Unholy, Death Strike is mainly a survival decision. Use it after meaningful damage instead of pressing it whenever possible. Blood is different: Death Strike is a central part of active tanking and should be timed after dangerous hits."),
            },
            {
                heading = T("Control prevents damage"),
                body = T("Mind Freeze, Death Grip, Chains of Ice, Asphyxiate, and Blinding Sleet can prevent far more damage than a late defensive. Interrupt priority casts first and use control to reduce the number of enemies acting at once."),
            },
            {
                heading = T("Core defensives"),
                body = T("Anti-Magic Shell is strongest before magic damage or magic crowd control. Icebound Fortitude is your major emergency defensive and can also help during dangerous stuns. Death's Advance helps against forced movement and slows."),
            },
        },
    },
    [250] = {
        title = T("Blood Death Knight"),
        sections = {
            {
                heading = T("Blood Death Knight"),
                body = T("Blood survives by preparing mitigation and then recovering after damage. Your health moving up and down is normal; the goal is to control those swings instead of reacting too late."),
            },
            {
                heading = T("Bone Shield"),
                body = T("Keep Bone Shield active before important pulls. Do not enter a dangerous pack with no stacks if you can prepare beforehand."),
            },
            {
                heading = T("Death Strike timing"),
                body = T("Death Strike is most valuable after a significant hit. Plan Runic Power around predictable tank damage instead of spending it without purpose."),
            },
            {
                heading = T("Use cooldowns early enough"),
                body = T("Vampiric Blood, Dancing Rune Weapon, Rune Tap, and Anti-Magic Shell are tools to prevent a crisis. A defensive used before a dangerous window is usually worth more than one pressed at nearly zero health."),
            },
        },
    },
    [251] = {
        title = T("Frost Death Knight"),
        sections = {
            {
                heading = T("Frost Death Knight"),
                body = T("Frost turns Runes into hard-hitting weapon attacks and Runic Power into Frost Strike or other spenders. The spec rewards reacting to procs without overcapping resources."),
            },
            {
                heading = T("Killing Machine and Rime"),
                body = T("Killing Machine makes your next Obliterate especially valuable, while Rime empowers a free Howling Blast. React to these procs quickly, but do not create resource waste just to consume them instantly."),
            },
            {
                heading = T("Cooldown windows"),
                body = T("Pillar of Frost defines an important damage window. Enter it with resources available, keep attacking, and avoid spending the entire window moving or recovering from preventable mechanics."),
            },
            {
                heading = T("Beginner priority"),
                body = T("Keep Runes cycling, react to Killing Machine and Rime, avoid capping Runic Power, use the native Assisted Combat glow for offensive sequencing, and reserve enough Runic Power for Death Strike when solo content becomes dangerous."),
            },
        },
    },
    [252] = {
        title = T("Unholy Death Knight"),
        sections = {
            {
                heading = T("Unholy Death Knight"),
                body = T("Unholy combines diseases, wounds, pets, and Runic Power spenders. Its damage often comes from setting up several systems before the payoff, so avoid pressing major cooldowns with no preparation."),
            },
            {
                heading = T("Festering Wounds"),
                body = T("Build Festering Wounds on important targets and burst them with your wound-consuming attacks. Avoid creating far more wounds than you can realistically consume before the target dies."),
            },
            {
                heading = T("Pets and major cooldowns"),
                body = T("Dark Transformation, Apocalypse, and Army of the Dead reward planning. Use them when the target will live long enough for the summons and empowered pet time to matter."),
            },
            {
                heading = T("Runic Power"),
                body = T("Spend Runic Power without capping, but keep survival in mind in solo or PvP content. Death Coil and Epidemic are damage tools; Death Strike competes for the same resource when you need to live."),
            },
        },
    },
    content = {
        title = T("Content tips"),
        sections = {
            {
                heading = T("Delves / solo"),
                body = T("Pull at a pace that lets you preserve Runic Power for recovery. Interrupt dangerous casts, use crowd control proactively, and do not save every defensive for an emergency that could have been prevented."),
            },
            {
                heading = T("Dungeons"),
                body = T("Your interrupt and grips are group utility. Learn which casts matter, use Anti-Magic Zone when several players will take magic damage, and coordinate large defensive cooldowns with dangerous pulls."),
            },
            {
                heading = T("Raids"),
                body = T("Plan defensives around known mechanics instead of health percentage alone. Death's Advance can trivialize some forced-movement mechanics, and Anti-Magic Shell is strongest when used before predictable magic damage."),
            },
            {
                heading = T("PvP"),
                body = T("Survival depends on predicting enemy cooldowns. Preserve Runic Power when you are likely to be targeted, use Anti-Magic Shell before incoming magic control, and use Icebound Fortitude during the enemy's real pressure window rather than after it ends."),
            },
        },
    },
    footer = T("This guide is intentionally beginner-focused and complements the build source shown in the Loadouts tab. It does not replace encounter-specific guides or simulations."),
}
