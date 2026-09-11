# DK Mentor 3.0.13 — Gear Mentor Readability Hotfix

DK Mentor 3.0.13 is a focused follow-up to 3.0.12 after live-client feedback.

## What changed

### 1) Gear Mentor text is no longer washed out inside panels
The descriptive text in **Melhorias**, **Berloques**, **Fontes**, and the lower **Direção de atributos** panel was still looking faint in-game.

Root cause: those font strings were being created on the Gear Mentor root frame while being visually placed over child panel frames. In WoW, child frames render above the parent frame's regions, so the panel backdrop was visually sitting over the text and muting it.

3.0.13 fixes this by parenting those texts directly to each panel.

### 2) Slight contrast boost for helper text
The source note and stat snapshot lines were also brightened a little so the information reads more cleanly against the dark panel treatment.

### 3) Tooltip cleanup from 3.0.12 remains intact
The 3.0.12 tooltip lifecycle fix remains in place.

## Practical result
You should now see normal, readable text in:
- **Melhorias / Upgrade plan**
- **Berloques / Quick guidance**
- **Fontes / Loot sources**
- **Direção de atributos**
- **Season 2 tier set** panel text

## Version
- DK Mentor: **3.0.13**
- Retail Interface: **120100**
