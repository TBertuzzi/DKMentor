# DK Mentor 3.3.1 - Test r1 Checklist

Base: published **3.3.0 / Source r11**. This patch changes guidance data and version metadata; it does not introduce a new major feature system.

## 1. Version and load

1. Confirm the AddOns list reports **DK Mentor 3.3.1**.
2. Confirm Retail Interface remains **120100**.
3. Log in on Blood, Frost, and Unholy and confirm the addon loads without Lua errors.

## 2. Valeera presets

1. Open `/dkm valeera`.
2. Confirm the preset selector contains **Nemesis / Azta'rec** and the existing High Tier entry is described as **Hard Delves**.
3. On Blood, Frost, and Unholy, select Nemesis and confirm:
   - Role: Healer
   - Combat Curio: Corrosive Bilespear
   - Utility Curio: Soul-Cracking Dreamcatcher
   - Poison: Phantasmal Spore Toxin
4. Confirm the detail text mentions Soulthirst Venom as an alternative.
5. Confirm changing away from Nemesis and back persists the preset correctly.

## 3. Unholy Preparation

1. Open Unholy Equipment > Preparation.
2. Confirm the existing primary recommendations still appear.
3. Confirm the new alternatives are represented:
   - Powerful Eversong Diamond
   - Flask of the Blood Knights
   - Refulgent Whetstone
   - Refulgent Weightstone
4. Confirm Ready Check remains advisory and does not treat optional alternatives as mandatory failures.

## 4. Unholy PvP

1. Open Unholy Builds > PvP.
2. Confirm Pet / Rider of the Apocalypse is marked **Recommended**.
3. Confirm Disease / San'layn is marked **Alternative**.
4. Confirm the source note explains that the current Icy Veins page contains contradictory ranking text.

## 5. Regression

- Visual Talent Tree, Saved/Export/Clone, Meta Pulse, Gear Mentor, Stats/Folio, HUDs, Survival Coach, interrupts, Lich King commentary, and Character Check should behave exactly as in the published 3.3.0 baseline.
- No automatic talent, gear, Valeera, consumable, or combat action should be introduced.
