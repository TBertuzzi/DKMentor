# DK Mentor 3.3.2 - Post-Tuning Guidance Audit

**Reviewed:** 2026-09-24  
**Live target:** World of Warcraft Retail 12.1.0 / Interface 120100  
**Comparison baseline:** published DK Mentor 3.3.1 (2026-09-11)

## Decision

A 3.3.2 guidance refresh is warranted. The September 22 Death Knight tuning materially changed Blood Deathbringer, Frost single-target/two-target throughput, Unholy San'layn/Blightfall, and Unholy San'layn PvP. The September 23 hotfix then corrected a Blightfall damage bug and a Valeera faction-change state bug.

The current third-party talent pages have **not** all consolidated those changes yet. DK Mentor therefore updates the facts and review state without inventing a new best build or importing an unverified talent string.

## Blizzard changes after the 3.3.1 baseline

### September 22 - Blood

Blizzard reduced all Blood ability/minion damage by 6%, increased Death Strike damage by 15%, and reduced Deadly Reach cleave from 75% to 60%. Deathbringer then received targeted buffs: Exterminate +25%, Reaper's Mark +20%, Wave of Souls +20%, Bind in Darkness Blood Boil bonus 30% -> 50%, Deathly Blows Death Strike bonus 12% -> 20%, and Swift and Painful Strength bonus 10% -> 15%.

Blizzard explicitly described the goal as lowering excessive San'layn AoE while making Deathbringer a small net positive in both AoE and single target.

**DK Mentor action:**
- Keep Deathbringer as the low-friction Mythic+ default.
- Keep the September 21 Wowhead San'layn raid recommendation as the last published guide-backed default, but label the whole Blood PvE ranking **REVIEW PENDING**.
- Rewrite the Raid/Deathbringer note to make clear that it is now a serious post-tuning single-target re-evaluation candidate.
- Do not change the existing Blood tree markers or fabricate a new import string.

Source: https://news.blizzard.com/en-gb/article/24296142/hotfixes-september-23-2026

### September 22 - Frost

Frostreaper damage increased by 100% and Obliterate damage increased by 10%; both changes explicitly do not apply to PvP.

**DK Mentor action:**
- Keep existing Deathbringer/Rider recommendations until the Wowhead talent page is updated after the tuning.
- Keep the current Frostscythe at 2+ targets and Glacial Advance at 3+ targets markers because the current guide still documents those thresholds and Blizzard did not change those mechanics.
- Mark Frost PvE build ranking **REVIEW PENDING**.
- Keep Frost PvP guidance current because these two buffs explicitly do not apply in PvP.

Sources:
- https://news.blizzard.com/en-gb/article/24296142/hotfixes-september-23-2026
- https://www.wowhead.com/guide/classes/death-knight/frost/talent-builds-pve-dps

### September 22 - Unholy PvE

Blizzard stated that it wanted to increase Unholy raid damage and bring the Blightfall build back after previous fixes had made it non-viable. Changes included Scourging plague eruptions to 65%/100% from 50%/70%, Blightfall to 200% of remaining plague damage from 100%, Infliction of Sorrow to 75% from 30%, Thrill of Blood Dread Plague bonus to 20% from 10%, and Frenzied Bloodthirst increasing Death Coil/Death Strike by 5% per stack.

### September 23 - Unholy Blightfall hotfix

Blizzard fixed Blightfall doing less damage as more time passed since the plague was applied. Wowhead's post-hotfix analysis estimated this fix alone as roughly +12% single target and +6% AoE for the affected Unholy profile, but those figures are an external estimate, not Blizzard tuning values.

The Wowhead Unholy **rotation** page is now dated September 23 and exposes both Rider and San'layn setup paths with Blightfall present. The Wowhead **talent-build** page is still dated September 5.

**DK Mentor action:**
- Keep Rider as the provisional Recommended raid profile because it is the last published talent-page baseline.
- Add **Unholy - Single Target / San'layn Blightfall** as a visible Alternative/review candidate.
- Add Blightfall to the visible key-talents row for San'layn Delve/Mythic+ and raid review profiles.
- Strengthen Delve/Mythic+ San'layn wording to reflect the real post-hotfix change.
- Mark Unholy PvE build ranking **REVIEW PENDING**.
- Do not replace full talent imports: DK Mentor 3.3.x intentionally does not embed unverified third-party import strings.

Sources:
- https://news.blizzard.com/en-gb/article/24296142/hotfixes-september-23-2026
- https://www.wowhead.com/guide/classes/death-knight/unholy/talent-builds-pve-dps
- https://www.wowhead.com/guide/classes/death-knight/unholy/rotation-cooldowns-pve-dps
- https://www.wowhead.com/news/massive-buff-to-unholy-dks-due-to-bug-fix-patch-12-1-hotfixes-for-september-23rd-383075

### September 22 - Unholy PvP San'layn

Blizzard explicitly said it wanted San'layn to be more viable for Unholy in PvP. Inevitable's missing-health plague bonus ceiling increased from 30% to 60% in PvP, and Vampiric Strike damage increased by 100% in PvP.

The Icy Veins Unholy PvP talent page remains dated August 10. It still has the known contradiction: its page heading labels Disease as Best 3v3 while the detailed Disease section says Disease is currently weaker than Pet.

