# DK Mentor 2.0.0 — Development Release Notes

## A focused DK Mentor

DK Mentor 2.0 is a major responsibility split. DK Mentor now focuses entirely on Death Knight gameplay, class guidance, HUDs, readiness, resources, and the DK Codex.

### Loadout automation moved to Loadout Pilot

Removed from DK Mentor's active runtime/UI:

- automatic specialization switching;
- automatic talent-loadout switching/import management;
- automatic Equipment Set switching;
- Loot Specialization automation;
- Dungeon Overrides and per-dungeon loadout rules;
- Loadouts main tab and native loadout/equipment picker UI.

Players who want those features can use the dedicated **Loadout Pilot** addon. DK Mentor can detect and open Loadout Pilot from Settings, the Codex Builds section, or `/dkm loadouts`.

### DK Codex Builds

Build recommendations now live in **DK Codex → Builds**. Recommendations are content-aware and source-linked, but they do not create, select, import, overwrite, or switch WoW talent loadouts.

### Cleaner main UI

The main navigation is now:

- Combat
- DK Codex
- Settings

### DK Status HUD

The compact status widget now focuses on DK information:

- specialization icon;
- detected content;
- DK READY state.

Left-clicking the specialization icon remains a manual Blood/Frost/Unholy picker. Right-clicking the widget opens/closes DK Mentor.

### DK Ready and Character Check

DK Ready no longer evaluates mapped talent loadouts or Equipment Sets. It focuses on DK-specific readiness: Runeforge coverage and the Unholy ghoul when applicable.

Character Check remains read-only and covers class/setup hygiene such as Runeforge/Ghoul, common permanent enchants, sockets, current secondary-stat snapshot, and known/talented utility.

### Upgrade safety

- Database schema remains **29**; no new migration was introduced for this responsibility split.
- Existing 1.x loadout mapping data is preserved in SavedVariables for rollback safety but is not used by DK Mentor 2.0.
- Legacy auto-switch flags are forced off during initialization.
- Existing HUD positions, language, combat-bar settings, DK Resources, DK Arcs, voice settings, and Codex preferences are preserved through normal defaults/migrations.

### Midnight 12.1 safeguards preserved

The 2.0 branch keeps the AuraContainer secret-aspect fix: DK Mentor never hooks protected AuraButton show/hide scripts or reads their visibility to infer aura state.
