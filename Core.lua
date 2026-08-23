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
local equipmentPickerFrame
local loadoutPickerFrame
local buffFrame
local externalBuffFrame
local debuffFrame
local abilityFrame
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
local mirroredBuffHooks = setmetatable({}, { __mode = "k" })
local mirroredViewerHooks = setmetatable({}, { __mode = "k" })
local overlayProcState = {}
local runtimeBuffState = {}
local buffRefreshElapsed = 0
local contextPollElapsed = 0

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
    schema = 19,
    firstRun = true,
    modeOverride = "auto",
    buildContextSelection = "world",
    selectedBuild = {},
    personalBuildCodes = {},
    loadoutBindings = {},
    equipmentBindings = {},
    autoSwitchLoadouts = true,
    autoSwitchEquipment = true,
    autoHideMainInCombat = true,
    combatBarsOnlyInCombat = false,
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
    },
    externalBuffBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 255,
        scale = 1,
    },
    debuffBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 305,
        scale = 1,
    },
    abilityBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 155,
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
        local ok, inVehicle = pcall(UnitInVehicle, "player")
        if ok and inVehicle == true then
            return { required = true, ready = true, paused = true, detail = T("Paused while in a vehicle") }
        end
    end
    if UnitOnTaxi then
        local ok, onTaxi = pcall(UnitOnTaxi, "player")
        if ok and onTaxi == true then
            return { required = true, ready = true, paused = true, detail = T("Paused while travelling") }
        end
    end

    local petExists = false
    if UnitExists then
        local ok, exists = pcall(UnitExists, "pet")
        petExists = ok and exists == true
    end

    if not petExists then
        return { required = true, ready = false, detail = T("Ghoul missing") }
    end

    local petDead = false
    if UnitIsDead then
        local ok, dead = pcall(UnitIsDead, "pet")
        petDead = ok and dead == true
    elseif UnitIsDeadOrGhost then
        local ok, dead = pcall(UnitIsDeadOrGhost, "pet")
        petDead = ok and dead == true
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

    local specID = select(1, self:GetSpecInfo())
    local context = self:DetectActualContext()
    local issues = {}
    local hardIssue = false

    local talentBinding = select(1, self:ResolveLoadoutBinding(specID, context))
    local selectedLoadoutID = self:GetSelectedLoadoutConfigID(specID)
    local talentReady = type(talentBinding) == "table"
        and talentBinding.configID ~= nil
        and selectedLoadoutID == talentBinding.configID
        and self.pendingLoadoutKey == nil
    local talentDetail
    if type(talentBinding) ~= "table" or not talentBinding.configID then
        talentDetail = T("No talent loadout mapped for this content")
        table.insert(issues, { key = "talents", label = T("TALENTS"), severity = "hard", detail = talentDetail })
        hardIssue = true
    elseif self.pendingLoadoutKey then
        talentDetail = T("Waiting for talent loadout: %s", tostring(talentBinding.name or talentBinding.configID))
        table.insert(issues, { key = "talents", label = T("TALENTS"), severity = "waiting", detail = talentDetail })
    elseif selectedLoadoutID ~= talentBinding.configID then
        talentDetail = T("Expected talent loadout: %s", tostring(talentBinding.name or talentBinding.configID))
        local severity = DB.autoSwitchLoadouts and "waiting" or "hard"
        table.insert(issues, { key = "talents", label = T("TALENTS"), severity = severity, detail = talentDetail })
        if severity == "hard" then hardIssue = true end
    else
        talentDetail = T("Talent loadout: %s", tostring(talentBinding.name or talentBinding.configID))
    end

    local equipmentBinding, equipmentInfo = self:ResolveEquipmentBinding(specID, context)
    local gearReady = type(equipmentBinding) == "table"
        and equipmentInfo ~= nil
        and equipmentInfo.isEquipped == true
        and self.pendingEquipmentKey == nil
    local gearDetail
    if type(equipmentBinding) ~= "table" then
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
        gearDetail = T("Equipment set: %s", tostring(equipmentInfo.name or equipmentBinding.name or equipmentBinding.setID))
    end

    local runeforge = self:GetRuneforgeStatus()
    if not runeforge.ready then
        local severity = runeforge.known and "hard" or "waiting"
        table.insert(issues, { key = "runeforge", label = T("RUNEFORGE"), severity = severity, detail = runeforge.detail })
        if severity == "hard" then hardIssue = true end
    end

    local ghoul = self:GetGhoulReadyStatus(specID)
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
        specID = specID,
        context = context,
        issues = issues,
        summary = summary,
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
    frame:SetScale(Clamp(config.scale or 1, 0.7, 1.4))
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

    local ok = false
    if C_ClassTalents and C_ClassTalents.SwitchToSpecializationByIndex then
        ok = pcall(C_ClassTalents.SwitchToSpecializationByIndex, index)
    elseif C_SpecializationInfo and C_SpecializationInfo.SetSpecialization then
        ok = pcall(C_SpecializationInfo.SetSpecialization, index)
    end

    if not ok then
        Print(T("WoW did not allow the specialization change."))
        return false
    end

    if specializationPickerFrame then specializationPickerFrame:Hide() end
    Print(T("Switching specialization to %s...", tostring(targetName)))
    return true
end

function addon:DetectActualContext()
    if C_PartyInfo and C_PartyInfo.IsDelveInProgress then
        local ok, inDelve = pcall(C_PartyInfo.IsDelveInProgress)
        if ok and inDelve then
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

    local specID = select(1, self:GetSpecInfo())
    local context = self:GetBuildConfigContext()
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

    local specID = select(1, self:GetSpecInfo())
    local context = self:GetBuildConfigContext()
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

function addon:GetActiveLoadoutInfo()
    local specID = select(1, self:GetSpecInfo())
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

    local activeID = select(1, self:GetActiveLoadoutInfo())
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
                isActive = select(1, self:GetActiveLoadoutInfo()) == binding.configID,
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
                isActive = select(1, self:GetActiveLoadoutInfo()) == repairedID,
            }
        end
    end

    if info then
        binding.configID = info.configID
        binding.name = info.name
    end
    return binding, info
end