**DK Mentor action:**
- Keep Pet/Rider as **provisional Recommended**, because that matches the last detailed guide explanation.
- Keep Disease/San'layn as **Alternative**, but explicitly call out the direct September 22 PvP buffs.
- Mark the Unholy PvP source **REVIEW PENDING** until Icy Veins publishes a post-tuning update.
- Do not silently flip the recommendation based only on tuning magnitude.

Sources:
- https://news.blizzard.com/en-gb/article/24296142/hotfixes-september-23-2026
- https://www.icy-veins.com/wow/unholy-death-knight-pvp-talents-and-builds

## Current guide audit

### Blood PvE

Wowhead talent page: updated **2026-09-21**, one day before the tuning. It still presents the San'layn throughput path when Dancing Rune Weapon is available while acknowledging Deathbringer's defensive/ease-of-play benefits.

**Result:** source date corrected in DK Mentor from the older embedded date to 2026-09-21; ranking flagged for post-tuning review.

### Frost PvE

Wowhead talent page: updated **2026-09-05**, before September 22. The documented Raid/Delve Deathbringer direction and the 2+ Frostscythe / 3+ Glacial Advance thresholds remain the last published guide direction.

**Result:** no forced build swap; ranking flagged for review.

### Unholy PvE

Wowhead talent page: updated **2026-09-05**, before September 22/23. It still exposes two Mythic+ build families. The rotation page was updated **2026-09-23** and now visibly includes the San'layn/Blightfall setup path.

**Result:** add the San'layn Blightfall raid alternative and refresh wording, but keep the published recommendation provisional.

## Gear, trinkets, crafting, tier and stats

Rechecked the guide pages used by 3.3.1. There is no post-September-22 page change that requires replacing DK Mentor's existing gear targets, trinket pairings, crafting targets, tier-set text, Catalyst priorities, runeforges, consumables, or stat-priority direction.

Current relevant guide dates remain:
- Blood gear: 2026-08-20.
- Frost gear: 2026-09-02.
- Unholy gear: 2026-09-08.
- Frost stats: 2026-08-12.
- Unholy stats: 2026-08-17.
- Unholy consumables: the September 10 refresh was already captured by 3.3.1.

**DK Mentor action:** advance local review dates to 2026-09-24 and explicitly state that the audit found no replacement guidance. Do not churn item targets merely because class tuning happened.

Sources:
- https://www.wowhead.com/guide/classes/death-knight/blood/bis-gear
- https://www.wowhead.com/guide/classes/death-knight/frost/bis-gear
- https://www.wowhead.com/guide/classes/death-knight/unholy/bis-gear
- https://www.wowhead.com/guide/classes/death-knight/blood/stat-priority-pve-tank
- https://www.wowhead.com/guide/classes/death-knight/frost/stat-priority-pve-dps
- https://www.wowhead.com/guide/classes/death-knight/unholy/stat-priority-pve-dps

## Valeera / Delves audit

Current Icy Veins Valeera guidance still uses Corrosive Bilespear + Soul-Cracking Dreamcatcher as the general Curio combination for all three roles. Current Azta'rec guidance still supports Healer Valeera for tank/DPS characters, matching the dedicated DK Mentor Nemesis preset. Season 2 still allows an independent poison choice with six poisons.

On September 23, Blizzard fixed a bug where Valeera could become unable to change talents or gain abilities after a faction change. Affected characters should enter a Delve, leave it, and log out once to recover the state.

**DK Mentor action:**
- Keep all current role/Curio/poison/Nemesis presets unchanged.
- Add the September 23 faction-change recovery fix to the live-hotfix panel.
- Treat it as troubleshooting guidance, not a new Valeera build.

Sources:
- https://www.icy-veins.com/wow/valeera-sanguinar-delve-companion-guide
- https://www.icy-veins.com/wow/aztarec-delve-guide
- https://www.wowhead.com/guide/midnight/delves-season-2-nemesis-boss-aztarec
- https://news.blizzard.com/en-gb/article/24296142/hotfixes-september-23-2026

## Files changed for 3.3.2

Runtime/data:
- `DKMentor.toc`
- `Data.lua`
- `Builds.lua`
- `GearData.lua`
- `PreparationData.lua`
- `AdvisorData.lua`
- `ValeeraData.lua`
- `Localization.lua`

Validation/docs:
- `scripts/validate.py`
- `tests/guidance_refresh_332_smoke.lua`
- historical regression smokes updated so review dates may advance without false failures
- `CHANGELOG.md`
- `PUBLISHING.md`
- `RELEASE_NOTES_v3.3.2.md`
- `CURSEFORGE_CHANGELOG_v3.3.2.md`
- `TESTING_v3.3.2.md`
- `VALIDATION_REPORT_v3.3.2.md`

## Intentionally unchanged

- Patch target remains 12.1.0 / Interface 120100.
- No combat engine, HUD, Talent Tree clone/snapshot, Survival Coach, Meta Pulse provider, or Loadout Pilot handoff change.
- No new embedded third-party talent import strings.
- No gear/trinket/crafting/tier/stat replacement.
- No Valeera role/Curio/poison preset replacement.
