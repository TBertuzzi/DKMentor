# DK Mentor 3.1.0 — Live Test Checklist

This is the first 3.1 test/RC checklist. Static validation cannot reproduce WoW item-cache behavior, native tooltips, protected combat restrictions, model availability, real SavedVariables migration, or UI scaling. Test in Retail 12.1.0 before publishing.

## 1. Upgrade / startup

- Install **3.1.0 Test** over the published 3.0.17 build.
- Log in on a Death Knight and confirm no Lua error occurs.
- `/reload` and confirm existing HUD positions/settings remain intact.
- Confirm all HUDs start locked even if a previous session ended while editing.
- Confirm Gear Mentor still opens and the existing Overview / Gear / Crafting / Sources / Trinkets / Upgrades views remain usable.

## 2. Preparation / Ready Check

Open **DK Codex → Gear Mentor → Preparation** or `/dkm prep`.

### All specs
- Test Blood, Frost, and Unholy.
- Confirm a `Preparation x / 9` style summary appears.
- Hover every visible Runeforge/enchant/gem/consumable card and confirm the native WoW tooltip opens and closes normally.
- Confirm item/spell names follow the WoW client locale while DK Mentor labels follow the addon language override.
- Confirm no card click equips, uses, sockets, enchants, purchases, or changes anything.
- Remove/restore recommended consumables from bags and confirm readiness changes after the normal inventory refresh.
- Test with an uncached item state if possible; no Lua error should occur.

### Runeforge
- Blood: verify Sanguination is accepted and Fallen Crusader is shown as the documented high-target Deathbringer alternative.
- Frost 2H: verify Fallen Crusader is expected.
- Frost Dual Wield + Shattering Blade: verify Razorice main hand + Fallen Crusader off hand is expected.
- Frost Dual Wield without Shattering Blade: verify Stoneskin Gargoyle main hand + Fallen Crusader off hand is expected.
- Unholy: verify Apocalypse is expected.
- Test a deliberately wrong/no Runeforge and confirm the page reports attention instead of changing the weapon.

### Enchants / sockets
- Test a character with all common slots enchanted.
- Remove/replace one enchant if practical and confirm the common enchant readiness changes.
- Test at least one empty socket and confirm it is detected.
- Confirm the note correctly explains that exact enchant/gem recommendation verification is intentionally conservative.

### Consumables
- Verify visible recommendations for flask, combat potion, health potion, weapon consumable, augment rune, and food.
- Test with none of them in bags and then with recommended items present.

## 3. SBA-friendly Build Mentor

Open **DK Codex → Builds**.

- Confirm **Standard** and **SBA-friendly** controls are visible.
- Standard mode should keep the normal guide-backed ordering.
- SBA-friendly mode should bring friendly profiles first without alphabetically reordering Recommended/Alternative entries inside the same group.
- Frost PvP: Rider should be the SBA-friendly recommendation; Deathbringer should remain the tighter manual burst alternative.
- Unholy Rider profiles should receive the SBA-friendly explanation where applicable.
- Verify the reduced-complexity Frost key-talent row does not present Breath of Sindragosa as a key SBA-friendly icon.
- Confirm the accessibility explanation clearly states that defensives, interrupts, CC, utility, movement/situational decisions remain manual.
- Confirm changing Standard/SBA-friendly never switches talents or specialization.

## 4. Layout preset export/import

Open **Settings → Layout presets...** or `/dkm preset`.

- Move/scale several DK Mentor HUDs, export, and copy the `DKM31;...` string.
- Reset HUD positions, paste the exported string, import, and confirm the saved positions/scales return.
- Confirm imported layouts are relocked after import.
- Confirm Combat Only/visibility and supported visual settings survive the round trip.
- Confirm the Lich King portrait position/scale/enabled state survives the round trip while importing it locked.
- Try invalid text and confirm it is rejected without a Lua error.
- Try a string beginning with something other than exact `DKM31;` and confirm it is rejected.
- Enter combat and confirm preset import is blocked.
- Confirm third-party addon layouts such as Bartender4 are not included.

## 5. Lich King commentary portrait

In **Settings → Lich King commentary**:

- Enable commentary and portrait separately.
- Unlock the portrait; confirm it becomes movable and a preview is visible while arranging it.
- Move it, lock it, `/reload`, and confirm the position persists.
- Cycle all portrait scales and check that it remains on screen.
- Use the existing voice Preview action and confirm the portrait appears with playback and hides after playback finishes.
- Confirm disabling the portrait does not disable voice commentary.
- Confirm disabling commentary/portrait does not cause errors.
- Confirm the WoW-native Lich King model is framed acceptably on the live client. If it is unavailable, confirm the built-in icon fallback remains safe/readable.
- Confirm no extracted Blizzard image/model/audio files exist in the addon directory.

## 6. Localization

- Test DK Mentor language **English** on a ptBR WoW client.
- Test DK Mentor language **Português**.
- Check Preparation cards, SBA mode labels/notes, preset dialog, portrait controls, and slash-help entries for clipping/leaked English addon text.
- Item/spell names from Blizzard are allowed to remain in the WoW client language.

## 7. Regression

- World / Delve / Dungeon / Mythic+ / Raid / PvP Build Mentor selector.
- Gear Mentor item/tier/crafting tooltips.
- DK Resource HUD and ordered Runes.
- Mind Freeze HUD/action glow/sound.
- Live Mentor / Review / DK Tools / Alert Studio.
- Loadout Pilot handoff.
- Lich King commentary without portrait.
- `/dkm reset` and **Reset HUDs**.
- Login/reload on Blood, Frost, and Unholy.

## Acceptance

Publish 3.1.0 only after the live client confirms:

1. no Lua errors or taint/protected-action errors;
2. Preparation data/cards fit at normal UI scale in EN and ptBR;
3. Frost 2H/DW Runeforge detection behaves as expected;
4. SBA-friendly mode is advisory only;
5. preset round-trip is stable and combat-safe;
6. portrait movement/model fallback/playback lifecycle behaves correctly.