function addon:BindExistingLoadout(configID)
    if not DB or not configID then return false end
    local specID, specName = self:GetSpecInfo()
    local context = self:GetBuildConfigContext()

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
    local configID = select(1, self:GetActiveLoadoutInfo())
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

    local specID = select(1, self:GetSpecInfo())
    local context = self:GetBuildConfigContext()
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
        local configID, name = self:GetActiveLoadoutInfo()
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
    local specID = select(1, self:GetSpecInfo())
    local context = self:GetBuildConfigContext()
    DB.loadoutBindings[self:GetLoadoutBindingKey(specID, context)] = nil
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    Print(T("Saved WoW loadout cleared for this content type."))
end

function addon:SetAutoSwitchLoadouts(enabled)
    DB.autoSwitchLoadouts = enabled == true
    self:UpdateBuildSection()
    self:UpdateStatusWidget()
    Print(DB.autoSwitchLoadouts and "Automatic talent-loadout switching enabled." or "Automatic talent-loadout switching disabled.")
    if DB.autoSwitchLoadouts then
        self:TryAutoSwitchLoadout("toggle")
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
    if not self.worldReady and reason ~= "toggle" and reason ~= "pvp-enter" then
        return false
    end

    local specID = select(1, self:GetSpecInfo())
    local context = self:DetectActualContext()
    local key = self:GetLoadoutBindingKey(specID, context)
    local binding = select(1, self:ResolveLoadoutBinding(specID, context))
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
                Print(T("Switching talents to '%s' for %s...", tostring(binding.name or binding.configID), (Data.contextNames and Data.contextNames[context]) or context))
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
                Print(T("Auto-switching to '%s' for %s.", tostring(binding.name or binding.configID), (Data.contextNames and Data.contextNames[context]) or context))
                self:RefreshTalentFrameUI()
                self:UpdateBuildSection()
                self:UpdateStatusWidget()
                return true
            end

            if result == inProgressValue then
                self.pendingLoadoutSwitchStartedAt = GetNow()
                self.lastLoadoutSwitchError = nil
                Print(T("Switching talents to '%s' for %s...", tostring(binding.name or binding.configID), (Data.contextNames and Data.contextNames[context]) or context))
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

function addon:BindExistingEquipmentSet(setID)
    if not DB then return false end
    local info = self:GetEquipmentSetStatus(setID)
    if not info then
        Print(T("That WoW equipment set is no longer available."))
        return false
    end

    local specID, specName = self:GetSpecInfo()
    local context = self:GetBuildConfigContext()
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
    local specID = select(1, self:GetSpecInfo())
    local context = self:GetBuildConfigContext()
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
        self:TryAutoSwitchEquipment("toggle")
    end
end

function addon:ToggleAutoSwitchEquipment()
    self:SetAutoSwitchEquipment(not DB.autoSwitchEquipment)
end

