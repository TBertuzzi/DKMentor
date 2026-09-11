# Validation report — DK Mentor 1.0.10

Target: World of Warcraft Retail 12.1.0 / Interface 120100

- Version metadata synchronized.
- War Mode experiment remains absent.
- Automatic-only runtime context remains enabled.
- Added a secret-boolean accessibility helper based on the existing secret-value guards.
- Replaced the reported direct `UnitIsAFK("player") == true` comparison.
- Audited related Unit boolean reads used by Ready Check, mounting, pet voice, and combat-status helpers.
- Package integrity and project validator must pass before release files are generated.
