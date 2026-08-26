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
