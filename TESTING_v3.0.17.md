# DK Mentor 3.0.17 — Live Test Checklist

Install **3.0.17 Test** over **3.0.16**.

## Build Mentor navigation
- Open **DK Codex / Código do DK → Builds**.
- Confirm the content selector shows **Auto, World, Delves, Dungeon, Mythic+, Raid, PvP**.
- Confirm **Auto** follows the detected content.
- Manually select every context and confirm the selection remains visual only; it must not switch talents/spec.

## Visual cards
- Verify each visible build profile shows a Hero Talent icon (when applicable), badge, focus, explanation, key-talent icons, and source line.
- Hover the Hero Talent and key-talent icons; native WoW spell tooltips should open and close normally.
- Verify multiple recommendations stack correctly (for example Blood M+/Raid and Unholy M+).

## Localization
- Test **ptBR** and confirm UI/explanations are Portuguese except official/proper game names returned by the WoW client.
- Test **enUS** and confirm the same layout still fits.

## Existing Codex regression
- Confirm the specialization-icon row still works, including **Current** using the active spec icon.
- Confirm the left menu still fits.
- Open Gear Mentor and verify its Overview / Gear / Crafting / Sources / Trinkets / Upgrades tabs still work.

## Loadout Pilot handoff
- Confirm the existing **Open Loadout Pilot** action still works when Loadout Pilot is installed.
