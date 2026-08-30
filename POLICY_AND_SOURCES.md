# DK Mentor — Policy and Sources

## Gameplay automation boundary

DK Mentor is a display, guidance, and class-knowledge addon. It never casts combat abilities automatically.

Starting with 2.0, DK Mentor also does not automatically change the player's specialization, talent loadout, Equipment Set, or Loot Specialization. Those responsibilities belong to the separate Loadout Pilot addon. The optional DK Mentor integration only opens Loadout Pilot when it is already installed and loaded.

The manual specialization picker in the DK Status HUD is a direct player-initiated convenience. It never runs from context detection or automation.

## DK Ready Check

The DK Ready Check reads only player-owned class state required for its DK-specific checks: equipped weapon item links/permanent Runeforge IDs and the player's pet unit for the Unholy ghoul check. It does not inspect enemy combat state or trigger combat actions. Talent loadouts and equipment mappings are not readiness requirements in 2.0.

## DK Codex and Character Check

The Codex is advisory. It contains summarized/original guidance based on current public DK theorycraft/guide references and does not reproduce third-party guide prose or bundled talent import strings.

Character Check is read-only. It can inspect equipped item data, permanent enchant presence, sockets when readable, player secondary stats, and whether common DK utility spells are known/talented. It does not change gear, talents, gems, enchants, or abilities.

## Midnight 12.1 protected data

DK Mentor respects secret/protected values. It does not attempt to bypass Blizzard's restrictions.

Aura HUDs use Blizzard's native AuraContainer/AuraButton system. DK Mentor does not attach `OnShow`/`OnHide` handlers to protected AuraButtons and does not read AuraButton visibility to infer aura state. Its own decorative chrome is hidden during normal locked gameplay while Blizzard owns active aura-icon visibility.

Runic Power can be secret during combat. DK Mentor can pass that value into Blizzard's StatusBar rendering path but does not branch or make combat recommendations from an inaccessible numeric value.

## External references

Build/Codex source metadata points players to current public references such as Wowhead and Icy Veins. IceHUD was used only as a visual/architectural reference for the original DK Arcs concept; DK Mentor uses original code and project assets. See `THIRD_PARTY_NOTICES.md` for attribution notes.

## DK Mentor 3.0 research notes

The 3.0 feature direction was informed by public community discussions and current addon/guide patterns, while all implementation remains original to DK Mentor.

- RogueFlow inspired the high-level idea of separating live awareness from post-combat Overview / Timeline / Patterns review. No RogueFlow code or assets are included.
- Current DK-specific addon demand shows continued interest in compact Rune/Runic Power state, Death and Decay tracking, Unholy timing/reminder tools, and readable melee-range awareness.
- Blood 3.0 uses the player-owned Coagulating Blood aura (spell 463730) as the supported readable Death Strike recent-damage pool signal. It does not fabricate Blood Shield or hidden combat values.
- Unholy 3.0 guidance was updated for the Midnight Lesser Ghoul / Dark Transformation / Putrefy model. Dread Plague is kept conservative because current Midnight target-aura restrictions can make third-party tracking incomplete.
- Frost 3.0 does not use the pre-Midnight assumption that Breath of Sindragosa continuously drains Runic Power.
- Frost 12.1 action-bar coverage treats Soul Reaper as Unholy-only; current Frost 12.1 references note that Soul Reaper moved to the Unholy talent tree.

Public references used during 3.0 research included current Wowhead Death Knight guides/spell pages, Warcraft Wiki API documentation, current CurseForge DK utility addons, and public Reddit discussions. Third-party prose is summarized rather than copied.

## DK Mentor 3.0.9 interrupt presentation notes

The 3.0.9 action-bar glow is presentation-only and does not replace or relax the existing Midnight-safe interrupt detector.

- `C_ActionBar.FindSpellActionButtons` is used to discover direct Mind Freeze action slots outside combat.
- `GetActionInfo` and `GetMacroSpell` are used to recognize direct spell actions and macros whose current spell resolves to Mind Freeze.
- Blizzard's `ActionBarButtonEventsFrame.frames` registry is used to discover currently registered Blizzard action-button frames without taking ownership of Blizzard's native proc overlay.
- The custom cyan border is a DK Mentor-owned lightweight frame. DK Mentor does not call `ActionButton_ShowOverlayGlow` / `ActionButton_HideOverlayGlow`, avoiding interference with Blizzard proc highlights.
- Secret `notInterruptible` values are passed directly to `SetAlphaFromBoolean`; Lua does not branch on the protected boolean.
- Interrupt sound uses a single Blizzard-installed `SOUNDKIT.RAID_WARNING` sound when explicitly enabled. No external audio asset is bundled.
## DK Mentor 3.0.10 Gear Mentor notes

Gear Mentor is a read-only DK-specific gearing assistant. It does not equip items, spend currencies, purchase/craft items, apply gems/enchants, or change talent/loadout state.

The 3.0.10 dataset is separated in `GearData.lua` and records its patch/season review metadata. Current high-level target, trinket, crafting, and Crest guidance was summarized from current public Death Knight gearing references, primarily Icy Veins Blood/Frost/Unholy Season 2 gear guides, with item identity/source cross-checks against public WoW item data and current Blizzard tuning notes where relevant. GearPlanner and similar public addons informed the product idea of turning guide data into owned/equipped/target progress and farming sources; no third-party code or assets are included.

Priority labels such as VERY HIGH/HIGH describe farming value only. DK Mentor intentionally does not estimate an exact DPS percentage or claim that a listed target is guaranteed to upgrade the user's current character. Close choices remain simulation-dependent. Item names are requested from the WoW client by item ID when possible so Blizzard's localized names can be displayed.

The Rune ordering change is also presentation-only. DK Mentor sorts the six visible Rune indicators by current readable readiness/recharge progress to mimic Blizzard's stable visual pool; it does not choose which underlying Rune the game spends or alter regeneration.


## DK Mentor 3.0.12 tier-set notes

The Season 2 class-set panel uses the public Death Knight set identity **Baleful Grave-Knight's Crucible** (item set 2055) and its five canonical item IDs for visual references. Item/set names are resolved from the WoW client when available. Set-bonus summaries are intentionally short and do not replace Blizzard's native item tooltip; the tooltip remains the source of exact live percentages/effects.

Equipped tier detection reads the set ID returned by the WoW item API for the equipped item link, with canonical item-ID fallback. This is read-only and is intended to recognize equipped/catalyzed Season 2 tier pieces without changing them.

The set identity and current Season 2 bonus behavior were cross-checked against current Wowhead / Warcraft Wiki data, including the August 18, 2026 Frost 2-piece tuning hotfix. Current Icy Veins Blood/Frost/Unholy gearing pages remain the primary source for broader gearing and Catalyst guidance.
