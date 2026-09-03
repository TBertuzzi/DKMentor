# DK Mentor 3.1.0 — Validation Report

Date: **2026-09-01**
Target: **World of Warcraft Retail 12.1.0 / Interface 120100**

## Completed checks

- `scripts/validate.py` passed for DK Mentor **3.1.0** / Interface **120100**.
- Verified the TOC version, interface, SavedVariables metadata, and runtime file load order.
- Verified the 3.1 PreparationData integration and package-script inclusion.
- Verified static regression guards for Preparation / Ready Check, SBA-friendly Build Mentor, DKM31 preset import/export, Lich King portrait support, localization, Gear Mentor, Build Mentor, HUD edit safety, and existing 3.0 systems.
- Verified preset import remains bounded/data-only and does not use `loadstring` or `RunScript`.
- Built the game package successfully.
- Verified ZIP integrity with `unzip -t`.
- Verified the release archive has exactly one top-level `DKMentor` folder.
- Verified the release package contains no bundled `.ogg`, `.mp3`, `.wav`, `.flac`, `.m4a`, `.aac`, or `.opus` files.
- Re-checked the 3.1 data-audit sources on release day; see `DATA_AUDIT_v3.1.0.md`.

## Release archive

`DKMentor-v3.1.0-CurseForge.zip`

SHA-256:

`b8ed1f6b705fe1c5f3ea31c185c8d99e1a28d179418b91f679648b8ef6c34ea5`

## Environment limitations

This environment does not run the World of Warcraft client, so it cannot prove live-client behavior for protected combat restrictions, Blizzard item caching, localized native tooltips, model availability/framing, SavedVariables migration, or real UI scale.

The repository contains Lua smoke-test scripts, but this container does not currently provide a standalone `lua`/`luac` executable, so those scripts were not executed here. The project-level Python validator passed; live Retail testing remains required before public release.

## Live acceptance gate

Use `TESTING_v3.1.0.md` in Retail before publishing. In particular, confirm Preparation cards/readiness, Frost 2H/DW Runeforge detection, SBA-friendly ordering, preset round-trip/combat blocking, portrait lifecycle/fallback, EN/ptBR layout, and regression behavior on Blood/Frost/Unholy.
