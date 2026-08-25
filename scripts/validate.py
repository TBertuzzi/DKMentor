#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = "1.2.3"
INTERFACE = "120100"

REQUIRED = [
    "DKMentor.toc", "Localization.lua", "Data.lua", "Builds.lua", "Guides.lua",
    "Voices.lua", "Core.lua", "README.md", "CHANGELOG.md", "LICENSE",
    "THIRD_PARTY_NOTICES.md", "POLICY_AND_SOURCES.md", "PUBLISHING.md",
    "Media/DKArcFill.tga", "Media/DKArcBG.tga", "Media/DKArcGlow.tga",
    "Media/DKArcFillRight.tga", "Media/DKArcBGRight.tga", "Media/DKArcGlowRight.tga",
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

    if f"## {VERSION}" not in (ROOT / "CHANGELOG.md").read_text(encoding="utf-8"):
        errors.append(f"CHANGELOG.md has no {VERSION} entry")

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


    # 1.0.10 regression guards: runtime context must be automatic-only and War Mode experiment absent.
    if 'function addon:DetectContext()' not in core or 'return self:DetectActualContext(), true' not in core:
        errors.append("Automatic-only runtime context detection is missing")
    if 'DB.modeOverride = "auto"' not in core:
        errors.append("Legacy modeOverride migration is missing")
    if 'contexts = { "world", "delve", "dungeon", "mythicplus", "raid", "pvp" }' not in core:
        errors.append("Expected World/Delve/Dungeon/Mythic+/Raid/PvP selector set is missing")
    for forbidden_warmode in ("UpdateWarModeButton", "ToggleWarMode", "SetWarModeDesired", "warModeButton", "warmode ="):
        if forbidden_warmode in core:
            errors.append(f"Experimental War Mode logic must not be present: {forbidden_warmode}")

    # 1.0.10 secret-value regression guards. PvP can return secret booleans from Unit APIs.
    forbidden_secret_bool_patterns = (
        'UnitIsAFK("player") == true',
        'UnitExists("pet") then',
        'UnitIsDeadOrGhost("player"))',
        'IsMounted() == true',
        'value ~= nil then\n            return value == true',
    )
    for pattern in forbidden_secret_bool_patterns:
        if pattern in core:
            errors.append(f"Secret boolean must be guarded before comparison/branch: {pattern}")
    if "local function GetAccessibleBoolean(value)" not in core:
        errors.append("GetAccessibleBoolean secret-value guard is missing")

    # 1.0.13 proc/interrupt feature guards.
    if 'function addon:UpdateInterruptAlert()' not in core:
        errors.append("Mind Freeze interrupt alert is missing")
    if 'SPELL_ACTIVATION_OVERLAY_GLOW_SHOW' not in core or 'activeProcGlows' not in core:
        errors.append("Dynamic proc-glow tracking is missing")
    if 'frame.slotsPerRow = GetConfiguredBarColumns(dbKey, slotsPerRow or maxSlots, maxSlots)' not in core:
        errors.append("Wrapped DK buff-bar layout support is missing")
    if 'GetAccessibleBoolean(notInterruptible)' not in core:
        errors.append("Interruptibility secret-value guard is missing")
    if 'CastSpellByName' in core or 'CastSpellByID' in core:
        errors.append("Interrupt alert must never cast Mind Freeze")

    if 'mirroredActiveBuffOrder' not in core or 'GetMirrorItemDisplaySpellID' not in core:
        errors.append("Active Blizzard tracked-buff mirroring is missing")
    if 'ResolveProcGlowDisplaySpellID' not in core or 'Data.procGlowMappings' not in data:
        errors.append("DK proc-glow to aura mapping is missing")
    if 'SyncKnownProcGlowStates' not in core or 'C_SpellActivationOverlay.IsSpellOverlayed' not in core:
        errors.append("Known proc-glow polling fallback is missing")
    for frost_proc in (51124, 59052, 1229310, 194879, 377101, 377103, 1230916):
        if str(frost_proc) not in data:
            errors.append(f"Missing Frost proc/buff tracking ID {frost_proc}")

    # 1.0.13 active-only buff bar regression guards.
    if 'if visibleCount <= 0 then' not in core or 'buffFrame:Hide()' not in core:
        errors.append("DK Buff bar must hide when no DK buff/proc is active")
    if 'inactive/dim placeholders remain' not in core:
        errors.append("Active-only DK buff list implementation is missing")
    if 'self:RefreshCooldownViewerBuffMirrors()' not in core:
        errors.append("DK Buff bar must poll Blizzard tracked-buff mirrors")
    if 'item.GetAuraSpellID' not in core or 'item.GetAuraSpellInstanceID' not in core:
        errors.append("Blizzard materialized aura identity/instance bridge is missing")

    # 1.0.15 Wowhead Cooldown Manager profile integration guards.
    if 'Data.cooldownManagerProfiles' not in data:
        errors.append("Cooldown Manager profile metadata is missing")
    for cooldown_id in (92575, 86579, 92577, 86281, 90617, 92923, 90603, 90611, 92535, 92533):
        if str(cooldown_id) not in data:
            errors.append(f"Missing researched Cooldown Manager ID {cooldown_id}")
    if 'BuildCooldownManagerProfileSpellList' not in core or 'GetCachedCooldownViewerInfo' not in core:
        errors.append("Safe Cooldown Manager profile resolver is missing")
    # This public API has AllowedWhenUntainted secret arguments in Midnight;
    # DK Mentor must consume Blizzard's already-built provider/frame cache instead.
    if 'pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo' in core:
        errors.append("Protected Cooldown Viewer info API must not be called directly")
    if 'cooldownUseAuraDisplayTime' not in core or 'wasSetFromAura' not in core:
        errors.append("Materialized aura visual-state bridge is missing")
    for proc_id in (1265790, 1297365, 1254252, 1242223, 433925, 434157, 1233448):
        if str(proc_id) not in data:
            errors.append(f"Missing Midnight 12.1 proc/buff tracking ID {proc_id}")

    # 1.0.16 native AuraContainer + combat-exit regression guards.
    if 'schema = 29' not in core or 'combatBarsOnlyInCombat = true' not in core:
        errors.append("Current settings schema/combat-only default is missing")
    if 'if previousSchema < 21 then' not in core or 'DB.combatBarsOnlyInCombat = true' not in core:
        errors.append("Existing installs are not migrated back to combat-only HUDs")
    if 'CreateManagedAuraBar(' not in core or '"DKMentorBuffBar"' not in core:
        errors.append("Primary DK Buffs AuraContainer path is missing")
    if 'includeSpellIDs = BuildDKBuffIncludeSpellIDs(specID)' not in core:
        errors.append("DK Buffs spell-ID candidate filter is missing")
    if 'SetAuraGroupCandidateFilters' not in core or 'RefreshManagedDKBuffFilter' not in core:
        errors.append("Live DK Buffs candidate-filter refresh is missing")
    if 'pcall(container.SetEnabled, container, true)' not in core:
        errors.append("AuraContainer SetEnabled activation is missing")
    unit_pos = core.find('pcall(container.SetUnit, container, "player")')
    group_pos = core.find('pcall(container.AddAuraGroup, container, dbKey, filterString, options)')
    enable_pos = core.find('pcall(container.SetEnabled, container, true)')
    if min(unit_pos, group_pos, enable_pos) < 0 or not (unit_pos < group_pos < enable_pos):
        errors.append("AuraContainer initialization order must be SetUnit -> AddAuraGroup -> SetEnabled")
    if 'function addon:SyncCombatEventState()' not in core:
        errors.append("Combat-state resynchronization helper is missing")
    if 'C_Timer.After(0.25' not in core or 'addon:RefreshCombatHUDVisibility()' not in core:
        errors.append("Delayed combat-exit visibility assertion is missing")
    for season2_buff in (1310372, 1300369):
        if str(season2_buff) not in data:
            errors.append(f"Missing Blood Season 2 buff tracking ID {season2_buff}")

    # 1.0.17 configurable combat-bar layout + Preview hard-override guards.
    for snippet in (
        'iconsPerRow = 5',
        'iconsPerRow = 11',
        'function addon:SetCombatBarScale(dbKey, value)',
        'function addon:SetCombatBarColumns(dbKey, value)',
        'function addon:ResetCombatBarLayout()',
        'local function ShowManagedAuraPreview(frame, slotStore)',
        'local function RestoreManagedAuraRuntime(frame, slotStore)',
        'self.hudPreviewMode ~= true and DB.combatBarsOnlyInCombat == true',
    ):
        if snippet not in core:
            errors.append(f"1.0.17 bar-layout/Preview regression guard missing: {snippet}")
    if 'P("HUD size...", "Tamanho dos HUDs...")' not in localization:
        errors.append("Combat-HUD layout ptBR localization is missing")

    # 1.0.18 regression guard: preview/runtime helpers must see the local cooldown
    # reset helper. In Lua, a later `local function` is NOT visible to functions
    # compiled before its declaration, which broke both normal DK Buffs and Preview.
    clear_cd_pos = core.find('local function ClearTrackingCooldown(slot)')
    hide_slots_pos = core.find('local function HideTrackingSlots(slotStore)')
    preview_pos = core.find('local function ShowManagedAuraPreview(frame, slotStore)')
    if min(clear_cd_pos, hide_slots_pos, preview_pos) < 0 or not (clear_cd_pos < hide_slots_pos < preview_pos):
        errors.append("ClearTrackingCooldown must be declared before managed-aura runtime/preview helpers")

    # 1.0.19 regression guard: HUD lock is interaction-only. Managed aura bars
    # must not become visually transparent just because dragging is disabled.
    chrome_start = core.find('local function UpdateManagedAuraBarChrome(frame)')
    chrome_end = core.find('local MANAGED_AURA_ICON_SIZE', chrome_start)
    chrome_block = core[chrome_start:chrome_end] if chrome_start >= 0 and chrome_end > chrome_start else ''
    if 'frame.label:SetShown(true)' not in chrome_block:
        errors.append("Managed-aura labels must remain visible when HUDs are locked")
    if 'frame:EnableMouse(editing)' not in chrome_block:
        errors.append("HUD lock must still disable managed-aura mouse interaction")
    if 'frame:SetBackdropColor(0, 0, 0, 0)' in chrome_block or 'frame:SetBackdropBorderColor(0, 0, 0, 0)' in chrome_block:
        errors.append("HUD lock must not make managed-aura bars transparent")

    # 1.0.20 DK resource HUD + Midnight secret-value regression guards.
    for snippet in (
        'resourceHUD = {',
        'local function CreateResourceHUD()',
        'for index = 1, 6 do',
        'pcall(GetRuneCooldown, index)',
        'pcall(UnitPower, "player", RUNIC_POWER_TYPE)',
        'pcall(UnitPowerMax, "player", RUNIC_POWER_TYPE)',
        'resourceFrame.power.SetMinMaxValues',
        'resourceFrame.power.SetValue',
        'function addon:UpdateResourceHUD()',
        'function addon:CycleResourceHUDMode()',
        '"UNIT_DISPLAYPOWER"',
        '"RUNE_POWER_UPDATE"',
        'command == "resources" or command == "resource"',
        'self.hudPreviewMode ~= true and DB.combatBarsOnlyInCombat == true',
    ):
        if snippet not in core:
            errors.append(f"1.0.20 resource-HUD regression guard missing: {snippet}")

    resource_update_start = core.find('function addon:UpdateRunicPowerHUD()')
    resource_update_end = core.find('function addon:UpdateResourceHUD()', resource_update_start)
    resource_update = core[resource_update_start:resource_update_end] if resource_update_start >= 0 and resource_update_end > resource_update_start else ''
    native_value_pos = resource_update.find('resourceFrame.power.SetValue')
    readable_guard_pos = resource_update.find('if IsAccessibleNumber(power) and IsAccessibleNumber(maxPower) then')
    numeric_format_pos = resource_update.find('math.floor(power + 0.5)')
    if min(native_value_pos, readable_guard_pos, numeric_format_pos) < 0 or not (native_value_pos < readable_guard_pos < numeric_format_pos):
        errors.append("Runic Power must flow to the native StatusBar before any readable-only numeric formatting")
    for forbidden in ('if power >', 'if power <', 'if power ==', 'if power >=', 'if power <='):
        if forbidden in resource_update:
            errors.append(f"Runic Power secret value must not drive combat logic: {forbidden}")

    if 'if InCombatLockdown and InCombatLockdown() then\n        Print(T("HUD preview cannot be changed during combat."))' not in core:
        errors.append("HUD Preview must be blocked during combat for secret-safe resource anchoring")
    if core.count('Print(T("HUD positions cannot be changed during combat."))') < 2:
        errors.append("HUD position resets must be blocked during combat")
    for loc_snippet in (
        'P("DK Resources", "Recursos do DK")',
        'P("Runes + Runic Power", "Runas + Poder Rúnico")',
        'P("Runes only", "Só Runas")',
        'P("Runic Power only", "Só Poder Rúnico")',
    ):
        if loc_snippet not in localization:
            errors.append(f"1.0.20 resource-HUD ptBR localization missing: {loc_snippet}")

    # 1.0.21 HUD appearance controls.
    for snippet in (
        'opacity = 1',
        'function addon:SetCombatBarOpacity(dbKey, value)',
        'local function NormalizeCombatBarOpacity(value)',
        'frame:SetAlpha(config.opacity)',
        'showPowerText = true',
        'runeSpacing = "normal"',
        'function addon:SetResourceHUDPowerTextEnabled(enabled)',
        'function addon:CycleResourceRuneSpacing()',
        'function addon:ResetResourceHUDLayout()',
        'RESOURCE_RUNE_LAYOUTS',
        'resourceFrame.layoutRuneSpacing',
    ):
        if snippet not in core:
            errors.append(f"1.0.21 HUD-appearance regression guard missing: {snippet}")
    if core.count('opacity = 1') < 5:
        errors.append("Every configurable combat HUD must default to full opacity")
    for loc_snippet in (
        'P("Opacity", "Opacidade")',
        'P("Power text: ON", "Texto do Poder: LIGADO")',
        'P("Rune spacing: %s", "Espaçamento das Runas: %s")',
        'P("Restore DK Resources", "Restaurar Recursos do DK")',
        'P("HUD appearance...", "Aparência dos HUDs...")',
    ):
        if loc_snippet not in localization:
            errors.append(f"1.0.21 HUD-appearance ptBR localization missing: {loc_snippet}")

    for rel in ("RELEASE_NOTES_v1.0.21.md", "TESTING_v1.0.21.md"):
        if not (ROOT / rel).is_file():
            errors.append(f"Missing 1.0.21 release document: {rel}")

    # 1.1.5 DK Arcs mirroring/movement/opening regression guards.
    for snippet in (
        'DK_ARC_FILL_TEXTURE',
        'DK_ARC_FILL_RIGHT_TEXTURE',
        'DK_ARC_BG_RIGHT_TEXTURE',
        'DK_ARC_GLOW_RIGHT_TEXTURE',
        'CreateDKArcBar',
        'holder.bar:SetOrientation("VERTICAL")',
        'DK_RUNE_TEXTURE',
        'GetDKRuneColors',
        'SaveResourceArcPosition',
        'RestoreResourceArcPosition',
        'NormalizeResourceArcSpacing',
        'function addon:SetResourceArcSpacing(value)',
        'SetResourceArcHealthColors',
    ):
        if snippet not in core:
            errors.append(f"1.1.5 DK Arcs regression guard missing: {snippet}")
    for rel in ("RELEASE_NOTES_v1.1.5.md", "TESTING_v1.1.5.md"):
        if not (ROOT / rel).is_file():
            errors.append(f"Missing 1.1.5 release document: {rel}")

    classic_start = core.find('local function CreateResourceHUD()')
    classic_end = core.find('local DK_ARC_FILL_TEXTURE', classic_start)
    classic_body = core[classic_start:classic_end] if classic_start >= 0 and classic_end > classic_start else ''
    if 'RestoreFramePosition(frame, "resourceHUD")' not in classic_body:
        errors.append('Classic DK Resources lost its saved-position restore path')
    arc_start = core.find('local function CreateResourceArcHUD()')
    arc_end = core.find('local COMBAT_BAR_LAYOUT_LIMITS', arc_start)
    arc_body = core[arc_start:arc_end] if arc_start >= 0 and arc_end > arc_start else ''
    if 'RestoreResourceArcPosition(frame)' not in arc_body:
        errors.append('DK Arcs lost its independent saved-position restore path')
    if 'SaveResourceArcPosition(self)' not in arc_body:
        errors.append('DK Arcs is no longer movable/saving its position')
    if 'dragHandle = CreateFrame' in arc_body or 'frame.label = frame.dragHandle' in arc_body:
        errors.append('DK Arcs must not recreate the visible Arcos do DK/Move header')
    if 'CenterResourceArcHUD' in core:
        errors.append('Legacy forced-centering helper must not remain in DK Arcs 1.1.5')

    # 1.1.6 low-health arc warning regression guard.
    for snippet in (
        'local percent = GetPlayerHealthPercent()',
        'local low = IsAccessibleNumber(percent) and percent <= 30',
        'resourceArcFrame.healthBar:SetStatusBarColor(0.92, 0.20, 0.20, 0.98)',
    ):
        if snippet not in core:
            errors.append(f"1.1.6 low-health warning regression guard missing: {snippet}")
    for rel in ("RELEASE_NOTES_v1.1.6.md", "TESTING_v1.1.6.md"):
        if not (ROOT / rel).is_file():
            errors.append(f"Missing 1.1.6 release document: {rel}")



    # 1.1.8 selectable addon-language regression guards.
    for snippet in (
        'languageOverride = "auto"',
        'function addon:SetLanguageOverride(value)',
        'function addon:ToggleLanguagePicker()',
        'function addon:UpdateLanguageSettings()',
        'languagePickerFrame = CreateLanguagePickerFrame()',
        'DKM.SetLocaleOverride(DB.languageOverride)',
        'command == "language" or command == "lang" or command == "idioma"',
    ):
        if snippet not in core:
            errors.append(f"1.1.8 language-selection regression guard missing: {snippet}")
    for loc_snippet in (
        'function DKM.SetLocaleOverride(value)',
        'P("Automatic (WoW)", "Automático (WoW)")',
        'P("Portuguese (Brazil)", "Português (Brasil)")',
        'P("Language: %s", "Idioma: %s")',
    ):
        if loc_snippet not in localization:
            errors.append(f"1.1.8 language localization guard missing: {loc_snippet}")
    for rel in ("RELEASE_NOTES_v1.1.8.md", "TESTING_v1.1.8.md"):
        if not (ROOT / rel).is_file():
            errors.append(f"Missing 1.1.8 release document: {rel}")

    # 1.1.7 packaging regression guard: both arc sides must ship in every addon ZIP.
    package_sh = (ROOT / "scripts/package.sh").read_text(encoding="utf-8")
    package_ps1 = (ROOT / "scripts/package.ps1").read_text(encoding="utf-8")
    if 'cp -a "$ROOT/Media/." "$STAGE/Media/"' not in package_sh:
        errors.append("package.sh must copy the complete Media folder")
    if 'Copy-Item $MediaSource $MediaDest -Recurse -Force' not in package_ps1:
        errors.append("package.ps1 must copy the complete Media folder")
    for rel in (
        "Media/DKArcFill.tga", "Media/DKArcBG.tga", "Media/DKArcGlow.tga",
        "Media/DKArcFillRight.tga", "Media/DKArcBGRight.tga", "Media/DKArcGlowRight.tga",
    ):
        if not (ROOT / rel).is_file():
            errors.append(f"DK Arcs package asset missing: {rel}")


    # 1.2.0 Loadouts 2.0 regression guards.
    for snippet in (
        'specializationBindings = {}',
        'dungeonOverrides = {}',
        'knownDungeons = {}',
        'autoSwitchSpecialization = true',
        'function addon:ResolveRuntimeSpecializationTarget(context)',
        'function addon:TryAutoSwitchSpecialization(reason)',
        'function addon:ApplyAutomaticProfile(reason)',
        'function addon:CanAutoSwitchSpecialization(targetSpecID, context)',
        'UnitGroupRolesAssigned',
        'if specID == 250 then return "TANK" end',
        'function addon:GetCurrentSeasonDungeonCatalog()',
        'C_ChallengeMode.GetMapScoreInfo',
        'C_ChallengeMode.GetMapTable',
        'C_ChallengeMode.GetMapUIInfo',
        'function addon:GetActiveDungeonOverride()',
        'function addon:FindDungeonOverrideForIdentity(identity, includeDisabled)',
        'function addon:ApplyDungeonOverrideIfCurrent(key, reason)',
        'SPECIALIZATION_CHANGE_CAST_FAILED',
        'function addon:ResolveRuntimeLoadoutBinding(specID, context)',
        'function addon:ResolveRuntimeEquipmentBinding(specID, context)',
        'function addon:CreateDungeonOverridesFrame()',
        'function addon:CreateDungeonOverrideEditorFrame()',
        'function addon:CreateProfileSpecializationPickerFrame()',
        'addon:ToggleSpecializationPicker()',
        'Dungeon overrides...',
    ):
        if snippet not in core:
            errors.append(f"1.2.0 Loadouts 2.0 regression guard missing: {snippet}")
    for loc_snippet in (
        'P("Spec AUTO: ON", "Spec AUTO: LIGADO")',
        'P("Dungeon Overrides", "Overrides de Masmorra")',
        'P("Do not change", "Não alterar")',
        'P("Role protection: your group role is %s, but the target specialization is %s (%s). Automatic specialization switching was skipped."',
    ):
        if loc_snippet not in localization:
            errors.append(f"1.2.0 Loadouts localization guard missing: {loc_snippet}")
    if 'if previousSchema < 28 then' not in core:
        errors.append("1.2.0 schema migration is missing")
    if core.count('self:ApplyAutomaticProfile(') + core.count('addon:ApplyAutomaticProfile(') < 5:
        errors.append("Automatic profile orchestration is not wired to enough runtime transitions")
    for rel in ("RELEASE_NOTES_v1.2.0.md", "TESTING_v1.2.0.md"):
        if not (ROOT / rel).is_file():
            errors.append(f"Missing 1.2.0 release document: {rel}")

    # 1.2.1 Loadout Pilot parity: Mythic+ defaults, unified dungeon identity,
    # independent Loot Specialization, and override-picker layering.
    for snippet in (
        'schema = 29',
        'if previousSchema < 29 then',
        'DB.specializationBindings.mythicplus = DB.specializationBindings.dungeon',
        'function addon:GetMythicPlusMapID()',
        'C_ChallengeMode.HasSlottedKeystone',
        'C_ChallengeMode.GetSlottedKeystoneInfo',
        'function addon:GetChallengeDungeonIdentity(challengeMapID)',
        'EJ_GetInstanceForMap',
        'EJ_GetInstanceInfo',
        '"dungeon:" .. tostring',
        'function addon:MigrateDungeonOverrideIdentity(oldKey, newKey, info)',
        'function addon:MigrateUnifiedDungeonOverrides()',
        'function addon:GetDungeonFallbackContext(entry)',
        'function addon:GetLootSpecializationID()',
        'SetLootSpecialization',
        'function addon:SyncDungeonLootSpecialization(reason)',
        'function addon:SetDungeonOverrideLootSpec(key, specID)',
        'function addon:SyncPendingEquipmentState(announce)',
        'pending-equipment-retry',
        'equipment-swap-finished',
        'function addon:CreateLootSpecializationPickerFrame()',
        'PLAYER_LOOT_SPEC_UPDATED',
        'PLAYER_ROLES_ASSIGNED',
        'UPDATE_BATTLEFIELD_STATUS',
        'CHALLENGE_MODE_KEYSTONE_SLOTTED',
        'CHALLENGE_MODE_RESET',
    ):
        if snippet not in core:
            errors.append(f"1.2.1 dungeon/loadout regression guard missing: {snippet}")

    if 'Data.contextOrder = { "world", "delve", "dungeon", "mythicplus", "raid", "pvp" }' not in data:
        errors.append("1.2.1 Data.contextOrder must expose a separate Mythic+ profile")

    # 1.2.2 hotfix regression guard: the schema-29 migration must use the
    # existing DeepCopy helper. 1.2.1 accidentally referenced a nonexistent
    # CopyTableDeep global and crashed InitializeDatabase before the UI loaded.
    if 'CopyTableDeep(' in core:
        errors.append("1.2.2 migration must not reference undefined CopyTableDeep")
    migration_start = core.find('if previousSchema < 29 then')
    migration_end = core.find('DB.schema = DEFAULTS.schema', migration_start)
    migration_body = core[migration_start:migration_end] if migration_start >= 0 and migration_end > migration_start else ''
    if 'DeepCopy(DB.loadoutBindings[dungeonKey])' not in migration_body:
        errors.append("1.2.2 Mythic+ talent migration must use DeepCopy")
    if 'DeepCopy(DB.equipmentBindings[dungeonKey])' not in migration_body:
        errors.append("1.2.2 Mythic+ equipment migration must use DeepCopy")
    if core.find('local function DeepCopy(value)') < 0 or core.find('local function DeepCopy(value)') > core.find('function addon:InitializeDatabase()'):
        errors.append("1.2.2 DeepCopy helper must be declared before InitializeDatabase")
    if 'if result then\n            self.pendingEquipmentKey = nil' in core:
        errors.append("Gear pending state must not clear blindly on EQUIPMENT_SWAP_FINISHED")

    # Verify the requested sequence without requiring Loot Spec to wait for a
    # role-blocked playing-spec switch. Loot Spec is intentionally independent.
    apply_start = core.find('function addon:ApplyAutomaticProfile(reason)')
    apply_end = core.find('function addon:SetAutoSwitchLoadouts', apply_start)
    apply_body = core[apply_start:apply_end] if apply_start >= 0 and apply_end > apply_start else ''
    spec_pos = apply_body.find('self:TryAutoSwitchSpecialization(reason)')
    loot_pos = apply_body.find('self:SyncDungeonLootSpecialization(reason)')
    talent_pos = apply_body.find('self:TryAutoSwitchLoadout(reason)')
    gear_pos = apply_body.find('self:TryAutoSwitchEquipment(reason)')
    if min(spec_pos, loot_pos, talent_pos, gear_pos) < 0 or not (spec_pos < loot_pos < talent_pos < gear_pos):
        errors.append("1.2.1 apply order must be playing spec -> loot spec -> talents -> equipment")
    mismatch_guard_pos = apply_body.find('if targetSpecID and currentSpecID ~= targetSpecID then return false end')
    if mismatch_guard_pos < 0 or loot_pos > mismatch_guard_pos:
        errors.append("Loot Spec must be applied even if playing-spec automation is pending/role-blocked")

    # The community-reported UI bug was caused by child pickers rendering
    # behind the Dungeon Override editor. Check each picker constructor.
    picker_markers = (
        ('function addon:CreateProfileSpecializationPickerFrame()', 'function addon:UpdateProfileSpecializationPicker'),
        ('function addon:CreateLootSpecializationPickerFrame()', 'function addon:UpdateLootSpecializationPicker'),
        ('local function CreateLoadoutPickerFrame()', 'local function CreateEquipmentPickerFrame()'),
        ('local function CreateEquipmentPickerFrame()', 'local function CreateVoiceConfigFrame()'),
    )
    for start_marker, end_marker in picker_markers:
        start = core.find(start_marker)
        end = core.find(end_marker, start + 1)
        body = core[start:end] if start >= 0 and end > start else ''
        if 'SetFrameStrata("FULLSCREEN_DIALOG")' not in body or 'SetFrameLevel(1200)' not in body:
            errors.append(f"1.2.1 picker must render above Dungeon Overrides: {start_marker}")

    editor_start = core.find('function addon:CreateDungeonOverrideEditorFrame()')
    editor_end = core.find('function addon:OpenDungeonOverrideEditor', editor_start)
    editor_body = core[editor_start:editor_end] if editor_start >= 0 and editor_end > editor_start else ''
    if 'SetFrameStrata("FULLSCREEN_DIALOG")' not in editor_body or 'SetFrameLevel(900)' not in editor_body:
        errors.append("Dungeon Override editor must remain below its pickers")

    for loc_snippet in (
        'P("Mythic+", "Mítica+")',
        'P("Loot specialization", "Especialização de saque")',
        'P("No override", "Sem override")',
        'P("Current specialization (%s)", "Especialização atual (%s)")',
        'P("Dungeon override: ACTIVE", "Override de masmorra: ATIVO")',
    ):
        if loc_snippet not in localization:
            errors.append(f"1.2.1 localization guard missing: {loc_snippet}")

    for rel in ("RELEASE_NOTES_v1.2.1.md", "TESTING_v1.2.1.md"):
        if not (ROOT / rel).is_file():
            errors.append(f"Missing 1.2.1 release document: {rel}")

    for rel in ("RELEASE_NOTES_v1.2.2.md", "TESTING_v1.2.2.md"):
        if not (ROOT / rel).is_file():
            errors.append(f"Missing 1.2.2 hotfix document: {rel}")


    # 1.2.3 Loadout Pilot responsiveness + compact HUD shortcut guards.
    manual_spec_start = core.find('function addon:SwitchSpecialization(index)')
    manual_spec_end = core.find('function addon:DetectActualContext()', manual_spec_start)
    manual_spec_body = core[manual_spec_start:manual_spec_end] if manual_spec_start >= 0 and manual_spec_end > manual_spec_start else ''
    auto_spec_start = core.find('function addon:TryAutoSwitchSpecialization(reason)')
    auto_spec_end = core.find('function addon:ApplyAutomaticProfile(reason)', auto_spec_start)
    auto_spec_body = core[auto_spec_start:auto_spec_end] if auto_spec_start >= 0 and auto_spec_end > auto_spec_start else ''
    if manual_spec_body.find('C_SpecializationInfo.SetSpecialization') < 0 or manual_spec_body.find('C_SpecializationInfo.SetSpecialization') > manual_spec_body.find('C_ClassTalents.SwitchToSpecializationByIndex'):
        errors.append("1.2.3 manual spec switching must prefer the Loadout Pilot SetSpecialization path")
    if auto_spec_body.find('C_SpecializationInfo.SetSpecialization') < 0 or auto_spec_body.find('C_SpecializationInfo.SetSpecialization') > auto_spec_body.find('C_ClassTalents.SwitchToSpecializationByIndex'):
        errors.append("1.2.3 automatic spec switching must prefer the Loadout Pilot SetSpecialization path")
    if '(now - self.lastSpecializationSwitchAttemptAt) < 2 then' not in auto_spec_body:
        errors.append("1.2.3 automatic specialization retry throttle must be 2 seconds")
    for snippet in (
        'function addon:SchedulePendingSpecializationRetry(targetSpecID, delay)',
        'addon:SchedulePendingSpecializationRetry(targetSpecID, 2.0)',
        'self:SchedulePendingSpecializationRetry(targetSpecID, 2.0)',
        'addon:ApplyAutomaticProfile("world-ready")',
        'C_Timer.After(1.0, function()',
        'C_Timer.After(0.5, function()',
        'frame:SetScript("OnMouseUp", function(_, mouseButton)',
        'frame.specButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")',
        'addon:ToggleMainFrame()',
        'Right-click: open or close DK Mentor',
    ):
        if snippet not in core and snippet not in localization:
            errors.append(f"1.2.3 responsiveness/HUD regression guard missing: {snippet}")
    for rel in ("RELEASE_NOTES_v1.2.3.md", "TESTING_v1.2.3.md"):
        if not (ROOT / rel).is_file():
            errors.append(f"Missing 1.2.3 release document: {rel}")

    # 1.1.9 language-picker layering + protected reload regression guards.
    for snippet in (
        'frame:SetFrameStrata("FULLSCREEN_DIALOG")',
        'frame:SetFrameLevel(1000)',
        'frame:EnableMouse(true)',
        'Language saved as %s. Type /reload to apply it.',
    ):
        if snippet not in core and snippet not in localization:
            errors.append(f"1.1.9 language picker regression guard missing: {snippet}")
    if 'C_Timer.After(0.05, ReloadUI)' in core or 'ReloadUI()' in core:
        errors.append("1.1.9 language selector must not call protected ReloadUI/Reload automatically")
    for rel in ("RELEASE_NOTES_v1.1.9.md", "TESTING_v1.1.9.md"):
        if not (ROOT / rel).is_file():
            errors.append(f"Missing 1.1.9 release document: {rel}")

    if errors:
        print("Validation failed:", file=sys.stderr)
        print("\n".join(f"- {e}" for e in errors), file=sys.stderr)
        return 1

    print(f"Validation passed: DK Mentor {VERSION}, Retail interface {INTERFACE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
