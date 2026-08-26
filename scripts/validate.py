#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = "2.0.11"
INTERFACE = "120100"

RUNTIME_LUA = ["Localization.lua", "Data.lua", "Builds.lua", "Guides.lua", "Codex.lua", "Voices.lua", "Core.lua", "MentorEngine.lua"]
REQUIRED = [
    "DKMentor.toc", *RUNTIME_LUA, "README.md", "CHANGELOG.md", "LICENSE",
    "THIRD_PARTY_NOTICES.md", "POLICY_AND_SOURCES.md", "PUBLISHING.md",
    "RELEASE_NOTES_v2.0.11.md", "TESTING_v2.0.11.md", "CURSEFORGE_CHANGELOG_v2.0.11.md", "tests/localization_smoke.lua",
    "Media/DKArcFill.tga", "Media/DKArcBG.tga", "Media/DKArcGlow.tga",
    "Media/DKArcFillRight.tga", "Media/DKArcBGRight.tga", "Media/DKArcGlowRight.tga",
]


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


def section(text: str, start: str, end: str) -> str:
    a = text.find(start)
    b = text.find(end, a + 1) if a >= 0 else -1
    return text[a:b] if a >= 0 and b > a else ""


def main() -> int:
    errors: list[str] = []
    for rel in REQUIRED:
        if not (ROOT / rel).is_file():
            errors.append(f"Missing required file: {rel}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1

    toc_text = (ROOT / "DKMentor.toc").read_text(encoding="utf-8")
    meta, order = parse_toc(toc_text)
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
    if order != RUNTIME_LUA:
        errors.append(f"TOC load order mismatch: {order!r}")
    notes = meta.get("Notes", "")
    if "Loadout Pilot" not in notes or "Death Knight" not in notes:
        errors.append("TOC Notes must describe the DK-focused 2.0 scope and Loadout Pilot handoff")

    core = (ROOT / "Core.lua").read_text(encoding="utf-8")
    mentor_engine = (ROOT / "MentorEngine.lua").read_text(encoding="utf-8")
    data = (ROOT / "Data.lua").read_text(encoding="utf-8")
    builds = (ROOT / "Builds.lua").read_text(encoding="utf-8")
    codex = (ROOT / "Codex.lua").read_text(encoding="utf-8")
    loc = (ROOT / "Localization.lua").read_text(encoding="utf-8")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")

    if f'Data.version = "{VERSION}"' not in data:
        errors.append("Data.version does not match current build")
    if f"Data.interface = {INTERFACE}" not in data:
        errors.append("Data.interface does not match TOC")
    if f"## {VERSION}" not in changelog:
        errors.append("CHANGELOG.md has no current-version entry")

    # 2.0.10 compact post-combat popup: dynamic content sizing with bounded density.
    for snippet in (
        'local POST_COMBAT_MIN_WIDTH = 300',
        'local POST_COMBAT_MAX_WIDTH = 480',
        'local POST_COMBAT_MAX_INSIGHTS = 3',
        'local function LayoutPostCombatFrame(frame, titleText, bodyText)',
        'GetFontStringMetric(frame.text, "GetStringHeight", 14)',
        'frame:SetSize(desiredWidth, math.max(50, desiredHeight))',
        'local bodyText = BuildPostCombatSummary(report)',
        'LayoutPostCombatFrame(frame, titleText, bodyText)',
    ):
        if snippet not in mentor_engine:
            errors.append(f"2.0.10 dynamic post-combat popup regression: {snippet}")

    # 2.0.7 HUD edit-mode safety: movement handles are session-explicit.
    for snippet in (
        'addon.hudEditSessionActive = false',
        'DB.hudLocked = true',
        'self.hudEditSessionActive = not DB.hudLocked',
        'DB.hudLocked ~= false or self.hudEditSessionActive ~= true',
        'resourceArcFrame.dragHandle:SetShown(canMove)',
    ):
        if snippet not in core:
            errors.append(f"2.0.7 HUD edit-mode guard missing: {snippet}")

    # 2.0.10 release-candidate polish guards.
    for snippet in (
        'majorReleaseNotice = ""',
        'DB.majorReleaseNotice ~= "2.0"',
        'local function SanitizeFrameConfig(key)',
        'cfg.x = Clamp(tonumber(cfg.x) or defaults.x or 0, -4000, 4000)',
        'function addon:ShowMentorAlertPreview()',
        'Alert preview active for 8 seconds.',
    ):
        if snippet not in core:
            errors.append(f"2.0.10 RC Core polish regression: {snippet}")
    for snippet in (
        'function Engine.ResetSettings()',
        'function Engine.TestAlerts()',
        'configFrame.testButton:SetText(T("Test alerts"))',
        'configFrame.resetButton:SetText(T("Reset Mentor settings"))',
        'rest == "test" or rest == "preview"',
        'rest == "reset" or rest == "defaults"',
        'DK Mentor recommends actions; it never casts abilities automatically.',
    ):
        if snippet not in mentor_engine:
            errors.append(f"2.0.10 RC Mentor polish regression: {snippet}")


    # 2.0.11 manual-language override regression guards.
    for snippet in (
        'local enUSByPtBR = {}',
        'value = enUSByPtBR[key] or key',
        'function DKM.RefreshStaticLocalization()',
        'for _, moduleName in ipairs({ "Data", "Builds", "Guides", "Codex", "Voices" }) do',
    ):
        if snippet not in loc:
            errors.append(f"2.0.11 localization refresh regression: {snippet}")
    for snippet in (
        'if DKM.RefreshStaticLocalization then DKM.RefreshStaticLocalization() end',
        'function addon:GetRuntimeSpecLabel(specID, fallbackName)',
        'return T(labelKey)',
        'addon:GetRuntimeContextLabel(contextKey)',
        'button:SetText(addon:GetRuntimeContextLabel(button.contextKey))',
        'row.tag:SetText(T(tip.tag or "TIP"))',
        'row.description:SetText(T(tip.text or ""))',
        'card.action:SetText(T(entry.title or "USE"))',
        'card.when:SetText(T(entry.when or ""))',
    ):
        if snippet not in core:
            errors.append(f"2.0.11 runtime localization regression: {snippet}")
    for snippet in (
        '[250] = "Blood"', '[251] = "Frost"', '[252] = "Unholy"',
        'world = "World"', 'delve = "Delve"', 'dungeon = "Dungeon"',
        'mythicplus = "Mythic+"', 'raid = "Raid"', 'pvp = "PvP"',
        'tag = tag', 'text = text', 'title = title', 'when = when',
    ):
        if snippet not in data:
            errors.append(f"2.0.11 canonical localization key missing: {snippet}")
    if 'self.GetRuntimeContextLabel and self:GetRuntimeContextLabel(context)' not in mentor_engine:
        errors.append("2.0.11 MentorEngine must use runtime-localized context labels")

    # Project safety/policy basics.
    for p in ROOT.rglob("*"):
        if p.is_file() and p.suffix.lower() in {".ogg", ".mp3", ".wav", ".flac", ".m4a"}:
            errors.append(f"Bundled audio is not allowed: {p.relative_to(ROOT)}")
        if p.is_file() and p.name.endswith(".bak"):
            errors.append(f"Backup file must not be committed: {p.relative_to(ROOT)}")
    if re.search(r'code\s*=\s*"[^"\s]{20,}"', builds):
        errors.append("Builds.lua must not bundle third-party talent import strings")
    for api_name in ("CastSpellByName", "CastSpellByID", "RunMacroText", "UseAction", "UseContainerItem", "TargetUnit", "AttackTarget"):
        if api_name in core or api_name in mentor_engine:
            errors.append(f"Combat automation API must not be used: {api_name}")

    # DK Mentor 2.0 responsibility boundary: no built-in loadout engine/UI.
    defaults = section(core, "local DEFAULTS = {", "local function GetSpellData")
    for legacy_default in (
        "specializationBindings", "loadoutBindings", "equipmentBindings", "dungeonOverrides",
        "knownDungeons", "personalBuildCodes", "selectedBuild", "autoSwitchSpecialization = true",
        "autoSwitchLoadouts = true", "autoSwitchEquipment = true",
    ):
        if legacy_default in defaults:
            errors.append(f"2.0 DEFAULTS must not contain retired loadout state: {legacy_default}")

    for forbidden_symbol in (
        "function addon:ApplyAutomaticProfile(", "function addon:TryAutoSwitchSpecialization(",
        "function addon:TryAutoSwitchLoadout(", "function addon:TryAutoSwitchEquipment(",
        "function addon:SyncDungeonLootSpecialization(", "function addon:GetCurrentDungeonIdentity(",
        "function addon:RememberDungeonIdentity(", "function addon:CreateDungeonOverridesFrame(",
        "function addon:CreateDungeonOverrideEditorFrame(", "local function CreateLoadoutPickerFrame(",
        "local function CreateEquipmentPickerFrame(", "function addon:UpdateBuildSection(",
        "SetLootSpecialization", "C_ClassTalents.ImportLoadout", "C_EquipmentSet.UseEquipmentSet",
    ):
        if forbidden_symbol in core:
            errors.append(f"Retired loadout engine/UI remains in Core.lua: {forbidden_symbol}")

    for legacy_event in (
        '"SPECIALIZATION_CHANGE_CAST_FAILED"', '"TRAIT_CONFIG_CREATED"', '"TRAIT_CONFIG_LIST_UPDATED"',
        '"SELECTED_LOADOUT_CHANGED"', '"ACTIVE_COMBAT_CONFIG_CHANGED"', '"CONFIG_COMMIT_FAILED"',
        '"EQUIPMENT_SETS_CHANGED"', '"EQUIPMENT_SWAP_FINISHED"', '"PLAYER_LOOT_SPEC_UPDATED"',
        '"PLAYER_ROLES_ASSIGNED"',
    ):
        if legacy_event in section(core, "function addon:RegisterRuntimeEvents()", "addon:SetScript(\"OnEvent\""):
            errors.append(f"Loadout-specific runtime event still registered: {legacy_event}")

    if 'local tabOrder = { "combat", "guide", "settings" }' not in core:
        errors.append("2.0 main UI must expose exactly Combat / DK Codex / Settings tabs")
    if 'CreatePage("builds")' in core or "loadoutContextBar" in core:
        errors.append("Retired Loadouts main-tab UI still exists")
    if 'frame.loadoutPilotSection = CreateSection(settingsPage, T("Loadout automation")' not in core:
        errors.append("Settings handoff to Loadout Pilot is missing")
    if 'SlashCmdList.LOADOUTPILOT("")' not in core:
        errors.append("Optional Loadout Pilot open integration is missing")
    if 'command == "loadout" or command == "loadouts"' not in core:
        errors.append("/dkm loadouts handoff command is missing")

    # Upgrades from 1.x: keep old SavedVariables inert and avoid another schema migration.
    if "schema = 30" not in defaults:
        errors.append("2.0.10 RC must use schema 30 for the non-destructive HUD migration guard")
    init = section(core, "function addon:InitializeDatabase()", "function addon:CreateUI()")
    for snippet in (
        'if DB.mainTab == "builds" then DB.mainTab = "guide" end',
        "DB.autoSwitchSpecialization ~= nil then DB.autoSwitchSpecialization = false", "DB.autoSwitchLoadouts ~= nil then DB.autoSwitchLoadouts = false", "DB.autoSwitchEquipment ~= nil then DB.autoSwitchEquipment = false",
        "DB.schema = DEFAULTS.schema",
    ):
        if snippet not in init:
            errors.append(f"2.0 upgrade safety guard missing: {snippet}")
    if "DB.specializationBindings = nil" in init or "DB.loadoutBindings = nil" in init or "DB.equipmentBindings = nil" in init:
        errors.append("2.0 must preserve legacy mapping tables for rollback safety rather than deleting them")

    # Manual spec chooser is allowed; automatic spec switching is not.
    manual_spec = section(core, "function addon:SwitchSpecialization(index)", "function addon:DetectActualContext()")
    if "C_SpecializationInfo.SetSpecialization" not in manual_spec and "C_ClassTalents.SwitchToSpecializationByIndex" not in manual_spec:
        errors.append("Manual specialization picker implementation is missing")
    if "Manual-only convenience" not in manual_spec:
        errors.append("Manual specialization boundary is not documented in code")
    on_update = section(core, 'addon:SetScript("OnUpdate"', 'addon:RegisterEvent("ADDON_LOADED")')
    if "GetCurrentDungeonIdentity" in on_update or "RememberDungeonIdentity" in on_update or "ApplyAutomaticProfile" in on_update:
        errors.append("Active context polling still touches retired loadout automation")

    # DK Ready remains class-specific rather than loadout-compliance-specific.
    ready = section(core, "function addon:GetReadyCheckStatus()", "function addon:PrintReadyCheckStatus()")
    for required in ("GetRuneforgeStatus", "GetGhoulReadyStatus"):
        if required not in ready:
            errors.append(f"DK Ready lost class-specific check: {required}")
    for forbidden in ("loadout", "equipmentBindings", "specializationBindings", "talent"):
        if forbidden.lower() in ready.lower():
            errors.append(f"DK Ready must not check retired loadout compliance: {forbidden}")

    # Compact DK status HUD: context + ready only, with manual spec chooser and right-click open.
    widget = section(core, "local function CreateStatusWidget()", "local function LayoutStatusWidget()")
    if "frame.build" in widget or "frame.gear" in widget or "frame.auto" in widget:
        errors.append("2.0 status HUD must not contain build/gear/automation fields")
    for required in ('frame.specButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")', "addon:ToggleSpecializationPicker()", "addon:ToggleMainFrame()"):
        if required not in widget:
            errors.append(f"DK status HUD interaction missing: {required}")
    status_update = section(core, "function addon:UpdateStatusWidget()", "function addon:RefreshStatusWidgetVisibility()")
    if "GetRuntimeContextLabel" not in status_update or "GetReadyCheckStatus" not in status_update:
        errors.append("2.0 status HUD must show context and DK Ready")

    # 2.0.1 compact status HUD / Codex action-row regression guards.
    for snippet in (
        'frame:SetSize(150, 32)', 'frame.icon:SetSize(24, 24)',
        'frame.title:SetPoint("LEFT", frame.icon, "RIGHT", 6, 0)',
        'frame.ready:SetPoint("LEFT", frame.title, "RIGHT", 8, 0)',
        'math.max(140, math.min(360, 4 + 24 + 6 + titleWidth + 8 + readyWidth + 6))',
        'statusWidget:SetSize(desiredWidth, 32)',
        'guide.sourceURLBox:SetSize(395, 24)',
        'guide.selectSourceButton:SetSize(170, 24)',
        'guide.openPilotButton:SetSize(155, 24)',
    ):
        if snippet not in core:
            errors.append(f"2.0.1 compact UI regression: {snippet}")

    # Codex + recommendation-only builds.
    if 'sectionOrder = { "overview", "builds", "rotation", "survival", "stats", "utility", "check" }' not in codex:
        errors.append("DK Codex must expose seven sections including Builds")
    for snippet in ("DK mechanics — Runes", "PvE stat priority", "Runeforge", "Gems", "Enchants", "Consumables", "Cheat sheet", "Beginner opener", "Interrupt and crowd control handbook"):
        if snippet not in codex:
            errors.append(f"DK Codex content missing: {snippet}")
    guide_update = section(core, "function addon:UpdateGuideSection()", "function addon:UpdateAll()")
    for snippet in ('sectionKey == "builds"', "self:GetBuildProfiles(specID, context)", "does not create, select, or switch WoW loadouts", "self:UpdateLoadoutPilotIntegration()"):
        if snippet not in guide_update:
            errors.append(f"Recommendation-only Builds section missing: {snippet}")
    if 'command == "build" or command == "builds"' not in core:
        errors.append("/dkm builds must open Codex build recommendations")

    # Character Check is read-only and DK-oriented.
    check = section(core, "function addon:GetCharacterCheckReport(selectedSpecID)", "function addon:UpdateGuideSection()")
    for forbidden in ("Talent loadout", "Equipment set", "specializationBindings", "loadoutBindings", "equipmentBindings"):
        if forbidden in check:
            errors.append(f"Character Check still references retired loadout state: {forbidden}")
    for required in ("Common enchant slots", "Sockets", "Current stat snapshot", "Utility toolkit"):
        if required not in check:
            errors.append(f"Character Check regression: {required}")

    # Midnight 12.1 secret-aspect/aura safeguards.
    managed_create = section(core, "local function CreateManagedAuraBar", "local function ClearTrackingCooldown")
    if 'pcall(container.SetUnit, container, "player")' not in managed_create or "pcall(container.SetEnabled, container, true)" not in managed_create:
        errors.append("Managed AuraContainer setup is incomplete")
    if "HookScript(\"OnShow\"" in core or "HookScript(\"OnHide\"" in core:
        errors.append("Never hook secret AuraButton OnShow/OnHide handlers")
    if "managedAuraButtons" in core:
        errors.append("Do not retain AuraButton objects to infer secret aura visibility")
    chrome = section(core, "local function UpdateManagedAuraBarChrome(frame)", "local MANAGED_AURA_ICON_SIZE")
    for snippet in ("local showChrome = addon.hudPreviewMode == true", "frame.label:SetShown(showChrome)", "frame.dragHint:SetShown(showChrome)", "frame:EnableMouse(editing)", "frame:SetBackdropColor(0, 0, 0, 0)"):
        if snippet not in chrome:
            errors.append(f"Secret-safe empty aura bar behavior missing: {snippet}")

    # 2.0.3 resource-arc click-through regression guards.
    arc_create = section(core, "local function CreateResourceArcHUD()", "local COMBAT_BAR_LAYOUT_LIMITS")
    for snippet in (
        'frame:EnableMouse(false)',
        'frame.dragHandle = CreateFrame("Frame", nil, frame, "BackdropTemplate")',
        'frame.dragHandle:SetSize(118, 20)',
        'frame.dragHandle:RegisterForDrag("LeftButton")',
    ):
        if snippet not in arc_create:
            errors.append(f"2.0.3 resource arc click-through guard missing: {snippet}")
    hud_hints = section(core, "function addon:UpdateHUDMoveHints()", "function addon:SetHUDsLocked(locked)")
    for snippet in (
        'local canMove = self:CanMoveHUDs()',
        'resourceArcFrame:EnableMouse(false)',
        'resourceArcFrame.dragHandle:EnableMouse(canMove)',
        'resourceArcFrame.dragHandle:SetShown(canMove)',
    ):
        if snippet not in hud_hints:
            errors.append(f"2.0.3 resource arc interaction sync missing: {snippet}")
    if 'resourceArcFrame:EnableMouse(editing)' in core:
        errors.append("Resource arc parent must never be mouse-enabled; it blocks world target clicks")

    # 2.0.4+ Mind Freeze alert event-latch reliability guards.
    interrupt_update = section(core, "function addon:UpdateInterruptAlert()", "function addon:UpdateAbilityBar()")
    for snippet in (
        "targetInterruptEventState == true",
        "local presentationBound = SetInterruptFrameFromNotInterruptible",
        "if not presentationBound then",
    ):
        if snippet not in interrupt_update:
            errors.append(f"Interrupt event-latch guard missing: {snippet}")
    runtime_events = section(core, "function addon:RegisterRuntimeEvents()", 'addon:SetScript("OnEvent"')
    for snippet in (
        'self.RegisterUnitEvent, self, eventName, "target"',
        '"UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"',
        '"UNIT_SPELLCAST_DELAYED"',
        '"UNIT_SPELLCAST_CHANNEL_UPDATE"',
        '"UNIT_SPELLCAST_EMPOWER_START"',
    ):
        if snippet not in runtime_events:
            errors.append(f"2.0.4 interrupt registration guard missing: {snippet}")
    if "ScheduleInterruptAlertRefreshes()" not in core:
        errors.append("2.0.4 interrupt transition refresh helper is missing")

    # 2.0.10 Midnight Secret-safe interrupt presentation guards.
    for snippet in (
        'local function GetTargetInterruptStateFromCastAPI()',
        'return true, notInterruptible, "cast", castBarID',
        'return true, notInterruptible, "channel", castBarID',
        'local function SetInterruptFrameFromNotInterruptible(frame, notInterruptible)',
        'IsSecretValue(notInterruptible)',
        'pcall(frame.SetAlphaFromBoolean, frame, notInterruptible, 0, 1)',
        'local presentationBound = SetInterruptFrameFromNotInterruptible(interruptFrame, rawNotInterruptible)',
        'self:UpdateInterruptAlert()',
        'function addon:PrintInterruptAlertStatus()',
        'interruptFrame:EnableMouse(canMove)',
    ):
        if snippet not in core:
            errors.append(f"2.0.10 Secret-safe interrupt regression: {snippet}")
    if 'GetTargetInterruptibleFromCastAPI' in core:
        errors.append('2.0.10 must not use the old readable-only interrupt API helper')

    # Core DK HUD/resource guards.
    for snippet in (
        "function addon:UpdateInterruptAlert()", "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "activeProcGlows",
        "local function CreateResourceHUD()", "local function CreateResourceArcHUD()", "for index = 1, 6 do",
        'pcall(UnitPower, "player", RUNIC_POWER_TYPE)', "DK_ARC_FILL_RIGHT_TEXTURE", "GetDKRuneColors",
        "SetResourceArcHealthColors", "function addon:SetCombatBarScale(dbKey, value)",
        "function addon:SetCombatBarOpacity(dbKey, value)", "function addon:SetCombatBarColumns(dbKey, value)",
        "function addon:SetLanguageOverride(value)", "languagePickerFrame = CreateLanguagePickerFrame()",
    ):
        if snippet not in core:
            errors.append(f"Core DK/HUD regression guard missing: {snippet}")

    # 2.0.5 Adaptive DK Coach / Combat Insights feature guards.
    for snippet in (
        'local MODE_ORDER = { "essential", "mentor", "training" }',
        'function addon:GetAdaptiveCoachEntries(specID, context, baseEntries)',
        'GetRecentDamagePercent', 'GetRunicPowerPercent', 'GetReadyRuneCount',
        'BONE SHIELD', 'BUILD WOUNDS', 'high-value proc is active',
        'UNIT_SPELLCAST_INTERRUPTIBLE', 'UNIT_SPELLCAST_NOT_INTERRUPTIBLE',
        'SamplePlayerHealthDamage', 'BuildScoreReport', 'DK Mentor Score',
        'Adaptive DK Coach — last combat', 'Solo/Delve boost', 'Post-combat popup',
    ):
        if snippet not in mentor_engine:
            errors.append(f"2.0.5 Adaptive Coach regression: {snippet}")
    # 2.0.6 Midnight hardening: CLEU is forbidden for third-party addons.
    for forbidden in ('COMBAT_LOG_EVENT_UNFILTERED', 'CombatLogGetCurrentEventInfo'):
        if forbidden in mentor_engine or forbidden in core:
            errors.append(f"2.0.6 forbidden Midnight combat-log dependency present: {forbidden}")
    for snippet in (
        'SamplePlayerHealthDamage()',
        'MarkInterruptHandled(true)',
        'event == "UNIT_SPELLCAST_INTERRUPTED" then MarkInterruptHandled(false)',
        'GetUnitAuraBySpellID, "target", spellID',
    ):
        if snippet not in mentor_engine:
            errors.append(f"2.0.6 Midnight-safe mentor guard missing: {snippet}")

    for snippet in (
        'BONE_SHIELD = 195181', 'FESTERING_WOUND = 194310',
        'VIRULENT_PLAGUE = 191587', 'FROST_STRIKE = 49143', 'DEATH_COIL = 47541',
    ):
        if snippet not in data:
            errors.append(f"2.0.5 DK state data missing: {snippet}")
    if 'MentorEngine.lua' not in (ROOT / "scripts/package.sh").read_text(encoding="utf-8"):
        errors.append("package.sh must include MentorEngine.lua")
    if 'MentorEngine.lua' not in (ROOT / "scripts/package.ps1").read_text(encoding="utf-8"):
        errors.append("package.ps1 must include MentorEngine.lua")
    for snippet in (
        'P("Adaptive DK Coach", "Coach Adaptativo de DK")',
        'P("Mentor intelligence...", "Inteligência do Mentor...")',
        'P("Combat Insights: ON", "Combat Insights: LIGADO")',
    ):
        if snippet not in loc:
            errors.append(f"2.0.5 Adaptive Coach localization missing: {snippet}")

    # Media packaging scripts must copy the full texture folder.
    package_sh = (ROOT / "scripts/package.sh").read_text(encoding="utf-8")
    package_ps1 = (ROOT / "scripts/package.ps1").read_text(encoding="utf-8")
    if 'cp -a "$ROOT/Media/." "$STAGE/Media/"' not in package_sh:
        errors.append("package.sh must copy the complete Media folder")
    if "Copy-Item $MediaSource $MediaDest -Recurse -Force" not in package_ps1:
        errors.append("package.ps1 must copy the complete Media folder")

    # Localization for the new ownership boundary.
    for snippet in (
        'P("Loadout automation", "Automação de loadouts")',
        'P("Open Loadout Pilot", "Abrir Loadout Pilot")',
        'P("Build recommendations", "Recomendações de builds")',
        'P("/dkm loadouts — open Loadout Pilot when installed",',
    ):
        if snippet not in loc:
            errors.append(f"2.0 EN/ptBR localization missing: {snippet}")

    if errors:
        print("Validation failed:", file=sys.stderr)
        for error in errors:
            print(f" - {error}", file=sys.stderr)
        return 1

    print(f"Validation passed: DK Mentor {VERSION}, Retail interface {INTERFACE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
