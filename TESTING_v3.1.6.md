# DK Mentor 3.1.6 — Live Test Checklist

## 1. Startup
- Install **3.1.6 Test r4** over the previous 3.1 test build and `/reload`.
- Confirm no Lua warnings/errors and that existing settings remain intact.

## 2. Layout Presets
- Open **Settings -> Layout Presets**.
- Confirm the modal appears above the main DK Mentor window and remains draggable.
- Confirm both the top-right X and **Close / Fechar** footer button work.
- Reopen it and verify Export, Import, Select All and Reset HUDs still work.

## 3. Lich King portrait
- Unlock the portrait, drag it to an obvious position, then lock it.
- With the portrait locked, use **Preview Voice** and trigger normal commentary: **Drag to move / Arraste para mover** and **Preview / Prévia** must not be visible.
- Unlock/show the portrait for positioning and confirm the movement helper appears only in that state.
- Switch Arthas/Bolvar, change scale through 80%, 100%, 120% and 140%, then `/reload`; the saved position must remain stable.
- Export/import a DKM31 preset and confirm the portrait position and selected character restore correctly.

## 4. DK Ready / DK Pronto
- Keep the widget enabled and visible outside combat.
- Enter combat: the widget must hide immediately and any open spec selector must close.
- Leave combat: the widget must return automatically if enabled.
- Repeat in world combat, Delve/dungeon combat and a boss encounter if available.
- Confirm the user's ON/OFF setting is not changed by the temporary combat hide.

## 5. Frost guidance refresh
- Open **Gear Mentor -> Gear** and confirm the headline dual-wield weapon direction uses **Jaw of the Shackled Goddess** as Main Hand and **Aman'muso** as Off Hand.
- Confirm the crafting direction includes **Loa Worshiper's Band** and late **Spellbreaker's Bracers + Stabilizing Gemstone Bandolier** guidance.
- Open **Preparation** and confirm **Light's Potential** is the recommended combat potion, **Draught of Rampant Abandon** is an alternative, and **Silvermoon Health Potion** is the health potion.
- Confirm dual-wield Runeforge guidance: Fallen Crusader Off Hand; Razorice Main Hand with Shattering Blade; Stoneskin Gargoyle Main Hand without Shattering Blade because Glacial Advance supplies Razorice.
- Confirm DK Codex stat direction reads **Strength > Critical Strike > Mastery > Haste > Versatility**.

## 6. Unholy guidance refresh
- Confirm **Voracious Heart of Ula'tek** remains the standout on-use trinket.
- Confirm **Zul'jin's Guillotine Technique** is described as strongest for roughly 1–2 targets rather than a universal AoE best choice.
- Confirm **Gebbo's Bottomless Bag / Bellowstone** are called out as stronger directions for frequent AoE such as M+, Delves and open world.
- Confirm upgrade guidance reads **Weapon > strong trinkets > lowest item-level pieces** and current consumables/gems remain available in Preparation.

## 7. Blood guidance refresh
- Confirm Codex/Preparation distinguishes **Rune of Sanguination** for San'layn and Deathbringer single target from **Rune of the Fallen Crusader** for Deathbringer high-target AoE.
- Confirm the current Blood gem, enchant, flask, potion, health-potion, food and weapon-oil directions render without missing localization strings.

## 8. Build regression
- Open Build Mentor for Blood, Frost and Unholy in PvE and PvP contexts.
- Confirm existing talent codes/build profiles still load exactly as before; this r4 intentionally does **not** replace talent trees or Hero Talent recommendations.
- Confirm SBA-friendly mode remains unchanged.
