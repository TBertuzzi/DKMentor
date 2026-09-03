# DK Mentor 2.0.8 validation report

Validated against Retail interface `120100`.

## Automated checks

- `Localization.lua`, `Data.lua`, `Builds.lua`, `Guides.lua`, `Codex.lua`, `Voices.lua`, `Core.lua`, and `MentorEngine.lua` parse successfully with `texluac -p`.
- `python3 scripts/validate.py` passes for version 2.0.8.
- `tests/codex_smoke.lua` passes.
- `tests/mentor_engine_smoke.lua` passes.
- Validator includes explicit regression guards for the dynamic post-combat card: 300-480 px bounds, maximum three visible insights, rendered text-height sizing, and the dynamic layout call from `Engine.ShowPostCombat`.
- Existing Midnight guards remain active, including the ban on `COMBAT_LOG_EVENT_UNFILTERED` / combat automation APIs and protected AuraButton visibility hooks.

## 2.0.8 behavior checked in source

- Post-combat popup no longer uses the fixed `500 x 116` size.
- Initial card is compact and is resized every time a report is shown.
- Width is derived from the rendered score/insight text, capped at 480 UI pixels and relative to current UI width.
- Height is derived from wrapped FontString height.
- Up to three report insights are displayed; additional observations are collapsed into the last visible line as `(+N more)` / `(+N a mais)`.
- Popup remains mouse-transparent and keeps the existing 12-second auto-hide behavior.
- Full report remains available in Adaptive DK Coach / `/dkm insights`.
- SavedVariables schema remains 29.

## Live verification still required

The WoW client must still be used to verify exact visual sizing under the player's UI scale, PT-BR wrapping, and the transition between one-, two-, and three-insight cards.