function addon:TryAutoSwitchEquipment(reason)
    if not DB or not DB.autoSwitchEquipment or not self.active then
        return false
    end
    if not self.worldReady and reason ~= "toggle" then
        return false
    end

    local specID = select(1, self:GetSpecInfo())
    local context = self:DetectActualContext()
    local key = self:GetEquipmentBindingKey(specID, context)
    local binding, info = self:ResolveEquipmentBinding(specID, context)
    if type(binding) ~= "table" then
        return false
    end

    if not info or not binding.setID then
        self.pendingEquipmentKey = key
        self:UpdateStatusWidget()
        return false
    end

    if info.isEquipped then
        self.pendingEquipmentKey = nil
        self:UpdateStatusWidget()
        return true
    end

    if InCombatLockdown and InCombatLockdown() then
        self.pendingEquipmentKey = key
        self:UpdateStatusWidget()
        return false
    end

    if C_EquipmentSet and C_EquipmentSet.CanUseEquipmentSets then
        local okCan, canUse = pcall(C_EquipmentSet.CanUseEquipmentSets)
        if okCan and canUse == false then
            self.pendingEquipmentKey = key
            return false
        end
    end

    if C_EquipmentSet and C_EquipmentSet.UseEquipmentSet then
        local okUse, equipped = pcall(C_EquipmentSet.UseEquipmentSet, binding.setID)
        if okUse and equipped then
            self.pendingEquipmentKey = nil
            Print(T("Auto-equipping '%s' for %s.", tostring(binding.name or binding.setID), (Data.contextNames and Data.contextNames[context]) or context))
            if C_Timer and C_Timer.After then
                C_Timer.After(0.35, function()
                    if addon.active then
                        addon:UpdateBuildSection()
                        addon:UpdateStatusWidget()
                    end
                end)
            else
                self:UpdateBuildSection()
                self:UpdateStatusWidget()
            end
            return true
        end
    end

    self.pendingEquipmentKey = key
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
    local specID = select(1, self:GetSpecInfo())
    local context = self:GetBuildConfigContext()
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

    local ok, mounted = pcall(IsMounted)
    if not ok then
        return
    end
    mounted = mounted == true

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
        contexts = { "world", "delve", "dungeon", "raid", "pvp" },
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
        contexts = { "world", "delve", "dungeon", "raid", "pvp" },
        labelWidth = 180,
        buttonWidth = 92,
        getSelectedContext = function() return addon:GetBuildConfigContext() end,
        onSelect = function(contextKey) addon:SetBuildConfigContext(contextKey) end,
    })
    frame.buildSection = CreateSection(buildsPage, T("Loadouts"), -52, 520)
    local build = frame.buildSection

    build.name = build:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    build.name:SetPoint("TOPLEFT", build, "TOPLEFT", 12, -30)
    build.name:SetWidth(585)
    build.name:SetJustifyH("LEFT")

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
    build.autoHint:SetWidth(745)
    build.autoHint:SetHeight(58)
    build.autoHint:SetJustifyH("LEFT")
    build.autoHint:SetJustifyV("TOP")

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
    settingsPage.scope:SetWidth(760)
    settingsPage.scope:SetJustifyH("LEFT")
    settingsPage.scope:SetText(T("Global addon settings. These options apply across all Death Knight specializations and content profiles."))
    settingsPage.scope:SetTextColor(0.55, 0.84, 0.95)

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
        text:SetHeight(30)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("MIDDLE")
        text:SetText(description)
        return text
    end

    hud.buildButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.buildButton:SetSize(180, 27)
    hud.buildButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -72)
    hud.buildButton:SetScript("OnClick", function() addon:SetStatusWidgetEnabled(not DB.statusWidget.enabled) end)
    AddHudRow(-68, T("Shows specialization, detected content, active build, and mapped gear."))
    build.hudButton = hud.buildButton

    hud.coachButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.coachButton:SetSize(180, 27)
    hud.coachButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -102)
    hud.coachButton:SetScript("OnClick", function() addon:SetCoachEnabled(not DB.coach.enabled) end)
    AddHudRow(-98, T("Shows defensive and recovery recommendations, including health-adaptive priorities."))

    hud.buffButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.buffButton:SetSize(180, 27)
    hud.buffButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -132)
    hud.buffButton:SetScript("OnClick", function() addon:SetBuffBarEnabled(not DB.buffBar.enabled) end)
    AddHudRow(-128, T("Shows important Death Knight buffs in a compact movable row."))

    hud.externalBuffButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.externalBuffButton:SetSize(180, 27)
    hud.externalBuffButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -162)
    hud.externalBuffButton:SetScript("OnClick", function() addon:SetExternalBuffBarEnabled(not DB.externalBuffBar.enabled) end)
    AddHudRow(-158, T("Shows helpful effects on you that were applied by other players or NPCs."))

    hud.debuffButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.debuffButton:SetSize(180, 27)
    hud.debuffButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -192)
    hud.debuffButton:SetScript("OnClick", function() addon:SetDebuffBarEnabled(not DB.debuffBar.enabled) end)
    AddHudRow(-188, T("Shows harmful effects currently affecting your character."))

    hud.abilityButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.abilityButton:SetSize(180, 27)
    hud.abilityButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -222)
    hud.abilityButton:SetScript("OnClick", function() addon:SetAbilityBarEnabled(not DB.abilityBar.enabled) end)
    AddHudRow(-218, T("Shows important abilities and whether they are ready, cooling down, or temporarily unusable."))

    -- Keep the three layout controls on one clean row even with the longer
    -- ptBR labels. The old 180px buttons clipped/overflowed localized text.
    hud.lockButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.lockButton:SetSize(190, 27)
    hud.lockButton:SetPoint("BOTTOMLEFT", hud, "BOTTOMLEFT", 12, 12)
    hud.lockButton:SetScript("OnClick", function() addon:ToggleHUDLock() end)

    hud.previewButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.previewButton:SetSize(230, 27)
    hud.previewButton:SetPoint("LEFT", hud.lockButton, "RIGHT", 9, 0)
    hud.previewButton:SetScript("OnClick", function() addon:ToggleHUDPreview() end)

    hud.resetButton = CreateFrame("Button", nil, hud, "UIPanelButtonTemplate")
    hud.resetButton:SetSize(250, 27)
    hud.resetButton:SetPoint("LEFT", hud.previewButton, "RIGHT", 9, 0)
    hud.resetButton:SetText(T("Reset HUD positions"))
    hud.resetButton:SetScript("OnClick", function() addon:ResetHUDPositions() end)

    for _, button in ipairs({ hud.lockButton, hud.previewButton, hud.resetButton }) do
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
    automation.description:SetWidth(300)
    automation.description:SetHeight(54)
    automation.description:SetJustifyH("LEFT")
    automation.description:SetJustifyV("TOP")
    automation.description:SetText(T("Loadout mappings are configured per specialization and content in the Loadouts tab. These switches are global."))

    build.autoSwitchButton = CreateFrame("Button", nil, automation, "UIPanelButtonTemplate")
    build.autoSwitchButton:SetSize(200, 28)
    build.autoSwitchButton:SetPoint("TOPLEFT", automation, "TOPLEFT", 330, -37)
    build.autoSwitchButton:SetScript("OnClick", function() addon:ToggleAutoSwitchLoadouts() end)

    build.autoEquipmentButton = CreateFrame("Button", nil, automation, "UIPanelButtonTemplate")
    build.autoEquipmentButton:SetSize(225, 28)
    build.autoEquipmentButton:SetPoint("TOPRIGHT", automation, "TOPRIGHT", -12, -37)
    build.autoEquipmentButton:SetScript("OnClick", function() addon:ToggleAutoSwitchEquipment() end)

    for _, button in ipairs({ build.autoSwitchButton, build.autoEquipmentButton }) do
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
    frame:SetSize(286, 88)
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

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(42, 42)
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -9)
    frame.icon:SetTexture(QUESTION_MARK_ICON)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.specButton = CreateFrame("Button", nil, frame)
    frame.specButton:SetAllPoints(frame.icon)
    frame.specButton:RegisterForClicks("LeftButtonUp")
    frame.specButton:SetScript("OnClick", function() addon:ToggleSpecializationPicker() end)
    frame.specButton:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(T("Change specialization"))
            GameTooltip:AddLine(T("Click to choose Blood, Frost, or Unholy. Specializations are never changed automatically."), 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    frame.specButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 8, -1)
    frame.title:SetWidth(220)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetTextColor(0.48, 0.87, 1)

    frame.build = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.build:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -3)
    frame.build:SetWidth(220)
    frame.build:SetJustifyH("LEFT")

    frame.gear = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.gear:SetPoint("TOPLEFT", frame.build, "BOTTOMLEFT", 0, -2)
    frame.gear:SetWidth(220)
    frame.gear:SetJustifyH("LEFT")

    frame.ready = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.ready:SetPoint("TOPLEFT", frame.gear, "BOTTOMLEFT", 0, -3)
    frame.ready:SetWidth(220)
    frame.ready:SetJustifyH("LEFT")

    frame.auto = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.auto:SetPoint("TOPLEFT", frame.ready, "BOTTOMLEFT", 0, -3)
    frame.auto:SetWidth(220)
    frame.auto:SetJustifyH("LEFT")

    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(T("DK Mentor Build HUD"))
        GameTooltip:AddLine(T("Shows your Death Knight specialization, detected content, active WoW talent loadout, and associated equipment set."), 1, 1, 1, true)

        local status = addon:GetReadyCheckStatus()
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(T("DK Ready Check"), 0.45, 0.85, 1)
        GameTooltip:AddLine((status.talentReady and "|cff66ff99" or "|cffffcc55") .. T("Talents") .. ":|r " .. tostring(status.talentDetail or "-"), 1, 1, 1, true)
        GameTooltip:AddLine((status.gearReady and "|cff66ff99" or "|cffffcc55") .. T("Gear") .. ":|r " .. tostring(status.gearDetail or "-"), 1, 1, 1, true)
        GameTooltip:AddLine((status.runeforge and status.runeforge.ready and "|cff66ff99" or "|cffff7777") .. T("Runeforge") .. ":|r " .. tostring(status.runeforge and status.runeforge.detail or "-"), 1, 1, 1, true)
        if status.ghoul and status.ghoul.required then
            GameTooltip:AddLine((status.ghoul.ready and "|cff66ff99" or "|cffff7777") .. T("Ghoul") .. ":|r " .. tostring(status.ghoul.detail or "-"), 1, 1, 1, true)
        end
        GameTooltip:AddLine(T("Runeforge Guard checks for a Death Knight Runeforge on each equipped weapon; it does not claim that one rune is always the best for every build."), 0.72, 0.78, 0.84, true)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(DB and DB.hudLocked and T("HUDs are locked. Unlock them in Settings to move this panel.") or T("Drag to move. Toggle it from Settings or with /dkm hud."), 0.65, 0.8, 0.9, true)
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

    -- Width is content-aware, but capped so localized text cannot create a giant HUD.
    local leftInset = 8 + 42 + 8
    local rightInset = 10
    local widest = 0
    local regions = { statusWidget.title, statusWidget.build, statusWidget.gear, statusWidget.ready, statusWidget.auto }
    for _, region in ipairs(regions) do
        if region and region.GetStringWidth then
            widest = math.max(widest, math.ceil(region:GetStringWidth() or 0))
        end
    end

    local desiredWidth = math.max(240, math.min(380, leftInset + widest + rightInset))
    local textWidth = desiredWidth - leftInset - rightInset

    statusWidget:SetWidth(desiredWidth)
    statusWidget.title:SetWidth(textWidth)
    statusWidget.build:SetWidth(textWidth)
    statusWidget.gear:SetWidth(textWidth)
    statusWidget.ready:SetWidth(textWidth)
    statusWidget.auto:SetWidth(textWidth)

    -- Height follows the actual rendered text. This removes the unused bottom
    -- space in the normal five-line state while still growing safely when a
    -- localized label wraps or a warning becomes longer.
    local gaps = { 0, 3, 2, 3, 3 }
    local textHeight = 0
    for index, region in ipairs(regions) do
        local height = 0
        if region and region.GetStringHeight then
            height = math.ceil(region:GetStringHeight() or 0)
        end
        if height <= 0 then
            height = (index == 1) and 14 or 12
        end
        textHeight = textHeight + gaps[index] + height
    end

    local topPadding = 9
    local bottomPadding = 6
    local iconHeight = 42
    local contentHeight = math.max(iconHeight, textHeight)
    local desiredHeight = math.max(72, math.min(150, topPadding + contentHeight + bottomPadding))
    statusWidget:SetHeight(desiredHeight)
