# DK Mentor v3.2.0 – Validation Report (r7)

## Scope
Validation of the Frost weapon-guidance correction and the new in-addon Omnium Folio quick editor.

## Static/runtime validation
- All runtime Lua files compiled successfully with `texluac -p`.
- `python3 scripts/validate.py` passed.
- All existing smoke tests passed, including the expanded 3.2 Advisor/Gear smoke test.

## New static coverage
The 3.2 Advisor smoke test now checks for:
- `GetOmniumFolioRuntimeRows`
- `ApplyDKAdvisorFolioDraft`
- `C_Traits.SetSelection`
- `C_Traits.CommitConfig`
- Folio quick-editor integration
- Aman'muso as Main Hand
- Jaw of the Shackled Goddess as Off Hand
- 2H Breathbane Runeforge support

## Safety behavior
The Folio apply routine:
- refuses to run in combat;
- refuses to overwrite a config that already has staged changes;
- uses `C_Traits.SetSelection` for the edited Folio rows;
- uses `C_Traits.CommitConfig` to apply the staged selections;
- rolls back staged changes if a row cannot be staged or the commit fails;
- does not auto-apply on context/spec changes.

## Result
Offline validation passed. The remaining required validation is the live Retail 12.1.0 test of the generic trait configuration on tree 1186, especially the final Apply Folio operation.
