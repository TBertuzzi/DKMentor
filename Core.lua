local ADDON_NAME, DKM = ...

local Data = DKM.Data or {}
local Builds = DKM.Builds or {}
local Voices = DKM.Voices or {}
local Guides = DKM.Guides or {}
local T = DKM.T or function(value, ...)
    if select("#", ...) > 0 then
        return string.format(value, ...)
    end
    return value
end

local addon = CreateFrame("Frame")
DKM.Addon = addon

local DB
local mainFrame
local coachFrame
local minimapButton
local statusWidget
local specializationPickerFrame
local voiceConfigFrame
local languagePickerFrame
local equipmentPickerFrame
local loadoutPickerFrame
local barLayoutFrame
local buffFrame
local externalBuffFrame
local debuffFrame
local abilityFrame
local resourceFrame
local resourceArcFrame
local interruptFrame
local modeButtons = {}
local tipRows = {}
local coachCards = {}
local voiceRows = {}
local equipmentRows = {}
local loadoutRows = {}
local tabButtons = {}
local buffSlots = {}
local externalBuffSlots = {}
local debuffSlots = {}
local abilitySlots = {}
local mirroredBuffItems = {}
local mirroredActiveBuffItems = {}
local mirroredActiveBuffOrder = {}
local mirroredBuffHooks = setmetatable({}, { __mode = "k" })
local mirroredViewerHooks = setmetatable({}, { __mode = "k" })
local overlayProcState = {}
local activeProcGlows = {}
local activeProcGlowOrder = {}
local cooldownManagerProfileCache = {}
local targetInterruptEventState = nil
local runtimeBuffState = {}
local buffRefreshElapsed = 0
local contextPollElapsed = 0
local lootSpecState = {
    pendingID = nil,
    pendingRuleKey = nil,
    isRestore = false,
    retryElapsed = 0,
    lastError = nil,
    activeOverrideKey = nil,
    restoreID = nil,
    equipmentRetryElapsed = 0,
}

local voiceHandle
local voiceBusyUntil = 0
local lastVoiceAt = -1000000
local lastVoiceFileID
local lastVoiceCategory
local lastVoiceCategoryAt = {}
local lastVoiceAttemptCategory
local lastVoiceAttemptResult
local ambientPollElapsed = 0
local combatStartedAt
local pendingLoadoutCreation
local pendingEquipmentCreation
local updateScheduled = false
local updateNeedsBarCheck = false

local PREFIX = "|cff69ccf0DK Mentor|r"
local QUESTION_MARK_ICON = 134400
local RUNIC_POWER_TYPE = (Enum and Enum.PowerType and Enum.PowerType.RunicPower) or 6

local function Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": " .. tostring(message))
    end
end

local function Trim(value)
    value = tostring(value or "")
    return value:match("^%s*(.-)%s*$") or ""
end

local function Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function IsSecretValue(value)
    if not issecretvalue then
        return false
    end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret == true
end

local function IsAccessibleValue(value)
    -- Secret values cannot safely be compared even with nil, so test secrecy
    -- before doing any normal Lua operation on the value.
    if IsSecretValue(value) then
        return false
    end
    if value == nil then
        return false
    end
    if canaccessvalue then
        local ok, accessible = pcall(canaccessvalue, value)
        if ok and accessible == false then
            return false
        end
    end
    return true
end

local function IsAccessibleNumber(value)
    if IsSecretValue(value) then
        return false
    end
    if type(value) ~= "number" then
        return false
    end
    if canaccessvalue then
        local ok, accessible = pcall(canaccessvalue, value)
        if ok and accessible == false then
            return false
        end
    end
    return true
end

local function GetAccessibleBoolean(value)
    -- Midnight may return secret booleans from otherwise familiar Unit APIs.
    -- Never compare, negate, or branch on the value until accessibility is known.
    if not IsAccessibleValue(value) then
        return nil
    end
    if type(value) ~= "boolean" then
        return nil
    end
    return value
end

local function GetAccessibleBooleanFromCall(ok, value)
    if not ok then
        return nil
    end
    return GetAccessibleBoolean(value)
end

local function FormatShortTime(seconds)
    if not IsAccessibleNumber(seconds) then
        return ""
    end
    seconds = math.max(0, seconds)
    if seconds >= 60 then
        return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
    elseif seconds >= 10 then
        return tostring(math.ceil(seconds))
    elseif seconds > 0 then
        return string.format("%.1f", seconds)
    end
    return ""
end

local function GetNow()
    if GetTime then
        local ok, value = pcall(GetTime)
        if ok and type(value) == "number" then
            return value
        end
    end

    if time then
        local ok, value = pcall(time)
        if ok and type(value) == "number" then
            return value
        end
    end

    return 0
end

local function GetClientLocale()
    if GetLocale then
        local ok, locale = pcall(GetLocale)
        if ok and type(locale) == "string" and locale ~= "" then
            return locale
        end
    end

    return "unknown"
end


local function GetPlayerHealthPercent()
    local function NormalizePercent(value)
        if value == nil then
            return nil
        end
        if issecretvalue and issecretvalue(value) then
            return nil
        end
        if canaccessvalue then
            local okAccess, canAccess = pcall(canaccessvalue, value)
            if okAccess and canAccess == false then
                return nil
            end
        end
        if type(value) ~= "number" then
            return nil
        end

        -- Depending on the client build/API overload, percentages may arrive
        -- as 0..1 or 0..100. Normalize both forms without touching secrets.
        if value >= 0 and value <= 1.0001 then
            value = value * 100
        end
        return Clamp(value, 0, 100)
    end

    if UnitHealthPercent then
        -- Prefer the plain percentage API first. Midnight keeps this usable for
        -- addon arithmetic in supported contexts, unlike raw UnitHealth values.
        local ok, value = pcall(UnitHealthPercent, "player", true)
        if ok then
            local percent = NormalizePercent(value)
            if percent then
                return percent
            end
        end

        -- Some builds expose the ScaleTo100 curve path more reliably.
        if CurveConstants and CurveConstants.ScaleTo100 then
            ok, value = pcall(UnitHealthPercent, "player", true, CurveConstants.ScaleTo100)
            if ok then
                local percent = NormalizePercent(value)
                if percent then
                    return percent
                end
            end
        end
    end

    if UnitHealth and UnitHealthMax then
        local okHealth, health = pcall(UnitHealth, "player")
        local okMax, maxHealth = pcall(UnitHealthMax, "player")
        if okHealth and okMax and type(health) == "number" and type(maxHealth) == "number" then
            if issecretvalue and (issecretvalue(health) or issecretvalue(maxHealth)) then
                return nil
            end
            if maxHealth > 0 then
                return Clamp((health / maxHealth) * 100, 0, 100)
            end
        end
    end

    return nil
end

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = DeepCopy(child)
    end
    return copy
end

local function ApplyDefaults(target, defaults)
    for key, defaultValue in pairs(defaults) do
        if type(defaultValue) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            ApplyDefaults(target[key], defaultValue)
        elseif target[key] == nil then
            target[key] = defaultValue
        end
    end
end

local DEFAULTS = {
    schema = 29,
    firstRun = true,
    languageOverride = "auto",
    modeOverride = "auto",
    buildContextSelection = "world",
    selectedBuild = {},
    personalBuildCodes = {},
    loadoutBindings = {},
    equipmentBindings = {},
    specializationBindings = {},
    dungeonOverrides = {},
    knownDungeons = {},
    autoSwitchSpecialization = true,
    autoSwitchLoadouts = true,
    autoSwitchEquipment = true,
    autoHideMainInCombat = true,
    combatBarsOnlyInCombat = true,
    mainTab = "combat",
    hudLocked = true,
    main = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = -35,
        y = 20,
        scale = 1,
    },
    coach = {
        enabled = true,
        onlyInCombat = true,
        adaptiveHealth = true,
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = -245,
        scale = 1,
    },
    statusWidget = {
        enabled = true,
        point = "TOP",
        relativePoint = "TOP",
        x = 0,
        y = -105,
        scale = 1,
    },
    buffBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 205,
        scale = 1,
        iconsPerRow = 5,
        opacity = 1,
    },
    externalBuffBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 255,
        scale = 1,
        iconsPerRow = 5,
        opacity = 1,
    },
    debuffBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 305,
        scale = 1,
        iconsPerRow = 5,
        opacity = 1,
    },
    abilityBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 155,
        scale = 1,
        iconsPerRow = 11,
        opacity = 1,
    },
    resourceHUD = {
        enabled = true,
        showRunes = true,
        showRunicPower = true,
        showPowerText = true,
        runeSpacing = "normal",
        style = "classic",
        arcSpacing = 105,
        arcPoint = "CENTER",
        arcRelativePoint = "CENTER",
        arcX = 0,
        arcY = 0,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 85,
        scale = 1,
        opacity = 1,
    },
    interruptAlert = {
        enabled = true,
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 95,
        scale = 1,
    },
    minimap = {
        show = true,
        angle = 225,
    },
    voice = {
        enabled = false,
        frequency = "normal",
        allowInPvP = true,
        situational = true,
        selections = {},
    },
}

local function GetSpellData(spellID, fallbackName)
    local name
    local icon

    if spellID and C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and info then
            name = info.name
            icon = info.iconID
        end
    end

    if spellID and not name and GetSpellInfo then
        local ok, spellName, _, spellIcon = pcall(GetSpellInfo, spellID)
        if ok then
            name = spellName
            icon = spellIcon
        end
    end

    return name or fallbackName or ("Spell " .. tostring(spellID or "?")), icon or QUESTION_MARK_ICON
end

local function IsSpellKnownSafe(spellID)
    if not spellID then
        return false
    end

    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellID)
        if ok and known ~= nil then
            return known == true
        end
    end

    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellID)
        if ok and known ~= nil then
            return known == true
        end
    end

    return true
end

local MAIN_HAND_SLOT = _G.INVSLOT_MAINHAND or 16
local OFF_HAND_SLOT = _G.INVSLOT_OFFHAND or 17

local function GetEquippedItemData(slotID)
    local itemID
    local itemLink

    if GetInventoryItemID then
        local ok, value = pcall(GetInventoryItemID, "player", slotID)
        if ok and IsAccessibleValue(value) and type(value) == "number" and value > 0 then
            itemID = value
        end
    end

    if GetInventoryItemLink then
        local ok, value = pcall(GetInventoryItemLink, "player", slotID)
        if ok and IsAccessibleValue(value) and type(value) == "string" then
            itemLink = value
        end
    end

    return itemID, itemLink
end

local function GetPermanentEnchantID(itemLink)
    if not IsAccessibleValue(itemLink) or type(itemLink) ~= "string" then
        return nil
    end

    -- Item links begin with item:<itemID>:<permanentEnchantID>:...
    local value = itemLink:match("item:%-?%d+:(%-?%d+)")
    return tonumber(value)
end

function addon:GetRuneforgeSlotStatus(slotID, slotLabel)
    local itemID, itemLink = GetEquippedItemData(slotID)
    local equipped = itemID ~= nil or itemLink ~= nil
    if not equipped then
        return {
            slotID = slotID,
            slotLabel = slotLabel,
            equipped = false,
            known = true,
            valid = false,
            text = T("No weapon equipped"),
        }
    end

    if not itemLink then
        return {
            slotID = slotID,
            slotLabel = slotLabel,
            equipped = true,
            known = false,
            valid = false,
            text = T("Checking runeforge..."),
        }
    end

    local enchantID = GetPermanentEnchantID(itemLink) or 0
    local rune = Data.runeforges and Data.runeforges[enchantID] or nil
    if rune then
        local runeName = select(1, GetSpellData(rune.spellID, rune.fallbackName))
        return {
            slotID = slotID,
            slotLabel = slotLabel,
            equipped = true,
            known = true,
            valid = true,
            enchantID = enchantID,
            spellID = rune.spellID,
            runeName = runeName,
            text = runeName,
        }
    end

    return {
        slotID = slotID,
        slotLabel = slotLabel,
        equipped = true,
        known = true,
        valid = false,
        enchantID = enchantID,
        text = enchantID > 0 and T("Weapon has a non-Runeforge enchant") or T("Runeforge missing"),
    }
end

function addon:GetRuneforgeStatus()
    local main = self:GetRuneforgeSlotStatus(MAIN_HAND_SLOT, T("Main hand"))
    local off = self:GetRuneforgeSlotStatus(OFF_HAND_SLOT, T("Off hand"))
    local required = { main }
    if off.equipped then
        table.insert(required, off)
    end

    local ready = true
    local known = true
    local details = {}
    for _, slot in ipairs(required) do
        if not slot.known then
            known = false
            ready = false
        elseif not slot.valid then
            ready = false
        end
        table.insert(details, T("%s: %s", tostring(slot.slotLabel), tostring(slot.text)))
    end

    return {
        ready = ready,
        known = known,
        main = main,
        off = off,
        dualWield = off.equipped == true,
        detail = table.concat(details, " • "),
    }
end

function addon:GetGhoulReadyStatus(specID)
    if specID ~= 252 then
        return { required = false, ready = true, detail = T("Not required") }
    end

    local knowsRaiseDead = false
    for _, spellID in ipairs(Data.raiseDeadSpellIDs or {}) do
        if IsSpellKnownSafe(spellID) then
            knowsRaiseDead = true
            break
        end
    end

    -- Do not invent a requirement if this client/build does not expose Raise Dead.
    if not knowsRaiseDead then
        return { required = false, ready = true, detail = T("Not required") }
    end

    if UnitInVehicle then
        local ok, rawInVehicle = pcall(UnitInVehicle, "player")
        local inVehicle = GetAccessibleBooleanFromCall(ok, rawInVehicle)
        if inVehicle == true then
            return { required = true, ready = true, paused = true, detail = T("Paused while in a vehicle") }
        end
    end
    if UnitOnTaxi then
        local ok, rawOnTaxi = pcall(UnitOnTaxi, "player")
        local onTaxi = GetAccessibleBooleanFromCall(ok, rawOnTaxi)
        if onTaxi == true then
            return { required = true, ready = true, paused = true, detail = T("Paused while travelling") }
        end
    end

    local petExists = false
    if UnitExists then
        local ok, rawExists = pcall(UnitExists, "pet")
        local exists = GetAccessibleBooleanFromCall(ok, rawExists)
        petExists = exists == true
    end

    if not petExists then
        return { required = true, ready = false, detail = T("Ghoul missing") }
    end

    local petDead = false
    if UnitIsDead then
        local ok, rawDead = pcall(UnitIsDead, "pet")
        local dead = GetAccessibleBooleanFromCall(ok, rawDead)
        petDead = dead == true
    elseif UnitIsDeadOrGhost then
        local ok, rawDead = pcall(UnitIsDeadOrGhost, "pet")
        local dead = GetAccessibleBooleanFromCall(ok, rawDead)
        petDead = dead == true
    end

    if petDead then
        return { required = true, ready = false, detail = T("Ghoul is dead") }
    end

    return { required = true, ready = true, detail = T("Ghoul active") }
end

function addon:GetReadyCheckStatus()
    if not DB then
        return { ready = false, issues = {}, summary = T("Ready Check unavailable") }
    end

    local currentSpecID = select(1, self:GetSpecInfo())
    local context = self:DetectActualContext()
    local targetSpecID, specMode = self:ResolveRuntimeSpecializationTarget(context)
    local effectiveSpecID = targetSpecID or currentSpecID
    local issues = {}
    local hardIssue = false

    local specReady = not targetSpecID or currentSpecID == targetSpecID
    local specDetail
    if not targetSpecID then
        specDetail = T("Specialization: keep current (%s)", tostring((Data.specNames and Data.specNames[currentSpecID]) or currentSpecID))
    elseif specReady then
        specDetail = T("Specialization: %s", tostring((Data.specNames and Data.specNames[currentSpecID]) or currentSpecID))
    else
        local targetName = tostring((Data.specNames and Data.specNames[targetSpecID]) or targetSpecID)
        local severity = "hard"
        if DB.autoSwitchSpecialization then
            local allowed, blockedReason = self:CanAutoSwitchSpecialization(targetSpecID, context)
            if self.pendingSpecializationTargetSpecID == targetSpecID or (not allowed and blockedReason == T("Waiting for combat to end")) then
                severity = "waiting"
                specDetail = T("Waiting for specialization: %s", targetName)
            elseif not allowed then
                specDetail = blockedReason or T("Expected specialization: %s", targetName)
            else
                severity = "waiting"
                specDetail = self.lastSpecializationSwitchError or T("Expected specialization: %s", targetName)
            end
        else
            specDetail = T("Expected specialization: %s", targetName)
        end
        table.insert(issues, { key = "spec", label = T("SPEC"), severity = severity, detail = specDetail })
        if severity == "hard" then hardIssue = true end
    end

    local talentBinding, _, talentMode = self:ResolveRuntimeLoadoutBinding(effectiveSpecID, context)
    local selectedLoadoutID = self:GetSelectedLoadoutConfigID(effectiveSpecID)
    local talentReady = false
    local talentDetail
    if talentMode == "keep" then
        talentReady = true
        talentDetail = T("Dungeon override: keep current talents")
    elseif type(talentBinding) ~= "table" or not talentBinding.configID then
        talentDetail = T("No talent loadout mapped for this content")
        table.insert(issues, { key = "talents", label = T("TALENTS"), severity = "hard", detail = talentDetail })
        hardIssue = true
    elseif currentSpecID ~= effectiveSpecID then
        talentDetail = T("Talent loadout after specialization change: %s", tostring(talentBinding.name or talentBinding.configID))
        local severity = DB.autoSwitchSpecialization and "waiting" or "hard"
        table.insert(issues, { key = "talents", label = T("TALENTS"), severity = severity, detail = talentDetail })
        if severity == "hard" then hardIssue = true end
    elseif self.pendingLoadoutKey then
        talentDetail = T("Waiting for talent loadout: %s", tostring(talentBinding.name or talentBinding.configID))
        table.insert(issues, { key = "talents", label = T("TALENTS"), severity = "waiting", detail = talentDetail })
    elseif selectedLoadoutID ~= talentBinding.configID then
        talentDetail = T("Expected talent loadout: %s", tostring(talentBinding.name or talentBinding.configID))
        local severity = DB.autoSwitchLoadouts and "waiting" or "hard"
        table.insert(issues, { key = "talents", label = T("TALENTS"), severity = severity, detail = talentDetail })
        if severity == "hard" then hardIssue = true end
    else
        talentReady = true
        talentDetail = T("Talent loadout: %s", tostring(talentBinding.name or talentBinding.configID))
    end

    local equipmentBinding, equipmentInfo, equipmentMode = self:ResolveRuntimeEquipmentBinding(effectiveSpecID, context)
    local gearReady = false
    local gearDetail
    if equipmentMode == "keep" then
        gearReady = true
        gearDetail = T("Dungeon override: keep current gear")
    elseif type(equipmentBinding) ~= "table" then
        gearDetail = T("No equipment set mapped for this content")
        table.insert(issues, { key = "gear", label = T("GEAR"), severity = "hard", detail = gearDetail })
        hardIssue = true
    elseif not equipmentInfo then
        gearDetail = T("Mapped equipment set is missing")
        table.insert(issues, { key = "gear", label = T("GEAR"), severity = "hard", detail = gearDetail })
        hardIssue = true
    elseif self.pendingEquipmentKey or not equipmentInfo.isEquipped then
        gearDetail = T("Expected equipment set: %s", tostring(equipmentInfo.name or equipmentBinding.name or equipmentBinding.setID))
        local severity = DB.autoSwitchEquipment and "waiting" or "hard"
        table.insert(issues, { key = "gear", label = T("GEAR"), severity = severity, detail = gearDetail })
        if severity == "hard" then hardIssue = true end
    else
        gearReady = true
        gearDetail = T("Equipment set: %s", tostring(equipmentInfo.name or equipmentBinding.name or equipmentBinding.setID))
    end

    local runeforge = self:GetRuneforgeStatus()
    if not runeforge.ready then
        local severity = runeforge.known and "hard" or "waiting"
        table.insert(issues, { key = "runeforge", label = T("RUNEFORGE"), severity = severity, detail = runeforge.detail })
        if severity == "hard" then hardIssue = true end
    end

    local ghoul = self:GetGhoulReadyStatus(currentSpecID)
    if ghoul.required and not ghoul.ready then
        table.insert(issues, { key = "ghoul", label = T("GHOUL"), severity = "hard", detail = ghoul.detail })
        hardIssue = true
    end

    local ready = #issues == 0
    local summary
    if ready then
        summary = T("DK READY")
    elseif #issues == 1 then
        summary = T("DK NOT READY: %s", tostring(issues[1].label))
    else
        summary = T("DK NOT READY: %d ISSUES", #issues)
    end

    return {
        ready = ready,
        hardIssue = hardIssue,
        specID = currentSpecID,
        targetSpecID = targetSpecID,
        specMode = specMode,
        context = context,
        issues = issues,
        summary = summary,
        specReady = specReady,
        specDetail = specDetail,
        talentReady = talentReady,
        talentDetail = talentDetail,
        gearReady = gearReady,
        gearDetail = gearDetail,
        runeforge = runeforge,
        ghoul = ghoul,
    }
end

function addon:PrintReadyCheckStatus()
    local status = self:GetReadyCheckStatus()
    if status.ready then
        Print("|cff66ff99" .. T("DK READY") .. "|r")
    else
        Print((status.hardIssue and "|cffff7777" or "|cffffcc55") .. status.summary .. "|r")
    end

    if status.targetSpecID then
        Print((status.specReady and "|cff66ff99" or "|cffffcc55") .. T("Specialization") .. ":|r " .. tostring(status.specDetail or "-"))
    end
    Print((status.talentReady and "|cff66ff99" or "|cffffcc55") .. T("Talents") .. ":|r " .. tostring(status.talentDetail or "-"))
    Print((status.gearReady and "|cff66ff99" or "|cffffcc55") .. T("Gear") .. ":|r " .. tostring(status.gearDetail or "-"))
    Print((status.runeforge and status.runeforge.ready and "|cff66ff99" or "|cffff7777") .. T("Runeforge") .. ":|r " .. tostring(status.runeforge and status.runeforge.detail or "-"))
    if status.ghoul and status.ghoul.required then
        Print((status.ghoul.ready and "|cff66ff99" or "|cffff7777") .. T("Ghoul") .. ":|r " .. tostring(status.ghoul.detail or "-"))
    end
end

local function GetCVarBoolSafe(cvarName)
    if C_CVar and C_CVar.GetCVarBool then
        local ok, result = pcall(C_CVar.GetCVarBool, cvarName)
        if ok then
            return result == true
        end
    end

    if GetCVarBool then
        local ok, result = pcall(GetCVarBool, cvarName)
        if ok then
            return result == true
        end
    end

    return false
end

local function SetCVarSafe(cvarName, value)
    local stringValue = value and "1" or "0"

    if C_CVar and C_CVar.SetCVar then
        local ok = pcall(C_CVar.SetCVar, cvarName, stringValue)
        if ok then
            return true
        end
    end

    if SetCVar then
        local ok = pcall(SetCVar, cvarName, stringValue)
        if ok then
            return true
        end
    end

    return false
end

local function ApplyBackdrop(frame, alpha)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.025, 0.045, 0.065, alpha or 0.96)
    frame:SetBackdropBorderColor(0.22, 0.66, 0.82, 0.8)
end

local function SaveFramePosition(frame, dbKey)
    if not DB or not frame or not DB[dbKey] then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if point then
        DB[dbKey].point = point
        DB[dbKey].relativePoint = relativePoint or point
        DB[dbKey].x = math.floor((x or 0) + 0.5)
        DB[dbKey].y = math.floor((y or 0) + 0.5)
        DB[dbKey].scale = frame:GetScale() or 1
    end
end

local function RestoreFramePosition(frame, dbKey)
    if not DB or not frame or not DB[dbKey] then
        return
    end

    local config = DB[dbKey]
    frame:ClearAllPoints()
    frame:SetPoint(
        config.point or "CENTER",
        UIParent,
        config.relativePoint or config.point or "CENTER",
        config.x or 0,
        config.y or 0
    )
    local combatBar = dbKey == "buffBar" or dbKey == "externalBuffBar" or dbKey == "debuffBar" or dbKey == "abilityBar" or dbKey == "resourceHUD"
    frame:SetScale(Clamp(config.scale or 1, 0.7, combatBar and 1.6 or 1.4))
    if combatBar then frame:SetAlpha(Clamp(config.opacity or 1, 0.3, 1)) end
end

function addon:IsDeathKnight()
    local _, classFile = UnitClass("player")
    return classFile == "DEATHKNIGHT"
end

function addon:GetSpecInfo()
    local specializationIndex
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        local ok, value = pcall(C_SpecializationInfo.GetSpecialization)
        if ok then specializationIndex = value end
    elseif GetSpecialization then
        specializationIndex = GetSpecialization()
    end

    if specializationIndex then
        local specID, specName, specIcon
        if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
            local ok, id, name, _, icon = pcall(C_SpecializationInfo.GetSpecializationInfo, specializationIndex)
            if ok then
                specID, specName, specIcon = id, name, icon
            end
        elseif GetSpecializationInfo then
            specID, specName, _, specIcon = GetSpecializationInfo(specializationIndex)
        end

        if specID then
            return specID, specName or Data.specNames[specID] or "Death Knight", specIcon or QUESTION_MARK_ICON, specializationIndex
        end
    end

    return 0, T("No specialization"), QUESTION_MARK_ICON, 0
end

function addon:GetSpecializationInfoByIndex(index)
    if not index then return nil end

    if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
        local ok, specID, specName, _, specIcon = pcall(C_SpecializationInfo.GetSpecializationInfo, index)
        if ok and specID then
            return specID, specName or Data.specNames[specID] or tostring(specID), specIcon or QUESTION_MARK_ICON
        end
    elseif GetSpecializationInfo then
        local specID, specName, _, specIcon = GetSpecializationInfo(index)
        if specID then
            return specID, specName or Data.specNames[specID] or tostring(specID), specIcon or QUESTION_MARK_ICON
        end
    end

    return nil
end

function addon:GetSpecializationIndexByID(specID)
    specID = tonumber(specID)
    if not specID then return nil end
    for index = 1, 3 do
        local id = select(1, self:GetSpecializationInfoByIndex(index))
        if id == specID then
            return index
        end
    end
    return nil
end

function addon:GetSpecializationRoleByIDSafe(specID)
    specID = tonumber(specID)
    if not specID then return nil end

    if GetSpecializationRoleByID then
        local ok, role = pcall(GetSpecializationRoleByID, specID)
        if ok and type(role) == "string" and role ~= "" and role ~= "NONE" then
            return role
        end
    end

    if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
        local index = self:GetSpecializationIndexByID(specID)
        if index then
            local ok, _, _, _, _, role = pcall(C_SpecializationInfo.GetSpecializationInfo, index)
            if ok and type(role) == "string" and role ~= "" and role ~= "NONE" then
                return role
            end
        end
    end

    -- Death Knight role fallback if the specialization API is temporarily unavailable.
    if specID == 250 then return "TANK" end
    if specID == 251 or specID == 252 then return "DAMAGER" end
    return nil
end

function addon:GetAssignedGroupRole()
    if not UnitGroupRolesAssigned then return nil end
    local ok, role = pcall(UnitGroupRolesAssigned, "player")
    if not ok or not IsAccessibleValue(role) or type(role) ~= "string" or role == "" or role == "NONE" then
        return nil
    end
    return role
end

function addon:GetContentSpecializationBinding(context)
    if not DB or type(DB.specializationBindings) ~= "table" then return nil end
    local specID = tonumber(DB.specializationBindings[context])
    if specID == 250 or specID == 251 or specID == 252 then
        return specID
    end
    return nil
end

function addon:GetBuildConfigSpecID(context)
    context = context or self:GetBuildConfigContext()
    return self:GetContentSpecializationBinding(context) or select(1, self:GetSpecInfo())
end

function addon:GetBuildConfigSpecInfo(context)
    local specID = self:GetBuildConfigSpecID(context)
    local index = self:GetSpecializationIndexByID(specID)
    if index then
        local id, name, icon = self:GetSpecializationInfoByIndex(index)
        return id or specID, name or (Data.specNames and Data.specNames[specID]) or tostring(specID), icon or QUESTION_MARK_ICON, index
    end
    return specID, (Data.specNames and Data.specNames[specID]) or tostring(specID), QUESTION_MARK_ICON, 0
end

function addon:SetContentSpecializationBinding(context, specID)
    if not DB or not context or not (Data.contextNames and Data.contextNames[context]) or context == "auto" then
        return false
    end

    specID = tonumber(specID)
    if specID ~= 250 and specID ~= 251 and specID ~= 252 then
        specID = nil
    end

    DB.specializationBindings[context] = specID
    self.pendingSpecializationTargetSpecID = nil
    self.pendingSpecializationContext = nil
    self.lastSpecializationSwitchError = nil
    self:UpdateBuildSection()
    self:UpdateLoadoutPicker()
    self:UpdateEquipmentPicker()
    self:UpdateStatusWidget()
    if self.profileSpecializationPickerFrame and self.profileSpecializationPickerFrame:IsShown() then
        self:UpdateProfileSpecializationPicker()
    end
    if context == self:DetectActualContext() then
        self:ApplyAutomaticProfile("mapping")
    end
    return true
end

function addon:SetAutoSwitchSpecialization(enabled)
    if not DB then return end
    DB.autoSwitchSpecialization = enabled == true
    self.pendingSpecializationTargetSpecID = nil
    self.pendingSpecializationContext = nil
    self.lastSpecializationSwitchError = nil
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    Print(T(DB.autoSwitchSpecialization and "Automatic specialization switching enabled." or "Automatic specialization switching disabled."))
    if DB.autoSwitchSpecialization then
        self:ApplyAutomaticProfile("toggle")
    end
end

function addon:ToggleAutoSwitchSpecialization()
    self:SetAutoSwitchSpecialization(not DB.autoSwitchSpecialization)
end

function addon:SwitchSpecialization(index)
    index = tonumber(index)
    if not index or index < 1 or index > 3 then
        return false
    end

    if InCombatLockdown and InCombatLockdown() then
        Print(T("You cannot change specialization during combat."))
        return false
    end

    local _, currentName, _, currentIndex = self:GetSpecInfo()
    if currentIndex == index then
        if specializationPickerFrame then specializationPickerFrame:Hide() end
        return true
    end

    local _, targetName = self:GetSpecializationInfoByIndex(index)
    if not targetName then
        Print(T("That specialization is not available."))
        return false
    end

    local ok, result = false, nil
    -- Match the proven Loadout Pilot path first. On current Retail,
    -- C_SpecializationInfo.SetSpecialization delegates to the ClassTalents
    -- specialization switch internally, but it also gives us a direct boolean
    -- result when the request is rejected immediately.
    if C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
        ok, result = pcall(C_SpecializationInfo.SetSpecialization, index)
    elseif C_ClassTalents and C_ClassTalents.SwitchToSpecializationByIndex then
        ok, result = pcall(C_ClassTalents.SwitchToSpecializationByIndex, index)
    end

    if not ok or result == false then
        Print(T("WoW did not allow the specialization change."))
        return false
    end

    if specializationPickerFrame then specializationPickerFrame:Hide() end
    Print(T("Switching specialization to %s...", tostring(targetName)))
    return true
end

function addon:DetectActualContext()
    if C_PartyInfo and C_PartyInfo.IsDelveInProgress then
        local ok, rawInDelve = pcall(C_PartyInfo.IsDelveInProgress)
        local inDelve = GetAccessibleBooleanFromCall(ok, rawInDelve)
        if inDelve == true then
            return "delve"
        end
    end

    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "arena" or instanceType == "pvp" then
            return "pvp"
        elseif instanceType == "raid" then
            return "raid"
        elseif instanceType == "party" then
            local challengeActive
            if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive then
                local ok, rawValue = pcall(C_ChallengeMode.IsChallengeModeActive)
                challengeActive = GetAccessibleBooleanFromCall(ok, rawValue)
            elseif C_PartyInfo and C_PartyInfo.IsChallengeModeActive then
                local ok, rawValue = pcall(C_PartyInfo.IsChallengeModeActive)
                challengeActive = GetAccessibleBooleanFromCall(ok, rawValue)
            end

            local keystoneSlotted
            if C_ChallengeMode and C_ChallengeMode.HasSlottedKeystone then
                local ok, rawValue = pcall(C_ChallengeMode.HasSlottedKeystone)
                keystoneSlotted = GetAccessibleBooleanFromCall(ok, rawValue)
            elseif C_ChallengeMode and C_ChallengeMode.GetSlottedKeystoneInfo then
                local ok, mapID = pcall(C_ChallengeMode.GetSlottedKeystoneInfo)
                keystoneSlotted = ok and IsAccessibleNumber(mapID) and mapID > 0 or false
            end

            -- Treat a slotted keystone as Mythic+ before the timer starts. This
            -- is the useful preparation window where WoW can still permit spec,
            -- talent and equipment changes.
            if challengeActive == true or keystoneSlotted == true then
                return "mythicplus"
            end
            return "dungeon"
        end
    end

    return "world"
end

function addon:DetectContext()
    -- Runtime content detection is intentionally automatic-only. Older builds
    -- allowed a manual override, which could leave the HUD stuck on PvP after
    -- returning to the open world even though gear had already switched back.
    return self:DetectActualContext(), true
end

function addon:GetMythicPlusMapID()
    if not C_ChallengeMode then return nil end

    if C_ChallengeMode.GetActiveChallengeMapID then
        local ok, mapID = pcall(C_ChallengeMode.GetActiveChallengeMapID)
        if ok and IsAccessibleNumber(mapID) and mapID > 0 then return mapID end
    end

    if C_ChallengeMode.GetSlottedKeystoneInfo then
        local ok, mapID = pcall(C_ChallengeMode.GetSlottedKeystoneInfo)
        if ok and IsAccessibleNumber(mapID) and mapID > 0 then return mapID end
    end

    return nil
end

function addon:FindChallengeMapIDByName(instanceName)
    if not instanceName or not C_ChallengeMode or not C_ChallengeMode.GetMapTable or not C_ChallengeMode.GetMapUIInfo then
        return nil
    end
    local ok, ids = pcall(C_ChallengeMode.GetMapTable)
    if not ok or type(ids) ~= "table" then return nil end
    for _, challengeMapID in ipairs(ids) do
        local okInfo, name = pcall(C_ChallengeMode.GetMapUIInfo, challengeMapID)
        if okInfo and name == instanceName then return tonumber(challengeMapID) end
    end
    return nil
end

function addon:GetChallengeDungeonIdentity(challengeMapID)
    challengeMapID = tonumber(challengeMapID)
    if not challengeMapID or not C_ChallengeMode or not C_ChallengeMode.GetMapUIInfo then return nil end

    local okInfo, name, returnedID, _, _, _, uiMapID = pcall(C_ChallengeMode.GetMapUIInfo, challengeMapID)
    if not okInfo then return nil end

    local identity = {
        name = (type(name) == "string" and name ~= "") and name or T("Dungeon"),
        challengeMapID = tonumber(returnedID) or challengeMapID,
        uiMapID = tonumber(uiMapID),
        seasonal = true,
        supportsMythicPlus = true,
        context = "mythicplus",
    }

    -- Retail exposes the dungeon UiMapID through Challenge Mode. Resolve it
    -- through the Encounter Journal so Normal/Heroic/Mythic 0 and Mythic+
    -- share one stable dungeon:<InstanceID> override.
    if identity.uiMapID and EJ_GetInstanceForMap and EJ_GetInstanceInfo then
        local okJournal, journalInstanceID = pcall(EJ_GetInstanceForMap, identity.uiMapID)
        if okJournal and journalInstanceID then
            local okJournalInfo, _, _, _, _, _, _, _, _, _, instanceMapID = pcall(EJ_GetInstanceInfo, journalInstanceID)
            if okJournalInfo and tonumber(instanceMapID) and tonumber(instanceMapID) > 0 then
                identity.instanceID = tonumber(instanceMapID)
            end
        end
    end

    -- If the Encounter Journal path is temporarily unavailable, reuse a
    -- visited dungeon record with the same localized name.
    if not identity.instanceID and DB and type(DB.knownDungeons) == "table" then
        for _, known in pairs(DB.knownDungeons) do
            if type(known) == "table" and known.name == identity.name and tonumber(known.instanceID) then
                identity.instanceID = tonumber(known.instanceID)
                break
            end
        end
    end

    if identity.instanceID and identity.instanceID > 0 then
        identity.key = "dungeon:" .. tostring(identity.instanceID)
    else
        identity.key = "challenge:" .. tostring(identity.challengeMapID)
    end
    return identity
end

function addon:GetCurrentDungeonIdentity()
    local context = self:DetectActualContext()
    if context ~= "dungeon" and context ~= "mythicplus" then return nil end

    local ok, name, instanceType, difficultyID, difficultyName, _, _, _, instanceID = pcall(GetInstanceInfo)
    if not ok or instanceType ~= "party" then return nil end

    local identity = {
        name = (type(name) == "string" and name ~= "") and name or T("Current dungeon"),
        context = context,
        instanceID = tonumber(instanceID),
        difficultyID = tonumber(difficultyID),
        difficultyName = difficultyName,
    }

    if C_Map and C_Map.GetBestMapForUnit then
        local okMap, uiMapID = pcall(C_Map.GetBestMapForUnit, "player")
        if okMap and IsAccessibleNumber(uiMapID) and uiMapID > 0 then identity.uiMapID = uiMapID end
    end

    local challengeMapID = self:GetMythicPlusMapID() or self:FindChallengeMapIDByName(identity.name)
    if challengeMapID then
        identity.challengeMapID = tonumber(challengeMapID)
        identity.supportsMythicPlus = true
        if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
            local okInfo, challengeName, _, _, _, _, challengeUIMapID = pcall(C_ChallengeMode.GetMapUIInfo, challengeMapID)
            if okInfo then
                if type(challengeName) == "string" and challengeName ~= "" then identity.name = challengeName end
                if IsAccessibleNumber(challengeUIMapID) and challengeUIMapID > 0 then identity.uiMapID = challengeUIMapID end
            end
        end
    end

    -- InstanceID is the canonical identity across all dungeon difficulties.
    if identity.instanceID and identity.instanceID > 0 then
        identity.key = "dungeon:" .. tostring(identity.instanceID)
    elseif identity.challengeMapID then
        identity.key = "challenge:" .. tostring(identity.challengeMapID)
    elseif identity.uiMapID and identity.uiMapID > 0 then
        identity.key = "map:" .. tostring(identity.uiMapID)
    else
        identity.key = "name:" .. tostring(identity.name)
    end

    if self.MigrateDungeonOverrideIdentity and identity.instanceID then
        self:MigrateDungeonOverrideIdentity(nil, identity.key, identity)
    end
    return identity
end

function addon:RememberDungeonIdentity(identity)
    if not DB or type(DB.knownDungeons) ~= "table" or type(identity) ~= "table" or not identity.key then return end
    local key = identity.instanceID and ("dungeon:" .. tostring(identity.instanceID)) or identity.key
    DB.knownDungeons[key] = {
        key = key,
        name = identity.name,
        context = identity.context,
        instanceID = identity.instanceID,
        challengeMapID = identity.challengeMapID,
        uiMapID = identity.uiMapID,
        seasonal = identity.seasonal,
        supportsMythicPlus = identity.supportsMythicPlus,
    }
end

function addon:RememberCurrentDungeon()
    local identity = self:GetCurrentDungeonIdentity()
    if identity then self:RememberDungeonIdentity(identity) end
    return identity
end

function addon:GetCurrentSeasonDungeonCatalog()
    local result = {}
    local seen = {}
    if not C_ChallengeMode or not C_ChallengeMode.GetMapUIInfo then return result end

    -- GetMapTable is the stable Challenge Mode catalog used by Loadout Pilot.
    -- Prefer it so every seasonal dungeon is available even before the player
    -- has a score for that map. Keep GetMapScoreInfo only as a compatibility
    -- fallback for clients where the catalog is temporarily unavailable.
    local ids = {}
    if C_ChallengeMode.GetMapTable then
        local okIDs, mapIDs = pcall(C_ChallengeMode.GetMapTable)
        if okIDs and type(mapIDs) == "table" then
            for _, id in ipairs(mapIDs) do
                id = tonumber(id)
                if id and id > 0 and not seen[id] then seen[id] = true; table.insert(ids, id) end
            end
        end
    end
    if #ids == 0 and C_ChallengeMode.GetMapScoreInfo then
        local okScores, scores = pcall(C_ChallengeMode.GetMapScoreInfo)
        if okScores and type(scores) == "table" then
            for _, scoreInfo in ipairs(scores) do
                local id = type(scoreInfo) == "table" and tonumber(scoreInfo.mapChallengeModeID) or nil
                if id and id > 0 and not seen[id] then seen[id] = true; table.insert(ids, id) end
            end
        end
    end

    for _, challengeMapID in ipairs(ids) do
        local identity = self:GetChallengeDungeonIdentity(challengeMapID)
        if identity and identity.name then table.insert(result, identity) end
    end
    return result
end

function addon:GetDungeonCatalog()
    local merged, order = {}, {}
    local function Add(info)
        if type(info) ~= "table" or not info.key then return end
        local canonicalKey = (tonumber(info.instanceID) and tonumber(info.instanceID) > 0)
            and ("dungeon:" .. tostring(tonumber(info.instanceID))) or info.key
        local existing = merged[canonicalKey]
        if not existing then
            existing = { key = canonicalKey }
            merged[canonicalKey] = existing
            table.insert(order, canonicalKey)
        end
        for field, value in pairs(info) do if value ~= nil then existing[field] = value end end
        existing.key = canonicalKey
        existing.supportsMythicPlus = existing.supportsMythicPlus or info.supportsMythicPlus or info.seasonal
    end

    for _, info in ipairs(self:GetCurrentSeasonDungeonCatalog()) do Add(info) end
    for _, info in pairs(DB and DB.knownDungeons or {}) do Add(info) end

    -- Keep configured legacy dungeons visible even before they are encountered
    -- again after upgrading from 1.2.0.
    for key, override in pairs(DB and DB.dungeonOverrides or {}) do
        if type(override) == "table" then
            local info = {
                key = key,
                name = override.name or T("Dungeon override"),
                instanceID = tonumber(override.instanceID),
                challengeMapID = tonumber(override.challengeMapID),
                uiMapID = tonumber(override.uiMapID),
            }
            if info.challengeMapID then info.supportsMythicPlus = true end
            Add(info)
        end
    end

    local current = self:GetCurrentDungeonIdentity()
    if current then
        self:RememberDungeonIdentity(current)
        current.isCurrent = true
        Add(current)
    end

    local result = {}
    for _, key in ipairs(order) do if merged[key] then table.insert(result, merged[key]) end end
    table.sort(result, function(a, b)
        return string.lower(tostring(a.name or a.key)) < string.lower(tostring(b.name or b.key))
    end)
    return result
end

function addon:GetDungeonCatalogEntry(key)
    if not key then return nil end
    for _, entry in ipairs(self:GetDungeonCatalog()) do if entry.key == key then return entry end end

    local instanceID = tostring(key):match("^instance:(%d+)$") or tostring(key):match("^dungeon:(%d+)$")
    if instanceID then
        local canonical = "dungeon:" .. tostring(instanceID)
        for _, entry in ipairs(self:GetDungeonCatalog()) do if entry.key == canonical then return entry end end
    end
    local challengeMapID = tostring(key):match("^challenge:(%d+)$") or tostring(key):match("^mplus:(%d+)$")
    if challengeMapID then
        local identity = self:GetChallengeDungeonIdentity(tonumber(challengeMapID))
        if identity and identity.instanceID then
            local canonical = "dungeon:" .. tostring(identity.instanceID)
            for _, entry in ipairs(self:GetDungeonCatalog()) do if entry.key == canonical then return entry end end
        end
    end
    return nil
end

function addon:GetDungeonFallbackContext(entry)
    if not entry then return "dungeon" end
    local current = self:GetCurrentDungeonIdentity()
    if current and current.key == entry.key then return current.context or "dungeon" end
    if entry.supportsMythicPlus or entry.seasonal or entry.context == "mythicplus" then return "mythicplus" end
    return "dungeon"
end

function addon:GetDungeonOverride(key)
    if not DB or type(DB.dungeonOverrides) ~= "table" or not key then return nil end
    local value = DB.dungeonOverrides[key]
    return type(value) == "table" and value or nil
end

function addon:EnsureDungeonOverride(key, dungeonInfo)
    if not DB or not key then return nil end
    DB.dungeonOverrides = DB.dungeonOverrides or {}
    local override = DB.dungeonOverrides[key]
    if type(override) ~= "table" then
        override = {
            enabled = true,
            specMode = "inherit",
            loadoutMode = "inherit",
            equipmentMode = "inherit",
        }
        DB.dungeonOverrides[key] = override
    end

    override.enabled = override.enabled ~= false
    override.specMode = override.specMode or "inherit"
    override.loadoutMode = override.loadoutMode or "inherit"
    override.equipmentMode = override.equipmentMode or "inherit"
    if type(dungeonInfo) == "table" then
        override.name = dungeonInfo.name or override.name
        override.instanceID = dungeonInfo.instanceID or override.instanceID
        override.challengeMapID = dungeonInfo.challengeMapID or override.challengeMapID
        override.uiMapID = dungeonInfo.uiMapID or override.uiMapID
    end
    override.name = override.name or T("Dungeon override")
    return override
end

local function MergeDKDungeonOverrideRecord(target, source, sourceWins)
    if type(target) ~= "table" then target = {} end
    if type(source) ~= "table" then return target end
    local fields = {
        "enabled", "specMode", "specID", "loadoutMode", "loadout",
        "equipmentMode", "equipment", "lootSpecID", "name", "instanceID",
        "challengeMapID", "uiMapID",
    }
    for _, field in ipairs(fields) do
        if source[field] ~= nil and (sourceWins or target[field] == nil) then target[field] = source[field] end
    end
    return target
end

function addon:MigrateDungeonOverrideIdentity(oldKey, newKey, info)
    if not DB or type(DB.dungeonOverrides) ~= "table" or not newKey then return false end
    local sourceKeys = {}
    if oldKey then table.insert(sourceKeys, oldKey) end
    if type(info) == "table" then
        if info.instanceID then
            table.insert(sourceKeys, "instance:" .. tostring(info.instanceID))
            table.insert(sourceKeys, "dungeon:" .. tostring(info.instanceID))
        end
        if info.challengeMapID then
            table.insert(sourceKeys, "challenge:" .. tostring(info.challengeMapID))
            table.insert(sourceKeys, "mplus:" .. tostring(info.challengeMapID))
        end
        if info.uiMapID then table.insert(sourceKeys, "map:" .. tostring(info.uiMapID)) end
        if info.name then table.insert(sourceKeys, "name:" .. tostring(info.name)) end
    end

    local target = DB.dungeonOverrides[newKey]
    local changed = false
    local seen = {}
    for _, key in ipairs(sourceKeys) do
        if key and not seen[key] then
            seen[key] = true
            local legacy = DB.dungeonOverrides[key]
            if type(legacy) == "table" and key ~= newKey then
                target = MergeDKDungeonOverrideRecord(target, legacy, true)
                DB.dungeonOverrides[key] = nil
                changed = true
            end
        end
    end
    if type(target) == "table" then
        if type(info) == "table" then
            target.name = info.name or target.name
            target.instanceID = info.instanceID or target.instanceID
            target.challengeMapID = info.challengeMapID or target.challengeMapID
            target.uiMapID = info.uiMapID or target.uiMapID
        end
        DB.dungeonOverrides[newKey] = target
    end
    return changed
end

function addon:MigrateUnifiedDungeonOverrides()
    if not DB or type(DB.dungeonOverrides) ~= "table" then return end
    local moves = {}
    for key, override in pairs(DB.dungeonOverrides) do
        if type(override) == "table" then
            local instanceID = tostring(key):match("^instance:(%d+)$") or tostring(key):match("^dungeon:(%d+)$") or tonumber(override.instanceID)
            local challengeMapID = tostring(key):match("^challenge:(%d+)$") or tostring(key):match("^mplus:(%d+)$") or tonumber(override.challengeMapID)
            local info
            if challengeMapID then info = self:GetChallengeDungeonIdentity(tonumber(challengeMapID)) end
            if not instanceID and info then instanceID = info.instanceID end
            if instanceID and tonumber(instanceID) and tonumber(instanceID) > 0 then
                info = info or {}
                info.instanceID = tonumber(instanceID)
                info.name = info.name or override.name
                info.challengeMapID = info.challengeMapID or tonumber(challengeMapID)
                info.uiMapID = info.uiMapID or tonumber(override.uiMapID)
                table.insert(moves, { oldKey = key, newKey = "dungeon:" .. tostring(tonumber(instanceID)), info = info })
            end
        end
    end
    for _, move in ipairs(moves) do self:MigrateDungeonOverrideIdentity(move.oldKey, move.newKey, move.info) end

    -- Canonicalize remembered dungeon metadata too.
    if type(DB.knownDungeons) == "table" then
        local knownMoves = {}
        for key, info in pairs(DB.knownDungeons) do
            if type(info) == "table" and tonumber(info.instanceID) and tonumber(info.instanceID) > 0 then
                local newKey = "dungeon:" .. tostring(tonumber(info.instanceID))
                if key ~= newKey then table.insert(knownMoves, { oldKey = key, newKey = newKey, info = info }) end
            end
        end
        for _, move in ipairs(knownMoves) do
            local existing = DB.knownDungeons[move.newKey] or {}
            for field, value in pairs(move.info) do if value ~= nil then existing[field] = value end end
            existing.key = move.newKey
            DB.knownDungeons[move.newKey] = existing
            DB.knownDungeons[move.oldKey] = nil
        end
    end
end

function addon:GetLootSpecializationID()
    if not GetLootSpecialization then return nil end
    local ok, specID = pcall(GetLootSpecialization)
    if not ok or not IsAccessibleValue(specID) then return nil end
    specID = tonumber(specID)
    if specID == nil or specID < 0 then return nil end
    return specID
end

function addon:GetLootSpecDisplayName(specID)
    specID = tonumber(specID)
    if specID == nil then return T("No override") end
    if specID == 0 then
        local _, currentName = self:GetSpecInfo()
        return T("Current specialization (%s)", tostring(currentName or T("Unknown")))
    end
    local index = self:GetSpecializationIndexByID(specID)
    local _, name = self:GetSpecializationInfoByIndex(index)
    return name or tostring((Data.specNames and Data.specNames[specID]) or specID)
end

function addon:ClearPendingLootSpecChange()
    lootSpecState.pendingID = nil
    lootSpecState.pendingRuleKey = nil
    lootSpecState.isRestore = false
    lootSpecState.retryElapsed = 0
    lootSpecState.lastError = nil
end

function addon:RequestLootSpecialization(targetSpecID, ruleKey, isRestore, reason)
    targetSpecID = tonumber(targetSpecID)
    if targetSpecID == nil then return true end
    if not GetLootSpecialization or not SetLootSpecialization then
        self:ClearPendingLootSpecChange()
        lootSpecState.lastError = T("Loot specialization is unavailable on this client.")
        return false
    end

    local current = self:GetLootSpecializationID()
    if current == targetSpecID then
        self:ClearPendingLootSpecChange()
        return true
    end

    lootSpecState.pendingID = targetSpecID
    lootSpecState.pendingRuleKey = ruleKey
    lootSpecState.isRestore = isRestore == true
    lootSpecState.retryElapsed = 0

    local ok = pcall(SetLootSpecialization, targetSpecID)
    if not ok then
        lootSpecState.lastError = T("WoW did not allow the loot specialization change yet.")
        return false
    end

    local updated = self:GetLootSpecializationID()
    if updated == targetSpecID then
        local label = self:GetLootSpecDisplayName(targetSpecID)
        local restored = lootSpecState.isRestore
        self:ClearPendingLootSpecChange()
        Print(restored and T("Loot specialization restored to %s.", label) or T("Loot specialization changed to %s.", label))
        return true
    end

    lootSpecState.lastError = T("Applying loot specialization...")
    return false
end

function addon:UpdatePendingLootSpecState()
    if lootSpecState.pendingID == nil then return false end
    local current = self:GetLootSpecializationID()
    if current ~= lootSpecState.pendingID then return false end
    local label = self:GetLootSpecDisplayName(lootSpecState.pendingID)
    local restored = lootSpecState.isRestore
    self:ClearPendingLootSpecChange()
    Print(restored and T("Loot specialization restored to %s.", label) or T("Loot specialization changed to %s.", label))
    if restored then
        lootSpecState.activeOverrideKey = nil
        lootSpecState.restoreID = nil
    end
    self:UpdateStatusWidget()
    return true
end

function addon:SyncDungeonLootSpecialization(reason)
    local override, key, identity = self:GetActiveDungeonOverride()
    local hasLootOverride = type(override) == "table" and override.lootSpecID ~= nil and identity ~= nil

    if hasLootOverride then
        if not lootSpecState.activeOverrideKey then lootSpecState.restoreID = self:GetLootSpecializationID() end
        lootSpecState.activeOverrideKey = identity.key or key
        return self:RequestLootSpecialization(override.lootSpecID, tostring(identity.key or key), false, reason)
    end

    if lootSpecState.activeOverrideKey then
        local restoreID = lootSpecState.restoreID
        if restoreID == nil then
            lootSpecState.activeOverrideKey = nil
            self:ClearPendingLootSpecChange()
            return true
        end
        local restored = self:RequestLootSpecialization(restoreID, "restore:" .. tostring(lootSpecState.activeOverrideKey), true, reason)
        if restored then
            lootSpecState.activeOverrideKey = nil
            lootSpecState.restoreID = nil
        end
        return restored
    end

    self:ClearPendingLootSpecChange()
    return true
end

function addon:SetDungeonOverrideLootSpec(key, specID)
    local override = self:EnsureDungeonOverride(key)
    if not override then return end
    if specID == nil then
        override.lootSpecID = nil
    else
        specID = tonumber(specID)
        if specID ~= 0 and specID ~= 250 and specID ~= 251 and specID ~= 252 then return end
        override.lootSpecID = specID
    end
    self:UpdateDungeonOverrideEditor()
    self:UpdateDungeonOverridesFrame()
    self:ApplyDungeonOverrideIfCurrent(key, "loot-spec-mapping")
end

function addon:FindDungeonOverrideForIdentity(identity, includeDisabled)
    if not DB or type(DB.dungeonOverrides) ~= "table" or type(identity) ~= "table" then return nil, nil end

    local canonicalKey = identity.instanceID and ("dungeon:" .. tostring(identity.instanceID)) or identity.key
    local directKeys = {}
    if canonicalKey then table.insert(directKeys, canonicalKey) end
    if identity.key and identity.key ~= canonicalKey then table.insert(directKeys, identity.key) end
    if identity.instanceID then table.insert(directKeys, "instance:" .. tostring(identity.instanceID)) end
    if identity.challengeMapID then
        table.insert(directKeys, "challenge:" .. tostring(identity.challengeMapID))
        table.insert(directKeys, "mplus:" .. tostring(identity.challengeMapID))
    end
    if identity.uiMapID then table.insert(directKeys, "map:" .. tostring(identity.uiMapID)) end

    local seen = {}
    for _, key in ipairs(directKeys) do
        if key and not seen[key] then
            seen[key] = true
            local override = self:GetDungeonOverride(key)
            if override and (includeDisabled or override.enabled ~= false) then
                if canonicalKey and key ~= canonicalKey then
                    self:MigrateDungeonOverrideIdentity(key, canonicalKey, identity)
                    override = self:GetDungeonOverride(canonicalKey) or override
                    key = canonicalKey
                end
                return override, key
            end
        end
    end

    for key, override in pairs(DB.dungeonOverrides) do
        if type(override) == "table" and (includeDisabled or override.enabled ~= false) then
            local matches = (identity.challengeMapID and tonumber(override.challengeMapID) == identity.challengeMapID)
                or (identity.instanceID and tonumber(override.instanceID) == identity.instanceID)
                or (identity.uiMapID and tonumber(override.uiMapID) == identity.uiMapID)
            if matches then
                if canonicalKey and key ~= canonicalKey then
                    self:MigrateDungeonOverrideIdentity(key, canonicalKey, identity)
                    return self:GetDungeonOverride(canonicalKey) or override, canonicalKey
                end
                return override, key
            end
        end
    end
    return nil, nil
end

function addon:GetActiveDungeonOverride()
    local context = self:DetectActualContext()
    if context ~= "dungeon" and context ~= "mythicplus" then return nil, nil, nil end
    local identity = self:GetCurrentDungeonIdentity()
    if not identity then return nil, nil, nil end
    local override, key = self:FindDungeonOverrideForIdentity(identity)
    return override, key, identity
end

function addon:GetDungeonOverrideEffectiveSpecID(key)
    local override = self:GetDungeonOverride(key)
    local info = self:GetDungeonCatalogEntry(key)
    if type(override) ~= "table" and info then
        override = select(1, self:FindDungeonOverrideForIdentity(info, true))
    end
    local currentSpecID = select(1, self:GetSpecInfo())
    local fallbackContext = self:GetDungeonFallbackContext(info or { key = key })
    if type(override) ~= "table" then
        return self:GetContentSpecializationBinding(fallbackContext) or currentSpecID
    end

    if override.specMode == "spec" then
        local specID = tonumber(override.specID)
        if specID == 250 or specID == 251 or specID == 252 then return specID end
    elseif override.specMode == "keep" then
        return currentSpecID
    end
    return self:GetContentSpecializationBinding(fallbackContext) or currentSpecID
end

function addon:ApplyDungeonOverrideIfCurrent(key, reason)
    if not key then return end
    local context = self:DetectActualContext()
    if context ~= "dungeon" and context ~= "mythicplus" then return end
    local identity = self:GetCurrentDungeonIdentity()
    if not identity then return end
    local _, matchingKey = self:FindDungeonOverrideForIdentity(identity, true)
    if matchingKey == key or (identity.key and matchingKey == identity.key) then
        self:ApplyAutomaticProfile(reason or "mapping")
    end
end

function addon:SetDungeonOverrideEnabled(key, enabled)
    local override = self:EnsureDungeonOverride(key)
    if not override then return end
    override.enabled = enabled == true
    self:UpdateDungeonOverridesFrame()
    self:UpdateDungeonOverrideEditor()
    self:UpdateStatusWidget()
    self:ApplyDungeonOverrideIfCurrent(key, "mapping")
end

function addon:SetDungeonOverrideSpecMode(key, mode, specID)
    local override = self:EnsureDungeonOverride(key)
    if not override then return end
    if mode == "spec" then
        specID = tonumber(specID)
        if specID ~= 250 and specID ~= 251 and specID ~= 252 then return end
        override.specMode = "spec"
        override.specID = specID
    elseif mode == "keep" then
        override.specMode = "keep"
        override.specID = nil
    else
        override.specMode = "inherit"
        override.specID = nil
    end
    local effectiveSpecID = self:GetDungeonOverrideEffectiveSpecID(key)
    if override.loadoutMode == "override" and type(override.loadout) == "table"
        and tonumber(override.loadout.specID) and tonumber(override.loadout.specID) ~= tonumber(effectiveSpecID) then
        override.loadoutMode = "inherit"
        override.loadout = nil
    end
    self:UpdateDungeonOverrideEditor()
    self:UpdateDungeonOverridesFrame()
    self:ApplyDungeonOverrideIfCurrent(key, "mapping")
end

function addon:SetDungeonOverrideLoadoutMode(key, mode)
    local override = self:EnsureDungeonOverride(key)
    if not override then return end
    if mode ~= "keep" and mode ~= "override" then mode = "inherit" end
    override.loadoutMode = mode
    if mode ~= "override" then override.loadout = nil end
    self:UpdateDungeonOverrideEditor()
    self:UpdateDungeonOverridesFrame()
    self:ApplyDungeonOverrideIfCurrent(key, "mapping")
end

function addon:SetDungeonOverrideEquipmentMode(key, mode)
    local override = self:EnsureDungeonOverride(key)
    if not override then return end
    if mode ~= "keep" and mode ~= "override" then mode = "inherit" end
    override.equipmentMode = mode
    if mode ~= "override" then override.equipment = nil end
    self:UpdateDungeonOverrideEditor()
    self:UpdateDungeonOverridesFrame()
    self:ApplyDungeonOverrideIfCurrent(key, "mapping")
end

function addon:SetDungeonOverrideLoadout(key, specID, configID, name)
    local override = self:EnsureDungeonOverride(key)
    if not override or not configID then return false end
    override.loadoutMode = "override"
    override.loadout = {
        specID = tonumber(specID),
        configID = tonumber(configID),
        name = name,
    }
    self:UpdateDungeonOverrideEditor()
    self:UpdateDungeonOverridesFrame()
    self:ApplyDungeonOverrideIfCurrent(key, "mapping")
    return true
end

function addon:SetDungeonOverrideEquipment(key, setID, name)
    local override = self:EnsureDungeonOverride(key)
    if not override or not setID then return false end
    override.equipmentMode = "override"
    override.equipment = { setID = tonumber(setID), name = name }
    self:UpdateDungeonOverrideEditor()
    self:UpdateDungeonOverridesFrame()
    self:ApplyDungeonOverrideIfCurrent(key, "mapping")
    return true
end

function addon:DeleteDungeonOverride(key)
    if not DB or not key then return end
    local wasCurrent = false
    local deleteContext = self:DetectActualContext()
    if deleteContext == "dungeon" or deleteContext == "mythicplus" then
        local identity = self:GetCurrentDungeonIdentity()
        if identity then
            local _, matchingKey = self:FindDungeonOverrideForIdentity(identity, true)
            wasCurrent = matchingKey == key
        end
    end
    DB.dungeonOverrides[key] = nil
    if self.activeDungeonOverrideKey == key then self.activeDungeonOverrideKey = nil end
    if self.dungeonOverrideEditorFrame then self.dungeonOverrideEditorFrame:Hide() end
    self:UpdateDungeonOverridesFrame()
    self:UpdateStatusWidget()
    if wasCurrent then self:ApplyAutomaticProfile("mapping") end
end

function addon:ResolveRuntimeSpecializationTarget(context)
    context = context or self:DetectActualContext()
    if context == "dungeon" or context == "mythicplus" then
        local override = select(1, self:GetActiveDungeonOverride())
        if type(override) == "table" then
            if override.specMode == "keep" then
                return nil, "keep", override
            elseif override.specMode == "spec" then
                local specID = tonumber(override.specID)
                if specID == 250 or specID == 251 or specID == 252 then
                    return specID, "override", override
                end
            end
        end
    end
    return self:GetContentSpecializationBinding(context), "default", nil
end

function addon:GetRuntimeContextLabel(context)
    context = context or self:DetectActualContext()
    if context == "dungeon" or context == "mythicplus" then
        local override, _, identity = self:GetActiveDungeonOverride()
        if type(override) == "table" and override.name then return override.name end
        if identity and identity.name then return identity.name end
    end
    return (Data.contextNames and Data.contextNames[context]) or context
end

function addon:GetBuildConfigContext()
    local detected = self:DetectActualContext()
    if not DB then
        return detected
    end

    local context = DB.buildContextSelection
    if context == nil or context == "auto" or not (Data.contextNames and Data.contextNames[context]) then
        context = detected
        DB.buildContextSelection = context
    end

    return context
end

function addon:SetBuildConfigContext(context)
    if not DB or not context or context == "auto" then
        return
    end

    local valid = false
    for _, contextKey in ipairs(Data.contextOrder or {}) do
        if contextKey == context then
            valid = contextKey ~= "auto"
            break
        end
    end

    if not valid then
        return
    end

    DB.buildContextSelection = context
    self:UpdateBuildSection()
    self:UpdateLoadoutPicker()
    self:UpdateEquipmentPicker()
end

function addon:GetBuildProfiles(specID, context)
    local specBuilds = Builds[specID]
    if not specBuilds then
        return {}
    end

    if context == "mythicplus" then
        return specBuilds.mythicplus or specBuilds.dungeon or specBuilds.world or {}
    end
    return specBuilds[context] or specBuilds.world or {}
end

function addon:GetBuildKey(specID, context)
    return tostring(specID or 0) .. ":" .. tostring(context or "world")
end

function addon:GetPersonalBuildCodeKey(specID, context, profileIndex)
    return string.format("%s:%d", self:GetBuildKey(specID, context), tonumber(profileIndex) or 1)
end

function addon:SavePersonalBuildCode()
    if not mainFrame or not mainFrame.buildSection or not DB then
        return
    end

    local context = self:GetBuildConfigContext()
    local specID = self:GetBuildConfigSpecID(context)
    local _, index = self:GetSelectedBuild(specID, context)
    if index == 0 then
        return
    end

    local value = Trim(mainFrame.buildSection.codeBox:GetText())
    local key = self:GetPersonalBuildCodeKey(specID, context, index)
    if value == "" then
        DB.personalBuildCodes[key] = nil
        Print(T("Personal build code cleared for this profile."))
    else
        DB.personalBuildCodes[key] = value
        Print(T("Personal build code saved locally for this profile."))
    end
    self:UpdateBuildSection()
end

function addon:ClearPersonalBuildCode()
    if not mainFrame or not mainFrame.buildSection or not DB then
        return
    end

    local context = self:GetBuildConfigContext()
    local specID = self:GetBuildConfigSpecID(context)
    local _, index = self:GetSelectedBuild(specID, context)
    if index == 0 then
        return
    end

    local key = self:GetPersonalBuildCodeKey(specID, context, index)
    DB.personalBuildCodes[key] = nil
    mainFrame.buildSection.codeBox:SetText("")
    Print(T("Personal build code cleared for this profile."))
    self:UpdateBuildSection()
end

function addon:GetLoadoutBindingKey(specID, context)
    return self:GetBuildKey(specID, context)
end

function addon:GetSelectedLoadoutConfigID(specID)
    specID = specID or select(1, self:GetSpecInfo())

    -- Saved loadout IDs are different from C_ClassTalents.GetActiveConfigID().
    -- GetActiveConfigID() is the live working config and must not be compared
    -- with IDs returned by GetConfigIDsBySpecID().
    if C_ClassTalents and C_ClassTalents.GetLastSelectedSavedConfigID and specID then
        local ok, configID = pcall(C_ClassTalents.GetLastSelectedSavedConfigID, specID)
        if ok and type(configID) == "number" and configID > 0 then
            return configID
        end
    end

    -- Best-effort fallback when the Blizzard Talent UI is already loaded.
    local talentFrame = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    local loadSystem = talentFrame and talentFrame.LoadSystem
    if loadSystem and type(loadSystem.GetSelectionID) == "function" then
        local ok, configID = pcall(loadSystem.GetSelectionID, loadSystem)
        if ok and type(configID) == "number" and configID > 0 then
            return configID
        end
    end

    return nil
end

function addon:RememberSelectedLoadout(specID, configID)
    if not specID or not configID or not C_ClassTalents or not C_ClassTalents.UpdateLastSelectedSavedConfigID then
        return false
    end

    local ok = pcall(C_ClassTalents.UpdateLastSelectedSavedConfigID, specID, configID)
    return ok == true
end

function addon:GetActiveLoadoutInfo(specID)
    specID = specID or select(1, self:GetSpecInfo())
    local configID = self:GetSelectedLoadoutConfigID(specID)
    if not configID then
        return nil, nil
    end

    local name
    if C_Traits and C_Traits.GetConfigInfo then
        local okInfo, info = pcall(C_Traits.GetConfigInfo, configID)
        if okInfo and type(info) == "table" then
            name = info.name
        end
    end
    return configID, name or ("Loadout " .. tostring(configID))
end

function addon:GetLoadoutIndexByConfigID(specID, targetConfigID)
    if not targetConfigID or not C_ClassTalents or not C_ClassTalents.GetConfigIDsBySpecID then
        return nil
    end

    local ok, configIDs = pcall(C_ClassTalents.GetConfigIDsBySpecID, specID)
    if not ok or type(configIDs) ~= "table" then
        return nil
    end

    for index, configID in ipairs(configIDs) do
        if configID == targetConfigID then
            return index
        end
    end

    return nil
end

function addon:GetManagedLoadoutName(context)
    local names = {
        world = "DKM World",
        delve = "DKM Delve",
        dungeon = "DKM Dungeon",
        mythicplus = "DKM Mythic+",
        raid = "DKM Raid",
        pvp = "DKM PvP",
    }
    return names[context] or ("DKM " .. tostring(context or "World"))
end

function addon:FindSavedLoadoutByName(specID, loadoutName)
    if not C_ClassTalents or not C_ClassTalents.GetConfigIDsBySpecID or not C_Traits or not C_Traits.GetConfigInfo then
        return nil
    end

    local okIDs, configIDs = pcall(C_ClassTalents.GetConfigIDsBySpecID, specID)
    if not okIDs or type(configIDs) ~= "table" then
        return nil
    end

    for _, configID in ipairs(configIDs) do
        local okInfo, info = pcall(C_Traits.GetConfigInfo, configID)
        if okInfo and type(info) == "table" and info.name == loadoutName then
            return configID, info.name
        end
    end
    return nil
end

function addon:BindManagedLoadout(specID, context, configID, name)
    if not DB or not configID then
        return false
    end
    local key = self:GetLoadoutBindingKey(specID, context)
    DB.loadoutBindings[key] = { configID = configID, name = name or self:GetManagedLoadoutName(context) }
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    return true
end
function addon:GetLoadoutList(specID)
    local result = {}
    if not C_ClassTalents or not C_ClassTalents.GetConfigIDsBySpecID or not C_Traits or not C_Traits.GetConfigInfo then
        return result
    end

    local okIDs, configIDs = pcall(C_ClassTalents.GetConfigIDsBySpecID, specID)
    if not okIDs or type(configIDs) ~= "table" then
        return result
    end

    local activeID = select(1, self:GetActiveLoadoutInfo(specID))
    for _, configID in ipairs(configIDs) do
        local okInfo, info = pcall(C_Traits.GetConfigInfo, configID)
        if okInfo and type(info) == "table" then
            local name = info.name or ("Loadout " .. tostring(configID))
            table.insert(result, {
                configID = configID,
                name = name,
                isActive = activeID == configID,
            })
        end
    end

    table.sort(result, function(a, b)
        return string.lower(tostring(a.name or "")) < string.lower(tostring(b.name or ""))
    end)
    return result
end

function addon:ResolveLoadoutBinding(specID, context)
    if not DB then return nil, nil end
    local key = self:GetLoadoutBindingKey(specID, context)
    local binding = DB.loadoutBindings[key]
    if type(binding) ~= "table" then
        return nil, nil
    end

    local info
    if binding.configID and C_Traits and C_Traits.GetConfigInfo then
        local okInfo, configInfo = pcall(C_Traits.GetConfigInfo, binding.configID)
        if okInfo and type(configInfo) == "table" then
            info = {
                configID = binding.configID,
                name = configInfo.name or binding.name or ("Loadout " .. tostring(binding.configID)),
                isActive = select(1, self:GetActiveLoadoutInfo(specID)) == binding.configID,
            }
        end
    end

    -- Config IDs can change if the player deletes/recreates a loadout. Repair by name.
    if not info and binding.name then
        local repairedID, repairedName = self:FindSavedLoadoutByName(specID, binding.name)
        if repairedID then
            binding.configID = repairedID
            binding.name = repairedName or binding.name
            info = {
                configID = repairedID,
                name = binding.name,
                isActive = select(1, self:GetActiveLoadoutInfo(specID)) == repairedID,
            }
        end
    end

    if info then
        binding.configID = info.configID
        binding.name = info.name
    end
    return binding, info
end

function addon:ResolveDungeonOverrideLoadout(override, specID)
    if type(override) ~= "table" or override.loadoutMode ~= "override" or type(override.loadout) ~= "table" then
        return nil, nil
    end

    local binding = override.loadout
    if tonumber(binding.specID) and tonumber(binding.specID) ~= tonumber(specID) then
        return nil, nil
    end

    local info
    if binding.configID and C_Traits and C_Traits.GetConfigInfo then
        local okInfo, configInfo = pcall(C_Traits.GetConfigInfo, binding.configID)
        if okInfo and type(configInfo) == "table" then
            info = {
                configID = binding.configID,
                name = configInfo.name or binding.name or ("Loadout " .. tostring(binding.configID)),
                isActive = select(1, self:GetActiveLoadoutInfo(specID)) == binding.configID,
            }
        end
    end

    if not info and binding.name then
        local repairedID, repairedName = self:FindSavedLoadoutByName(specID, binding.name)
        if repairedID then
            binding.configID = repairedID
            binding.specID = specID
            binding.name = repairedName or binding.name
            info = {
                configID = repairedID,
                name = binding.name,
                isActive = select(1, self:GetActiveLoadoutInfo(specID)) == repairedID,
            }
        end
    end

    return binding, info
end

function addon:ResolveRuntimeLoadoutBinding(specID, context)
    context = context or self:DetectActualContext()
    if context == "dungeon" or context == "mythicplus" then
        local override, key = self:GetActiveDungeonOverride()
        if type(override) == "table" then
            if override.loadoutMode == "keep" then
                return nil, nil, "keep", override, key
            elseif override.loadoutMode == "override" then
                local binding, info = self:ResolveDungeonOverrideLoadout(override, specID)
                return binding, info, "override", override, key
            end
        end
    end
    local binding, info = self:ResolveLoadoutBinding(specID, context)
    return binding, info, "default", nil, nil
end

function addon:BindExistingLoadout(configID)
    if not DB or not configID then return false end
    local context = self:GetBuildConfigContext()
    local specID, specName = self:GetBuildConfigSpecInfo(context)

    local chosen
    for _, info in ipairs(self:GetLoadoutList(specID)) do
        if info.configID == configID then
            chosen = info
            break
        end
    end
    if not chosen then
        Print(T("That WoW talent loadout is no longer available."))
        return false
    end

    self:BindManagedLoadout(specID, context, chosen.configID, chosen.name)
    self.pendingLoadoutKey = nil
    Print(T("Mapped WoW talent loadout '%s' to %s / %s.", tostring(chosen.name), tostring(specName), (Data.contextNames and Data.contextNames[context]) or context))
    if DB.autoSwitchLoadouts then
        self:TryAutoSwitchLoadout("mapping")
    end
    return true
end

function addon:BindCurrentLoadout()
    local context = self:GetBuildConfigContext()
    local configSpecID = self:GetBuildConfigSpecID(context)
    local currentSpecID = select(1, self:GetSpecInfo())
    if configSpecID ~= currentSpecID then
        Print(T("Switch to %s before using the current talent loadout for this profile.", tostring((Data.specNames and Data.specNames[configSpecID]) or configSpecID)))
        return false
    end
    local configID = select(1, self:GetActiveLoadoutInfo(currentSpecID))
    if not configID then
        Print(T("Could not read the current WoW talent loadout."))
        return false
    end
    return self:BindExistingLoadout(configID)
end


function addon:FinishPendingLoadoutCreation(configInfo)
    local pending = pendingLoadoutCreation
    if not pending or type(configInfo) ~= "table" or not configInfo.ID then
        return false
    end
    if configInfo.name ~= pending.name then
        return false
    end

    pendingLoadoutCreation = nil
    if C_ClassTalents and C_ClassTalents.SaveConfig then
        pcall(C_ClassTalents.SaveConfig, configInfo.ID)
    end
    self:BindManagedLoadout(pending.specID, pending.context, configInfo.ID, configInfo.name)
    Print(T("Created and saved WoW loadout '%s' for %s.", configInfo.name, (Data.contextNames and Data.contextNames[pending.context]) or pending.context))
    return true
end

function addon:SaveCurrentLoadoutBinding()
    if not DB then return end

    local context = self:GetBuildConfigContext()
    local specID = self:GetBuildConfigSpecID(context)
    local currentSpecID = select(1, self:GetSpecInfo())
    if specID ~= currentSpecID then
        Print(T("Switch to %s before creating a DKM copy for this profile.", tostring((Data.specNames and Data.specNames[specID]) or specID)))
        return
    end
    local managedName = self:GetManagedLoadoutName(context)

    if InCombatLockdown and InCombatLockdown() then
        Print(T("A WoW talent loadout cannot be created while in combat. Try again after combat ends."))
        return
    end

    -- If DK Mentor already created this named loadout, simply bind it again.
    local existingID, existingName = self:FindSavedLoadoutByName(specID, managedName)
    if existingID then
        self:BindManagedLoadout(specID, context, existingID, existingName)
        Print(T("Using existing WoW loadout '%s' for %s.", existingName, (Data.contextNames and Data.contextNames[context]) or context))
        return
    end

    if not C_ClassTalents or not C_ClassTalents.RequestNewConfig then
        -- Compatibility fallback: bind the currently selected saved loadout.
        local configID, name = self:GetActiveLoadoutInfo(specID)
        if configID then
            self:BindManagedLoadout(specID, context, configID, name)
            Print(T("This client could not create '%s'; bound the current WoW loadout '%s' instead.", managedName, tostring(name)))
        else
            Print(T("Could not read or create a WoW talent loadout."))
        end
        return
    end

    if C_ClassTalents.CanCreateNewConfig then
        local okCan, canCreate = pcall(C_ClassTalents.CanCreateNewConfig)
        if okCan and canCreate == false then
            Print(T("WoW cannot create another talent loadout for this specialization. Delete an unused loadout or bind an existing DKM loadout."))
            return
        end
    end

    pendingLoadoutCreation = {
        specID = specID,
        context = context,
        name = managedName,
        requestedAt = GetNow(),
    }

    local ok, success = pcall(C_ClassTalents.RequestNewConfig, managedName)
    if not ok or success == false then
        pendingLoadoutCreation = nil
        Print(T("WoW rejected the new loadout request. Open the Talents window and try again out of combat."))
        return
    end

    Print(T("Creating WoW loadout '%s' from your current talent setup...", managedName))

    -- TRAIT_CONFIG_CREATED is the authoritative completion path. This fallback
    -- handles clients where the list update arrives without the create event.
    if C_Timer and C_Timer.After then
        C_Timer.After(1.0, function()
            if not pendingLoadoutCreation or pendingLoadoutCreation.name ~= managedName then
                return
            end
            local configID, name = addon:FindSavedLoadoutByName(specID, managedName)
            if configID then
                pendingLoadoutCreation = nil
                addon:BindManagedLoadout(specID, context, configID, name)
                Print(T("Created and saved WoW loadout '%s' for %s.", name, (Data.contextNames and Data.contextNames[context]) or context))
            end
        end)
    end
end

function addon:ClearCurrentLoadoutBinding()
    if not DB then return end
    local context = self:GetBuildConfigContext()
    local specID = self:GetBuildConfigSpecID(context)
    DB.loadoutBindings[self:GetLoadoutBindingKey(specID, context)] = nil
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    Print(T("Saved WoW loadout cleared for this content type."))
end

function addon:GetLoadoutPickerSpecInfo()
    local target = self.loadoutPickerTarget
    if type(target) == "table" and target.kind == "dungeon" then
        local specID = self:GetDungeonOverrideEffectiveSpecID(target.key)
        local specIndex = self:GetSpecializationIndexByID(specID)
        local _, name, icon = self:GetSpecializationInfoByIndex(specIndex)
        return specID, name or tostring((Data.specNames and Data.specNames[specID]) or specID), icon, "dungeon", target.key
    end
    local context = self:GetBuildConfigContext()
    local specID, specName, specIcon = self:GetBuildConfigSpecInfo(context)
    return specID, specName, specIcon, context, nil
end

function addon:BindLoadoutPickerSelection(configID)
    local specID, specName, _, context, dungeonKey = self:GetLoadoutPickerSpecInfo()
    if dungeonKey then
        local chosen
        for _, info in ipairs(self:GetLoadoutList(specID)) do
            if info.configID == configID then chosen = info break end
        end
        if not chosen then
            Print(T("That WoW talent loadout is no longer available."))
            return false
        end
        self:SetDungeonOverrideLoadout(dungeonKey, specID, chosen.configID, chosen.name)
        Print(T("Dungeon override talent loadout set to '%s' (%s).", tostring(chosen.name), tostring(specName)))
        self:UpdateDungeonOverrideEditor()
        return true
    end
    return self:BindExistingLoadout(configID)
end

function addon:BindCurrentLoadoutPickerSelection()
    local specID, _, _, _, dungeonKey = self:GetLoadoutPickerSpecInfo()
    if not dungeonKey then return self:BindCurrentLoadout() end
    local currentSpecID = select(1, self:GetSpecInfo())
    if currentSpecID ~= specID then
        Print(T("Switch to %s before using the current talent loadout for this override.", tostring((Data.specNames and Data.specNames[specID]) or specID)))
        return false
    end
    local configID, name = self:GetActiveLoadoutInfo(specID)
    if not configID then return false end
    self:SetDungeonOverrideLoadout(dungeonKey, specID, configID, name)
    return true
end

function addon:GetEquipmentPickerTargetInfo()
    local target = self.equipmentPickerTarget
    if type(target) == "table" and target.kind == "dungeon" then
        local specID = self:GetDungeonOverrideEffectiveSpecID(target.key)
        local specIndex = self:GetSpecializationIndexByID(specID)
        local _, name = self:GetSpecializationInfoByIndex(specIndex)
        return specID, name or tostring((Data.specNames and Data.specNames[specID]) or specID), "dungeon", target.key
    end
    local context = self:GetBuildConfigContext()
    local specID, specName = self:GetBuildConfigSpecInfo(context)
    return specID, specName, context, nil
end

function addon:BindEquipmentPickerSelection(setID)
    local _, _, _, dungeonKey = self:GetEquipmentPickerTargetInfo()
    if dungeonKey then
        local info = self:GetEquipmentSetStatus(setID)
        if not info then
            Print(T("That WoW equipment set is no longer available."))
            return false
        end
        self:SetDungeonOverrideEquipment(dungeonKey, info.setID or setID, info.name)
        Print(T("Dungeon override equipment set set to '%s'.", tostring(info.name)))
        self:UpdateDungeonOverrideEditor()
        return true
    end
    return self:BindExistingEquipmentSet(setID)
end

function addon:BindCurrentlyEquippedPickerSelection()
    local _, _, _, dungeonKey = self:GetEquipmentPickerTargetInfo()
    if not dungeonKey then return self:BindCurrentlyEquippedEquipmentSet() end
    local matches = {}
    for _, info in ipairs(self:GetEquipmentSetList()) do
        if info.isEquipped then table.insert(matches, info) end
    end
    if #matches == 1 then
        return self:BindEquipmentPickerSelection(matches[1].setID)
    elseif #matches > 1 then
        Print(T("More than one saved equipment set matches your current gear. Choose one explicitly."))
    else
        Print(T("Your currently equipped gear does not exactly match a saved WoW equipment set."))
    end
    return false
end

function addon:GetRoleDisplayName(role)
    if role == "TANK" then return T("Tank") end
    if role == "DAMAGER" then return T("Damage") end
    if role == "HEALER" then return T("Healer") end
    return tostring(role or T("Unknown"))
end

function addon:CanAutoSwitchSpecialization(targetSpecID, context)
    if InCombatLockdown and InCombatLockdown() then
        return false, T("Waiting for combat to end")
    end

    context = context or self:DetectActualContext()
    local currentSpecID = select(1, self:GetSpecInfo())
    if currentSpecID == targetSpecID then return true end

    local grouped = false
    if IsInGroup then
        local ok, value = pcall(IsInGroup)
        grouped = ok and value == true
    end

    if context == "dungeon" or context == "mythicplus" or context == "raid" or context == "pvp" then
        local targetRole = self:GetSpecializationRoleByIDSafe(targetSpecID)
        local assignedRole = grouped and self:GetAssignedGroupRole() or nil
        if targetRole and assignedRole and targetRole ~= assignedRole then
            return false, T(
                "Role protection: your group role is %s, but the target specialization is %s (%s). Automatic specialization switching was skipped.",
                self:GetRoleDisplayName(assignedRole),
                tostring((Data.specNames and Data.specNames[targetSpecID]) or targetSpecID),
                self:GetRoleDisplayName(targetRole)
            )
        end

        if targetRole and not assignedRole then
            local currentRole = self:GetSpecializationRoleByIDSafe(currentSpecID)
            if currentRole and targetRole ~= currentRole then
                return false, T(
                    "Role protection: switching from %s to %s would change your group role from %s to %s. Automatic specialization switching was skipped.",
                    tostring((Data.specNames and Data.specNames[currentSpecID]) or currentSpecID),
                    tostring((Data.specNames and Data.specNames[targetSpecID]) or targetSpecID),
                    self:GetRoleDisplayName(currentRole),
                    self:GetRoleDisplayName(targetRole)
                )
            end
        end
    end

    return true
end

function addon:ClearPendingSpecializationSwitch()
    self.pendingSpecializationTargetSpecID = nil
    self.pendingSpecializationContext = nil
    self.pendingSpecializationSwitchStartedAt = nil
    self.pendingSpecializationRetryScheduled = nil
end

function addon:SchedulePendingSpecializationRetry(targetSpecID, delay)
    if not targetSpecID or not C_Timer or not C_Timer.After then return end
    if self.pendingSpecializationRetryScheduled == targetSpecID then return end
    self.pendingSpecializationRetryScheduled = targetSpecID
    C_Timer.After(tonumber(delay) or 2.0, function()
        if addon.pendingSpecializationRetryScheduled == targetSpecID then
            addon.pendingSpecializationRetryScheduled = nil
        end
        if not addon.active or not DB or not DB.autoSwitchSpecialization then return end
        if addon.pendingSpecializationTargetSpecID ~= targetSpecID then return end
        if InCombatLockdown and InCombatLockdown() then return end
        local currentSpecID = select(1, addon:GetSpecInfo())
        if currentSpecID == targetSpecID then
            addon:ClearPendingSpecializationSwitch()
            return
        end
        if addon.pendingSpecializationSwitchStartedAt then return end
        addon:TryAutoSwitchSpecialization("specialization-retry")
    end)
end

function addon:StartPendingSpecializationWatch(targetSpecID, attemptsRemaining)
    if not targetSpecID or not C_Timer or not C_Timer.After then return end
    attemptsRemaining = attemptsRemaining or 8
    C_Timer.After(0.75, function()
        if not addon.active or addon.pendingSpecializationTargetSpecID ~= targetSpecID then return end
        local currentSpecID = select(1, addon:GetSpecInfo())
        if currentSpecID == targetSpecID then
            addon:ClearPendingSpecializationSwitch()
            addon.lastSpecializationSwitchError = nil
            addon:UpdateAll()
            addon:TryAutoSwitchLoadout("specialization-ready")
            addon:TryAutoSwitchEquipment("specialization-ready")
            return
        end
        if attemptsRemaining > 1 then
            addon:StartPendingSpecializationWatch(targetSpecID, attemptsRemaining - 1)
        else
            -- Keep the target pending and retry like Loadout Pilot instead of
            -- abandoning the mapping after one transient client rejection.
            addon.pendingSpecializationSwitchStartedAt = nil
            addon.lastSpecializationSwitchError = T("WoW did not allow the automatic specialization change.")
            addon:UpdateBuildSection()
            addon:UpdateStatusWidget()
            addon:SchedulePendingSpecializationRetry(targetSpecID, 2.0)
        end
    end)
end

function addon:TryAutoSwitchSpecialization(reason)
    if not DB or not DB.autoSwitchSpecialization or not self.active then
        self:ClearPendingSpecializationSwitch()
        return false
    end
    if not self.worldReady and reason ~= "toggle" and reason ~= "mapping" and reason ~= "pvp-enter" then
        return false
    end

    local context = self:DetectActualContext()
    local targetSpecID = select(1, self:ResolveRuntimeSpecializationTarget(context))
    if not targetSpecID then
        self:ClearPendingSpecializationSwitch()
        self.lastSpecializationSwitchError = nil
        return true
    end

    local currentSpecID = select(1, self:GetSpecInfo())
    if currentSpecID == targetSpecID then
        self:ClearPendingSpecializationSwitch()
        self.lastSpecializationSwitchError = nil
        return true
    end

    local allowed, reasonText = self:CanAutoSwitchSpecialization(targetSpecID, context)
    if not allowed then
        if reasonText == T("Waiting for combat to end") then
            self.pendingSpecializationTargetSpecID = targetSpecID
            self.pendingSpecializationContext = context
        else
            self:ClearPendingSpecializationSwitch()
        end
        self.lastSpecializationSwitchError = reasonText
        self:UpdateBuildSection()
        self:UpdateStatusWidget()
        return false
    end

    local now = GetNow()
    if self.lastSpecializationSwitchAttemptTarget == targetSpecID
        and self.lastSpecializationSwitchAttemptAt
        and (now - self.lastSpecializationSwitchAttemptAt) < 2 then
        return false
    end

    local specIndex = self:GetSpecializationIndexByID(targetSpecID)
    if not specIndex then
        self.lastSpecializationSwitchError = T("The target specialization is not available.")
        return false
    end

    local ok, result = false, nil
    -- Keep the same request path that proved reliable in Loadout Pilot.
    -- Retail currently routes this into the ClassTalents switch internally.
    if C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
        ok, result = pcall(C_SpecializationInfo.SetSpecialization, specIndex)
    elseif C_ClassTalents and C_ClassTalents.SwitchToSpecializationByIndex then
        ok, result = pcall(C_ClassTalents.SwitchToSpecializationByIndex, specIndex)
    end

    self.lastSpecializationSwitchAttemptTarget = targetSpecID
    self.lastSpecializationSwitchAttemptAt = now

    if not ok or result == false then
        self.pendingSpecializationTargetSpecID = targetSpecID
        self.pendingSpecializationContext = context
        self.pendingSpecializationSwitchStartedAt = nil
        self.lastSpecializationSwitchError = T("WoW did not allow the automatic specialization change.")
        self:UpdateBuildSection()
        self:UpdateStatusWidget()
        self:SchedulePendingSpecializationRetry(targetSpecID, 2.0)
        return false
    end

    self.pendingSpecializationTargetSpecID = targetSpecID
    self.pendingSpecializationContext = context
    self.pendingSpecializationSwitchStartedAt = now
    self.lastSpecializationSwitchError = nil
    Print(T(
        "Auto-switching specialization to %s for %s...",
        tostring((Data.specNames and Data.specNames[targetSpecID]) or targetSpecID),
        tostring(self:GetRuntimeContextLabel(context))
    ))
    self:StartPendingSpecializationWatch(targetSpecID, 8)
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    return true
end

function addon:ApplyAutomaticProfile(reason)
    self:TryAutoSwitchSpecialization(reason)
    local context = self:DetectActualContext()
    local targetSpecID = select(1, self:ResolveRuntimeSpecializationTarget(context))
    local currentSpecID = select(1, self:GetSpecInfo())

    -- Loot specialization is deliberately independent from the specialization
    -- used to play the dungeon. Apply/restore it even when a playing-spec
    -- switch is still pending or was blocked by role protection. This lets a
    -- Frost/Unholy DPS intentionally select Blood loot without becoming Tank.
    self:SyncDungeonLootSpecialization(reason)

    if targetSpecID and currentSpecID ~= targetSpecID then return false end
    self:TryAutoSwitchLoadout(reason)
    self:TryAutoSwitchEquipment(reason)
    return true
end

function addon:SetAutoSwitchLoadouts(enabled)
    DB.autoSwitchLoadouts = enabled == true
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    Print(DB.autoSwitchLoadouts and "Automatic talent-loadout switching enabled." or "Automatic talent-loadout switching disabled.")
    if DB.autoSwitchLoadouts then
        self:ApplyAutomaticProfile("toggle")
    end
end

function addon:ToggleAutoSwitchLoadouts()
    self:SetAutoSwitchLoadouts(not DB.autoSwitchLoadouts)
end

function addon:ClearPendingLoadoutSwitch()
    self.pendingLoadoutKey = nil
    self.pendingLoadoutTargetConfigID = nil
    self.pendingLoadoutSpecID = nil
    self.pendingLoadoutSwitchStartedAt = nil
    self.lastLoadoutSwitchError = nil
end

function addon:CompletePendingLoadoutSwitch(updateSavedSelection)
    local specID = self.pendingLoadoutSpecID or select(1, self:GetSpecInfo())
    local targetConfigID = self.pendingLoadoutTargetConfigID

    if updateSavedSelection and specID and targetConfigID then
        self:RememberSelectedLoadout(specID, targetConfigID)
    end

    self:ClearPendingLoadoutSwitch()
    self:RefreshTalentFrameUI()
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
end

function addon:StartPendingLoadoutWatch(expectedConfigID, attemptsRemaining)
    if not expectedConfigID or not C_Timer or not C_Timer.After then
        return
    end

    attemptsRemaining = attemptsRemaining or 10
    C_Timer.After(0.75, function()
        if not addon.active or not addon.pendingLoadoutKey then
            return
        end

        local specID = addon.pendingLoadoutSpecID or select(1, addon:GetSpecInfo())
        local selectedID = addon:GetSelectedLoadoutConfigID(specID)
        if selectedID == expectedConfigID then
            addon:CompletePendingLoadoutSwitch(false)
            return
        end

        if attemptsRemaining > 1 then
            addon:StartPendingLoadoutWatch(expectedConfigID, attemptsRemaining - 1)
        elseif addon.pendingLoadoutSwitchStartedAt and not addon.lastLoadoutSwitchError then
            -- Direct LoadConfig does not update the saved-loadout selector by itself.
            -- If the client applied the switch but omitted the expected UI event, sync
            -- the selected saved config after the guarded retry window.
            addon:CompletePendingLoadoutSwitch(true)
        else
            addon:UpdateStatusWidget()
        end
    end)
end

function addon:RefreshTalentFrameUI()
    local function SafeCall(target, methodName)
        if target and type(target[methodName]) == "function" then
            pcall(target[methodName], target)
            return true
        end
        return false
    end

    local refreshed = false

    if PlayerSpellsFrame and PlayerSpellsFrame:IsShown() then
        refreshed = SafeCall(PlayerSpellsFrame, "Refresh") or refreshed
        if PlayerSpellsFrame.TalentsFrame then
            refreshed = SafeCall(PlayerSpellsFrame.TalentsFrame, "Refresh") or refreshed
            refreshed = SafeCall(PlayerSpellsFrame.TalentsFrame, "Update") or refreshed
            refreshed = SafeCall(PlayerSpellsFrame.TalentsFrame, "UpdateTreeInfo") or refreshed
            refreshed = SafeCall(PlayerSpellsFrame.TalentsFrame, "UpdateLoadoutOptions") or refreshed
        end
    end

    if ClassTalentFrame and ClassTalentFrame:IsShown() then
        refreshed = SafeCall(ClassTalentFrame, "Refresh") or refreshed
        refreshed = SafeCall(ClassTalentFrame, "Update") or refreshed
        if ClassTalentFrame.TalentsTab then
            refreshed = SafeCall(ClassTalentFrame.TalentsTab, "Refresh") or refreshed
            refreshed = SafeCall(ClassTalentFrame.TalentsTab, "Update") or refreshed
            refreshed = SafeCall(ClassTalentFrame.TalentsTab, "UpdateView") or refreshed
            refreshed = SafeCall(ClassTalentFrame.TalentsTab, "UpdateLoadoutOptions") or refreshed
        end
    end

    return refreshed
end

function addon:SyncPendingLoadoutState(forceRefreshUI)
    if not DB then
        return false
    end

    local changed = false
    if self.pendingLoadoutKey then
        local targetConfigID = self.pendingLoadoutTargetConfigID
        local specID = self.pendingLoadoutSpecID or select(1, self:GetSpecInfo())
        if not targetConfigID then
            local binding = DB.loadoutBindings and DB.loadoutBindings[self.pendingLoadoutKey]
            targetConfigID = type(binding) == "table" and binding.configID or nil
        end

        local selectedID = self:GetSelectedLoadoutConfigID(specID)
        if targetConfigID and selectedID == targetConfigID then
            self:ClearPendingLoadoutSwitch()
            changed = true
        end
    end

    if forceRefreshUI then
        self:RefreshTalentFrameUI()
    end

    return changed
end

function addon:TryAutoSwitchLoadout(reason)
    if not DB or not DB.autoSwitchLoadouts or not self.active then
        return false
    end
    if not self.worldReady and reason ~= "toggle" and reason ~= "pvp-enter" and reason ~= "specialization-ready" then
        return false
    end

    local specID = select(1, self:GetSpecInfo())
    local context = self:DetectActualContext()
    local targetSpecID = select(1, self:ResolveRuntimeSpecializationTarget(context))
    if targetSpecID and targetSpecID ~= specID then
        self:ClearPendingLoadoutSwitch()
        return false
    end

    local binding, _, mode, _, overrideKey = self:ResolveRuntimeLoadoutBinding(specID, context)
    if mode == "keep" then
        self:ClearPendingLoadoutSwitch()
        self:UpdateStatusWidget()
        return true
    end

    local key = mode == "override" and ("dungeon:" .. tostring(overrideKey or "current") .. ":talents")
        or self:GetLoadoutBindingKey(specID, context)
    if type(binding) ~= "table" or not binding.configID then
        self:ClearPendingLoadoutSwitch()
        return false
    end

    local selectedID = self:GetSelectedLoadoutConfigID(specID)
    if selectedID == binding.configID then
        self:ClearPendingLoadoutSwitch()
        self:UpdateStatusWidget()
        return true
    end

    self.pendingLoadoutKey = key
    self.pendingLoadoutTargetConfigID = binding.configID
    self.pendingLoadoutSpecID = specID

    if InCombatLockdown and InCombatLockdown() then
        self.pendingLoadoutSwitchStartedAt = nil
        self.lastLoadoutSwitchError = T("Waiting for combat to end")
        self:UpdateStatusWidget()
        return false
    end

    if C_ClassTalents and C_ClassTalents.CanEditTalents then
        local okCan, canEdit, changeError = pcall(C_ClassTalents.CanEditTalents)
        if okCan and canEdit == false then
            self.pendingLoadoutSwitchStartedAt = nil
            self.lastLoadoutSwitchError = changeError or T("WoW is not allowing talent changes right now")
            self:UpdateStatusWidget()
            return false
        end
    end

    local contextLabel = self:GetRuntimeContextLabel(context)

    -- Retail 12.0.5+ provides a Blizzard-managed loadout switch. Prefer it
    -- because it routes through the default Talent UI and keeps the dropdown
    -- selection synchronized instead of only copying talents into ActiveConfig.
    if C_ClassTalents and C_ClassTalents.SwitchToLoadoutByIndex then
        local loadoutIndex = self:GetLoadoutIndexByConfigID(specID, binding.configID)
        if loadoutIndex then
            local okSwitch = pcall(C_ClassTalents.SwitchToLoadoutByIndex, loadoutIndex)
            if okSwitch then
                self.pendingLoadoutSwitchStartedAt = GetNow()
                self.lastLoadoutSwitchError = nil
                Print(T("Switching talents to '%s' for %s...", tostring(binding.name or binding.configID), tostring(contextLabel)))
                self:StartPendingLoadoutWatch(binding.configID, 10)
                self:UpdateStatusWidget()
                return true
            end
        end
    end

    -- Compatibility fallback for clients where the secure delegate is not
    -- available. LoadConfig applies the talents, and we explicitly update the
    -- saved-loadout selection when the operation completes.
    if C_ClassTalents and C_ClassTalents.LoadConfig then
        local ok, result, changeError = pcall(C_ClassTalents.LoadConfig, binding.configID, true)
        if ok then
            local errorValue = Enum and Enum.LoadConfigResult and Enum.LoadConfigResult.Error or 0
            local noChangesValue = Enum and Enum.LoadConfigResult and Enum.LoadConfigResult.NoChangesNecessary or 1
            local inProgressValue = Enum and Enum.LoadConfigResult and Enum.LoadConfigResult.LoadInProgress or 2
            local readyValue = Enum and Enum.LoadConfigResult and Enum.LoadConfigResult.Ready or 3

            if result == errorValue then
                self.pendingLoadoutSwitchStartedAt = nil
                self.lastLoadoutSwitchError = changeError or T("WoW rejected the talent loadout change")
                Print(T("Could not switch talent loadout: %s", tostring(self.lastLoadoutSwitchError)))
                self:UpdateStatusWidget()
                return false
            end

            if result == noChangesValue or result == readyValue then
                self:RememberSelectedLoadout(specID, binding.configID)
                self:ClearPendingLoadoutSwitch()
                Print(T("Auto-switching to '%s' for %s.", tostring(binding.name or binding.configID), tostring(contextLabel)))
                self:RefreshTalentFrameUI()
                self:UpdateBuildSection()
                self:UpdateStatusWidget()
                return true
            end

            if result == inProgressValue then
                self.pendingLoadoutSwitchStartedAt = GetNow()
                self.lastLoadoutSwitchError = nil
                Print(T("Switching talents to '%s' for %s...", tostring(binding.name or binding.configID), tostring(contextLabel)))
                self:StartPendingLoadoutWatch(binding.configID, 10)
                self:UpdateStatusWidget()
                return true
            end

            self.pendingLoadoutSwitchStartedAt = GetNow()
            self.lastLoadoutSwitchError = changeError
        else
            self.pendingLoadoutSwitchStartedAt = nil
            self.lastLoadoutSwitchError = tostring(result or T("Talent API call failed"))
        end
    end

    self:UpdateStatusWidget()
    return false
end

function addon:GetEquipmentBindingKey(specID, context)
    return self:GetBuildKey(specID, context)
end

function addon:GetManagedEquipmentSetName(specID, context)
    local specName = (Data.specNames and Data.specNames[specID]) or tostring(specID or "DK")
    local contextNames = {
        world = "World",
        delve = "Delve",
        dungeon = "Dng",
        mythicplus = "M+",
        raid = "Raid",
        pvp = "PvP",
    }
    return string.format("DKM %s %s", specName, contextNames[context] or tostring(context or "World"))
end

function addon:FindEquipmentSetByName(name)
    if not C_EquipmentSet or not name or name == "" then
        return nil
    end

    if C_EquipmentSet.GetEquipmentSetID then
        local ok, setID = pcall(C_EquipmentSet.GetEquipmentSetID, name)
        if ok and type(setID) == "number" then
            return setID
        end
    end

    -- Fallback: walk the player's saved sets. This also repairs mappings if a
    -- set was deleted and recreated with the same name and therefore got a new ID.
    if C_EquipmentSet.GetEquipmentSetIDs and C_EquipmentSet.GetEquipmentSetInfo then
        local okIDs, ids = pcall(C_EquipmentSet.GetEquipmentSetIDs)
        if okIDs and type(ids) == "table" then
            local wanted = string.lower(tostring(name))
            for _, setID in ipairs(ids) do
                local okInfo, setName = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
                if okInfo and type(setName) == "string" and string.lower(setName) == wanted then
                    return setID
                end
            end
        end
    end

    return nil
end

function addon:GetEquipmentSetStatus(setID)
    if not C_EquipmentSet or not C_EquipmentSet.GetEquipmentSetInfo or not setID then
        return nil
    end
    local ok, name, iconFileID, returnedID, isEquipped, numItems, numEquipped, numInInventory, numLost, numIgnored = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
    if not ok or not name then
        return nil
    end
    return {
        name = name,
        iconFileID = iconFileID,
        setID = returnedID or setID,
        isEquipped = isEquipped == true,
        numItems = tonumber(numItems) or 0,
        numEquipped = tonumber(numEquipped) or 0,
        numInInventory = tonumber(numInInventory) or 0,
        numLost = tonumber(numLost) or 0,
        numIgnored = tonumber(numIgnored) or 0,
    }
end

function addon:GetEquipmentSetList()
    local result = {}
    if not C_EquipmentSet or not C_EquipmentSet.GetEquipmentSetIDs then
        return result
    end

    local ok, ids = pcall(C_EquipmentSet.GetEquipmentSetIDs)
    if not ok or type(ids) ~= "table" then
        return result
    end

    for _, setID in ipairs(ids) do
        local info = self:GetEquipmentSetStatus(setID)
        if info then
            table.insert(result, info)
        end
    end

    table.sort(result, function(a, b)
        return string.lower(tostring(a.name or "")) < string.lower(tostring(b.name or ""))
    end)
    return result
end

function addon:ResolveEquipmentBinding(specID, context)
    if not DB then
        return nil, nil
    end

    local key = self:GetEquipmentBindingKey(specID, context)
    local binding = DB.equipmentBindings[key]
    if type(binding) ~= "table" then
        return nil, nil
    end

    local info
    if binding.setID then
        info = self:GetEquipmentSetStatus(binding.setID)
    end

    if not info and binding.name then
        local repairedID = self:FindEquipmentSetByName(binding.name)
        if repairedID then
            info = self:GetEquipmentSetStatus(repairedID)
            if info then
                binding.setID = info.setID or repairedID
                binding.name = info.name
            end
        end
    end

    if info then
        binding.setID = info.setID or binding.setID
        binding.name = info.name or binding.name
    end

    return binding, info
end

function addon:ResolveDungeonOverrideEquipment(override)
    if type(override) ~= "table" or override.equipmentMode ~= "override" or type(override.equipment) ~= "table" then
        return nil, nil
    end

    local binding = override.equipment
    local info
    if binding.setID then
        info = self:GetEquipmentSetStatus(binding.setID)
    end
    if not info and binding.name then
        local repairedID = self:FindEquipmentSetByName(binding.name)
        if repairedID then
            info = self:GetEquipmentSetStatus(repairedID)
            if info then
                binding.setID = info.setID or repairedID
                binding.name = info.name or binding.name
            end
        end
    end
    return binding, info
end

function addon:ResolveRuntimeEquipmentBinding(specID, context)
    context = context or self:DetectActualContext()
    if context == "dungeon" or context == "mythicplus" then
        local override, key = self:GetActiveDungeonOverride()
        if type(override) == "table" then
            if override.equipmentMode == "keep" then
                return nil, nil, "keep", override, key
            elseif override.equipmentMode == "override" then
                local binding, info = self:ResolveDungeonOverrideEquipment(override)
                return binding, info, "override", override, key
            end
        end
    end
    local binding, info = self:ResolveEquipmentBinding(specID, context)
    return binding, info, "default", nil, nil
end

function addon:BindExistingEquipmentSet(setID)
    if not DB then return false end
    local info = self:GetEquipmentSetStatus(setID)
    if not info then
        Print(T("That WoW equipment set is no longer available."))
        return false
    end

    local context = self:GetBuildConfigContext()
    local specID, specName = self:GetBuildConfigSpecInfo(context)
    self:BindEquipmentSet(specID, context, info.setID or setID, info.name)
    self.pendingEquipmentKey = nil

    Print(T("Mapped equipment set '%s' to %s / %s.", tostring(info.name), tostring(specName), (Data.contextNames and Data.contextNames[context]) or context))
    if DB.autoSwitchEquipment then
        self:TryAutoSwitchEquipment("mapping")
    end
    return true
end

function addon:BindCurrentlyEquippedEquipmentSet()
    local matches = {}
    for _, info in ipairs(self:GetEquipmentSetList()) do
        if info.isEquipped then
            table.insert(matches, info)
        end
    end

    if #matches == 1 then
        return self:BindExistingEquipmentSet(matches[1].setID)
    elseif #matches > 1 then
        Print(T("More than one saved equipment set matches your current gear. Use 'Choose gear set...' to select one explicitly."))
    else
        Print(T("Your currently equipped gear does not exactly match a saved WoW equipment set. Equip one of your saved sets first or choose it from the list."))
    end
    return false
end

function addon:BindEquipmentSet(specID, context, setID, name)
    if not DB or not setID then
        return false
    end
    local key = self:GetEquipmentBindingKey(specID, context)
    DB.equipmentBindings[key] = {
        setID = setID,
        name = name or self:GetManagedEquipmentSetName(specID, context),
    }
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    return true
end

function addon:FinishPendingEquipmentCreation()
    local pending = pendingEquipmentCreation
    if not pending then
        return false
    end
    local setID = self:FindEquipmentSetByName(pending.name)
    if not setID then
        return false
    end

    pendingEquipmentCreation = nil
    if C_EquipmentSet and C_EquipmentSet.SaveEquipmentSet then
        pcall(C_EquipmentSet.SaveEquipmentSet, setID)
    end
    self:BindEquipmentSet(pending.specID, pending.context, setID, pending.name)
    Print(T("Created and saved equipment set '%s' for %s.", pending.name, (Data.contextNames and Data.contextNames[pending.context]) or pending.context))
    return true
end

function addon:SaveCurrentEquipmentBinding()
    -- v0.4.5 no longer creates duplicate DKM equipment sets from this action.
    -- It maps an already saved WoW Equipment Set that exactly matches the
    -- currently equipped gear. Use the picker when more than one set matches.
    return self:BindCurrentlyEquippedEquipmentSet()
end

function addon:ClearCurrentEquipmentBinding()
    if not DB then return end
    local context = self:GetBuildConfigContext()
    local specID = self:GetBuildConfigSpecID(context)
    DB.equipmentBindings[self:GetEquipmentBindingKey(specID, context)] = nil
    self.pendingEquipmentKey = nil
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    Print(T("Saved equipment-set association cleared for this content type. The WoW equipment set itself was not deleted."))
end

function addon:SetAutoSwitchEquipment(enabled)
    DB.autoSwitchEquipment = enabled == true
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    Print(DB.autoSwitchEquipment and "Automatic equipment switching enabled." or "Automatic equipment switching disabled.")
    if DB.autoSwitchEquipment then
        self:ApplyAutomaticProfile("toggle")
    end
end

function addon:ToggleAutoSwitchEquipment()
    self:SetAutoSwitchEquipment(not DB.autoSwitchEquipment)
end

function addon:SyncPendingEquipmentState(announce)
    if not self.pendingEquipmentKey then return false end

    local specID = select(1, self:GetSpecInfo())
    local context = self:DetectActualContext()
    local targetSpecID = select(1, self:ResolveRuntimeSpecializationTarget(context))
    if targetSpecID and targetSpecID ~= specID then return false end

    local binding, info = self:ResolveRuntimeEquipmentBinding(specID, context)
    if info and info.isEquipped then
        self.pendingEquipmentKey = nil
        lootSpecState.equipmentRetryElapsed = 0
        if announce and type(binding) == "table" then
            Print(T("Auto-equipping '%s' for %s.", tostring(binding.name or binding.setID), tostring(self:GetRuntimeContextLabel(context))))
        end
        self:UpdateBuildSection()
        self:UpdateStatusWidget()
        return true
    end
    return false
end

function addon:TryAutoSwitchEquipment(reason)
    if not DB or not DB.autoSwitchEquipment or not self.active then
        return false
    end
    if not self.worldReady and reason ~= "toggle" and reason ~= "specialization-ready" then
        return false
    end

    local specID = select(1, self:GetSpecInfo())
    local context = self:DetectActualContext()
    local targetSpecID = select(1, self:ResolveRuntimeSpecializationTarget(context))
    if targetSpecID and targetSpecID ~= specID then
        self.pendingEquipmentKey = nil
        lootSpecState.equipmentRetryElapsed = 0
        return false
    end

    local binding, info, mode, _, overrideKey = self:ResolveRuntimeEquipmentBinding(specID, context)
    if mode == "keep" then
        self.pendingEquipmentKey = nil
        lootSpecState.equipmentRetryElapsed = 0
        self:UpdateStatusWidget()
        return true
    end

    local key = mode == "override" and ("dungeon:" .. tostring(overrideKey or "current") .. ":gear")
        or self:GetEquipmentBindingKey(specID, context)
    if type(binding) ~= "table" then
        self.pendingEquipmentKey = nil
        lootSpecState.equipmentRetryElapsed = 0
        return false
    end

    if not info or not binding.setID then
        self.pendingEquipmentKey = key
        self:UpdateStatusWidget()
        return false
    end

    if info.isEquipped then
        self.pendingEquipmentKey = nil
        lootSpecState.equipmentRetryElapsed = 0
        self:UpdateStatusWidget()
        return true
    end

    self.pendingEquipmentKey = key

    if InCombatLockdown and InCombatLockdown() then
        self:UpdateStatusWidget()
        return false
    end

    if C_EquipmentSet and C_EquipmentSet.CanUseEquipmentSets then
        local okCan, canUse = pcall(C_EquipmentSet.CanUseEquipmentSets)
        local canUseAccessible = okCan and GetAccessibleBoolean(canUse) or nil
        if canUseAccessible == false then
            self:UpdateStatusWidget()
            return false
        end
    end

    if C_EquipmentSet and C_EquipmentSet.UseEquipmentSet then
        local okUse, rawEquipped = pcall(C_EquipmentSet.UseEquipmentSet, binding.setID)
        local requestAccepted = okUse and GetAccessibleBoolean(rawEquipped)
        if requestAccepted == true then
            -- Do not clear the pending target just because the request was
            -- accepted. Retail can report success before the equipment-set
            -- state has caught up during transitions. Finalize only after the
            -- mapped set is actually reported as equipped.
            if self:SyncPendingEquipmentState(true) then return true end
            self:UpdateStatusWidget()
            return true
        end
    end

    self:UpdateStatusWidget()
    return false
end

function addon:GetSelectedBuild(specID, context)
    local profiles = self:GetBuildProfiles(specID, context)
    if #profiles == 0 then
        return nil, 0, profiles
    end

    local key = self:GetBuildKey(specID, context)
    local index = Clamp(DB.selectedBuild[key] or 1, 1, #profiles)
    DB.selectedBuild[key] = index
    return profiles[index], index, profiles
end

function addon:CycleBuild(delta)
    local context = self:GetBuildConfigContext()
    local specID = self:GetBuildConfigSpecID(context)
    local profiles = self:GetBuildProfiles(specID, context)
    if #profiles <= 1 then
        return
    end

    local key = self:GetBuildKey(specID, context)
    local index = Clamp(DB.selectedBuild[key] or 1, 1, #profiles)
    index = ((index - 1 + delta) % #profiles) + 1
    DB.selectedBuild[key] = index
    self:UpdateBuildSection()
end

function addon:GetAssistedCombatAvailability()
    if not C_AssistedCombat or not C_AssistedCombat.IsAvailable then
        return false, T("The C_AssistedCombat API is not available in this game client.")
    end

    local ok, available, reason = pcall(C_AssistedCombat.IsAvailable)
    if not ok then
        return false, T("The native combat assistant could not be queried.")
    end

    return available == true, reason or ""
end

function addon:GetRotationSpells()
    if not C_AssistedCombat or not C_AssistedCombat.GetRotationSpells then
        return {}
    end

    local ok, spells = pcall(C_AssistedCombat.GetRotationSpells)
    if ok and type(spells) == "table" then
        return spells
    end

    return {}
end

function addon:CheckActionBarCoverage(silent)
    local rotationSpells = self:GetRotationSpells()
    if #rotationSpells == 0 then
        self.coverageText = T("Action bars: the native rotation has not provided a spell list yet.")
        self:UpdateAssistedCombatSection()
        if not silent then
            Print(self.coverageText)
        end
        return
    end

    local found = {}
    local wanted = {}
    for _, spellID in ipairs(rotationSpells) do
        wanted[spellID] = true
    end

    for slot = 1, 180 do
        local actionType, actionID, subType = GetActionInfo(slot)
        if actionID and (actionType == "spell" or (actionType == "macro" and subType == "spell")) then
            found[actionID] = true

            if C_Spell and C_Spell.GetOverrideSpell then
                local ok, overrideSpellID = pcall(C_Spell.GetOverrideSpell, actionID)
                if ok and overrideSpellID then
                    found[overrideSpellID] = true
                end
            end
        end
    end

    local present = 0
    local missingNames = {}
    for _, spellID in ipairs(rotationSpells) do
        if found[spellID] then
            present = present + 1
        elseif #missingNames < 3 then
            local spellName = GetSpellData(spellID)
            table.insert(missingNames, spellName)
        end
    end

    if present == #rotationSpells then
        self.coverageText = T("Action bars: %d/%d rotation spells found.", present, #rotationSpells)
    else
        local missingText = #missingNames > 0 and table.concat(missingNames, ", ") or "unidentified spells"
        self.coverageText = T(
            "Action bars: %d/%d found. Missing or inside macros: %s%s",
            present,
            #rotationSpells,
            missingText,
            (#rotationSpells - present) > #missingNames and "…" or "."
        )
    end

    self:UpdateAssistedCombatSection()
    if not silent then
        Print(self.coverageText .. T(" Macro detection is approximate."))
    end
end

function addon:ToggleNativeHighlight()
    local enabled = GetCVarBoolSafe("assistedCombatHighlight")
    if not SetCVarSafe("assistedCombatHighlight", not enabled) then
        Print(T("The native highlight could not be changed. Enable it in the WoW combat options."))
        return
    end

    C_Timer.After(0.1, function()
        addon:UpdateAssistedCombatSection()
        addon:CheckActionBarCoverage(true)
    end)
end


function addon:RefreshMountSpellCache(force)
    if self.mountCacheReady and not force then
        return
    end

    self.mountSpellIDs = {}
    if not C_MountJournal or not C_MountJournal.GetMountIDs or not C_MountJournal.GetMountInfoByID then
        return
    end

    local okIDs, mountIDs = pcall(C_MountJournal.GetMountIDs)
    if not okIDs or type(mountIDs) ~= "table" then
        return
    end

    for _, mountID in ipairs(mountIDs) do
        local okInfo, _, spellID = pcall(C_MountJournal.GetMountInfoByID, mountID)
        if okInfo and type(spellID) == "number" then
            self.mountSpellIDs[spellID] = true
        end
    end
    self.mountCacheReady = true
end

function addon:RememberHearthstoneSpell(spellID, spellName)
    self.hearthstoneSpellIDs = self.hearthstoneSpellIDs or {}
    self.hearthstoneSpellNames = self.hearthstoneSpellNames or {}
    if type(spellID) == "number" then
        self.hearthstoneSpellIDs[spellID] = true
    end
    if type(spellName) == "string" and spellName ~= "" then
        self.hearthstoneSpellNames[string.lower(spellName)] = true
    end
end

function addon:CacheHearthstoneItemSpell(itemID, requestIfMissing)
    if type(itemID) ~= "number" then
        return
    end

    self.hearthstoneItemIDs = self.hearthstoneItemIDs or {}
    self.hearthstoneItemLoadRequested = self.hearthstoneItemLoadRequested or {}
    self.hearthstoneItemIDs[itemID] = true

    local ok, spellName, spellID
    if C_Item and C_Item.GetItemSpell then
        ok, spellName, spellID = pcall(C_Item.GetItemSpell, itemID)
    elseif GetItemSpell then
        ok, spellName, spellID = pcall(GetItemSpell, itemID)
    end

    if ok and (type(spellID) == "number" or (type(spellName) == "string" and spellName ~= "")) then
        self:RememberHearthstoneSpell(spellID, spellName)
        return
    end

    -- Request each item at most once per session. ITEM_DATA_LOAD_RESULT must
    -- never rebuild/request the full list again; that could create an event
    -- feedback storm while a character is entering the world.
    if requestIfMissing and not self.hearthstoneItemLoadRequested[itemID]
        and C_Item and C_Item.RequestLoadItemDataByID then
        self.hearthstoneItemLoadRequested[itemID] = true
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
end

function addon:RefreshHearthstoneSpellCache(requestMissing)
    self.hearthstoneSpellIDs = self.hearthstoneSpellIDs or {}
    self.hearthstoneSpellNames = self.hearthstoneSpellNames or {}
    self.hearthstoneItemIDs = self.hearthstoneItemIDs or {}

    for spellID, enabled in pairs(Voices.hearthstoneSpells or {}) do
        if enabled and type(spellID) == "number" then
            local spellName
            if C_Spell and C_Spell.GetSpellInfo then
                local okInfo, info = pcall(C_Spell.GetSpellInfo, spellID)
                if okInfo and type(info) == "table" then spellName = info.name end
            elseif GetSpellInfo then
                local okInfo, name = pcall(GetSpellInfo, spellID)
                if okInfo then spellName = name end
            end
            self:RememberHearthstoneSpell(spellID, spellName)
        end
    end

    for _, itemID in ipairs(Voices.hearthstoneItems or {}) do
        self:CacheHearthstoneItemSpell(itemID, requestMissing == true)
    end
end

function addon:RefreshVoiceTriggerCaches(force)
    if not DB or not DB.voice or not DB.voice.enabled or DB.voice.situational == false then
        return
    end
    self:RefreshMountSpellCache(force == true)
    self:RefreshHearthstoneSpellCache(true)
end

function addon:IsMountSpell(spellID)
    return type(spellID) == "number" and self.mountSpellIDs and self.mountSpellIDs[spellID] == true
end

function addon:IsHearthstoneSpell(spellID)
    if type(spellID) ~= "number" then
        return false
    end
    if self.hearthstoneSpellIDs and self.hearthstoneSpellIDs[spellID] == true then
        return true
    end

    -- A cosmetic Hearthstone can resolve to a spell ID that was not available
    -- when the item cache was first built. A localized spell-name match gives
    -- us a second safe path after at least one known Hearthstone has loaded.
    local spellName
    if C_Spell and C_Spell.GetSpellInfo then
        local okInfo, info = pcall(C_Spell.GetSpellInfo, spellID)
        if okInfo and type(info) == "table" then spellName = info.name end
    elseif GetSpellInfo then
        local okInfo, name = pcall(GetSpellInfo, spellID)
        if okInfo then spellName = name end
    end
    return type(spellName) == "string"
        and self.hearthstoneSpellNames
        and self.hearthstoneSpellNames[string.lower(spellName)] == true
end

function addon:TriggerPriorityVoice(category, minInterval)
    if not DB or not DB.voice or DB.voice.situational == false then
        lastVoiceAttemptCategory = category
        lastVoiceAttemptResult = "situations disabled"
        self:UpdateVoiceSection()
        return false
    end

    local played, result = self:TryVoiceComment(category, {
        force = true,
        ignoreCooldown = true,
        interrupt = true,
        minCategoryInterval = minInterval or 6,
    })
    lastVoiceAttemptCategory = category
    lastVoiceAttemptResult = played and "played" or tostring(result or "not played")
    self:UpdateVoiceSection()
    return played, result
end

function addon:CheckMountedTransition()
    if not self.active or not DB or not DB.voice or not DB.voice.enabled or DB.voice.situational == false or not IsMounted then
        return
    end

    local ok, rawMounted = pcall(IsMounted)
    if not ok then
        return
    end
    local mounted = GetAccessibleBoolean(rawMounted)
    if mounted == nil then
        return
    end

    if mounted and not self.lastMountedState then
        self.lastMountedState = true
        self:TriggerPriorityVoice("mount", 8)
    elseif not mounted then
        self.lastMountedState = false
    end
end

function addon:GetVoiceFrequencyConfig()
    local frequencyKey = DB and DB.voice and DB.voice.frequency or "normal"
    local frequencies = Voices.frequencies or {}
    local config = frequencies[frequencyKey]

    if not config then
        frequencyKey = "normal"
        config = frequencies.normal or {
            label = "Normal",
            cooldown = 95,
            chance = 0.48,
        }
        if DB and DB.voice then
            DB.voice.frequency = frequencyKey
        end
    end

    return config, frequencyKey
end

function addon:IsVoicePlaying()
    local now = GetNow()

    if voiceHandle and C_Sound and C_Sound.IsPlaying then
        local ok, playing = pcall(C_Sound.IsPlaying, voiceHandle)
        if ok and playing then
            return true
        elseif ok then
            voiceHandle = nil
        end
    end

    return now < (voiceBusyUntil or 0)
end

function addon:StopVoice()
    if voiceHandle and StopSound then
        pcall(StopSound, voiceHandle)
    end

    voiceHandle = nil
    voiceBusyUntil = 0
end

function addon:IsVoiceAllowedInCurrentContext()
    if not DB or not DB.voice then
        return false
    end

    if DB.voice.allowInPvP == false then
        local context = select(1, self:DetectContext())
        if context == "pvp" then
            return false
        end
    end

    return true
end

function addon:PlayVoiceFile(fileDataID)
    if not PlaySoundFile or type(fileDataID) ~= "number" then
        return false
    end

    local ok, willPlay, soundHandle = pcall(PlaySoundFile, fileDataID, Voices.channel or "Dialog")
    if not ok or willPlay == false then
        return false
    end

    voiceHandle = type(soundHandle) == "number" and soundHandle or nil
    voiceBusyUntil = GetNow() + 10
    return true
end

function addon:GetVoiceSelection(category)
    if not DB or not DB.voice then
        return 0
    end
    DB.voice.selections = DB.voice.selections or {}
    return tonumber(DB.voice.selections[category]) or 0
end

function addon:GetVoiceSelectionText(category)
    local pool = Voices.pools and Voices.pools[category] or nil
    local count = type(pool) == "table" and #pool or 0
    if count == 0 then
        return T("Unavailable")
    end

    local selection = self:GetVoiceSelection(category)
    if selection == -1 then
        return T("Disabled")
    elseif selection >= 1 and selection <= count then
        return T("Voice %d/%d", selection, count)
    end
    return T("Random (%d)", count)
end

function addon:SetVoiceSelection(category, selection)
    if not DB or not DB.voice then
        return
    end
    local pool = Voices.pools and Voices.pools[category] or nil
    if type(pool) ~= "table" or #pool == 0 then
        return
    end

    selection = tonumber(selection) or 0
    if selection < -1 then selection = -1 end
    if selection > #pool then selection = #pool end
    DB.voice.selections = DB.voice.selections or {}
    DB.voice.selections[category] = selection
    self:UpdateVoiceConfigFrame()
end

function addon:CycleVoiceSelection(category, delta)
    local pool = Voices.pools and Voices.pools[category] or nil
    if type(pool) ~= "table" or #pool == 0 then
        return
    end

    local selection = self:GetVoiceSelection(category)
    local states = #pool + 2 -- Disabled (-1), Random (0), then 1..N.
    local position = selection + 2
    position = ((position - 1 + (tonumber(delta) or 1)) % states) + 1
    self:SetVoiceSelection(category, position - 2)
end

function addon:ResetVoiceSelections()
    if not DB or not DB.voice then
        return
    end
    DB.voice.selections = {}
    self:UpdateVoiceConfigFrame()
    Print(T("All Lich King situation voices reset to Random."))
end

function addon:ChooseVoiceFile(pool, category)
    if type(pool) ~= "table" or #pool == 0 then
        return nil
    end

    local selection = category and self:GetVoiceSelection(category) or 0
    if selection == -1 then
        return nil, "disabled"
    elseif selection >= 1 and selection <= #pool then
        return pool[selection], "selected"
    end

    if #pool == 1 then
        return pool[1], "random"
    end

    local selected
    for _ = 1, 8 do
        selected = pool[math.random(1, #pool)]
        if selected ~= lastVoiceFileID then
            return selected, "random"
        end
    end

    for _, fileDataID in ipairs(pool) do
        if fileDataID ~= lastVoiceFileID then
            return fileDataID, "random"
        end
    end

    return selected or pool[1], "random"
end

function addon:TryVoiceComment(category, options)
    options = options or {}
    category = category or "preview"

    if not options.preview then
        if not DB or not DB.voice or not DB.voice.enabled then
            return false, "Voice commentary is disabled."
        end
        if not self:IsVoiceAllowedInCurrentContext() then
            return false, "Voice commentary is disabled in PvP."
        end
    end

    if not PlaySoundFile then
        return false, "The PlaySoundFile API is unavailable."
    end

    if InCinematic then
        local ok, cinematic = pcall(InCinematic)
        if ok and cinematic then
            return false, "Voice commentary is paused during cinematics."
        end
    end

    local pools = Voices.pools or {}
    local pool = pools[category] or pools.preview
    if type(pool) ~= "table" or #pool == 0 then
        return false, "No voice files are configured for this event."
    end

    if category ~= "preview" and self:GetVoiceSelection(category) == -1 then
        return false, "This voice situation is disabled."
    end

    local now = GetNow()
    local minCategoryInterval = tonumber(options.minCategoryInterval)
    if minCategoryInterval and (now - (lastVoiceCategoryAt[category] or -1000000)) < minCategoryInterval then
        return false, "This situation was already announced recently."
    end

    if options.interrupt then
        self:StopVoice()
    elseif self:IsVoicePlaying() then
        return false, "Another commentary line is still playing."
    end

    local config = self:GetVoiceFrequencyConfig()
    local cooldown = tonumber(options.cooldown) or tonumber(config.cooldown) or 95
    if not options.preview and not options.ignoreCooldown and (now - lastVoiceAt) < cooldown then
        return false, "Commentary cooldown is active."
    end

    if not options.preview and not options.force then
        local multiplier = 1
        if Voices.categoryChance and Voices.categoryChance[category] then
            multiplier = tonumber(Voices.categoryChance[category]) or 1
        end
        if options.chanceMultiplier then
            multiplier = multiplier * (tonumber(options.chanceMultiplier) or 1)
        end

        local chance = Clamp((tonumber(config.chance) or 0.48) * multiplier, 0, 1)
        if math.random() > chance then
            return false, "Random chance skipped this event."
        end
    end

    local configuredSelection = self:GetVoiceSelection(category)
    local tried = {}
    local maxAttempts = configuredSelection >= 1 and 1 or math.min(4, #pool)
    for _ = 1, maxAttempts do
        local fileDataID = self:ChooseVoiceFile(pool, category)
        if fileDataID and not tried[fileDataID] then
            tried[fileDataID] = true
            if self:PlayVoiceFile(fileDataID) then
                lastVoiceAt = now
                lastVoiceFileID = fileDataID
                lastVoiceCategory = category
                lastVoiceCategoryAt[category] = now
                if mainFrame and mainFrame.voiceSection then
                    self:UpdateVoiceSection()
                end
                return true, fileDataID
            end
        end
    end

    return false, "The selected localized game audio could not be played."
end

function addon:PreviewVoiceCategory(category)
    self:StopVoice()
    local played, result = self:TryVoiceComment(category, {
        preview = true,
        force = true,
        ignoreCooldown = true,
        interrupt = true,
    })
    if not played then
        Print(T("Voice preview failed for %s: %s", tostring((Voices.categoryLabels and Voices.categoryLabels[category]) or category), tostring(result)))
    end
end

function addon:PreviewVoice()
    self:StopVoice()
    local played, result = self:TryVoiceComment("preview", {
        preview = true,
        force = true,
        ignoreCooldown = true,
    })

    if played then
        Print(T("Lich King commentary preview played. Client locale: %s.", GetClientLocale()))
    else
        Print(T("Voice preview failed: %s", tostring(result)))
    end
end

function addon:ToggleVoice(forceEnabled)
    if not DB or not DB.voice then
        return
    end

    if forceEnabled == nil then
        DB.voice.enabled = not DB.voice.enabled
    else
        DB.voice.enabled = forceEnabled == true
    end

    if not DB.voice.enabled then
        self:StopVoice()
    elseif self.worldReady and DB.voice.situational ~= false then
        self:RefreshVoiceTriggerCaches(false)
    end

    self:UpdateVoiceSection()
    Print(T(DB.voice.enabled and "Lich King commentary enabled." or "Lich King commentary disabled."))
end

function addon:SetVoiceFrequency(frequencyKey)
    frequencyKey = string.lower(Trim(frequencyKey))
    if not Voices.frequencies or not Voices.frequencies[frequencyKey] then
        Print(T("Invalid voice frequency. Use low, normal, or high."))
        return
    end

    DB.voice.frequency = frequencyKey
    self:UpdateVoiceSection()
    local config = Voices.frequencies[frequencyKey]
    Print(T("Lich King commentary frequency set to %s.", tostring(config.label or frequencyKey)))
end

function addon:CycleVoiceFrequency()
    local order = Voices.frequencyOrder or { "low", "normal", "high" }
    local _, currentKey = self:GetVoiceFrequencyConfig()
    local currentIndex = 1

    for index, key in ipairs(order) do
        if key == currentKey then
            currentIndex = index
            break
        end
    end

    local nextIndex = currentIndex + 1
    if nextIndex > #order then
        nextIndex = 1
    end

    self:SetVoiceFrequency(order[nextIndex])
end

function addon:SetVoicePvP(enabled)
    DB.voice.allowInPvP = enabled == true
    self:UpdateVoiceSection()
    Print(T(DB.voice.allowInPvP and "Lich King commentary is allowed in PvP." or "Lich King commentary is muted in PvP."))
end

function addon:SetVoiceSituational(enabled)
    DB.voice.situational = enabled == true
    if DB.voice.situational and DB.voice.enabled and self.worldReady then
        self:RefreshVoiceTriggerCaches(false)
    end
    self:UpdateVoiceSection()
    Print(T(DB.voice.situational and "Situational Lich King comments enabled." or "Situational Lich King comments disabled."))
end

function addon:HandleSituationalSpellVoice(spellID)
    if not DB or not DB.voice or DB.voice.situational == false then
        return
    end
    local trigger = Voices.situationalSpells and Voices.situationalSpells[spellID]
    if not trigger then
        return
    end
    if type(trigger) == "string" then
        self:TryVoiceComment(trigger)
    elseif type(trigger) == "table" then
        self:TryVoiceComment(trigger.category or "spell", {
            chanceMultiplier = trigger.chanceMultiplier or 1,
            cooldown = trigger.cooldown or 18,
        })
    end
end

function addon:HandleVoiceCommand(rest)
    rest = Trim(rest)
    local action, value = rest:match("^(%S*)%s*(.-)$")
    action = string.lower(action or "")
    value = string.lower(Trim(value))

    if action == "" or action == "toggle" then
        self:ToggleVoice()
    elseif action == "on" then
        self:ToggleVoice(true)
    elseif action == "off" then
        self:ToggleVoice(false)
    elseif action == "test" or action == "preview" then
        self:PreviewVoice()
    elseif action == "low" or action == "normal" or action == "high" then
        self:SetVoiceFrequency(action)
    elseif action == "frequency" then
        self:SetVoiceFrequency(value)
    elseif action == "situations" or action == "situation" then
        if value == "on" then
            self:SetVoiceSituational(true)
        elseif value == "off" then
            self:SetVoiceSituational(false)
        else
            self:SetVoiceSituational(not DB.voice.situational)
        end
    elseif action == "map" or action == "mapping" or action == "voices" then
        self:ToggleVoiceConfigFrame()
    elseif action == "reset" then
        self:ResetVoiceSelections()
    elseif action == "pvp" then
        if value == "on" then
            self:SetVoicePvP(true)
        elseif value == "off" then
            self:SetVoicePvP(false)
        else
            Print(T("Use /dkm voice pvp on or /dkm voice pvp off."))
        end
    elseif action == "status" then
        local config = self:GetVoiceFrequencyConfig()
        Print(string.format(
            "Lich King commentary: %s • frequency: %s • PvP: %s • situations: %s • client locale: %s • last priority event: %s (%s).",
            DB.voice.enabled and "enabled" or "disabled",
            tostring(config.label or DB.voice.frequency),
            DB.voice.allowInPvP and "allowed" or "muted",
            DB.voice.situational and "on" or "off",
            GetClientLocale(),
            tostring(lastVoiceAttemptCategory or "none"),
            tostring(lastVoiceAttemptResult or "none")
        ))
    else
        Print(T("Use /dkm voice on|off|test|low|normal|high|status|map|reset, /dkm voice pvp on|off, or /dkm voice situations on|off."))
    end
end

local function CreateSection(parent, title, topOffset, height)
    local section = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, topOffset)
    section:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, topOffset)
    section:SetHeight(height)
    section:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    section:SetBackdropColor(0.03, 0.075, 0.105, 0.72)
    section:SetBackdropBorderColor(0.12, 0.38, 0.5, 0.8)

    section.title = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    section.title:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -8)
    section.title:SetText(title)
    section.title:SetTextColor(0.45, 0.85, 1)

    return section
end

local function StyleTabButton(button, active)
    if not button then return end
    button.isSelected = active == true
    if active then
        button:SetBackdropColor(0.035, 0.20, 0.27, 0.98)
        button:SetBackdropBorderColor(0.35, 0.82, 1.00, 1)
        button.label:SetTextColor(0.72, 0.94, 1.00)
    else
        button:SetBackdropColor(0.025, 0.065, 0.085, 0.90)
        button:SetBackdropBorderColor(0.16, 0.38, 0.48, 0.82)
        button.label:SetTextColor(0.92, 0.84, 0.58)
    end
end

local function CreateFlatTabButton(parent, width, height, label)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.label:SetText(label or "")
    button:SetScript("OnEnter", function(self)
        if not self.isSelected then
            self:SetBackdropColor(0.045, 0.12, 0.15, 0.96)
            self:SetBackdropBorderColor(0.26, 0.58, 0.70, 0.95)
        end
    end)
    button:SetScript("OnLeave", function(self)
        StyleTabButton(self, self.isSelected)
    end)
    StyleTabButton(button, false)
    return button
end

local function CreateContextSelector(parent, labelText, options)
    options = options or {}
    local contexts = options.contexts or Data.contextOrder or {}
    local labelWidth = options.labelWidth or 145
    local buttonWidth = options.buttonWidth or 96
    local gap = options.gap or 4
    local getSelectedContext = options.getSelectedContext or function()
        return DB and DB.modeOverride or "auto"
    end
    local onSelect = options.onSelect or function(contextKey)
        DB.modeOverride = contextKey
        addon:UpdateAll()
    end

    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -2)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -2)
    bar:SetHeight(42)
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    bar:SetBackdropColor(0.025, 0.065, 0.085, 0.72)
    bar:SetBackdropBorderColor(0.10, 0.30, 0.38, 0.75)

    bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.label:SetPoint("LEFT", bar, "LEFT", 10, 0)
    bar.label:SetWidth(labelWidth)
    bar.label:SetJustifyH("LEFT")
    bar.label:SetText(labelText)
    bar.label:SetTextColor(0.55, 0.84, 0.95)

    bar.buttons = {}
    local startX = 10 + labelWidth + 10
    for index, contextKey in ipairs(contexts) do
        local button = CreateFlatTabButton(bar, buttonWidth, 26, (Data.contextNames and Data.contextNames[contextKey]) or contextKey)
        button:SetPoint("LEFT", bar, "LEFT", startX + ((index - 1) * (buttonWidth + gap)), 0)
        button.contextKey = contextKey
        if options.readOnly then
            button:EnableMouse(false)
        else
            button:SetScript("OnClick", function(self)
                onSelect(self.contextKey)
            end)
        end
        table.insert(bar.buttons, button)

        if options.useGlobalModeButtons then
            modeButtons[contextKey] = modeButtons[contextKey] or {}
            table.insert(modeButtons[contextKey], button)
        end
    end

    function bar:RefreshSelection()
        local selected = getSelectedContext()
        for _, button in ipairs(self.buttons) do
            StyleTabButton(button, button.contextKey == selected)
        end
    end

    return bar
end

local function NormalizeAddonLanguage(value)
    value = string.lower(tostring(value or "auto"))
    if value == "ptbr" or value == "pt" or value == "portuguese" or value == "portugues" then
        return "ptBR"
    end
    if value == "enus" or value == "engb" or value == "en" or value == "english" then
        return "enUS"
    end
    return "auto"
end

local function GetAddonLanguageLabel(value)
    value = NormalizeAddonLanguage(value)
    if value == "ptBR" then return T("Portuguese (Brazil)") end
    if value == "enUS" then return T("English") end
    return T("Automatic (WoW)")
end

local function CreateLanguagePickerFrame()
    local frame = CreateFrame("Frame", "DKMentorLanguagePicker", UIParent, "BackdropTemplate")
    frame:SetSize(390, 250)
    -- This picker is modal-like and must always render above the DK Mentor main window.
    -- The main window itself uses DIALOG, so FULLSCREEN_DIALOG prevents the picker
    -- from being visually/mouse-obscured by the parent settings UI.
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1000)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    if frame.SetToplevel then frame:SetToplevel(true) end
    ApplyBackdrop(frame, 0.98)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
    frame.title:SetText(T("Addon language"))
    frame.title:SetTextColor(0.55, 0.86, 1)

    frame.description = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.description:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -10)
    frame.description:SetWidth(350)
    frame.description:SetJustifyH("LEFT")
    frame.description:SetJustifyV("TOP")
    frame.description:SetText(T("Choose the DK Mentor language. Automatic follows the WoW client language; unsupported client languages use English."))

    frame.current = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.current:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -92)
    frame.current:SetWidth(350)
    frame.current:SetJustifyH("LEFT")

    local choices = {
        { value = "auto", label = "Automatic (WoW)" },
        { value = "ptBR", label = "Portuguese (Brazil)" },
        { value = "enUS", label = "English" },
    }
    frame.choiceButtons = {}
    for index, choice in ipairs(choices) do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(110, 30)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 16 + ((index - 1) * 118), -120)
        button.languageValue = choice.value
        button.languageLabelKey = choice.label
        button:SetText(T(choice.label))
        button:SetScript("OnClick", function(self)
            addon:SetLanguageOverride(self.languageValue)
        end)
        frame.choiceButtons[index] = button
    end

    frame.cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.cancel:SetSize(120, 28)
    frame.cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16)
    frame.cancel:SetText(T("Cancel"))
    frame.cancel:SetScript("OnClick", function() frame:Hide() end)

    frame:SetScript("OnShow", function(self)
        addon:UpdateLanguagePicker()
    end)
    frame:Hide()
    return frame
end

function addon:CreateProfileSpecializationPickerFrame()
    local frame = CreateFrame("Frame", "DKMentorProfileSpecializationPicker", UIParent, "BackdropTemplate")
    frame:SetSize(285, 162)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1200)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    if frame.SetToplevel then frame:SetToplevel(true) end
    ApplyBackdrop(frame, 0.99)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -11)
    frame.title:SetText(T("Profile specialization"))
    frame.title:SetTextColor(0.52, 0.88, 1)

    frame.rows = {}
    local values = { false, 250, 251, 252 }
    for index, value in ipairs(values) do
        local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
        row:SetSize(261, 27)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -31 - ((index - 1) * 29))
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        row:SetBackdropColor(0.035, 0.09, 0.12, 0.94)
        row:SetBackdropBorderColor(0.12, 0.34, 0.42, 0.9)
        row.specID = value or nil

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(21, 21)
        row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetWidth(165)
        row.name:SetJustifyH("LEFT")

        row.state = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.state:SetPoint("RIGHT", row, "RIGHT", -7, 0)
        row.state:SetWidth(56)
        row.state:SetJustifyH("RIGHT")

        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.055, 0.18, 0.23, 0.98)
            self:SetBackdropBorderColor(0.30, 0.72, 0.88, 1)
        end)
        row:SetScript("OnLeave", function() addon:UpdateProfileSpecializationPicker() end)
        row:SetScript("OnClick", function(self)
            addon:SetContentSpecializationBinding(addon:GetBuildConfigContext(), self.specID)
            frame:Hide()
        end)
        frame.rows[index] = row
    end

    frame:Hide()
    return frame
end

function addon:UpdateProfileSpecializationPicker()
    local frame = self.profileSpecializationPickerFrame
    if not frame or not DB then return end
    local context = self:GetBuildConfigContext()
    local selected = self:GetContentSpecializationBinding(context)
    for index, row in ipairs(frame.rows or {}) do
        if row.specID == nil then
            row.icon:SetTexture(QUESTION_MARK_ICON)
            row.name:SetText(T("Do not change"))
        else
            local specIndex = self:GetSpecializationIndexByID(row.specID)
            local _, name, icon = self:GetSpecializationInfoByIndex(specIndex)
            row.icon:SetTexture(icon or QUESTION_MARK_ICON)
            row.name:SetText(name or tostring((Data.specNames and Data.specNames[row.specID]) or row.specID))
        end
        local isSelected = (selected == row.specID) or (selected == nil and row.specID == nil)
        if isSelected then
            row.state:SetText(T("SELECTED"))
            row.state:SetTextColor(0.45, 1.0, 0.65)
            row:SetBackdropColor(0.045, 0.18, 0.13, 0.98)
            row:SetBackdropBorderColor(0.30, 0.78, 0.50, 1)
        else
            row.state:SetText("")
            row:SetBackdropColor(0.035, 0.09, 0.12, 0.94)
            row:SetBackdropBorderColor(0.12, 0.34, 0.42, 0.9)
        end
    end
end

function addon:ToggleProfileSpecializationPicker()
    local frame = self.profileSpecializationPickerFrame
    if not frame or not mainFrame or not mainFrame.buildSection then return end
    if frame:IsShown() then frame:Hide() return end
    self:UpdateProfileSpecializationPicker()
    frame:ClearAllPoints()
    frame:SetPoint("TOPRIGHT", mainFrame.buildSection.specButton, "BOTTOMRIGHT", 0, -4)
    frame:Show()
    frame:Raise()
end

function addon:CreateLootSpecializationPickerFrame()
    local frame = CreateFrame("Frame", "DKMentorLootSpecializationPicker", UIParent, "BackdropTemplate")
    frame:SetSize(330, 196)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1200)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    if frame.SetToplevel then frame:SetToplevel(true) end
    ApplyBackdrop(frame, 0.995)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -11)
    frame.title:SetText(T("Loot specialization"))
    frame.title:SetTextColor(0.52, 0.88, 1)

    frame.rows = {}
    local values = { false, 0, 250, 251, 252 }
    for index, value in ipairs(values) do
        local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
        row:SetSize(306, 27)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -31 - ((index - 1) * 29))
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        row:SetBackdropColor(0.035, 0.09, 0.12, 0.94)
        row:SetBackdropBorderColor(0.12, 0.34, 0.42, 0.9)
        row.noLootOverride = value == false
        row.lootSpecID = row.noLootOverride and nil or value

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(21, 21)
        row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetWidth(205)
        row.name:SetJustifyH("LEFT")
        row.state = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.state:SetPoint("RIGHT", row, "RIGHT", -7, 0)
        row.state:SetWidth(62)
        row.state:SetJustifyH("RIGHT")
        row:SetScript("OnEnter", function(self) self:SetBackdropColor(0.055, 0.18, 0.23, 0.98) end)
        row:SetScript("OnLeave", function() addon:UpdateLootSpecializationPicker() end)
        row:SetScript("OnClick", function(self)
            if addon.activeDungeonOverrideKey then addon:SetDungeonOverrideLootSpec(addon.activeDungeonOverrideKey, self.lootSpecID) end
            frame:Hide()
        end)
        frame.rows[index] = row
    end
    frame:Hide()
    return frame
end

function addon:UpdateLootSpecializationPicker()
    local frame = self.lootSpecializationPickerFrame
    local key = self.activeDungeonOverrideKey
    if not frame or not key then return end
    local override = self:GetDungeonOverride(key)
    local selected = type(override) == "table" and override.lootSpecID or nil
    for index, row in ipairs(frame.rows or {}) do
        if index == 1 then
            row.icon:SetTexture(QUESTION_MARK_ICON)
            row.name:SetText(T("No override"))
        elseif row.lootSpecID == 0 then
            local currentSpecID = select(1, self:GetSpecInfo())
            local specIndex = self:GetSpecializationIndexByID(currentSpecID)
            local _, currentName, icon = self:GetSpecializationInfoByIndex(specIndex)
            row.icon:SetTexture(icon or QUESTION_MARK_ICON)
            row.name:SetText(T("Current specialization (%s)", tostring(currentName or T("Unknown"))))
        else
            local specIndex = self:GetSpecializationIndexByID(row.lootSpecID)
            local _, name, icon = self:GetSpecializationInfoByIndex(specIndex)
            row.icon:SetTexture(icon or QUESTION_MARK_ICON)
            row.name:SetText(name or tostring((Data.specNames and Data.specNames[row.lootSpecID]) or row.lootSpecID))
        end
        local isSelected = (row.noLootOverride and selected == nil) or (not row.noLootOverride and selected == row.lootSpecID)
        if isSelected then
            row.state:SetText(T("SELECTED"))
            row.state:SetTextColor(0.45, 1.0, 0.65)
            row:SetBackdropColor(0.045, 0.18, 0.13, 0.98)
            row:SetBackdropBorderColor(0.30, 0.78, 0.50, 1)
        else
            row.state:SetText("")
            row:SetBackdropColor(0.035, 0.09, 0.12, 0.94)
            row:SetBackdropBorderColor(0.12, 0.34, 0.42, 0.9)
        end
    end
end

function addon:ToggleLootSpecializationPicker()
    local frame = self.lootSpecializationPickerFrame
    local editor = self.dungeonOverrideEditorFrame
    if not frame or not editor or not editor.lootSpecButton then return end
    if frame:IsShown() then frame:Hide(); return end
    self:UpdateLootSpecializationPicker()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", editor.lootSpecButton, "BOTTOMLEFT", 0, -4)
    frame:Show()
    frame:Raise()
end

function addon:GetDungeonOverrideSummary(info)
    if type(info) ~= "table" then return T("Uses Dungeon/Mythic+ profile") end
    local override = self:GetDungeonOverride(info.key)
    if type(override) ~= "table" then override = select(1, self:FindDungeonOverrideForIdentity(info, true)) end
    if type(override) ~= "table" then return T("Uses Dungeon/Mythic+ profile") end
    if override.enabled == false then return T("Override disabled") end

    local fallbackContext = self:GetDungeonFallbackContext(info)
    local fallbackName = tostring((Data.contextNames and Data.contextNames[fallbackContext]) or fallbackContext)
    local specText
    if override.specMode == "keep" then specText = T("Keep current")
    elseif override.specMode == "spec" and override.specID then specText = tostring((Data.specNames and Data.specNames[tonumber(override.specID)]) or override.specID)
    else specText = fallbackName end

    local lootText = self:GetLootSpecDisplayName(override.lootSpecID)
    local talentText = fallbackName
    if override.loadoutMode == "keep" then talentText = T("Keep current")
    elseif override.loadoutMode == "override" and type(override.loadout) == "table" then talentText = tostring(override.loadout.name or T("Custom")) end
    local gearText = fallbackName
    if override.equipmentMode == "keep" then gearText = T("Keep current")
    elseif override.equipmentMode == "override" and type(override.equipment) == "table" then gearText = tostring(override.equipment.name or T("Custom")) end

    return T("Spec: %s • Loot: %s • Talents: %s • Gear: %s", specText, lootText, talentText, gearText)
end

function addon:CreateDungeonOverridesFrame()
    local frame = CreateFrame("Frame", "DKMentorDungeonOverridesFrame", UIParent, "BackdropTemplate")
    frame:SetSize(720, 520)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(180)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.99)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetScript("OnMouseWheel", function(_, delta)
        local catalog = addon:GetDungeonCatalog()
        local maxOffset = math.max(0, #catalog - 10)
        addon.dungeonOverrideScrollOffset = Clamp((addon.dungeonOverrideScrollOffset or 0) - delta, 0, maxOffset)
        addon:UpdateDungeonOverridesFrame()
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -15)
    frame.title:SetText(T("Dungeon Overrides"))
    frame.title:SetTextColor(0.52, 0.88, 1)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -6)
    frame.subtitle:SetWidth(650)
    frame.subtitle:SetJustifyH("LEFT")
    frame.subtitle:SetText(T("One override per dungeon is shared across Normal, Heroic, Mythic 0, and Mythic+. Spec, talents, and gear can inherit the active Dungeon/Mythic+ profile; Loot Spec is independent."))

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    frame.rows = {}
    for index = 1, 10 do
        local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
        row:SetSize(680, 38)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -72 - ((index - 1) * 40))
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        row:SetBackdropColor(0.025, 0.08, 0.11, index % 2 == 0 and 0.50 or 0.30)
        row:SetBackdropBorderColor(0.12, 0.34, 0.42, 0.8)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -6)
        row.name:SetWidth(260)
        row.name:SetJustifyH("LEFT")
        row.name:SetTextColor(0.55, 0.88, 1)

        row.summary = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.summary:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -21)
        row.summary:SetWidth(600)
        row.summary:SetJustifyH("LEFT")

        row.action = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.action:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.action:SetText(T("Configure"))

        row:SetScript("OnEnter", function(self) self:SetBackdropColor(0.07, 0.20, 0.26, 0.82) end)
        row:SetScript("OnLeave", function(self)
            local i = self.rowIndex or 1
            self:SetBackdropColor(0.025, 0.08, 0.11, i % 2 == 0 and 0.50 or 0.30)
        end)
        row:SetScript("OnClick", function(self)
            if self.dungeonKey then addon:OpenDungeonOverrideEditor(self.dungeonKey, self.dungeonInfo) end
        end)
        row.rowIndex = index
        frame.rows[index] = row
    end

    frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 17)
    frame.footer:SetWidth(650)
    frame.footer:SetJustifyH("LEFT")

    frame:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, frame:GetName()) end
    return frame
end

function addon:UpdateDungeonOverridesFrame()
    local frame = self.dungeonOverridesFrame
    if not frame or not DB then return end
    local catalog = self:GetDungeonCatalog()
    local maxOffset = math.max(0, #catalog - 10)
    self.dungeonOverrideScrollOffset = Clamp(self.dungeonOverrideScrollOffset or 0, 0, maxOffset)
    local offset = self.dungeonOverrideScrollOffset
    local current = self:GetCurrentDungeonIdentity()

    for index, row in ipairs(frame.rows or {}) do
        local info = catalog[index + offset]
        if info then
            local _, existingOverrideKey = self:FindDungeonOverrideForIdentity(info, true)
            row.dungeonKey = existingOverrideKey or info.key
            row.dungeonInfo = info
            local currentSuffix = ""
            if current and ((current.challengeMapID and current.challengeMapID == info.challengeMapID)
                or (current.instanceID and current.instanceID == info.instanceID)
                or (current.uiMapID and current.uiMapID == info.uiMapID)) then
                currentSuffix = "  |cff66ff99" .. T("CURRENT") .. "|r"
            end
            row.name:SetText(tostring(info.name or info.key) .. currentSuffix)
            row.summary:SetText(self:GetDungeonOverrideSummary(info))
            row:Show()
        else
            row.dungeonKey = nil
            row.dungeonInfo = nil
            row:Hide()
        end
    end

    if #catalog == 0 then
        frame.footer:SetText(T("No dungeons were discovered yet. Enter a dungeon or open the Mythic+ interface, then reopen this window."))
    elseif #catalog > 10 then
        frame.footer:SetText(T("Showing %d-%d of %d dungeons • use the mouse wheel to scroll.", offset + 1, math.min(offset + 10, #catalog), #catalog))
    else
        frame.footer:SetText(T("%d dungeons discovered dynamically from WoW and your visited instances.", #catalog))
    end
end

function addon:OpenDungeonOverrides()
    local frame = self.dungeonOverridesFrame
    if not frame then return end
    self:RememberCurrentDungeon()
    self:UpdateDungeonOverridesFrame()
    frame:Show()
    frame:Raise()
end

function addon:CycleDungeonOverrideSpecMode(key)
    local override = self:EnsureDungeonOverride(key)
    if not override then return end
    local modes = {
        { mode = "inherit" }, { mode = "keep" }, { mode = "spec", specID = 250 },
        { mode = "spec", specID = 251 }, { mode = "spec", specID = 252 },
    }
    local currentIndex = 1
    for index, entry in ipairs(modes) do
        if override.specMode == entry.mode and (entry.mode ~= "spec" or tonumber(override.specID) == entry.specID) then
            currentIndex = index
            break
        end
    end
    local nextEntry = modes[(currentIndex % #modes) + 1]
    self:SetDungeonOverrideSpecMode(key, nextEntry.mode, nextEntry.specID)
end

function addon:CycleDungeonOverrideLoadoutMode(key)
    local override = self:EnsureDungeonOverride(key)
    if not override then return end
    if override.loadoutMode == "inherit" then
        self:SetDungeonOverrideLoadoutMode(key, "keep")
    elseif override.loadoutMode == "keep" then
        self:OpenLoadoutPicker({ kind = "dungeon", key = key })
    else
        self:SetDungeonOverrideLoadoutMode(key, "inherit")
    end
end

function addon:CycleDungeonOverrideEquipmentMode(key)
    local override = self:EnsureDungeonOverride(key)
    if not override then return end
    if override.equipmentMode == "inherit" then
        self:SetDungeonOverrideEquipmentMode(key, "keep")
    elseif override.equipmentMode == "keep" then
        self:OpenEquipmentPicker({ kind = "dungeon", key = key })
    else
        self:SetDungeonOverrideEquipmentMode(key, "inherit")
    end
end

function addon:CreateDungeonOverrideEditorFrame()
    local frame = CreateFrame("Frame", "DKMentorDungeonOverrideEditorFrame", UIParent, "BackdropTemplate")
    frame:SetSize(640, 485)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(900)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.995)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetScript("OnHide", function()
        if addon.lootSpecializationPickerFrame then addon.lootSpecializationPickerFrame:Hide() end
        if loadoutPickerFrame then loadoutPickerFrame:Hide() end
        if equipmentPickerFrame then equipmentPickerFrame:Hide() end
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -15)
    frame.title:SetTextColor(0.52, 0.88, 1)
    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -6)
    frame.subtitle:SetWidth(570)
    frame.subtitle:SetJustifyH("LEFT")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    frame.enableButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.enableButton:SetSize(210, 28)
    frame.enableButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -68)
    frame.enableButton:SetScript("OnClick", function()
        local key = addon.activeDungeonOverrideKey
        local override = key and addon:GetDungeonOverride(key)
        if key and override then addon:SetDungeonOverrideEnabled(key, override.enabled == false) end
    end)

    frame.specLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.specLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -116)
    frame.specLabel:SetText(T("Playing specialization"))
    frame.specButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.specButton:SetSize(290, 28)
    frame.specButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -138)
    frame.specButton:SetScript("OnClick", function() if addon.activeDungeonOverrideKey then addon:CycleDungeonOverrideSpecMode(addon.activeDungeonOverrideKey) end end)
    frame.specHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.specHint:SetPoint("LEFT", frame.specButton, "RIGHT", 12, 0)
    frame.specHint:SetWidth(295)
    frame.specHint:SetJustifyH("LEFT")

    frame.lootSpecLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.lootSpecLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -186)
    frame.lootSpecLabel:SetText(T("Loot specialization"))
    frame.lootSpecButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.lootSpecButton:SetSize(290, 28)
    frame.lootSpecButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -208)
    frame.lootSpecButton:SetScript("OnClick", function() addon:ToggleLootSpecializationPicker() end)
    frame.lootSpecHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.lootSpecHint:SetPoint("LEFT", frame.lootSpecButton, "RIGHT", 12, 0)
    frame.lootSpecHint:SetWidth(295)
    frame.lootSpecHint:SetJustifyH("LEFT")
    frame.lootSpecHint:SetText(T("Changes only the loot table preference; it never changes the role you are playing."))

    frame.talentLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.talentLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -256)
    frame.talentLabel:SetText(T("Talent loadout"))
    frame.talentModeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.talentModeButton:SetSize(290, 28)
    frame.talentModeButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -278)
    frame.talentModeButton:SetScript("OnClick", function() if addon.activeDungeonOverrideKey then addon:CycleDungeonOverrideLoadoutMode(addon.activeDungeonOverrideKey) end end)
    frame.talentChooseButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.talentChooseButton:SetSize(180, 28)
    frame.talentChooseButton:SetPoint("LEFT", frame.talentModeButton, "RIGHT", 12, 0)
    frame.talentChooseButton:SetText(T("Choose loadout..."))
    frame.talentChooseButton:SetScript("OnClick", function()
        if addon.activeDungeonOverrideKey then addon:OpenLoadoutPicker({ kind = "dungeon", key = addon.activeDungeonOverrideKey }) end
    end)

    frame.gearLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.gearLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -326)
    frame.gearLabel:SetText(T("Equipment set"))
    frame.gearModeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.gearModeButton:SetSize(290, 28)
    frame.gearModeButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -348)
    frame.gearModeButton:SetScript("OnClick", function() if addon.activeDungeonOverrideKey then addon:CycleDungeonOverrideEquipmentMode(addon.activeDungeonOverrideKey) end end)
    frame.gearChooseButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.gearChooseButton:SetSize(180, 28)
    frame.gearChooseButton:SetPoint("LEFT", frame.gearModeButton, "RIGHT", 12, 0)
    frame.gearChooseButton:SetText(T("Choose gear set..."))
    frame.gearChooseButton:SetScript("OnClick", function()
        if addon.activeDungeonOverrideKey then addon:OpenEquipmentPicker({ kind = "dungeon", key = addon.activeDungeonOverrideKey }) end
    end)

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -396)
    frame.hint:SetWidth(595)
    frame.hint:SetHeight(35)
    frame.hint:SetJustifyH("LEFT")
    frame.hint:SetJustifyV("TOP")
    frame.hint:SetText(T("Inherit follows the active Dungeon or Mythic+ profile. Keep current prevents DK Mentor from changing that component. Loot Spec uses No override when DK Mentor should leave it alone."))

    frame.deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.deleteButton:SetSize(180, 27)
    frame.deleteButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 13)
    frame.deleteButton:SetText(T("Delete override"))
    frame.deleteButton:SetScript("OnClick", function() if addon.activeDungeonOverrideKey then addon:DeleteDungeonOverride(addon.activeDungeonOverrideKey) end end)
    frame.doneButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.doneButton:SetSize(120, 27)
    frame.doneButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 13)
    frame.doneButton:SetText(T("Done"))
    frame.doneButton:SetScript("OnClick", function() frame:Hide() end)

    frame:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, frame:GetName()) end
    return frame
end

function addon:OpenDungeonOverrideEditor(key, info)
    if not key or not self.dungeonOverrideEditorFrame then return end
    self.activeDungeonOverrideKey = key
    self:EnsureDungeonOverride(key, info)
    self:UpdateDungeonOverrideEditor()
    self.dungeonOverrideEditorFrame:Show()
    self.dungeonOverrideEditorFrame:Raise()
end

function addon:UpdateDungeonOverrideEditor()
    local frame = self.dungeonOverrideEditorFrame
    local key = self.activeDungeonOverrideKey
    if not frame or not key or not DB then return end
    local override = self:GetDungeonOverride(key)
    if type(override) ~= "table" then return end
    local info = self:GetDungeonCatalogEntry(key) or {
        key = key, name = override.name, instanceID = override.instanceID,
        challengeMapID = override.challengeMapID, uiMapID = override.uiMapID,
        supportsMythicPlus = override.challengeMapID ~= nil,
    }
    local fallbackContext = self:GetDungeonFallbackContext(info)
    local fallbackName = tostring((Data.contextNames and Data.contextNames[fallbackContext]) or fallbackContext)

    frame.title:SetText(T("Dungeon Override — %s", tostring(override.name or T("Dungeon"))))
    frame.subtitle:SetText(T("One dungeon rule is reused across Normal, Heroic, Mythic 0, and Mythic+. Inherited fields follow the active Dungeon/Mythic+ profile."))
    frame.enableButton:SetText(T(override.enabled == false and "Override: DISABLED" or "Override: ENABLED"))

    local specText
    if override.specMode == "keep" then specText = T("Spec: Keep current")
    elseif override.specMode == "spec" and override.specID then specText = T("Spec: %s", tostring((Data.specNames and Data.specNames[tonumber(override.specID)]) or override.specID))
    else specText = T("Spec: Use %s default", fallbackName) end
    frame.specButton:SetText(specText)
    local effectiveSpecID = self:GetDungeonOverrideEffectiveSpecID(key)
    frame.specHint:SetText(T("Effective specialization for talent selection: %s", tostring((Data.specNames and Data.specNames[effectiveSpecID]) or effectiveSpecID)))

    frame.lootSpecButton:SetText(T("Loot: %s", self:GetLootSpecDisplayName(override.lootSpecID)))

    if override.loadoutMode == "keep" then frame.talentModeButton:SetText(T("Talents: Keep current"))
    elseif override.loadoutMode == "override" and type(override.loadout) == "table" then frame.talentModeButton:SetText(T("Talents: %s", tostring(override.loadout.name or T("Custom"))))
    else frame.talentModeButton:SetText(T("Talents: Use %s default", fallbackName)) end

    if override.equipmentMode == "keep" then frame.gearModeButton:SetText(T("Gear: Keep current"))
    elseif override.equipmentMode == "override" and type(override.equipment) == "table" then frame.gearModeButton:SetText(T("Gear: %s", tostring(override.equipment.name or T("Custom"))))
    else frame.gearModeButton:SetText(T("Gear: Use %s default", fallbackName)) end
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "DKMentorMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(830, 760)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.97)

    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveFramePosition(self, "main")
    end)
    frame:SetScript("OnShow", function()
        addon:UpdateAll()
        addon:SetMainTab(DB and DB.mainTab or "combat")
        if frame.loadoutContextBar and frame.loadoutContextBar.RefreshSelection then
            frame.loadoutContextBar:RefreshSelection()
        end
    end)

    frame.specIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.specIcon:SetSize(42, 42)
    frame.specIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -13)
    frame.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame.specIcon, "TOPRIGHT", 10, -1)
    frame.title:SetText("DK Mentor")
    frame.title:SetTextColor(0.52, 0.88, 1)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    frame.subtitle:SetWidth(695)
    frame.subtitle:SetJustifyH("LEFT")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    -- Primary navigation. These are global pages; only Combat and Loadouts
    -- contain a content-profile selector.
    local tabOrder = { "combat", "builds", "guide", "settings" }
    local tabLabels = {
        combat = T("Combat"),
        builds = T("Loadouts"),
        guide = T("Guide"),
        settings = T("Settings"),
    }
    local tabWidth = 188
    for index, tabKey in ipairs(tabOrder) do
        local button = CreateFlatTabButton(frame, tabWidth, 31, tabLabels[tabKey])
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 22 + ((index - 1) * (tabWidth + 8)), -69)
        button.tabKey = tabKey
        button:SetScript("OnClick", function(self)
            addon:SetMainTab(self.tabKey)
        end)
        tabButtons[tabKey] = button
    end

    frame.pages = {}
    local function CreatePage(key)
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -108)
        page:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 42)
        page:Hide()
        frame.pages[key] = page
        return page
    end

    local combatPage = CreatePage("combat")
    local buildsPage = CreatePage("builds")
    local guidePage = CreatePage("guide")
    local settingsPage = CreatePage("settings")

    -- COMBAT TAB -----------------------------------------------------------
    frame.combatContextBar = CreateContextSelector(combatPage, T("Detected content:"), {
        contexts = { "world", "delve", "dungeon", "mythicplus", "raid", "pvp" },
        labelWidth = 145,
        buttonWidth = 96,
        getSelectedContext = function() return addon:DetectActualContext() end,
        readOnly = true,
    })

    frame.offenseSection = CreateSection(combatPage, T("Offensive rotation"), -52, 132)
    local offense = frame.offenseSection

    offense.status = offense:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    offense.status:SetPoint("TOPLEFT", offense, "TOPLEFT", 12, -30)
    offense.status:SetWidth(500)
    offense.status:SetHeight(68)
    offense.status:SetJustifyH("LEFT")
    offense.status:SetJustifyV("TOP")

    offense.toggleButton = CreateFrame("Button", nil, offense, "UIPanelButtonTemplate")
    offense.toggleButton:SetSize(205, 26)
    offense.toggleButton:SetPoint("TOPRIGHT", offense, "TOPRIGHT", -12, -30)
    offense.toggleButton:SetScript("OnClick", function() addon:ToggleNativeHighlight() end)

    offense.checkButton = CreateFrame("Button", nil, offense, "UIPanelButtonTemplate")
    offense.checkButton:SetSize(205, 26)
    offense.checkButton:SetPoint("TOPRIGHT", offense, "TOPRIGHT", -12, -62)
    offense.checkButton:SetText(T("Check action bars"))
    offense.checkButton:SetScript("OnClick", function() addon:CheckActionBarCoverage(false) end)

    offense.hint = offense:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    offense.hint:SetPoint("BOTTOMLEFT", offense, "BOTTOMLEFT", 12, 10)
    offense.hint:SetWidth(745)
    offense.hint:SetJustifyH("LEFT")
    offense.hint:SetText(T("The offensive highlight comes from Blizzard Assisted Combat. DK Mentor does not calculate a custom APL during combat."))

    frame.survivalSection = CreateSection(combatPage, T("Survival — when to use it"), -194, 322)
    local survival = frame.survivalSection

    survival.scopeHint = survival:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    survival.scopeHint:SetPoint("TOPRIGHT", survival, "TOPRIGHT", -10, -9)
    survival.scopeHint:SetText(T("HUD visibility is configured in Settings"))

    for index = 1, 6 do
        local row = CreateFrame("Frame", nil, survival)
        row:SetPoint("TOPLEFT", survival, "TOPLEFT", 8, -34 - ((index - 1) * 45))
        row:SetPoint("TOPRIGHT", survival, "TOPRIGHT", -8, -34 - ((index - 1) * 45))
        row:SetHeight(41)
        row:EnableMouse(true)

        row.background = row:CreateTexture(nil, "BACKGROUND")
        row.background:SetAllPoints()
        row.background:SetColorTexture(0.04, 0.11, 0.15, index % 2 == 0 and 0.55 or 0.35)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(33, 33)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        row.tag = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.tag:SetPoint("LEFT", row.icon, "RIGHT", 7, 9)
        row.tag:SetWidth(115)
        row.tag:SetJustifyH("LEFT")
        row.tag:SetTextColor(0.45, 0.85, 1)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 7, -8)
        row.name:SetWidth(250)
        row.name:SetJustifyH("LEFT")

        row.description = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.description:SetPoint("LEFT", row, "LEFT", 390, 0)
        row.description:SetPoint("RIGHT", row, "RIGHT", -7, 0)
        row.description:SetHeight(37)
        row.description:SetJustifyH("LEFT")
        row.description:SetJustifyV("MIDDLE")

        row:SetScript("OnEnter", function(self)
            self.background:SetColorTexture(0.08, 0.22, 0.29, 0.72)
            if self.spellID and GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spellID)
                else GameTooltip:SetText(self.spellName or T("Ability")) end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self.background:SetColorTexture(0.04, 0.11, 0.15, self.rowIndex % 2 == 0 and 0.55 or 0.35)
            if GameTooltip then GameTooltip:Hide() end
        end)
        row.rowIndex = index
        tipRows[index] = row
    end

    -- LOADOUTS TAB ---------------------------------------------------------
    frame.loadoutContextBar = CreateContextSelector(buildsPage, T("Configure loadout for:"), {
        contexts = { "world", "delve", "dungeon", "mythicplus", "raid", "pvp" },
        labelWidth = 180,
        buttonWidth = 92,
        getSelectedContext = function() return addon:GetBuildConfigContext() end,
        onSelect = function(contextKey) addon:SetBuildConfigContext(contextKey) end,
    })
    frame.buildSection = CreateSection(buildsPage, T("Loadouts"), -52, 520)
    local build = frame.buildSection

    build.name = build:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    build.name:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -30)
    build.name:SetWidth(315)
    build.name:SetJustifyH("LEFT")

    build.specLabel = build:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    build.specLabel:SetPoint("TOPLEFT", build, "TOPLEFT", 330, -34)
    build.specLabel:SetText(T("Profile spec:"))
    build.specLabel:SetTextColor(0.50, 0.86, 1)

    build.specButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.specButton:SetSize(215, 26)
    build.specButton:SetPoint("TOPLEFT", build, "TOPLEFT", 405, -27)
    build.specButton:SetScript("OnClick", function() addon:ToggleProfileSpecializationPicker() end)

    build.previousButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.previousButton:SetSize(32, 24)
    build.previousButton:SetPoint("TOPRIGHT", build, "TOPRIGHT", -88, -27)
    build.previousButton:SetText("<")
    build.previousButton:SetScript("OnClick", function() addon:CycleBuild(-1) end)

    build.index = build:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    build.index:SetPoint("LEFT", build.previousButton, "RIGHT", 5, 0)
    build.index:SetWidth(42)
    build.index:SetJustifyH("CENTER")

    build.nextButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.nextButton:SetSize(32, 24)
    build.nextButton:SetPoint("LEFT", build.index, "RIGHT", 5, 0)
    build.nextButton:SetText(">")
    build.nextButton:SetScript("OnClick", function() addon:CycleBuild(1) end)

    build.note = build:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    build.note:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -58)
    build.note:SetWidth(745)
    build.note:SetHeight(48)
    build.note:SetJustifyH("LEFT")
    build.note:SetJustifyV("TOP")

    build.source = build:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    build.source:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -109)
    build.source:SetWidth(745)
    build.source:SetHeight(18)
    build.source:SetJustifyH("LEFT")

    build.sourceURLBox = CreateFrame("EditBox", nil, build, "InputBoxTemplate")
    build.sourceURLBox:SetPoint("TOPLEFT", build, "TOPLEFT", 16, -133)
    build.sourceURLBox:SetSize(535, 26)
    build.sourceURLBox:SetAutoFocus(false)
    build.sourceURLBox:SetFontObject("ChatFontNormal")
    build.sourceURLBox:SetTextInsets(4, 4, 0, 0)
    build.sourceURLBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    build.sourceURLBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    build.sourceButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.sourceButton:SetSize(165, 25)
    build.sourceButton:SetPoint("LEFT", build.sourceURLBox, "RIGHT", 8, 0)
    build.sourceButton:SetText(T("Select source URL"))
    build.sourceButton:SetScript("OnClick", function()
        build.sourceURLBox:SetFocus()
        build.sourceURLBox:HighlightText()
    end)

    build.codeLabel = build:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    build.codeLabel:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -169)
    build.codeLabel:SetText(T("Personal talent import code (optional; stored locally):"))

    build.codeBox = CreateFrame("EditBox", nil, build, "InputBoxTemplate")
    build.codeBox:SetPoint("TOPLEFT", build, "TOPLEFT", 16, -189)
    build.codeBox:SetSize(465, 28)
    build.codeBox:SetAutoFocus(false)
    build.codeBox:SetFontObject("ChatFontNormal")
    build.codeBox:SetTextInsets(4, 4, 0, 0)
    build.codeBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        addon:UpdateBuildSection()
    end)
    build.codeBox:SetScript("OnEnterPressed", function(self)
        addon:SavePersonalBuildCode()
        self:ClearFocus()
    end)

    build.selectButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.selectButton:SetSize(115, 27)
    build.selectButton:SetPoint("LEFT", build.codeBox, "RIGHT", 8, 0)
    build.selectButton:SetText(T("Save code"))
    build.selectButton:SetScript("OnClick", function()
        addon:SavePersonalBuildCode()
        build.codeBox:ClearFocus()
    end)

    build.clearButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.clearButton:SetSize(90, 27)
    build.clearButton:SetPoint("LEFT", build.selectButton, "RIGHT", 8, 0)
    build.clearButton:SetText(T("Clear"))
    build.clearButton:SetScript("OnClick", function()
        addon:ClearPersonalBuildCode()
        build.codeBox:ClearFocus()
    end)

    build.profileHint = build:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    build.profileHint:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -227)
    build.profileHint:SetWidth(745)
    build.profileHint:SetHeight(46)
    build.profileHint:SetJustifyH("LEFT")
    build.profileHint:SetJustifyV("TOP")

    build.loadoutHeading = build:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    build.loadoutHeading:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -284)
    build.loadoutHeading:SetText(T("Talent loadout"))
    build.loadoutHeading:SetTextColor(0.50, 0.86, 1)

    build.loadoutLabel = build:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    build.loadoutLabel:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -311)
    build.loadoutLabel:SetText(T("Mapped") .. ":")

    build.loadoutStatus = build:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    build.loadoutStatus:SetPoint("TOPLEFT", build, "TOPLEFT", 78, -311)
    build.loadoutStatus:SetWidth(290)
    build.loadoutStatus:SetJustifyH("LEFT")

    build.saveLoadoutButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.saveLoadoutButton:SetSize(170, 27)
    build.saveLoadoutButton:SetPoint("TOPLEFT", build, "TOPLEFT", 380, -304)
    build.saveLoadoutButton:SetText(T("Choose loadout..."))
    build.saveLoadoutButton:SetScript("OnClick", function() addon:OpenLoadoutPicker() end)

    build.clearLoadoutButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.clearLoadoutButton:SetSize(100, 27)
    build.clearLoadoutButton:SetPoint("LEFT", build.saveLoadoutButton, "RIGHT", 8, 0)
    build.clearLoadoutButton:SetText(T("Clear"))
    build.clearLoadoutButton:SetScript("OnClick", function() addon:ClearCurrentLoadoutBinding() end)

    build.equipmentHeading = build:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    build.equipmentHeading:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -358)
    build.equipmentHeading:SetText(T("Equipment set"))
    build.equipmentHeading:SetTextColor(0.50, 0.86, 1)

    build.equipmentLabel = build:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    build.equipmentLabel:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -385)
    build.equipmentLabel:SetText(T("Mapped") .. ":")

    build.equipmentStatus = build:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    build.equipmentStatus:SetPoint("TOPLEFT", build, "TOPLEFT", 78, -385)
    build.equipmentStatus:SetWidth(290)
    build.equipmentStatus:SetJustifyH("LEFT")

    build.saveEquipmentButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.saveEquipmentButton:SetSize(170, 27)
    build.saveEquipmentButton:SetPoint("TOPLEFT", build, "TOPLEFT", 380, -378)
    build.saveEquipmentButton:SetText(T("Choose gear set..."))
    build.saveEquipmentButton:SetScript("OnClick", function() addon:OpenEquipmentPicker() end)

    build.clearEquipmentButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.clearEquipmentButton:SetSize(100, 27)
    build.clearEquipmentButton:SetPoint("LEFT", build.saveEquipmentButton, "RIGHT", 8, 0)
    build.clearEquipmentButton:SetText(T("Clear"))
    build.clearEquipmentButton:SetScript("OnClick", function() addon:ClearCurrentEquipmentBinding() end)

    build.autoHint = build:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    build.autoHint:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -438)
    build.autoHint:SetWidth(535)
    build.autoHint:SetHeight(58)
    build.autoHint:SetJustifyH("LEFT")
    build.autoHint:SetJustifyV("TOP")

    build.dungeonOverridesButton = CreateFrame("Button", nil, build, "UIPanelButtonTemplate")
    build.dungeonOverridesButton:SetSize(195, 28)
    build.dungeonOverridesButton:SetPoint("BOTTOMRIGHT", build, "BOTTOMRIGHT", -12, 15)
    build.dungeonOverridesButton:SetText(T("Dungeon overrides..."))
    build.dungeonOverridesButton:SetScript("OnClick", function() addon:OpenDungeonOverrides() end)

    -- GUIDE TAB ------------------------------------------------------------
    guidePage.scope = guidePage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    guidePage.scope:SetPoint("TOPLEFT", guidePage, "TOPLEFT", 12, -10)
    guidePage.scope:SetWidth(760)
    guidePage.scope:SetJustifyH("LEFT")
    guidePage.scope:SetText(T("This guide follows your current Death Knight specialization only. It is not tied to the World/Delve/Dungeon/Raid/PvP loadout profile."))
    guidePage.scope:SetTextColor(0.55, 0.84, 0.95)

    frame.guideSection = CreateSection(guidePage, T("Specialization guide"), -42, 535)
    local guide = frame.guideSection

    guide.specTitle = guide:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    guide.specTitle:SetPoint("TOPLEFT", guide, "TOPLEFT", 14, -31)
    guide.specTitle:SetWidth(720)
    guide.specTitle:SetJustifyH("LEFT")
    guide.specTitle:SetTextColor(0.60, 0.88, 1)

    guide.scroll = CreateFrame("ScrollFrame", nil, guide, "UIPanelScrollFrameTemplate")
    guide.scroll:SetPoint("TOPLEFT", guide, "TOPLEFT", 12, -62)
    guide.scroll:SetPoint("BOTTOMRIGHT", guide, "BOTTOMRIGHT", -31, 18)

    guide.content = CreateFrame("Frame", nil, guide.scroll)
    guide.content:SetSize(715, 1)
    guide.scroll:SetScrollChild(guide.content)

    guide.text = guide.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    guide.text:SetPoint("TOPLEFT", guide.content, "TOPLEFT", 2, 0)
    guide.text:SetWidth(700)
    guide.text:SetJustifyH("LEFT")
    guide.text:SetJustifyV("TOP")

    -- SETTINGS TAB ---------------------------------------------------------
    settingsPage.scope = settingsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    settingsPage.scope:SetPoint("TOPLEFT", settingsPage, "TOPLEFT", 12, -8)
    settingsPage.scope:SetWidth(500)
    settingsPage.scope:SetJustifyH("LEFT")
    settingsPage.scope:SetText(T("Global addon settings. These options apply across all Death Knight specializations and content profiles."))
    settingsPage.scope:SetTextColor(0.55, 0.84, 0.95)

    frame.languageButton = CreateFrame("Button", nil, settingsPage, "UIPanelButtonTemplate")
    frame.languageButton:SetSize(235, 27)
    frame.languageButton:SetPoint("TOPRIGHT", settingsPage, "TOPRIGHT", -12, -2)
    frame.languageButton:SetScript("OnClick", function() addon:ToggleLanguagePicker() end)
    local languageFont = frame.languageButton.GetFontString and frame.languageButton:GetFontString()
    if languageFont and GameFontNormalSmall then languageFont:SetFontObject(GameFontNormalSmall) end

    frame.hudSection = CreateSection(settingsPage, T("HUDs and layout"), -38, 315)
    local hud = frame.hudSection

    hud.description = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hud.description:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -31)
    hud.description:SetWidth(390)
    hud.description:SetHeight(34)
    hud.description:SetJustifyH("LEFT")
    hud.description:SetJustifyV("TOP")
    hud.description:SetText(T("Choose which combat HUDs are visible. Unlock them only while arranging the interface, then lock them again to prevent accidental dragging."))

    hud.combatOnlyButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.combatOnlyButton:SetSize(330, 27)
    hud.combatOnlyButton:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -12, -31)
    hud.combatOnlyButton:SetScript("OnClick", function() addon:SetCombatBarsOnlyInCombat(not DB.combatBarsOnlyInCombat) end)
    local combatOnlyFont = hud.combatOnlyButton.GetFontString and hud.combatOnlyButton:GetFontString()
    if combatOnlyFont and GameFontNormalSmall then
        combatOnlyFont:SetFontObject(GameFontNormalSmall)
    end

    local function AddHudRow(y, description)
        local text = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", hud, "TOPLEFT", 205, y)
        text:SetWidth(540)
        text:SetHeight(24)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("MIDDLE")
        text:SetText(description)
        return text
    end

    hud.buildButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.buildButton:SetSize(180, 24)
    hud.buildButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -72)
    hud.buildButton:SetScript("OnClick", function() addon:SetStatusWidgetEnabled(not DB.statusWidget.enabled) end)
    AddHudRow(-68, T("Shows specialization, detected content, active build, and mapped gear."))
    build.hudButton = hud.buildButton

    hud.coachButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.coachButton:SetSize(180, 24)
    hud.coachButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -97)
    hud.coachButton:SetScript("OnClick", function() addon:SetCoachEnabled(not DB.coach.enabled) end)
    AddHudRow(-93, T("Shows defensive and recovery recommendations, including health-adaptive priorities."))

    hud.buffButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.buffButton:SetSize(180, 24)
    hud.buffButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -122)
    hud.buffButton:SetScript("OnClick", function() addon:SetBuffBarEnabled(not DB.buffBar.enabled) end)
    AddHudRow(-118, T("Shows important Death Knight buffs in a compact movable row."))

    hud.externalBuffButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.externalBuffButton:SetSize(180, 24)
    hud.externalBuffButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -147)
    hud.externalBuffButton:SetScript("OnClick", function() addon:SetExternalBuffBarEnabled(not DB.externalBuffBar.enabled) end)
    AddHudRow(-143, T("Shows helpful effects on you that were applied by other players or NPCs."))

    hud.debuffButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.debuffButton:SetSize(180, 24)
    hud.debuffButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -172)
    hud.debuffButton:SetScript("OnClick", function() addon:SetDebuffBarEnabled(not DB.debuffBar.enabled) end)
    AddHudRow(-168, T("Shows harmful effects currently affecting your character."))

    hud.abilityButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.abilityButton:SetSize(180, 24)
    hud.abilityButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -197)
    hud.abilityButton:SetScript("OnClick", function() addon:SetAbilityBarEnabled(not DB.abilityBar.enabled) end)
    AddHudRow(-193, T("Shows important abilities and whether they are ready, cooling down, or temporarily unusable."))

    hud.resourceButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.resourceButton:SetSize(180, 24)
    hud.resourceButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -222)
    hud.resourceButton:SetScript("OnClick", function() addon:SetResourceHUDEnabled(not DB.resourceHUD.enabled) end)
    hud.resourceDescription = AddHudRow(-218, T("Shows all six Runes plus Runic Power in a compact movable Death Knight resource HUD."))

    hud.interruptButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.interruptButton:SetSize(180, 24)
    hud.interruptButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -247)
    hud.interruptButton:SetScript("OnClick", function() addon:SetInterruptAlertEnabled(not DB.interruptAlert.enabled) end)
    AddHudRow(-243, T("Shows the Mind Freeze icon only when your current target has a confirmed interruptible cast or channel."))

    -- Keep the layout controls on one clean row even with localized labels.
    hud.lockButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.lockButton:SetSize(170, 27)
    hud.lockButton:SetPoint("BOTTOMLEFT", hud, "BOTTOMLEFT", 12, 12)
    hud.lockButton:SetScript("OnClick", function() addon:ToggleHUDLock() end)

    hud.previewButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.previewButton:SetSize(180, 27)
    hud.previewButton:SetPoint("LEFT", hud.lockButton, "RIGHT", 8, 0)
    hud.previewButton:SetScript("OnClick", function() addon:ToggleHUDPreview() end)

    hud.barLayoutButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.barLayoutButton:SetSize(180, 27)
    hud.barLayoutButton:SetPoint("LEFT", hud.previewButton, "RIGHT", 8, 0)
    hud.barLayoutButton:SetText(T("HUD appearance..."))
    hud.barLayoutButton:SetScript("OnClick", function() addon:ToggleBarLayoutFrame() end)

    hud.resetButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.resetButton:SetSize(200, 27)
    hud.resetButton:SetPoint("LEFT", hud.barLayoutButton, "RIGHT", 8, 0)
    hud.resetButton:SetText(T("Reset HUD positions"))
    hud.resetButton:SetScript("OnClick", function() addon:ResetHUDPositions() end)

    for _, button in ipairs({ hud.lockButton, hud.previewButton, hud.barLayoutButton, hud.resetButton }) do
        local fontString = button.GetFontString and button:GetFontString()
        if fontString and GameFontNormalSmall then
            fontString:SetFontObject(GameFontNormalSmall)
        end
    end

    frame.automationSection = CreateSection(settingsPage, T("Automatic switching"), -363, 100)
    local automation = frame.automationSection
    automation.description = automation:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    automation.description:SetPoint("TOPLEFT", automation, "TOPLEFT", 12, -30)
    -- Reserve enough horizontal room for localized AUTO buttons.
    automation.description:SetWidth(215)
    automation.description:SetHeight(54)
    automation.description:SetJustifyH("LEFT")
    automation.description:SetJustifyV("TOP")
    automation.description:SetText(T("Specialization, talent, and gear mappings are configured per content profile in the Loadouts tab. These switches are global."))

    build.autoSpecButton = CreateFrame("Button", nil, automation, "UIPanelButtonTemplate")
    build.autoSpecButton:SetSize(165, 28)
    build.autoSpecButton:SetPoint("TOPLEFT", automation, "TOPLEFT", 235, -37)
    build.autoSpecButton:SetScript("OnClick", function() addon:ToggleAutoSwitchSpecialization() end)

    build.autoSwitchButton = CreateFrame("Button", nil, automation, "UIPanelButtonTemplate")
    build.autoSwitchButton:SetSize(165, 28)
    build.autoSwitchButton:SetPoint("LEFT", build.autoSpecButton, "RIGHT", 8, 0)
    build.autoSwitchButton:SetScript("OnClick", function() addon:ToggleAutoSwitchLoadouts() end)

    build.autoEquipmentButton = CreateFrame("Button", nil, automation, "UIPanelButtonTemplate")
    build.autoEquipmentButton:SetSize(175, 28)
    build.autoEquipmentButton:SetPoint("LEFT", build.autoSwitchButton, "RIGHT", 8, 0)
    build.autoEquipmentButton:SetScript("OnClick", function() addon:ToggleAutoSwitchEquipment() end)

    for _, button in ipairs({ build.autoSpecButton, build.autoSwitchButton, build.autoEquipmentButton }) do
        local fontString = button.GetFontString and button:GetFontString()
        if fontString and GameFontNormalSmall then
            fontString:SetFontObject(GameFontNormalSmall)
        end
    end

    frame.voiceSection = CreateSection(settingsPage, T("Lich King commentary"), -468, 150)
    local voice = frame.voiceSection

    voice.status = voice:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    voice.status:SetPoint("TOPLEFT", voice, "TOPLEFT", 12, -31)
    voice.status:SetWidth(525)
    voice.status:SetHeight(55)
    voice.status:SetJustifyH("LEFT")
    voice.status:SetJustifyV("TOP")

    voice.toggleButton = CreateFrame("Button", nil, voice, "UIPanelButtonTemplate")
    voice.toggleButton:SetSize(190, 27)
    voice.toggleButton:SetPoint("TOPRIGHT", voice, "TOPRIGHT", -12, -30)
    voice.toggleButton:SetScript("OnClick", function() addon:ToggleVoice() end)

    voice.situationalButton = CreateFrame("Button", nil, voice, "UIPanelButtonTemplate")
    voice.situationalButton:SetSize(150, 27)
    voice.situationalButton:SetPoint("TOPLEFT", voice, "TOPLEFT", 12, -88)
    voice.situationalButton:SetScript("OnClick", function()
        DB.voice.situational = not DB.voice.situational
        addon:UpdateVoiceSection()
        Print(T(DB.voice.situational and "Situational Lich King comments enabled." or "Situational Lich King comments disabled."))
    end)

    voice.mapButton = CreateFrame("Button", nil, voice, "UIPanelButtonTemplate")
    voice.mapButton:SetSize(150, 27)
    voice.mapButton:SetPoint("LEFT", voice.situationalButton, "RIGHT", 8, 0)
    voice.mapButton:SetText(T("Voice mapping..."))
    voice.mapButton:SetScript("OnClick", function() addon:ToggleVoiceConfigFrame() end)

    voice.previewButton = CreateFrame("Button", nil, voice, "UIPanelButtonTemplate")
    voice.previewButton:SetSize(140, 27)
    voice.previewButton:SetPoint("LEFT", voice.mapButton, "RIGHT", 8, 0)
    voice.previewButton:SetText(T("Preview voice"))
    voice.previewButton:SetScript("OnClick", function() addon:PreviewVoice() end)

    voice.frequencyButton = CreateFrame("Button", nil, voice, "UIPanelButtonTemplate")
    voice.frequencyButton:SetSize(170, 27)
    voice.frequencyButton:SetPoint("LEFT", voice.previewButton, "RIGHT", 8, 0)
    voice.frequencyButton:SetScript("OnClick", function() addon:CycleVoiceFrequency() end)

    frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 22)
    frame.footer:SetWidth(790)
    frame.footer:SetJustifyH("LEFT")
    frame.footer:SetText(T(
        "Data %s • Patch %s • /dkm help • Guidance only; no ability is used automatically.",
        Data.dataVersion or "?",
        Data.patch or "?"
    ))

    frame:Hide()
    RestoreFramePosition(frame, "main")
    if UISpecialFrames then table.insert(UISpecialFrames, frame:GetName()) end
    return frame
end

function addon:SetMainTab(tabKey)
    if not mainFrame or not mainFrame.pages then
        return
    end

    if not mainFrame.pages[tabKey] then
        tabKey = "combat"
    end
    if DB then
        DB.mainTab = tabKey
    end

    for key, page in pairs(mainFrame.pages) do
        if key == tabKey then page:Show() else page:Hide() end
    end

    for key, button in pairs(tabButtons) do
        StyleTabButton(button, key == tabKey)
    end

    if tabKey == "guide" then
        self:UpdateGuideSection()
    elseif tabKey == "settings" then
        self:UpdateHUDSettings()
        self:UpdateVoiceSection()
    elseif tabKey == "builds" then
        self:UpdateBuildSection()
    end
end

local function CreateCoachFrame()
    local frame = CreateFrame("Frame", "DKMentorCoachFrame", UIParent, "BackdropTemplate")
    frame:SetSize(480, 138)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    ApplyBackdrop(frame, 0.94)

    local function StartCoachDrag(self)
        local owner = self.owner or self
        if addon:CanMoveHUDs() then owner:StartMoving() end
    end

    local function StopCoachDrag(self)
        local owner = self.owner or self
        owner:StopMovingOrSizing()
        if DB and DB.hudLocked == false then SaveFramePosition(owner, "coach") end
    end

    frame.dragBar = CreateFrame("Frame", nil, frame)
    frame.dragBar.owner = frame
    frame.dragBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    frame.dragBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -32, -4)
    frame.dragBar:SetHeight(27)
    frame.dragBar:EnableMouse(true)
    frame.dragBar:RegisterForDrag("LeftButton")
    frame.dragBar:SetScript("OnDragStart", StartCoachDrag)
    frame.dragBar:SetScript("OnDragStop", StopCoachDrag)

    frame:SetScript("OnShow", function()
        addon:UpdateCoach()
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -9)
    frame.title:SetTextColor(0.48, 0.87, 1)

    frame.dragHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.dragHint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -38, -10)
    frame.dragHint:SetText(T("Drag to move"))

    frame.healthText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.healthText:SetPoint("TOP", frame, "TOP", 0, -10)
    frame.healthText:SetText("")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetSize(25, 25)
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    frame.closeButton:SetScript("OnClick", function()
        addon:SetCoachEnabled(false)
    end)

    for index = 1, 3 do
        local card = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        card:SetSize(148, 96)
        card:SetPoint("TOPLEFT", frame, "TOPLEFT", 8 + ((index - 1) * 157), -34)
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 9,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        card:SetBackdropColor(0.025, 0.08, 0.11, 0.82)
        card:SetBackdropBorderColor(0.16, 0.47, 0.62, 0.85)
        card:EnableMouse(true)
        card.owner = frame
        card:RegisterForDrag("LeftButton")
        card:SetScript("OnDragStart", StartCoachDrag)
        card:SetScript("OnDragStop", StopCoachDrag)

        card.icon = card:CreateTexture(nil, "ARTWORK")
        card.icon:SetSize(36, 36)
        card.icon:SetPoint("TOPLEFT", card, "TOPLEFT", 7, -8)
        card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        card.action = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.action:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 6, -1)
        card.action:SetWidth(91)
        card.action:SetJustifyH("LEFT")
        card.action:SetTextColor(0.46, 0.86, 1)

        card.spell = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.spell:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 6, -18)
        card.spell:SetWidth(91)
        card.spell:SetHeight(28)
        card.spell:SetJustifyH("LEFT")
        card.spell:SetJustifyV("TOP")

        card.when = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.when:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 7, 8)
        card.when:SetWidth(134)
        card.when:SetJustifyH("LEFT")

        card:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.07, 0.19, 0.25, 0.92)
            if GameTooltip and (self.spellID or self.auraIndex) then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                local shown = false
                if self.auraIndex and self.auraFilter and GameTooltip.SetUnitAura then
                    local ok = pcall(GameTooltip.SetUnitAura, GameTooltip, "player", self.auraIndex, self.auraFilter)
                    shown = ok
                end
                if not shown and self.spellID and GameTooltip.SetSpellByID then
                    local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, self.spellID)
                    shown = ok
                end
                if not shown then
                    GameTooltip:SetText(self.spellName or T("Aura"))
                end
                GameTooltip:Show()
            end
        end)
        card:SetScript("OnLeave", function(self)
            if GameTooltip then
                GameTooltip:Hide()
            end
            addon:UpdateCoach()
        end)

        coachCards[index] = card
    end

    frame:Hide()
    RestoreFramePosition(frame, "coach")
    return frame
end

local function CreateSpecializationPickerFrame(parent)
    local frame = CreateFrame("Frame", "DKMentorSpecializationPicker", UIParent, "BackdropTemplate")
    frame:SetSize(190, 118)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.025, 0.055, 0.075, 0.98)
    frame:SetBackdropBorderColor(0.25, 0.70, 0.90, 0.95)
    frame:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, -4)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)
    frame.title:SetText(T("Change specialization"))
    frame.title:SetTextColor(0.55, 0.88, 1.0)

    frame.rows = {}
    for index = 1, 3 do
        local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
        row:SetSize(170, 27)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -27 - ((index - 1) * 28))
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        row:SetBackdropColor(0.035, 0.09, 0.12, 0.92)
        row:SetBackdropBorderColor(0.12, 0.34, 0.42, 0.9)
        row.specIndex = index

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(21, 21)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 7, 0)
        row.name:SetWidth(96)
        row.name:SetJustifyH("LEFT")

        row.state = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.state:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.state:SetWidth(42)
        row.state:SetJustifyH("RIGHT")

        row:SetScript("OnEnter", function(self)
            if self.specIndex ~= select(4, addon:GetSpecInfo()) then
                self:SetBackdropColor(0.055, 0.18, 0.23, 0.98)
                self:SetBackdropBorderColor(0.30, 0.72, 0.88, 1)
            end
        end)
        row:SetScript("OnLeave", function() addon:UpdateSpecializationPicker() end)
        row:SetScript("OnClick", function(self) addon:SwitchSpecialization(self.specIndex) end)
        frame.rows[index] = row
    end

    frame:Hide()
    return frame
end

function addon:UpdateSpecializationPicker()
    if not specializationPickerFrame then return end
    local currentIndex = select(4, self:GetSpecInfo())
    for index, row in ipairs(specializationPickerFrame.rows or {}) do
        local _, name, icon = self:GetSpecializationInfoByIndex(index)
        row.icon:SetTexture(icon or QUESTION_MARK_ICON)
        row.name:SetText(name or T("Unknown"))
        if currentIndex == index then
            row.state:SetText(T("CURRENT"))
            row.state:SetTextColor(0.45, 1.0, 0.65)
            row:SetBackdropColor(0.045, 0.18, 0.13, 0.98)
            row:SetBackdropBorderColor(0.30, 0.78, 0.50, 1)
        else
            row.state:SetText("")
            row:SetBackdropColor(0.035, 0.09, 0.12, 0.92)
            row:SetBackdropBorderColor(0.12, 0.34, 0.42, 0.9)
        end
    end
end

function addon:ToggleSpecializationPicker()
    if not specializationPickerFrame then return end
    if InCombatLockdown and InCombatLockdown() then
        specializationPickerFrame:Hide()
        Print(T("You cannot change specialization during combat."))
        return
    end

    if specializationPickerFrame:IsShown() then
        specializationPickerFrame:Hide()
    else
        self:UpdateSpecializationPicker()
        specializationPickerFrame:ClearAllPoints()
        specializationPickerFrame:SetPoint("TOPLEFT", statusWidget, "BOTTOMLEFT", 0, -4)
        specializationPickerFrame:Show()
    end
end

local function CreateStatusWidget()
    local frame = CreateFrame("Frame", "DKMentorStatusWidget", UIParent, "BackdropTemplate")
    frame:SetSize(500, 42)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.90)

    frame:SetScript("OnDragStart", function(self)
        if addon:CanMoveHUDs() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if DB and DB.hudLocked == false then SaveFramePosition(self, "statusWidget") end
    end)
    frame:SetScript("OnMouseUp", function(_, mouseButton)
        if mouseButton == "RightButton" then
            addon:ToggleMainFrame()
        end
    end)

    -- The specialization icon doubles as the specialization picker button.
    -- This keeps the compact one-line HUD while preserving manual spec switching.
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(32, 32)
    frame.icon:SetPoint("LEFT", frame, "LEFT", 6, 0)
    frame.icon:SetTexture(QUESTION_MARK_ICON)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.specButton = CreateFrame("Button", nil, frame)
    frame.specButton:SetAllPoints(frame.icon)
    frame.specButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame.specButton:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            addon:ToggleMainFrame()
        else
            addon:ToggleSpecializationPicker()
        end
    end)
    frame.specButton:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(T("Change specialization"))
            GameTooltip:AddLine(T("Click to choose Blood, Frost, or Unholy manually. Automatic specialization switching can be configured in Loadouts."), 1, 1, 1, true)
            GameTooltip:AddLine(T("Right-click: open or close DK Mentor"), 0.72, 0.86, 1.0, true)
            GameTooltip:Show()
        end
    end)
    frame.specButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.title:SetPoint("LEFT", frame.icon, "RIGHT", 10, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetTextColor(0.48, 0.87, 1)
    frame.title:SetWordWrap(false)

    frame.build = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.build:SetPoint("LEFT", frame.title, "RIGHT", 18, 0)
    frame.build:SetJustifyH("LEFT")
    frame.build:SetWordWrap(false)

    frame.gear = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.gear:SetPoint("LEFT", frame.build, "RIGHT", 18, 0)
    frame.gear:SetJustifyH("LEFT")
    frame.gear:SetWordWrap(false)

    frame.ready = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.ready:SetPoint("LEFT", frame.gear, "RIGHT", 18, 0)
    frame.ready:SetJustifyH("LEFT")
    frame.ready:SetWordWrap(false)

    -- Kept for compatibility with existing update paths, but hidden in compact mode.
    frame.auto = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.auto:Hide()

    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(T("DK Mentor Build HUD"))
        GameTooltip:AddLine(T("Shows your Death Knight specialization, detected content, active WoW talent loadout, and associated equipment set."), 1, 1, 1, true)

        local status = addon:GetReadyCheckStatus()
        local context = addon:DetectActualContext()
        local contextLabel = (Data.contextNames and Data.contextNames[context]) or context
        local currentSpecID, currentSpecName = addon:GetSpecInfo()
        local targetSpecID = select(1, addon:ResolveRuntimeSpecializationTarget(context))
        local assignedRole = addon:GetAssignedGroupRole()
        local currentRole = addon:GetSpecializationRoleByIDSafe(currentSpecID)
        local lootSpecID = addon:GetLootSpecializationID()
        local activeOverride, _, dungeonIdentity = addon:GetActiveDungeonOverride()
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(T("Loadout status"), 0.45, 0.85, 1)
        GameTooltip:AddLine(T("Content: %s", tostring(contextLabel)), 1, 1, 1)
        if dungeonIdentity and dungeonIdentity.name then GameTooltip:AddLine(T("Dungeon: %s", tostring(dungeonIdentity.name)), 1, 1, 1) end
        GameTooltip:AddLine(T("Current specialization: %s (%s)", tostring(currentSpecName or currentSpecID), addon:GetRoleDisplayName(currentRole)), 1, 1, 1)
        if targetSpecID then GameTooltip:AddLine(T("Target specialization: %s", tostring((Data.specNames and Data.specNames[targetSpecID]) or targetSpecID)), 1, 1, 1) end
        if assignedRole then GameTooltip:AddLine(T("Assigned group role: %s", addon:GetRoleDisplayName(assignedRole)), 1, 1, 1) end
        GameTooltip:AddLine(T("Loot specialization: %s", addon:GetLootSpecDisplayName(lootSpecID)), 1, 1, 1)
        if activeOverride then GameTooltip:AddLine(T("Dungeon override: ACTIVE"), 0.45, 1.0, 0.65) end
        if lootSpecState.pendingID ~= nil or lootSpecState.lastError then GameTooltip:AddLine(tostring(lootSpecState.lastError or T("Applying loot specialization...")), 1.0, 0.82, 0.35, true) end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(T("DK Ready Check"), 0.45, 0.85, 1)
        if status.targetSpecID then
            GameTooltip:AddLine((status.specReady and "|cff66ff99" or "|cffffcc55") .. T("Specialization") .. ":|r " .. tostring(status.specDetail or "-"), 1, 1, 1, true)
        end
        GameTooltip:AddLine((status.talentReady and "|cff66ff99" or "|cffffcc55") .. T("Talents") .. ":|r " .. tostring(status.talentDetail or "-"), 1, 1, 1, true)
        GameTooltip:AddLine((status.gearReady and "|cff66ff99" or "|cffffcc55") .. T("Gear") .. ":|r " .. tostring(status.gearDetail or "-"), 1, 1, 1, true)
        GameTooltip:AddLine((status.runeforge and status.runeforge.ready and "|cff66ff99" or "|cffff7777") .. T("Runeforge") .. ":|r " .. tostring(status.runeforge and status.runeforge.detail or "-"), 1, 1, 1, true)
        if status.ghoul and status.ghoul.required then
            GameTooltip:AddLine((status.ghoul.ready and "|cff66ff99" or "|cffff7777") .. T("Ghoul") .. ":|r " .. tostring(status.ghoul.detail or "-"), 1, 1, 1, true)
        end
        GameTooltip:AddLine(T("Runeforge Guard checks for a Death Knight Runeforge on each equipped weapon; it does not claim that one rune is always the best for every build."), 0.72, 0.78, 0.84, true)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(DB and DB.hudLocked and T("HUDs are locked. Unlock them in Settings to move this panel.") or T("Drag to move. Toggle it from Settings or with /dkm hud."), 0.65, 0.8, 0.9, true)
        GameTooltip:AddLine(T("Right-click: open or close DK Mentor"), 0.72, 0.86, 1.0, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    RestoreFramePosition(frame, "statusWidget")
    frame:Hide()
    return frame
end

local function LayoutStatusWidget()
    if not statusWidget then
        return
    end

    -- Compact LoadoutPilot-style line: spec icon | context | build | gear | ready.
    local regions = { statusWidget.title, statusWidget.build, statusWidget.gear, statusWidget.ready }
    local widths = {}
    local textTotal = 0
    for index, region in ipairs(regions) do
        local width = 0
        if region and region.GetStringWidth then
            width = math.ceil(region:GetStringWidth() or 0)
        end
        width = math.max(width, 24)
        widths[index] = width
        textTotal = textTotal + width
    end

    local leftInset = 6 + 32 + 10
    local gaps = 18 * (#regions - 1)
    local rightInset = 10
    local desiredWidth = math.max(360, math.min(760, leftInset + textTotal + gaps + rightInset))
    statusWidget:SetSize(desiredWidth, 42)

    -- Give every segment exactly the width it needs so labels stay on one line.
    statusWidget.title:SetWidth(widths[1])
    statusWidget.build:SetWidth(widths[2])
    statusWidget.gear:SetWidth(widths[3])
    statusWidget.ready:SetWidth(widths[4])
    statusWidget.auto:SetWidth(1)
end

local function GetConfiguredBarColumns(dbKey, fallback, maximum)
    local config = DB and DB[dbKey]
    local value = config and tonumber(config.iconsPerRow) or tonumber(fallback) or 5
    value = math.floor(value + 0.5)
    return Clamp(value, 3, maximum or 12)
end

local function LayoutTrackingSlots(frame, slotStore, columns, anchorFromBottom)
    if not frame or not slotStore then return end
    columns = math.max(1, math.floor(tonumber(columns) or frame.slotsPerRow or #slotStore))
    frame.slotsPerRow = columns

    for index, slot in ipairs(slotStore) do
        slot:ClearAllPoints()
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        if anchorFromBottom then
            slot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 7 + (column * 38), 18 + (row * 38))
        else
            slot:SetPoint("TOPLEFT", frame, "TOPLEFT", 7 + (column * 38), -16 - (row * 38))
        end
    end
end

local function CreateTrackingBar(frameName, dbKey, title, slotStore, maxSlots, updateInterval, slotsPerRow)
    local frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(330, 54)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame.dbKey = dbKey
    frame.slotsPerRow = GetConfiguredBarColumns(dbKey, slotsPerRow or maxSlots, maxSlots)
    frame.updateElapsed = 0
    frame.updateInterval = tonumber(updateInterval) or 0.12
    ApplyBackdrop(frame, 0.82)

    frame:SetScript("OnDragStart", function(self)
        if addon:CanMoveHUDs() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if DB and DB.hudLocked == false then SaveFramePosition(self, self.dbKey) end
    end)

    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.label:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -4)
    frame.label:SetText(title)
    frame.label:SetTextColor(0.55, 0.82, 0.95)

    frame.dragHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.dragHint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -7, -4)
    frame.dragHint:SetText(T("Drag to move"))
    frame.dragHint:SetTextColor(0.42, 0.55, 0.62)

    for index = 1, maxSlots do
        local slot = CreateFrame("Button", nil, frame, "BackdropTemplate")
        slot:SetSize(34, 34)
        local column = (index - 1) % frame.slotsPerRow
        local row = math.floor((index - 1) / frame.slotsPerRow)
        slot:SetPoint("TOPLEFT", frame, "TOPLEFT", 7 + (column * 38), -16 - (row * 38))
        slot:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        slot:SetBackdropColor(0.02, 0.04, 0.06, 0.85)
        slot:SetBackdropBorderColor(0.18, 0.45, 0.58, 0.8)

        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
        slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon:SetTexture(QUESTION_MARK_ICON)

        -- A native Cooldown widget is used instead of Lua-side countdown math.
        -- On Midnight, cooldown timing can become a secret value in combat;
        -- DurationObjects can still be rendered by the widget safely.
        slot.cooldown = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
        slot.cooldown:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
        slot.cooldown:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
        if slot.cooldown.SetDrawEdge then slot.cooldown:SetDrawEdge(false) end
        if slot.cooldown.SetDrawBling then slot.cooldown:SetDrawBling(false) end
        if slot.cooldown.SetHideCountdownNumbers then slot.cooldown:SetHideCountdownNumbers(false) end
        if slot.cooldown.SetCountdownFormatter and SecondsFormatter then
            pcall(slot.cooldown.SetCountdownFormatter, slot.cooldown, SecondsFormatter)
            if slot.cooldown.SetCountdownMillisecondsThreshold then
                pcall(slot.cooldown.SetCountdownMillisecondsThreshold, slot.cooldown, 10)
            end
        end

        slot.timer = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.timer:SetPoint("BOTTOM", slot, "BOTTOM", 0, 2)
        slot.timer:SetText("")
        slot.timer:SetShadowOffset(1, -1)

        slot.count = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        slot.count:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -2, -2)
        slot.count:SetText("")
        slot.count:SetShadowOffset(1, -1)

        slot:SetScript("OnEnter", function(self)
            if self.spellID and GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                if GameTooltip.SetSpellByID then
                    GameTooltip:SetSpellByID(self.spellID)
                else
                    GameTooltip:SetText(self.spellName or T("Ability"))
                end
                GameTooltip:Show()
            end
        end)
        slot:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)

        slotStore[index] = slot
    end

    frame:SetScript("OnUpdate", function(self, elapsed)
        self.updateElapsed = self.updateElapsed + (tonumber(elapsed) or 0)
        if self.updateElapsed < self.updateInterval then
            return
        end
        self.updateElapsed = 0
        if self.dbKey == "buffBar" then
            addon:UpdateBuffBar()
        elseif self.dbKey == "externalBuffBar" then
            addon:UpdateExternalBuffBar()
        elseif self.dbKey == "debuffBar" then
            addon:UpdateDebuffBar()
        else
            addon:UpdateAbilityBar()
        end
    end)

    RestoreFramePosition(frame, dbKey)
    frame:Hide()
    return frame
end

local CreateBuffBar

-- Midnight 12.1 makes player aura identity/timing secret during restricted combat.
-- The sanctioned way to keep custom aura HUDs live is AuraContainer: Blizzard owns
-- the aura assignment and updates AuraButtons without exposing secret aura data to Lua.
local function StyleManagedAuraButton(button, harmful)
    if not button then return end

    pcall(button.SetSize, button, 34, 34)

    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints(button)
    if harmful then
        border:SetColorTexture(0.82, 0.20, 0.20, 0.95)
    else
        border:SetColorTexture(0.20, 0.62, 0.82, 0.95)
    end

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if button.SetIcon then
        pcall(button.SetIcon, button, icon)
    end

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(false) end
    if button.SetDurationCooldown then
        pcall(button.SetDurationCooldown, button, cooldown)
    end

    local textLayer = CreateFrame("Frame", nil, button)
    textLayer:SetAllPoints(button)
    textLayer:EnableMouse(false)

    local count = textLayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    count:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    count:SetShadowOffset(1, -1)
    if button.SetApplicationCount then
        pcall(button.SetApplicationCount, button, count, {})
    end
end

local function UpdateManagedAuraBarChrome(frame)
    if not frame or not frame.managedAuraContainer then return end
    local editing = (DB and DB.hudLocked == false) or addon.hudPreviewMode == true

    -- HUD lock is interaction-only. Locking a bar must never change whether the
    -- player can see it in combat; it only disables dragging/click interception.
    -- Keep managed-aura bars visually consistent with the Abilities bar.
    if frame.label then frame.label:SetShown(true) end
    if frame.dragHint then
        frame.dragHint:SetShown(editing)
        if editing then frame.dragHint:SetText(T("Drag to move")) end
    end

    frame:EnableMouse(editing)
    frame:SetBackdropColor(0.02, 0.04, 0.06, 0.82)
    frame:SetBackdropBorderColor(0.16, 0.47, 0.62, 0.85)
end

local MANAGED_AURA_ICON_SIZE = 34
local MANAGED_AURA_SPACING = 4
local MANAGED_AURAS_PER_LINE = 5
local MANAGED_AURA_MAX_FRAMES = 30

local function GetManagedAuraLineSize(perLine)
    perLine = math.max(1, math.floor(tonumber(perLine) or MANAGED_AURAS_PER_LINE))
    return (perLine * (MANAGED_AURA_ICON_SIZE + MANAGED_AURA_SPACING)) + 1
end

local function ConfigureManagedAuraFlow(container, perLine)
    if not container then return end
    perLine = math.max(1, math.floor(tonumber(perLine) or MANAGED_AURAS_PER_LINE))
    local lineSize = GetManagedAuraLineSize(perLine)

    -- The default remains five icons per row, but the user can widen/narrow
    -- each aura HUD from Settings. Additional rows always grow UP so a HUD
    -- placed above the action bars never turns into an uncontrolled strip.
    if container.SetFlowLayoutMaximumLineSize then
        pcall(container.SetFlowLayoutMaximumLineSize, container, lineSize)
    elseif container.SetAuraLayoutRowWidth then
        pcall(container.SetAuraLayoutRowWidth, container, lineSize)
    end

    local anchorSetter = container.SetFlowLayoutAnchorPoint or container.SetAuraLayoutAnchorPoint
    if anchorSetter then
        pcall(anchorSetter, container, "BOTTOMLEFT")
    end

    local growthSetter = container.SetFlowLayoutGrowthDirection or container.SetAuraLayoutGrowthDirection
    local directions = AnchorUtil and AnchorUtil.FlowDirection
    if growthSetter and directions then
        pcall(growthSetter, container, directions.Right, directions.Up)
    end
end

local function CreateManagedAuraBar(frameName, dbKey, title, slotStore, filterString, harmful, candidateFilters)
    -- Build the legacy row first as a compatibility fallback. On Retail 12.1 the
    -- managed container path below takes over and these ordinary slots stay hidden.
    local frame = CreateTrackingBar(frameName, dbKey, title, slotStore, MANAGED_AURA_MAX_FRAMES, 0.25)
    local perLine = GetConfiguredBarColumns(dbKey, MANAGED_AURAS_PER_LINE, 10)
    local lineSize = GetManagedAuraLineSize(perLine)
    frame:SetSize(math.max(92, 14 + (perLine * 38)), 56)
    if frame.label then
        frame.label:ClearAllPoints()
        frame.label:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 7, 3)
    end
    if frame.dragHint then
        frame.dragHint:ClearAllPoints()
        frame.dragHint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -7, 3)
    end

    local okCreate, container = pcall(CreateFrame, "AuraContainer", nil, frame, "CustomAuraContainerTemplate")
    if not okCreate or not container or type(container.AddAuraGroup) ~= "function" then
        return frame
    end

    -- The bottom row remains at the saved HUD position; wrapped rows are placed
    -- above it by the AuraContainer flow engine.
    container:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 7, 18)
    container:SetSize(lineSize, MANAGED_AURA_ICON_SIZE)
    container:Show()
    ConfigureManagedAuraFlow(container, perLine)

    local options = {
        maxFrameCount = MANAGED_AURA_MAX_FRAMES,
        initializeFrame = function(button)
            StyleManagedAuraButton(button, harmful)
        end,
        candidateFilters = candidateFilters or {},
        layout = {
            elementWidth = MANAGED_AURA_ICON_SIZE,
            elementHeight = MANAGED_AURA_ICON_SIZE,
            elementSpacing = MANAGED_AURA_SPACING,
            lineSpacing = MANAGED_AURA_SPACING,
            maximumLineSize = lineSize,
        },
    }

    -- Retail 12.1 live order: SetUnit -> AddAuraGroup -> SetEnabled LAST.
    -- SetEnabled arms Blizzard's own aura-event processing; the addon never
    -- needs to inspect secret combat aura state to decide what is active.
    if container.SetUnit then
        pcall(container.SetUnit, container, "player")
    end

    -- IMPORTANT: the PLAYER filter is negatable and is evaluated inside the
    -- secure aura engine. HELPFUL|!PLAYER therefore means positive effects on
    -- the player that were not cast by the player/pet, even while aura identity
    -- is secret to addon Lua during combat.
    local okGroup = pcall(container.AddAuraGroup, container, dbKey, filterString, options)
    if not okGroup then
        container:Hide()
        return frame
    end

    -- Apply the flow settings again after the group exists; this is harmless on
    -- current Retail and also covers builds that dirty/rebuild the layout here.
    ConfigureManagedAuraFlow(container, perLine)
    if container.SetAuraGroupLayout then
        pcall(container.SetAuraGroupLayout, container, dbKey, options.layout)
    end
    if container.SetEnabled then
        pcall(container.SetEnabled, container, true)
    end
    if container.UpdateAllAuras then
        pcall(container.UpdateAllAuras, container)
    end

    frame.managedAuraContainer = container
    frame.managedAuraFilter = filterString
    frame.managedAuraGroupKey = dbKey
    frame.managedAuraCandidateFilters = options.candidateFilters
    frame.managedAuraHarmful = harmful == true
    frame.managedAuraTitle = title
    frame.slotsPerRow = perLine
    frame.managedAuraAppliedColumns = perLine
    frame:SetScript("OnUpdate", nil)
    for _, slot in ipairs(slotStore) do
        slot:Hide()
    end
    UpdateManagedAuraBarChrome(frame)
    return frame
end

local function ClearTrackingCooldown(slot)
    if slot and slot.cooldown and slot.cooldown.Clear then
        pcall(slot.cooldown.Clear, slot.cooldown)
    end
end

local function HideTrackingSlots(slotStore)
    for _, slot in ipairs(slotStore or {}) do
        slot.spellID = nil
        slot.spellName = nil
        if slot.timer then slot.timer:SetText("") end
        if slot.count then slot.count:SetText("") end
        ClearTrackingCooldown(slot)
        slot:Hide()
    end
end

local function ShowManagedAuraPreview(frame, slotStore)
    if not frame then return end
    local columns = GetConfiguredBarColumns(frame.dbKey, MANAGED_AURAS_PER_LINE, 10)
    frame.slotsPerRow = columns
    frame:SetSize(math.max(92, 14 + (columns * 38)), 56)
    LayoutTrackingSlots(frame, slotStore, columns, true)

    if frame.managedAuraContainer then
        frame.managedAuraContainer:Hide()
    end

    for index, slot in ipairs(slotStore or {}) do
        if index <= columns then
            slot.spellID = nil
            slot.spellName = frame.managedAuraTitle or T("Aura")
            slot.icon:SetTexture(QUESTION_MARK_ICON)
            if slot.icon.SetDesaturated then slot.icon:SetDesaturated(true) end
            slot.icon:SetAlpha(0.42)
            slot.timer:SetText("")
            slot.count:SetText("")
            ClearTrackingCooldown(slot)
            if frame.managedAuraHarmful then
                slot:SetBackdropBorderColor(0.70, 0.22, 0.20, 0.85)
            else
                slot:SetBackdropBorderColor(0.20, 0.58, 0.76, 0.85)
            end
            slot:Show()
        else
            slot:Hide()
        end
    end

    UpdateManagedAuraBarChrome(frame)
    frame:Show()
end

local function ApplyManagedAuraLayout(frame)
    if not frame or not frame.managedAuraContainer then return end
    local lockdown = false
    if InCombatLockdown then
        local ok, rawValue = pcall(InCombatLockdown)
        lockdown = GetAccessibleBooleanFromCall(ok, rawValue) == true
    end
    if lockdown then
        frame.managedAuraLayoutPending = true
        return
    end

    local columns = GetConfiguredBarColumns(frame.dbKey, MANAGED_AURAS_PER_LINE, 10)
    local lineSize = GetManagedAuraLineSize(columns)
    frame.slotsPerRow = columns
    frame:SetSize(math.max(92, 14 + (columns * 38)), 56)
    frame.managedAuraContainer:SetSize(lineSize, MANAGED_AURA_ICON_SIZE)
    ConfigureManagedAuraFlow(frame.managedAuraContainer, columns)
    if frame.managedAuraContainer.SetAuraGroupLayout then
        pcall(frame.managedAuraContainer.SetAuraGroupLayout, frame.managedAuraContainer, frame.managedAuraGroupKey, {
            elementWidth = MANAGED_AURA_ICON_SIZE,
            elementHeight = MANAGED_AURA_ICON_SIZE,
            elementSpacing = MANAGED_AURA_SPACING,
            lineSpacing = MANAGED_AURA_SPACING,
            maximumLineSize = lineSize,
        })
    end
    frame.managedAuraAppliedColumns = columns
    frame.managedAuraLayoutPending = false
end

local function RestoreManagedAuraRuntime(frame, slotStore)
    if not frame or not frame.managedAuraContainer then return end
    HideTrackingSlots(slotStore)
    local configuredColumns = GetConfiguredBarColumns(frame.dbKey, MANAGED_AURAS_PER_LINE, 10)
    if frame.managedAuraLayoutPending == true or frame.managedAuraAppliedColumns ~= configuredColumns then
        ApplyManagedAuraLayout(frame)
    end
    frame.managedAuraContainer:Show()
    if frame.managedAuraContainer.UpdateAllAuras then
        pcall(frame.managedAuraContainer.UpdateAllAuras, frame.managedAuraContainer)
    end
    UpdateManagedAuraBarChrome(frame)
end

CreateBuffBar = function()
    -- The primary DK buff/proc HUD now uses the same Blizzard-owned AuraContainer
    -- engine as the native 12.1 UI. candidateFilters.includeSpellIDs is a
    -- whitelist assembled from our curated DK list plus the current Cooldown
    -- Manager profile, so Blizzard decides active state, stacks and duration.
    local candidateFilters = addon.BuildDKBuffCandidateFilters and addon:BuildDKBuffCandidateFilters() or {}
    return CreateManagedAuraBar(
        "DKMentorBuffBar",
        "buffBar",
        T("DK Buffs"),
        buffSlots,
        "HELPFUL",
        false,
        candidateFilters
    )
end

local function CreateExternalBuffBar()
    return CreateManagedAuraBar(
        "DKMentorExternalBuffBar",
        "externalBuffBar",
        T("External Buffs"),
        externalBuffSlots,
        "HELPFUL|!PLAYER",
        false
    )
end

local function CreateDebuffBar()
    return CreateManagedAuraBar(
        "DKMentorDebuffBar",
        "debuffBar",
        T("Debuffs"),
        debuffSlots,
        "HARMFUL",
        true
    )
end

local function CreateAbilityBar()
    return CreateTrackingBar("DKMentorAbilityBar", "abilityBar", T("Abilities"), abilitySlots, 11, 0.12)
end

local RESOURCE_RUNE_LAYOUTS = {
    compact = { runeWidth = 40, gap = 3 },
    normal = { runeWidth = 47, gap = 4 },
    wide = { runeWidth = 54, gap = 6 },
}

local function NormalizeResourceRuneSpacing(value)
    value = tostring(value or "normal")
    if not RESOURCE_RUNE_LAYOUTS[value] then return "normal" end
    return value
end

local function NormalizeResourceHUDStyle(value)
    value = tostring(value or "classic")
    if value ~= "classic" and value ~= "arcs" then
        return "classic"
    end
    return value
end

local function LayoutResourceHUDComponents(frame, showRunes, showRunicPower)
    if not frame then return end

    local config = DB and DB.resourceHUD or DEFAULTS.resourceHUD
    local spacingKey = NormalizeResourceRuneSpacing(config and config.runeSpacing)
    local spacing = RESOURCE_RUNE_LAYOUTS[spacingKey]
    local contentWidth = (spacing.runeWidth * 6) + (spacing.gap * 5)
    local frameWidth = contentWidth + 28

    if showRunes and showRunicPower then
        frame:SetSize(frameWidth, 66)
    elseif showRunes then
        frame:SetSize(frameWidth, 45)
    elseif showRunicPower then
        frame:SetSize(frameWidth, 43)
    else
        frame:SetSize(frameWidth, 43)
    end

    for index, rune in ipairs(frame.runes or {}) do
        rune:SetShown(showRunes == true)
        rune:SetSize(spacing.runeWidth, 12)
        rune:ClearAllPoints()
        rune:SetPoint("TOPLEFT", frame, "TOPLEFT", 7 + ((index - 1) * (spacing.runeWidth + spacing.gap)), -22)
    end

    if frame.power then
        frame.power:SetShown(showRunicPower == true)
        frame.power:SetWidth(contentWidth)
        frame.power:ClearAllPoints()
        if showRunes then
            frame.power:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -43)
        else
            frame.power:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -21)
        end
    end

    local showText = config == nil or config.showPowerText ~= false
    if frame.powerLabel then frame.powerLabel:SetShown(showRunicPower == true and showText) end
    if frame.powerValue then frame.powerValue:SetShown(showRunicPower == true and showText) end

    frame.layoutShowRunes = showRunes == true
    frame.layoutShowRunicPower = showRunicPower == true
    frame.layoutRuneSpacing = spacingKey
    frame.layoutShowPowerText = showText
end

local function CreateResourceHUD()
    local frame = CreateFrame("Frame", "DKMentorResourceHUD", UIParent, "BackdropTemplate")
    frame:SetSize(330, 66)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.84)

    frame:SetScript("OnDragStart", function(self)
        if addon:CanMoveHUDs() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if DB and DB.hudLocked == false then SaveFramePosition(self, "resourceHUD") end
    end)

    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.label:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -4)
    frame.label:SetText(T("DK Resources"))
    frame.label:SetTextColor(0.55, 0.82, 0.95)

    frame.dragHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.dragHint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -7, -4)
    frame.dragHint:SetText(T("Drag to move"))
    frame.dragHint:SetTextColor(0.42, 0.55, 0.62)

    frame.runes = {}
    for index = 1, 6 do
        local rune = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
        rune:SetSize(47, 12)
        rune:SetPoint("TOPLEFT", frame, "TOPLEFT", 7 + ((index - 1) * 51), -22)
        rune:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        rune:SetMinMaxValues(0, 1)
        rune:SetValue(1)
        rune:SetStatusBarColor(0.25, 0.78, 0.98, 0.95)
        rune:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        rune:SetBackdropColor(0.015, 0.035, 0.05, 0.92)
        rune:SetBackdropBorderColor(0.16, 0.42, 0.56, 0.9)
        frame.runes[index] = rune
    end

    frame.power = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
    frame.power:SetSize(302, 15)
    frame.power:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -43)
    frame.power:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    frame.power:SetMinMaxValues(0, 100)
    frame.power:SetValue(0)
    frame.power:SetStatusBarColor(0.18, 0.62, 0.92, 0.95)
    frame.power:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.power:SetBackdropColor(0.015, 0.035, 0.05, 0.92)
    frame.power:SetBackdropBorderColor(0.16, 0.42, 0.56, 0.9)

    frame.powerLabel = frame.power:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.powerLabel:SetPoint("LEFT", frame.power, "LEFT", 5, 0)
    frame.powerLabel:SetText(T("Runic Power"))
    frame.powerLabel:SetShadowOffset(1, -1)

    frame.powerValue = frame.power:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.powerValue:SetPoint("RIGHT", frame.power, "RIGHT", -5, 0)
    frame.powerValue:SetText("")
    frame.powerValue:SetShadowOffset(1, -1)

    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(T("DK Resources"))
        GameTooltip:AddLine(T("Tracks all six Death Knight Runes and Runic Power in one compact HUD."), 0.72, 0.84, 0.95, true)
        GameTooltip:AddLine(T("Runes fill as they recharge. Runic Power uses Blizzard's native StatusBar so primary-power secret values can be displayed safely during combat."), 0.62, 0.76, 0.86, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    frame.runeElapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.runeElapsed = self.runeElapsed + (tonumber(elapsed) or 0)
        if self.runeElapsed >= 0.05 then
            self.runeElapsed = 0
            addon:UpdateResourceRunes()
        end
    end)

    RestoreFramePosition(frame, "resourceHUD")
    frame:Hide()
    return frame
end

local DK_ARC_FILL_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcFill"
local DK_ARC_BG_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcBG"
local DK_ARC_GLOW_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcGlow"
local DK_ARC_FILL_RIGHT_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcFillRight"
local DK_ARC_BG_RIGHT_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcBGRight"
local DK_ARC_GLOW_RIGHT_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcGlowRight"
local DK_RUNE_TEXTURE = "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-SingleRune"

local function NormalizeResourceArcSpacing(value)
    value = tonumber(value) or 105
    value = Clamp(value, 65, 165)
    return math.floor((value / 5) + 0.5) * 5
end

local function CreateDKArcBar(parent, side)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(76, 246)

    local rightSide = side == "RIGHT"
    local fillTexture = rightSide and DK_ARC_FILL_RIGHT_TEXTURE or DK_ARC_FILL_TEXTURE
    local bgTexture = rightSide and DK_ARC_BG_RIGHT_TEXTURE or DK_ARC_BG_TEXTURE
    local glowTexture = rightSide and DK_ARC_GLOW_RIGHT_TEXTURE or DK_ARC_GLOW_TEXTURE

    holder.glow = holder:CreateTexture(nil, "BACKGROUND", nil, -2)
    holder.glow:SetTexture(glowTexture)
    holder.glow:SetAllPoints(holder)
    holder.glow:SetVertexColor(0.10, 0.68, 0.92, 0.22)

    holder.bg = holder:CreateTexture(nil, "BACKGROUND", nil, -1)
    holder.bg:SetTexture(bgTexture)
    holder.bg:SetAllPoints(holder)
    holder.bg:SetVertexColor(0.025, 0.055, 0.075, 0.82)

    holder.bar = CreateFrame("StatusBar", nil, holder)
    holder.bar:SetAllPoints(holder)
    holder.bar:SetOrientation("VERTICAL")
    holder.bar:SetMinMaxValues(0, 100)
    holder.bar:SetValue(0)
    holder.bar:SetStatusBarTexture(fillTexture)
    holder.bar:SetStatusBarColor(0.20, 0.82, 0.96, 0.98)
    if holder.bar.SetReverseFill then holder.bar:SetReverseFill(false) end

    return holder
end

local function SaveResourceArcPosition(frame)
    if not frame or not DB or not DB.resourceHUD then return end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    DB.resourceHUD.arcPoint = point or "CENTER"
    DB.resourceHUD.arcRelativePoint = relativePoint or point or "CENTER"
    DB.resourceHUD.arcX = tonumber(x) or 0
    DB.resourceHUD.arcY = tonumber(y) or 0
end

local function RestoreResourceArcPosition(frame)
    if not frame or not DB or not DB.resourceHUD then return end
    frame:ClearAllPoints()
    frame:SetPoint(
        DB.resourceHUD.arcPoint or DEFAULTS.resourceHUD.arcPoint or "CENTER",
        UIParent,
        DB.resourceHUD.arcRelativePoint or DEFAULTS.resourceHUD.arcRelativePoint or "CENTER",
        tonumber(DB.resourceHUD.arcX) or 0,
        tonumber(DB.resourceHUD.arcY) or 0
    )
end

local function ResetResourceArcPosition()
    if not DB or not DB.resourceHUD then return end
    DB.resourceHUD.arcPoint = DEFAULTS.resourceHUD.arcPoint
    DB.resourceHUD.arcRelativePoint = DEFAULTS.resourceHUD.arcRelativePoint
    DB.resourceHUD.arcX = DEFAULTS.resourceHUD.arcX
    DB.resourceHUD.arcY = DEFAULTS.resourceHUD.arcY
    if resourceArcFrame then RestoreResourceArcPosition(resourceArcFrame) end
end

local function GetDKRuneColors()
    local specID = addon and addon.GetSpecInfo and select(1, addon:GetSpecInfo()) or nil
    if specID == 250 then
        return { 0.88, 0.16, 0.18, 1 }, { 0.42, 0.08, 0.10, 0.72 }
    elseif specID == 252 then
        return { 0.30, 0.86, 0.34, 1 }, { 0.10, 0.38, 0.14, 0.72 }
    end
    return { 0.22, 0.82, 1.00, 1 }, { 0.08, 0.38, 0.56, 0.72 }
end

local function LayoutResourceArcHUDComponents(frame, showRunes, showRunicPower)
    if not frame then return end

    local spacing = NormalizeResourceArcSpacing(DB and DB.resourceHUD and DB.resourceHUD.arcSpacing or DEFAULTS.resourceHUD.arcSpacing)
    if frame.healthHolder then
        frame.healthHolder:ClearAllPoints()
        frame.healthHolder:SetPoint("CENTER", frame, "CENTER", -spacing, -2)
    end
    if frame.powerHolder then
        frame.powerHolder:ClearAllPoints()
        frame.powerHolder:SetPoint("CENTER", frame, "CENTER", spacing, -2)
        frame.powerHolder:SetShown(showRunicPower == true)
    end
    if frame.runeAnchor then frame.runeAnchor:SetShown(showRunes == true) end

    local showText = DB == nil or DB.resourceHUD == nil or DB.resourceHUD.showPowerText ~= false
    if frame.powerValue then frame.powerValue:SetShown(showRunicPower == true and showText) end
    if frame.healthValue then frame.healthValue:SetShown(showText) end

    frame.layoutShowRunes = showRunes == true
    frame.layoutShowRunicPower = showRunicPower == true
    frame.layoutShowPowerText = showText
end

local function CreateResourceArcHUD()
    -- This is deliberately an original DK-specific implementation. It follows
    -- the proven IceHUD idea of texture-driven vertical StatusBars positioned
    -- around the player, but uses DK Mentor code, layout, colors and textures.
    local frame = CreateFrame("Frame", "DKMentorResourceArcHUD", UIParent)
    frame:SetSize(360, 300)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if addon:CanMoveHUDs() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if DB and DB.hudLocked == false then SaveResourceArcPosition(self) end
    end)

    frame.healthHolder = CreateDKArcBar(frame, "LEFT")
    frame.healthHolder:SetPoint("CENTER", frame, "CENTER", -105, -2)
    frame.healthHolder.glow:SetVertexColor(0.18, 0.92, 0.34, 0.20)
    frame.healthHolder.bar:SetStatusBarColor(0.18, 0.92, 0.34, 0.98)

    frame.powerHolder = CreateDKArcBar(frame, "RIGHT")
    frame.powerHolder:SetPoint("CENTER", frame, "CENTER", 105, -2)
    frame.powerHolder.glow:SetVertexColor(0.08, 0.64, 0.98, 0.24)
    frame.powerHolder.bar:SetStatusBarColor(0.12, 0.66, 0.98, 0.98)

    frame.healthBar = frame.healthHolder.bar
    frame.powerBar = frame.powerHolder.bar

    frame.runeAnchor = CreateFrame("Frame", nil, frame)
    frame.runeAnchor:SetSize(154, 28)
    frame.runeAnchor:SetPoint("TOP", frame, "CENTER", 0, -62)

    frame.runes = {}
    local readyColor = GetDKRuneColors()
    for index = 1, 6 do
        local rune = CreateFrame("StatusBar", nil, frame.runeAnchor)
        rune:SetSize(22, 22)
        rune:SetPoint("LEFT", frame.runeAnchor, "LEFT", (index - 1) * 26, 0)
        rune:SetOrientation("VERTICAL")
        rune:SetMinMaxValues(0, 1)
        rune:SetValue(1)
        rune:SetStatusBarTexture(DK_RUNE_TEXTURE)
        rune:SetStatusBarColor(readyColor[1], readyColor[2], readyColor[3], readyColor[4])
        if rune.SetReverseFill then rune:SetReverseFill(false) end

        rune.bg = rune:CreateTexture(nil, "BACKGROUND")
        rune.bg:SetTexture(DK_RUNE_TEXTURE)
        rune.bg:SetAllPoints(rune)
        rune.bg:SetVertexColor(0.08, 0.15, 0.20, 0.58)

        frame.runes[index] = rune
    end

    frame.healthValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.healthValue:SetPoint("TOP", frame.healthHolder, "BOTTOM", 0, -4)
    frame.healthValue:SetJustifyH("CENTER")
    frame.healthValue:SetText("")
    frame.healthValue:SetTextColor(0.94, 0.98, 0.94)
    frame.healthValue:SetShadowOffset(1, -1)

    frame.powerValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.powerValue:SetPoint("TOP", frame.powerHolder, "BOTTOM", 0, -4)
    frame.powerValue:SetJustifyH("CENTER")
    frame.powerValue:SetText("")
    frame.powerValue:SetTextColor(0.75, 0.90, 1.00)
    frame.powerValue:SetShadowOffset(1, -1)


    frame.runeElapsed = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.runeElapsed = self.runeElapsed + (tonumber(elapsed) or 0)
        if self.runeElapsed >= 0.05 then
            self.runeElapsed = 0
            addon:UpdateResourceHealthHUD()
            addon:UpdateResourceRunes()
            addon:UpdateRunicPowerHUD()
        end
    end)

    RestoreResourceArcPosition(frame)
    frame:Hide()
    return frame
end

local COMBAT_BAR_LAYOUT_LIMITS = {
    buffBar = { minColumns = 3, maxColumns = 10, defaultColumns = 5 },
    externalBuffBar = { minColumns = 3, maxColumns = 10, defaultColumns = 5 },
    debuffBar = { minColumns = 3, maxColumns = 10, defaultColumns = 5 },
    abilityBar = { minColumns = 3, maxColumns = 11, defaultColumns = 11 },
    resourceHUD = { minColumns = 6, maxColumns = 6, defaultColumns = 6, resourceMode = true },
}

local function GetCombatBarParts(dbKey)
    if dbKey == "buffBar" then return buffFrame, buffSlots end
    if dbKey == "externalBuffBar" then return externalBuffFrame, externalBuffSlots end
    if dbKey == "debuffBar" then return debuffFrame, debuffSlots end
    if dbKey == "abilityBar" then return abilityFrame, abilitySlots end
    if dbKey == "resourceHUD" then return resourceFrame, nil end
    return nil, nil
end

local function NormalizeCombatBarScale(value)
    value = Clamp(value or 1, 0.7, 1.6)
    return math.floor((value * 10) + 0.5) / 10
end

local function NormalizeCombatBarOpacity(value)
    value = Clamp(value or 1, 0.3, 1)
    return math.floor((value * 10) + 0.5) / 10
end

function addon:ApplyCombatBarLayout(dbKey)
    if not DB or not DB[dbKey] then return end
    local limits = COMBAT_BAR_LAYOUT_LIMITS[dbKey]
    if not limits then return end

    local frame, slots = GetCombatBarParts(dbKey)
    local config = DB[dbKey]

    if limits.resourceMode then
        config.scale = NormalizeCombatBarScale(config.scale)
        config.opacity = NormalizeCombatBarOpacity(config.opacity)
        config.runeSpacing = NormalizeResourceRuneSpacing(config.runeSpacing)
        config.style = NormalizeResourceHUDStyle(config.style)
        config.arcSpacing = NormalizeResourceArcSpacing(config.arcSpacing)
        if resourceFrame then
            resourceFrame:SetScale(config.scale)
            resourceFrame:SetAlpha(config.opacity)
            LayoutResourceHUDComponents(resourceFrame, config.showRunes ~= false, config.showRunicPower ~= false)
        end
        if resourceArcFrame then
            resourceArcFrame:SetScale(config.scale)
            resourceArcFrame:SetAlpha(config.opacity)
            LayoutResourceArcHUDComponents(resourceArcFrame, config.showRunes ~= false, config.showRunicPower ~= false)
        end
        self:UpdateResourceHUD()
        return
    end

    if not frame then return end

    config.scale = NormalizeCombatBarScale(config.scale)
    config.opacity = NormalizeCombatBarOpacity(config.opacity)
    frame:SetScale(config.scale)
    frame:SetAlpha(config.opacity)

    config.iconsPerRow = Clamp(math.floor((tonumber(config.iconsPerRow) or limits.defaultColumns) + 0.5), limits.minColumns, limits.maxColumns)
    frame.slotsPerRow = config.iconsPerRow

    if frame.managedAuraContainer then
        ApplyManagedAuraLayout(frame)
        if self.hudPreviewMode == true then
            ShowManagedAuraPreview(frame, slots)
        else
            RestoreManagedAuraRuntime(frame, slots)
        end
    else
        LayoutTrackingSlots(frame, slots, config.iconsPerRow, false)
    end

    if dbKey == "abilityBar" then
        self:UpdateAbilityBar()
    end
end

function addon:SetCombatBarScale(dbKey, value)
    if not DB or not DB[dbKey] or not COMBAT_BAR_LAYOUT_LIMITS[dbKey] then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end

    DB[dbKey].scale = NormalizeCombatBarScale(value)
    self:ApplyCombatBarLayout(dbKey)
    self:RefreshCombatHUDVisibility()
    self:UpdateBarLayoutFrame()
end

function addon:SetCombatBarOpacity(dbKey, value)
    if not DB or not DB[dbKey] or not COMBAT_BAR_LAYOUT_LIMITS[dbKey] then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end

    DB[dbKey].opacity = NormalizeCombatBarOpacity(value)
    self:ApplyCombatBarLayout(dbKey)
    self:RefreshCombatHUDVisibility()
    self:UpdateBarLayoutFrame()
end

function addon:SetCombatBarColumns(dbKey, value)
    if not DB or not DB[dbKey] then return end
    local limits = COMBAT_BAR_LAYOUT_LIMITS[dbKey]
    if not limits then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end

    if limits.resourceMode then return end
    DB[dbKey].iconsPerRow = Clamp(math.floor((tonumber(value) or limits.defaultColumns) + 0.5), limits.minColumns, limits.maxColumns)
    self:ApplyCombatBarLayout(dbKey)
    self:RefreshCombatHUDVisibility()
    self:UpdateBarLayoutFrame()
end

function addon:ResetCombatBarLayout()
    if not DB then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end

    for dbKey, limits in pairs(COMBAT_BAR_LAYOUT_LIMITS) do
        if DB[dbKey] then
            DB[dbKey].scale = DEFAULTS[dbKey].scale or 1
            DB[dbKey].opacity = DEFAULTS[dbKey].opacity or 1
            if not limits.resourceMode then
                DB[dbKey].iconsPerRow = limits.defaultColumns
            else
                DB[dbKey].showPowerText = DEFAULTS.resourceHUD.showPowerText
                DB[dbKey].runeSpacing = DEFAULTS.resourceHUD.runeSpacing
                DB[dbKey].style = DEFAULTS.resourceHUD.style
                DB[dbKey].arcSpacing = DEFAULTS.resourceHUD.arcSpacing
            end
            self:ApplyCombatBarLayout(dbKey)
        end
    end
    self:RefreshCombatHUDVisibility()
    self:UpdateBarLayoutFrame()
    self:UpdateHUDSettings()
    Print(T("HUD size and opacity restored to defaults."))
end

function addon:SetResourceHUDEnabled(enabled)
    if not DB or not DB.resourceHUD then return end
    DB.resourceHUD.enabled = enabled == true
    self:UpdateResourceHUD()
    self:UpdateHUDSettings()
    Print(T(DB.resourceHUD.enabled and "DK resource HUD enabled." or "DK resource HUD disabled."))
end

function addon:SetResourceHUDRunesEnabled(enabled)
    if not DB or not DB.resourceHUD then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end
    DB.resourceHUD.showRunes = enabled == true
    self:ApplyCombatBarLayout("resourceHUD")
    self:UpdateResourceHUD()
    self:UpdateBarLayoutFrame()
    self:UpdateHUDSettings()
end

function addon:SetResourceHUDRunicPowerEnabled(enabled)
    if not DB or not DB.resourceHUD then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end
    DB.resourceHUD.showRunicPower = enabled == true
    self:ApplyCombatBarLayout("resourceHUD")
    self:UpdateResourceHUD()
    self:UpdateBarLayoutFrame()
    self:UpdateHUDSettings()
end

function addon:CycleResourceHUDMode()
    if not DB or not DB.resourceHUD then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end

    local runes = DB.resourceHUD.showRunes ~= false
    local power = DB.resourceHUD.showRunicPower ~= false
    if runes and power then
        DB.resourceHUD.showRunes = true
        DB.resourceHUD.showRunicPower = false
    elseif runes then
        DB.resourceHUD.showRunes = false
        DB.resourceHUD.showRunicPower = true
    else
        DB.resourceHUD.showRunes = true
        DB.resourceHUD.showRunicPower = true
    end

    self:ApplyCombatBarLayout("resourceHUD")
    self:UpdateResourceHUD()
    self:UpdateBarLayoutFrame()
    self:UpdateHUDSettings()
end

function addon:GetResourceHUDModeLabel()
    if not DB or not DB.resourceHUD then return T("Runes + Runic Power") end
    local runes = DB.resourceHUD.showRunes ~= false
    local power = DB.resourceHUD.showRunicPower ~= false
    if runes and power then return T("Runes + Runic Power") end
    if runes then return T("Runes only") end
    if power then return T("Runic Power only") end
    return T("Resources hidden")
end

function addon:GetResourceRuneSpacingLabel()
    local spacing = DB and DB.resourceHUD and NormalizeResourceRuneSpacing(DB.resourceHUD.runeSpacing) or "normal"
    if spacing == "compact" then return T("Compact") end
    if spacing == "wide" then return T("Wide") end
    return T("Normal")
end

function addon:GetResourceHUDStyleLabel()
    local style = DB and DB.resourceHUD and NormalizeResourceHUDStyle(DB.resourceHUD.style) or "classic"
    if style == "arcs" then return T("DK Arcs") end
    return T("Classic")
end

function addon:CycleResourceHUDStyle()
    if not DB or not DB.resourceHUD then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end

    local current = NormalizeResourceHUDStyle(DB.resourceHUD.style)
    DB.resourceHUD.style = current == "classic" and "arcs" or "classic"
    self:ApplyCombatBarLayout("resourceHUD")
    self:RefreshCombatHUDVisibility()
    self:UpdateBarLayoutFrame()
    self:UpdateHUDSettings()
end

function addon:SetResourceHUDPowerTextEnabled(enabled)
    if not DB or not DB.resourceHUD then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end
    DB.resourceHUD.showPowerText = enabled == true
    self:ApplyCombatBarLayout("resourceHUD")
    self:UpdateResourceHUD()
    self:UpdateBarLayoutFrame()
    self:UpdateHUDSettings()
end

function addon:CycleResourceRuneSpacing()
    if not DB or not DB.resourceHUD then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end

    local current = NormalizeResourceRuneSpacing(DB.resourceHUD.runeSpacing)
    if current == "compact" then
        DB.resourceHUD.runeSpacing = "normal"
    elseif current == "normal" then
        DB.resourceHUD.runeSpacing = "wide"
    else
        DB.resourceHUD.runeSpacing = "compact"
    end

    self:ApplyCombatBarLayout("resourceHUD")
    self:RefreshCombatHUDVisibility()
    self:UpdateBarLayoutFrame()
    self:UpdateHUDSettings()
end

function addon:SetResourceArcSpacing(value)
    if not DB or not DB.resourceHUD then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end
    DB.resourceHUD.arcSpacing = NormalizeResourceArcSpacing(value)
    self:ApplyCombatBarLayout("resourceHUD")
    self:RefreshCombatHUDVisibility()
    self:UpdateBarLayoutFrame()
    self:UpdateHUDSettings()
end

function addon:GetResourceArcSpacingLabel()
    if not DB or not DB.resourceHUD then return "100%" end
    local spacing = NormalizeResourceArcSpacing(DB.resourceHUD.arcSpacing)
    return string.format("%d%%", math.floor(((spacing / 105) * 100) + 0.5))
end

function addon:ResetResourceHUDLayout()
    if not DB or not DB.resourceHUD then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("Bar layout cannot be changed during combat."))
        return
    end

    local enabled = DB.resourceHUD.enabled
    DB.resourceHUD.showRunes = DEFAULTS.resourceHUD.showRunes
    DB.resourceHUD.showRunicPower = DEFAULTS.resourceHUD.showRunicPower
    DB.resourceHUD.showPowerText = DEFAULTS.resourceHUD.showPowerText
    DB.resourceHUD.runeSpacing = DEFAULTS.resourceHUD.runeSpacing
    DB.resourceHUD.style = DEFAULTS.resourceHUD.style
    DB.resourceHUD.arcSpacing = DEFAULTS.resourceHUD.arcSpacing
    DB.resourceHUD.scale = DEFAULTS.resourceHUD.scale
    DB.resourceHUD.opacity = DEFAULTS.resourceHUD.opacity
    DB.resourceHUD.point = DEFAULTS.resourceHUD.point
    DB.resourceHUD.relativePoint = DEFAULTS.resourceHUD.relativePoint
    DB.resourceHUD.x = DEFAULTS.resourceHUD.x
    DB.resourceHUD.y = DEFAULTS.resourceHUD.y
    DB.resourceHUD.enabled = enabled

    RestoreFramePosition(resourceFrame, "resourceHUD")
    ResetResourceArcPosition()
    self:ApplyCombatBarLayout("resourceHUD")
    self:RefreshCombatHUDVisibility()
    self:UpdateBarLayoutFrame()
    self:UpdateHUDSettings()
    Print(T("DK Resources HUD restored to defaults."))
end

function addon:UpdateResourceRunes()
    if not DB or not DB.resourceHUD then return end

    local style = NormalizeResourceHUDStyle(DB.resourceHUD.style)
    local activeFrame = style == "arcs" and resourceArcFrame or resourceFrame
    if not activeFrame or not activeFrame:IsShown() then return end

    local preview = self.hudPreviewMode == true
    local showRunes = preview or DB.resourceHUD.showRunes ~= false
    if not showRunes then return end

    local readyColor = { 0.25, 0.78, 0.98, 0.95 }
    local chargingColor = { 0.16, 0.52, 0.72, 0.92 }
    local emptyColor = { 0.12, 0.34, 0.46, 0.80 }
    if style == "arcs" then
        readyColor, chargingColor = GetDKRuneColors()
        emptyColor = { chargingColor[1] * 0.55, chargingColor[2] * 0.55, chargingColor[3] * 0.55, 0.62 }
    end

    if preview then
        local samples = { 1, 1, 1, 0.78, 0.48, 0.22 }
        for index, rune in ipairs(activeFrame.runes or {}) do
            local sample = samples[index] or 0
            rune:SetMinMaxValues(0, 1)
            rune:SetValue(sample)
            local color = sample >= 1 and readyColor or chargingColor
            rune:SetStatusBarColor(color[1], color[2], color[3], color[4])
        end
        return
    end

    if not GetRuneCooldown then return end
    local now = GetNow()
    for index, rune in ipairs(activeFrame.runes or {}) do
        local ok, startTime, duration, rawReady = pcall(GetRuneCooldown, index)
        local ready = ok and GetAccessibleBoolean(rawReady) or nil
        if ready == true then
            rune:SetMinMaxValues(0, 1)
            rune:SetValue(1)
            rune:SetStatusBarColor(readyColor[1], readyColor[2], readyColor[3], readyColor[4])
        elseif ok and IsAccessibleNumber(startTime) and IsAccessibleNumber(duration) and duration > 0 then
            local elapsed = Clamp(now - startTime, 0, duration)
            rune:SetMinMaxValues(0, duration)
            rune:SetValue(elapsed)
            rune:SetStatusBarColor(chargingColor[1], chargingColor[2], chargingColor[3], chargingColor[4])
        else
            rune:SetMinMaxValues(0, 1)
            rune:SetValue(0)
            rune:SetStatusBarColor(emptyColor[1], emptyColor[2], emptyColor[3], emptyColor[4])
        end
    end
end

function addon:UpdateRunicPowerHUD()
    if not DB or not DB.resourceHUD then return end

    local style = NormalizeResourceHUDStyle(DB.resourceHUD.style)
    local preview = self.hudPreviewMode == true
    local showPower = preview or DB.resourceHUD.showRunicPower ~= false

    if style == "arcs" then
        if not resourceArcFrame or not resourceArcFrame:IsShown() or not resourceArcFrame.powerBar then return end
        local bar = resourceArcFrame.powerBar
        if not showPower then
            if resourceArcFrame.powerValue then resourceArcFrame.powerValue:SetText("") end
            return
        end

        if preview then
            bar:SetMinMaxValues(0, 100)
            bar:SetValue(65)
            if resourceArcFrame.powerValue then resourceArcFrame.powerValue:SetText("65%") end
            return
        end

        if not UnitPower or not UnitPowerMax then
            bar:SetMinMaxValues(0, 100)
            bar:SetValue(0)
            if resourceArcFrame.powerValue then resourceArcFrame.powerValue:SetText("") end
            return
        end

        local okPower, power = pcall(UnitPower, "player", RUNIC_POWER_TYPE)
        local okMax, maxPower = pcall(UnitPowerMax, "player", RUNIC_POWER_TYPE)

        -- Midnight may make Runic Power secret in combat. Feed the raw value
        -- directly into StatusBar where Blizzard permits it and only build text
        -- when both values are normal accessible numbers.
        if okMax then
            local okSetMax = pcall(bar.SetMinMaxValues, bar, 0, maxPower)
            if not okSetMax then bar:SetMinMaxValues(0, 100) end
        else
            bar:SetMinMaxValues(0, 100)
        end
        if okPower then
            local okSetValue = pcall(bar.SetValue, bar, power)
            if not okSetValue then bar:SetValue(0) end
        else
            bar:SetValue(0)
        end

        if IsAccessibleNumber(power) and IsAccessibleNumber(maxPower) and maxPower > 0 then
            local percent = math.floor(((power / maxPower) * 100) + 0.5)
            if resourceArcFrame.powerValue then resourceArcFrame.powerValue:SetText(string.format("%d%%", percent)) end
        else
            if resourceArcFrame.powerValue then resourceArcFrame.powerValue:SetText("") end
        end
        return
    end

    if not resourceFrame or not resourceFrame.power or not resourceFrame:IsShown() then return end
    if not showPower then return end

    if preview then
        resourceFrame.power:SetMinMaxValues(0, 100)
        resourceFrame.power:SetValue(65)
        resourceFrame.powerValue:SetText("65 / 100")
        return
    end

    if not UnitPower or not UnitPowerMax then
        resourceFrame.power:SetMinMaxValues(0, 100)
        resourceFrame.power:SetValue(0)
        resourceFrame.powerValue:SetText("")
        return
    end

    local okPower, power = pcall(UnitPower, "player", RUNIC_POWER_TYPE)
    local okMax, maxPower = pcall(UnitPowerMax, "player", RUNIC_POWER_TYPE)

    -- Runic Power is a primary resource in Midnight and may be secret in combat.
    -- Do not compare or calculate with it. Blizzard explicitly allows secret
    -- BarValue inputs to flow into StatusBar:SetMinMaxValues/SetValue.
    if okMax then
        local okSetMax = pcall(resourceFrame.power.SetMinMaxValues, resourceFrame.power, 0, maxPower)
        if not okSetMax then
            resourceFrame.power:SetMinMaxValues(0, 100)
        end
    else
        resourceFrame.power:SetMinMaxValues(0, 100)
    end
    if okPower then
        local okSetValue = pcall(resourceFrame.power.SetValue, resourceFrame.power, power)
        if not okSetValue then
            resourceFrame.power:SetValue(0)
        end
    else
        resourceFrame.power:SetValue(0)
    end

    if IsAccessibleNumber(power) and IsAccessibleNumber(maxPower) then
        resourceFrame.powerValue:SetText(string.format("%d / %d", math.floor(power + 0.5), math.floor(maxPower + 0.5)))
    else
        -- The fill remains live in combat even when the raw number is secret.
        resourceFrame.powerValue:SetText("")
    end
end

local function SetResourceArcHealthColors(percent)
    if not resourceArcFrame or not resourceArcFrame.healthBar or not resourceArcFrame.healthHolder then return end
    local low = IsAccessibleNumber(percent) and percent <= 30
    if low then
        resourceArcFrame.healthHolder.glow:SetVertexColor(0.92, 0.18, 0.18, 0.28)
        resourceArcFrame.healthBar:SetStatusBarColor(0.92, 0.20, 0.20, 0.98)
        if resourceArcFrame.healthValue then
            resourceArcFrame.healthValue:SetTextColor(1.00, 0.34, 0.34)
        end
    else
        resourceArcFrame.healthHolder.glow:SetVertexColor(0.18, 0.92, 0.34, 0.20)
        resourceArcFrame.healthBar:SetStatusBarColor(0.18, 0.92, 0.34, 0.98)
        if resourceArcFrame.healthValue then
            resourceArcFrame.healthValue:SetTextColor(0.94, 0.98, 0.94)
        end
    end
end

function addon:UpdateResourceHealthHUD()
    if not resourceArcFrame or not DB or not DB.resourceHUD or not resourceArcFrame:IsShown() or not resourceArcFrame.healthBar then return end

    local bar = resourceArcFrame.healthBar
    local showText = DB.resourceHUD.showPowerText ~= false
    if self.hudPreviewMode == true then
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(85)
        SetResourceArcHealthColors(85)
        if resourceArcFrame.healthValue then
            resourceArcFrame.healthValue:SetText(showText and "85%" or "")
        end
        return
    end

    if not UnitHealth or not UnitHealthMax then
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(0)
        SetResourceArcHealthColors(nil)
        if resourceArcFrame.healthValue then resourceArcFrame.healthValue:SetText("") end
        return
    end

    local okHealth, health = pcall(UnitHealth, "player")
    local okMax, maxHealth = pcall(UnitHealthMax, "player")

    -- Use the same secret-safe pattern as Runic Power so the visual bar keeps
    -- working even when Midnight protects combat values.
    if okMax then
        local okSetMax = pcall(bar.SetMinMaxValues, bar, 0, maxHealth)
        if not okSetMax then bar:SetMinMaxValues(0, 100) end
    else
        bar:SetMinMaxValues(0, 100)
    end
    if okHealth then
        local okSetValue = pcall(bar.SetValue, bar, health)
        if not okSetValue then bar:SetValue(0) end
    else
        bar:SetValue(0)
    end

    -- Raw UnitHealth/UnitHealthMax can become secret in combat. The DK Mentor
    -- already has a dedicated percentage helper that prefers UnitHealthPercent,
    -- which remains suitable for threshold checks in supported Midnight contexts.
    -- Use that percentage for the <=30% warning so the arc can actually turn red
    -- during combat instead of falling back to green whenever raw health is secret.
    local percent = GetPlayerHealthPercent()
    if IsAccessibleNumber(percent) then
        percent = math.floor(percent + 0.5)
        SetResourceArcHealthColors(percent)
        if resourceArcFrame.healthValue then
            resourceArcFrame.healthValue:SetText(showText and string.format("%d%%", percent) or "")
        end
    else
        SetResourceArcHealthColors(nil)
        if resourceArcFrame.healthValue then resourceArcFrame.healthValue:SetText("") end
    end
end

function addon:UpdateResourceHUD()
    if not DB or not DB.resourceHUD then return end
    local style = NormalizeResourceHUDStyle(DB.resourceHUD.style)
    local preview = self.hudPreviewMode == true

    if resourceFrame == nil and resourceArcFrame == nil then return end
    if not self:ShouldShowCombatBar(DB.resourceHUD) then
        if resourceFrame then resourceFrame:Hide() end
        if resourceArcFrame then resourceArcFrame:Hide() end
        return
    end

    local showRunes = preview or DB.resourceHUD.showRunes ~= false
    local showPower = preview or DB.resourceHUD.showRunicPower ~= false
    if not showRunes and not showPower then
        if resourceFrame then resourceFrame:Hide() end
        if resourceArcFrame then resourceArcFrame:Hide() end
        return
    end

    local spacingKey = NormalizeResourceRuneSpacing(DB.resourceHUD.runeSpacing)
    local showPowerText = DB.resourceHUD.showPowerText ~= false
    local lockdown = InCombatLockdown and InCombatLockdown()

    if style == "arcs" then
        if resourceFrame then resourceFrame:Hide() end
        if resourceArcFrame then
            local layoutChanged = resourceArcFrame.layoutShowRunes ~= (showRunes == true)
                or resourceArcFrame.layoutShowRunicPower ~= (showPower == true)
                or resourceArcFrame.layoutShowPowerText ~= showPowerText
            if layoutChanged and not lockdown then
                LayoutResourceArcHUDComponents(resourceArcFrame, showRunes, showPower)
            end
            resourceArcFrame:Show()
            self:UpdateResourceHealthHUD()
            self:UpdateResourceRunes()
            self:UpdateRunicPowerHUD()
        end
        return
    end

    if resourceArcFrame then resourceArcFrame:Hide() end
    if resourceFrame then
        local layoutChanged = resourceFrame.layoutShowRunes ~= (showRunes == true)
            or resourceFrame.layoutShowRunicPower ~= (showPower == true)
            or resourceFrame.layoutRuneSpacing ~= spacingKey
            or resourceFrame.layoutShowPowerText ~= showPowerText
        if layoutChanged and not lockdown then
            -- Never re-anchor the Runic Power StatusBar after it has received a
            -- secret combat value. The resource-mode switches are already blocked
            -- in combat, so the layout can safely stay frozen until combat ends.
            LayoutResourceHUDComponents(resourceFrame, showRunes, showPower)
        end

        resourceFrame:Show()
        self:UpdateResourceRunes()
        self:UpdateRunicPowerHUD()
    end
end

local function CreateInterruptAlert()
    local frame = CreateFrame("Frame", "DKMentorInterruptAlert", UIParent, "BackdropTemplate")
    frame:SetSize(58, 58)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.92)

    frame:SetScript("OnDragStart", function(self)
        if addon:CanMoveHUDs() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if DB and DB.hudLocked == false then SaveFramePosition(self, "interruptAlert") end
    end)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    frame.icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local _, icon = GetSpellData(Data.spells and Data.spells.MIND_FREEZE or 47528, T("Mind Freeze"))
    frame.icon:SetTexture(icon or QUESTION_MARK_ICON)

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    frame.cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    if frame.cooldown.SetDrawEdge then frame.cooldown:SetDrawEdge(false) end
    if frame.cooldown.SetDrawBling then frame.cooldown:SetDrawBling(false) end
    if frame.cooldown.SetHideCountdownNumbers then frame.cooldown:SetHideCountdownNumbers(false) end

    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(Data.spells and Data.spells.MIND_FREEZE or 47528)
        else
            GameTooltip:SetText(T("Mind Freeze"))
        end
        GameTooltip:AddLine(T("Appears when your current target is confirmed to be casting or channeling an interruptible spell."), 0.72, 0.84, 0.95, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    RestoreFramePosition(frame, "interruptAlert")
    frame:Hide()
    return frame
end

local function CreateBarLayoutFrame()
    local frame = CreateFrame("Frame", "DKMentorBarLayoutFrame", UIParent, "BackdropTemplate")
    frame:SetSize(820, 560)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1200)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.98)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -15)
    frame.title:SetText(T("Combat HUD size and layout"))
    frame.title:SetTextColor(0.52, 0.88, 1)

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    frame.description = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.description:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -45)
    frame.description:SetWidth(780)
    frame.description:SetHeight(40)
    frame.description:SetJustifyH("LEFT")
    frame.description:SetJustifyV("TOP")
    frame.description:SetText(T("Adjust each combat HUD independently. Size scales the whole HUD, opacity controls transparency, aura/ability rows can change width, and DK Resources has its own mode, style, text, Rune spacing, and Arc opening. Preview HUDs overrides combat-only visibility while you arrange the interface."))

    local function AddHeader(text, x, width)
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -92)
        header:SetWidth(width)
        header:SetJustifyH("CENTER")
        header:SetText(T(text))
        header:SetTextColor(0.55, 0.84, 0.95)
        return header
    end

    frame.headerBar = AddHeader("Bar", 20, 150)
    frame.headerScale = AddHeader("Size", 180, 125)
    frame.headerOpacity = AddHeader("Opacity", 330, 125)
    frame.headerColumns = AddHeader("Icons / mode", 505, 250)

    frame.rows = {}
    local rowDefs = {
        { key = "buffBar", label = T("DK Buffs") },
        { key = "externalBuffBar", label = T("External Buffs") },
        { key = "debuffBar", label = T("Debuffs") },
        { key = "abilityBar", label = T("Abilities") },
        { key = "resourceHUD", label = T("DK Resources"), resourceMode = true },
    }

    for index, definition in ipairs(rowDefs) do
        local y = -120 - ((index - 1) * 44)
        local row = CreateFrame("Frame", nil, frame)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, y)
        row:SetSize(788, 38)
        row.dbKey = definition.key

        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.label:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.label:SetWidth(150)
        row.label:SetJustifyH("LEFT")
        row.label:SetText(definition.label)

        row.scaleMinus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.scaleMinus:SetSize(30, 26)
        row.scaleMinus:SetPoint("LEFT", row, "LEFT", 166, 0)
        row.scaleMinus:SetText("-")
        row.scaleMinus:SetScript("OnClick", function()
            addon:SetCombatBarScale(row.dbKey, (DB[row.dbKey].scale or 1) - 0.1)
        end)

        row.scaleValue = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.scaleValue:SetPoint("LEFT", row.scaleMinus, "RIGHT", 5, 0)
        row.scaleValue:SetWidth(58)
        row.scaleValue:SetJustifyH("CENTER")

        row.scalePlus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.scalePlus:SetSize(30, 26)
        row.scalePlus:SetPoint("LEFT", row.scaleValue, "RIGHT", 5, 0)
        row.scalePlus:SetText("+")
        row.scalePlus:SetScript("OnClick", function()
            addon:SetCombatBarScale(row.dbKey, (DB[row.dbKey].scale or 1) + 0.1)
        end)

        row.opacityMinus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.opacityMinus:SetSize(30, 26)
        row.opacityMinus:SetPoint("LEFT", row, "LEFT", 316, 0)
        row.opacityMinus:SetText("-")
        row.opacityMinus:SetScript("OnClick", function()
            addon:SetCombatBarOpacity(row.dbKey, (DB[row.dbKey].opacity or 1) - 0.1)
        end)

        row.opacityValue = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.opacityValue:SetPoint("LEFT", row.opacityMinus, "RIGHT", 5, 0)
        row.opacityValue:SetWidth(58)
        row.opacityValue:SetJustifyH("CENTER")

        row.opacityPlus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.opacityPlus:SetSize(30, 26)
        row.opacityPlus:SetPoint("LEFT", row.opacityValue, "RIGHT", 5, 0)
        row.opacityPlus:SetText("+")
        row.opacityPlus:SetScript("OnClick", function()
            addon:SetCombatBarOpacity(row.dbKey, (DB[row.dbKey].opacity or 1) + 0.1)
        end)

        row.columnsMinus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.columnsMinus:SetSize(30, 26)
        row.columnsMinus:SetPoint("LEFT", row, "LEFT", 510, 0)
        row.columnsMinus:SetText("-")
        row.columnsMinus:SetScript("OnClick", function()
            addon:SetCombatBarColumns(row.dbKey, (DB[row.dbKey].iconsPerRow or 5) - 1)
        end)

        row.columnsValue = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.columnsValue:SetPoint("LEFT", row.columnsMinus, "RIGHT", 5, 0)
        row.columnsValue:SetWidth(64)
        row.columnsValue:SetJustifyH("CENTER")

        row.columnsPlus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.columnsPlus:SetSize(30, 26)
        row.columnsPlus:SetPoint("LEFT", row.columnsValue, "RIGHT", 5, 0)
        row.columnsPlus:SetText("+")
        row.columnsPlus:SetScript("OnClick", function()
            addon:SetCombatBarColumns(row.dbKey, (DB[row.dbKey].iconsPerRow or 5) + 1)
        end)

        if definition.resourceMode then
            row.columnsMinus:Hide()
            row.columnsValue:Hide()
            row.columnsPlus:Hide()
            row.resourceModeButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.resourceModeButton:SetSize(240, 26)
            row.resourceModeButton:SetPoint("LEFT", row, "LEFT", 500, 0)
            row.resourceModeButton:SetScript("OnClick", function() addon:CycleResourceHUDMode() end)
            local modeFont = row.resourceModeButton.GetFontString and row.resourceModeButton:GetFontString()
            if modeFont and GameFontNormalSmall then modeFont:SetFontObject(GameFontNormalSmall) end
        end

        frame.rows[definition.key] = row
    end

    frame.resourceOptionsTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.resourceOptionsTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -350)
    frame.resourceOptionsTitle:SetText(T("DK Resources appearance"))
    frame.resourceOptionsTitle:SetTextColor(0.55, 0.84, 0.95)

    frame.resourceTextButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resourceTextButton:SetSize(165, 28)
    frame.resourceTextButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -374)
    frame.resourceTextButton:SetScript("OnClick", function()
        addon:SetResourceHUDPowerTextEnabled(not DB.resourceHUD.showPowerText)
    end)

    frame.resourceStyleButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resourceStyleButton:SetSize(165, 28)
    frame.resourceStyleButton:SetPoint("LEFT", frame.resourceTextButton, "RIGHT", 8, 0)
    frame.resourceStyleButton:SetScript("OnClick", function() addon:CycleResourceHUDStyle() end)

    frame.resourceSpacingButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resourceSpacingButton:SetSize(190, 28)
    frame.resourceSpacingButton:SetPoint("LEFT", frame.resourceStyleButton, "RIGHT", 8, 0)
    frame.resourceSpacingButton:SetScript("OnClick", function() addon:CycleResourceRuneSpacing() end)

    frame.resourceResetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resourceResetButton:SetSize(190, 28)
    frame.resourceResetButton:SetPoint("LEFT", frame.resourceSpacingButton, "RIGHT", 8, 0)
    frame.resourceResetButton:SetText(T("Restore DK Resources"))
    frame.resourceResetButton:SetScript("OnClick", function() addon:ResetResourceHUDLayout() end)

    frame.resourceArcSpacingLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.resourceArcSpacingLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -414)
    frame.resourceArcSpacingLabel:SetWidth(150)
    frame.resourceArcSpacingLabel:SetJustifyH("LEFT")
    frame.resourceArcSpacingLabel:SetText(T("Arc opening"))

    frame.resourceArcSpacingMinus = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resourceArcSpacingMinus:SetSize(32, 26)
    frame.resourceArcSpacingMinus:SetPoint("TOPLEFT", frame, "TOPLEFT", 174, -407)
    frame.resourceArcSpacingMinus:SetText("-")
    frame.resourceArcSpacingMinus:SetScript("OnClick", function()
        addon:SetResourceArcSpacing((DB.resourceHUD.arcSpacing or 105) - 10)
    end)

    frame.resourceArcSpacingValue = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.resourceArcSpacingValue:SetPoint("LEFT", frame.resourceArcSpacingMinus, "RIGHT", 6, 0)
    frame.resourceArcSpacingValue:SetWidth(70)
    frame.resourceArcSpacingValue:SetJustifyH("CENTER")

    frame.resourceArcSpacingPlus = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resourceArcSpacingPlus:SetSize(32, 26)
    frame.resourceArcSpacingPlus:SetPoint("LEFT", frame.resourceArcSpacingValue, "RIGHT", 6, 0)
    frame.resourceArcSpacingPlus:SetText("+")
    frame.resourceArcSpacingPlus:SetScript("OnClick", function()
        addon:SetResourceArcSpacing((DB.resourceHUD.arcSpacing or 105) + 10)
    end)

    frame.resourceArcSpacingHint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.resourceArcSpacingHint:SetPoint("LEFT", frame.resourceArcSpacingPlus, "RIGHT", 10, 0)
    frame.resourceArcSpacingHint:SetWidth(430)
    frame.resourceArcSpacingHint:SetJustifyH("LEFT")
    frame.resourceArcSpacingHint:SetText(T("Close or open the two arcs around the character without changing their size."))
    frame.resourceArcSpacingHint:SetTextColor(0.62, 0.76, 0.86)

    frame.resourceStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.resourceStatus:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -452)
    frame.resourceStatus:SetWidth(775)
    frame.resourceStatus:SetHeight(34)
    frame.resourceStatus:SetJustifyH("LEFT")
    frame.resourceStatus:SetJustifyV("TOP")
    frame.resourceStatus:SetTextColor(0.62, 0.76, 0.86)

    frame.resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resetButton:SetSize(245, 28)
    frame.resetButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 16)
    frame.resetButton:SetText(T("Restore HUD appearance"))
    frame.resetButton:SetScript("OnClick", function() addon:ResetCombatBarLayout() end)

    frame.previewButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.previewButton:SetSize(245, 28)
    frame.previewButton:SetPoint("LEFT", frame.resetButton, "RIGHT", 10, 0)
    frame.previewButton:SetScript("OnClick", function() addon:ToggleHUDPreview() end)

    frame.doneButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.doneButton:SetSize(245, 28)
    frame.doneButton:SetPoint("LEFT", frame.previewButton, "RIGHT", 10, 0)
    frame.doneButton:SetText(T("Close"))
    frame.doneButton:SetScript("OnClick", function() frame:Hide() end)

    for _, button in ipairs({
        frame.resourceTextButton, frame.resourceStyleButton, frame.resourceSpacingButton, frame.resourceResetButton,
        frame.resourceArcSpacingMinus, frame.resourceArcSpacingPlus,
        frame.resetButton, frame.previewButton, frame.doneButton,
    }) do
        local fontString = button.GetFontString and button:GetFontString()
        if fontString and GameFontNormalSmall then fontString:SetFontObject(GameFontNormalSmall) end
    end

    frame:SetScript("OnShow", function() addon:UpdateBarLayoutFrame() end)
    frame:Hide()
    return frame
end

function addon:UpdateBarLayoutFrame()
    if not barLayoutFrame or not DB then return end
    for dbKey, row in pairs(barLayoutFrame.rows or {}) do
        local config = DB[dbKey]
        local limits = COMBAT_BAR_LAYOUT_LIMITS[dbKey]
        if config and limits then
            local scale = NormalizeCombatBarScale(config.scale)
            row.scaleValue:SetText(string.format("%d%%", math.floor((scale * 100) + 0.5)))
            row.scaleMinus:SetEnabled(scale > 0.7)
            row.scalePlus:SetEnabled(scale < 1.6)

            local opacity = NormalizeCombatBarOpacity(config.opacity)
            row.opacityValue:SetText(string.format("%d%%", math.floor((opacity * 100) + 0.5)))
            row.opacityMinus:SetEnabled(opacity > 0.3)
            row.opacityPlus:SetEnabled(opacity < 1)

            if limits.resourceMode then
                if row.resourceModeButton then row.resourceModeButton:SetText(self:GetResourceHUDModeLabel()) end
            else
                local columns = Clamp(math.floor((tonumber(config.iconsPerRow) or limits.defaultColumns) + 0.5), limits.minColumns, limits.maxColumns)
                row.columnsValue:SetText(tostring(columns))
                row.columnsMinus:SetEnabled(columns > limits.minColumns)
                row.columnsPlus:SetEnabled(columns < limits.maxColumns)
            end
        end
    end

    if barLayoutFrame.resourceTextButton then
        barLayoutFrame.resourceTextButton:SetText(T(DB.resourceHUD.showPowerText ~= false and "Power text: ON" or "Power text: OFF"))
    end
    if barLayoutFrame.resourceStyleButton then
        barLayoutFrame.resourceStyleButton:SetText(T("Style: %s", self:GetResourceHUDStyleLabel()))
    end
    if barLayoutFrame.resourceSpacingButton then
        barLayoutFrame.resourceSpacingButton:SetText(T("Rune spacing: %s", self:GetResourceRuneSpacingLabel()))
    end
    if barLayoutFrame.resourceArcSpacingValue then
        local arcSpacing = NormalizeResourceArcSpacing(DB.resourceHUD.arcSpacing)
        local arcMode = NormalizeResourceHUDStyle(DB.resourceHUD.style) == "arcs"
        barLayoutFrame.resourceArcSpacingValue:SetText(self:GetResourceArcSpacingLabel())
        barLayoutFrame.resourceArcSpacingMinus:SetEnabled(arcMode and arcSpacing > 65)
        barLayoutFrame.resourceArcSpacingPlus:SetEnabled(arcMode and arcSpacing < 165)
        if barLayoutFrame.resourceArcSpacingLabel then
            barLayoutFrame.resourceArcSpacingLabel:SetTextColor(arcMode and 1 or 0.45, arcMode and 0.82 or 0.45, arcMode and 0.25 or 0.45)
        end
        if barLayoutFrame.resourceArcSpacingHint then
            barLayoutFrame.resourceArcSpacingHint:SetTextColor(arcMode and 0.62 or 0.42, arcMode and 0.76 or 0.42, arcMode and 0.86 or 0.42)
        end
    end
    if barLayoutFrame.resourceStatus then
        barLayoutFrame.resourceStatus:SetText(T(
            "Current DK Resources: %s • Style %s • Size %d%% • Opacity %d%% • Arc opening %s",
            self:GetResourceHUDModeLabel(),
            self:GetResourceHUDStyleLabel(),
            math.floor((NormalizeCombatBarScale(DB.resourceHUD.scale) * 100) + 0.5),
            math.floor((NormalizeCombatBarOpacity(DB.resourceHUD.opacity) * 100) + 0.5),
            self:GetResourceArcSpacingLabel()
        ))
    end
    if barLayoutFrame.previewButton then
        barLayoutFrame.previewButton:SetText(self.hudPreviewMode == true and T("Preview HUDs: ON") or T("Preview HUDs: OFF"))
    end
end

function addon:ToggleBarLayoutFrame()
    if not barLayoutFrame then return end
    if barLayoutFrame:IsShown() then
        barLayoutFrame:Hide()
    else
        barLayoutFrame:Show()
        barLayoutFrame:Raise()
    end
end


local function CreateLoadoutPickerFrame()
    local frame = CreateFrame("Frame", "DKMentorLoadoutPickerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(520, 455)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1200)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.98)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -15)
    frame.title:SetText(T("Talent Loadout Mapping"))
    frame.title:SetTextColor(0.52, 0.88, 1)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -6)
    frame.subtitle:SetWidth(455)
    frame.subtitle:SetJustifyH("LEFT")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    for index = 1, 10 do
        local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
        row:SetSize(476, 31)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -(69 + ((index - 1) * 34)))
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        row:SetBackdropColor(0.025, 0.08, 0.11, index % 2 == 0 and 0.50 or 0.30)
        row:RegisterForClicks("LeftButtonUp")

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(24, 24)
        row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.icon:SetTexture(QUESTION_MARK_ICON)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetWidth(270)
        row.name:SetJustifyH("LEFT")

        row.status = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.status:SetPoint("RIGHT", row, "RIGHT", -9, 0)
        row.status:SetWidth(140)
        row.status:SetJustifyH("RIGHT")

        row:SetScript("OnEnter", function(self) self:SetBackdropColor(0.08, 0.25, 0.32, 0.75) end)
        row:SetScript("OnLeave", function(self)
            local i = self.rowIndex or 1
            self:SetBackdropColor(0.025, 0.08, 0.11, i % 2 == 0 and 0.50 or 0.30)
        end)
        row:SetScript("OnClick", function(self)
            if self.configID and addon:BindLoadoutPickerSelection(self.configID) then
                frame:Hide()
            end
        end)

        row.rowIndex = index
        loadoutRows[index] = row
    end

    frame.currentButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.currentButton:SetSize(165, 25)
    frame.currentButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 14)
    frame.currentButton:SetText(T("Use current loadout"))
    frame.currentButton:SetScript("OnClick", function()
        if addon:BindCurrentLoadoutPickerSelection() then frame:Hide() end
    end)

    frame.createButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.createButton:SetSize(145, 25)
    frame.createButton:SetPoint("LEFT", frame.currentButton, "RIGHT", 8, 0)
    frame.createButton:SetText(T("Create DKM copy"))
    frame.createButton:SetScript("OnClick", function()
        frame:Hide()
        addon:SaveCurrentLoadoutBinding()
    end)

    frame.refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.refreshButton:SetSize(105, 25)
    frame.refreshButton:SetPoint("LEFT", frame.createButton, "RIGHT", 8, 0)
    frame.refreshButton:SetText(T("Refresh list"))
    frame.refreshButton:SetScript("OnClick", function() addon:UpdateLoadoutPicker() end)

    frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.footer:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 16, 48)
    frame.footer:SetWidth(475)
    frame.footer:SetJustifyH("LEFT")

    frame:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, frame:GetName()) end
    return frame
end

local function CreateEquipmentPickerFrame()
    local frame = CreateFrame("Frame", "DKMentorEquipmentPickerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(520, 455)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1200)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.98)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -15)
    frame.title:SetText(T("Equipment Set Mapping"))
    frame.title:SetTextColor(0.52, 0.88, 1)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -6)
    frame.subtitle:SetWidth(455)
    frame.subtitle:SetJustifyH("LEFT")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    for index = 1, 10 do
        local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
        row:SetSize(476, 31)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -(69 + ((index - 1) * 34)))
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        row:SetBackdropColor(0.025, 0.08, 0.11, index % 2 == 0 and 0.50 or 0.30)
        row:RegisterForClicks("LeftButtonUp")

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(24, 24)
        row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.icon:SetTexture(QUESTION_MARK_ICON)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetWidth(260)
        row.name:SetJustifyH("LEFT")

        row.status = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.status:SetPoint("RIGHT", row, "RIGHT", -9, 0)
        row.status:SetWidth(150)
        row.status:SetJustifyH("RIGHT")

        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.08, 0.25, 0.32, 0.75)
        end)
        row:SetScript("OnLeave", function(self)
            local i = self.rowIndex or 1
            self:SetBackdropColor(0.025, 0.08, 0.11, i % 2 == 0 and 0.50 or 0.30)
        end)
        row:SetScript("OnClick", function(self)
            if self.setID and addon:BindEquipmentPickerSelection(self.setID) then
                frame:Hide()
            end
        end)

        row.rowIndex = index
        equipmentRows[index] = row
    end

    frame.equippedButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.equippedButton:SetSize(170, 25)
    frame.equippedButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 14)
    frame.equippedButton:SetText(T("Use currently equipped set"))
    frame.equippedButton:SetScript("OnClick", function()
        if addon:BindCurrentlyEquippedPickerSelection() then
            frame:Hide()
        end
    end)

    frame.refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.refreshButton:SetSize(105, 25)
    frame.refreshButton:SetPoint("LEFT", frame.equippedButton, "RIGHT", 8, 0)
    frame.refreshButton:SetText(T("Refresh list"))
    frame.refreshButton:SetScript("OnClick", function() addon:UpdateEquipmentPicker() end)

    frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.footer:SetPoint("LEFT", frame.refreshButton, "RIGHT", 10, 0)
    frame.footer:SetWidth(185)
    frame.footer:SetJustifyH("LEFT")
    frame.footer:SetText(T("Click a saved WoW set to map it. DK Mentor does not duplicate it."))

    frame:Hide()
    if UISpecialFrames then
        table.insert(UISpecialFrames, frame:GetName())
    end
    return frame
end

local function CreateVoiceConfigFrame()
    local frame = CreateFrame("Frame", "DKMentorVoiceConfigFrame", UIParent, "BackdropTemplate")
    frame:SetSize(610, 560)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.98)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -15)
    frame.title:SetText(T("Lich King Voice Mapping"))
    frame.title:SetTextColor(0.52, 0.88, 1)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
    frame.subtitle:SetWidth(540)
    frame.subtitle:SetJustifyH("LEFT")
    frame.subtitle:SetText(T("Choose Random, Disabled, or a specific installed voice for each situation. Use Preview to identify a line; DK Mentor stores no quote text."))

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -72)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -31, 48)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(555, math.max(1, #(Voices.selectionOrder or {})) * 34)
    scroll:SetScrollChild(content)
    frame.content = content

    for index, category in ipairs(Voices.selectionOrder or {}) do
        local categoryKey = category
        local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
        row:SetSize(550, 30)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((index - 1) * 34))
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        row:SetBackdropColor(0.025, 0.08, 0.11, index % 2 == 0 and 0.46 or 0.28)
        row.category = categoryKey

        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.label:SetWidth(175)
        row.label:SetJustifyH("LEFT")
        row.label:SetText((Voices.categoryLabels and Voices.categoryLabels[categoryKey]) or categoryKey)

        row.prev = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.prev:SetSize(28, 22)
        row.prev:SetPoint("LEFT", row, "LEFT", 184, 0)
        row.prev:SetText("<")
        row.prev:SetScript("OnClick", function() addon:CycleVoiceSelection(categoryKey, -1) end)

        row.selection = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.selection:SetPoint("LEFT", row.prev, "RIGHT", 5, 0)
        row.selection:SetWidth(105)
        row.selection:SetJustifyH("CENTER")

        row.next = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.next:SetSize(28, 22)
        row.next:SetPoint("LEFT", row.selection, "RIGHT", 5, 0)
        row.next:SetText(">")
        row.next:SetScript("OnClick", function() addon:CycleVoiceSelection(categoryKey, 1) end)

        row.preview = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.preview:SetSize(76, 22)
        row.preview:SetPoint("LEFT", row.next, "RIGHT", 9, 0)
        row.preview:SetText(T("Preview"))
        row.preview:SetScript("OnClick", function() addon:PreviewVoiceCategory(categoryKey) end)

        row.random = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.random:SetSize(72, 22)
        row.random:SetPoint("LEFT", row.preview, "RIGHT", 7, 0)
        row.random:SetText(T("Random"))
        row.random:SetScript("OnClick", function() addon:SetVoiceSelection(categoryKey, 0) end)

        voiceRows[categoryKey] = row
    end

    frame.resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.resetButton:SetSize(140, 25)
    frame.resetButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
    frame.resetButton:SetText(T("Reset all to Random"))
    frame.resetButton:SetScript("OnClick", function() addon:ResetVoiceSelections() end)

    frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.footer:SetPoint("LEFT", frame.resetButton, "RIGHT", 12, 0)
    frame.footer:SetWidth(420)
    frame.footer:SetJustifyH("LEFT")
    frame.footer:SetText(T("A selected line may be unavailable in some client locales; Preview lets you verify it."))

    frame:Hide()
    if UISpecialFrames then
        table.insert(UISpecialFrames, frame:GetName())
    end
    return frame
end

local function Atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end

    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    end

    return 0
end

local MINIMAP_BUTTON_OUTER_OFFSET = 10

local function GetMinimapButtonOrbitRadii()
    -- Do not use a fixed radius here. Edit Mode can resize the minimap, and a
    -- hard-coded value places the button over the map on larger layouts.
    -- Keep the button center slightly outside the current minimap edge so most
    -- of the icon lives outside the map, matching Blizzard-style edge buttons.
    local width = (Minimap and Minimap.GetWidth and Minimap:GetWidth()) or 140
    local height = (Minimap and Minimap.GetHeight and Minimap:GetHeight()) or 140

    if type(width) ~= "number" or width <= 0 then
        width = 140
    end
    if type(height) ~= "number" or height <= 0 then
        height = 140
    end

    return (width * 0.5) + MINIMAP_BUTTON_OUTER_OFFSET,
           (height * 0.5) + MINIMAP_BUTTON_OUTER_OFFSET
end

function addon:UpdateMinimapPosition()
    if not minimapButton or not DB or not Minimap then
        return
    end

    local radians = math.rad(DB.minimap.angle or 225)
    local radiusX, radiusY = GetMinimapButtonOrbitRadii()
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint(
        "CENTER",
        Minimap,
        "CENTER",
        math.cos(radians) * radiusX,
        math.sin(radians) * radiusY
    )
end

local function CreateMinimapButton()
    local button = CreateFrame("Button", "DKMentorMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- MiniMap-TrackingBorder artwork is intentionally offset inside its texture.
    -- Match Blizzard/LibDBIcon anchoring instead of centering the raw texture.
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetSize(53, 53)
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button.background = button:CreateTexture(nil, "BACKGROUND")
    button.background:SetSize(20, 20)
    button.background:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
    button.background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(20, 20)
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)
    button.icon:SetTexture(QUESTION_MARK_ICON)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints(button)
    button.highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button.highlight:SetBlendMode("ADD")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            if IsShiftKeyDown and IsShiftKeyDown() then
                addon:ToggleVoice()
            else
                addon:SetCoachEnabled(not DB.coach.enabled)
            end
        else
            addon:ToggleMainFrame()
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("DK Mentor")
        GameTooltip:AddLine(T("Left-click: open/close"), 1, 1, 1)
        GameTooltip:AddLine(T("Right-click: toggle survival coach"), 1, 1, 1)
        GameTooltip:AddLine(T("Shift-right-click: toggle Lich King commentary"), 1, 1, 1)
        GameTooltip:AddLine(T("Drag: move around the minimap"), 0.65, 0.8, 0.9)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local minimapX, minimapY = Minimap:GetCenter()
            local cursorX, cursorY = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cursorX = cursorX / scale
            cursorY = cursorY / scale
            local angle = math.deg(Atan2(cursorY - minimapY, cursorX - minimapX))
            DB.minimap.angle = angle
            addon:UpdateMinimapPosition()
        end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        addon:UpdateMinimapPosition()
    end)

    -- Edit Mode can resize the minimap after login. Recalculate the orbit when
    -- that happens so the DK Mentor button remains on the outer rim.
    if Minimap and Minimap.HookScript then
        Minimap:HookScript("OnSizeChanged", function()
            addon:UpdateMinimapPosition()
        end)
    end

    addon:UpdateMinimapPosition()
    if not DB.minimap.show then
        button:Hide()
    end
    return button
end

function addon:UpdateModeButtons()
    if not DB then return end
    if mainFrame and mainFrame.combatContextBar and mainFrame.combatContextBar.RefreshSelection then
        mainFrame.combatContextBar:RefreshSelection()
    end
    if mainFrame and mainFrame.loadoutContextBar and mainFrame.loadoutContextBar.RefreshSelection then
        mainFrame.loadoutContextBar:RefreshSelection()
    end
end

function addon:UpdateHeader()
    if not mainFrame then
        return
    end

    local specID, specName, specIcon = self:GetSpecInfo()
    local context = self:DetectActualContext()
    local contextName = (Data.contextNames and Data.contextNames[context]) or context

    mainFrame.specIcon:SetTexture(specIcon)
    mainFrame.subtitle:SetText(T(
        "Specialization: %s • Content: %s (%s)",
        specName,
        contextName,
        T("automatic")
    ))

    if minimapButton and minimapButton.icon then
        minimapButton.icon:SetTexture(specIcon)
    end

    self.currentSpecID = specID
    self.currentContext = context
end

function addon:CanMoveHUDs()
    return DB and DB.hudLocked == false and not InCombatLockdown()
end

function addon:IsPlayerInCombat()
    -- PLAYER_REGEN_* remains the primary latch, but zone/loading transitions can
    -- leave a stale TRUE behind. If both public combat signals explicitly say
    -- "out of combat", heal the latch instead of keeping combat-only HUDs stuck.
    local unitCombat
    local lockdown

    if UnitAffectingCombat then
        local ok, rawValue = pcall(UnitAffectingCombat, "player")
        unitCombat = GetAccessibleBooleanFromCall(ok, rawValue)
    end
    if InCombatLockdown then
        local ok, rawValue = pcall(InCombatLockdown)
        lockdown = GetAccessibleBooleanFromCall(ok, rawValue)
    end

    if self.combatEventState == true then
        if unitCombat == false and lockdown == false then
            self.combatEventState = false
            return false
        end
        return true
    elseif self.combatEventState == false then
        return false
    end

    if unitCombat ~= nil then
        return unitCombat
    end
    if lockdown ~= nil then
        return lockdown
    end
    return false
end

function addon:SyncCombatEventState()
    local unitCombat
    local lockdown
    if UnitAffectingCombat then
        local ok, rawValue = pcall(UnitAffectingCombat, "player")
        unitCombat = GetAccessibleBooleanFromCall(ok, rawValue)
    end
    if InCombatLockdown then
        local ok, rawValue = pcall(InCombatLockdown)
        lockdown = GetAccessibleBooleanFromCall(ok, rawValue)
    end

    if unitCombat == true or lockdown == true then
        self.combatEventState = true
    elseif unitCombat == false and lockdown == false then
        self.combatEventState = false
    else
        self.combatEventState = nil
    end
    return self:IsPlayerInCombat()
end

function addon:ShouldShowCombatBar(config)
    -- Preview is a hard layout override. It intentionally ignores both the
    -- individual ON/OFF toggle and Bars only in combat so every combat HUD can
    -- be positioned and resized safely while the player is out of combat.
    if self.hudPreviewMode == true then
        return true
    end
    if not config or config.enabled ~= true then
        return false
    end
    if DB and DB.combatBarsOnlyInCombat == true then
        return self:IsPlayerInCombat()
    end
    return true
end

function addon:SetCombatBarsOnlyInCombat(enabled)
    if not DB then return end
    DB.combatBarsOnlyInCombat = enabled == true
    self:RefreshCombatHUDVisibility()
    self:UpdateHUDSettings()
    Print(T(DB.combatBarsOnlyInCombat and "Combat bars and resources now show only in combat." or "Combat bars and resources can now show outside combat."))
end

function addon:UpdateHUDMoveHints()
    if not DB then return end
    local editing = (DB.hudLocked == false) or self.hudPreviewMode == true
    local text = DB.hudLocked and "" or T("Drag to move")
    if coachFrame and coachFrame.dragHint then coachFrame.dragHint:SetText(text) end
    if buffFrame and buffFrame.dragHint then buffFrame.dragHint:SetText(text) end
    if externalBuffFrame and externalBuffFrame.dragHint then externalBuffFrame.dragHint:SetText(text) end
    if debuffFrame and debuffFrame.dragHint then debuffFrame.dragHint:SetText(text) end
    if abilityFrame and abilityFrame.dragHint then abilityFrame.dragHint:SetText(text) end
    if resourceFrame and resourceFrame.dragHint then resourceFrame.dragHint:SetText(text) end
    if resourceArcFrame and resourceArcFrame.dragHint then resourceArcFrame.dragHint:SetText("") end
    if resourceArcFrame and resourceArcFrame.dragHandle then resourceArcFrame.dragHandle:Hide() end
    if resourceArcFrame then resourceArcFrame:EnableMouse(editing) end
    UpdateManagedAuraBarChrome(buffFrame)
    UpdateManagedAuraBarChrome(externalBuffFrame)
    UpdateManagedAuraBarChrome(debuffFrame)
end

function addon:SetHUDsLocked(locked)
    if not DB then return end
    DB.hudLocked = locked == true
    self:UpdateHUDMoveHints()
    self:UpdateHUDSettings()
    Print(T(DB.hudLocked and "Combat HUDs locked." or "Combat HUDs unlocked. Drag them to arrange the interface."))
end

function addon:ToggleHUDLock()
    self:SetHUDsLocked(not DB.hudLocked)
end

function addon:ToggleHUDPreview()
    if InCombatLockdown and InCombatLockdown() then
        Print(T("HUD preview cannot be changed during combat."))
        return
    end
    self.hudPreviewMode = not (self.hudPreviewMode == true)
    self:RefreshCoachVisibility()
    self:RefreshStatusWidgetVisibility()
    self:RefreshCombatHUDVisibility()
    self:UpdateHUDSettings()
    self:UpdateBarLayoutFrame()
end

function addon:SetCoachEnabled(enabled)
    if not DB or not DB.coach then return end
    DB.coach.enabled = enabled == true
    self:RefreshCoachVisibility()
    self:UpdateSurvivalTips()
    self:UpdateHUDSettings()
    Print(T(DB.coach.enabled and "Survival coach HUD enabled." or "Survival coach HUD disabled."))
end

function addon:SetStatusWidgetEnabled(enabled)
    if not DB or not DB.statusWidget then return end
    DB.statusWidget.enabled = enabled == true
    if not DB.statusWidget.enabled and specializationPickerFrame then
        specializationPickerFrame:Hide()
    end
    self:RefreshStatusWidgetVisibility()
    self:UpdateBuildSection()
    self:UpdateHUDSettings()
    Print(T(DB.statusWidget.enabled and "Build HUD enabled." or "Build HUD disabled."))
end

function addon:UpdateStatusWidget()
    if not statusWidget or not DB or not self.active then
        return
    end

    self:SyncPendingLoadoutState(false)

    local specID, _, specIcon = self:GetSpecInfo()
    local context = self:DetectActualContext()
    local contextName = self:GetRuntimeContextLabel(context)
    local profile = self:GetSelectedBuild(specID, context)
    local activeID, activeName = self:GetActiveLoadoutInfo(specID)
    local binding, _, loadoutMode = self:ResolveRuntimeLoadoutBinding(specID, context)
    local equipmentBinding, equipmentInfo, equipmentMode = self:ResolveRuntimeEquipmentBinding(specID, context)

    statusWidget.icon:SetTexture(specIcon or QUESTION_MARK_ICON)
    statusWidget.title:SetText(tostring(contextName))

    local buildText
    if activeName and activeName ~= "" then
        buildText = T("Build: %s", tostring(activeName))
        if loadoutMode == "keep" or (type(binding) == "table" and binding.configID == activeID) then
            buildText = "|cff66ff99" .. T("Build: %s", tostring(activeName)) .. "|r"
        end
    elseif loadoutMode == "keep" then
        buildText = "|cff66ff99" .. T("Build: current") .. "|r"
    elseif type(binding) == "table" and binding.name then
        buildText = T("Build: %s", tostring(binding.name))
    elseif type(profile) == "table" and profile.name then
        buildText = T("Guide: %s", tostring(profile.name))
    else
        buildText = T("Build: not detected")
    end
    statusWidget.build:SetText(buildText)

    local gearText = T("Gear: not bound")
    if equipmentMode == "keep" then
        gearText = "|cff66ff99" .. T("Gear: current") .. "|r"
        for _, info in ipairs(self:GetEquipmentSetList()) do
            if info.isEquipped then
                gearText = "|cff66ff99" .. T("Gear: %s", tostring(info.name)) .. "|r"
                break
            end
        end
    elseif type(equipmentBinding) == "table" then
        if equipmentInfo then
            if equipmentInfo.isEquipped then
                gearText = "|cff66ff99" .. T("Gear: %s", tostring(equipmentInfo.name)) .. "|r"
            elseif equipmentInfo.numLost > 0 then
                gearText = "|cffffcc55" .. T("Gear: %s", T("%s (%d missing)", tostring(equipmentInfo.name), equipmentInfo.numLost)) .. "|r"
            else
                gearText = T("Gear: %s", tostring(equipmentInfo.name))
            end
        else
            gearText = "|cffff7777" .. T("Gear: saved set missing") .. "|r"
        end
    end
    statusWidget.gear:SetText(gearText)

    -- Auto-switch state remains available in Settings; the compact HUD omits it.
    statusWidget.auto:SetText("")

    local readyStatus = self:GetReadyCheckStatus()
    if statusWidget.ready then
        local color = readyStatus.ready and "|cff66ff99" or (readyStatus.hardIssue and "|cffff7777" or "|cffffcc55")
        statusWidget.ready:SetText(color .. tostring(readyStatus.summary or T("Ready Check unavailable")) .. "|r")
    end

    LayoutStatusWidget()
end

function addon:RefreshStatusWidgetVisibility()
    if not statusWidget or not DB or not self.active then
        return
    end
    if (DB.statusWidget and DB.statusWidget.enabled) or self.hudPreviewMode == true then
        statusWidget:Show()
        self:UpdateStatusWidget()
    else
        statusWidget:Hide()
        if specializationPickerFrame then specializationPickerFrame:Hide() end
    end
end

function addon:UpdateVoiceConfigFrame()
    if not voiceConfigFrame or not DB or not DB.voice then
        return
    end
    for category, row in pairs(voiceRows) do
        if row and row.selection then
            local selection = self:GetVoiceSelection(category)
            row.selection:SetText(self:GetVoiceSelectionText(category))
            if selection == -1 then
                row.selection:SetTextColor(0.75, 0.75, 0.75)
            elseif selection == 0 then
                row.selection:SetTextColor(0.45, 0.85, 1)
            else
                row.selection:SetTextColor(1, 0.82, 0)
            end
            row.preview:SetEnabled(PlaySoundFile ~= nil and selection ~= -1)
        end
    end
end

function addon:ToggleVoiceConfigFrame()
    if not voiceConfigFrame then return end
    if voiceConfigFrame:IsShown() then
        voiceConfigFrame:Hide()
    else
        voiceConfigFrame:Show()
        self:UpdateVoiceConfigFrame()
    end
end

function addon:UpdateAssistedCombatSection()
    if not mainFrame or not mainFrame.offenseSection then
        return
    end

    local available, reason = self:GetAssistedCombatAvailability()
    local enabled = GetCVarBoolSafe("assistedCombatHighlight")
    local status

    if available and enabled then
        status = "|cff66ff99" .. T("Native highlight enabled.") .. "|r " .. T("Follow the blue glow on your action bars for the next offensive ability.")
    elseif available then
        status = "|cffffcc55" .. T("Native highlight disabled.") .. "|r " .. T("Enable it to receive the offensive recommendation provided by the game client.")
    else
        status = "|cffff7777" .. T("Native combat assistant is currently unavailable.") .. "|r"
        if reason and reason ~= "" then
            status = status .. " " .. tostring(reason)
        end
    end

    if self.coverageText and self.coverageText ~= "" then
        status = status .. "\n" .. self.coverageText
    end

    mainFrame.offenseSection.status:SetText(status)
    mainFrame.offenseSection.toggleButton:SetText(T(enabled and "Disable native highlight" or "Enable native highlight"))
end

function addon:UpdateBuildSection()
    if not mainFrame or not mainFrame.buildSection then
        return
    end

    local context = self:GetBuildConfigContext()
    local specID, specName = self:GetBuildConfigSpecInfo(context)
    local contextName = (Data.contextNames and Data.contextNames[context]) or context
    local profile, index, profiles = self:GetSelectedBuild(specID, context)
    local build = mainFrame.buildSection
    if build.title then
        build.title:SetText(T("Loadouts — %s / %s", tostring(specName), tostring(contextName)))
    end
    local configuredSpecID = self:GetContentSpecializationBinding(context)
    if build.specButton then
        if configuredSpecID then
            build.specButton:SetText(T("Specialization: %s", tostring(specName)))
        else
            build.specButton:SetText(T("Do not change (%s)", tostring(specName)))
        end
    end

    if not profile then
        build.name:SetText(T("No build focus is available for this specialization."))
        build.note:SetText(T("Select Blood, Frost, or Unholy and refresh the interface."))
        build.source:SetText("")
        build.sourceURLBox:SetText("")
        build.sourceURLBox:SetEnabled(false)
        build.sourceButton:SetEnabled(false)
        build.codeBox:SetText("")
        build.profileHint:SetText("")
        build.loadoutStatus:SetText(T("No saved WoW loadout"))
        build.equipmentStatus:SetText(T("No saved equipment set"))
        if build.autoSpecButton then build.autoSpecButton:SetText(T(DB.autoSwitchSpecialization and "Spec AUTO: ON" or "Spec AUTO: OFF")) end
        build.autoSwitchButton:SetText(T(DB.autoSwitchLoadouts and "Talents AUTO: ON" or "Talents AUTO: OFF"))
        build.autoEquipmentButton:SetText(T(DB.autoSwitchEquipment and "Gear AUTO: ON" or "Gear AUTO: OFF"))
        if build.hudButton then build.hudButton:SetText(T(DB.statusWidget.enabled and "Build HUD: ON" or "Build HUD: OFF")) end
        build.index:SetText("0/0")
        build.previousButton:SetEnabled(false)
        build.nextButton:SetEnabled(false)
        build.selectButton:SetEnabled(false)
        build.clearButton:SetEnabled(false)
        build.saveLoadoutButton:SetEnabled(false)
        build.clearLoadoutButton:SetEnabled(false)
        if mainFrame.loadoutContextBar and mainFrame.loadoutContextBar.RefreshSelection then
            mainFrame.loadoutContextBar:RefreshSelection()
        end
        build.saveEquipmentButton:SetEnabled(false)
        build.clearEquipmentButton:SetEnabled(false)
        return
    end

    local codeKey = self:GetPersonalBuildCodeKey(specID, context, index)
    local savedCode = DB.personalBuildCodes[codeKey] or ""

    build.name:SetText(profile.name or T("Build recommendation"))
    build.note:SetText(profile.note or "")
    local reviewSuffix = ""
    if profile.reviewedPatch or profile.reviewedDate then
        reviewSuffix = T(" • reviewed for %s on %s", profile.reviewedPatch or "?", profile.reviewedDate or "?")
    end
    build.source:SetText((profile.source or "DK Mentor") .. reviewSuffix .. T(" • data package %s", tostring(Data.dataVersion or "?")))
    build.sourceURLBox:SetText(profile.sourceURL or T("No external source URL for this profile"))
    build.sourceURLBox:SetCursorPosition(0)
    build.sourceURLBox:SetEnabled(profile.sourceURL ~= nil)
    build.sourceButton:SetEnabled(profile.sourceURL ~= nil)
    if not build.codeBox:HasFocus() then
        build.codeBox:SetText(savedCode)
        build.codeBox:SetCursorPosition(0)
    end

    if profile.pvp then
        build.profileHint:SetText("|cff89d8ff" .. T("PvP guide:") .. "|r " .. profile.pvp)
    elseif savedCode == "" then
        build.profileHint:SetText("|cff89d8ff" .. T("Guide code:") .. "|r " .. T("Copy the current import code from the cited guide and save it here if you want a local reference."))
    else
        build.profileHint:SetText("|cff89d8ff" .. T("Guide code:") .. "|r " .. T("Saved locally. Import it into WoW, save that WoW loadout, then bind it below."))
    end

    local binding, loadoutInfo = self:ResolveLoadoutBinding(specID, context)
    if type(binding) == "table" and binding.configID then
        local color = (loadoutInfo and loadoutInfo.isActive) and "|cff66ff99" or "|cffffcc55"
        build.loadoutStatus:SetText(color .. T("DKM loadout:") .. "|r " .. tostring(binding.name or binding.configID))
    else
        build.loadoutStatus:SetText("|cffffcc55" .. T("DKM loadout: none") .. "|r")
    end

    local equipmentBinding, equipmentInfo = self:ResolveEquipmentBinding(specID, context)
    if type(equipmentBinding) == "table" then
        if equipmentInfo then
            if equipmentInfo.isEquipped then
                build.equipmentStatus:SetText("|cff66ff99" .. T("Gear:") .. "|r " .. tostring(equipmentInfo.name))
            elseif equipmentInfo.numLost > 0 then
                build.equipmentStatus:SetText("|cffffcc55" .. T("Gear:") .. "|r " .. T("%s (%d missing)", tostring(equipmentInfo.name), equipmentInfo.numLost))
            else
                build.equipmentStatus:SetText("|cffffcc55" .. T("Gear:") .. "|r " .. tostring(equipmentInfo.name))
            end
        else
            build.equipmentStatus:SetText("|cffff7777" .. T("Gear set missing") .. "|r")
        end
    else
        build.equipmentStatus:SetText("|cffffcc55" .. T("Gear: none") .. "|r")
    end

    if build.autoSpecButton then build.autoSpecButton:SetText(T(DB.autoSwitchSpecialization and "Spec AUTO: ON" or "Spec AUTO: OFF")) end
    build.autoSwitchButton:SetText(T(DB.autoSwitchLoadouts and "Talents AUTO: ON" or "Talents AUTO: OFF"))
    build.autoEquipmentButton:SetText(T(DB.autoSwitchEquipment and "Gear AUTO: ON" or "Gear AUTO: OFF"))
    build.autoHint:SetText(T("This profile is specific to %s / %s. DK Mentor can switch specialization, talents, and equipment automatically when their AUTO options are enabled. Dungeon overrides can also set Loot Spec independently.", tostring(specName), tostring(contextName)))
    if build.hudButton then build.hudButton:SetText(T(DB.statusWidget.enabled and "Build HUD: ON" or "Build HUD: OFF")) end
    if mainFrame.loadoutContextBar and mainFrame.loadoutContextBar.RefreshSelection then
        mainFrame.loadoutContextBar:RefreshSelection()
    end
    build.saveLoadoutButton:SetEnabled(true)
    build.clearLoadoutButton:SetEnabled(type(binding) == "table")
    build.saveEquipmentButton:SetEnabled(true)
    build.clearEquipmentButton:SetEnabled(type(equipmentBinding) == "table")

    build.index:SetText(string.format("%d/%d", index, #profiles))
    build.previousButton:SetEnabled(#profiles > 1)
    build.nextButton:SetEnabled(#profiles > 1)
    build.selectButton:SetEnabled(true)
    build.clearButton:SetEnabled(savedCode ~= "")
end

function addon:UpdateLoadoutPicker()
    if not loadoutPickerFrame or not DB then return end
    local specID, specName, specIcon, context, dungeonKey = self:GetLoadoutPickerSpecInfo()
    local contextName = (Data.contextNames and Data.contextNames[context]) or context
    local mappedInfo
    if dungeonKey then
        local override = self:GetDungeonOverride(dungeonKey)
        if type(override) == "table" and override.loadoutMode == "override" then
            _, mappedInfo = self:ResolveDungeonOverrideLoadout(override, specID)
        end
        local dungeonName = override and override.name or T("Dungeon override")
        loadoutPickerFrame.subtitle:SetText(T("Choose a WoW talent loadout for the %s override (%s).", tostring(dungeonName), tostring(specName)))
    else
        _, mappedInfo = self:ResolveLoadoutBinding(specID, context)
        loadoutPickerFrame.subtitle:SetText(T("Map an existing WoW talent loadout to %s / %s. This mapping is used by Talents AUTO.", tostring(specName), tostring(contextName)))
    end

    local loadouts = self:GetLoadoutList(specID)
    for index, row in ipairs(loadoutRows) do
        local info = loadouts[index]
        if info then
            row.configID = info.configID
            row.icon:SetTexture(specIcon or QUESTION_MARK_ICON)
            row.name:SetText(info.name or T("Loadout %s", tostring(info.configID)))
            local status = ""
            if mappedInfo and mappedInfo.configID == info.configID then
                status = "|cff66ff99" .. T("MAPPED") .. "|r"
                if info.isActive then status = status .. " • " .. "|cff89d8ff" .. T("ACTIVE") .. "|r" end
            elseif info.isActive then
                status = "|cff89d8ff" .. T("ACTIVE") .. "|r"
            end
            row.status:SetText(status)
            row:Show()
        else
            row.configID = nil
            row:Hide()
        end
    end

    if loadoutPickerFrame.currentButton then
        loadoutPickerFrame.currentButton:SetEnabled(select(1, self:GetSpecInfo()) == specID)
    end
    if loadoutPickerFrame.createButton then
        loadoutPickerFrame.createButton:SetEnabled(dungeonKey == nil and select(1, self:GetSpecInfo()) == specID)
    end
    if #loadouts == 0 then
        loadoutPickerFrame.footer:SetText(T("No saved WoW talent loadouts were found for this specialization."))
    elseif dungeonKey then
        loadoutPickerFrame.footer:SetText(T("Choosing a loadout overrides only talents for this dungeon. Other values can still inherit the Dungeon profile."))
    else
        loadoutPickerFrame.footer:SetText(T("Click a saved WoW loadout to map it. The same loadout can be reused for multiple content types."))
    end
end

function addon:OpenLoadoutPicker(target)
    if not loadoutPickerFrame then return end
    self.loadoutPickerTarget = target
    self:UpdateLoadoutPicker()
    loadoutPickerFrame:Show()
    loadoutPickerFrame:Raise()
end

function addon:UpdateEquipmentPicker()
    if not equipmentPickerFrame or not DB then return end

    local specID, specName, context, dungeonKey = self:GetEquipmentPickerTargetInfo()
    local contextName = (Data.contextNames and Data.contextNames[context]) or context
    local mappedInfo
    if dungeonKey then
        local override = self:GetDungeonOverride(dungeonKey)
        if type(override) == "table" and override.equipmentMode == "override" then
            _, mappedInfo = self:ResolveDungeonOverrideEquipment(override)
        end
        local dungeonName = override and override.name or T("Dungeon override")
        equipmentPickerFrame.subtitle:SetText(T("Choose a WoW Equipment Set for the %s override (%s).", tostring(dungeonName), tostring(specName)))
    else
        _, mappedInfo = self:ResolveEquipmentBinding(specID, context)
        equipmentPickerFrame.subtitle:SetText(T("Map an existing WoW Equipment Set to %s / %s. This mapping is used by Gear AUTO.", tostring(specName), tostring(contextName)))
    end

    local sets = self:GetEquipmentSetList()
    for index, row in ipairs(equipmentRows) do
        local info = sets[index]
        if info then
            row.setID = info.setID
            row.icon:SetTexture(info.iconFileID or QUESTION_MARK_ICON)
            row.name:SetText(info.name or T("Equipment Set %s", tostring(info.setID)))
            local status = ""
            if mappedInfo and mappedInfo.setID == info.setID then
                status = "|cff66ff99" .. T("MAPPED") .. "|r"
            elseif info.isEquipped then
                status = "|cff89d8ff" .. T("EQUIPPED") .. "|r"
            elseif info.numLost > 0 then
                status = "|cffffcc55" .. T("%d missing", info.numLost) .. "|r"
            else
                status = T("%d/%d equipped", info.numEquipped or 0, info.numItems or 0)
            end
            row.status:SetText(status)
            row:Show()
        else
            row.setID = nil
            row:Hide()
        end
    end

    if #sets == 0 then
        equipmentPickerFrame.footer:SetText(T("No saved WoW Equipment Sets were found. Create one in the Character > Equipment Manager first."))
    elseif dungeonKey then
        equipmentPickerFrame.footer:SetText(T("Choosing a set overrides only gear for this dungeon. Other values can still inherit the Dungeon profile."))
    else
        equipmentPickerFrame.footer:SetText(T("Click a saved WoW set to map it. DK Mentor does not duplicate it."))
    end
end

function addon:OpenEquipmentPicker(target)
    if not equipmentPickerFrame then return end
    self.equipmentPickerTarget = target
    self:UpdateEquipmentPicker()
    equipmentPickerFrame:Show()
    equipmentPickerFrame:Raise()
end

function addon:UpdateVoiceSection()
    if not mainFrame or not mainFrame.voiceSection or not DB or not DB.voice then
        return
    end

    local section = mainFrame.voiceSection
    local config = self:GetVoiceFrequencyConfig()
    local locale = GetClientLocale()
    local enabledText = DB.voice.enabled and ("|cff66ff99" .. T("Enabled") .. "|r") or ("|cffffcc55" .. T("Disabled") .. "|r")
    local pvpText = T(DB.voice.allowInPvP and "on" or "off")
    local situationalText = T(DB.voice.situational and "on" or "off")
    local lastText = lastVoiceCategory and T(" • last: %s", tostring((Voices.categoryLabels and Voices.categoryLabels[lastVoiceCategory]) or lastVoiceCategory)) or ""

    section.status:SetText(T(
        "%s • locale: %s • PvP: %s • situations: %s%s",
        enabledText,
        locale,
        pvpText,
        situationalText,
        lastText
    ) .. "\n" .. T("Uses installed WoW voice resources; no audio files are bundled."))
    section.toggleButton:SetText(T(DB.voice.enabled and "Disable commentary" or "Enable commentary"))
    section.frequencyButton:SetText(T("Frequency: %s", tostring(config.label or DB.voice.frequency)))
    section.previewButton:SetEnabled(PlaySoundFile ~= nil)
    section.situationalButton:SetText(T(DB.voice.situational and "Situations: ON" or "Situations: OFF"))
    if section.mapButton then section.mapButton:SetEnabled(PlaySoundFile ~= nil) end
    self:UpdateVoiceConfigFrame()
end

function addon:UpdateSurvivalTips()
    if not mainFrame then
        return
    end

    local specID, specName = self:GetSpecInfo()
    local context = select(1, self:DetectContext())
    local contextName = (Data.contextNames and Data.contextNames[context]) or context
    local specTips = Data.tips and Data.tips[specID]
    local generalTips = Data.tips and Data.tips.general
    local tips = (specTips and (specTips[context] or specTips.world)) or (generalTips and (generalTips[context] or generalTips.world)) or {}

    for index, row in ipairs(tipRows) do
        local tip = tips[index]
        if tip then
            local spellName, spellIcon = GetSpellData(tip.spellID, tip.fallbackName)
            local known = IsSpellKnownSafe(tip.spellID)
            local suffix = tip.optional and not known and (" |cff999999" .. T("(talent)") .. "|r") or ""

            row.spellID = tip.spellID
            row.spellName = spellName
            row.icon:SetTexture(spellIcon)
            row.tag:SetText(tip.tag or "TIP")
            row.name:SetText(spellName .. suffix)
            row.description:SetText(tip.text or "")
            row:Show()
        else
            row.spellID = nil
            row:Hide()
        end
    end

    if mainFrame.survivalSection and mainFrame.survivalSection.title then
        mainFrame.survivalSection.title:SetText(T("Survival — %s / %s", tostring(specName), tostring(contextName)))
    end
end

function addon:GetAdaptiveCoachEntries(specID, context, baseEntries)
    if not DB or not DB.coach or DB.coach.adaptiveHealth == false then
        return baseEntries, nil, nil
    end

    local health = GetPlayerHealthPercent()
    if not health then
        return baseEntries, nil, nil
    end

    local S = Data.spells or {}
    local result = {}
    local state = "STABLE"

    local function Add(spellID, title, whenText, optional, fallbackName)
        if not spellID or #result >= 3 then
            return
        end
        for _, existing in ipairs(result) do
            if existing.spellID == spellID then
                return
            end
        end
        table.insert(result, {
            spellID = spellID,
            title = T(title),
            when = T(whenText),
            optional = optional == true,
            fallbackName = T(fallbackName or "Ability"),
        })
    end

    if health <= 30 then
        state = "CRITICAL"
        if specID == 250 then
            Add(S.VAMPIRIC_BLOOD, "USE NOW", "critical health")
            Add(S.DEATH_STRIKE, "RECOVER", "heal immediately")
            Add(S.ICEBOUND_FORTITUDE, "EMERGENCY", "if pressure continues")
        else
            Add(S.ICEBOUND_FORTITUDE, "USE NOW", "critical health")
            Add(S.DEATH_STRIKE, "RECOVER", "heal immediately")
            Add(S.DEATH_PACT, "PANIC", "if talented / needed", true)
        end
    elseif health <= 50 then
        state = "DANGER"
        Add(S.DEATH_STRIKE, "USE NOW", "recover recent damage")
        if specID == 250 then
            Add(S.VAMPIRIC_BLOOD, "DEFENSIVE", "if health keeps falling")
            Add(S.RUNE_TAP, "MITIGATE", "before the next hit", true)
        else
            Add(S.ICEBOUND_FORTITUDE, "DEFENSIVE", "if pressure continues")
            Add(S.DEATH_PACT, "BACKUP HEAL", "if talented / needed", true)
        end
    elseif health <= 70 then
        state = "RECOVER"
        Add(S.DEATH_STRIKE, "RECOVER", "after meaningful damage")
        if specID == 250 then
            Add(S.RUNE_TAP, "PREPARE", "before another heavy hit", true)
            Add(S.VAMPIRIC_BLOOD, "HOLD READY", "for sustained pressure")
        else
            Add(S.ANTI_MAGIC_SHELL, "MAGIC", "before incoming magic")
            Add(S.ICEBOUND_FORTITUDE, "HOLD READY", "for a bigger spike")
        end
    else
        for _, entry in ipairs(baseEntries or {}) do
            if #result >= 3 then
                break
            end
            table.insert(result, entry)
        end
    end

    if #result < 3 then
        for _, entry in ipairs(baseEntries or {}) do
            if #result >= 3 then
                break
            end
            Add(entry.spellID, entry.title, entry.when, entry.optional, entry.fallbackName)
        end
    end

    return result, health, state
end

function addon:UpdateCoach()
    if not coachFrame then
        return
    end

    local specID, specName = self:GetSpecInfo()
    local context = select(1, self:DetectContext())
    local contextName = (Data.contextNames and Data.contextNames[context]) or context
    local specCoach = Data.coach and Data.coach[specID]
    local generalCoach = Data.coach and Data.coach.general
    local baseEntries = (specCoach and (specCoach[context] or specCoach.world)) or (generalCoach and (generalCoach[context] or generalCoach.world)) or {}
    local entries, health, state = self:GetAdaptiveCoachEntries(specID, context, baseEntries)

    coachFrame.title:SetText(string.format("DK Mentor — %s / %s", specName, contextName))
    if health then
        coachFrame.healthText:SetText(T("Health: %d%% • %s", math.floor(health + 0.5), T(state or "")))
    else
        coachFrame.healthText:SetText("")
    end

    for index, card in ipairs(coachCards) do
        local entry = entries[index]
        if entry then
            local spellName, spellIcon = GetSpellData(entry.spellID, entry.fallbackName)
            local known = IsSpellKnownSafe(entry.spellID)
            local suffix = entry.optional and not known and (" " .. T("(talent)")) or ""

            card.spellID = entry.spellID
            card.spellName = spellName
            card.icon:SetTexture(spellIcon)
            card.action:SetText(entry.title or T("USE"))
            card.spell:SetText(spellName .. suffix)
            card.when:SetText(entry.when or "")
            if index == 1 and health and health <= 70 then
                card:SetBackdropColor(0.10, 0.18, 0.22, 0.96)
                card:SetBackdropBorderColor(0.95, 0.72, 0.18, 1)
            else
                card:SetBackdropColor(0.025, 0.08, 0.11, 0.82)
                card:SetBackdropBorderColor(0.16, 0.47, 0.62, 0.85)
            end
            card:Show()
        else
            card.spellID = nil
            card:Hide()
        end
    end
end

function addon:RefreshCoachVisibility()
    if not coachFrame or not DB or not self.active then
        return
    end

    local preview = self.hudPreviewMode == true
    local shouldShow = preview or DB.coach.enabled
    if shouldShow and not preview and DB.coach.onlyInCombat then
        shouldShow = InCombatLockdown() or UnitAffectingCombat("player")
    end

    if shouldShow then
        coachFrame:Show()
        self:UpdateCoach()
    else
        coachFrame:Hide()
    end
end

local function GetPlayerAuraDataSingleSafe(spellID)
    if not spellID then
        return nil
    end

    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        -- In Midnight some aura results may be secret/tainted in restricted
        -- contexts. Never branch on a returned value before accessibility is
        -- confirmed; Blizzard's own Cooldown Viewer mirror remains our combat
        -- fallback when direct aura data is unavailable.
        if ok and IsAccessibleValue(aura) and type(aura) == "table" then
            return aura
        end
    end

    if AuraUtil and AuraUtil.FindAuraBySpellID then
        local ok, name, icon, count, _, duration, expirationTime, source, _, _, auraSpellID = pcall(AuraUtil.FindAuraBySpellID, spellID, "player", "HELPFUL")
        if ok and IsAccessibleValue(name) then
            return {
                name = name,
                icon = icon,
                applications = count,
                duration = duration,
                expirationTime = expirationTime,
                sourceUnit = source,
                spellId = IsAccessibleNumber(auraSpellID) and auraSpellID or spellID,
            }
        end
    end

    return nil
end

local function GetPlayerAuraDataSafe(spellID)
    if not spellID then
        return nil
    end

    -- Prefer the canonical spell ID, then try any current-client aliases.
    -- This is important for spells such as Breath of Sindragosa, whose
    -- Midnight 12.1 implementation uses a newer aura/cast spell ID while the
    -- historic/base spell ID can still be returned by other APIs.
    local aura = GetPlayerAuraDataSingleSafe(spellID)
    if aura then
        return aura
    end

    local aliases = Data.buffAuraAliases and Data.buffAuraAliases[spellID]
    for _, aliasSpellID in ipairs(aliases or {}) do
        if aliasSpellID ~= spellID then
            aura = GetPlayerAuraDataSingleSafe(aliasSpellID)
            if aura then
                return aura
            end
        end
    end

    return nil
end

local function InvalidateCooldownManagerProfileCache()
    for key in pairs(cooldownManagerProfileCache) do
        cooldownManagerProfileCache[key] = nil
    end
end

local function GetCooldownManagerProfileCooldownIDSet(specID, kind)
    local result = {}
    local profile = Data.cooldownManagerProfiles and Data.cooldownManagerProfiles[specID]
    if type(profile) ~= "table" then return result end

    local function Add(list)
        for _, cooldownID in ipairs(list or {}) do
            if IsAccessibleNumber(cooldownID) then result[cooldownID] = true end
        end
    end

    if kind == "buff" then
        Add(profile.trackedBuffCooldownIDs)
        Add(profile.trackedBarCooldownIDs)
    elseif kind == "ability" then
        Add(profile.essentialCooldownIDs)
    else
        Add(profile.trackedBuffCooldownIDs)
        Add(profile.trackedBarCooldownIDs)
        Add(profile.essentialCooldownIDs)
    end
    return result
end

local function GetCachedCooldownViewerDisplayData()
    -- IMPORTANT: GetDisplayData() is a passive accessor. Do not call
    -- GetCooldownInfoForID/CheckBuildDisplayData here because those paths can
    -- invoke C_CooldownViewer functions with AllowedWhenUntainted secret args.
    local provider = _G.CooldownViewerDataProvider
    if not provider or type(provider.GetDisplayData) ~= "function" then
        return nil
    end
    local ok, displayData = pcall(provider.GetDisplayData, provider)
    if ok and IsAccessibleValue(displayData) and type(displayData) == "table" then
        return displayData
    end
    return nil
end

local function GetCachedCooldownViewerInfo(cooldownID)
    if not IsAccessibleNumber(cooldownID) then return nil end
    local displayData = GetCachedCooldownViewerDisplayData()
    if not displayData then return nil end
    local infoByID = displayData.cooldownInfoByID
    if type(infoByID) ~= "table" then return nil end
    local info = infoByID[cooldownID]
    if IsAccessibleValue(info) and type(info) == "table" then return info end
    return nil
end

local function CollectCooldownInfoSpellIDs(info, output, seen)
    if type(info) ~= "table" then return end
    local function Add(value)
        if IsAccessibleNumber(value) and not seen[value] then
            seen[value] = true
            table.insert(output, value)
        end
    end

    -- Prefer the same order Blizzard uses for display resolution, while also
    -- retaining every associated ID because the active aura can be a linked
    -- spell rather than the action's base spell.
    Add(info.linkedSpellID)
    Add(info.overrideTooltipSpellID)
    Add(info.overrideSpellID)
    if type(info.linkedSpellIDs) == "table" then
        for _, spellID in ipairs(info.linkedSpellIDs) do Add(spellID) end
    end
    Add(info.spellID)
end

local function BuildCooldownManagerProfileSpellList(kind, specID)
    local key = tostring(specID or 0) .. ":" .. tostring(kind or "buff")
    local cached = cooldownManagerProfileCache[key]
    if cached then return cached end

    local ids = GetCooldownManagerProfileCooldownIDSet(specID, kind)
    local result, seen = {}, {}
    local resolvedAny = false
    for cooldownID in pairs(ids) do
        local info = GetCachedCooldownViewerInfo(cooldownID)
        if info then
            resolvedAny = true
            CollectCooldownInfoSpellIDs(info, result, seen)
        end
    end

    -- Only cache a resolved result. If Blizzard has not built its provider yet,
    -- a later COOLDOWN_VIEWER_DATA_LOADED refresh gets another chance.
    if resolvedAny then cooldownManagerProfileCache[key] = result end
    return result
end

local function BuildTrackingList(kind, specID)
    local source = kind == "buff" and Data.buffTracking or Data.abilityTracking
    local result = {}
    local seen = {}

    local function AddList(list)
        for _, entry in ipairs(list or {}) do
            local spellID = type(entry) == "table" and entry.spellID or entry
            if spellID and not seen[spellID] then
                local include = true
                if kind == "ability" then
                    include = IsSpellKnownSafe(spellID)
                end
                if include then
                    seen[spellID] = true
                    table.insert(result, entry)
                end
            end
        end
    end

    AddList(source and source[specID])
    AddList(source and source.general)

    -- Augment the curated fallback with the spell/linked-aura IDs resolved from
    -- the current Wowhead Cooldown Manager profile IDs. This allows Midnight
    -- hotfix/override spell IDs to follow Blizzard data without hard-coding
    -- every internal spell variant in DK Mentor.
    AddList(BuildCooldownManagerProfileSpellList(kind, specID))
    return result
end

local function BuildDKBuffIncludeSpellIDs(specID)
    local includeSpellIDs = {}

    local function Add(spellID)
        if not IsAccessibleNumber(spellID) then return end
        includeSpellIDs[spellID] = true
        local aliases = Data.buffAuraAliases and Data.buffAuraAliases[spellID]
        for _, aliasSpellID in ipairs(aliases or {}) do
            if IsAccessibleNumber(aliasSpellID) then
                includeSpellIDs[aliasSpellID] = true
            end
        end
    end

    for _, entry in ipairs(BuildTrackingList("buff", specID)) do
        Add(type(entry) == "table" and entry.spellID or entry)
    end
    return includeSpellIDs
end

function addon:BuildDKBuffCandidateFilters()
    local specID = select(1, self:GetSpecInfo())
    return {
        includeSpellIDs = BuildDKBuffIncludeSpellIDs(specID),
    }
end

function addon:RefreshManagedDKBuffFilter()
    if not buffFrame or not buffFrame.managedAuraContainer then return end

    -- Candidate-filter tuning is deliberately out-of-combat. Current 12.1
    -- implementations treat this as live tuning; defer it to regen if needed.
    local lockdown = false
    if InCombatLockdown then
        local ok, rawValue = pcall(InCombatLockdown)
        lockdown = GetAccessibleBooleanFromCall(ok, rawValue) == true
    end
    if lockdown then
        self.managedDKBuffFilterPending = true
        return
    end

    local container = buffFrame.managedAuraContainer
    local groupKey = buffFrame.managedAuraGroupKey or "buffBar"
    local candidateFilters = self:BuildDKBuffCandidateFilters()
    buffFrame.managedAuraCandidateFilters = candidateFilters

    if container.SetAuraGroupCandidateFilters then
        pcall(container.SetAuraGroupCandidateFilters, container, groupKey, candidateFilters)
    end
    if container.SetAuraGroupMaxFrameCount then
        pcall(container.SetAuraGroupMaxFrameCount, container, groupKey, MANAGED_AURA_MAX_FRAMES)
    end
    ConfigureManagedAuraFlow(container, GetConfiguredBarColumns("buffBar", MANAGED_AURAS_PER_LINE, 10))
    if container.UpdateAllAuras then
        pcall(container.UpdateAllAuras, container)
    end

    -- The native dirty processor is partitioned; an out-of-combat Hide/Show kick
    -- makes an updated whitelist visible immediately instead of waiting one aura event.
    pcall(container.Hide, container)
    pcall(container.Show, container)
    self.managedDKBuffFilterPending = false
end

local function GetRuntimeBuffEntry(spellID)
    if not spellID then return nil end
    return runtimeBuffState[spellID]
end

local function SetRuntimeBuffState(spellID, active, duration, source)
    if not spellID then return end
    local now = GetNow()
    local state = runtimeBuffState[spellID] or {}
    runtimeBuffState[spellID] = state

    state.active = active == true
    state.source = source or state.source
    state.updatedAt = now

    if state.active then
        if IsAccessibleNumber(duration) and duration > 0 then
            state.duration = duration
            state.startedAt = now
            state.expiresAt = now + duration
        elseif duration == false then
            state.duration = nil
            state.startedAt = now
            state.expiresAt = nil
        end
    else
        state.duration = nil
        state.startedAt = nil
        state.expiresAt = nil
        state.auraInstanceID = nil
    end
end

local function GetRuntimeBuffPresentation(spellID)
    local state = GetRuntimeBuffEntry(spellID)
    if not state then return nil, nil end

    if state.active and IsAccessibleNumber(state.expiresAt) and state.expiresAt > 0 then
        local remaining = state.expiresAt - GetNow()
        if remaining <= 0 then
            state.active = false
            state.duration = nil
            state.startedAt = nil
            state.expiresAt = nil
        end
    end

    return state.active, state
end

local function NormalizeTrackedBuffSpellID(spellID)
    if not IsAccessibleNumber(spellID) then
        return nil
    end

    local specID = select(1, addon:GetSpecInfo())
    local wanted = {}
    for _, entry in ipairs(BuildTrackingList("buff", specID)) do
        local trackedID = type(entry) == "table" and entry.spellID or entry
        if trackedID then
            wanted[trackedID] = trackedID
            local aliases = Data.buffAuraAliases and Data.buffAuraAliases[trackedID]
            for _, aliasSpellID in ipairs(aliases or {}) do
                wanted[aliasSpellID] = trackedID
            end
        end
    end

    if wanted[spellID] then
        return wanted[spellID]
    end

    if C_Spell and C_Spell.GetBaseSpell then
        local ok, baseSpellID = pcall(C_Spell.GetBaseSpell, spellID)
        if ok and IsAccessibleNumber(baseSpellID) and wanted[baseSpellID] then
            return wanted[baseSpellID]
        end
    end

    return nil
end

function addon:TrackRuntimeBuffCast(spellID)
    if not IsAccessibleNumber(spellID) then return end
    local rules = Data.buffRuntimeRules or {}
    local rule = rules[spellID]
    if not rule and C_Spell and C_Spell.GetBaseSpell then
        local ok, baseSpellID = pcall(C_Spell.GetBaseSpell, spellID)
        if ok and IsAccessibleNumber(baseSpellID) then
            rule = rules[baseSpellID]
        end
    end
    if not rule then
        local trackedID = NormalizeTrackedBuffSpellID(spellID)
        if trackedID then
            rule = rules[trackedID]
        end
    end
    if not rule then return end

    local buffSpellID = rule.buffSpellID or spellID
    local duration = rule.duration
    SetRuntimeBuffState(buffSpellID, true, duration == nil and false or duration, "cast")
end

local function ResolveProcGlowDisplaySpellID(spellID)
    if not IsAccessibleNumber(spellID) then
        return nil
    end

    local specID = select(1, addon:GetSpecInfo())
    local mappings = Data.procGlowMappings and Data.procGlowMappings[specID]
    if mappings and mappings[spellID] then
        return mappings[spellID]
    end

    if C_Spell and C_Spell.GetBaseSpell then
        local ok, baseSpellID = pcall(C_Spell.GetBaseSpell, spellID)
        if ok and IsAccessibleNumber(baseSpellID) and mappings and mappings[baseSpellID] then
            return mappings[baseSpellID]
        end
    end

    return NormalizeTrackedBuffSpellID(spellID) or spellID
end

function addon:TrackRuntimeProc(spellID, active)
    if not IsAccessibleNumber(spellID) then return end

    local displaySpellID = ResolveProcGlowDisplaySpellID(spellID)
    if not displaySpellID then return end

    -- Proc-glow events identify the action that should light up. Prefer the
    -- mapped DK proc aura (KM/Rime/Frostbane) so the HUD uses the same icon a
    -- player recognizes from the buff/proc itself. Unknown future proc glows
    -- are still kept dynamically using their action spell as a fallback.
    if active == true then
        if activeProcGlows[displaySpellID] ~= true then
            activeProcGlows[displaySpellID] = true
            table.insert(activeProcGlowOrder, displaySpellID)
        end
    else
        activeProcGlows[displaySpellID] = nil
        for index = #activeProcGlowOrder, 1, -1 do
            if activeProcGlowOrder[index] == displaySpellID then
                table.remove(activeProcGlowOrder, index)
            end
        end
    end

    local trackedID = NormalizeTrackedBuffSpellID(displaySpellID) or displaySpellID
    overlayProcState[trackedID] = active == true
    SetRuntimeBuffState(trackedID, active == true, false, "proc")

    -- Breath of Sindragosa starts at 8 seconds in modern Frost and is extended
    -- when Killing Machine or Rime are consumed. When a proc glow disappears
    -- while Breath is active, extend the local fallback timer slightly. The
    -- native aura/mirror path remains authoritative whenever WoW exposes it.
    if active == false and (trackedID == 51124 or trackedID == 59052) then
        local breath = runtimeBuffState[152279]
        if breath and breath.active and IsAccessibleNumber(breath.expiresAt) then
            breath.expiresAt = breath.expiresAt + 0.8
            if IsAccessibleNumber(breath.duration) then
                breath.duration = breath.duration + 0.8
            end
        end
    end
end

function addon:ClearTransientProcStates()
    for key in pairs(activeProcGlows) do activeProcGlows[key] = nil end
    for index = #activeProcGlowOrder, 1, -1 do activeProcGlowOrder[index] = nil end
    for spellID in pairs(overlayProcState) do overlayProcState[spellID] = false end

    for _, state in pairs(runtimeBuffState) do
        if type(state) == "table" and (state.source == "proc" or state.source == "proc-poll") then
            state.active = false
            state.duration = nil
            state.startedAt = nil
            state.expiresAt = nil
            state.auraInstanceID = nil
        end
    end
end

function addon:SyncReadableBuffRuntime(clearMissing)
    if not self.active then return end
    local specID = select(1, self:GetSpecInfo())
    local now = GetNow()

    for _, entry in ipairs(BuildTrackingList("buff", specID)) do
        local spellID = type(entry) == "table" and entry.spellID or entry
        if spellID then
            local aura = GetPlayerAuraDataSafe(spellID)
            if aura then
                local state = runtimeBuffState[spellID] or {}
                runtimeBuffState[spellID] = state
                state.active = true
                state.source = "aura"
                state.updatedAt = now

                if IsAccessibleNumber(aura.auraInstanceID) then
                    state.auraInstanceID = aura.auraInstanceID
                end
                if IsAccessibleNumber(aura.duration) and aura.duration > 0 then
                    state.duration = aura.duration
                end
                if IsAccessibleNumber(aura.expirationTime) and aura.expirationTime > 0 then
                    state.expiresAt = aura.expirationTime
                    if IsAccessibleNumber(state.duration) then
                        state.startedAt = aura.expirationTime - state.duration
                    end
                else
                    state.expiresAt = nil
                end
            elseif clearMissing == true then
                local state = runtimeBuffState[spellID]
                if state then
                    state.active = false
                    state.duration = nil
                    state.startedAt = nil
                    state.expiresAt = nil
                    state.auraInstanceID = nil
                end
            end
        end
    end
end

local function SetTrackingCooldownDuration(slot, durationObject)
    if not slot or not slot.cooldown then
        return false
    end
    if durationObject and slot.cooldown.SetCooldownFromDurationObject then
        local ok = pcall(slot.cooldown.SetCooldownFromDurationObject, slot.cooldown, durationObject, true)
        if ok then
            return true
        end
    end
    ClearTrackingCooldown(slot)
    return false
end

local function ApplyRuntimeBuffDuration(slot, state)
    if not slot or not state or not state.active then
        return false
    end

    if IsAccessibleNumber(state.auraInstanceID) and C_UnitAuras and C_UnitAuras.GetAuraDuration then
        local ok, durationObject = pcall(C_UnitAuras.GetAuraDuration, "player", state.auraInstanceID)
        if ok and durationObject and SetTrackingCooldownDuration(slot, durationObject) then
            if C_UnitAuras.GetAuraApplicationDisplayCount and slot.count then
                local okCount, countText = pcall(C_UnitAuras.GetAuraApplicationDisplayCount, "player", state.auraInstanceID, 2, 99)
                if okCount and countText ~= nil then
                    pcall(slot.count.SetText, slot.count, countText)
                end
            end
            return true
        end
    end

    if IsAccessibleNumber(state.startedAt) and IsAccessibleNumber(state.duration) and state.duration > 0 then
        if slot.cooldown and slot.cooldown.SetCooldown then
            local ok = pcall(slot.cooldown.SetCooldown, slot.cooldown, state.startedAt, state.duration)
            if ok then return true end
        end
    end

    return false
end

local function SetTrackingReadyVisual(slot, ready, alphaWhenFalse)
    alphaWhenFalse = alphaWhenFalse or 0.30
    if not slot or not slot.icon then
        return
    end

    if IsAccessibleValue(ready) and type(ready) == "boolean" then
        slot.icon:SetAlpha(ready and 1 or alphaWhenFalse)
        if slot.icon.SetDesaturated then
            slot.icon:SetDesaturated(not ready)
        end
        return
    end

    -- Secret booleans cannot be inspected by Lua, but the Region widget can
    -- consume them directly and update alpha inside the game engine.
    if slot.icon.SetAlphaFromBoolean then
        local ok = pcall(slot.icon.SetAlphaFromBoolean, slot.icon, ready, 1, alphaWhenFalse)
        if ok then
            if slot.icon.SetDesaturated then
                slot.icon:SetDesaturated(false)
            end
            return
        end
    end

    slot.icon:SetAlpha(alphaWhenFalse)
    if slot.icon.SetDesaturated then
        slot.icon:SetDesaturated(true)
    end
end

local function GetMirrorItemBaseSpellID(item)
    if not item then return nil end
    if item.GetBaseSpellID then
        local ok, value = pcall(item.GetBaseSpellID, item)
        if ok and IsAccessibleNumber(value) then
            return value
        end
    end
    return nil
end

local function GetWantedSpellForMirrorItem(item, wanted)
    local baseSpellID = GetMirrorItemBaseSpellID(item)
    if baseSpellID and wanted[baseSpellID] then
        return wanted[baseSpellID]
    end

    -- Some Cooldown Viewer entries represent a spell through an override or
    -- linked aura. Resolve those relationships while the data is readable so
    -- combat-time updates can use the viewer's secret-safe active state.
    if item and item.GetCooldownInfo then
        local ok, info = pcall(item.GetCooldownInfo, item)
        if ok and type(info) == "table" then
            local candidates = {
                info.spellID,
                info.overrideSpellID,
                info.overrideTooltipSpellID,
            }
            for _, spellID in ipairs(candidates) do
                if IsAccessibleNumber(spellID) and wanted[spellID] then
                    return wanted[spellID]
                end
            end

            if type(info.linkedSpellIDs) == "table" then
                for _, spellID in ipairs(info.linkedSpellIDs) do
                    if IsAccessibleNumber(spellID) and wanted[spellID] then
                        return wanted[spellID]
                    end
                end
            end
        end
    end

    return nil
end

local function GetMirrorItemDisplaySpellID(item)
    if not item then return nil end

    -- Blizzard's Cooldown Viewer resolves linked/override proc auras internally.
    -- Prefer the materialized aura spell ID because it is the closest match to
    -- the icon the player is actually seeing in the Tracked Buffs viewer.
    if item.GetAuraSpellID then
        local ok, value = pcall(item.GetAuraSpellID, item)
        if ok and IsAccessibleNumber(value) then
            return value
        end
    end

    local okAuraField, auraSpellID = pcall(function() return item.auraSpellID end)
    if okAuraField and IsAccessibleNumber(auraSpellID) then
        return auraSpellID
    end

    if item.GetSpellID then
        local ok, value = pcall(item.GetSpellID, item)
        if ok and IsAccessibleNumber(value) then
            return value
        end
    end

    local baseSpellID = GetMirrorItemBaseSpellID(item)
    if baseSpellID then
        return baseSpellID
    end

    if item.GetCooldownInfo then
        local ok, info = pcall(item.GetCooldownInfo, item)
        if ok and type(info) == "table" then
            for _, value in ipairs({ info.linkedSpellID, info.overrideTooltipSpellID, info.overrideSpellID, info.spellID }) do
                if IsAccessibleNumber(value) then
                    return value
                end
            end
        end
    end

    -- Last-resort lookup uses ONLY Blizzard's already-built provider cache.
    -- Calling C_CooldownViewer.GetCooldownViewerCooldownInfo directly from an
    -- addon can be restricted/tainted in Midnight (AllowedWhenUntainted).
    local cooldownID
    if item.GetCooldownID then
        local ok, value = pcall(item.GetCooldownID, item)
        if ok and IsAccessibleNumber(value) then cooldownID = value end
    end
    if not cooldownID then
        local ok, value = pcall(function() return item.cooldownID end)
        if ok and IsAccessibleNumber(value) then cooldownID = value end
    end
    local info = cooldownID and GetCachedCooldownViewerInfo(cooldownID) or nil
    if info then
        local candidates, seen = {}, {}
        CollectCooldownInfoSpellIDs(info, candidates, seen)
        for _, value in ipairs(candidates) do
            if IsAccessibleNumber(value) then return value end
        end
    end

    return nil
end

local function IsMirrorBuffItemActive(item)
    if not item then return false end

    -- Strongest signal: Blizzard has materialized a real aura instance for this
    -- Cooldown Manager item. This is precisely the state DK Mentor wants to
    -- mirror and does not require reading the protected aura payload ourselves.
    if item.GetAuraSpellInstanceID then
        local ok, value = pcall(item.GetAuraSpellInstanceID, item)
        if ok and IsAccessibleNumber(value) and value > 0 then return true end
    end
    local okAuraID, auraInstanceID = pcall(function() return item.auraInstanceID end)
    if okAuraID and IsAccessibleNumber(auraInstanceID) and auraInstanceID > 0 then return true end

    -- CooldownViewerItemMixin explicitly marks visual data sourced from an aura.
    -- Unlike item:IsActive(), this means an aura/proc is actually driving the
    -- visual. Base IsActive only means the cooldown entry is configured.
    for _, fieldName in ipairs({ "wasSetFromAura", "cooldownUseAuraDisplayTime" }) do
        local ok, value = pcall(function() return item[fieldName] end)
        if ok and IsAccessibleValue(value) and type(value) == "boolean" and value then
            return true
        end
    end

    -- A cached aura table is also safe evidence only when the table itself is
    -- accessible. Do not inspect secret aura payloads.
    if item.GetAuraDataCached then
        local ok, auraData = pcall(item.GetAuraDataCached, item)
        if ok and IsAccessibleValue(auraData) and type(auraData) == "table" then
            return true
        end
    end

    return false
end

local function CanonicalizeMirroredBuffSpellID(spellID)
    if not IsAccessibleNumber(spellID) then return nil end
    return NormalizeTrackedBuffSpellID(spellID) or ResolveProcGlowDisplaySpellID(spellID) or spellID
end

function addon:RefreshCooldownViewerBuffMirrors()
    if not self.active then return end

    local inCombat = false
    if InCombatLockdown then
        local ok, value = pcall(InCombatLockdown)
        inCombat = ok and IsAccessibleValue(value) and value == true
    end

    if C_AddOns and C_AddOns.LoadAddOn and not _G.BuffIconCooldownViewer and not inCombat then
        pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
    end

    for key in pairs(mirroredBuffItems) do mirroredBuffItems[key] = nil end
    for key in pairs(mirroredActiveBuffItems) do mirroredActiveBuffItems[key] = nil end
    for index = #mirroredActiveBuffOrder, 1, -1 do mirroredActiveBuffOrder[index] = nil end

    local specID = select(1, self:GetSpecInfo())
    local profileCooldownIDs = GetCooldownManagerProfileCooldownIDSet(specID, "buff")
    local wanted = {}
    for _, entry in ipairs(BuildTrackingList("buff", specID)) do
        local spellID = type(entry) == "table" and entry.spellID or entry
        if spellID then
            wanted[spellID] = spellID
            local aliases = Data.buffAuraAliases and Data.buffAuraAliases[spellID]
            for _, aliasSpellID in ipairs(aliases or {}) do wanted[aliasSpellID] = spellID end
        end
    end

    local function GetItemCooldownID(item)
        if item and item.GetCooldownID then
            local ok, value = pcall(item.GetCooldownID, item)
            if ok and IsAccessibleNumber(value) then return value end
        end
        if item then
            local ok, value = pcall(function() return item.cooldownID end)
            if ok and IsAccessibleNumber(value) then return value end
        end
        return nil
    end

    local function ScanViewer(viewer)
        if not viewer or not viewer.itemFramePool or not viewer.itemFramePool.EnumerateActive then return end

        pcall(function()
            for item in viewer.itemFramePool:EnumerateActive() do
                local cooldownID = GetItemCooldownID(item)
                local profileWanted = cooldownID and profileCooldownIDs[cooldownID] == true
                local rawSpellID = GetMirrorItemDisplaySpellID(item)
                local canonicalSpellID = CanonicalizeMirroredBuffSpellID(rawSpellID)
                local knownSpellID = GetWantedSpellForMirrorItem(item, wanted)

                -- Profile cooldown IDs are authoritative even when Blizzard uses
                -- a linked/override spell ID that is new to DK Mentor.
                local displaySpellID = knownSpellID or canonicalSpellID or rawSpellID
                local useful = profileWanted or knownSpellID ~= nil
                if useful and displaySpellID then
                    mirroredBuffItems[displaySpellID] = item
                    if IsMirrorBuffItemActive(item) and not mirroredActiveBuffItems[displaySpellID] then
                        mirroredActiveBuffItems[displaySpellID] = item
                        table.insert(mirroredActiveBuffOrder, displaySpellID)
                    end
                end
            end
        end)
    end

    ScanViewer(_G.BuffIconCooldownViewer)
    ScanViewer(_G.BuffBarCooldownViewer)
end

local function GetMirroredBuffState(spellID)
    local item = mirroredBuffItems[spellID]
    if not item then return nil, nil end
    return IsMirrorBuffItemActive(item), item
end

local function GetMirroredBuffTexture(item)
    if not item then return nil end

    if item.GetIconTexture then
        local ok, textureRegion = pcall(item.GetIconTexture, item)
        if ok and textureRegion and textureRegion.GetTexture then
            local okTexture, texture = pcall(textureRegion.GetTexture, textureRegion)
            if okTexture and IsAccessibleValue(texture) then return texture end
        end
    end

    if item.Icon then
        if item.Icon.GetTexture then
            local ok, texture = pcall(item.Icon.GetTexture, item.Icon)
            if ok and IsAccessibleValue(texture) then return texture end
        end
        if item.Icon.Icon and item.Icon.Icon.GetTexture then
            local ok, texture = pcall(item.Icon.Icon.GetTexture, item.Icon.Icon)
            if ok and IsAccessibleValue(texture) then return texture end
        end
    end

    return nil
end

local function ApplyMirroredAuraDuration(slot, item)
    if not slot or not item or not C_UnitAuras or not C_UnitAuras.GetAuraDuration then
        return false
    end

    local okID, auraInstanceID = pcall(function() return item.auraInstanceID end)
    if not okID or not IsAccessibleNumber(auraInstanceID) then
        return false
    end

    local ok, durationObject = pcall(C_UnitAuras.GetAuraDuration, "player", auraInstanceID)
    if ok and durationObject then
        SetTrackingCooldownDuration(slot, durationObject)

        if C_UnitAuras.GetAuraApplicationDisplayCount and slot.count then
            local okCount, countText = pcall(C_UnitAuras.GetAuraApplicationDisplayCount, "player", auraInstanceID, 2, 99)
            if okCount then
                if IsSecretValue(countText) then
                    pcall(slot.count.SetText, slot.count, countText)
                elseif countText ~= nil then
                    pcall(slot.count.SetText, slot.count, countText)
                end
            end
        end
        return true
    end

    return false
end

function addon:SetBuffBarEnabled(enabled)
    if not DB or not DB.buffBar then return end
    DB.buffBar.enabled = enabled == true
    if DB.buffBar.enabled then
        if buffFrame and buffFrame.managedAuraContainer then
            self:RefreshManagedDKBuffFilter()
        else
            self:RefreshCooldownViewerBuffMirrors()
        end
    end
    self:RefreshCombatHUDVisibility()
    self:UpdateHUDSettings()
    Print(T(DB.buffBar.enabled and "Buff bar enabled." or "Buff bar disabled."))
end

function addon:SetAbilityBarEnabled(enabled)
    if not DB or not DB.abilityBar then return end
    DB.abilityBar.enabled = enabled == true
    self:RefreshCombatHUDVisibility()
    self:UpdateHUDSettings()
    Print(T(DB.abilityBar.enabled and "Ability bar enabled." or "Ability bar disabled."))
end

local function SyncKnownProcGlowStates()
    if not C_SpellActivationOverlay or not C_SpellActivationOverlay.IsSpellOverlayed then
        return
    end

    local specID = select(1, addon:GetSpecInfo())
    local mappings = Data.procGlowMappings and Data.procGlowMappings[specID]
    if type(mappings) ~= "table" then return end

    local canonicalSeen = {}
    for actionSpellID, procSpellID in pairs(mappings) do
        if IsAccessibleNumber(actionSpellID) and IsAccessibleNumber(procSpellID) then
            local ok, overlayed = pcall(C_SpellActivationOverlay.IsSpellOverlayed, actionSpellID)
            if ok and IsAccessibleValue(overlayed) and type(overlayed) == "boolean" then
                -- Several actions can represent the same proc (KM on Obliterate
                -- and Frostscythe). OR them together before clearing the proc.
                local state = canonicalSeen[procSpellID]
                if state == nil then state = false end
                canonicalSeen[procSpellID] = state or overlayed
            end
        end
    end

    for procSpellID, overlayed in pairs(canonicalSeen) do
        local current = activeProcGlows[procSpellID] == true
        if current ~= overlayed then
            if overlayed then
                activeProcGlows[procSpellID] = true
                table.insert(activeProcGlowOrder, procSpellID)
            else
                activeProcGlows[procSpellID] = nil
                for index = #activeProcGlowOrder, 1, -1 do
                    if activeProcGlowOrder[index] == procSpellID then
                        table.remove(activeProcGlowOrder, index)
                    end
                end
            end
            overlayProcState[procSpellID] = overlayed
            SetRuntimeBuffState(procSpellID, overlayed, false, "proc-poll")
        end
    end
end

local function BuildBuffDisplayList(specID)
    local list = {}
    local seen = {}

    local function Add(spellID, flags)
        if not spellID or seen[spellID] then return end
        seen[spellID] = true
        local entry = { spellID = spellID }
        for key, value in pairs(flags or {}) do entry[key] = value end
        table.insert(list, entry)
    end

    -- 1) Exact active entries currently materialized by Blizzard's Tracked
    -- Buffs/Tracked Bars viewers. This is the closest possible mirror of the
    -- proc row the player sees at the top of the screen.
    for _, spellID in ipairs(mirroredActiveBuffOrder) do
        if mirroredActiveBuffItems[spellID] then
            Add(spellID, { mirrorActive = true, priorityProc = true })
        end
    end

    -- 2) Proc glows are a fallback for procs the player has not configured in
    -- Blizzard's tracked-buff viewer. They disappear as soon as the glow ends.
    for _, spellID in ipairs(activeProcGlowOrder) do
        if activeProcGlows[spellID] == true then
            Add(spellID, { procGlow = true, priorityProc = true })
        end
    end

    -- 3) Known DK buffs are included only while they are ACTUALLY active. No
    -- inactive/dim placeholders remain in normal gameplay.
    for _, tracked in ipairs(BuildTrackingList("buff", specID)) do
        local spellID = type(tracked) == "table" and tracked.spellID or tracked
        if spellID and not seen[spellID] then
            local aura = GetPlayerAuraDataSafe(spellID)
            local mirrorActive = select(1, GetMirroredBuffState(spellID))
            local procActive = overlayProcState[spellID]
            local runtimeActive = select(1, GetRuntimeBuffPresentation(spellID))

            local active = aura ~= nil
            if not active and IsAccessibleValue(mirrorActive) and type(mirrorActive) == "boolean" then
                active = mirrorActive
            end
            if not active and procActive == true then active = true end
            if not active and runtimeActive == true then active = true end

            if active then
                Add(spellID, { priorityProc = procActive == true })
            end
        end
    end

    -- Preview mode exists only so the user can position the HUD while no proc
    -- is active. These samples disappear immediately when Preview HUDs is off.
    if #list == 0 and addon.hudPreviewMode == true then
        local previewCount = 0
        local previewLimit = GetConfiguredBarColumns("buffBar", 5, 10)
        for _, tracked in ipairs(BuildTrackingList("buff", specID)) do
            local spellID = type(tracked) == "table" and tracked.spellID or tracked
            if spellID and not seen[spellID] then
                Add(spellID, { previewOnly = true })
                previewCount = previewCount + 1
                if previewCount >= previewLimit then break end
            end
        end
    end

    return list
end

function addon:UpdateBuffBar()
    if not buffFrame or not DB or not self.active then
        return
    end
    if not self:ShouldShowCombatBar(DB.buffBar) then
        buffFrame:Hide()
        return
    end

    if buffFrame.managedAuraContainer then
        if self.hudPreviewMode == true then
            ShowManagedAuraPreview(buffFrame, buffSlots)
            return
        end
        RestoreManagedAuraRuntime(buffFrame, buffSlots)
        buffFrame:Show()
        UpdateManagedAuraBarChrome(buffFrame)
        -- Blizzard's AuraContainer owns active-state/stacks/duration updates.
        -- Do not poll secret aura data or infer presence from mirror frames here.
        return
    end

    -- Compatibility fallback for clients without the 12.1 AuraContainer engine.
    -- Poll Blizzard's materialized tracked-buff frames every bar refresh. The
    -- previous event-only bridge could miss short/new procs in Midnight.
    self:RefreshCooldownViewerBuffMirrors()
    SyncKnownProcGlowStates()

    local specID = select(1, self:GetSpecInfo())
    local list = BuildBuffDisplayList(specID)
    local visibleCount = math.min(#list, #buffSlots)
    if visibleCount <= 0 then
        for _, slot in ipairs(buffSlots) do
            slot.spellID = nil
            ClearTrackingCooldown(slot)
            slot:Hide()
        end
        buffFrame:Hide()
        return
    end
    local perRow = buffFrame.slotsPerRow or #buffSlots
    local columns = math.max(1, math.min(perRow, visibleCount))
    local rows = math.max(1, math.ceil(math.max(1, visibleCount) / perRow))
    buffFrame:SetWidth(math.max(92, 14 + (columns * 38)))
    buffFrame:SetHeight(16 + (rows * 38))

    for index, slot in ipairs(buffSlots) do
        local entry = list[index]
        if entry then
            local spellID = type(entry) == "table" and entry.spellID or entry
            local isDynamicProc = type(entry) == "table" and entry.procGlow == true
            local isDynamicMirror = type(entry) == "table" and entry.mirrorActive == true
            local isPriorityProc = type(entry) == "table" and entry.priorityProc == true
            local isPreviewOnly = type(entry) == "table" and entry.previewOnly == true
            local spellName, spellIcon = GetSpellData(spellID)
            local aura = (isDynamicProc or isDynamicMirror) and nil or GetPlayerAuraDataSafe(spellID)
            local mirrorActive, mirrorItem
            if isDynamicMirror then
                mirrorActive = true
                mirrorItem = mirroredActiveBuffItems[spellID]
            elseif not isDynamicProc then
                mirrorActive, mirrorItem = GetMirroredBuffState(spellID)
            end
            local procActive = isDynamicProc and true or overlayProcState[spellID]
            local runtimeActive, runtimeState = (isDynamicProc or isDynamicMirror) and nil or GetRuntimeBuffPresentation(spellID)
            local activeState

            if isPreviewOnly then
                activeState = false
            elseif aura then
                activeState = true
            elseif procActive == true then
                activeState = true
            elseif runtimeActive == true then
                activeState = true
            elseif IsSecretValue(mirrorActive) then
                activeState = mirrorActive
            elseif mirrorActive ~= nil then
                activeState = mirrorActive
            elseif procActive ~= nil then
                activeState = procActive
            elseif runtimeActive ~= nil then
                activeState = runtimeActive
            else
                activeState = false
            end

            slot.spellID = spellID
            slot.spellName = spellName
            local iconTexture = spellIcon
            if aura and IsAccessibleNumber(aura.icon) then
                iconTexture = aura.icon
            elseif mirrorItem then
                local mirroredTexture = GetMirroredBuffTexture(mirrorItem)
                if mirroredTexture ~= nil then
                    iconTexture = mirroredTexture
                end
            end
            slot.icon:SetTexture(iconTexture)
            SetTrackingReadyVisual(slot, activeState, 0.24)

            if isPriorityProc and activeState == true then
                slot:SetBackdropBorderColor(1.00, 0.76, 0.12, 1)
            elseif IsAccessibleValue(activeState) and type(activeState) == "boolean" then
                slot:SetBackdropBorderColor(activeState and 0.30 or 0.16, activeState and 0.82 or 0.35, activeState and 0.55 or 0.48, activeState and 1 or 0.65)
            else
                slot:SetBackdropBorderColor(0.18, 0.52, 0.66, 0.90)
            end

            slot.count:SetText("")
            slot.timer:SetText("")
            if slot.timer.SetAlpha then slot.timer:SetAlpha(1) end
            ClearTrackingCooldown(slot)

            local renderedDuration = false
            if aura then
                local count = aura.applications
                if IsAccessibleNumber(count) and count > 1 then
                    slot.count:SetText(tostring(math.floor(count + 0.5)))
                end

                local auraInstanceID = aura.auraInstanceID
                if IsAccessibleNumber(auraInstanceID) and C_UnitAuras and C_UnitAuras.GetAuraDuration then
                    local okDuration, durationObject = pcall(C_UnitAuras.GetAuraDuration, "player", auraInstanceID)
                    if okDuration and durationObject then
                        renderedDuration = SetTrackingCooldownDuration(slot, durationObject)
                    end
                end

                -- Legacy/plain-value fallback outside restricted combat.
                if not renderedDuration and IsAccessibleNumber(aura.expirationTime) and aura.expirationTime > 0 then
                    local remaining = aura.expirationTime - GetNow()
                    if IsAccessibleNumber(remaining) and remaining > 0 then
                        slot.timer:SetText(FormatShortTime(remaining))
                    end
                end
            elseif mirrorItem then
                renderedDuration = ApplyMirroredAuraDuration(slot, mirrorItem)
            end

            if not renderedDuration and runtimeState and runtimeActive == true then
                renderedDuration = ApplyRuntimeBuffDuration(slot, runtimeState)
                if not renderedDuration and IsAccessibleNumber(runtimeState.expiresAt) then
                    local remaining = runtimeState.expiresAt - GetNow()
                    if remaining > 0 then
                        slot.timer:SetText(FormatShortTime(remaining))
                    end
                end
            end

            slot:Show()
        else
            slot.spellID = nil
            ClearTrackingCooldown(slot)
            slot:Hide()
        end
    end

    buffFrame:Show()
end


local function GetDynamicPlayerAuras(filter, maxResults, externalOnly)
    local results = {}
    local scanLimit = externalOnly and 60 or math.max(24, tonumber(maxResults) or 12)

    if C_UnitAuras and C_UnitAuras.GetUnitAuras then
        local ok, auras = pcall(C_UnitAuras.GetUnitAuras, "player", filter, scanLimit)
        if ok and type(auras) == "table" then
            for index, aura in ipairs(auras) do
                if type(aura) == "table" then
                    local include = true
                    if externalOnly then
                        local own = aura.isFromPlayerOrPlayerPet
                        if IsAccessibleValue(own) and own == true then
                            include = false
                        end
                    end
                    if include then
                        results[#results + 1] = { aura = aura, index = index, filter = filter }
                        if #results >= maxResults then break end
                    end
                end
            end
            return results
        end
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for index = 1, scanLimit do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", index, filter)
            if not ok or type(aura) ~= "table" then break end
            local include = true
            if externalOnly then
                local own = aura.isFromPlayerOrPlayerPet
                if IsAccessibleValue(own) and own == true then include = false end
            end
            if include then
                results[#results + 1] = { aura = aura, index = index, filter = filter }
                if #results >= maxResults then break end
            end
        end
    end

    return results
end

local function ApplyDynamicAuraToSlot(slot, record, harmful)
    local aura = record and record.aura or nil
    if not slot or type(aura) ~= "table" then return end

    local spellID = IsAccessibleNumber(aura.spellId) and aura.spellId or nil
    local auraInstanceID = IsAccessibleNumber(aura.auraInstanceID) and aura.auraInstanceID or nil
    local auraName = IsAccessibleValue(aura.name) and aura.name or nil
    local auraIcon = IsAccessibleNumber(aura.icon) and aura.icon or QUESTION_MARK_ICON

    slot.spellID = spellID
    slot.spellName = auraName
    slot.auraInstanceID = auraInstanceID
    slot.auraIndex = record.index
    slot.auraFilter = record.filter
    slot.icon:SetTexture(auraIcon)
    if slot.icon.SetDesaturated then slot.icon:SetDesaturated(false) end
    slot.icon:SetAlpha(1)
    slot.count:SetText("")
    slot.timer:SetText("")
    if slot.timer.SetAlpha then slot.timer:SetAlpha(1) end
    ClearTrackingCooldown(slot)

    if harmful then
        local r, g, b = 0.88, 0.28, 0.25
        local dispelName = aura.dispelName
        if IsAccessibleValue(dispelName) and type(dispelName) == "string" and DebuffTypeColor and DebuffTypeColor[dispelName] then
            local c = DebuffTypeColor[dispelName]
            r, g, b = c.r or r, c.g or g, c.b or b
        end
        slot:SetBackdropBorderColor(r, g, b, 1)
    else
        slot:SetBackdropBorderColor(0.28, 0.78, 0.92, 1)
    end

    if auraInstanceID and C_UnitAuras then
        if C_UnitAuras.GetAuraDuration then
            local okDuration, durationObject = pcall(C_UnitAuras.GetAuraDuration, "player", auraInstanceID)
            if okDuration and durationObject then
                SetTrackingCooldownDuration(slot, durationObject)
            end
        end
        if C_UnitAuras.GetAuraApplicationDisplayCount then
            local okCount, countText = pcall(C_UnitAuras.GetAuraApplicationDisplayCount, "player", auraInstanceID, 2, 99)
            if okCount then
                if IsSecretValue(countText) then
                    pcall(slot.count.SetText, slot.count, countText)
                elseif countText ~= nil then
                    pcall(slot.count.SetText, slot.count, countText)
                end
            end
        end
    elseif IsAccessibleNumber(aura.applications) and aura.applications > 1 then
        slot.count:SetText(tostring(math.floor(aura.applications + 0.5)))
    end
end

local function RenderDynamicAuraBar(frame, slots, dbEntry, filter, externalOnly, harmful, previewTitle)
    if not frame or not dbEntry then return end

    local preview = addon.hudPreviewMode == true
    if not dbEntry.enabled and not preview then
        frame:Hide()
        return
    end

    local perLine = GetConfiguredBarColumns(frame.dbKey, 5, 10)
    local records = GetDynamicPlayerAuras(filter, #slots, externalOnly)
    local visibleCount = #records
    if preview and visibleCount == 0 then visibleCount = math.min(perLine, #slots) end

    if visibleCount == 0 then
        frame:Hide()
        return
    end

    local rows = math.max(1, math.ceil(visibleCount / perLine))
    local columns = math.max(1, math.min(perLine, visibleCount))
    frame:SetWidth(math.max(92, 14 + (columns * 38)))
    frame:SetHeight(22 + (rows * 38))
    for index, slot in ipairs(slots) do
        slot:ClearAllPoints()
        local row = math.floor((index - 1) / perLine)
        local column = (index - 1) % perLine
        slot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 7 + (column * 38), 4 + (row * 38))
        local record = records[index]
        if record then
            ApplyDynamicAuraToSlot(slot, record, harmful)
            slot:Show()
        elseif preview and index <= visibleCount then
            slot.spellID = nil
            slot.spellName = previewTitle
            slot.auraInstanceID = nil
            slot.auraIndex = nil
            slot.auraFilter = nil
            slot.icon:SetTexture(QUESTION_MARK_ICON)
            if slot.icon.SetDesaturated then slot.icon:SetDesaturated(true) end
            slot.icon:SetAlpha(0.35)
            slot.count:SetText("")
            slot.timer:SetText("")
            ClearTrackingCooldown(slot)
            slot:SetBackdropBorderColor(harmful and 0.70 or 0.20, harmful and 0.22 or 0.55, harmful and 0.20 or 0.72, 0.75)
            slot:Show()
        else
            slot.spellID = nil
            slot.spellName = nil
            slot.auraInstanceID = nil
            slot.auraIndex = nil
            slot.auraFilter = nil
            ClearTrackingCooldown(slot)
            slot:Hide()
        end
    end
    frame:Show()
end

function addon:SetExternalBuffBarEnabled(enabled)
    if not DB or not DB.externalBuffBar then return end
    DB.externalBuffBar.enabled = enabled == true
    self:RefreshCombatHUDVisibility()
    self:UpdateHUDSettings()
    Print(T(DB.externalBuffBar.enabled and "External buff bar enabled." or "External buff bar disabled."))
end

function addon:SetDebuffBarEnabled(enabled)
    if not DB or not DB.debuffBar then return end
    DB.debuffBar.enabled = enabled == true
    self:RefreshCombatHUDVisibility()
    self:UpdateHUDSettings()
    Print(T(DB.debuffBar.enabled and "Debuff bar enabled." or "Debuff bar disabled."))
end

function addon:UpdateExternalBuffBar()
    if not externalBuffFrame or not DB or not self.active then return end
    if not self:ShouldShowCombatBar(DB.externalBuffBar) then
        externalBuffFrame:Hide()
        return
    end

    if externalBuffFrame.managedAuraContainer then
        if self.hudPreviewMode == true then
            ShowManagedAuraPreview(externalBuffFrame, externalBuffSlots)
            return
        end
        local visible = self:ShouldShowCombatBar(DB.externalBuffBar)
        if visible then
            RestoreManagedAuraRuntime(externalBuffFrame, externalBuffSlots)
            externalBuffFrame:Show()
            UpdateManagedAuraBarChrome(externalBuffFrame)
            if externalBuffFrame.managedAuraContainer.UpdateAllAuras then
                pcall(externalBuffFrame.managedAuraContainer.UpdateAllAuras, externalBuffFrame.managedAuraContainer)
            end
        else
            externalBuffFrame:Hide()
        end
        return
    end

    -- Compatibility path for clients without the 12.1 AuraContainer engine.
    RenderDynamicAuraBar(externalBuffFrame, externalBuffSlots, DB.externalBuffBar, "HELPFUL", true, false, T("External Buffs"))
end

function addon:UpdateDebuffBar()
    if not debuffFrame or not DB or not self.active then return end
    if not self:ShouldShowCombatBar(DB.debuffBar) then
        debuffFrame:Hide()
        return
    end

    if debuffFrame.managedAuraContainer then
        if self.hudPreviewMode == true then
            ShowManagedAuraPreview(debuffFrame, debuffSlots)
            return
        end
        local visible = self:ShouldShowCombatBar(DB.debuffBar)
        if visible then
            RestoreManagedAuraRuntime(debuffFrame, debuffSlots)
            debuffFrame:Show()
            UpdateManagedAuraBarChrome(debuffFrame)
            if debuffFrame.managedAuraContainer.UpdateAllAuras then
                pcall(debuffFrame.managedAuraContainer.UpdateAllAuras, debuffFrame.managedAuraContainer)
            end
        else
            debuffFrame:Hide()
        end
        return
    end

    -- Compatibility path for clients without the 12.1 AuraContainer engine.
    RenderDynamicAuraBar(debuffFrame, debuffSlots, DB.debuffBar, "HARMFUL", false, true, T("Debuffs"))
end

local function GetSpellCooldownPresentation(spellID)
    local cooldownInfo
    local cooldownDuration
    local chargeInfo
    local chargeDuration
    local usable
    local insufficientPower

    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, value = pcall(C_Spell.GetSpellCooldown, spellID)
        if ok and type(value) == "table" then
            cooldownInfo = value
        end
    end

    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local ok, value = pcall(C_Spell.GetSpellCooldownDuration, spellID, true)
        if ok then cooldownDuration = value end
    end

    if C_Spell and C_Spell.GetSpellCharges then
        local ok, value = pcall(C_Spell.GetSpellCharges, spellID)
        if ok and type(value) == "table" then
            chargeInfo = value
        end
    end

    if chargeInfo and IsAccessibleNumber(chargeInfo.maxCharges) and chargeInfo.maxCharges > 1 and C_Spell and C_Spell.GetSpellChargeDuration then
        local ok, value = pcall(C_Spell.GetSpellChargeDuration, spellID, true)
        if ok then chargeDuration = value end
    end

    if C_Spell and C_Spell.IsSpellUsable then
        local ok, canUse, noPower = pcall(C_Spell.IsSpellUsable, spellID)
        if ok then
            usable = canUse
            insufficientPower = noPower
        end
    end

    return cooldownInfo, chargeInfo, chargeDuration or cooldownDuration, usable, insufficientPower
end

function addon:SetInterruptAlertEnabled(enabled)
    if not DB or not DB.interruptAlert then return end
    DB.interruptAlert.enabled = enabled == true
    targetInterruptEventState = nil
    self:UpdateInterruptAlert()
    self:UpdateHUDSettings()
    Print(T(DB.interruptAlert.enabled and "Interrupt alert enabled." or "Interrupt alert disabled."))
end

local function GetTargetInterruptibleFromCastAPI()
    local hasCast = false
    local interruptible

    if UnitCastingInfo then
        local ok, _, _, _, _, _, _, _, notInterruptible, _, castBarID = pcall(UnitCastingInfo, "target")
        if ok and IsAccessibleNumber(castBarID) then
            hasCast = true
            local guarded = GetAccessibleBoolean(notInterruptible)
            if guarded ~= nil then interruptible = not guarded end
        end
    end

    if not hasCast and UnitChannelInfo then
        local ok, _, _, _, _, _, _, notInterruptible, _, _, _, castBarID = pcall(UnitChannelInfo, "target")
        if ok and IsAccessibleNumber(castBarID) then
            hasCast = true
            local guarded = GetAccessibleBoolean(notInterruptible)
            if guarded ~= nil then interruptible = not guarded end
        end
    end

    return hasCast, interruptible
end

function addon:UpdateInterruptAlert()
    if not interruptFrame or not DB or not self.active then return end

    if self.hudPreviewMode == true then
        interruptFrame:SetBackdropBorderColor(0.25, 0.78, 0.95, 1)
        interruptFrame.icon:SetAlpha(1)
        if interruptFrame.icon.SetDesaturated then interruptFrame.icon:SetDesaturated(false) end
        ClearTrackingCooldown(interruptFrame)
        interruptFrame:Show()
        return
    end

    if not DB.interruptAlert or DB.interruptAlert.enabled ~= true then
        interruptFrame:Hide()
        return
    end

    if DB.combatBarsOnlyInCombat == true and not self:IsPlayerInCombat() then
        interruptFrame:Hide()
        return
    end

    local hasCast, interruptible = GetTargetInterruptibleFromCastAPI()
    if interruptible == nil and hasCast and targetInterruptEventState ~= nil then
        interruptible = targetInterruptEventState
    end
    if not hasCast or interruptible ~= true then
        interruptFrame:Hide()
        return
    end

    local spellID = Data.spells and Data.spells.MIND_FREEZE or 47528
    local _, icon = GetSpellData(spellID, T("Mind Freeze"))
    interruptFrame.icon:SetTexture(icon or QUESTION_MARK_ICON)

    local cooldownInfo, _, durationObject, usable = GetSpellCooldownPresentation(spellID)
    if IsSecretValue(usable) then
        SetTrackingReadyVisual(interruptFrame, usable, 0.42)
    elseif IsAccessibleValue(usable) then
        SetTrackingReadyVisual(interruptFrame, usable, 0.42)
    else
        SetTrackingReadyVisual(interruptFrame, true, 0.42)
    end
    if durationObject then
        SetTrackingCooldownDuration(interruptFrame, durationObject)
    elseif cooldownInfo and IsAccessibleNumber(cooldownInfo.startTime) and IsAccessibleNumber(cooldownInfo.duration) and cooldownInfo.duration > 0 then
        pcall(interruptFrame.cooldown.SetCooldown, interruptFrame.cooldown, cooldownInfo.startTime, cooldownInfo.duration)
    else
        ClearTrackingCooldown(interruptFrame)
    end

    local usableBool = GetAccessibleBoolean(usable)
    if usableBool == false then
        interruptFrame:SetBackdropBorderColor(0.72, 0.28, 0.20, 1)
    else
        interruptFrame:SetBackdropBorderColor(0.18, 0.88, 0.92, 1)
    end
    interruptFrame:Show()
end

function addon:UpdateAbilityBar()
    if not abilityFrame or not DB or not self.active then
        return
    end
    if not self:ShouldShowCombatBar(DB.abilityBar) then
        abilityFrame:Hide()
        return
    end

    local specID = select(1, self:GetSpecInfo())
    local list = BuildTrackingList("ability", specID)
    local perRow = GetConfiguredBarColumns("abilityBar", 11, 11)
    LayoutTrackingSlots(abilityFrame, abilitySlots, perRow, false)
    local visibleCount = math.min(#list, #abilitySlots)
    if self.hudPreviewMode == true and visibleCount == 0 then
        visibleCount = math.min(perRow, #abilitySlots)
    end
    if visibleCount <= 0 then
        abilityFrame:Hide()
        return
    end
    local columns = math.max(1, math.min(perRow, visibleCount))
    local rows = math.max(1, math.ceil(visibleCount / perRow))
    abilityFrame:SetWidth(math.max(92, 14 + (columns * 38)))
    abilityFrame:SetHeight(16 + (rows * 38))

    for index, slot in ipairs(abilitySlots) do
        local entry = list[index]
        if entry then
            local spellID = type(entry) == "table" and entry.spellID or entry
            local spellName, spellIcon = GetSpellData(spellID)
            local cooldownInfo, chargeInfo, durationObject, usable, insufficientPower = GetSpellCooldownPresentation(spellID)

            slot.spellID = spellID
            slot.spellName = spellName
            slot.icon:SetTexture(spellIcon)
            if slot.icon.SetDesaturated then slot.icon:SetDesaturated(false) end
            slot.icon:SetAlpha(1)

            -- IsSpellUsable may be a secret boolean during combat. Feed it
            -- directly into the Region API rather than reading it in Lua.
            if IsSecretValue(usable) then
                SetTrackingReadyVisual(slot, usable, 0.34)
            elseif usable ~= nil then
                SetTrackingReadyVisual(slot, usable, 0.34)
            else
                local ready = true
                if cooldownInfo and cooldownInfo.isActive == true and cooldownInfo.isOnGCD ~= true then
                    ready = false
                end
                SetTrackingReadyVisual(slot, ready, 0.34)
            end

            local onRealCooldown = cooldownInfo and cooldownInfo.isActive == true and cooldownInfo.isOnGCD ~= true
            if onRealCooldown then
                slot:SetBackdropBorderColor(0.44, 0.30, 0.30, 1)
            else
                slot:SetBackdropBorderColor(0.30, 0.82, 0.55, 1)
            end

            if durationObject then
                SetTrackingCooldownDuration(slot, durationObject)
            else
                ClearTrackingCooldown(slot)
            end

            slot.count:SetText("")
            if chargeInfo and IsAccessibleNumber(chargeInfo.maxCharges) and chargeInfo.maxCharges > 1 then
                local currentCharges = chargeInfo.currentCharges
                if IsSecretValue(currentCharges) then
                    pcall(slot.count.SetText, slot.count, currentCharges)
                elseif currentCharges ~= nil then
                    pcall(slot.count.SetText, slot.count, currentCharges)
                end
            end

            -- Resource state is also allowed to become secret. Display RP only
            -- through a secret-safe alpha path when needed.
            slot.timer:SetText("RP")
            if IsSecretValue(insufficientPower) and slot.timer.SetAlphaFromBoolean then
                local ok = pcall(slot.timer.SetAlphaFromBoolean, slot.timer, insufficientPower, 1, 0)
                if not ok then slot.timer:SetAlpha(0) end
            elseif IsAccessibleValue(insufficientPower) and insufficientPower == true then
                slot.timer:SetAlpha(1)
            else
                slot.timer:SetAlpha(0)
            end

            slot:Show()
        elseif self.hudPreviewMode == true and index <= visibleCount then
            slot.spellID = nil
            slot.spellName = T("Abilities")
            slot.icon:SetTexture(QUESTION_MARK_ICON)
            if slot.icon.SetDesaturated then slot.icon:SetDesaturated(true) end
            slot.icon:SetAlpha(0.42)
            slot.timer:SetText("")
            slot.timer:SetAlpha(1)
            slot.count:SetText("")
            ClearTrackingCooldown(slot)
            slot:SetBackdropBorderColor(0.20, 0.58, 0.76, 0.85)
            slot:Show()
        else
            slot.spellID = nil
            slot.timer:SetAlpha(1)
            ClearTrackingCooldown(slot)
            slot:Hide()
        end
    end

    abilityFrame:Show()
end

function addon:RefreshCombatHUDVisibility()
    if not self.active or not DB then
        if buffFrame then buffFrame:Hide() end
        if externalBuffFrame then externalBuffFrame:Hide() end
        if debuffFrame then debuffFrame:Hide() end
        if abilityFrame then abilityFrame:Hide() end
        if resourceFrame then resourceFrame:Hide() end
        if interruptFrame then interruptFrame:Hide() end
        return
    end

    if buffFrame then
        if self:ShouldShowCombatBar(DB.buffBar) then
            buffFrame:Show()
            self:UpdateBuffBar()
        else
            buffFrame:Hide()
        end
    end

    if externalBuffFrame then
        if self:ShouldShowCombatBar(DB.externalBuffBar) then
            self:UpdateExternalBuffBar()
        else
            externalBuffFrame:Hide()
        end
    end

    if debuffFrame then
        if self:ShouldShowCombatBar(DB.debuffBar) then
            self:UpdateDebuffBar()
        else
            debuffFrame:Hide()
        end
    end

    if abilityFrame then
        if self:ShouldShowCombatBar(DB.abilityBar) then
            abilityFrame:Show()
            self:UpdateAbilityBar()
        else
            abilityFrame:Hide()
        end
    end

    if resourceFrame then
        self:UpdateResourceHUD()
    end

    self:UpdateInterruptAlert()
end

function addon:GetLanguageOverrideLabel()
    return GetAddonLanguageLabel(DB and DB.languageOverride or "auto")
end

function addon:UpdateLanguagePicker()
    if not languagePickerFrame or not DB then return end
    local selected = NormalizeAddonLanguage(DB.languageOverride)
    if languagePickerFrame.current then
        languagePickerFrame.current:SetText(T("Current: %s", GetAddonLanguageLabel(selected)))
    end
    for _, button in ipairs(languagePickerFrame.choiceButtons or {}) do
        local label = T(button.languageLabelKey or "")
        if NormalizeAddonLanguage(button.languageValue) == selected then
            button:SetText("|cff69d8ff✓|r " .. label)
        else
            button:SetText(label)
        end
    end
end

function addon:ToggleLanguagePicker()
    if not languagePickerFrame then return end
    if languagePickerFrame:IsShown() then
        languagePickerFrame:Hide()
        return
    end
    languagePickerFrame:ClearAllPoints()
    if mainFrame and mainFrame:IsShown() then
        languagePickerFrame:SetPoint("CENTER", mainFrame, "CENTER", 0, 20)
    else
        languagePickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    self:UpdateLanguagePicker()
    languagePickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    languagePickerFrame:SetFrameLevel(1000)
    languagePickerFrame:Show()
    if languagePickerFrame.Raise then languagePickerFrame:Raise() end
end

function addon:SetLanguageOverride(value)
    if not DB then return end
    local normalized = NormalizeAddonLanguage(value)
    DB.languageOverride = normalized
    local label = GetAddonLanguageLabel(normalized)

    -- Do not call ReloadUI/Reload from addon code. In current Retail clients
    -- that path can be protected and trigger ADDON_ACTION_BLOCKED. Persist the
    -- preference and let the player explicitly run /reload instead.
    self:UpdateLanguagePicker()
    self:UpdateLanguageSettings()
    if languagePickerFrame then languagePickerFrame:Hide() end
    Print(T("Language saved as %s. Type /reload to apply it.", label))
end

function addon:UpdateLanguageSettings()
    if not mainFrame or not mainFrame.languageButton or not DB then return end
    mainFrame.languageButton:SetText(T("Language: %s", self:GetLanguageOverrideLabel()))
end

function addon:UpdateHUDSettings()
    if not mainFrame or not mainFrame.hudSection or not DB then return end
    self:UpdateLanguageSettings()
    local hud = mainFrame.hudSection
    if hud.buildButton then hud.buildButton:SetText(DB.statusWidget.enabled and T("Build HUD: ON") or T("Build HUD: OFF")) end
    if hud.coachButton then hud.coachButton:SetText(DB.coach.enabled and T("Coach HUD: ON") or T("Coach HUD: OFF")) end
    if hud.buffButton then hud.buffButton:SetText(DB.buffBar.enabled and T("Buff bar: ON") or T("Buff bar: OFF")) end
    if hud.externalBuffButton then hud.externalBuffButton:SetText(DB.externalBuffBar.enabled and T("External buffs: ON") or T("External buffs: OFF")) end
    if hud.debuffButton then hud.debuffButton:SetText(DB.debuffBar.enabled and T("Debuffs: ON") or T("Debuffs: OFF")) end
    if hud.abilityButton then hud.abilityButton:SetText(DB.abilityBar.enabled and T("Ability bar: ON") or T("Ability bar: OFF")) end
    if hud.resourceButton then hud.resourceButton:SetText(DB.resourceHUD.enabled and T("DK resources: ON") or T("DK resources: OFF")) end
    if hud.resourceDescription then
        hud.resourceDescription:SetText(T(
            "Resources: %s • Style: %s • Text: %s • Rune spacing: %s",
            self:GetResourceHUDModeLabel(),
            self:GetResourceHUDStyleLabel(),
            T(DB.resourceHUD.showPowerText ~= false and "ON" or "OFF"),
            self:GetResourceRuneSpacingLabel()
        ))
    end
    if hud.interruptButton then hud.interruptButton:SetText(DB.interruptAlert.enabled and T("Interrupt alert: ON") or T("Interrupt alert: OFF")) end
    if hud.combatOnlyButton then hud.combatOnlyButton:SetText(DB.combatBarsOnlyInCombat and T("Bars only in combat: ON") or T("Bars only in combat: OFF")) end
    if hud.lockButton then hud.lockButton:SetText(DB.hudLocked and T("HUDs: LOCKED") or T("HUDs: UNLOCKED")) end
    if hud.previewButton then hud.previewButton:SetText(self.hudPreviewMode == true and T("Preview HUDs: ON") or T("Preview HUDs: OFF")) end
    self:UpdateHUDMoveHints()
end

function addon:UpdateGuideSection()
    if not mainFrame or not mainFrame.guideSection then
        return
    end

    local specID, specName = self:GetSpecInfo()
    local guide = mainFrame.guideSection
    local specGuide = Guides[specID] or { title = specName, sections = {} }
    local generalGuide = Guides.general or { sections = {} }
    local contentGuide = Guides.content or { sections = {} }
    local lines = {}

    local function AddSection(section)
        if not section then return end
        table.insert(lines, "|cffffcc55" .. tostring(section.heading or "") .. "|r")
        table.insert(lines, tostring(section.body or ""))
        table.insert(lines, "")
    end

    guide.specTitle:SetText(T("Beginner guide — %s", tostring(specGuide.title or specName)))
    table.insert(lines, "|cff89d8ff" .. tostring(generalGuide.title or T("Death Knight fundamentals")) .. "|r")
    table.insert(lines, "")
    for _, section in ipairs(generalGuide.sections or {}) do
        AddSection(section)
    end

    table.insert(lines, "|cff89d8ff" .. tostring(specGuide.title or specName) .. "|r")
    table.insert(lines, "")
    for _, section in ipairs(specGuide.sections or {}) do
        AddSection(section)
    end

    table.insert(lines, "|cff89d8ff" .. tostring(contentGuide.title or T("Content tips")) .. "|r")
    table.insert(lines, "")
    for _, section in ipairs(contentGuide.sections or {}) do
        AddSection(section)
    end

    table.insert(lines, "|cff999999" .. tostring(Guides.footer or "") .. "|r")
    guide.text:SetText(table.concat(lines, "\n"))
    local height = guide.text:GetStringHeight() or 1
    guide.content:SetHeight(math.max(1, height + 12))
end


function addon:UpdateAll()
    if not self.active or not self:IsDeathKnight() then
        return
    end

    self:UpdateHeader()
    self:UpdateModeButtons()
    self:UpdateAssistedCombatSection()
    self:UpdateBuildSection()
    self:UpdateVoiceSection()
    self:UpdateSurvivalTips()
    self:UpdateCoach()
    self:RefreshCoachVisibility()
    self:UpdateStatusWidget()
    self:RefreshStatusWidgetVisibility()
    self:UpdateGuideSection()
    self:UpdateHUDSettings()
    self:RefreshCombatHUDVisibility()
end

function addon:ToggleMainFrame()
    if not self.active then
        return
    end

    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        self:UpdateAll()
    end
end

function addon:ResetHUDPositions()
    if not DB then return end
    if InCombatLockdown and InCombatLockdown() then
        Print(T("HUD positions cannot be changed during combat."))
        return
    end
    local function ResetFramePosition(key, defaults)
        DB[key] = DB[key] or {}
        DB[key].point = defaults.point
        DB[key].relativePoint = defaults.relativePoint
        DB[key].x = defaults.x
        DB[key].y = defaults.y
    end

    ResetFramePosition("coach", DEFAULTS.coach)
    ResetFramePosition("statusWidget", DEFAULTS.statusWidget)
    ResetFramePosition("buffBar", DEFAULTS.buffBar)
    ResetFramePosition("externalBuffBar", DEFAULTS.externalBuffBar)
    ResetFramePosition("debuffBar", DEFAULTS.debuffBar)
    ResetFramePosition("abilityBar", DEFAULTS.abilityBar)
    ResetFramePosition("resourceHUD", DEFAULTS.resourceHUD)
    ResetResourceArcPosition()
    ResetFramePosition("interruptAlert", DEFAULTS.interruptAlert)
    RestoreFramePosition(coachFrame, "coach")
    RestoreFramePosition(statusWidget, "statusWidget")
    RestoreFramePosition(buffFrame, "buffBar")
    RestoreFramePosition(externalBuffFrame, "externalBuffBar")
    RestoreFramePosition(debuffFrame, "debuffBar")
    RestoreFramePosition(abilityFrame, "abilityBar")
    RestoreFramePosition(resourceFrame, "resourceHUD")
    if resourceArcFrame then RestoreResourceArcPosition(resourceArcFrame) end
    RestoreFramePosition(interruptFrame, "interruptAlert")
    Print(T("Combat HUD positions restored."))
end

function addon:ResetPositions()
    if InCombatLockdown and InCombatLockdown() then
        Print(T("HUD positions cannot be changed during combat."))
        return
    end
    local function ResetFramePosition(key, defaults)
        DB[key] = DB[key] or {}
        DB[key].point = defaults.point
        DB[key].relativePoint = defaults.relativePoint
        DB[key].x = defaults.x
        DB[key].y = defaults.y
        DB[key].scale = defaults.scale
        if defaults.iconsPerRow then DB[key].iconsPerRow = defaults.iconsPerRow end
    end

    ResetFramePosition("main", DEFAULTS.main)
    ResetFramePosition("coach", DEFAULTS.coach)
    ResetFramePosition("statusWidget", DEFAULTS.statusWidget)
    ResetFramePosition("buffBar", DEFAULTS.buffBar)
    ResetFramePosition("externalBuffBar", DEFAULTS.externalBuffBar)
    ResetFramePosition("debuffBar", DEFAULTS.debuffBar)
    ResetFramePosition("abilityBar", DEFAULTS.abilityBar)
    ResetFramePosition("resourceHUD", DEFAULTS.resourceHUD)
    ResetResourceArcPosition()
    ResetFramePosition("interruptAlert", DEFAULTS.interruptAlert)
    RestoreFramePosition(mainFrame, "main")
    RestoreFramePosition(coachFrame, "coach")
    RestoreFramePosition(statusWidget, "statusWidget")
    RestoreFramePosition(buffFrame, "buffBar")
    RestoreFramePosition(externalBuffFrame, "externalBuffBar")
    RestoreFramePosition(debuffFrame, "debuffBar")
    RestoreFramePosition(abilityFrame, "abilityBar")
    RestoreFramePosition(resourceFrame, "resourceHUD")
    if resourceArcFrame then RestoreResourceArcPosition(resourceArcFrame) end
    RestoreFramePosition(interruptFrame, "interruptAlert")
    for dbKey in pairs(COMBAT_BAR_LAYOUT_LIMITS) do self:ApplyCombatBarLayout(dbKey) end
    self:UpdateBarLayoutFrame()
    Print(T("Frame positions and scale restored. HUD visibility settings were kept."))
end

function addon:SetMode(mode)
    if not DB then return end
    DB.modeOverride = "auto"
    self:UpdateAll()
    Print(T("Content detection is automatic. DK Mentor follows the current game environment."))
end

function addon:ShowHelp()
    Print(T("/dkm — open or close the main window"))
    Print(T("/dkm mode — content detection is automatic"))
    Print(T("/dkm build — open Build Manager"))
    Print(T("/dkm build choose — choose an existing WoW talent loadout for this content"))
    Print(T("/dkm build current — bind the currently active WoW loadout"))
    Print(T("/dkm build create — create a DKM copy from the current talents"))
    Print(T("/dkm build clear — clear the saved loadout for this content"))
    Print(T("/dkm build auto on|off — auto-switch saved talent loadouts by content"))
    Print(T("/dkm gear choose — choose an existing WoW equipment set for this content"))
    Print(T("/dkm gear equipped — bind the currently equipped saved set"))
    Print(T("/dkm gear clear — clear the equipment-set association for this content"))
    Print(T("/dkm gear auto on|off — auto-switch saved equipment sets by content"))
    Print(T("/dkm coach on|off — show or hide the compact survival coach"))
    Print(T("/dkm coach health on|off — toggle health-adaptive recommendations"))
    Print(T("/dkm hud on|off — show or hide the movable specialization/build HUD"))
    Print(T("/dkm hud lock|unlock|preview — arrange combat HUDs"))
    Print(T("/dkm buffs on|off — show or hide the movable DK buff bar"))
    Print(T("/dkm externalbuffs on|off — show or hide buffs received from others"))
    Print(T("/dkm debuffs on|off — show or hide harmful effects on yourself"))
    Print(T("/dkm abilities on|off — show or hide the ability availability bar"))
    Print(T("/dkm resources on|off — show or hide the Runes + Runic Power HUD"))
    Print(T("/dkm resources runes on|off — show or hide Rune segments"))
    Print(T("/dkm resources power on|off — show or hide Runic Power"))
    Print(T("/dkm resources style classic|arcs — choose the DK Resources visual style"))
    Print(T("/dkm interrupt on|off — show or hide the Mind Freeze interrupt alert"))
    Print(T("/dkm combatbars combat|always - show aura/ability bars only in combat or always"))
    Print(T("/dkm guide — open the beginner specialization guide"))
    Print(T("/dkm settings — open HUD and commentary settings"))
    Print(T("/dkm language auto|ptbr|en — change DK Mentor language"))
    Print(T("/dkm voice on|off|test|low|normal|high|status|map|reset"))
    Print(T("/dkm voice pvp on|off — allow or mute commentary in PvP"))
    Print(T("/dkm voice situations on|off — toggle contextual spell/mount/hearthstone/AFK comments"))
    Print(T("/dkm voice map — choose a voice per situation"))
    Print(T("/dkm rotation — toggle the native offensive highlight"))
    Print(T("/dkm bars — check native rotation spells on your action bars"))
    Print(T("/dkm ready — show the DK Ready Check details"))
    Print(T("/dkm reset — restore frame positions"))
end

function addon:HandleSlashCommand(message)
    message = Trim(message)
    local command, rest = message:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    rest = Trim(rest)

    if command == "" or command == "toggle" then
        self:ToggleMainFrame()
        return
    end

    if command == "help" then
        self:ShowHelp()
    elseif command == "mode" then
        local map = { auto = "auto", world = "world", delve = "delve", dungeon = "dungeon", mplus = "mythicplus", mythicplus = "mythicplus", raid = "raid", pvp = "pvp" }
        self:SetMode(map[string.lower(rest)] or rest)
    elseif command == "guide" then
        mainFrame:Show()
        self:SetMainTab("guide")
        self:UpdateAll()
    elseif command == "settings" or command == "config" then
        mainFrame:Show()
        self:SetMainTab("settings")
        self:UpdateAll()
    elseif command == "language" or command == "lang" or command == "idioma" then
        local languageValue = string.lower(Trim(rest))
        if languageValue == "" then
            self:ToggleLanguagePicker()
        elseif languageValue == "auto" or languageValue == "wow" then
            self:SetLanguageOverride("auto")
        elseif languageValue == "pt" or languageValue == "ptbr" or languageValue == "portuguese" or languageValue == "portugues" then
            self:SetLanguageOverride("ptBR")
        elseif languageValue == "en" or languageValue == "enus" or languageValue == "engb" or languageValue == "english" then
            self:SetLanguageOverride("enUS")
        else
            self:ToggleLanguagePicker()
        end
    elseif command == "buffs" or command == "buff" then
        local value = string.lower(Trim(rest))
        if value == "on" or value == "show" then
            self:SetBuffBarEnabled(true)
        elseif value == "off" or value == "hide" then
            self:SetBuffBarEnabled(false)
        else
            self:SetBuffBarEnabled(not DB.buffBar.enabled)
        end
    elseif command == "externalbuffs" or command == "externalbuff" or command == "extbuffs" then
        local value = string.lower(Trim(rest))
        if value == "on" or value == "show" then
            self:SetExternalBuffBarEnabled(true)
        elseif value == "off" or value == "hide" then
            self:SetExternalBuffBarEnabled(false)
        else
            self:SetExternalBuffBarEnabled(not DB.externalBuffBar.enabled)
        end
    elseif command == "debuffs" or command == "debuff" then
        local value = string.lower(Trim(rest))
        if value == "on" or value == "show" then
            self:SetDebuffBarEnabled(true)
        elseif value == "off" or value == "hide" then
            self:SetDebuffBarEnabled(false)
        else
            self:SetDebuffBarEnabled(not DB.debuffBar.enabled)
        end
    elseif command == "abilities" or command == "ability" or command == "cooldowns" then
        local value = string.lower(Trim(rest))
        if value == "on" or value == "show" then
            self:SetAbilityBarEnabled(true)
        elseif value == "off" or value == "hide" then
            self:SetAbilityBarEnabled(false)
        else
            self:SetAbilityBarEnabled(not DB.abilityBar.enabled)
        end
    elseif command == "resources" or command == "resource" then
        local resourceAction, resourceValue = rest:match("^(%S*)%s*(.-)$")
        resourceAction = string.lower(resourceAction or "")
        resourceValue = string.lower(Trim(resourceValue))
        if resourceAction == "runes" or resourceAction == "rune" then
            if resourceValue == "on" or resourceValue == "show" then
                self:SetResourceHUDRunesEnabled(true)
            elseif resourceValue == "off" or resourceValue == "hide" then
                self:SetResourceHUDRunesEnabled(false)
            else
                self:SetResourceHUDRunesEnabled(not DB.resourceHUD.showRunes)
            end
        elseif resourceAction == "power" or resourceAction == "runic" or resourceAction == "runicpower" then
            if resourceValue == "on" or resourceValue == "show" then
                self:SetResourceHUDRunicPowerEnabled(true)
            elseif resourceValue == "off" or resourceValue == "hide" then
                self:SetResourceHUDRunicPowerEnabled(false)
            else
                self:SetResourceHUDRunicPowerEnabled(not DB.resourceHUD.showRunicPower)
            end
        elseif resourceAction == "style" or resourceAction == "view" then
            if resourceValue == "arc" or resourceValue == "arcs" or resourceValue == "icehud" then
                if NormalizeResourceHUDStyle(DB.resourceHUD.style) ~= "arcs" then self:CycleResourceHUDStyle() end
            elseif resourceValue == "classic" or resourceValue == "bars" then
                if NormalizeResourceHUDStyle(DB.resourceHUD.style) ~= "classic" then self:CycleResourceHUDStyle() end
            else
                self:CycleResourceHUDStyle()
            end
        elseif resourceAction == "on" or resourceAction == "show" then
            self:SetResourceHUDEnabled(true)
        elseif resourceAction == "off" or resourceAction == "hide" then
            self:SetResourceHUDEnabled(false)
        else
            self:SetResourceHUDEnabled(not DB.resourceHUD.enabled)
        end
    elseif command == "interrupt" or command == "kick" then
        local value = string.lower(Trim(rest))
        if value == "on" or value == "show" then
            self:SetInterruptAlertEnabled(true)
        elseif value == "off" or value == "hide" then
            self:SetInterruptAlertEnabled(false)
        else
            self:SetInterruptAlertEnabled(not DB.interruptAlert.enabled)
        end
    elseif command == "combatbars" or command == "hudbars" then
        local value = string.lower(Trim(rest))
        if value == "combat" or value == "combatonly" or value == "on" then
            self:SetCombatBarsOnlyInCombat(true)
        elseif value == "always" or value == "off" then
            self:SetCombatBarsOnlyInCombat(false)
        else
            self:SetCombatBarsOnlyInCombat(not DB.combatBarsOnlyInCombat)
        end
    elseif command == "build" then
        local buildAction, buildValue = rest:match("^(%S*)%s*(.-)$")
        buildAction = string.lower(buildAction or "")
        buildValue = string.lower(Trim(buildValue))
        if buildAction == "choose" or buildAction == "map" then
            self:OpenLoadoutPicker()
        elseif buildAction == "current" or buildAction == "save" then
            self:BindCurrentLoadout()
        elseif buildAction == "create" then
            self:SaveCurrentLoadoutBinding()
        elseif buildAction == "clear" then
            self:ClearCurrentLoadoutBinding()
        elseif buildAction == "auto" then
            if buildValue == "on" then self:SetAutoSwitchLoadouts(true)
            elseif buildValue == "off" then self:SetAutoSwitchLoadouts(false)
            else self:ToggleAutoSwitchLoadouts() end
        else
            mainFrame:Show()
            self:SetMainTab("builds")
            self:UpdateAll()
        end
    elseif command == "gear" or command == "equipment" then
        local gearAction, gearValue = rest:match("^(%S*)%s*(.-)$")
        gearAction = string.lower(gearAction or "")
        gearValue = string.lower(Trim(gearValue))
        if gearAction == "choose" or gearAction == "map" then
            self:OpenEquipmentPicker()
        elseif gearAction == "equipped" or gearAction == "current" or gearAction == "save" then
            self:BindCurrentlyEquippedEquipmentSet()
        elseif gearAction == "clear" then
            self:ClearCurrentEquipmentBinding()
        elseif gearAction == "auto" then
            if gearValue == "on" then self:SetAutoSwitchEquipment(true)
            elseif gearValue == "off" then self:SetAutoSwitchEquipment(false)
            else self:ToggleAutoSwitchEquipment() end
        else
            mainFrame:Show()
            self:SetMainTab("builds")
            self:UpdateAll()
        end
    elseif command == "coach" then
        local coachAction, coachValue = rest:match("^(%S*)%s*(.-)$")
        coachAction = string.lower(coachAction or "")
        coachValue = string.lower(Trim(coachValue))
        if coachAction == "health" then
            if coachValue == "on" then DB.coach.adaptiveHealth = true
            elseif coachValue == "off" then DB.coach.adaptiveHealth = false
            else DB.coach.adaptiveHealth = not DB.coach.adaptiveHealth end
            self:UpdateCoach()
            Print(T(DB.coach.adaptiveHealth and "Health-adaptive recommendations enabled." or "Health-adaptive recommendations disabled."))
        elseif coachAction == "on" or coachAction == "show" then
            self:SetCoachEnabled(true)
        elseif coachAction == "off" or coachAction == "hide" then
            self:SetCoachEnabled(false)
        else
            self:SetCoachEnabled(not DB.coach.enabled)
        end
    elseif command == "hud" then
        local hudValue = string.lower(Trim(rest))
        if hudValue == "unlock" then self:SetHUDsLocked(false)
        elseif hudValue == "lock" then self:SetHUDsLocked(true)
        elseif hudValue == "preview" then self:ToggleHUDPreview()
        elseif hudValue == "on" or hudValue == "show" then self:SetStatusWidgetEnabled(true)
        elseif hudValue == "off" or hudValue == "hide" then self:SetStatusWidgetEnabled(false)
        else self:SetStatusWidgetEnabled(not DB.statusWidget.enabled) end
    elseif command == "voice" then
        self:HandleVoiceCommand(rest)
    elseif command == "rotation" then
        self:ToggleNativeHighlight()
    elseif command == "bars" or command == "bar" then
        self:CheckActionBarCoverage(false)
    elseif command == "ready" or command == "readycheck" then
        self:PrintReadyCheckStatus()
    elseif command == "reset" then
        self:ResetPositions()
    else
        self:ShowHelp()
    end
end

function addon:InitializeDatabase()
    _G.DKMentorDB = _G.DKMentorDB or {}
    DB = _G.DKMentorDB
    local previousSchema = tonumber(DB.schema or 0) or 0
    ApplyDefaults(DB, DEFAULTS)
    DB.languageOverride = NormalizeAddonLanguage(DB.languageOverride)
    if DKM.SetLocaleOverride then
        DKM.SetLocaleOverride(DB.languageOverride)
    end

    if previousSchema < 16 then
        DB.autoSwitchLoadouts = true
        DB.autoSwitchEquipment = true
        if DB.buildContextSelection == nil or DB.buildContextSelection == "auto" then
            DB.buildContextSelection = self:DetectActualContext()
        end
    end

    -- 1.0.16 regression repair: the combat HUD setting accidentally defaulted
    -- back to Always. Restore combat-only behavior once during migration. Users
    -- can still switch it off explicitly from Settings afterwards.
    if previousSchema < 21 then
        DB.combatBarsOnlyInCombat = true
    end

    -- 1.1.5 separates the movable DK Arcs position from the Classic resource HUD.
    -- Existing Arc users keep the last shared resource position; Classic users
    -- receive the centered Arc default on first use.
    if previousSchema < 26 then
        if DB.resourceHUD and DB.resourceHUD.style == "arcs" then
            DB.resourceHUD.arcPoint = DB.resourceHUD.point or DEFAULTS.resourceHUD.arcPoint
            DB.resourceHUD.arcRelativePoint = DB.resourceHUD.relativePoint or DEFAULTS.resourceHUD.arcRelativePoint
            DB.resourceHUD.arcX = tonumber(DB.resourceHUD.x) or DEFAULTS.resourceHUD.arcX
            DB.resourceHUD.arcY = tonumber(DB.resourceHUD.y) or DEFAULTS.resourceHUD.arcY
        else
            DB.resourceHUD.arcPoint = DEFAULTS.resourceHUD.arcPoint
            DB.resourceHUD.arcRelativePoint = DEFAULTS.resourceHUD.arcRelativePoint
            DB.resourceHUD.arcX = DEFAULTS.resourceHUD.arcX
            DB.resourceHUD.arcY = DEFAULTS.resourceHUD.arcY
        end
        DB.resourceHUD.arcSpacing = NormalizeResourceArcSpacing(DB.resourceHUD.arcSpacing or DEFAULTS.resourceHUD.arcSpacing)
    end

    -- 1.0.8 deliberately removes the experimental War Mode profile/button.
    -- Clean only state introduced by those experimental builds so the proven
    -- World/Delve/Dungeon/Raid/PvP mappings remain untouched.
    local validBuildModes = { world = true, delve = true, dungeon = true, mythicplus = true, raid = true, pvp = true }

    -- Manual runtime overrides were removed. Always migrate them back to Auto
    -- while preserving the independent Loadouts configuration selection.
    DB.modeOverride = "auto"
    if not validBuildModes[DB.buildContextSelection] then
        DB.buildContextSelection = self:DetectActualContext()
    end

    local function RemoveExperimentalWarModeKeys(tbl)
        if type(tbl) ~= "table" then return end
        for key in pairs(tbl) do
            if type(key) == "string" and key:find(":warmode", 1, true) then
                tbl[key] = nil
            end
        end
    end

    RemoveExperimentalWarModeKeys(DB.selectedBuild)
    RemoveExperimentalWarModeKeys(DB.personalBuildCodes)
    RemoveExperimentalWarModeKeys(DB.loadoutBindings)
    RemoveExperimentalWarModeKeys(DB.equipmentBindings)

    -- 1.2.0 Loadouts 2.0 adds optional content-level specialization mapping
    -- plus partial per-dungeon overrides. Existing talent/equipment mappings
    -- remain untouched; nil specialization bindings intentionally mean keep
    -- the player's current specialization.
    if previousSchema < 28 then
        DB.specializationBindings = type(DB.specializationBindings) == "table" and DB.specializationBindings or {}
        DB.dungeonOverrides = type(DB.dungeonOverrides) == "table" and DB.dungeonOverrides or {}
        DB.knownDungeons = type(DB.knownDungeons) == "table" and DB.knownDungeons or {}
        if DB.autoSwitchSpecialization == nil then DB.autoSwitchSpecialization = true end
    end

    -- 1.2.1 adopts the proven Loadout Pilot dungeon model: separate Dungeon
    -- and Mythic+ defaults, one InstanceID-based override shared by all
    -- difficulties, and an independent per-dungeon Loot Specialization.
    if previousSchema < 29 then
        DB.specializationBindings = type(DB.specializationBindings) == "table" and DB.specializationBindings or {}
        DB.dungeonOverrides = type(DB.dungeonOverrides) == "table" and DB.dungeonOverrides or {}
        DB.knownDungeons = type(DB.knownDungeons) == "table" and DB.knownDungeons or {}

        -- Existing 1.2.0 users used Dungeon for both regular dungeons and M+.
        -- Seed the new Mythic+ defaults from those mappings once so upgrading
        -- never makes an established M+ setup suddenly look unconfigured.
        if DB.specializationBindings.mythicplus == nil then
            DB.specializationBindings.mythicplus = DB.specializationBindings.dungeon
        end
        for _, specID in ipairs({ 250, 251, 252 }) do
            local dungeonKey = tostring(specID) .. ":dungeon"
            local mythicKey = tostring(specID) .. ":mythicplus"
            if DB.loadoutBindings[mythicKey] == nil and DB.loadoutBindings[dungeonKey] ~= nil then
                DB.loadoutBindings[mythicKey] = DeepCopy(DB.loadoutBindings[dungeonKey])
            end
            if DB.equipmentBindings[mythicKey] == nil and DB.equipmentBindings[dungeonKey] ~= nil then
                DB.equipmentBindings[mythicKey] = DeepCopy(DB.equipmentBindings[dungeonKey])
            end
            if DB.selectedBuild[mythicKey] == nil and DB.selectedBuild[dungeonKey] ~= nil then
                DB.selectedBuild[mythicKey] = DB.selectedBuild[dungeonKey]
            end
            for profileIndex = 1, 8 do
                local oldCodeKey = dungeonKey .. ":" .. tostring(profileIndex)
                local newCodeKey = mythicKey .. ":" .. tostring(profileIndex)
                if DB.personalBuildCodes[newCodeKey] == nil and DB.personalBuildCodes[oldCodeKey] ~= nil then
                    DB.personalBuildCodes[newCodeKey] = DB.personalBuildCodes[oldCodeKey]
                end
            end
        end
        self:MigrateUnifiedDungeonOverrides()
    end

    DB.schema = DEFAULTS.schema
end

function addon:CreateUI()
    mainFrame = CreateMainFrame()
    coachFrame = CreateCoachFrame()
    statusWidget = CreateStatusWidget()
    specializationPickerFrame = CreateSpecializationPickerFrame(statusWidget)
    buffFrame = CreateBuffBar()
    externalBuffFrame = CreateExternalBuffBar()
    debuffFrame = CreateDebuffBar()
    abilityFrame = CreateAbilityBar()
    resourceFrame = CreateResourceHUD()
    resourceArcFrame = CreateResourceArcHUD()
    interruptFrame = CreateInterruptAlert()
    barLayoutFrame = CreateBarLayoutFrame()
    loadoutPickerFrame = CreateLoadoutPickerFrame()
    equipmentPickerFrame = CreateEquipmentPickerFrame()
    self.profileSpecializationPickerFrame = self:CreateProfileSpecializationPickerFrame()
    self.lootSpecializationPickerFrame = self:CreateLootSpecializationPickerFrame()
    self.dungeonOverridesFrame = self:CreateDungeonOverridesFrame()
    self.dungeonOverrideEditorFrame = self:CreateDungeonOverrideEditorFrame()
    voiceConfigFrame = CreateVoiceConfigFrame()
    languagePickerFrame = CreateLanguagePickerFrame()
    minimapButton = CreateMinimapButton()
    for dbKey in pairs(COMBAT_BAR_LAYOUT_LIMITS) do self:ApplyCombatBarLayout(dbKey) end
    self:UpdateBarLayoutFrame()
    self:UpdateMinimapPosition()
    self:UpdateHUDMoveHints()
end

function addon:RegisterRuntimeEvents()
    -- Some events can change between client builds. Registering them safely
    -- prevents a removed event name from stopping the entire addon from loading.
    local events = {
        "PLAYER_LOGIN",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_SPECIALIZATION_CHANGED",
        "SPECIALIZATION_CHANGE_CAST_FAILED",
        "ACTIVE_TALENT_GROUP_CHANGED",
        "PLAYER_TALENT_UPDATE",
        "TRAIT_CONFIG_UPDATED",
        "TRAIT_CONFIG_CREATED",
        "TRAIT_CONFIG_LIST_UPDATED",
        "SELECTED_LOADOUT_CHANGED",
        "ACTIVE_COMBAT_CONFIG_CHANGED",
        "CONFIG_COMMIT_FAILED",
        "PLAYER_ENTERING_BATTLEGROUND",
        "EQUIPMENT_SETS_CHANGED",
        "EQUIPMENT_SWAP_FINISHED",
        "PLAYER_EQUIPMENT_CHANGED",
        "UNIT_INVENTORY_CHANGED",
        "UNIT_AURA",
        "SPELL_UPDATE_COOLDOWN",
        "SPELL_UPDATE_CHARGES",
        "ACTIONBAR_UPDATE_USABLE",
        "UNIT_POWER_UPDATE",
        "UNIT_DISPLAYPOWER",
        "RUNE_POWER_UPDATE",
        "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW",
        "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE",
        "COOLDOWN_VIEWER_DATA_LOADED",
        "COOLDOWN_VIEWER_TABLE_HOTFIXED",
        "COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED",
        "ADDON_RESTRICTION_STATE_CHANGED",
        "SPELLS_CHANGED",
        "ACTIONBAR_SLOT_CHANGED",
        "ZONE_CHANGED_NEW_AREA",
        "PLAYER_MOUNT_DISPLAY_CHANGED",
        "PLAYER_FLAGS_CHANGED",
        "UNIT_PET",
        "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED",
        "UNIT_HEALTH",
        "UNIT_MAXHEALTH",
        "PLAYER_DEAD",
        "PLAYER_ALIVE",
        "PLAYER_UNGHOST",
        "ENCOUNTER_START",
        "ENCOUNTER_END",
        "UNIT_SPELLCAST_SENT",
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTIBLE",
        "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
        "PLAYER_TARGET_CHANGED",
        "ITEM_DATA_LOAD_RESULT",
        "NEW_MOUNT_ADDED",
        "PVP_MATCH_COMPLETE",
        "UPDATE_BATTLEFIELD_STATUS",
        "PLAYER_ROLES_ASSIGNED",
        "PLAYER_LOOT_SPEC_UPDATED",
        "CHALLENGE_MODE_KEYSTONE_SLOTTED",
        "CHALLENGE_MODE_RESET",
        "CVAR_UPDATE",
        "PVP_MATCH_ACTIVE",
        "PLAYER_PVP_TALENT_UPDATE",
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_COMPLETED",
    }

    for _, eventName in ipairs(events) do
        pcall(self.RegisterEvent, self, eventName)
    end
end

function addon:ScheduleUpdate(checkBar)
    updateNeedsBarCheck = updateNeedsBarCheck or checkBar == true
    if updateScheduled then
        return
    end
    updateScheduled = true
    C_Timer.After(0.25, function()
        updateScheduled = false
        if addon.active then
            local doBarCheck = updateNeedsBarCheck
            updateNeedsBarCheck = false
            addon:UpdateAll()
            if doBarCheck then
                addon:CheckActionBarCoverage(true)
            end
        else
            updateNeedsBarCheck = false
        end
    end)
end

addon:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ADDON_NAME then
            return
        end

        self:InitializeDatabase()
        self:CreateUI()
        self:RegisterRuntimeEvents()
        self:UnregisterEvent("ADDON_LOADED")
        return
    end

    if event == "PLAYER_LOGIN" then
        if not self:IsDeathKnight() then
            self.active = false
            mainFrame:Hide()
            coachFrame:Hide()
            statusWidget:Hide()
            if specializationPickerFrame then specializationPickerFrame:Hide() end
            buffFrame:Hide()
            abilityFrame:Hide()
            if resourceFrame then resourceFrame:Hide() end
            if interruptFrame then interruptFrame:Hide() end
            voiceConfigFrame:Hide()
            minimapButton:Hide()
            Print(T("This addon only runs on Death Knights."))
            return
        end

        self.active = true
        self.worldReady = false
        self.playerWasDead = false
        if UnitIsDeadOrGhost then
            local ok, rawDead = pcall(UnitIsDeadOrGhost, "player")
            local dead = GetAccessibleBooleanFromCall(ok, rawDead)
            self.playerWasDead = dead == true
        end
        self.lastMountedState = false
        if IsMounted then
            local ok, rawMounted = pcall(IsMounted)
            local mounted = GetAccessibleBooleanFromCall(ok, rawMounted)
            self.lastMountedState = mounted == true
        end
        if DB.minimap.show then
            minimapButton:Show()
        end
        self:UpdateAll()
        self:CheckActionBarCoverage(true)

        if DB.firstRun then
            DB.firstRun = false
            mainFrame:Show()
            Print(T("Ready. Enable the native highlight, review your build focus, and use /dkm help to view commands."))
        end

        self:RefreshCoachVisibility()
        self:RefreshStatusWidgetVisibility()
        self:RefreshCombatHUDVisibility()
        -- Do not scan mounts/items or switch talents/gear during PLAYER_LOGIN.
        -- Those operations are deferred until the player has entered the world.
        C_Timer.After(1.5, function()
            if addon.active then
                addon:TryVoiceComment("login", { cooldown = 20 })
            end
        end)
        return
    end

    if not self.active then
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        self.combatEventState = true
        if specializationPickerFrame then specializationPickerFrame:Hide() end
        self:SyncReadableBuffRuntime(false)
        combatStartedAt = GetNow()
        self.mainWasVisibleBeforeCombat = mainFrame:IsShown()
        if DB.autoHideMainInCombat and self.mainWasVisibleBeforeCombat then
            mainFrame:Hide()
        end
        self:TryVoiceComment("combatStart")
        if DB.coach.enabled then
            coachFrame:Show()
        end
        self:UpdateCoach()
        self:RefreshCoachVisibility()
        -- Buff/cooldown HUDs must remain live after restrictions activate.
        -- Re-scan already-loaded Blizzard viewer frames because their secret
        -- active-state signals remain usable even after combat begins.
        if not (buffFrame and buffFrame.managedAuraContainer) then
            self:RefreshCooldownViewerBuffMirrors()
        end
        self:UpdateBuffBar()
        self:UpdateExternalBuffBar()
        self:UpdateDebuffBar()
        self:UpdateAbilityBar()
        self:UpdateResourceHUD()
    elseif event == "PLAYER_REGEN_ENABLED" then
        self.combatEventState = false
        local combatDuration = combatStartedAt and (GetNow() - combatStartedAt) or 0
        -- Remove proc-only fallbacks that may have missed a HIDE event during
        -- restricted combat, then rebuild from actually readable auras/viewers.
        self:ClearTransientProcStates()
        self:SyncReadableBuffRuntime(true)
        combatStartedAt = nil

        -- Hide combat-only bars immediately on the definitive combat-end event.
        -- UpdateAll below will repopulate only the bars the user's settings allow.
        if DB.combatBarsOnlyInCombat == true and self.hudPreviewMode ~= true then
            if buffFrame then buffFrame:Hide() end
            if externalBuffFrame then externalBuffFrame:Hide() end
            if debuffFrame then debuffFrame:Hide() end
            if abilityFrame then abilityFrame:Hide() end
            if resourceFrame then resourceFrame:Hide() end
            if interruptFrame then interruptFrame:Hide() end
        end
        if DB.autoHideMainInCombat and self.mainWasVisibleBeforeCombat then
            mainFrame:Show()
        end
        self.mainWasVisibleBeforeCombat = false
        local playerAliveConfirmed = true
        if UnitIsDeadOrGhost then
            local ok, rawDead = pcall(UnitIsDeadOrGhost, "player")
            local dead = GetAccessibleBooleanFromCall(ok, rawDead)
            playerAliveConfirmed = dead == false
        end
        if combatDuration >= 8 and playerAliveConfirmed then
            self:TryVoiceComment("combatVictory")
        end
        if not (buffFrame and buffFrame.managedAuraContainer) then
            self:RefreshCooldownViewerBuffMirrors()
        end
        self:RefreshManagedDKBuffFilter()
        self:UpdateAll()
        self:RefreshCombatHUDVisibility()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if addon.active then addon:RefreshCombatHUDVisibility() end
            end)
            C_Timer.After(0.25, function()
                if addon.active then
                    addon:SyncCombatEventState()
                    addon:RefreshCombatHUDVisibility()
                end
            end)
        end
        self:ApplyAutomaticProfile("combat-ended")
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            -- During unrestricted periods this keeps an exact cache. During
            -- restricted combat, unreadable auras do not clear the event/cast
            -- fallback state, so the bar keeps reacting instead of freezing.
            local clearMissing = not (InCombatLockdown and InCombatLockdown())
            self:SyncReadableBuffRuntime(clearMissing)
            self:UpdateBuffBar()
            self:UpdateExternalBuffBar()
            self:UpdateDebuffBar()
        end
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local spellID = ...
        if IsAccessibleNumber(spellID) then
            self:TrackRuntimeProc(spellID, event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
            self:UpdateBuffBar()
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" or event == "ACTIONBAR_UPDATE_USABLE" then
        self:UpdateAbilityBar()
        self:UpdateInterruptAlert()
    elseif event == "UNIT_POWER_UPDATE" then
        local unit = ...
        if unit == "player" then
            self:UpdateAbilityBar()
            self:UpdateRunicPowerHUD()
        end
    elseif event == "UNIT_DISPLAYPOWER" then
        local unit = ...
        if not unit or unit == "player" then
            self:UpdateResourceHUD()
        end
    elseif event == "RUNE_POWER_UPDATE" then
        self:UpdateAbilityBar()
        self:UpdateResourceRunes()
    elseif event == "COOLDOWN_VIEWER_DATA_LOADED" or event == "COOLDOWN_VIEWER_TABLE_HOTFIXED" or event == "COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED" then
        InvalidateCooldownManagerProfileCache()
        if not (buffFrame and buffFrame.managedAuraContainer) then
            self:RefreshCooldownViewerBuffMirrors()
        end
        self:RefreshManagedDKBuffFilter()
        self:UpdateBuffBar()
        self:UpdateAbilityBar()
        self:UpdateInterruptAlert()
    elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
        -- Midnight can switch secret-data restrictions without a normal aura
        -- or cooldown event. Refresh every visual tracker at that boundary.
        if not (buffFrame and buffFrame.managedAuraContainer) then
            self:RefreshCooldownViewerBuffMirrors()
        end
        self:UpdateBuffBar()
        self:UpdateExternalBuffBar()
        self:UpdateDebuffBar()
        self:UpdateAbilityBar()
        self:UpdateResourceHUD()
        self:UpdateInterruptAlert()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...
        if unit == "player" then
            self:UpdateCoach()
        end
    elseif event == "PLAYER_DEAD" then
        self.playerWasDead = true
        self:TryVoiceComment("death", { cooldown = 12 })
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        if self.playerWasDead then
            self.playerWasDead = false
            C_Timer.After(1, function()
                if addon.active then
                    addon:TryVoiceComment("resurrection", { cooldown = 12 })
                end
            end)
        end
    elseif event == "ENCOUNTER_START" then
        self:TryVoiceComment("encounterStart", { cooldown = 20 })
    elseif event == "ENCOUNTER_END" then
        local success = select(5, ...)
        if success == 1 then
            C_Timer.After(1.25, function()
                if addon.active then
                    addon:TryVoiceComment("encounterVictory", { cooldown = 20 })
                end
            end)
        end
    elseif event == "TRAIT_CONFIG_CREATED" then
        local configInfo = ...
        self:FinishPendingLoadoutCreation(configInfo)
        self:ScheduleUpdate(false)
    elseif event == "TRAIT_CONFIG_LIST_UPDATED" then
        if pendingLoadoutCreation then
            local pending = pendingLoadoutCreation
            local configID, name = self:FindSavedLoadoutByName(pending.specID, pending.name)
            if configID then
                pendingLoadoutCreation = nil
                self:BindManagedLoadout(pending.specID, pending.context, configID, name)
                Print(T("Created and saved WoW loadout '%s' for %s.", name, (Data.contextNames and Data.contextNames[pending.context]) or pending.context))
            end
        end
        if loadoutPickerFrame and loadoutPickerFrame:IsShown() then
            self:UpdateLoadoutPicker()
        end
        self:ScheduleUpdate(false)
    elseif event == "SELECTED_LOADOUT_CHANGED" then
        self:SyncPendingLoadoutState(true)
        if loadoutPickerFrame and loadoutPickerFrame:IsShown() then
            self:UpdateLoadoutPicker()
        end
        self:ScheduleUpdate(false)
    elseif event == "ACTIVE_COMBAT_CONFIG_CHANGED" then
        self:SyncPendingLoadoutState(true)
        self:ScheduleUpdate(false)
    elseif event == "CONFIG_COMMIT_FAILED" then
        self.pendingLoadoutSwitchStartedAt = nil
        self.lastLoadoutSwitchError = T("WoW rejected the talent loadout change")
        self.pendingLoadoutKey = nil
        self.pendingLoadoutTargetConfigID = nil
        self.pendingLoadoutSpecID = nil
        self:UpdateStatusWidget()
    elseif event == "SPECIALIZATION_CHANGE_CAST_FAILED" then
        if self.pendingSpecializationTargetSpecID then
            local retryTargetSpecID = self.pendingSpecializationTargetSpecID
            self.pendingSpecializationSwitchStartedAt = nil
            self.lastSpecializationSwitchError = T("WoW did not allow the automatic specialization change.")
            self:UpdateBuildSection()
            self:UpdateStatusWidget()
            self:SchedulePendingSpecializationRetry(retryTargetSpecID, 2.0)
        end
    elseif event == "PLAYER_ENTERING_BATTLEGROUND" then
        -- Try during the battleground preparation window, before PVP_MATCH_ACTIVE.
        if C_Timer and C_Timer.After then
            C_Timer.After(0.35, function()
                if addon.active then
                    addon.worldReady = true
                    addon:ApplyAutomaticProfile("pvp-enter")
                end
            end)
        end
        self:ScheduleUpdate(false)
    elseif event == "EQUIPMENT_SETS_CHANGED" then
        if pendingEquipmentCreation then
            self:FinishPendingEquipmentCreation()
        end
        if equipmentPickerFrame and equipmentPickerFrame:IsShown() then
            self:UpdateEquipmentPicker()
        end
        self:ScheduleUpdate(false)
    elseif event == "EQUIPMENT_SWAP_FINISHED" then
        local result = ...
        local swapSucceeded = GetAccessibleBoolean(result)
        local completed = self:SyncPendingEquipmentState(true)
        if not completed and self.pendingEquipmentKey and swapSucceeded == false then
            lootSpecState.equipmentRetryElapsed = 1.0
        end
        if self.pendingEquipmentKey and C_Timer and C_Timer.After then
            C_Timer.After(0.25, function()
                if addon.active and addon.pendingEquipmentKey and (not InCombatLockdown or not InCombatLockdown()) then
                    addon:TryAutoSwitchEquipment("equipment-swap-finished")
                end
            end)
        end
        self:UpdateBuildSection()
        self:UpdateStatusWidget()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        self:ScheduleUpdate(false)
    elseif event == "PLAYER_TARGET_CHANGED" then
        targetInterruptEventState = nil
        self:UpdateInterruptAlert()
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        local unitTarget = ...
        if IsAccessibleValue(unitTarget) and type(unitTarget) == "string" and unitTarget == "target" then
            targetInterruptEventState = event == "UNIT_SPELLCAST_INTERRUPTIBLE"
            self:UpdateInterruptAlert()
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unitTarget = ...
        if IsAccessibleValue(unitTarget) and type(unitTarget) == "string" and unitTarget == "target" then
            targetInterruptEventState = nil
            self:UpdateInterruptAlert()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unitTarget = ...
        if IsAccessibleValue(unitTarget) and type(unitTarget) == "string" and unitTarget == "target" then
            targetInterruptEventState = nil
            self:UpdateInterruptAlert()
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function() if addon.active then addon:UpdateInterruptAlert() end end)
            end
        end
    elseif event == "UNIT_SPELLCAST_SENT" then
        local unitTarget, _, _, spellID = ...
        if IsAccessibleValue(unitTarget) and unitTarget == "player" and IsAccessibleNumber(spellID) then
            -- MountJournal summons fire UNIT_SPELLCAST_SENT before IsMounted()
            -- becomes true. Triggering here gives immediate, reliable feedback;
            -- the later mounted-state poll is retained as a macro/UI fallback.
            if self:IsMountSpell(spellID) then
                self:TriggerPriorityVoice("mount", 8)
            end
            if self:IsHearthstoneSpell(spellID) then
                self:TriggerPriorityVoice("hearthstone", 6)
            end
        end
    elseif event == "UNIT_SPELLCAST_START" then
        local unitTarget, _, spellID = ...
        if IsAccessibleValue(unitTarget) and type(unitTarget) == "string" and unitTarget == "target" then
            targetInterruptEventState = nil
            self:UpdateInterruptAlert()
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function() if addon.active then addon:UpdateInterruptAlert() end end)
            end
        elseif IsAccessibleValue(unitTarget) and unitTarget == "player" and IsAccessibleNumber(spellID) and self:IsHearthstoneSpell(spellID) then
            -- Fallback for clients/toys where SENT was not observed. The
            -- per-category interval prevents this from double-playing.
            self:TriggerPriorityVoice("hearthstone", 6)
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...
        if IsAccessibleValue(unitTarget) and type(unitTarget) == "string" and unitTarget == "target" then
            targetInterruptEventState = nil
            self:UpdateInterruptAlert()
        end
        if IsAccessibleValue(unitTarget) and unitTarget == "player" and IsAccessibleNumber(spellID) then
            self:TrackRuntimeBuffCast(spellID)
            self:UpdateBuffBar()
            if self:IsMountSpell(spellID) and C_Timer and C_Timer.After then
                C_Timer.After(0.20, function() if addon.active then addon:CheckMountedTransition() end end)
            end
            if self:IsHearthstoneSpell(spellID) then
                self:TriggerPriorityVoice("hearthstone", 6)
            end
            if Voices.defensiveSpells and Voices.defensiveSpells[spellID] then
                self:TryVoiceComment("defensive")
            end
            self:HandleSituationalSpellVoice(spellID)
        end
    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "PVP_MATCH_COMPLETE" then
        C_Timer.After(1, function()
            if addon.active then
                addon:TryVoiceComment("encounterVictory", { cooldown = 20 })
            end
        end)
        self:ScheduleUpdate(false)
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self:SyncCombatEventState()
        self:RefreshCombatHUDVisibility()
        self:ScheduleUpdate(false)

        -- Loadout Pilot applies its context rule shortly after the loading
        -- transition. Do the same here instead of making the first automatic
        -- specialization/loadout wait for the heavier four-second cache pass.
        if C_Timer and C_Timer.After then
            C_Timer.After(1.0, function()
                if addon.active then
                    addon.worldReady = true
                    addon:RememberCurrentDungeon()
                    addon:ApplyAutomaticProfile("world-ready")
                end
            end)
        else
            self.worldReady = true
            self:RememberCurrentDungeon()
            self:ApplyAutomaticProfile("world-ready")
        end

        -- Delay non-essential aura/voice/cache work until the loading transition
        -- has fully settled. Loadout automation no longer depends on this pass.
        C_Timer.After(4, function()
            if addon.active then
                addon.worldReady = true
                addon:SyncCombatEventState()
                addon:SyncReadableBuffRuntime(true)
                if not (buffFrame and buffFrame.managedAuraContainer) then
                    addon:RefreshCooldownViewerBuffMirrors()
                end
                addon:RefreshManagedDKBuffFilter()
                addon:RefreshVoiceTriggerCaches(false)
                addon:TryVoiceComment("zone")
                addon:UpdateAll()
                addon:RefreshCombatHUDVisibility()
                addon:RememberCurrentDungeon()
                addon:ApplyAutomaticProfile("context-change")
            end
        end)
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        if C_Timer and C_Timer.After then
            C_Timer.After(0.20, function() if addon.active then addon:CheckMountedTransition() end end)
        else
            self:CheckMountedTransition()
        end
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local itemID, success = ...
        if success and self.hearthstoneItemIDs and self.hearthstoneItemIDs[itemID] then
            self:CacheHearthstoneItemSpell(itemID, false)
        end
    elseif event == "NEW_MOUNT_ADDED" then
        self.mountCacheReady = false
        if DB.voice.enabled and DB.voice.situational ~= false and self.worldReady then
            C_Timer.After(1, function()
                if addon.active then addon:RefreshMountSpellCache(false) end
            end)
        end
    elseif event == "PLAYER_FLAGS_CHANGED" then
        local unit = ...
        if (not unit or unit == "player") and DB.voice.situational and UnitIsAFK then
            local ok, rawAFK = pcall(UnitIsAFK, "player")
            local afk = GetAccessibleBooleanFromCall(ok, rawAFK)
            if afk ~= nil and afk ~= self.lastAFKState then
                self.lastAFKState = afk
                self:TryVoiceComment(afk and "afkStart" or "afkEnd")
            end
        end
    elseif event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
            self:UpdateStatusWidget()
            if DB.voice.situational and UnitExists then
                local ok, rawExists = pcall(UnitExists, "pet")
                local exists = GetAccessibleBooleanFromCall(ok, rawExists)
                if exists == true then
                    self:TryVoiceComment("petSummon")
                end
            end
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit == "player" then
            self:UpdateStatusWidget()
        end
    elseif event == "CHALLENGE_MODE_START" or event == "CHALLENGE_MODE_KEYSTONE_SLOTTED" or event == "CHALLENGE_MODE_RESET" or event == "UPDATE_BATTLEFIELD_STATUS" or event == "PVP_MATCH_ACTIVE" then
        self:ScheduleUpdate(false)
        if C_Timer and C_Timer.After then
            C_Timer.After(0.75, function()
                if addon.active then
                    addon:RememberCurrentDungeon()
                    addon:ApplyAutomaticProfile("content-start")
                end
            end)
        end
    elseif event == "CVAR_UPDATE" then
        local cvarName = ...
        if cvarName == "assistedCombatHighlight" or cvarName == "ASSISTEDCOMBATHIGHLIGHT" then
            self:UpdateAssistedCombatSection()
        end
    elseif event == "PLAYER_LOOT_SPEC_UPDATED" then
        self:UpdatePendingLootSpecState()
        if C_Timer and C_Timer.After then
            C_Timer.After(0.20, function() if addon.active then addon:ApplyAutomaticProfile("loot-spec-updated") end end)
        end
    elseif event == "PLAYER_ROLES_ASSIGNED" then
        self:ApplyAutomaticProfile("role-assigned")
        self:UpdateStatusWidget()
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        InvalidateCooldownManagerProfileCache()
        if not unit or unit == "player" then
            if specializationPickerFrame then
                specializationPickerFrame:Hide()
                self:UpdateSpecializationPicker()
            end
            local currentSpecID = select(1, self:GetSpecInfo())
            if self.pendingSpecializationTargetSpecID and self.pendingSpecializationTargetSpecID == currentSpecID then
                self:ClearPendingSpecializationSwitch()
                self.lastSpecializationSwitchError = nil
            end
            self:ScheduleUpdate(true)
            C_Timer.After(0.5, function()
                if addon.active then
                    if not InCombatLockdown() and not (buffFrame and buffFrame.managedAuraContainer) then
                        addon:RefreshCooldownViewerBuffMirrors()
                    end
                    addon:RefreshManagedDKBuffFilter()
                    addon:ApplyAutomaticProfile("specialization")
                end
            end)
        end
    elseif event == "SPELLS_CHANGED"
        or event == "ACTIONBAR_SLOT_CHANGED"
        or event == "ACTIVE_TALENT_GROUP_CHANGED"
        or event == "PLAYER_TALENT_UPDATE"
        or event == "TRAIT_CONFIG_UPDATED"
        or event == "PLAYER_PVP_TALENT_UPDATE" then
        if event == "TRAIT_CONFIG_UPDATED" and self.pendingLoadoutKey and self.pendingLoadoutSwitchStartedAt then
            self:CompletePendingLoadoutSwitch(true)
        elseif event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
            self:SyncPendingLoadoutState(true)
        end
        self:ScheduleUpdate(true)
    else
        self:ScheduleUpdate(false)
    end
end)

addon:SetScript("OnUpdate", function(self, elapsed)
    if not self.active or not DB then
        return
    end

    local delta = tonumber(elapsed) or 0

    -- Buff visuals need an independent, combat-safe heartbeat. Ability cooldown
    -- widgets animate natively, but proc/cast fallbacks and short buff timers
    -- need periodic presentation refreshes even when UNIT_AURA is restricted.
    buffRefreshElapsed = buffRefreshElapsed + delta
    if buffRefreshElapsed >= 0.12 then
        buffRefreshElapsed = 0
        if self:ShouldShowCombatBar(DB.buffBar) then
            self:UpdateBuffBar()
        elseif buffFrame then
            buffFrame:Hide()
        end

        -- Ability/external/debuff bars do not need a full 120 ms refresh, but
        -- their visibility must still follow the combat latch if an event/UI
        -- refresh is delayed.
        if self.hudPreviewMode ~= true and DB.combatBarsOnlyInCombat == true and not self:IsPlayerInCombat() then
            if buffFrame then buffFrame:Hide() end
            if externalBuffFrame then externalBuffFrame:Hide() end
            if debuffFrame then debuffFrame:Hide() end
            if abilityFrame then abilityFrame:Hide() end
            if resourceFrame then resourceFrame:Hide() end
            if interruptFrame then interruptFrame:Hide() end
        end
    end

    -- Instance/PvP transitions can briefly report the previous instance type.
    -- Poll only the coarse environment twice per second and refresh when it
    -- actually changes. This reads no combat-secret aura/resource data.
    contextPollElapsed = contextPollElapsed + delta
    if contextPollElapsed >= 0.50 then
        contextPollElapsed = 0
        local detectedContext = self:DetectActualContext()
        local dungeonIdentity = (detectedContext == "dungeon" or detectedContext == "mythicplus") and self:GetCurrentDungeonIdentity() or nil
        local dungeonKey = dungeonIdentity and dungeonIdentity.key or nil
        if detectedContext ~= self.currentContext or dungeonKey ~= self.currentDungeonKey then
            self.currentContext = detectedContext
            self.currentDungeonKey = dungeonKey
            if dungeonIdentity then self:RememberDungeonIdentity(dungeonIdentity) end
            self:UpdateAll()
            if self.worldReady then
                self:ApplyAutomaticProfile("context-detected")
            end
        end
    end

    if lootSpecState.pendingID ~= nil then
        self:UpdatePendingLootSpecState()
        if lootSpecState.pendingID ~= nil then
            lootSpecState.retryElapsed = lootSpecState.retryElapsed + delta
            if lootSpecState.retryElapsed >= 1.0 then
                lootSpecState.retryElapsed = 0
                self:SyncDungeonLootSpecialization("pending-loot-spec-retry")
            end
        end
    else
        lootSpecState.retryElapsed = 0
    end

    if self.pendingEquipmentKey then
        self:SyncPendingEquipmentState(true)
        if self.pendingEquipmentKey and (not InCombatLockdown or not InCombatLockdown()) then
            lootSpecState.equipmentRetryElapsed = lootSpecState.equipmentRetryElapsed + delta
            if lootSpecState.equipmentRetryElapsed >= 1.0 then
                lootSpecState.equipmentRetryElapsed = 0
                self:TryAutoSwitchEquipment("pending-equipment-retry")
            end
        end
    else
        lootSpecState.equipmentRetryElapsed = 0
    end

    if not DB.voice or not DB.voice.enabled or DB.voice.situational == false then
        return
    end

    ambientPollElapsed = ambientPollElapsed + delta
    if ambientPollElapsed < 0.25 then
        return
    end
    ambientPollElapsed = 0

    -- IsMounted() becomes reliable shortly after some mount-related events.
    -- Polling only the local player's transition is a lightweight fallback
    -- that also covers mounts summoned from macros or collection buttons.
    self:CheckMountedTransition()
end)

addon:RegisterEvent("ADDON_LOADED")

SLASH_DKMENTOR1 = "/dkm"
SLASH_DKMENTOR2 = "/dkmentor"
SlashCmdList.DKMENTOR = function(message)
    addon:HandleSlashCommand(message)
end