end

local function CreateTrackingBar(frameName, dbKey, title, slotStore, maxSlots, updateInterval)
    local frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    frame:SetSize(330, 54)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame.dbKey = dbKey
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
        slot:SetPoint("TOPLEFT", frame, "TOPLEFT", 7 + ((index - 1) * 38), -16)
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

local function CreateBuffBar()
    return CreateTrackingBar("DKMentorBuffBar", "buffBar", T("DK Buffs"), buffSlots, 10, 0.12)
end

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

    if frame.label then frame.label:SetShown(editing) end
    if frame.dragHint then
        frame.dragHint:SetShown(editing)
        if editing then frame.dragHint:SetText(T("Drag to move")) end
    end

    -- When locked, keep the host frame visually/click-through transparent. The
    -- Blizzard-owned AuraButtons remain visible and continue updating normally.
    frame:EnableMouse(editing)
    if editing then
        frame:SetBackdropColor(0.02, 0.04, 0.06, 0.82)
        frame:SetBackdropBorderColor(0.16, 0.47, 0.62, 0.85)
    else
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

local MANAGED_AURA_ICON_SIZE = 34
local MANAGED_AURA_SPACING = 4
local MANAGED_AURAS_PER_LINE = 5
local MANAGED_AURA_MAX_FRAMES = 30
local MANAGED_AURA_LINE_SIZE = (MANAGED_AURAS_PER_LINE * (MANAGED_AURA_ICON_SIZE + MANAGED_AURA_SPACING)) + 1

local function ConfigureManagedAuraFlow(container)
    if not container then return end

    -- Five icons per row. Additional rows grow UP so a HUD placed above the
    -- action bars never turns into an extremely long horizontal strip.
    if container.SetFlowLayoutMaximumLineSize then
        pcall(container.SetFlowLayoutMaximumLineSize, container, MANAGED_AURA_LINE_SIZE)
    elseif container.SetAuraLayoutRowWidth then
        pcall(container.SetAuraLayoutRowWidth, container, MANAGED_AURA_LINE_SIZE)
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

local function CreateManagedAuraBar(frameName, dbKey, title, slotStore, filterString, harmful)
    -- Build the legacy row first as a compatibility fallback. On Retail 12.1 the
    -- managed container path below takes over and these ordinary slots stay hidden.
    local frame = CreateTrackingBar(frameName, dbKey, title, slotStore, MANAGED_AURA_MAX_FRAMES, 0.25)
    frame:SetSize(200, 56)
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
    container:SetSize(MANAGED_AURA_LINE_SIZE, MANAGED_AURA_ICON_SIZE)
    container:Show()
    ConfigureManagedAuraFlow(container)

    local options = {
        maxFrameCount = MANAGED_AURA_MAX_FRAMES,
        initializeFrame = function(button)
            StyleManagedAuraButton(button, harmful)
        end,
        candidateFilters = {},
        layout = {
            elementWidth = MANAGED_AURA_ICON_SIZE,
            elementHeight = MANAGED_AURA_ICON_SIZE,
            elementSpacing = MANAGED_AURA_SPACING,
            lineSpacing = MANAGED_AURA_SPACING,
            maximumLineSize = MANAGED_AURA_LINE_SIZE,
        },
    }

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
    ConfigureManagedAuraFlow(container)
    if container.SetAuraGroupLayout then
        pcall(container.SetAuraGroupLayout, container, dbKey, options.layout)
    end

    -- Declare groups before assigning the unit so the container registers the
    -- proper aura events. The container then owns all combat-time refreshes.
    if container.SetUnit then
        pcall(container.SetUnit, container, "player")
    end
    if container.UpdateAllAuras then
        pcall(container.UpdateAllAuras, container)
    end

    frame.managedAuraContainer = container
    frame.managedAuraFilter = filterString
    frame:SetScript("OnUpdate", nil)
    for _, slot in ipairs(slotStore) do
        slot:Hide()
    end
    UpdateManagedAuraBarChrome(frame)
    return frame
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


