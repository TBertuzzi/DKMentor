#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = "3.1.6"
INTERFACE = "120100"

RUNTIME_LUA = ["Localization.lua", "Data.lua", "Builds.lua", "Guides.lua", "GearData.lua", "PreparationData.lua", "Codex.lua", "Voices.lua", "Core.lua", "MentorEngine.lua", "MentorReview.lua", "DKTools.lua", "MentorStudio.lua"]
REQUIRED = [
    "DKMentor.toc", *RUNTIME_LUA, "README.md", "CHANGELOG.md", "LICENSE",
    "THIRD_PARTY_NOTICES.md", "POLICY_AND_SOURCES.md", "PUBLISHING.md",
    "RELEASE_NOTES_v3.1.6.md", "TESTING_v3.1.6.md", "CURSEFORGE_CHANGELOG_v3.1.6.md", "VALIDATION_REPORT_v3.1.6.md", "DATA_AUDIT_v3.1.0.md",
    "tests/localization_smoke.lua", "tests/review_smoke.lua", "tests/tools_smoke.lua", "tests/studio_smoke.lua", "tests/core_ux_smoke.lua", "tests/modal_navigation_smoke.lua", "tests/interrupt_enhancements_smoke.lua", "tests/gear_mentor_smoke.lua", "tests/build_mentor_smoke.lua", "tests/rune_order_smoke.lua", "tests/preparation_31_smoke.lua", "tests/accessibility_preset_31_smoke.lua", "tests/voice_portrait_315_smoke.lua", "tests/layout_preset_316_smoke.lua", "tests/portrait_position_316_smoke.lua",
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
        errors.append("TOC Notes must describe the DK-focused 3.0 scope and Loadout Pilot handoff")

    core = (ROOT / "Core.lua").read_text(encoding="utf-8")

    # WoW/Lua rejects a chunk once more than 200 locals are simultaneously
    # active in its main function. Core.lua intentionally keeps a safety margin.
    chunk_locals = 0
    for raw in core.splitlines():
        if raw.startswith("local function "):
            chunk_locals += 1
        elif raw.startswith("local "):
            declaration = raw[6:].split("=", 1)[0].strip()
            names = [name.strip() for name in declaration.split(",")]
            chunk_locals += sum(1 for name in names if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", name))
    if chunk_locals > 190:
        errors.append(f"Core.lua chunk-level local count is {chunk_locals}; keep it <= 190 to preserve headroom below WoW's 200-local limit")
    mentor_engine = (ROOT / "MentorEngine.lua").read_text(encoding="utf-8")
    data = (ROOT / "Data.lua").read_text(encoding="utf-8")
    builds = (ROOT / "Builds.lua").read_text(encoding="utf-8")
    codex = (ROOT / "Codex.lua").read_text(encoding="utf-8")
    gear_data = (ROOT / "GearData.lua").read_text(encoding="utf-8")
    preparation_data = (ROOT / "PreparationData.lua").read_text(encoding="utf-8")
    loc = (ROOT / "Localization.lua").read_text(encoding="utf-8")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    mentor_review = (ROOT / "MentorReview.lua").read_text(encoding="utf-8")
    dk_tools = (ROOT / "DKTools.lua").read_text(encoding="utf-8")
    mentor_studio = (ROOT / "MentorStudio.lua").read_text(encoding="utf-8")
    runtime_text = "\n".join((ROOT / rel).read_text(encoding="utf-8") for rel in RUNTIME_LUA)

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
        'DB.majorReleaseNotice ~= "3.0"',
        'local function SanitizeFrameConfig(key)',
        'cfg.x = Clamp(tonumber(cfg.x) or defaults.x or 0, -4000, 4000)',
        'function addon:ShowMentorAlertPreview()',
        'Alert preview active for 4 seconds.',
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
        'for _, moduleName in ipairs({ "Data", "Builds", "Guides", "Codex", "Voices", "PreparationData" }) do',
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

    # 3.0.5 compact Live Mentor HUD visual regression guards.
    for snippet in (
        'local COACH_LAYOUT_ORDER = { "compact", "medium", "large" }',
        'compact = { frameHeight = 96, minWidth = 280, cardWidth = 102, cardHeight = 64',
        'cfg.layout=NormalizeCoachLayout(cfg.layout)',
        'function addon:ApplyMentorCoachLayout()',
        'local frameWidth = math.max(layout.minWidth, totalCardsWidth + 14)',
        'f.layout=Button(f,"Coach layout",160,function() CycleCoachLayout() end)',
        'f.layout:SetText(T("Coach layout: %s", CoachLayoutLabel(cfg.layout)))',
    ):
        if snippet not in mentor_studio:
            errors.append(f"3.0.5 compact Mentor HUD regression: {snippet}")
    for snippet in (
        'coachFrame.dragHint:SetText(canMove and T("Move") or "")',
        'if addon.ApplyMentorCoachLayout then addon:ApplyMentorCoachLayout() end',
    ):
        if snippet not in core:
            errors.append(f"3.0.5 Core Mentor layout regression: {snippet}")
    layout_section = section(mentor_studio, "function addon:ApplyMentorCoachLayout()", "local function CycleCoachLayout")
    if 'card:SetBackdrop(' in layout_section:
        errors.append("3.0.5 Mentor layout must not reapply card backdrops; that resets dark cards to white in-game")
    for snippet in (
        'card:SetBackdropColor(0.018, 0.055, 0.075, 0.88)',
        'card:SetBackdropBorderColor(0.12, 0.40, 0.54, 0.72)',
        'card.when:SetTextColor(0.78, 0.86, 0.90)',
    ):
        if snippet not in core:
            errors.append(f"3.0.5 dark compact card regression: {snippet}")
    for snippet in (
        'P("Medium", "Médio")',
        'P("Large", "Grande")',
        'P("Move", "Mover")',
        'P("Coach layout: %s", "Layout do Mentor: %s")',
    ):
        if snippet not in loc:
            errors.append(f"3.0.5 localization missing: {snippet}")

    # 3.0.6 pinned Blizzard next-action card.
    for snippet in (
        'pinNextAction = true',
        'local function GetAssistedCombatNextSpell()',
        'pcall(C_AssistedCombat.GetNextCastSpell, false)',
        'MakeCoachEntry(nextSpellID, "NEXT", "Blizzard Assisted Combat", false, nil, "rotation")',
        'frame.nextActionButton = CreateToggleButton',
        'rest == "nextaction on"',
        'rest == "nextaction off"',
    ):
        if snippet not in mentor_engine:
            errors.append(f"3.0.6 pinned next-action regression: {snippet}")
    for snippet in (
        'entry.kind == "rotation"',
        'card:SetBackdropBorderColor(0.25, 0.72, 0.88, 0.92)',
    ):
        if snippet not in core:
            errors.append(f"3.0.6 pinned-card presentation regression: {snippet}")
    for snippet in (
        'f.nextAction=Button(f,"Next action",155',
        'mentor.pinNextAction=not(mentor.pinNextAction~=false)',
        'f.nextAction:SetText(T(mentor.pinNextAction ~= false and "Next action: ON" or "Next action: OFF"))',
    ):
        if snippet not in mentor_studio:
            errors.append(f"3.0.6 next-action Studio regression: {snippet}")
    for snippet in (
        'P("NEXT", "PRÓXIMA")',
        'P("Blizzard Assisted Combat", "Combate Assistido da Blizzard")',
        'P("Next action: ON", "Próxima ação: LIGADA")',
        'P("Next action: OFF", "Próxima ação: DESLIGADA")',
    ):
        if snippet not in loc:
            errors.append(f"3.0.6 next-action localization missing: {snippet}")


    # 3.0.7 modal child-window navigation: never stack Studio/Review on Mentor Intelligence.
    for snippet in (
        'DKM.MentorReview.Open("overview", frame)',
        'DKM.MentorStudio.Open(frame)',
        'DKM.MentorStudio.OpenSetup(frame)',
    ):
        if snippet not in mentor_engine:
            errors.append(f"3.0.7 Mentor child-modal regression: {snippet}")
    for snippet in (
        'local reviewReturnFrame',
        'function Review.Open(tab, parentFrame)',
        'RestoreReviewParent()',
        'frame:SetFrameLevel(300)',
        'frame:SetToplevel(true)',
    ):
        if snippet not in mentor_review:
            errors.append(f"3.0.7 Review modal regression: {snippet}")
    for snippet in (
        'local studioTransitionInProgress = false',
        'local setupTransitionInProgress = false',
        'local studioReturnFrame',
        'local setupReturnFrame',
        'function Studio.Open(parentFrame)',
        'function Studio.OpenSetup(parentFrame)',
        'f:SetFrameLevel(280)',
        'f:SetToplevel(true)',
        'ShowModalParent(parent)',
    ):
        if snippet not in mentor_studio:
            errors.append(f"3.0.7 Studio/Setup modal regression: {snippet}")
    if 'returnToSetupAfterStudio' in mentor_studio:
        errors.append("3.0.7 must use generic modal-return state instead of the old one-off setup flag")

    # Project safety/policy basics.
    for p in ROOT.rglob("*"):
        if p.is_file() and p.suffix.lower() in {".ogg", ".mp3", ".wav", ".flac", ".m4a"}:
            errors.append(f"Bundled audio is not allowed: {p.relative_to(ROOT)}")
        if p.is_file() and p.name.endswith(".bak"):
            errors.append(f"Backup file must not be committed: {p.relative_to(ROOT)}")
    if re.search(r'code\s*=\s*"[^"\s]{20,}"', builds):
        errors.append("Builds.lua must not bundle third-party talent import strings")
    for api_name in ("CastSpellByName", "CastSpellByID", "RunMacroText", "UseAction", "UseContainerItem", "TargetUnit", "AttackTarget"):
        if api_name in runtime_text:
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

    # 3.1 adds persisted accessibility/portrait settings while keeping legacy loadout data inert.
    if "schema = 33" not in defaults:
        errors.append("3.1.x must use schema 33 for current SavedVariables defaults")
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
        'guide.sourceURLBox:SetSize(238, 22)',
        'guide.selectSourceButton:SetSize(152, 22)',
        'guide.openPilotButton:SetSize(160, 22)',
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
    for snippet in ('sectionKey == "builds"', "self:GetBuildProfiles(specID, context)", "self:RenderBuildMentorVisual(specID, context, autoDetected)", "self:UpdateLoadoutPilotIntegration()"):
        if snippet not in guide_update:
            errors.append(f"Recommendation-only Builds section missing: {snippet}")
    if "DK Mentor recommends and explains builds; it does not switch talents. Loadout automation remains in Loadout Pilot." not in core:
        errors.append("Build Mentor recommendation-only disclaimer missing")
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
    chrome = section(core, "local function UpdateManagedAuraBarChrome(frame)", "addon.MANAGED_AURA_ICON_SIZE")
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
        'BONE SHIELD', 'BUILD GHOULS', 'SUMMON GHOUL', 'high-value proc is active',
        'UNIT_SPELLCAST_INTERRUPTIBLE', 'UNIT_SPELLCAST_NOT_INTERRUPTIBLE',
        'SamplePlayerHealthDamage', 'BuildScoreReport', 'DK Mentor Score',
        'Adaptive DK Coach — last combat', 'Solo/Delve boost', 'Post-combat popup',
    ):
        if snippet not in mentor_engine:
            errors.append(f"2.0.5 Adaptive Coach regression: {snippet}")
    # 2.0.6 Midnight hardening: CLEU is forbidden for third-party addons.
    for forbidden in ('COMBAT_LOG_EVENT_UNFILTERED', 'CombatLogGetCurrentEventInfo'):
        if forbidden in runtime_text:
            errors.append(f"Midnight forbidden combat-log dependency present: {forbidden}")
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

    # 3.0 current Midnight DK state and review/tooling guards.
    for snippet in (
        'COAGULATING_BLOOD = 463730',
        'LESSER_GHOUL = 1254252',
        'DARK_TRANSFORMATION = 1233448',
        'PUTREFY = 1247378',
        'DREAD_PLAGUE = 1240996',
    ):
        if snippet not in data:
            errors.append(f"3.0 current DK state data missing: {snippet}")
    for snippet in (
        'historyLimit = 10',
        'local function AddTimelineEvent',
        'local strengths = {}',
        'Resource flow stayed efficient in the readable samples.',
        'Death Strike used with a readable recent-damage pool of %d%%',
        'BUILD GHOULS',
        'SUMMON GHOUL',
        'Midnight Breath of Sindragosa no longer continuously drains Runic Power',
        'DKM.MentorReview.Record(report)',
    ):
        if snippet not in mentor_engine:
            errors.append(f"3.0 MentorEngine feature missing: {snippet}")
    if 'and not breathActive' in mentor_engine or 'local breathActive =' in mentor_engine:
        errors.append("3.0 must not suppress Runic Power coaching using the pre-Midnight Breath fuel model")
    for snippet in (
        'DKMentorReviewFrame',
        'selectedTab = "overview"',
        '{ {"overview", "Overview"}, {"timeline", "Timeline"}, {"patterns", "Patterns"} }',
        'function Review.GetPatterns',
        'function Review.BuildTimeline',
        'function Review.BuildPatterns',
        'What keeps coming back',
        'What went well',
    ):
        if snippet not in mentor_review:
            errors.append(f"3.0 Review feature missing: {snippet}")
    for snippet in (
        'DKMentorGroundTracker',
        'DKMentorMeleeWarning',
        'DND_DURATION = 10',
        'C_Spell.GetSpellCharges',
        'C_Spell.IsSpellInRange',
        'IsSecretValue(raw)',
        'local MELEE_WARNING_DELAY = 0.30',
        'f:SetSize(136, 22)',
        'f.text:SetText(T("OUT OF RANGE"))',
        'f:SetShown((now - meleeOutSince) >= MELEE_WARNING_DELAY)',
        'SPELL_UPDATE_CHARGES',
    ):
        if snippet not in dk_tools:
            errors.append(f"3.0 DK Tools feature missing: {snippet}")
    for snippet in (
        'DKMentorStudioFrame',
        'DKMentorSetupWizard',
        'function addon:ApplyMentorCardStyle',
        'function Studio.PreviewKind',
        'local SETUP_VERSION = 301',
        'mentor.setupVersion=SETUP_VERSION',
        'Review and DK Tools',
        'Resource HUD visibility',
    ):
        if snippet not in mentor_studio:
            errors.append(f"3.0 Studio/Setup feature missing: {snippet}")

    # 3.0.1 Setup Wizard UX regression guards.
    for snippet in (
        'f:SetSize(690,470)',
        'local OPTION_BUTTON_HEIGHT = 44',
        'fontString:SetWidth(math.max(40, width - 16))',
        'LayoutOptions(f,4,2)',
        'if self.autoAdvance then',
        'f.current:SetText(T("Current selection: %s"',
        'f.next:Hide()',
        'RunPreviewOutsideWizard(function()',
        'f:Hide()',
        'local PREVIEW_SECONDS = 4',
        'ShowPreviewNotice(seconds)',
        'C_Timer.After(seconds + 0.25',
        'Studio.Open(f)',
        'local function PreviewSelectedFromStudio()',
        'studioPreviewInProgress = true',
        'C_Timer.After(PREVIEW_SECONDS + 0.25',
        'IsHUDLocked() and "Unlock HUDs" or "Lock HUDs"',
    ):
        if snippet not in mentor_studio:
            errors.append(f"3.0.1 Setup Wizard UX regression: {snippet}")
    if 'Keep current settings' in mentor_studio:
        errors.append("3.0.1 Setup Wizard must not restore the old ambiguous Keep current settings footer action")

    # 3.0.2 Core UI/HUD regression guards.
    normalize_pos = core.find('local function NormalizeResourceVisibilityMode')
    update_resource_pos = core.find('function addon:UpdateResourceHUD')
    if normalize_pos < 0 or update_resource_pos < 0 or normalize_pos > update_resource_pos:
        errors.append("3.0.2 Resource HUD visibility normalizer must be declared before UpdateResourceHUD")
    for snippet in (
        'DKM.CreateActionButton = CreateActionButton',
        'SetActionButtonSelected(button, isSelected)',
        'coachFrame.hasVisibleCards',
        'DK Toolkit — reference',
    ):
        if snippet not in core:
            errors.append(f"3.0.2 Core UI regression: {snippet}")
    if '✓' in core:
        errors.append("3.0.2 Core UI must not use unsupported checkmark glyphs")
    if 'UIPanelButtonTemplate' in core:
        errors.append("3.0.2 Core action buttons must use DK Mentor flat styling, not red UIPanelButtonTemplate")
    for snippet in (
        'local allowFallback = mode ~= "essential" or self.hudPreviewMode == true',
        'Live Mentor preview — %s',
    ):
        if snippet not in mentor_engine:
            errors.append(f"3.0.2 Essential/preview regression: {snippet}")

    # 3.0.3 settings/readability + preview-return + subtle melee UX guards.
    for snippet in (
        'hud.buildButton:SetSize(190, 24)',
        'fontString:SetWordWrap(false)',
        'T("DK status: ON")',
        'T("Abilities: ON")',
        'T("Resources: ON")',
        'T("Interrupt: ON")',
        'Alert preview active for 4 seconds.',
    ):
        if snippet not in core:
            errors.append(f"3.0.3 Core UX regression: {snippet}")
    for snippet in (
        'local PREVIEW_SECONDS = 4',
        'DKMentorSetupPreviewNotice',
        'ShowPreviewNotice(seconds)',
        'C_Timer.After(seconds + 0.25',
        'Previews briefly hide the wizard; a return notice stays visible.',
    ):
        if snippet not in mentor_studio:
            errors.append(f"3.0.3 Setup preview UX regression: {snippet}")
    for snippet in (
        'local MELEE_WARNING_DELAY = 0.30',
        'f:SetSize(136, 22)',
        'T("OUT OF RANGE")',
        'f:SetShown((now - meleeOutSince) >= MELEE_WARNING_DELAY)',
    ):
        if snippet not in dk_tools:
            errors.append(f"3.0.3 melee warning UX regression: {snippet}")
    for snippet in (
        'setupSettingsButton = CreateActionButton(settingsPage)',
        'setupSettingsButton:SetText(T("Setup..."))',
        'DKM.MentorStudio.OpenSetup()',
    ):
        if snippet not in mentor_engine:
            errors.append(f"3.0.3 Settings setup entry regression: {snippet}")
    for snippet in (
        'visibilityMode = "combat"',
        'fadeAlpha = 0.20',
        'function addon:SetResourceVisibilityMode(mode)',
        'function addon:CycleResourceVisibilityMode()',
        'DB.majorReleaseNotice ~= "3.0"',
    ):
        if snippet not in core:
            errors.append(f"3.0 Core feature missing: {snippet}")
    for module_name in ("GearData.lua", "MentorEngine.lua", "MentorReview.lua", "DKTools.lua", "MentorStudio.lua"):
        if module_name not in (ROOT / "scripts/package.sh").read_text(encoding="utf-8"):
            errors.append(f"package.sh must include {module_name}")
        if module_name not in (ROOT / "scripts/package.ps1").read_text(encoding="utf-8"):
            errors.append(f"package.ps1 must include {module_name}")
    for snippet in (
        'P("Adaptive DK Coach", "Coach Adaptativo de DK")',
        'P("Mentor intelligence...", "Inteligência do Mentor...")',
        'P("Combat Insights: ON", "Combat Insights: LIGADO")',
    ):
        if snippet not in loc:
            errors.append(f"2.0.5 Adaptive Coach localization missing: {snippet}")

    for snippet in (
        'P("DK Mentor Review 3.0", "DK Mentor Review 3.0")',
        'P("What went well", "O que foi bem")',
        'P("DK Mentor Alert Studio", "Estúdio de Alertas do DK Mentor")',
        'P("DK Mentor 3.0 Setup", "Configuração do DK Mentor 3.0")',
        'P("Lesser Ghouls", "Carniçais Menores")',
        'P("Fade out of combat", "Esmaecer fora de combate")',
    ):
        if snippet not in loc:
            errors.append(f"3.0 localization missing: {snippet}")

    for snippet in (
        'P("Setup...", "Assistente...")',
        'P("OUT OF RANGE", "FORA DE ALCANCE")',
        'P("Alert preview active for 4 seconds.", "Prévia dos alertas ativa por 4 segundos.")',
        'P("DK status: ON", "Status DK: LIGADO")',
        'P("Abilities: ON", "Habilidades: LIGADAS")',
    ):
        if snippet not in loc:
            errors.append(f"3.0.3 localization missing: {snippet}")

    # 3.0.8 Assisted Combat coverage must respect the active spec/loadout.
    for snippet in (
        'function addon:GetRelevantRotationSpells()',
        'local restrictions = Data.assistedCombatSpecRestrictions or {}',
        'local knownSpellID = GetKnownRotationSpellID(spellID)',
        'local rotationSpells = self:GetRelevantRotationSpells()',
    ):
        if snippet not in core:
            errors.append(f"3.0.8 spec-aware action-bar coverage regression: {snippet}")
    if 'Data.assistedCombatSpecRestrictions' not in data or '[343294] = 252' not in data:
        errors.append("3.0.8 Soul Reaper must remain Unholy-only for Assisted Combat coverage")

    # WoW fonts used by these panels do not reliably render every decorative
    # Unicode glyph. Keep known-problematic symbols out of runtime UI strings.
    for glyph in ('✓', '→', '▸', '▶', '◆', '●', '▪', '□', '■', '▲', '▼'):
        if glyph in runtime_text:
            errors.append(f"3.0.8 unsupported runtime UI glyph returned: {glyph}")
    if 'Overview | Timeline | Patterns: learn from one fight, then from repeated habits.' not in mentor_review:
        errors.append("3.0.8 Review subtitle must use font-safe ASCII separators")


    # 3.0.9 keeps the proven interrupt detector and adds optional presentation only.
    for snippet in (
        'actionGlow = true',
        'function addon:RefreshInterruptActionGlowTargets()',
        'C_ActionBar.FindSpellActionButtons',
        '_G.ActionBarButtonEventsFrame',
        'GetMacroSpell',
        'function addon:_CreateInterruptGlowFrame(button)',
        'function addon:_SetInterruptActionGlowFromNotInterruptible(glow, notInterruptible)',
        'pcall(glow.SetAlphaFromBoolean, glow, notInterruptible, 0, 1)',
        'function addon:UpdateInterruptActionGlows(hasCast, rawNotInterruptible, cooldownInfo, usable)',
        'local stillMindFreeze = self:_ActionSlotContainsMindFreeze(entry.slot, nil)',
        'function addon:SetInterruptActionGlowEnabled(enabled)',
        'function addon:SetInterruptSoundEnabled(enabled)',
        'interruptAction == "glow"',
        'interruptAction == "sound"',
        'interruptAction == "options"',
    ):
        if snippet not in core:
            errors.append(f"3.0.9 interrupt presentation regression: {snippet}")
    for snippet in (
        'SOUNDKIT.RAID_WARNING',
        'if cfg.kinds[kind].sound==nil then cfg.kinds[kind].sound=false end',
        'f.interruptGlow=Button',
        'function Studio.OpenInterrupt(parentFrame)',
    ):
        if snippet not in mentor_studio:
            errors.append(f"3.0.9 interrupt Studio regression: {snippet}")
    if 'local isNewWindow = state.targetCast.interruptKey ~= castKey' not in mentor_engine:
        errors.append("3.0.9 interrupt sound must be gated to one notification per cast window")
    if 'ActionButton_ShowOverlayGlow' in core or 'ActionButton_HideOverlayGlow' in core:
        errors.append("3.0.9 interrupt glow must not take ownership of Blizzard native proc overlays")

    # 3.0.10 Gear Mentor + Blizzard-like visual Rune ordering.
    for snippet in (
        'patch = "12.1.0"',
        'season = "Midnight Season 2"',
        'reviewed = "2026-09-03"',
        'GearData.specs[250]',
        'GearData.specs[251]',
        'GearData.specs[252]',
        'Target(268209, "Aman\'muso, Warlord\'s Vengeance"',
        'Target(268213, "Maze-roa, Warlord\'s Fury"',
        'Target(270175, "Voracious Heart of Ula\'tek"',
    ):
        if snippet not in gear_data:
            errors.append(f"3.0.10 GearData regression: {snippet}")
    for snippet in (
        'codexGearView = "overview"',
        'function addon:SetCodexGearView(viewKey)',
        'guide.gearActions = CreateFrame("Frame", nil, guide)',
        '{ key = "sources", label = T("Sources") },',
        'AddHeader("Loot sources")',
        'function addon:GetGearTargetState(target)',
        'function addon:GetGearMentorReport(specID, viewKey)',
        'AddHeader("Gear Mentor dashboard")',
        'AddHeader("Next target")',
        'if success and DB and DB.codexSection == "stats" and mainFrame and mainFrame:IsShown() then',
        'local function BuildOrderedRuneDisplayStates(now)',
        'if a.ready ~= b.ready then return a.ready end',
        'if a.progress ~= b.progress then return a.progress > b.progress end',
        'local states = BuildOrderedRuneDisplayStates(GetNow())',
        'local state = states[displayIndex]',
        'consumes from the right',
    ):
        if snippet not in core:
            errors.append(f"3.0.10 Gear/Rune regression: {snippet}")
    for snippet in (
        'for key, value in pairs(meta) do profile[key] = value end',
        'heroTalent="Deathbringer"',
        'heroSpellID=434765',
        'keyTalents=',
    ):
        if snippet not in builds:
            errors.append(f"3.0.17 richer Builds regression: {snippet}")
    if 'stats = T("Gear Mentor")' not in codex:
        errors.append("3.0.10 Codex stats section must be promoted to Gear Mentor")
    for snippet in (
        'P("Gear Mentor", "Mentor de equipamento")',
        'P("Dashboard", "Painel")',
        'P("Targets", "Alvos")',
        'P("Upgrade Plan", "Plano de melhorias")',
        'P("Sources", "Fontes")',
        'P("Loot sources", "Fontes de saque")',
        'P("Next target", "Próximo alvo")',
    ):
        if snippet not in loc:
            errors.append(f"3.0.10 Gear Mentor localization missing: {snippet}")
    if 'GearData.lua' not in (ROOT / "scripts/package.sh").read_text(encoding="utf-8"):
        errors.append("3.0.10 package.sh must include GearData.lua")
    if 'GearData.lua' not in (ROOT / "scripts/package.ps1").read_text(encoding="utf-8"):
        errors.append("3.0.10 package.ps1 must include GearData.lua")

    # 3.0.11 visual Gear Mentor presentation.
    for snippet in (
        'function addon:GetGearTargetIcon(target)',
        'C_Item.GetItemIconByID',
        'function addon:RenderGearMentorVisual(specID, viewKey)',
        'function addon:ConfigureGearItemCard(card, target, width, height)',
        'GameTooltip.SetHyperlink',
        '"item:" .. tostring(itemID)',
        '{ key = "targets", label = T("Gear") },',
        '{ key = "crafting", label = T("Crafting") },',
        'T("Hover for item details")',
        'T("Recommended gear targets")',
        'self.currentGearVisualHeight = self:RenderGearMentorVisual(specID, gearView)',
        'guide.text:Hide()',
    ):
        if snippet not in core:
            errors.append(f"3.0.11 visual Gear Mentor regression: {snippet}")
    for snippet in (
        'P("Hover an item for the full WoW tooltip",',
        'P("Recommended gear targets",',
        'P("Crests & upgrades",',
        'P("Stat direction",',
    ):
        if snippet not in loc:
            errors.append(f"3.0.11 visual Gear Mentor localization missing: {snippet}")

    # 3.0.14 Gear Mentor text-parenting and readability hotfix.
    for snippet in (
        'setID = 2055',
        'itemID = 271474',
        'itemID = 271472',
        'itemID = 271477',
        'itemID = 271475',
        'itemID = 271473',
    ):
        if snippet not in gear_data:
            errors.append(f"3.0.14 tier-set data missing: {snippet}")
    for snippet in (
        'function addon:GetEquippedTierSetState()',
        'function addon:GetTierSetName()',
        'function addon:HideGearTooltip(owner)',
        'function addon:ShowGearItemTooltip(owner, target, itemLinkOverride)',
        'root:SetScript("OnUpdate"',
        'if owner.ResetGearHover then owner:ResetGearHover() else addon:HideGearTooltip(owner) end',
        'function addon:AcquireGearTierCard(root)',
        'function addon:AcquireGearBonusCard(root)',
        'T("Season 2 set")',
        'AddSectionLabel("Season 2 tier set")',
        'T("%d/5 equipped", tierCount)',
        'GameFontNormalSmall',
    ):
        if snippet not in core:
            errors.append(f"3.0.14 visual/tier regression: {snippet}")
    for snippet in (
        'P("Hover items for WoW details",',
        'P("Season 2 set",',
        'P("Season 2 tier set",',
        'P("%d-piece bonus: %s",',
        'P("Season 2: Raid / Great Vault / Catalyst",',
    ):
        if snippet not in loc:
            errors.append(f"3.0.14 localization missing: {snippet}")


    # 3.0.16 Codex/Gear Mentor polish: no clipped guidance, visual crafting, spec icons.
    for snippet in (
        'function addon:GetSpecIconByID(specID)',
        'local function SetFlatTabButtonIcon(button, texture, size)',
        'local currentSpecIcon = select(3, self:GetSpecInfo()) or QUESTION_MARK_ICON',
        'SetFlatTabButtonIcon(button, iconTexture, 18)',
        'stats = "Equipment"',
        'check = "Character check short"',
    ):
        if snippet not in core:
            errors.append(f"3.0.16 Codex navigation regression: {snippet}")
    for snippet in (
        'craftTargets = {',
        'CraftTarget(237834, "Spellbreaker\'s Bracers"',
        'CraftTarget(237839, "Spellbreaker\'s Blade"',
        'CraftTarget(237846, "Blood Knight\'s Warblade"',
        'CraftTarget(251513, "Loa Worshiper\'s Band"',
        'CraftTarget(240949, "Masterwork Sin\'dorei Band"',
    ):
        if snippet not in gear_data:
            errors.append(f"3.0.16 craft target data missing: {snippet}")
    for snippet in (
        'AddSectionLabel("Recommended crafts")',
        'local craftTargets = spec.craftTargets or {}',
        'AddItemGrid(craftTargets, 82)',
        'target.craft and T("CRAFT") or T("TARGET")',
        'GameTooltip:AddLine(T("Embellishment: %s", T(target.embellishment))',
        'text:SetWordWrap(true)',
        'card.name:SetWordWrap(true)',
        'card.status:SetWordWrap(true)',
        'card.label:SetText(card.bonusTitle)',
    ):
        if snippet not in core:
            errors.append(f"3.0.16 Gear Mentor visual/cutoff regression: {snippet}")
    render_start = core.find('function addon:RenderGearMentorVisual(specID, viewKey)')
    render_end = core.find('function addon:GetGearMentorReport(specID, viewKey)')
    if render_start >= 0 and render_end > render_start and 'CompactGearText' in core[render_start:render_end]:
        errors.append("3.0.16 Gear Mentor visual renderer must not intentionally truncate text with CompactGearText")
    for snippet in (
        'P("Equipment", "Equipamento")',
        'P("Character check short", "Verificação")',
        'P("Upgrade plan", "Plano de melhorias")',
        'P("CRAFT", "CRAFTAR")',
        'P("Recommended crafts", "Crafts recomendados")',
        'P("Hover for item details", "Passe o mouse para detalhes")',
    ):
        if snippet not in loc:
            errors.append(f"3.0.16 localization missing: {snippet}")

    # 3.0.17 visual Build Mentor.
    for snippet in (
        'codexBuildContext = "auto"',
        'function addon:GetCodexBuildContext()',
        'function addon:SetCodexBuildContext(contextKey)',
        'guide.buildContextButtons = {}',
        'function addon:AcquireBuildTalentCard(root)',
        'function addon:AcquireBuildProfileCard(root)',
        'function addon:RenderBuildMentorVisual(specID, contextKey, autoDetected)',
        'GameTooltip.SetSpellByID',
        'self.currentBuildVisualHeight = self:RenderBuildMentorVisual(specID, context, autoDetected)',
    ):
        if snippet not in core:
            errors.append(f"3.0.17 visual Build Mentor regression: {snippet}")
    for snippet in (
        'world = {',
        'delve = {',
        'dungeon = {',
        'mythicplus = {',
        'raid = {',
        'pvp = {',
        'heroSpellID=434765',
        'heroSpellID=444040',
        'spellID = 51271',
        'spellID = 49028',
        'spellID = 63560',
    ):
        if snippet not in builds:
            errors.append(f"3.0.17 build profile data missing: {snippet}")
    for snippet in (
        'P("Build Mentor — %s",',
        'P("AUTO • following detected content",',
        'P("Manual content selection",',
        'P("Hero Talent: %s",',
        'P("Key talents",',
        'P("RECOMMENDED",',
        'P("ALTERNATIVE",',
        'P("Rider of the Apocalypse",',
    ):
        if snippet not in loc:
            errors.append(f"3.0.17 Build Mentor localization missing: {snippet}")

    # 3.1 Preparation / Ready Check.
    for snippet in (
        'patch = "12.1.0"',
        'reviewed = "2026-09-03"',
        'itemID=240983',
        'itemID=241288',
        'itemID=243734',
        'itemID=259085',
        'enchantID=6241',
        'enchantID=6245',
        'enchantID=3370',
        'enchantID=3847',
    ):
        if snippet not in preparation_data:
            errors.append(f"3.1 PreparationData regression: {snippet}")
    for snippet in (
        'codexBuildMode = "standard"',
        'function addon:GetPreparationReadyStatus(specID)',
        'function addon:GetRecommendedRuneforgeStatus(specID)',
        'elseif viewKey == "preparation" then',
        '{ key = "preparation", label = T("Preparation") },',
        'function addon:GetCodexBuildMode()',
        'function addon:SetCodexBuildMode(mode)',
        'profile.sbaFriendly == true',
        'local sourceOrder = {}',
        'function addon:ExportLayoutPreset()',
        'function addon:ImportLayoutPreset(text)',
        'not text:match("^DKM31;")',
        '#text > 12000',
        'DB.hudLocked = true',
        'addon.LICH_KING_CREATURE_ID = 36597',
        'addon.LICH_KING_BOLVAR_CREATURE_ID = 99456',
        'frame:SetFrameStrata("FULLSCREEN_DIALOG")',
        'frame:SetFrameLevel(1400)',
        'voice.portraitCharacterButton:SetPoint("LEFT", voice.portraitScaleButton, "RIGHT", 8, 0)',
        'addon.LICH_KING_CHARACTERS = {',
        'function addon:SetLichKingPortraitCharacter(characterKey)',
        'function addon:CycleLichKingPortraitCharacter()',
        'DB.voice.portrait.character = characterKey',
        'tostring(vp.character == "bolvar" and "bolvar" or "arthas")',
        'if fields[9] == "arthas" or fields[9] == "bolvar" then vp.character = fields[9] end',
        'addon.LICH_KING_FALLBACK_ICON = "Interface\\\\Icons\\\\Achievement_Boss_LichKing"',
        'addon.lichKingPortraitFrame = addon.CreateLichKingPortraitFrame()',
        'self:ShowLichKingPortrait()',
        'frame:SetSize(820, 720)',
        'page:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -104)',
        'frame.hudSection = CreateSection(settingsPage, T("HUDs and layout"), -38, 288)',
        'voiceBusyUntil = addon.voiceStartedAt + 7',
        'if now - (addon.voiceStartedAt or 0) < 0.20 then',
        'voiceBusyUntil = 0',
        'if self.elapsed < 0.10 then return end',
        'cfg.positionVersion = 2',
        'frame:SetPoint(point, parent, point, x / scale, y / scale)',
        'if cfg.positionVersion == 2 then',
        'if not frame.dragging then addon.RestoreLichKingPortraitPosition() end',
        'vp.positionVersion = tonumber(fields[10]) == 2 and 2 or nil',
    ):
        if snippet not in core:
            errors.append(f"3.1 Core regression: {snippet}")
    for snippet in (
        'profile.sbaFriendly = profile.heroTalent == "Deathbringer"',
        'profile.sbaFriendly = not (contextKey == "pvp" and profile.heroTalent == "Deathbringer")',
        'profile.sbaFriendly = profile.heroTalent == "Rider of the Apocalypse"',
        'FROST_SBA_CORE',
    ):
        if snippet not in builds:
            errors.append(f"3.1 SBA build regression: {snippet}")
    for snippet in (
        'P("Preparation", "Preparação")',
        'P("SBA-friendly", "SBA-friendly")',
        'P("Layout presets...", "Presets de layout...")',
        'P("Portrait: ON", "Retrato: LIGADO")',
        'P("Portrait character: %s", "Personagem do retrato: %s")',
        'P("Current Unholy personal-food option.", "Opção atual de comida pessoal para Profano.")',
    ):
        if snippet not in loc:
            errors.append(f"3.1 localization missing: {snippet}")
    if 'PreparationData.lua' not in (ROOT / "scripts/package.sh").read_text(encoding="utf-8"):
        errors.append("3.1 package.sh must include PreparationData.lua")
    if 'PreparationData.lua' not in (ROOT / "scripts/package.ps1").read_text(encoding="utf-8"):
        errors.append("3.1 package.ps1 must include PreparationData.lua")
    if 'loadstring' in core or 'RunScript' in core:
        errors.append("3.1 preset import must not evaluate script text")

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
