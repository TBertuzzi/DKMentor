local ADDON_NAME, DKM = ...

-- DK Mentor 3.1 preparation guidance for Midnight Season 2 / Patch 12.1.0.
-- Item and spell names are resolved from the WoW client whenever possible.
-- The table intentionally stores IDs and short original guidance only; it does
-- not bundle third-party guide text, artwork, talent strings, or game assets.

DKM.PreparationData = {
    patch = "12.1.0",
    reviewed = "2026-09-03",
    sourceName = "Wowhead",
    sourceURL = "https://www.wowhead.com/guide/classes/death-knight",
    sourceNote = "Recommendations reviewed for Midnight Season 2. Close stat choices should still be simulated for the individual character.",

    commonEnchants = {
        { kind="enchant", slotID=1,  slot="Head",      itemID=243981, fallbackName="Enchant Helm - Empowered Blessing of Speed", priority="RECOMMENDED", reason="Current Season 2 Death Knight helm enchant direction." },
        { kind="enchant", slotID=3,  slot="Shoulders", itemID=243963, fallbackName="Enchant Shoulders - Akil'zon's Swiftness", priority="RECOMMENDED", reason="Current Season 2 Death Knight shoulder enchant direction." },
        { kind="enchant", slotID=5,  slot="Chest",     itemID=243977, fallbackName="Enchant Chest - Mark of the Worldsoul", priority="RECOMMENDED", reason="Current Season 2 Death Knight chest enchant direction." },
        { kind="enchant", slotID=7,  slot="Legs",      itemID=244641, fallbackName="Forest Hunter's Armor Kit", priority="RECOMMENDED", reason="Current Season 2 Death Knight leg enhancement direction." },
        { kind="enchant", slotID=8,  slot="Feet",      itemID=244009, fallbackName="Enchant Boots - Farstrider's Hunt", priority="RECOMMENDED", reason="Current Season 2 Death Knight boot enchant direction." },
    },

    specs = {
        [250] = {
            name = "Blood",
            ringEnchant = { kind="enchant", slotIDs={11,12}, slot="Rings", itemID=243987, fallbackName="Enchant Ring - Nature's Fury", priority="RECOMMENDED", reason="Default Blood ring enchant direction; damage-focused setups can value Eyes of the Eagle." },
            ringAlternative = { kind="enchant", slotIDs={11,12}, slot="Rings", itemID=243957, fallbackName="Enchant Ring - Eyes of the Eagle", priority="ALTERNATIVE", reason="Damage-oriented Blood alternative when Critical Strike is preferred." },
            runeforge = {
                { kind="runeforge", spellID=326805, enchantID=6241, fallbackName="Rune of Sanguination", slot="Weapon", priority="RECOMMENDED", reason="Recommended Blood runeforge for San'layn and Deathbringer single-target direction." },
                { kind="runeforge", spellID=53344, enchantID=3368, fallbackName="Rune of the Fallen Crusader", slot="Weapon", priority="ALTERNATIVE", reason="Deathbringer high-target AoE alternative when throughput is preferred." },
            },
            acceptedRuneforges = { [6241]=true, [3368]=true },
            gems = {
                { kind="gem", itemID=240983, fallbackName="Indecipherable Eversong Diamond", slot="Diamond", priority="RECOMMENDED", reason="Primary Season 2 diamond recommendation." },
                { kind="gem", itemID=240908, fallbackName="Flawless Masterful Garnet", slot="Other gems", priority="RECOMMENDED", reason="Sensible Deathbringer baseline; sim close secondary-stat choices for your character." },
                { kind="gem", itemID=240890, fallbackName="Flawless Deadly Peridot", slot="Other gems", priority="ALTERNATIVE", reason="San'layn-oriented Haste/Crit direction from current Wowhead guidance; sim your current stat balance." },
            },
            consumables = {
                flask = {
                    { kind="consumable", itemID=241324, fallbackName="Flask of the Blood Knights", slot="Flask", priority="RECOMMENDED", reason="Primary Blood flask direction." },
                    { kind="consumable", itemID=241326, fallbackName="Flask of the Shattered Sun", slot="Flask", priority="ALTERNATIVE", reason="Current Blood alternative depending on stat direction." },
                },
                combatPotion = {
                    { kind="consumable", itemID=241288, fallbackName="Potion of Recklessness", slot="Combat potion", priority="RECOMMENDED", reason="Current Season 2 Blood combat potion baseline." },
                    { kind="consumable", itemID=241308, fallbackName="Light's Potential", slot="Combat potion", priority="ALTERNATIVE", reason="Current Blood alternative when its primary-stat profile better fits the situation or cost." },
                },
                healthPotion = {
                    { kind="consumable", itemID=271884, fallbackName="Concentrated Silvermoon Health Potion", slot="Health potion", priority="RECOMMENDED", reason="Current Season 2 high-end healing potion." },
                },
                weaponBuff = {
                    { kind="consumable", itemID=243734, fallbackName="Thalassian Phoenix Oil", slot="Weapon buff", priority="RECOMMENDED", reason="Current temporary weapon consumable direction." },
                },
                augmentRune = {
                    { kind="consumable", itemID=259085, fallbackName="Void-Touched Augment Rune", slot="Augment rune", priority="RECOMMENDED", reason="Current Season 2 augment rune." },
                },
                food = {
                    { kind="consumable", itemID=242273, fallbackName="Blooming Feast", slot="Secondary-stat feast", priority="RECOMMENDED", reason="Current Blood secondary-stat feast direction." },
                    { kind="consumable", itemID=255846, fallbackName="Harandar Celebration", slot="Primary-stat feast", priority="ALTERNATIVE", reason="Current Blood primary-stat feast alternative; sim the close choice." },
                },
            },
        },

        [251] = {
            name = "Frost",
            ringEnchant = { kind="enchant", slotIDs={11,12}, slot="Rings", itemID=243957, fallbackName="Enchant Ring - Eyes of the Eagle", priority="RECOMMENDED", reason="Current Frost ring enchant direction." },
            runeforge = {
                { kind="runeforge", spellID=53344, enchantID=3368, fallbackName="Rune of the Fallen Crusader", slot="Two-Hand / Off Hand", priority="RECOMMENDED", reason="Use on a two-handed weapon; while dual wielding this is the recommended off-hand rune." },
                { kind="runeforge", spellID=53343, enchantID=3370, fallbackName="Rune of Razorice", slot="Dual Wield Main Hand", priority="RECOMMENDED", conditionSpellID=207057, reason="Dual-wield recommendation when Shattering Blade is talented." },
                { kind="runeforge", spellID=62158, enchantID=3847, fallbackName="Rune of the Stoneskin Gargoyle", slot="Dual Wield Main Hand", priority="ALTERNATIVE", inverseConditionSpellID=207057, reason="Dual-wield main-hand direction when Shattering Blade is not talented; Glacial Advance supplies Razorice." },
            },
            gems = {
                { kind="gem", itemID=240983, fallbackName="Indecipherable Eversong Diamond", slot="Diamond", priority="RECOMMENDED", reason="Primary Season 2 diamond recommendation." },
                { kind="gem", itemID=240908, fallbackName="Flawless Masterful Garnet", slot="Other gems", priority="RECOMMENDED", reason="Current Frost secondary gem direction." },
            },
            consumables = {
                flask = {
                    { kind="consumable", itemID=241326, fallbackName="Flask of the Shattered Sun", slot="Flask", priority="RECOMMENDED", reason="Current Frost Season 2 flask direction." },
                },
                combatPotion = {
                    { kind="consumable", itemID=241308, fallbackName="Light's Potential", slot="Combat potion", priority="RECOMMENDED", reason="Current Wowhead default Frost combat potion." },
                    { kind="consumable", itemID=241292, fallbackName="Draught of Rampant Abandon", slot="Combat potion", priority="ALTERNATIVE", reason="Higher-primary-stat Frost alternative with a void-zone drawback; use it only when you can play around the effect cleanly." },
                },
                healthPotion = {
                    { kind="consumable", itemID=241304, fallbackName="Silvermoon Health Potion", slot="Health potion", priority="RECOMMENDED", reason="Current Wowhead Frost healing-potion recommendation." },
                },
                weaponBuff = {
                    { kind="consumable", itemID=243734, fallbackName="Thalassian Phoenix Oil", slot="Weapon buff", priority="RECOMMENDED", reason="Current temporary weapon consumable direction." },
                },
                augmentRune = {
                    { kind="consumable", itemID=259085, fallbackName="Void-Touched Augment Rune", slot="Augment rune", priority="RECOMMENDED", reason="Current Season 2 augment rune." },
                },
                food = {
                    { kind="consumable", itemID=242275, fallbackName="Royal Roast", slot="Food", priority="RECOMMENDED", reason="Current Frost Season 2 food direction." },
                },
            },
        },

        [252] = {
            name = "Unholy",
            ringEnchant = { kind="enchant", slotIDs={11,12}, slot="Rings", itemID=243957, fallbackName="Enchant Ring - Eyes of the Eagle", priority="RECOMMENDED", reason="Current Unholy ring enchant direction." },
            runeforge = {
                { kind="runeforge", spellID=327082, enchantID=6245, fallbackName="Rune of Apocalypse", slot="Weapon", priority="RECOMMENDED", reason="Current Unholy Season 2 runeforge direction." },
            },
            acceptedRuneforges = { [6245]=true },
            gems = {
                { kind="gem", itemID=240983, fallbackName="Indecipherable Eversong Diamond", slot="Diamond", priority="RECOMMENDED", reason="Primary Season 2 diamond recommendation." },
                { kind="gem", itemID=240908, fallbackName="Flawless Masterful Garnet", slot="Other gems", priority="RECOMMENDED", reason="Current Unholy secondary gem direction." },
                { kind="gem", itemID=240898, fallbackName="Flawless Deadly Amethyst", slot="Other gems", priority="ALTERNATIVE", reason="Current Unholy secondary gem alternative." },
            },
            consumables = {
                flask = {
                    { kind="consumable", itemID=241322, fallbackName="Flask of the Magisters", slot="Flask", priority="RECOMMENDED", reason="Current Unholy baseline when extra Mastery is needed to keep it as the highest secondary rating." },
                    { kind="consumable", itemID=241326, fallbackName="Flask of the Shattered Sun", slot="Flask", priority="ALTERNATIVE", reason="Current Unholy alternative when your existing Mastery is already high enough; sim the close choice." },
                },
                combatPotion = {
                    { kind="consumable", itemID=241288, fallbackName="Potion of Recklessness", slot="Combat potion", priority="RECOMMENDED", reason="Current Season 2 Unholy combat potion." },
                    { kind="consumable", itemID=241308, fallbackName="Light's Potential", slot="Combat potion", priority="ALTERNATIVE", reason="Situational Unholy alternative." },
                },
                healthPotion = {
                    { kind="consumable", itemID=241304, fallbackName="Silvermoon Health Potion", slot="Health potion", priority="RECOMMENDED", reason="Current Unholy guide healing-potion recommendation." },
                },
                weaponBuff = {
                    { kind="consumable", itemID=243734, fallbackName="Thalassian Phoenix Oil", slot="Weapon buff", priority="RECOMMENDED", reason="Current temporary weapon consumable direction." },
                },
                augmentRune = {
                    { kind="consumable", itemID=259085, fallbackName="Void-Touched Augment Rune", slot="Augment rune", priority="RECOMMENDED", reason="Current Season 2 augment rune." },
                },
                food = {
                    { kind="consumable", itemID=255845, fallbackName="Silvermoon Parade", slot="Feast", priority="RECOMMENDED", reason="Current Unholy primary-stat feast direction." },
                    { kind="consumable", itemID=242275, fallbackName="Royal Roast", slot="Personal food", priority="ALTERNATIVE", reason="Current Unholy personal-food option." },
                },
            },
        },
    },
}
