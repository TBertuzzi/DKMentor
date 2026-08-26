# DK Mentor

DK Mentor is a World of Warcraft Retail addon built specifically for **Blood, Frost, and Unholy Death Knights**.

**DK Mentor 2.0 is no longer just a Death Knight HUD: it is an adaptive combat coach built specifically for Blood, Frost, and Unholy.**

## DK Mentor 2.0

Version 2.0 focuses DK Mentor entirely on **Death Knight gameplay, guidance, and class-specific tools**.

Loadout automation has moved to the dedicated **Loadout Pilot** addon. DK Mentor no longer automatically changes specialization, talents, equipment, or Loot Specialization. Loadout Pilot is optional; when detected, DK Mentor can open it directly from Settings or `/dkm loadouts`.

## Features

- Blood, Frost, and Unholy specialization detection.
- World, Delve, Dungeon, Mythic+, Raid, and PvP context detection for guidance/HUD context.
- Blizzard Assisted Combat offensive highlighting.
- **Adaptive DK Coach** with Essential, Mentor, and Training modes.
- **Defensive Advisor** with readable player-health / recent health-loss pressure and spec-aware survival priorities, without reading Midnight's restricted combat log.
- Interrupt/Utility coaching for Mind Freeze plus possible Asphyxiate / Blinding Sleet / Death Grip stops.
- Resource/proc waste coaching for readable Runic Power, Runes, and important Blood/Frost/Unholy proc windows.
- **Combat Insights + DK Mentor Score** with a persistent last-combat summary and optional click-through post-combat popup.
- Compact DK Status HUD with specialization icon, detected content, and DK READY state.
- Manual Blood/Frost/Unholy specialization picker from the HUD icon.
- DK Ready Check for Death Knight Runeforge coverage and the Unholy ghoul when applicable.
- DK Codex with Overview, Builds, Rotation, Survival, Stats & Gear, Utility, and Character Check.
- Source-linked build recommendations without automatically creating/selecting WoW loadouts.
- Character Check for Runeforge/Ghoul, common enchants, sockets, live secondary stats, and DK utility.
- DK Buff Bar for important class buffs and procs.
- External Buff Bar for effects applied by other players/NPCs.
- Player Debuff Bar for harmful effects on your character.
- Ability Availability Bar for important cooldowns and charges.
- DK Resources HUD with six Runes and Runic Power.
- Optional DK Arcs resource layout.
- Mind Freeze interrupt alert for confirmed interruptible casts/channels, integrated with the Adaptive Coach.
- Adjustable HUD size, opacity, icon wrapping, positioning, Preview, and combat-only visibility.
- Release-candidate polish with Reset HUD positions, Reset Mentor settings, and an out-of-combat Test Alerts preview.
- English and Brazilian Portuguese interface.
- Optional Lich King commentary using sound resources already installed by WoW. No Blizzard audio files are bundled.

## Midnight 12.1 compatibility

DK Mentor respects World of Warcraft's protected and secret combat-value restrictions. It does not cast abilities automatically and does not attempt to bypass protected combat information.

Dynamic aura HUDs use Blizzard's native Retail AuraContainer system. DK Mentor does not inspect protected AuraButton visibility or attach show/hide handlers to those buttons.

## Loadout Pilot integration

Players who want automatic specialization, talent, equipment, Loot Specialization, or dungeon-specific loadout rules can use **Loadout Pilot**. DK Mentor detects the addon when loaded and provides a direct handoff, but there is no hard dependency between the two projects.

## Commands

- `/dkm` - Open DK Mentor.
- `/dkm codex` - Open the DK Codex.
- `/dkm builds` - Open Codex build recommendations.
- `/dkm loadouts` - Open Loadout Pilot when installed.
- `/dkm ready` - Run the DK Ready Check.
- `/dkm mentor` - Open Adaptive Coach / Combat Insights settings.
- `/dkm mentor essential|mentor|training` - Change coaching intensity.
- `/dkm mentor test|reset` - Preview alert visuals or restore Mentor defaults.
- `/dkm help` - Show the complete command list.

## License

MIT License.

DK Mentor is an independent community project and is not affiliated with or endorsed by Blizzard Entertainment, Wowhead, Icy Veins, IceHUD.

---

## ☕ Support the Project

DK Mentor is free and open source.

If you enjoy the addon and want to support its development:

**Buy me a coffee:** https://buymeacoffee.com/bertuzzi
