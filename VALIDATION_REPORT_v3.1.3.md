# Validation Report — DK Mentor 3.1.3

Date: 2026-09-01

## Static validation
- `python3 scripts/validate.py` passed for DK Mentor **3.1.3** / Retail interface **120100**.
- `Core.lua` remains at **185 chunk-level locals**, below the project's <=190 safety guard and WoW/Lua's 200-local ceiling.
- Version metadata matches between `DKMentor.toc` and `Data.lua`.
- SavedVariables schema advanced to **33** and defaults existing users to **Arthas** unless Bolvar is explicitly selected.

## 3.1.3 portrait selector review
- Arthas portrait uses in-client creature ID **36597**.
- Bolvar-as-Lich-King portrait uses in-client creature ID **95942**.
- The selected character is persisted in `DB.voice.portrait.character`.
- Settings UI cycles between Arthas and Bolvar.
- `/dkm voice portrait arthas|bolvar` updates the same setting.
- The animated portrait refreshes its creature model and title from the current selection.
- Existing talking-animation logic remains guarded by `HasAnimation` when available, so unsupported animation states fail safely.
- `DKM31` layout export appends the portrait character; import accepts it when present and remains compatible with older 3.1 strings that do not contain the new field.

## Package integrity
- CurseForge/runtime ZIP contains a single top-level `DKMentor/` folder.
- ZIP integrity check passed.
- Runtime package contains **0** bundled `.ogg`, `.mp3`, `.wav`, `.flac`, `.m4a`, `.aac`, or `.opus` files.
- No Blizzard model or texture files were added; portrait models are referenced from the installed WoW client.

## Live-client requirement
This environment cannot launch World of Warcraft Retail. Before publishing, use `TESTING_v3.1.3.md` to confirm that creature ID 95942 renders the intended Bolvar-as-Lich-King appearance in the live 12.1.0 client and that its available talking animation looks acceptable. Arthas/Bolvar selection, persistence, preset round-trip, 3.1.2 Preparation fixes, and Frost dual-wield Runeforge guidance should all be re-tested in game.
