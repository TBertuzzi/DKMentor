#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = "1.0.9"
INTERFACE = "120100"

REQUIRED = [
    "DKMentor.toc", "Localization.lua", "Data.lua", "Builds.lua", "Guides.lua",
    "Voices.lua", "Core.lua", "README.md", "CHANGELOG.md", "LICENSE",
    "THIRD_PARTY_NOTICES.md", "POLICY_AND_SOURCES.md", "PUBLISHING.md",
]

ADDON_LUA = ["Localization.lua", "Data.lua", "Builds.lua", "Guides.lua", "Voices.lua", "Core.lua"]


def parse_toc(text: str):
    meta, order = {}, []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        m = re.match(r"^##\s*([^:]+):\s*(.*)$", line)
        if m:
            meta[m.group(1).strip()] = m.group(2).strip()
        elif not line.startswith("#"):
            order.append(line)
    return meta, order


def main() -> int:
    errors: list[str] = []
    for rel in REQUIRED:
        if not (ROOT / rel).is_file():
            errors.append(f"Missing required file: {rel}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1

    toc = (ROOT / "DKMentor.toc").read_text(encoding="utf-8")
    meta, order = parse_toc(toc)
    expected = {
        "Interface": INTERFACE,
        "Title": "DK Mentor",
        "Author": "Thiago Bertuzzi",
        "Version": VERSION,
        "SavedVariables": "DKMentorDB",
        "X-License": "MIT",
    }
    for key, value in expected.items():
        if meta.get(key) != value:
            errors.append(f"TOC {key}: expected {value!r}, got {meta.get(key)!r}")

    if order != ADDON_LUA:
        errors.append(f"TOC load order mismatch: {order!r}")

    data = (ROOT / "Data.lua").read_text(encoding="utf-8")
    if f'Data.version = "{VERSION}"' not in data:
        errors.append("Data.version does not match release version")
    if f"Data.interface = {INTERFACE}" not in data:
        errors.append("Data.interface does not match TOC Interface")

    builds = (ROOT / "Builds.lua").read_text(encoding="utf-8")
    if re.search(r'code\s*=\s*"[^"\s]{20,}"', builds):
        errors.append("Builds.lua appears to bundle a talent import string")

    forbidden_ext = {".ogg", ".mp3", ".wav", ".flac", ".m4a"}
    for p in ROOT.rglob("*"):
        if p.is_file() and p.suffix.lower() in forbidden_ext:
            errors.append(f"Bundled audio is not allowed: {p.relative_to(ROOT)}")
        if p.is_file() and p.name.endswith(".bak"):
            errors.append(f"Backup file must not be committed: {p.relative_to(ROOT)}")

    if "## 1.0.9" not in (ROOT / "CHANGELOG.md").read_text(encoding="utf-8"):
        errors.append("CHANGELOG.md has no 1.0.9 entry")

    core = (ROOT / "Core.lua").read_text(encoding="utf-8")
    localization = (ROOT / "Localization.lua").read_text(encoding="utf-8")
    if "function addon:GetReadyCheckStatus()" not in core:
        errors.append("Core.lua is missing DK Ready Check")
    if "Data.runeforges" not in data:
        errors.append("Data.lua is missing Runeforge metadata")
    for enchant_id in (3368, 3370, 3847, 6241, 6242, 6243, 6244, 6245):
        if f"[{enchant_id}]" not in data:
            errors.append(f"Missing DK Runeforge enchant ID {enchant_id}")
    if 'command == "ready"' not in core:
        errors.append("/dkm ready command is missing")
    if 'P("DK READY", "DK PRONTO")' not in localization:
        errors.append("Ready Check ptBR localization is missing")

    forbidden_combat_calls = (
        "CastSpellByName", "CastSpellByID", "RunMacroText", "UseAction",
        "UseContainerItem", "PickupSpell", "TargetUnit", "AttackTarget",
    )
    for api_name in forbidden_combat_calls:
        if api_name in core:
            errors.append(f"Potential combat-automation API must not be used: {api_name}")


    # 1.0.9 regression guards: runtime context must be automatic-only and War Mode experiment absent.
    if 'function addon:DetectContext()' not in core or 'return self:DetectActualContext(), true' not in core:
        errors.append("Automatic-only runtime context detection is missing")
    if 'DB.modeOverride = "auto"' not in core:
        errors.append("Legacy modeOverride migration is missing")
    if 'contexts = { "world", "delve", "dungeon", "raid", "pvp" }' not in core:
        errors.append("Expected World/Delve/Dungeon/Raid/PvP selector set is missing")
    for forbidden_warmode in ("UpdateWarModeButton", "ToggleWarMode", "SetWarModeDesired", "warModeButton", "warmode ="):
        if forbidden_warmode in core:
            errors.append(f"Experimental War Mode logic must not be present: {forbidden_warmode}")

    if errors:
        print("Validation failed:", file=sys.stderr)
        print("\n".join(f"- {e}" for e in errors), file=sys.stderr)
        return 1

    print(f"Validation passed: DK Mentor {VERSION}, Retail interface {INTERFACE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
