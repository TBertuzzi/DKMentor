# Policy and sources

## Combat behavior

DK Mentor is a guidance and display addon. It does not cast abilities, perform protected actions automatically, or attempt to bypass Blizzard's protected/secret combat-value system.

Offensive recommendations come from Blizzard Assisted Combat when the game exposes them. Survival guidance is advisory. Dynamic player aura HUDs use Blizzard-owned Retail aura-container mechanisms where available.

The DK Ready Check reads only player-owned/configuration state: the selected saved talent loadout, mapped Equipment Set status, equipped weapon item links for permanent Runeforge IDs, and the player pet unit for the Unholy ghoul check. It does not inspect enemy combat state or trigger combat actions.

Runeforge Guard recognizes public Death Knight Runeforge enchant/spell identifiers. It validates that a DK Runeforge is present on each equipped weapon and deliberately does not declare a single rune universally optimal across all builds or encounters.

## Third-party build sources

DK Mentor links to public Wowhead PvE Death Knight talent guides and public Icy Veins PvP guides where appropriate. The addon stores source name, author, reviewed patch/date, and URL alongside short original summaries.

No third-party guide prose, artwork, page layout, addon code, or talent import strings are bundled.

## Audio

Optional Lich King commentary references numeric sound resources already installed by the WoW client. The repository and release archives must never contain extracted Blizzard `.ogg`, `.mp3`, `.wav`, or other game-audio files, nor copied dialogue transcripts.

## Trademarks

World of Warcraft, Warcraft, the Lich King, and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc. Wowhead and Icy Veins are third-party services. DK Mentor is not affiliated with or endorsed by Blizzard Entertainment, Wowhead, or Icy Veins.

## DK resource HUD

The DK Resources HUD is display-only. It uses the public six-Rune cooldown API for Rune recharge presentation. Runic Power is treated as a potentially secret primary resource during combat: DK Mentor forwards the value into Blizzard's native `StatusBar:SetValue` / `SetMinMaxValues` rendering path and does not compare, threshold, score, or select abilities from the hidden value. Resource layout changes and Preview/position resets are blocked during combat so a status bar that has received a secret value is not re-anchored while restricted.

