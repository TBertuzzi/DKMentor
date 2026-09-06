# DK Mentor v3.2.0 — Validation r9

## Scope
Added a native Valeera companion configuration shortcut to the r8 Valeera / Delve Mentor.

## Implementation
- Loads `Blizzard_DelvesCompanionConfiguration` on demand.
- Opens `DelvesCompanionConfigurationFrame` through `ShowUIPanel`.
- Blocks the shortcut during combat.
- Keeps DK Mentor recommendation-only; role/Curio/poison changes remain in Blizzard's native UI.
- Added EN / ptBR localization and Valeera visual-pool cleanup for the new button.

## Validation targets
- Static validation includes the Blizzard addon/frame integration.
- Dedicated smoke test verifies addon loading, frame opening, and combat blocking.
- Existing Valeera data/preset smoke coverage remains intact.
