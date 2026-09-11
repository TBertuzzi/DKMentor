
## 3.3.0 Test r10 - Build source audit (2026-09-09)

- Re-audited Blood, Frost and Unholy PvE build profiles by context against current Wowhead guidance.
- Removed the generic per-spec tree-marker assignment that caused Delve/Open World comparisons to inherit Raid/Mythic+ markers.
- Added context-specific, derived and Hero-only coverage modes.
- Frost Delves now validates Deathbringer only until an exact current Delve import is embedded.
- Unholy Raid/Open World no longer reuse Mythic+ AoE markers.
- Renamed `Create in WoW` to `Clone in WoW` so the UI accurately describes the current behavior.
- Build data reviewed date: 2026-09-09.

# DK Mentor 3.3.0 - Release Notes Draft (Test r8)

## DK Meta Pulse

Adds a new DK Meta Pulse section for Heroic Raid, Mythic+ +7 to +20, and High Keys using reviewed Archon.gg / Warcraft Logs-derived observed data.

The Meta Pulse shows Hero Talent usage, alternatives, sample size, observed build-performance snapshots, observed weapon usage, and a Guide vs Logs comparison for Blood, Frost and Unholy. Blood is treated separately as the tank signal.

## Guide vs Logs identity

Hero Talent comparison uses stable spell IDs only. English Archon labels and localized DK Mentor labels cannot create false divergence. Names are display text only.

External aggregate providers must also provide stable Hero Talent IDs; otherwise DK Mentor safely falls back to its built-in snapshot.

## Optional Archon integration

DK Mentor detects the Archon Tooltip core addon and known regional `ArchonTooltipDB_*` modules.

The Meta header explicitly shows the active data source, Archon detection state, DB-module detection, and whether a compatible aggregate Meta feed is available. If Archon is installed but its current dataset does not expose the aggregate spec/build/gear Meta feed DK Mentor needs, the addon keeps using the reviewed built-in snapshot.

DK Mentor does not make web requests from inside WoW and does not depend on private `ArchonTooltipPrivate` internals.

## Visual Talent Tree Mentor

Build Mentor now adds a read-only visual tree beneath the primary recommended profile.

- Uses Blizzard's live `C_Traits` / `C_ClassTalents` tree structure, positions, connections, spell icons and tooltips.
- Shows **Class**, **Hero**, and **Specialization** trees without bundling third-party artwork.
- Uses curated stable spell IDs for guide-defining nodes rather than comparing localized talent names.
- **Gold** = recommended guide node not selected.
- **Green** = recommended guide node already selected.
- **Blue** = selected talent that is not being claimed as a mandatory guide node.
- **Gray** = other/flex/pathing node.
- Choice-node mismatches are labeled **SWAP / TROCAR**.
- Hovering a recommended node adds a short **Why / Por quê** explanation on top of the native spell tooltip.
- Current-spec builds compare against the active loadout. Other DK specs use the last saved loadout when available, with a Blizzard view-only config fallback.
- The tree never silently purchases/refunds individual talent points or switches the active build. Direct loadout creation is a separate explicit action that imports a complete string into a new saved Blizzard config without auto-activating it.

The r5/r6 dataset intentionally marks verified guide-defining nodes instead of pretending DK Mentor contains a copied point-for-point Wowhead import string. This keeps the feature useful while preserving flex/pathing choices and avoiding stale cloned trees.

### r8 stable-ID mapping + direct Blizzard loadout creation

The live r7 test exposed an important Blizzard trait-model detail behind false `3/5` key-node counts: Hero Talent selection is represented by a **SubTreeSelection / subTreeID**, and selected choice/subtree nodes can report rank `0`. r8 therefore removes talent names from matching logic entirely.

- Guide matching now uses stable `nodeID`, `entryID`, `spellID`/override aliases, and Hero `subTreeID`. Localized names are display-only.
- Hero Talent selection is counted by the selected subtree entry even when Blizzard reports rank `0`.
- Choice nodes are counted by selected `entryID`, so a localized label or rank-zero choice can no longer turn an aligned build into a false mismatch.
- Frost's current Frostreaper / Smothering Offense / Frostscythe / Glacial Advance markers keep stable ID aliases for the live 12.1 spell variants.

r8 also extends the r7 Export / Save / Saved controls with **Create in WoW**:

- When the current Blizzard loadout is fully aligned with all mapped DK Mentor key nodes, **Create in WoW** generates the complete Blizzard import string and creates a new saved Blizzard talent loadout directly.
- The generated loadout preserves all of the player's current flex/pathing points; DK Mentor does not synthesize missing guide points or silently spend/refund talent points.
- Saved DK Mentor snapshots also gain **Create**, allowing a stored full Blizzard import string to be recreated directly in the native Talents loadout list.
- New loadout names are duplicate-safe, such as `DKM Frost M+ DB`, `DKM Frost M+ DB 2`, and so on.
- Creating a loadout is an explicit out-of-combat user action and does **not** activate the new loadout automatically.
- Browsing another specialization remains read-only; direct creation/export requires switching to that specialization first so Blizzard uses the correct loadout header.

### r7 alignment + export/save pass

Live testing showed that the Hero subtree selector and the first Hero node could inherit slightly different Blizzard X coordinates even though they visually form one vertical spine. r7 normalizes the first two singleton Hero rows to a shared center without altering the underlying trait data.

The visual tree also gained explicit loadout portability:

- **Export** generates Blizzard's import string for the active/compared loadout through `C_Traits.GenerateImportString`.
- **Save** stores that import string in `DKMentorDB` together with specialization, Hero Talent ID, guide-review metadata, and the guide-key spell IDs shown when the snapshot was saved.
- **Saved** opens the in-addon snapshot library.
- Gold guide nodes that are not already selected are never silently inserted into an exported snapshot.

### r6 layout pass

The live-client r5 test showed that Blizzard's tall trait graph was being squeezed because one uniform scale was shared by both axes. r6 expands the tree canvas from 352 to 540 UI units, increases internal padding, gives Class/Spec trees more horizontal room, and fits X/Y independently. The result keeps the same node size while creating substantially more space between rows and columns.

Current PvE key-node refresh includes the reviewed Blood direction, Frost's current Frostreaper / Smothering Offense / Frostscythe / Glacial Advance direction, and current Unholy disease/minion nodes with a separate Blightfall marker for San'layn.


### r9 guide-key diagnostics

Live r8 testing showed a `4/5 found - 4 selected` state that was technically accurate but poor UX: the player could not tell which guide key failed or whether the problem was their build or DK Mentor's mapping. r9 makes that explicit.

- The build-tree header now shows mapped and selected counts separately.
- A colored per-key diagnostic line names every guide key and marks it as **OK**, **MISSING**, **SWAP**, or **NOT MAPPED**.
- **NOT MAPPED** is explicitly treated as a DK Mentor guide-data mapping issue, not evidence that the player's talent selection is wrong.
- The disabled **Create in WoW** tooltip names the exact blocker.
- Matching remains ID-only; localized names are display text and never drive comparison.
- Header spacing and title copy were simplified so the diagnostic remains readable above the tree.

## UI polish

- Codex sidebar uses distinct native Blizzard icons for Overview, Stats & Folio, Equipment, Builds, Meta, Valeera, Rotation, Survival, Utility and Character Check.
- More room for localized Guide vs Logs text.
- DPS is labeled as an observed build snapshot.
- Weapon percentages are labeled as observed usage rather than BiS recommendations.

## Also included

- Valeera Leveling preset validation fix discovered during 3.3 testing.