local function CreateLoadoutPickerFrame()
    local frame = CreateFrame("Frame", "DKMentorLoadoutPickerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(520, 455)
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
            if self.configID and addon:BindExistingLoadout(self.configID) then
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
        if addon:BindCurrentLoadout() then frame:Hide() end
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
            if self.setID and addon:BindExistingEquipmentSet(self.setID) then
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
        if addon:BindCurrentlyEquippedEquipmentSet() then
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
    if UnitAffectingCombat then
        local ok, value = pcall(UnitAffectingCombat, "player")
        if ok and value ~= nil then
            return value == true
        end
    end
    if InCombatLockdown then
        local ok, value = pcall(InCombatLockdown)
        if ok then
            return value == true
        end
    end
    return false
end

function addon:ShouldShowCombatBar(config)
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
    Print(T(DB.combatBarsOnlyInCombat and "Aura and ability bars now show only in combat." or "Aura and ability bars can now show outside combat."))
end

function addon:UpdateHUDMoveHints()
    if not DB then return end
    local text = DB.hudLocked and "" or T("Drag to move")
    if coachFrame and coachFrame.dragHint then coachFrame.dragHint:SetText(text) end
    if buffFrame and buffFrame.dragHint then buffFrame.dragHint:SetText(text) end
    if externalBuffFrame and externalBuffFrame.dragHint then externalBuffFrame.dragHint:SetText(text) end
    if debuffFrame and debuffFrame.dragHint then debuffFrame.dragHint:SetText(text) end
    if abilityFrame and abilityFrame.dragHint then abilityFrame.dragHint:SetText(text) end
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
    self.hudPreviewMode = not (self.hudPreviewMode == true)
    self:RefreshCoachVisibility()
    self:RefreshStatusWidgetVisibility()
    self:RefreshCombatHUDVisibility()
    self:UpdateHUDSettings()
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

    local specID, specName, specIcon = self:GetSpecInfo()
    local context = self:DetectActualContext()
    local contextName = (Data.contextNames and Data.contextNames[context]) or context
    local profile = self:GetSelectedBuild(specID, context)
    local activeID, activeName = self:GetActiveLoadoutInfo()
    local binding = select(1, self:ResolveLoadoutBinding(specID, context))
    local equipmentBinding, equipmentInfo = self:ResolveEquipmentBinding(specID, context)

    statusWidget.icon:SetTexture(specIcon or QUESTION_MARK_ICON)
    statusWidget.title:SetText(string.format("%s • %s", tostring(specName), tostring(contextName)))

    local buildText
    if activeName and activeName ~= "" then
        buildText = T("Build: %s", tostring(activeName))
        if type(binding) == "table" and binding.configID == activeID then
            buildText = "|cff66ff99" .. T("Build: %s", tostring(activeName)) .. "|r"
        end
    elseif type(binding) == "table" and binding.name then
        buildText = T("Build: %s", tostring(binding.name))
    elseif type(profile) == "table" and profile.name then
        buildText = T("Guide: %s", tostring(profile.name))
    else
        buildText = T("Build: not detected")
    end
    statusWidget.build:SetText(buildText)

    local gearText = T("Gear: not bound")
    if type(equipmentBinding) == "table" then
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

    local talentAuto = DB.autoSwitchLoadouts and ("|cff66ff99" .. T("TALENTS AUTO") .. "|r") or T("TALENTS MANUAL")
    local gearAuto = DB.autoSwitchEquipment and ("|cff66ff99" .. T("GEAR AUTO") .. "|r") or T("GEAR MANUAL")
    if self.pendingLoadoutKey then
        talentAuto = "|cffffcc55" .. T("TALENTS QUEUED") .. "|r"
    end
    if self.pendingEquipmentKey then
        gearAuto = "|cffffcc55" .. T("GEAR QUEUED") .. "|r"
    end
    statusWidget.auto:SetText(talentAuto .. " • " .. gearAuto)

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

    local specID, specName = self:GetSpecInfo()
    local context = self:GetBuildConfigContext()
    local contextName = (Data.contextNames and Data.contextNames[context]) or context
    local profile, index, profiles = self:GetSelectedBuild(specID, context)
    local build = mainFrame.buildSection
    if build.title then
        build.title:SetText(T("Loadouts — %s / %s", tostring(specName), tostring(contextName)))
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

    build.autoSwitchButton:SetText(T(DB.autoSwitchLoadouts and "Talents AUTO: ON" or "Talents AUTO: OFF"))
    build.autoEquipmentButton:SetText(T(DB.autoSwitchEquipment and "Gear AUTO: ON" or "Gear AUTO: OFF"))
    build.autoHint:SetText(T("This mapping is specific to %s / %s. DK Mentor detects the environment automatically and switches to the mapped talents and equipment when Talents AUTO / Gear AUTO are enabled in Settings.", tostring(specName), tostring(contextName)))
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
    local specID, specName, specIcon = self:GetSpecInfo()
    local context = self:GetBuildConfigContext()
    local contextName = (Data.contextNames and Data.contextNames[context]) or context
    local _, mappedInfo = self:ResolveLoadoutBinding(specID, context)
    local loadouts = self:GetLoadoutList(specID)

    loadoutPickerFrame.subtitle:SetText(T("Map an existing WoW talent loadout to %s / %s. This mapping is used by Talents AUTO.", tostring(specName), tostring(contextName)))

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

    if #loadouts == 0 then
        loadoutPickerFrame.footer:SetText(T("No saved WoW talent loadouts were found for this specialization."))
    else
        loadoutPickerFrame.footer:SetText(T("Click a saved WoW loadout to map it. The same loadout can be reused for multiple content types."))
    end
end

function addon:OpenLoadoutPicker()
    if not loadoutPickerFrame then return end
    self:UpdateLoadoutPicker()
    loadoutPickerFrame:Show()
    loadoutPickerFrame:Raise()
end

function addon:UpdateEquipmentPicker()
    if not equipmentPickerFrame or not DB then
        return
    end

    local specID, specName = self:GetSpecInfo()
    local context = self:GetBuildConfigContext()
    local contextName = (Data.contextNames and Data.contextNames[context]) or context
    local _, mappedInfo = self:ResolveEquipmentBinding(specID, context)
    local sets = self:GetEquipmentSetList()

    equipmentPickerFrame.subtitle:SetText(T("Map an existing WoW Equipment Set to %s / %s. This mapping is used by Gear AUTO.", tostring(specName), tostring(contextName)))

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
    else
        equipmentPickerFrame.footer:SetText(T("Click a saved WoW set to map it. DK Mentor does not duplicate it."))
    end
end

function addon:OpenEquipmentPicker()
    if not equipmentPickerFrame then
        return
    end
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
        if ok and aura then
            return aura
        end
    end

    if AuraUtil and AuraUtil.FindAuraBySpellID then
        local ok, name, icon, count, _, duration, expirationTime, source, _, _, auraSpellID = pcall(AuraUtil.FindAuraBySpellID, spellID, "player", "HELPFUL")
        if ok and name then
            return {
                name = name,
                icon = icon,
                applications = count,
                duration = duration,
                expirationTime = expirationTime,
                sourceUnit = source,
                spellId = auraSpellID or spellID,
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
    return result
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

function addon:TrackRuntimeProc(spellID, active)
    local trackedID = NormalizeTrackedBuffSpellID(spellID)
    if not trackedID then return end

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

local function ClearTrackingCooldown(slot)
    if slot and slot.cooldown and slot.cooldown.Clear then
        pcall(slot.cooldown.Clear, slot.cooldown)
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

function addon:RefreshCooldownViewerBuffMirrors()
    if not self.active then return end

    local inCombat = InCombatLockdown and InCombatLockdown() == true

    -- The Blizzard Cooldown Viewer is allowed to resolve restricted aura state.
    -- When available, DK Mentor mirrors its active-state signal for tracked DK
    -- buffs instead of trying to inspect secret aura identifiers in combat.
    -- Loading Blizzard UI modules is deferred out of combat, but once the
    -- viewer exists its already-created frames can be scanned safely in combat.
    if C_AddOns and C_AddOns.LoadAddOn and not _G.BuffIconCooldownViewer and not inCombat then
        pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
    end

    for key in pairs(mirroredBuffItems) do
        mirroredBuffItems[key] = nil
    end

    local specID = select(1, self:GetSpecInfo())
    local wanted = {}
    for _, entry in ipairs(BuildTrackingList("buff", specID)) do
        local spellID = type(entry) == "table" and entry.spellID or entry
        if spellID then
            wanted[spellID] = spellID
            local aliases = Data.buffAuraAliases and Data.buffAuraAliases[spellID]
            for _, aliasSpellID in ipairs(aliases or {}) do
                wanted[aliasSpellID] = spellID
            end
        end
    end

    local function ScanViewer(viewer)
        if not viewer or not viewer.itemFramePool or not viewer.itemFramePool.EnumerateActive then
            return
        end

        if not mirroredViewerHooks[viewer] and hooksecurefunc and viewer.RefreshLayout then
            mirroredViewerHooks[viewer] = true
            hooksecurefunc(viewer, "RefreshLayout", function()
                if addon.active and C_Timer and C_Timer.After then
                    C_Timer.After(0, function()
                        if addon.active then
                            addon:RefreshCooldownViewerBuffMirrors()
                            addon:UpdateBuffBar()
                        end
                    end)
                end
            end)
        end

        pcall(function()
            for item in viewer.itemFramePool:EnumerateActive() do
                local spellID = GetWantedSpellForMirrorItem(item, wanted)
                if spellID then
                    mirroredBuffItems[spellID] = item
                    if not mirroredBuffHooks[item] and hooksecurefunc and item.OnActiveStateChanged then
                        mirroredBuffHooks[item] = true
                        hooksecurefunc(item, "OnActiveStateChanged", function()
                            if addon.active then
                                addon:UpdateBuffBar()
                            end
                        end)
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
    if not item or not item.IsActive then
        return nil, nil
    end

    local ok, active = pcall(item.IsActive, item)
    if not ok then
        return nil, item
    end
    if IsSecretValue(active) then
        return active, item
    end
    if active == nil then
        return nil, item
    end
    return active, item
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
        self:RefreshCooldownViewerBuffMirrors()
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

function addon:UpdateBuffBar()
    if not buffFrame or not DB or not self.active then
        return
    end
    if not self:ShouldShowCombatBar(DB.buffBar) then
        buffFrame:Hide()
        return
    end

    local specID = select(1, self:GetSpecInfo())
    local list = BuildTrackingList("buff", specID)
    local visibleCount = math.min(#list, #buffSlots)
    buffFrame:SetWidth(math.max(92, 14 + (visibleCount * 38)))

    for index, slot in ipairs(buffSlots) do
        local entry = list[index]
        if entry then
            local spellID = type(entry) == "table" and entry.spellID or entry
            local spellName, spellIcon = GetSpellData(spellID)
            local aura = GetPlayerAuraDataSafe(spellID)
            local mirrorActive, mirrorItem = GetMirroredBuffState(spellID)
            local procActive = overlayProcState[spellID]
            local runtimeActive, runtimeState = GetRuntimeBuffPresentation(spellID)
            local activeState

            if aura then
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
            end
            slot.icon:SetTexture(iconTexture)
            SetTrackingReadyVisual(slot, activeState, 0.24)

            if IsAccessibleValue(activeState) and type(activeState) == "boolean" then
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

    local records = GetDynamicPlayerAuras(filter, #slots, externalOnly)
    local visibleCount = #records
    if preview and visibleCount == 0 then visibleCount = math.min(5, #slots) end

    if visibleCount == 0 then
        frame:Hide()
        return
    end

    local perLine = 5
    local rows = math.max(1, math.ceil(visibleCount / perLine))
    frame:SetWidth(200)
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
        local visible = self:ShouldShowCombatBar(DB.externalBuffBar)
        if visible then
            externalBuffFrame:Show()
            externalBuffFrame.managedAuraContainer:Show()
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
        local visible = self:ShouldShowCombatBar(DB.debuffBar)
        if visible then
            debuffFrame:Show()
            debuffFrame.managedAuraContainer:Show()
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
    local visibleCount = math.min(#list, #abilitySlots)
    abilityFrame:SetWidth(math.max(92, 14 + (visibleCount * 38)))

    for index, slot in ipairs(abilitySlots) do
        local entry = list[index]
        if entry then
            local spellID = type(entry) == "table" and entry.spellID or entry
            local spellName, spellIcon = GetSpellData(spellID)
            local cooldownInfo, chargeInfo, durationObject, usable, insufficientPower = GetSpellCooldownPresentation(spellID)

            slot.spellID = spellID
            slot.spellName = spellName
            slot.icon:SetTexture(spellIcon)

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
end

function addon:UpdateHUDSettings()
    if not mainFrame or not mainFrame.hudSection or not DB then return end
    local hud = mainFrame.hudSection
    if hud.buildButton then hud.buildButton:SetText(DB.statusWidget.enabled and T("Build HUD: ON") or T("Build HUD: OFF")) end
    if hud.coachButton then hud.coachButton:SetText(DB.coach.enabled and T("Coach HUD: ON") or T("Coach HUD: OFF")) end
    if hud.buffButton then hud.buffButton:SetText(DB.buffBar.enabled and T("Buff bar: ON") or T("Buff bar: OFF")) end
    if hud.externalBuffButton then hud.externalBuffButton:SetText(DB.externalBuffBar.enabled and T("External buffs: ON") or T("External buffs: OFF")) end
    if hud.debuffButton then hud.debuffButton:SetText(DB.debuffBar.enabled and T("Debuffs: ON") or T("Debuffs: OFF")) end
    if hud.abilityButton then hud.abilityButton:SetText(DB.abilityBar.enabled and T("Ability bar: ON") or T("Ability bar: OFF")) end
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
    local function ResetFramePosition(key, defaults)
        DB[key] = DB[key] or {}
        DB[key].point = defaults.point
        DB[key].relativePoint = defaults.relativePoint
        DB[key].x = defaults.x
        DB[key].y = defaults.y
        DB[key].scale = defaults.scale
    end

    ResetFramePosition("coach", DEFAULTS.coach)
    ResetFramePosition("statusWidget", DEFAULTS.statusWidget)
    ResetFramePosition("buffBar", DEFAULTS.buffBar)
    ResetFramePosition("externalBuffBar", DEFAULTS.externalBuffBar)
    ResetFramePosition("debuffBar", DEFAULTS.debuffBar)
    ResetFramePosition("abilityBar", DEFAULTS.abilityBar)
    RestoreFramePosition(coachFrame, "coach")
    RestoreFramePosition(statusWidget, "statusWidget")
    RestoreFramePosition(buffFrame, "buffBar")
    RestoreFramePosition(externalBuffFrame, "externalBuffBar")
    RestoreFramePosition(debuffFrame, "debuffBar")
    RestoreFramePosition(abilityFrame, "abilityBar")
    Print(T("Combat HUD positions restored."))
end

function addon:ResetPositions()
    local function ResetFramePosition(key, defaults)
        DB[key] = DB[key] or {}
        DB[key].point = defaults.point
        DB[key].relativePoint = defaults.relativePoint
        DB[key].x = defaults.x
        DB[key].y = defaults.y
        DB[key].scale = defaults.scale
    end

    ResetFramePosition("main", DEFAULTS.main)
    ResetFramePosition("coach", DEFAULTS.coach)
    ResetFramePosition("statusWidget", DEFAULTS.statusWidget)
    ResetFramePosition("buffBar", DEFAULTS.buffBar)
    ResetFramePosition("externalBuffBar", DEFAULTS.externalBuffBar)
    ResetFramePosition("debuffBar", DEFAULTS.debuffBar)
    ResetFramePosition("abilityBar", DEFAULTS.abilityBar)
    RestoreFramePosition(mainFrame, "main")
    RestoreFramePosition(coachFrame, "coach")
    RestoreFramePosition(statusWidget, "statusWidget")
    RestoreFramePosition(buffFrame, "buffBar")
    RestoreFramePosition(externalBuffFrame, "externalBuffBar")
    RestoreFramePosition(debuffFrame, "debuffBar")
    RestoreFramePosition(abilityFrame, "abilityBar")
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
    Print(T("/dkm combatbars combat|always - show aura/ability bars only in combat or always"))
    Print(T("/dkm guide — open the beginner specialization guide"))
    Print(T("/dkm settings — open HUD and commentary settings"))
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
        local map = { auto = "auto", world = "world", delve = "delve", dungeon = "dungeon", raid = "raid", pvp = "pvp" }
        self:SetMode(map[string.lower(rest)] or rest)
    elseif command == "guide" then
        mainFrame:Show()
        self:SetMainTab("guide")
        self:UpdateAll()
    elseif command == "settings" or command == "config" then
        mainFrame:Show()
        self:SetMainTab("settings")
        self:UpdateAll()
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

    if previousSchema < 16 then
        DB.autoSwitchLoadouts = true
        DB.autoSwitchEquipment = true
        if DB.buildContextSelection == nil or DB.buildContextSelection == "auto" then
            DB.buildContextSelection = self:DetectActualContext()
        end
    end

    -- 1.0.8 deliberately removes the experimental War Mode profile/button.
    -- Clean only state introduced by those experimental builds so the proven
    -- World/Delve/Dungeon/Raid/PvP mappings remain untouched.
    local validBuildModes = { world = true, delve = true, dungeon = true, raid = true, pvp = true }

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
    loadoutPickerFrame = CreateLoadoutPickerFrame()
    equipmentPickerFrame = CreateEquipmentPickerFrame()
    voiceConfigFrame = CreateVoiceConfigFrame()
    minimapButton = CreateMinimapButton()
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
        "RUNE_POWER_UPDATE",
        "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW",
        "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE",
        "COOLDOWN_VIEWER_DATA_LOADED",
        "COOLDOWN_VIEWER_TABLE_HOTFIXED",
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
        "UNIT_SPELLCAST_SUCCEEDED",
        "ITEM_DATA_LOAD_RESULT",
        "NEW_MOUNT_ADDED",
        "PVP_MATCH_COMPLETE",
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
            voiceConfigFrame:Hide()
            minimapButton:Hide()
            Print(T("This addon only runs on Death Knights."))
            return
        end

        self.active = true
        self.worldReady = false
        self.playerWasDead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") or false
        self.lastMountedState = IsMounted and IsMounted() == true or false
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
        self:RefreshCooldownViewerBuffMirrors()
        self:UpdateBuffBar()
        self:UpdateExternalBuffBar()
        self:UpdateDebuffBar()
        self:UpdateAbilityBar()
    elseif event == "PLAYER_REGEN_ENABLED" then
        local combatDuration = combatStartedAt and (GetNow() - combatStartedAt) or 0
        self:SyncReadableBuffRuntime(true)
        combatStartedAt = nil
        if DB.autoHideMainInCombat and self.mainWasVisibleBeforeCombat then
            mainFrame:Show()
        end
        self.mainWasVisibleBeforeCombat = false
        if combatDuration >= 8 and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then
            self:TryVoiceComment("combatVictory")
        end
        self:RefreshCooldownViewerBuffMirrors()
        self:UpdateAll()
        self:TryAutoSwitchLoadout("combat-ended")
        self:TryAutoSwitchEquipment("combat-ended")
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
    elseif event == "UNIT_POWER_UPDATE" then
        local unit = ...
        if unit == "player" then
            self:UpdateAbilityBar()
        end
    elseif event == "RUNE_POWER_UPDATE" then
        self:UpdateAbilityBar()
    elseif event == "COOLDOWN_VIEWER_DATA_LOADED" or event == "COOLDOWN_VIEWER_TABLE_HOTFIXED" then
        self:RefreshCooldownViewerBuffMirrors()
        self:UpdateBuffBar()
        self:UpdateAbilityBar()
    elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
        -- Midnight can switch secret-data restrictions without a normal aura
        -- or cooldown event. Refresh every visual tracker at that boundary.
        self:RefreshCooldownViewerBuffMirrors()
        self:UpdateBuffBar()
        self:UpdateExternalBuffBar()
        self:UpdateDebuffBar()
        self:UpdateAbilityBar()
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
    elseif event == "PLAYER_ENTERING_BATTLEGROUND" then
        -- Try during the battleground preparation window, before PVP_MATCH_ACTIVE.
        if C_Timer and C_Timer.After then
            C_Timer.After(0.35, function()
                if addon.active then
                    addon.worldReady = true
                    addon:TryAutoSwitchLoadout("pvp-enter")
                    addon:TryAutoSwitchEquipment("pvp-enter")
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
        local result, setID = ...
        if result then
            self.pendingEquipmentKey = nil
        end
        self:UpdateBuildSection()
        self:UpdateStatusWidget()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        self:ScheduleUpdate(false)
    elseif event == "UNIT_SPELLCAST_SENT" then
        local unitTarget, _, _, spellID = ...
        if unitTarget == "player" then
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
        if unitTarget == "player" and self:IsHearthstoneSpell(spellID) then
            -- Fallback for clients/toys where SENT was not observed. The
            -- per-category interval prevents this from double-playing.
            self:TriggerPriorityVoice("hearthstone", 6)
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...
        if unitTarget == "player" then
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
        self:ScheduleUpdate(false)
        -- Delay non-essential work until the loading transition has settled.
        C_Timer.After(4, function()
            if addon.active then
                addon.worldReady = true
                addon:SyncReadableBuffRuntime(true)
                addon:RefreshCooldownViewerBuffMirrors()
                addon:RefreshVoiceTriggerCaches(false)
                addon:TryVoiceComment("zone")
                addon:UpdateAll()
                addon:TryAutoSwitchLoadout("context-change")
                addon:TryAutoSwitchEquipment("context-change")
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
            local afk = UnitIsAFK("player") == true
            if afk ~= self.lastAFKState then
                self.lastAFKState = afk
                self:TryVoiceComment(afk and "afkStart" or "afkEnd")
            end
        end
    elseif event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
            self:UpdateStatusWidget()
            if DB.voice.situational and UnitExists and UnitExists("pet") then
                self:TryVoiceComment("petSummon")
            end
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if unit == "player" then
            self:UpdateStatusWidget()
        end
    elseif event == "CHALLENGE_MODE_START" or event == "PVP_MATCH_ACTIVE" then
        self:ScheduleUpdate(false)
        if C_Timer and C_Timer.After then
            C_Timer.After(0.75, function()
                if addon.active then
                    addon:TryAutoSwitchLoadout("content-start")
                    addon:TryAutoSwitchEquipment("content-start")
                end
            end)
        end
    elseif event == "CVAR_UPDATE" then
        local cvarName = ...
        if cvarName == "assistedCombatHighlight" or cvarName == "ASSISTEDCOMBATHIGHLIGHT" then
            self:UpdateAssistedCombatSection()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if not unit or unit == "player" then
            if specializationPickerFrame then
                specializationPickerFrame:Hide()
                self:UpdateSpecializationPicker()
            end
            self:ScheduleUpdate(true)
            C_Timer.After(1, function()
                if addon.active then
                    if not InCombatLockdown() then addon:RefreshCooldownViewerBuffMirrors() end
                    addon:TryAutoSwitchLoadout("specialization")
                    addon:TryAutoSwitchEquipment("specialization")
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
        end
    end

    -- Instance/PvP transitions can briefly report the previous instance type.
    -- Poll only the coarse environment twice per second and refresh when it
    -- actually changes. This reads no combat-secret aura/resource data.
    contextPollElapsed = contextPollElapsed + delta
    if contextPollElapsed >= 0.50 then
        contextPollElapsed = 0
        local detectedContext = self:DetectActualContext()
        if detectedContext ~= self.currentContext then
            self.currentContext = detectedContext
            self:UpdateAll()
            if self.worldReady then
                self:TryAutoSwitchLoadout("context-detected")
                self:TryAutoSwitchEquipment("context-detected")
            end
        end
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
