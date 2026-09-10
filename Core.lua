local ADDON_NAME, DKM = ...

local Data = DKM.Data or {}
local Builds = DKM.Builds or {}
local Voices = DKM.Voices or {}
local Guides = DKM.Guides or {}
local GearData = DKM.GearData or {}
DKM.PreparationData = DKM.PreparationData or {}
local T = DKM.T or function(value, ...)
    if select("#", ...) > 0 then
        return string.format(value, ...)
    end
    return value
end

local addon = CreateFrame("Frame")
DKM.Addon = addon
addon.hudEditSessionActive = false

local DB
local mainFrame
local coachFrame
local minimapButton
local statusWidget
local specializationPickerFrame
local voiceConfigFrame
addon.lichKingPortraitFrame = nil
addon.layoutPresetFrame = nil
local languagePickerFrame
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
addon.interruptActionGlowTargets = {}
addon.interruptGlowFrames = setmetatable({}, { __mode = "k" })
addon.interruptGlowRefreshToken = 0
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
    schema = 34,
    firstRun = true,
    majorReleaseNotice = "",
    languageOverride = "auto",
    modeOverride = "auto",
    autoHideMainInCombat = true,
    combatBarsOnlyInCombat = true,
    mainTab = "combat",
    codexSpecID = 0,
    codexSection = "overview",
    codexBuildContext = "auto",
    codexMetaContext = "raid",
    codexAdvisorContext = "auto",
    codexBuildMode = "standard",
    codexGearView = "overview",
    valeeraPreset = "auto",
    hudLocked = true,
    main = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = -35,
        y = 20,
        scale = 1,
    },
    -- Starter HUD layout: keep the main combat HUDs in distinct bands so a
    -- fresh install (and Reset HUDs) never piles the preview bars on top of the
    -- Mentor Coach near the bottom-center of the screen.
    coach = {
        enabled = true,
        onlyInCombat = true,
        adaptiveHealth = true,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 250,
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
        x = -220,
        y = 395,
        scale = 1,
        iconsPerRow = 5,
        opacity = 1,
    },
    externalBuffBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 395,
        scale = 1,
        iconsPerRow = 5,
        opacity = 1,
    },
    debuffBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 220,
        y = 395,
        scale = 1,
        iconsPerRow = 5,
        opacity = 1,
    },
    abilityBar = {
        enabled = false,
        point = "BOTTOM",
        relativePoint = "BOTTOM",
        x = 0,
        y = 175,
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
        y = 95,
        scale = 1,
        opacity = 1,
        visibilityMode = "combat",
        fadeAlpha = 0.20,
    },
    interruptAlert = {
        enabled = true,
        actionGlow = true,
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
        portrait = {
            enabled = false,
            locked = true,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 165,
            scale = 1,
            character = "arthas",
        },
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

addon.MAIN_HAND_SLOT = _G.INVSLOT_MAINHAND or 16
addon.OFF_HAND_SLOT = _G.INVSLOT_OFFHAND or 17

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

    -- Midnight can occasionally withhold the legacy inventory link even while
    -- the equipped item itself is known.  Try the namespaced ItemLocation API
    -- before treating the slot as still loading.
    if (not itemID or not itemLink) and ItemLocation and ItemLocation.CreateFromEquipmentSlot and C_Item then
        local okLoc, location = pcall(ItemLocation.CreateFromEquipmentSlot, ItemLocation, slotID)
        if okLoc and location then
            if not itemID and C_Item.GetItemID then
                local okID, value = pcall(C_Item.GetItemID, location)
                if okID and IsAccessibleValue(value) and type(value) == "number" and value > 0 then
                    itemID = value
                end
            end
            if not itemLink and C_Item.GetItemLink then
                local okLink, value = pcall(C_Item.GetItemLink, location)
                if okLink and IsAccessibleValue(value) and type(value) == "string" then
                    itemLink = value
                end
            end
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


function addon:GetPermanentEnchantState(slotID)
    local itemID, itemLink = GetEquippedItemData(slotID)
    if not itemID and not itemLink then
        return false, true, 0
    end

    if itemLink then
        local enchantID = GetPermanentEnchantID(itemLink)
        if enchantID ~= nil then
            return enchantID > 0, true, enchantID
        end
    end

    -- TooltipInfo exposes permanent enchantment rows directly and is a safer
    -- fallback on Midnight when an equipped item's hyperlink is temporarily
    -- unavailable to addon Lua.  This prevents Preparation cards from sitting
    -- on CHECKING forever when the client can already render the item tooltip.
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slotID)
        if ok and type(data) == "table" and type(data.lines) == "table" then
            local permanentType = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent or 15
            for _, line in ipairs(data.lines) do
                if type(line) == "table" and IsAccessibleNumber(line.type) and line.type == permanentType then
                    return true, true, nil
                end
            end
            -- The tooltip exists and contains a complete line table.  If there
            -- is no permanent-enchantment row, the slot is genuinely missing it.
            return false, true, 0
        end
    end

    return false, false, nil
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
    local main = self:GetRuneforgeSlotStatus(addon.MAIN_HAND_SLOT, T("Main hand"))
    local off = self:GetRuneforgeSlotStatus(addon.OFF_HAND_SLOT, T("Off hand"))
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

    local currentSpecID, currentSpecName = self:GetSpecInfo()
    local context = self:DetectActualContext()
    local issues = {}
    local hardIssue = false

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
        specName = currentSpecName,
        context = context,
        issues = issues,
        summary = summary,
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

    Print("|cff89d8ff" .. T("Specialization") .. ":|r " .. tostring(status.specName or status.specID or "-"))
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

function addon:GetRuntimeSpecLabel(specID, fallbackName)
    local labelKey = Data.specNames and Data.specNames[specID]
    if labelKey then
        return T(labelKey)
    end
    if fallbackName and fallbackName ~= "" then
        return T(fallbackName)
    end
    return T("Death Knight")
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
            return specID, self:GetRuntimeSpecLabel(specID, specName), specIcon or QUESTION_MARK_ICON, specializationIndex
        end
    end

    return 0, T("No specialization"), QUESTION_MARK_ICON, 0
end

function addon:GetSpecializationInfoByIndex(index)
    if not index then return nil end

    if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
        local ok, specID, specName, _, specIcon = pcall(C_SpecializationInfo.GetSpecializationInfo, index)
        if ok and specID then
            return specID, self:GetRuntimeSpecLabel(specID, specName), specIcon or QUESTION_MARK_ICON
        end
    elseif GetSpecializationInfo then
        local specID, specName, _, specIcon = GetSpecializationInfo(index)
        if specID then
            return specID, self:GetRuntimeSpecLabel(specID, specName), specIcon or QUESTION_MARK_ICON
        end
    end

    return nil
end

function addon:GetSpecIconByID(specID)
    specID = tonumber(specID)
    if specID == 250 then
        return select(3, self:GetSpecializationInfoByIndex(1)) or QUESTION_MARK_ICON
    elseif specID == 251 then
        return select(3, self:GetSpecializationInfoByIndex(2)) or QUESTION_MARK_ICON
    elseif specID == 252 then
        return select(3, self:GetSpecializationInfoByIndex(3)) or QUESTION_MARK_ICON
    end
    return QUESTION_MARK_ICON
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

function addon:SwitchSpecialization(index)
    index = tonumber(index)
    if not index or index < 1 or index > 3 then
        return false
    end

    if InCombatLockdown and InCombatLockdown() then
        Print(T("You cannot change specialization during combat."))
        return false
    end

    local _, _, _, currentIndex = self:GetSpecInfo()
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
    -- Manual-only convenience. DK Mentor 2.0 never invokes specialization
    -- switching as part of content detection, Codex guidance, or automation.
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

            if challengeActive == true or keystoneSlotted == true then
                return "mythicplus"
            end
            return "dungeon"
        end
    end

    return "world"
end

function addon:DetectContext()
    return self:DetectActualContext(), true
end

function addon:GetRuntimeContextLabel(context)
    context = context or self:DetectActualContext()
    local labelKey = (Data.contextNames and Data.contextNames[context]) or context
    return T(labelKey)
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

local function GetKnownRotationSpellID(spellID)
    if type(spellID) ~= "number" or spellID <= 0 then
        return nil
    end

    if IsSpellKnownSafe(spellID) then
        return spellID
    end

    -- Some action-bar entries use the currently active override rather than the
    -- base spell returned by Assisted Combat. Accept the override only when the
    -- player actually knows it in the active spellbook/talent configuration.
    if C_Spell and C_Spell.GetOverrideSpell then
        local ok, overrideSpellID = pcall(C_Spell.GetOverrideSpell, spellID)
        if ok and type(overrideSpellID) == "number" and overrideSpellID > 0 and overrideSpellID ~= spellID then
            if IsSpellKnownSafe(overrideSpellID) then
                return overrideSpellID
            end
        end
    end

    return nil
end

function addon:GetRelevantRotationSpells()
    local rawSpells = self:GetRotationSpells()
    if #rawSpells == 0 then
        return {}
    end

    local activeSpecID = select(1, self:GetSpecInfo())
    local restrictions = Data.assistedCombatSpecRestrictions or {}
    local relevant, seen = {}, {}

    for _, spellID in ipairs(rawSpells) do
        local requiredSpecID = restrictions[spellID]
        if not requiredSpecID or requiredSpecID == activeSpecID then
            local knownSpellID = GetKnownRotationSpellID(spellID)
            if knownSpellID and not seen[knownSpellID] then
                seen[knownSpellID] = true
                relevant[#relevant + 1] = knownSpellID
            end
        end
    end

    return relevant
end

function addon:CheckActionBarCoverage(silent)
    -- Coverage is about the active specialization/loadout, not every spell that
    -- Assisted Combat may momentarily report while its data is refreshing.
    local rotationSpells = self:GetRelevantRotationSpells()
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
            -- PlaySoundFile does not expose a finish callback for FileDataIDs,
            -- so poll the returned sound handle. Keep a tiny startup grace period
            -- in case the queued sound has not begun on the very first frame.
            if now - (addon.voiceStartedAt or 0) < 0.20 then
                return true
            end
            voiceHandle = nil
            voiceBusyUntil = 0
            return false
        end
    end

    -- Fallback for clients where a usable sound handle / C_Sound.IsPlaying is
    -- unavailable. Normal Retail clients should leave through the handle path.
    return now < (voiceBusyUntil or 0)
end

function addon:StopVoice()
    if voiceHandle and StopSound then
        pcall(StopSound, voiceHandle)
    end

    voiceHandle = nil
    voiceBusyUntil = 0
    addon.voiceStartedAt = 0
    self:SetLichKingPortraitTalking(false)
    if addon.lichKingPortraitFrame then addon.lichKingPortraitFrame:Hide() end
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
    addon.voiceStartedAt = GetNow()
    -- This timeout is only a fail-safe when the client cannot report whether
    -- the returned sound handle is still playing. The portrait normally stops
    -- as soon as C_Sound.IsPlaying reports that the voice has ended.
    voiceBusyUntil = addon.voiceStartedAt + 7
    self:ShowLichKingPortrait()
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
    elseif action == "portrait" then
        if value == "arthas" or value == "bolvar" then
            self:SetLichKingPortraitCharacter(value)
        else
            Print(T("Use /dkm voice portrait arthas or /dkm voice portrait bolvar."))
        end
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
        Print(T("Use /dkm voice on|off|test|low|normal|high|status|map|reset, /dkm voice pvp on|off, /dkm voice situations on|off, or /dkm voice portrait arthas|bolvar."))
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

addon.ACTION_BUTTON_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local function StyleActionButton(button)
    if not button or not button.SetBackdropColor then return end
    local enabled = true
    if button.IsEnabled then
        local ok, value = pcall(button.IsEnabled, button)
        if ok then enabled = value ~= false end
    end
    local selected = button.__dkSelected == true
    local hover = button.__dkHover == true
    local pressed = button.__dkPressed == true
    local fontString = button.GetFontString and button:GetFontString() or button.label

    if not enabled then
        button:SetBackdropColor(0.018, 0.035, 0.045, 0.86)
        button:SetBackdropBorderColor(0.10, 0.20, 0.24, 0.72)
        if fontString then fontString:SetTextColor(0.42, 0.48, 0.50) end
    elseif selected then
        button:SetBackdropColor(0.035, 0.20, 0.27, pressed and 0.90 or 0.98)
        button:SetBackdropBorderColor(0.35, 0.82, 1.00, 1)
        if fontString then fontString:SetTextColor(0.78, 0.95, 1.00) end
    elseif pressed then
        button:SetBackdropColor(0.035, 0.13, 0.17, 0.98)
        button:SetBackdropBorderColor(0.24, 0.62, 0.76, 0.98)
        if fontString then fontString:SetTextColor(0.90, 0.97, 1.00) end
    elseif hover then
        button:SetBackdropColor(0.045, 0.14, 0.18, 0.98)
        button:SetBackdropBorderColor(0.28, 0.68, 0.82, 0.98)
        if fontString then fontString:SetTextColor(0.94, 0.99, 1.00) end
    else
        button:SetBackdropColor(0.025, 0.075, 0.10, 0.94)
        button:SetBackdropBorderColor(0.15, 0.42, 0.54, 0.88)
        if fontString then fontString:SetTextColor(0.86, 0.93, 0.96) end
    end
end

local function SetActionButtonSelected(button, selected)
    if not button then return end
    button.__dkSelected = selected == true
    StyleActionButton(button)
end

local function CreateActionButton(parent, width, height, label)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 120, height or 28)
    button:SetBackdrop(addon.ACTION_BUTTON_BACKDROP)

    local fontString = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontString:SetPoint("LEFT", button, "LEFT", 8, 0)
    fontString:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    fontString:SetJustifyH("CENTER")
    fontString:SetJustifyV("MIDDLE")
    button:SetFontString(fontString)
    button.label = fontString
    button:SetText(label and T(label) or "")

    button:HookScript("OnEnter", function(self) self.__dkHover = true; StyleActionButton(self) end)
    button:HookScript("OnLeave", function(self) self.__dkHover = false; self.__dkPressed = false; StyleActionButton(self) end)
    button:HookScript("OnMouseDown", function(self) self.__dkPressed = true; StyleActionButton(self) end)
    button:HookScript("OnMouseUp", function(self) self.__dkPressed = false; StyleActionButton(self) end)
    StyleActionButton(button)
    return button
end

DKM.CreateActionButton = CreateActionButton
DKM.SetActionButtonSelected = SetActionButtonSelected
DKM.StyleActionButton = StyleActionButton

local function StyleTabButton(button, active)
    if not button then return end
    button.isSelected = active == true
    if active then
        button:SetBackdropColor(0.035, 0.20, 0.27, 0.98)
        button:SetBackdropBorderColor(0.35, 0.82, 1.00, 1)
        button.label:SetTextColor(0.72, 0.94, 1.00)
        if button.icon then button.icon:SetDesaturated(false) end
    else
        button:SetBackdropColor(0.025, 0.065, 0.085, 0.90)
        button:SetBackdropBorderColor(0.16, 0.38, 0.48, 0.82)
        button.label:SetTextColor(0.92, 0.84, 0.58)
        if button.icon then button.icon:SetDesaturated(false) end
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

local function EnsureFlatTabButtonIcon(button, size)
    if not button then return nil end
    if not button.icon then
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    button.icon:SetSize(size or 18, size or 18)
    button.icon:Show()
    return button.icon
end

local function SetFlatTabButtonIcon(button, texture, size)
    if not button then return end
    if texture and texture ~= 0 then
        local icon = EnsureFlatTabButtonIcon(button, size)
        icon:SetTexture(texture)
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", button, "LEFT", 9, 0)

        button.label:ClearAllPoints()
        button.label:SetPoint("LEFT", icon, "RIGHT", 7, 0)
        button.label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
        button.label:SetJustifyH("LEFT")
        button.label:SetJustifyV("MIDDLE")
    else
        if button.icon then button.icon:Hide() end
        button.label:ClearAllPoints()
        button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.label:SetJustifyH("CENTER")
        button.label:SetJustifyV("MIDDLE")
    end
end

local function SetFlatTabButtonMultiline(button, inset)
    if not button or not button.label then return end
    local leftInset = inset or 8
    button.label:ClearAllPoints()
    button.label:SetPoint("TOPLEFT", button, "TOPLEFT", leftInset, -4)
    button.label:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -8, 4)
    button.label:SetJustifyH("CENTER")
    button.label:SetJustifyV("MIDDLE")
    button.label:SetWordWrap(true)
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
        local button = CreateFlatTabButton(bar, buttonWidth, 26, addon:GetRuntimeContextLabel(contextKey))
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
            button:SetText(addon:GetRuntimeContextLabel(button.contextKey))
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
    frame:SetSize(450, 250)
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
    frame.description:SetWidth(410)
    frame.description:SetJustifyH("LEFT")
    frame.description:SetJustifyV("TOP")
    frame.description:SetText(T("Choose the DK Mentor language. Automatic follows the WoW client language; unsupported client languages use English."))

    frame.current = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.current:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -92)
    frame.current:SetWidth(410)
    frame.current:SetJustifyH("LEFT")

    local choices = {
        { value = "auto", label = "Automatic (WoW)" },
        { value = "ptBR", label = "Portuguese (Brazil)" },
        { value = "enUS", label = "English" },
    }
    frame.choiceButtons = {}
    for index, choice in ipairs(choices) do
        local button = CreateActionButton(frame)
        button:SetSize(128, 30)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 16 + ((index - 1) * 136), -120)
        button.languageValue = choice.value
        button.languageLabelKey = choice.label
        button:SetText(T(choice.label))
        button:SetScript("OnClick", function(self)
            addon:SetLanguageOverride(self.languageValue)
        end)
        frame.choiceButtons[index] = button
    end

    frame.cancel = CreateActionButton(frame)
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

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "DKMentorMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(1060, 780)
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
    frame.subtitle:SetWidth(930)
    frame.subtitle:SetJustifyH("LEFT")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    -- DK Mentor 2.0 focuses on Death Knight gameplay. Loadout automation lives
    -- in the dedicated Loadout Pilot addon.
    local tabOrder = { "combat", "guide", "settings" }
    local tabLabels = {
        combat = T("Combat"),
        guide = T("DK Codex"),
        settings = T("Settings"),
    }
    local tabGap = 8
    local tabLeft = 22
    local tabRight = 22
    local tabWidth = math.floor((frame:GetWidth() - tabLeft - tabRight - (tabGap * (#tabOrder - 1))) / #tabOrder)
    for index, tabKey in ipairs(tabOrder) do
        local button = CreateFlatTabButton(frame, tabWidth, 31, tabLabels[tabKey])
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", tabLeft + ((index - 1) * (tabWidth + tabGap)), -69)
        button.tabKey = tabKey
        button:SetScript("OnClick", function(self)
            addon:SetMainTab(self.tabKey)
        end)
        tabButtons[tabKey] = button
    end

    frame.pages = {}
    local function CreatePage(key)
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -104)
        page:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 34)
        page:Hide()
        frame.pages[key] = page
        return page
    end

    local combatPage = CreatePage("combat")
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

    offense.toggleButton = CreateActionButton(offense)
    offense.toggleButton:SetSize(205, 26)
    offense.toggleButton:SetPoint("TOPRIGHT", offense, "TOPRIGHT", -12, -30)
    offense.toggleButton:SetScript("OnClick", function() addon:ToggleNativeHighlight() end)

    offense.checkButton = CreateActionButton(offense)
    offense.checkButton:SetSize(205, 26)
    offense.checkButton:SetPoint("TOPRIGHT", offense, "TOPRIGHT", -12, -62)
    offense.checkButton:SetText(T("Check action bars"))
    offense.checkButton:SetScript("OnClick", function() addon:CheckActionBarCoverage(false) end)

    offense.hint = offense:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    offense.hint:SetPoint("BOTTOMLEFT", offense, "BOTTOMLEFT", 12, 10)
    offense.hint:SetWidth(745)
    offense.hint:SetJustifyH("LEFT")
    offense.hint:SetText(T("The offensive highlight comes from Blizzard Assisted Combat. DK Mentor does not calculate a custom APL during combat."))

    frame.survivalSection = CreateSection(combatPage, T("DK Toolkit — reference"), -194, 322)
    local survival = frame.survivalSection

    survival.scopeHint = survival:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    survival.scopeHint:SetPoint("TOPRIGHT", survival, "TOPRIGHT", -10, -9)
    survival.scopeHint:SetText(T("Reference list; Live Mentor shows only relevant calls."))

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

    -- DK CODEX TAB ---------------------------------------------------------
    guidePage.scope = guidePage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    guidePage.scope:SetPoint("TOPLEFT", guidePage, "TOPLEFT", 12, -8)
    guidePage.scope:SetWidth(1000)
    guidePage.scope:SetJustifyH("LEFT")
    guidePage.scope:SetText(T("DK Codex is an in-game Death Knight reference for Patch 12.1. Browse any DK specialization without changing the specialization you are playing. Choose a specialization above, then use the left menu to move between sections."))
    guidePage.scope:SetTextColor(0.68, 0.88, 0.97)
    guidePage.scope:SetShadowColor(0, 0, 0, 0.85)
    guidePage.scope:SetShadowOffset(1, -1)

    guidePage.specButtons = {}
    local codexSpecChoices = {
        { id = 0, labelKey = "Current" },
        { id = 250, labelKey = "Blood" },
        { id = 251, labelKey = "Frost" },
        { id = 252, labelKey = "Unholy" },
    }
    local specButtonGap = 8
    local specButtonAreaWidth = math.max(840, frame:GetWidth() - 48)
    local specButtonWidth = math.floor((specButtonAreaWidth - (specButtonGap * (#codexSpecChoices - 1))) / #codexSpecChoices)
    for index, choice in ipairs(codexSpecChoices) do
        local button = CreateFlatTabButton(guidePage, specButtonWidth, 28, T(choice.labelKey))
        button:SetPoint("TOPLEFT", guidePage, "TOPLEFT", 14 + ((index - 1) * (specButtonWidth + specButtonGap)), -34)
        button.codexSpecID = choice.id
        button.labelKey = choice.labelKey
        button.label:SetWordWrap(false)
        button:SetScript("OnClick", function(self) addon:SetCodexSpecID(self.codexSpecID) end)
        guidePage.specButtons[choice.id] = button
    end

    guidePage.sectionButtons = {}
    local codexSections = { "overview", "advisor", "stats", "builds", "meta", "valeera", "rotation", "survival", "utility", "check" }
    local codexSectionMenuLabels = {
        overview = "Overview",
        advisor = "Stats & Folio",
        stats = "Equipment",
        builds = "Builds",
        meta = "Meta",
        valeera = "Valeera",
        rotation = "Rotation",
        survival = "Survival",
        utility = "Utility",
        check = "Character check short",
    }
    -- Native WoW icons only: no artwork is bundled by DK Mentor.
    -- Use distinct silhouettes for Codex navigation so sections are readable at a glance.
    -- Numeric textures are Blizzard FileDataIDs from the retail client and avoid locale coupling.
    local codexSectionMenuIcons = {
        overview = { texture = 133743 },  -- INV_Misc_Book_11: reference / overview
        advisor = { spellID = 1279609 }, -- Omnium Folio: Critical Power
        stats = { texture = 132736 },     -- INV_Chest_Plate01: equipment
        builds = { texture = 132222 },    -- Ability_Marksmanship: planning / build target
        meta = { texture = 132767 },      -- INV_Crown_01: ranking / meta
        valeera = { spellID = 1784 },     -- Stealth: Valeera / rogue companion
        rotation = { texture = 132306 },  -- Ability_Rogue_SliceDice: action sequence / rotation
        survival = { spellID = 48792 },   -- Icebound Fortitude
        utility = { spellID = 49576 },    -- Death Grip
        check = { texture = "Interface\\RaidFrame\\ReadyCheck-Ready" }, -- Blizzard ready-check mark
    }

    frame.guideSection = CreateSection(guidePage, T("DK Codex"), -81, 538)
    local guide = frame.guideSection
    guide.navWidth = 160
    guide.contentLeft = 182
    guide.contentWidth = 780

    guide.navHint = guide:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    guide.navHint:SetPoint("TOPLEFT", guide, "TOPLEFT", 16, -31)
    guide.navHint:SetWidth(guide.navWidth - 8)
    guide.navHint:SetJustifyH("LEFT")
    guide.navHint:SetText(T("Sections"))
    guide.navHint:SetTextColor(0.68, 0.88, 0.97)
    guide.navHint:SetShadowColor(0, 0, 0, 0.85)
    guide.navHint:SetShadowOffset(1, -1)

    guide.navPanel = CreateFrame("Frame", nil, guide)
    guide.navPanel:SetPoint("TOPLEFT", guide, "TOPLEFT", 12, -54)
    guide.navPanel:SetPoint("BOTTOMLEFT", guide, "BOTTOMLEFT", 12, 18)
    guide.navPanel:SetWidth(guide.navWidth)

    for index, sectionKey in ipairs(codexSections) do
        local labelKey = codexSectionMenuLabels[sectionKey]
        local label = labelKey and T(labelKey) or (((DKM.Codex and DKM.Codex.sectionLabels) and (DKM.Codex and DKM.Codex.sectionLabels)[sectionKey]) or sectionKey)
        local button = CreateFlatTabButton(guide.navPanel, guide.navWidth - 10, 40, label)
        button:SetPoint("TOPLEFT", guide.navPanel, "TOPLEFT", 4, -((index - 1) * 44))
        local buttonFont = button.label
        if buttonFont and GameFontNormalSmall then buttonFont:SetFontObject(GameFontNormalSmall) end
        SetFlatTabButtonMultiline(button, 6)
        button.codexSection = sectionKey
        button.menuLabelKey = labelKey
        local iconInfo = codexSectionMenuIcons[sectionKey] or {}
        button.menuIconSpellID = iconInfo.spellID
        button.menuIconTexture = iconInfo.texture
        button.menuIconDynamic = iconInfo.dynamic
        button:SetScript("OnClick", function(self) addon:SetCodexSection(self.codexSection) end)
        guidePage.sectionButtons[sectionKey] = button
    end

    guide.specTitle = guide:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    guide.specTitle:SetPoint("TOPLEFT", guide, "TOPLEFT", guide.contentLeft, -31)
    guide.specTitle:SetWidth(guide.contentWidth - 10)
    guide.specTitle:SetJustifyH("LEFT")
    guide.specTitle:SetTextColor(0.60, 0.88, 1)
    guide.specTitle:SetShadowColor(0, 0, 0, 0.90)
    guide.specTitle:SetShadowOffset(1, -1)

    guide.scroll = CreateFrame("ScrollFrame", nil, guide, "UIPanelScrollFrameTemplate")
    guide.scroll:SetPoint("TOPLEFT", guide, "TOPLEFT", guide.contentLeft, -64)
    guide.scroll:SetPoint("BOTTOMRIGHT", guide, "BOTTOMRIGHT", -31, 18)

    guide.content = CreateFrame("Frame", nil, guide.scroll)
    guide.content:SetSize(guide.contentWidth, 1)
    guide.scroll:SetScrollChild(guide.content)

    guide.text = guide.content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    guide.text:SetPoint("TOPLEFT", guide.content, "TOPLEFT", 2, 0)
    guide.text:SetWidth(guide.contentWidth - 28)
    guide.text:SetJustifyH("LEFT")
    guide.text:SetJustifyV("TOP")
    guide.text:SetWordWrap(true)
    guide.text:SetTextColor(0.92, 0.96, 1.00)
    guide.text:SetShadowColor(0, 0, 0, 0.80)
    guide.text:SetShadowOffset(1, -1)

    guide.buildActions = CreateFrame("Frame", nil, guide)
    guide.buildActions:SetPoint("TOPLEFT", guide, "TOPLEFT", guide.contentLeft, -58)
    guide.buildActions:SetPoint("TOPRIGHT", guide, "TOPRIGHT", -12, -58)
    guide.buildActions:SetHeight(96)
    guide.buildActions:Hide()

    guide.buildContextButtons = {}
    local buildContexts = {
        { key="auto", labelKey="Auto", iconSpellID=47568 },          -- Empower Rune Weapon
        { key="world", labelKey="World", iconSpellID=48265 },      -- Death's Advance
        { key="delve", labelKey="Delve", iconSpellID=48792 },      -- Icebound Fortitude
        { key="dungeon", labelKey="Dungeon", iconSpellID=47528 },  -- Mind Freeze
        { key="mythicplus", labelKey="Mythic+", iconSpellID=43265 }, -- Death and Decay
        { key="raid", labelKey="Raid", iconSpellID=42650 },        -- Army of the Dead
        { key="pvp", labelKey="PvP", iconSpellID=45524 },          -- Chains of Ice
    }
    local buildContextGap = 4
    local buildContextWidth = math.floor(((guide.contentWidth - 8) - (buildContextGap * (#buildContexts - 1))) / #buildContexts)
    guide.buildContextOrder = { "auto", "world", "delve", "dungeon", "mythicplus", "raid", "pvp" }
    for index, choice in ipairs(buildContexts) do
        local button = CreateFlatTabButton(guide.buildActions, buildContextWidth, 24, T(choice.labelKey))
        button:SetPoint("TOPLEFT", guide.buildActions, "TOPLEFT", 2 + ((index - 1) * (buildContextWidth + buildContextGap)), 0)
        button.buildContext = choice.key
        button.labelKey = choice.labelKey
        button.iconSpellID = choice.iconSpellID
        local font = button.label
        if font and GameFontNormalSmall then font:SetFontObject(GameFontNormalSmall) end
        button:SetScript("OnClick", function(self) addon:SetCodexBuildContext(self.buildContext) end)
        guide.buildContextButtons[choice.key] = button
    end

    guide.buildModeButtons = {}
    local standardMode = CreateFlatTabButton(guide.buildActions, 138, 22, T("Standard"))
    standardMode:SetPoint("TOPLEFT", guide.buildActions, "TOPLEFT", 2, -31)
    standardMode.buildMode = "standard"
    standardMode:SetScript("OnClick", function(self) addon:SetCodexBuildMode(self.buildMode) end)
    guide.buildModeButtons.standard = standardMode

    local sbaMode = CreateFlatTabButton(guide.buildActions, 150, 22, T("SBA-friendly"))
    sbaMode:SetPoint("LEFT", standardMode, "RIGHT", 6, 0)
    sbaMode.buildMode = "sba"
    sbaMode:SetScript("OnClick", function(self) addon:SetCodexBuildMode(self.buildMode) end)
    guide.buildModeButtons.sba = sbaMode

    guide.buildModeHint = guide.buildActions:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    guide.buildModeHint:SetPoint("LEFT", sbaMode, "RIGHT", 10, 0)
    guide.buildModeHint:SetPoint("RIGHT", guide.buildActions, "RIGHT", -2, 0)
    guide.buildModeHint:SetHeight(22)
    guide.buildModeHint:SetJustifyH("LEFT")
    guide.buildModeHint:SetTextColor(0.72, 0.86, 0.93)

    guide.sourceURLBox = CreateFrame("EditBox", nil, guide.buildActions, "InputBoxTemplate")
    guide.sourceURLBox:SetSize(238, 22)
    guide.sourceURLBox:SetPoint("TOPLEFT", guide.buildActions, "TOPLEFT", 2, -68)
    guide.sourceURLBox:SetAutoFocus(false)
    guide.sourceURLBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    guide.selectSourceButton = CreateActionButton(guide.buildActions)
    guide.selectSourceButton:SetSize(152, 22)
    guide.selectSourceButton:SetPoint("LEFT", guide.sourceURLBox, "RIGHT", 8, 0)
    guide.selectSourceButton:SetText(T("Select URL"))
    guide.selectSourceButton:SetScript("OnClick", function()
        guide.sourceURLBox:SetFocus()
        guide.sourceURLBox:HighlightText()
    end)

    guide.openPilotButton = CreateActionButton(guide.buildActions)
    guide.openPilotButton:SetSize(160, 22)
    guide.openPilotButton:SetPoint("LEFT", guide.selectSourceButton, "RIGHT", 8, 0)
    guide.openPilotButton:SetText(T("Open Loadout Pilot"))
    guide.openPilotButton:SetScript("OnClick", function() addon:OpenLoadoutPilot() end)

    guide.gearActions = CreateFrame("Frame", nil, guide)
    guide.gearActions:SetPoint("TOPLEFT", guide, "TOPLEFT", guide.contentLeft, -58)
    guide.gearActions:SetPoint("TOPRIGHT", guide, "TOPRIGHT", -12, -58)
    guide.gearActions:SetHeight(32)
    guide.gearActions:Hide()
    guide.gearViewButtons = {}
    local gearViews = {
        { key = "overview", label = T("Overview") },
        { key = "targets", label = T("Gear") },
        { key = "preparation", label = T("Preparation") },
        { key = "crafting", label = T("Crafting") },
        { key = "sources", label = T("Sources") },
        { key = "trinkets", label = T("Trinkets") },
        { key = "upgrades", label = T("Upgrades") },
    }
    local gearViewGap = 4
    local gearViewWidth = math.floor(((guide.contentWidth - 8) - (gearViewGap * (#gearViews - 1))) / #gearViews)
    guide.gearViewOrder = { "overview", "targets", "preparation", "crafting", "sources", "trinkets", "upgrades" }
    for index, choice in ipairs(gearViews) do
        local button = CreateFlatTabButton(guide.gearActions, gearViewWidth, 24, choice.label)
        button:SetPoint("LEFT", guide.gearActions, "LEFT", 2 + ((index - 1) * (gearViewWidth + gearViewGap)), 0)
        if button.label and GameFontNormalSmall then button.label:SetFontObject(GameFontNormalSmall) end
        button.label:SetWordWrap(true)
        SetFlatTabButtonMultiline(button, 4)
        button.gearView = choice.key
        if choice.key == "overview" then
            button.iconTexture = "Interface\\Icons\\spell_deathknight_classicon"
        elseif choice.key == "targets" then
            button.iconSpellID = 53344 -- Fallen Crusader
        elseif choice.key == "preparation" then
            button.iconSpellID = 53343 -- Razorice
        elseif choice.key == "crafting" then
            button.iconSpellID = 2018 -- Blacksmithing
        elseif choice.key == "sources" then
            button.iconSpellID = 50977 -- Death Gate
        elseif choice.key == "trinkets" then
            button.iconItemID = 270175 -- current Season 2 DK target trinket icon
        elseif choice.key == "upgrades" then
            button.iconSpellID = 47568 -- Empower Rune Weapon
        end
        button:SetScript("OnClick", function(self) addon:SetCodexGearView(self.gearView) end)
        guide.gearViewButtons[choice.key] = button
    end

    -- SETTINGS TAB ---------------------------------------------------------
    settingsPage.scope = settingsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    settingsPage.scope:SetPoint("TOPLEFT", settingsPage, "TOPLEFT", 12, -8)
    settingsPage.scope:SetWidth(500)
    settingsPage.scope:SetJustifyH("LEFT")
    settingsPage.scope:SetText(T("Global addon settings for Death Knight combat HUDs, guidance, and commentary."))
    settingsPage.scope:SetTextColor(0.55, 0.84, 0.95)

    frame.languageButton = CreateActionButton(settingsPage)
    frame.languageButton:SetSize(235, 27)
    frame.languageButton:SetPoint("TOPRIGHT", settingsPage, "TOPRIGHT", -12, -2)
    frame.languageButton:SetScript("OnClick", function() addon:ToggleLanguagePicker() end)
    local languageFont = frame.languageButton.GetFontString and frame.languageButton:GetFontString()
    if languageFont and GameFontNormalSmall then languageFont:SetFontObject(GameFontNormalSmall) end

    frame.hudSection = CreateSection(settingsPage, T("HUDs and layout"), -38, 288)
    local hud = frame.hudSection

    hud.description = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hud.description:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -31)
    hud.description:SetWidth(390)
    hud.description:SetHeight(30)
    hud.description:SetJustifyH("LEFT")
    hud.description:SetJustifyV("TOP")
    hud.description:SetText(T("Choose which combat HUDs are visible. Unlock them only while arranging the interface, then lock them again to prevent accidental dragging."))

    hud.combatOnlyButton = CreateActionButton(hud)
    hud.combatOnlyButton:SetSize(330, 27)
    hud.combatOnlyButton:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -12, -31)
    hud.combatOnlyButton:SetScript("OnClick", function() addon:SetCombatBarsOnlyInCombat(not DB.combatBarsOnlyInCombat) end)
    local combatOnlyFont = hud.combatOnlyButton.GetFontString and hud.combatOnlyButton:GetFontString()
    if combatOnlyFont and GameFontNormalSmall then
        combatOnlyFont:SetFontObject(GameFontNormalSmall)
    end

    local function AddHudRow(y, description)
        local text = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", hud, "TOPLEFT", 213, y)
        text:SetWidth(532)
        text:SetHeight(24)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("MIDDLE")
        text:SetText(description)
        return text
    end

    hud.buildButton = CreateActionButton(hud)
    hud.buildButton:SetSize(190, 24)
    hud.buildButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -68)
    hud.buildButton:SetScript("OnClick", function() addon:SetStatusWidgetEnabled(not DB.statusWidget.enabled) end)
    AddHudRow(-65, T("Shows detected content and DK Ready status beside your specialization icon."))

    hud.coachButton = CreateActionButton(hud)
    hud.coachButton:SetSize(190, 24)
    hud.coachButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -90)
    hud.coachButton:SetScript("OnClick", function() addon:SetCoachEnabled(not DB.coach.enabled) end)
    AddHudRow(-87, T("Shows defensive and recovery recommendations, including health-adaptive priorities."))

    hud.buffButton = CreateActionButton(hud)
    hud.buffButton:SetSize(190, 24)
    hud.buffButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -112)
    hud.buffButton:SetScript("OnClick", function() addon:SetBuffBarEnabled(not DB.buffBar.enabled) end)
    AddHudRow(-109, T("Shows important Death Knight buffs in a compact movable row."))

    hud.externalBuffButton = CreateActionButton(hud)
    hud.externalBuffButton:SetSize(190, 24)
    hud.externalBuffButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -134)
    hud.externalBuffButton:SetScript("OnClick", function() addon:SetExternalBuffBarEnabled(not DB.externalBuffBar.enabled) end)
    AddHudRow(-131, T("Shows helpful effects on you that were applied by other players or NPCs."))

    hud.debuffButton = CreateActionButton(hud)
    hud.debuffButton:SetSize(190, 24)
    hud.debuffButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -156)
    hud.debuffButton:SetScript("OnClick", function() addon:SetDebuffBarEnabled(not DB.debuffBar.enabled) end)
    AddHudRow(-153, T("Shows harmful effects currently affecting your character."))

    hud.abilityButton = CreateActionButton(hud)
    hud.abilityButton:SetSize(190, 24)
    hud.abilityButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -178)
    hud.abilityButton:SetScript("OnClick", function() addon:SetAbilityBarEnabled(not DB.abilityBar.enabled) end)
    AddHudRow(-175, T("Shows important abilities and whether they are ready, cooling down, or temporarily unusable."))

    hud.resourceButton = CreateActionButton(hud)
    hud.resourceButton:SetSize(190, 24)
    hud.resourceButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -200)
    hud.resourceButton:SetScript("OnClick", function() addon:SetResourceHUDEnabled(not DB.resourceHUD.enabled) end)
    hud.resourceDescription = AddHudRow(-197, T("Shows all six Runes plus Runic Power in a compact movable Death Knight resource HUD."))

    hud.interruptButton = CreateActionButton(hud)
    hud.interruptButton:SetSize(190, 24)
    hud.interruptButton:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -222)
    hud.interruptButton:SetScript("OnClick", function() addon:SetInterruptAlertEnabled(not DB.interruptAlert.enabled) end)
    hud.interruptDescription = AddHudRow(-219, T("Shows the Mind Freeze icon only when your current target has a confirmed interruptible cast or channel."))
    hud.interruptDescription:SetWidth(400)

    hud.interruptOptionsButton = CreateActionButton(hud)
    hud.interruptOptionsButton:SetSize(120, 24)
    hud.interruptOptionsButton:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -12, -222)
    hud.interruptOptionsButton:SetText(T("Interrupt options..."))
    hud.interruptOptionsButton:SetScript("OnClick", function()
        if DKM.MentorStudio and DKM.MentorStudio.OpenInterrupt then
            DKM.MentorStudio.OpenInterrupt(mainFrame)
        end
    end)

    -- These are compact state toggles. Keep labels to one line; the explanatory
    -- text lives in the description column to the right.
    for _, button in ipairs({ hud.buildButton, hud.coachButton, hud.buffButton, hud.externalBuffButton, hud.debuffButton, hud.abilityButton, hud.resourceButton, hud.interruptButton, hud.interruptOptionsButton }) do
        local fontString = button.GetFontString and button:GetFontString()
        if fontString then
            if GameFontNormalSmall then fontString:SetFontObject(GameFontNormalSmall) end
            if fontString.SetWordWrap then fontString:SetWordWrap(false) end
        end
    end

    -- Keep the layout controls on one clean row even with localized labels.
    hud.lockButton = CreateActionButton(hud)
    hud.lockButton:SetSize(137, 27)
    hud.lockButton:SetPoint("BOTTOMLEFT", hud, "BOTTOMLEFT", 12, 12)
    hud.lockButton:SetScript("OnClick", function() addon:ToggleHUDLock() end)

    hud.previewButton = CreateActionButton(hud)
    hud.previewButton:SetSize(142, 27)
    hud.previewButton:SetPoint("LEFT", hud.lockButton, "RIGHT", 7, 0)
    hud.previewButton:SetScript("OnClick", function() addon:ToggleHUDPreview() end)

    hud.barLayoutButton = CreateActionButton(hud)
    hud.barLayoutButton:SetSize(149, 27)
    hud.barLayoutButton:SetPoint("LEFT", hud.previewButton, "RIGHT", 7, 0)
    hud.barLayoutButton:SetText(T("HUD appearance..."))
    hud.barLayoutButton:SetScript("OnClick", function() addon:ToggleBarLayoutFrame() end)

    hud.presetButton = CreateActionButton(hud)
    hud.presetButton:SetSize(143, 27)
    hud.presetButton:SetPoint("LEFT", hud.barLayoutButton, "RIGHT", 7, 0)
    hud.presetButton:SetText(T("Layout presets..."))
    hud.presetButton:SetScript("OnClick", function() addon:ToggleLayoutPresetFrame() end)

    hud.resetButton = CreateActionButton(hud)
    hud.resetButton:SetSize(145, 27)
    hud.resetButton:SetPoint("LEFT", hud.presetButton, "RIGHT", 7, 0)
    hud.resetButton:SetText(T("Reset HUDs"))
    hud.resetButton:SetScript("OnClick", function() addon:ResetHUDPositions() end)

    for _, button in ipairs({ hud.lockButton, hud.previewButton, hud.barLayoutButton, hud.presetButton, hud.resetButton }) do
        local fontString = button.GetFontString and button:GetFontString()
        if fontString and GameFontNormalSmall then
            fontString:SetFontObject(GameFontNormalSmall)
        end
    end

    frame.loadoutPilotSection = CreateSection(settingsPage, T("Loadout automation"), -331, 82)
    local pilot = frame.loadoutPilotSection
    pilot.description = pilot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    pilot.description:SetPoint("TOPLEFT", pilot, "TOPLEFT", 12, -30)
    pilot.description:SetWidth(520)
    pilot.description:SetHeight(42)
    pilot.description:SetJustifyH("LEFT")
    pilot.description:SetJustifyV("TOP")

    pilot.openButton = CreateActionButton(pilot)
    pilot.openButton:SetSize(190, 28)
    pilot.openButton:SetPoint("TOPRIGHT", pilot, "TOPRIGHT", -12, -31)
    pilot.openButton:SetScript("OnClick", function() addon:OpenLoadoutPilot() end)

    frame.voiceSection = CreateSection(settingsPage, T("Lich King commentary"), -418, 156)
    local voice = frame.voiceSection

    voice.status = voice:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    voice.status:SetPoint("TOPLEFT", voice, "TOPLEFT", 12, -31)
    voice.status:SetWidth(525)
    voice.status:SetHeight(43)
    voice.status:SetJustifyH("LEFT")
    voice.status:SetJustifyV("TOP")

    voice.toggleButton = CreateActionButton(voice)
    voice.toggleButton:SetSize(190, 27)
    voice.toggleButton:SetPoint("TOPRIGHT", voice, "TOPRIGHT", -12, -28)
    voice.toggleButton:SetScript("OnClick", function() addon:ToggleVoice() end)

    voice.situationalButton = CreateActionButton(voice)
    voice.situationalButton:SetSize(150, 27)
    voice.situationalButton:SetPoint("TOPLEFT", voice, "TOPLEFT", 12, -76)
    voice.situationalButton:SetScript("OnClick", function()
        DB.voice.situational = not DB.voice.situational
        addon:UpdateVoiceSection()
        Print(T(DB.voice.situational and "Situational Lich King comments enabled." or "Situational Lich King comments disabled."))
    end)

    voice.mapButton = CreateActionButton(voice)
    voice.mapButton:SetSize(150, 27)
    voice.mapButton:SetPoint("LEFT", voice.situationalButton, "RIGHT", 8, 0)
    voice.mapButton:SetText(T("Voice mapping..."))
    voice.mapButton:SetScript("OnClick", function() addon:ToggleVoiceConfigFrame() end)

    voice.previewButton = CreateActionButton(voice)
    voice.previewButton:SetSize(140, 27)
    voice.previewButton:SetPoint("LEFT", voice.mapButton, "RIGHT", 8, 0)
    voice.previewButton:SetText(T("Preview voice"))
    voice.previewButton:SetScript("OnClick", function() addon:PreviewVoice() end)

    voice.frequencyButton = CreateActionButton(voice)
    voice.frequencyButton:SetSize(170, 27)
    voice.frequencyButton:SetPoint("LEFT", voice.previewButton, "RIGHT", 8, 0)
    voice.frequencyButton:SetScript("OnClick", function() addon:CycleVoiceFrequency() end)

    voice.portraitButton = CreateActionButton(voice)
    voice.portraitButton:SetSize(145, 27)
    voice.portraitButton:SetPoint("TOPLEFT", voice, "TOPLEFT", 12, -111)
    voice.portraitButton:SetScript("OnClick", function() addon:SetLichKingPortraitEnabled(not (DB.voice.portrait and DB.voice.portrait.enabled)) end)

    voice.portraitLockButton = CreateActionButton(voice)
    voice.portraitLockButton:SetSize(155, 27)
    voice.portraitLockButton:SetPoint("LEFT", voice.portraitButton, "RIGHT", 8, 0)
    voice.portraitLockButton:SetScript("OnClick", function() addon:ToggleLichKingPortraitLock() end)

    voice.portraitScaleButton = CreateActionButton(voice)
    voice.portraitScaleButton:SetSize(165, 27)
    voice.portraitScaleButton:SetPoint("LEFT", voice.portraitLockButton, "RIGHT", 8, 0)
    voice.portraitScaleButton:SetScript("OnClick", function() addon:CycleLichKingPortraitScale() end)

    voice.portraitCharacterButton = CreateActionButton(voice)
    voice.portraitCharacterButton:SetSize(220, 27)
    voice.portraitCharacterButton:SetPoint("LEFT", voice.portraitScaleButton, "RIGHT", 8, 0)
    voice.portraitCharacterButton:SetScript("OnClick", function() addon:CycleLichKingPortraitCharacter() end)
    voice.portraitCharacterButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(T("Portrait character"), 0.66, 0.90, 1.00)
        GameTooltip:AddLine(T("Choose whether the animated commentary portrait shows Arthas or Bolvar. This setting changes the visual portrait only; commentary audio continues to use the existing Lich King voice resources."), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    voice.portraitCharacterButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 14)
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
        self:UpdateLoadoutPilotIntegration()
    end
end

local function CreateCoachFrame()
    local frame = CreateFrame("Frame", "DKMentorCoachFrame", UIParent, "BackdropTemplate")
    frame:SetSize(330, 96)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    ApplyBackdrop(frame, 0.78)

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
        card:SetSize(102, 64)
        card:SetPoint("TOPLEFT", frame, "TOPLEFT", 8 + ((index - 1) * 157), -34)
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 6,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        card:SetBackdropColor(0.018, 0.055, 0.075, 0.88)
        card:SetBackdropBorderColor(0.12, 0.40, 0.54, 0.72)
        card:EnableMouse(true)
        card.owner = frame
        card:RegisterForDrag("LeftButton")
        card:SetScript("OnDragStart", StartCoachDrag)
        card:SetScript("OnDragStop", StopCoachDrag)

        card.icon = card:CreateTexture(nil, "ARTWORK")
        card.icon:SetSize(24, 24)
        card.icon:SetPoint("TOPLEFT", card, "TOPLEFT", 5, -5)
        card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        card.action = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.action:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 4, 0)
        card.action:SetWidth(65)
        card.action:SetJustifyH("LEFT")
        card.action:SetTextColor(0.46, 0.86, 1)

        card.spell = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.spell:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 4, -14)
        card.spell:SetWidth(65)
        card.spell:SetHeight(22)
        card.spell:SetJustifyH("LEFT")
        card.spell:SetJustifyV("TOP")

        card.when = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.when:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 5, 5)
        card.when:SetWidth(92)
        card.when:SetHeight(18)
        card.when:SetJustifyH("LEFT")
        card.when:SetJustifyV("BOTTOM")
        if GameFontDisableSmall then card.when:SetFontObject(GameFontDisableSmall) end
        card.when:SetTextColor(0.78, 0.86, 0.90)

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
    -- 3.0 Alert Studio consumes the existing cards instead of creating a
    -- competing combat HUD. The table remains owned by Core; modules only style it.
    frame.cards = coachCards

    frame:Hide()
    RestoreFramePosition(frame, "coach")
    if addon.ApplyMentorCoachLayout then addon:ApplyMentorCoachLayout() end
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
    frame:SetSize(150, 32)
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
        if mouseButton == "RightButton" then addon:ToggleMainFrame() end
    end)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(24, 24)
    frame.icon:SetPoint("LEFT", frame, "LEFT", 4, 0)
    frame.icon:SetTexture(QUESTION_MARK_ICON)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.specButton = CreateFrame("Button", nil, frame)
    frame.specButton:SetAllPoints(frame.icon)
    frame.specButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame.specButton:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then addon:ToggleMainFrame() else addon:ToggleSpecializationPicker() end
    end)
    frame.specButton:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(T("Change specialization"))
            GameTooltip:AddLine(T("Click to choose Blood, Frost, or Unholy. Specializations are never changed automatically."), 1, 1, 1, true)
            GameTooltip:AddLine(T("Right-click: open or close DK Mentor"), 0.72, 0.86, 1.0, true)
            GameTooltip:Show()
        end
    end)
    frame.specButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.title:SetPoint("LEFT", frame.icon, "RIGHT", 6, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetTextColor(0.48, 0.87, 1)
    frame.title:SetWordWrap(false)

    frame.ready = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.ready:SetPoint("LEFT", frame.title, "RIGHT", 8, 0)
    frame.ready:SetJustifyH("LEFT")
    frame.ready:SetWordWrap(false)

    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(T("DK Mentor Status"))
        local status = addon:GetReadyCheckStatus()
        local context = addon:DetectActualContext()
        local contextLabel = addon:GetRuntimeContextLabel(context)
        local currentSpecID, currentSpecName = addon:GetSpecInfo()
        GameTooltip:AddLine(T("Current specialization: %s", tostring(currentSpecName or currentSpecID)), 1, 1, 1)
        GameTooltip:AddLine(T("Content: %s", tostring(contextLabel)), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(T("DK Ready Check"), 0.45, 0.85, 1)
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
    frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    RestoreFramePosition(frame, "statusWidget")
    frame:Hide()
    return frame
end

local function LayoutStatusWidget()
    if not statusWidget then return end
    -- Keep the HUD as compact as Loadout Pilot: text-sized columns, small gaps,
    -- and only a few pixels of trailing padding. Longer content names can still grow it.
    local titleWidth = math.max(32, math.ceil((statusWidget.title.GetStringWidth and statusWidget.title:GetStringWidth()) or 0) + 2)
    local readyWidth = math.max(58, math.ceil((statusWidget.ready.GetStringWidth and statusWidget.ready:GetStringWidth()) or 0) + 2)
    local desiredWidth = math.max(140, math.min(360, 4 + 24 + 6 + titleWidth + 8 + readyWidth + 6))
    statusWidget:SetSize(desiredWidth, 32)
    statusWidget.title:SetWidth(titleWidth)
    statusWidget.ready:SetWidth(readyWidth)
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

    -- Midnight 12.1 intentionally makes AuraButton presence/visibility secret while
    -- auras are protected. Addons must not query IsShown/IsVisible or install
    -- OnShow/OnHide hooks on AuraButtons. Blizzard owns the active icon visibility.
    -- Unlocking HUDs must therefore only enable dragging; it must NOT resurrect the
    -- large decorative background/title for an empty aura bar. The explicit Preview
    -- mode is the one place where we intentionally show the chrome/placeholder so an
    -- empty bar can be located and positioned. In normal play, locked OR unlocked,
    -- only Blizzard-managed active aura icons remain visible.
    local showChrome = addon.hudPreviewMode == true

    if frame.label then frame.label:SetShown(showChrome) end
    if frame.dragHint then
        frame.dragHint:SetShown(showChrome)
        if showChrome then frame.dragHint:SetText(T("Drag to move")) end
    end

    -- Keep the transparent parent draggable while HUDs are unlocked. Users who need
    -- to locate an entirely empty bar can enable Preview HUDs explicitly.
    frame:EnableMouse(editing)
    if showChrome then
        frame:SetBackdropColor(0.02, 0.04, 0.06, 0.82)
        frame:SetBackdropBorderColor(0.16, 0.47, 0.62, 0.85)
    else
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

addon.MANAGED_AURA_ICON_SIZE = 34
addon.MANAGED_AURA_SPACING = 4
addon.MANAGED_AURAS_PER_LINE = 5
addon.MANAGED_AURA_MAX_FRAMES = 30

local function GetManagedAuraLineSize(perLine)
    perLine = math.max(1, math.floor(tonumber(perLine) or addon.MANAGED_AURAS_PER_LINE))
    return (perLine * (addon.MANAGED_AURA_ICON_SIZE + addon.MANAGED_AURA_SPACING)) + 1
end

local function ConfigureManagedAuraFlow(container, perLine)
    if not container then return end
    perLine = math.max(1, math.floor(tonumber(perLine) or addon.MANAGED_AURAS_PER_LINE))
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
    local frame = CreateTrackingBar(frameName, dbKey, title, slotStore, addon.MANAGED_AURA_MAX_FRAMES, 0.25)
    local perLine = GetConfiguredBarColumns(dbKey, addon.MANAGED_AURAS_PER_LINE, 10)
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
    container:SetSize(lineSize, addon.MANAGED_AURA_ICON_SIZE)
    container:Show()
    ConfigureManagedAuraFlow(container, perLine)

    local options = {
        maxFrameCount = addon.MANAGED_AURA_MAX_FRAMES,
        initializeFrame = function(button)
            -- Styling is the only addon work performed on the AuraButton. Blizzard
            -- may apply forbidden/secret aspects immediately after this callback,
            -- so do not retain it for visibility queries or attach scripts to it.
            StyleManagedAuraButton(button, harmful)
        end,
        candidateFilters = candidateFilters or {},
        layout = {
            elementWidth = addon.MANAGED_AURA_ICON_SIZE,
            elementHeight = addon.MANAGED_AURA_ICON_SIZE,
            elementSpacing = addon.MANAGED_AURA_SPACING,
            lineSpacing = addon.MANAGED_AURA_SPACING,
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
    local columns = GetConfiguredBarColumns(frame.dbKey, addon.MANAGED_AURAS_PER_LINE, 10)
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

    local columns = GetConfiguredBarColumns(frame.dbKey, addon.MANAGED_AURAS_PER_LINE, 10)
    local lineSize = GetManagedAuraLineSize(columns)
    frame.slotsPerRow = columns
    frame:SetSize(math.max(92, 14 + (columns * 38)), 56)
    frame.managedAuraContainer:SetSize(lineSize, addon.MANAGED_AURA_ICON_SIZE)
    ConfigureManagedAuraFlow(frame.managedAuraContainer, columns)
    if frame.managedAuraContainer.SetAuraGroupLayout then
        pcall(frame.managedAuraContainer.SetAuraGroupLayout, frame.managedAuraContainer, frame.managedAuraGroupKey, {
            elementWidth = addon.MANAGED_AURA_ICON_SIZE,
            elementHeight = addon.MANAGED_AURA_ICON_SIZE,
            elementSpacing = addon.MANAGED_AURA_SPACING,
            lineSpacing = addon.MANAGED_AURA_SPACING,
            maximumLineSize = lineSize,
        })
    end
    frame.managedAuraAppliedColumns = columns
    frame.managedAuraLayoutPending = false
end

local function RestoreManagedAuraRuntime(frame, slotStore)
    if not frame or not frame.managedAuraContainer then return end
    HideTrackingSlots(slotStore)
    local configuredColumns = GetConfiguredBarColumns(frame.dbKey, addon.MANAGED_AURAS_PER_LINE, 10)
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

addon.RESOURCE_RUNE_LAYOUTS = {
    compact = { runeWidth = 40, gap = 3 },
    normal = { runeWidth = 47, gap = 4 },
    wide = { runeWidth = 54, gap = 6 },
}

local function NormalizeResourceRuneSpacing(value)
    value = tostring(value or "normal")
    if not addon.RESOURCE_RUNE_LAYOUTS[value] then return "normal" end
    return value
end

local function NormalizeResourceHUDStyle(value)
    value = tostring(value or "classic")
    if value ~= "classic" and value ~= "arcs" then
        return "classic"
    end
    return value
end

local function NormalizeResourceVisibilityMode(value)
    value = string.lower(tostring(value or "combat"))
    if value == "always" or value == "fade" or value == "combat" then return value end
    return "combat"
end

local function LayoutResourceHUDComponents(frame, showRunes, showRunicPower)
    if not frame then return end

    local config = DB and DB.resourceHUD or DEFAULTS.resourceHUD
    local spacingKey = NormalizeResourceRuneSpacing(config and config.runeSpacing)
    local spacing = addon.RESOURCE_RUNE_LAYOUTS[spacingKey]
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

addon.DK_ARC_FILL_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcFill"
addon.DK_ARC_BG_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcBG"
addon.DK_ARC_GLOW_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcGlow"
addon.DK_ARC_FILL_RIGHT_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcFillRight"
addon.DK_ARC_BG_RIGHT_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcBGRight"
addon.DK_ARC_GLOW_RIGHT_TEXTURE = "Interface\\AddOns\\DKMentor\\Media\\DKArcGlowRight"
addon.DK_RUNE_TEXTURE = "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-SingleRune"

local function NormalizeResourceArcSpacing(value)
    value = tonumber(value) or 105
    value = Clamp(value, 65, 165)
    return math.floor((value / 5) + 0.5) * 5
end

local function CreateDKArcBar(parent, side)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(76, 246)

    local rightSide = side == "RIGHT"
    local fillTexture = rightSide and addon.DK_ARC_FILL_RIGHT_TEXTURE or addon.DK_ARC_FILL_TEXTURE
    local bgTexture = rightSide and addon.DK_ARC_BG_RIGHT_TEXTURE or addon.DK_ARC_BG_TEXTURE
    local glowTexture = rightSide and addon.DK_ARC_GLOW_RIGHT_TEXTURE or addon.DK_ARC_GLOW_TEXTURE

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

    -- The arc HUD occupies a deliberately large transparent rectangle around the
    -- character. Never let that transparent parent receive mouse input: otherwise
    -- units standing between the arcs cannot be clicked in the 3D world. Movement
    -- is handled by a small edit-only drag handle instead.
    frame:EnableMouse(false)

    frame.dragHandle = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.dragHandle.owner = frame
    frame.dragHandle:SetSize(118, 20)
    frame.dragHandle:SetPoint("TOP", frame, "TOP", 0, -4)
    frame.dragHandle:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.dragHandle:SetBackdropColor(0.02, 0.05, 0.07, 0.78)
    frame.dragHandle:SetBackdropBorderColor(0.18, 0.58, 0.76, 0.88)
    frame.dragHandle:EnableMouse(false)
    frame.dragHandle:RegisterForDrag("LeftButton")
    frame.dragHandle:SetScript("OnDragStart", function(self)
        local owner = self.owner
        if owner and addon:CanMoveHUDs() then owner:StartMoving() end
    end)
    frame.dragHandle:SetScript("OnDragStop", function(self)
        local owner = self.owner
        if not owner then return end
        owner:StopMovingOrSizing()
        if DB and DB.hudLocked == false then SaveResourceArcPosition(owner) end
    end)
    frame.dragHandle.text = frame.dragHandle:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.dragHandle.text:SetPoint("CENTER", frame.dragHandle, "CENTER", 0, 0)
    frame.dragHandle.text:SetText(T("Drag to move"))
    frame.dragHandle:Hide()

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
        rune:SetStatusBarTexture(addon.DK_RUNE_TEXTURE)
        rune:SetStatusBarColor(readyColor[1], readyColor[2], readyColor[3], readyColor[4])
        if rune.SetReverseFill then rune:SetReverseFill(false) end

        rune.bg = rune:CreateTexture(nil, "BACKGROUND")
        rune.bg:SetTexture(addon.DK_RUNE_TEXTURE)
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
    DB.resourceHUD.visibilityMode = DEFAULTS.resourceHUD.visibilityMode
    DB.resourceHUD.fadeAlpha = DEFAULTS.resourceHUD.fadeAlpha
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

local function BuildOrderedRuneDisplayStates(now)
    local states = {}
    if not GetRuneCooldown then return states end

    for runeID = 1, 6 do
        local ok, startTime, duration, rawReady = pcall(GetRuneCooldown, runeID)
        local ready = ok and GetAccessibleBoolean(rawReady) or nil
        local progress = 0
        if ready == true then
            progress = 1
        elseif ok and IsAccessibleNumber(startTime) and IsAccessibleNumber(duration) and duration > 0 then
            progress = Clamp((now - startTime) / duration, 0, 1)
        end
        states[#states + 1] = {
            runeID = runeID,
            ready = ready == true,
            progress = progress,
            known = ok == true,
        }
    end

    -- Blizzard presents DK Runes as an ordered pool rather than exposing the
    -- underlying Rune IDs visually: available Runes stay on the left, spending
    -- consumes from the right, and the next Rune to finish recharging appears
    -- first in the depleted group. Sorting by readiness/progress reproduces that
    -- stable visual behavior without changing or predicting the real game state.
    table.sort(states, function(a, b)
        if a.ready ~= b.ready then return a.ready end
        if a.progress ~= b.progress then return a.progress > b.progress end
        return a.runeID < b.runeID
    end)
    return states
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
    local states = BuildOrderedRuneDisplayStates(GetNow())
    for displayIndex, rune in ipairs(activeFrame.runes or {}) do
        local state = states[displayIndex]
        local progress = state and state.progress or 0
        rune:SetMinMaxValues(0, 1)
        rune:SetValue(progress)
        if state and state.ready then
            rune:SetStatusBarColor(readyColor[1], readyColor[2], readyColor[3], readyColor[4])
        elseif progress > 0 then
            rune:SetStatusBarColor(chargingColor[1], chargingColor[2], chargingColor[3], chargingColor[4])
        else
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

    -- PLAYER_REGEN_DISABLED calls UpdateResourceHUD directly. Re-sync the arc
    -- edit handle here so an unlocked HUD becomes click-through the instant
    -- combat starts instead of swallowing world clicks until the next settings refresh.
    if resourceArcFrame then
        local canMove = self:CanMoveHUDs()
        resourceArcFrame:EnableMouse(false)
        if resourceArcFrame.dragHandle then
            resourceArcFrame.dragHandle:EnableMouse(canMove)
            resourceArcFrame.dragHandle:SetShown(canMove)
        end
    end
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
    local configuredOpacity = NormalizeCombatBarOpacity(DB.resourceHUD.opacity)
    local visibilityMode = NormalizeResourceVisibilityMode(DB.resourceHUD.visibilityMode)
    local displayOpacity = configuredOpacity
    if not preview and visibilityMode == "fade" and not self:IsPlayerInCombat() then
        displayOpacity = configuredOpacity * Clamp(tonumber(DB.resourceHUD.fadeAlpha) or 0.20, 0.05, 0.80)
    end
    if resourceFrame then resourceFrame:SetAlpha(displayOpacity) end
    if resourceArcFrame then resourceArcFrame:SetAlpha(displayOpacity) end
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
    -- Normal gameplay is click-through. Mouse input is enabled only while the
    -- HUD edit session is explicitly unlocked.
    frame:EnableMouse(false)
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

        row.scaleMinus = CreateActionButton(row)
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

        row.scalePlus = CreateActionButton(row)
        row.scalePlus:SetSize(30, 26)
        row.scalePlus:SetPoint("LEFT", row.scaleValue, "RIGHT", 5, 0)
        row.scalePlus:SetText("+")
        row.scalePlus:SetScript("OnClick", function()
            addon:SetCombatBarScale(row.dbKey, (DB[row.dbKey].scale or 1) + 0.1)
        end)

        row.opacityMinus = CreateActionButton(row)
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

        row.opacityPlus = CreateActionButton(row)
        row.opacityPlus:SetSize(30, 26)
        row.opacityPlus:SetPoint("LEFT", row.opacityValue, "RIGHT", 5, 0)
        row.opacityPlus:SetText("+")
        row.opacityPlus:SetScript("OnClick", function()
            addon:SetCombatBarOpacity(row.dbKey, (DB[row.dbKey].opacity or 1) + 0.1)
        end)

        row.columnsMinus = CreateActionButton(row)
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

        row.columnsPlus = CreateActionButton(row)
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
            row.resourceModeButton = CreateActionButton(row)
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

    frame.resourceTextButton = CreateActionButton(frame)
    frame.resourceTextButton:SetSize(165, 28)
    frame.resourceTextButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -374)
    frame.resourceTextButton:SetScript("OnClick", function()
        addon:SetResourceHUDPowerTextEnabled(not DB.resourceHUD.showPowerText)
    end)

    frame.resourceStyleButton = CreateActionButton(frame)
    frame.resourceStyleButton:SetSize(165, 28)
    frame.resourceStyleButton:SetPoint("LEFT", frame.resourceTextButton, "RIGHT", 8, 0)
    frame.resourceStyleButton:SetScript("OnClick", function() addon:CycleResourceHUDStyle() end)

    frame.resourceSpacingButton = CreateActionButton(frame)
    frame.resourceSpacingButton:SetSize(190, 28)
    frame.resourceSpacingButton:SetPoint("LEFT", frame.resourceStyleButton, "RIGHT", 8, 0)
    frame.resourceSpacingButton:SetScript("OnClick", function() addon:CycleResourceRuneSpacing() end)

    frame.resourceResetButton = CreateActionButton(frame)
    frame.resourceResetButton:SetSize(190, 28)
    frame.resourceResetButton:SetPoint("LEFT", frame.resourceSpacingButton, "RIGHT", 8, 0)
    frame.resourceResetButton:SetText(T("Restore DK Resources"))
    frame.resourceResetButton:SetScript("OnClick", function() addon:ResetResourceHUDLayout() end)

    frame.resourceArcSpacingLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.resourceArcSpacingLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -414)
    frame.resourceArcSpacingLabel:SetWidth(150)
    frame.resourceArcSpacingLabel:SetJustifyH("LEFT")
    frame.resourceArcSpacingLabel:SetText(T("Arc opening"))

    frame.resourceArcSpacingMinus = CreateActionButton(frame)
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

    frame.resourceArcSpacingPlus = CreateActionButton(frame)
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

    frame.resetButton = CreateActionButton(frame)
    frame.resetButton:SetSize(245, 28)
    frame.resetButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 16)
    frame.resetButton:SetText(T("Restore HUD appearance"))
    frame.resetButton:SetScript("OnClick", function() addon:ResetCombatBarLayout() end)

    frame.previewButton = CreateActionButton(frame)
    frame.previewButton:SetSize(245, 28)
    frame.previewButton:SetPoint("LEFT", frame.resetButton, "RIGHT", 10, 0)
    frame.previewButton:SetScript("OnClick", function() addon:ToggleHUDPreview() end)

    frame.doneButton = CreateActionButton(frame)
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
            StyleActionButton(row.scaleMinus); StyleActionButton(row.scalePlus)

            local opacity = NormalizeCombatBarOpacity(config.opacity)
            row.opacityValue:SetText(string.format("%d%%", math.floor((opacity * 100) + 0.5)))
            row.opacityMinus:SetEnabled(opacity > 0.3)
            row.opacityPlus:SetEnabled(opacity < 1)
            StyleActionButton(row.opacityMinus); StyleActionButton(row.opacityPlus)

            if limits.resourceMode then
                if row.resourceModeButton then row.resourceModeButton:SetText(self:GetResourceHUDModeLabel()) end
            else
                local columns = Clamp(math.floor((tonumber(config.iconsPerRow) or limits.defaultColumns) + 0.5), limits.minColumns, limits.maxColumns)
                row.columnsValue:SetText(tostring(columns))
                row.columnsMinus:SetEnabled(columns > limits.minColumns)
                row.columnsPlus:SetEnabled(columns < limits.maxColumns)
                StyleActionButton(row.columnsMinus); StyleActionButton(row.columnsPlus)
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
        StyleActionButton(barLayoutFrame.resourceArcSpacingMinus); StyleActionButton(barLayoutFrame.resourceArcSpacingPlus)
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

        row.prev = CreateActionButton(row)
        row.prev:SetSize(28, 22)
        row.prev:SetPoint("LEFT", row, "LEFT", 184, 0)
        row.prev:SetText("<")
        row.prev:SetScript("OnClick", function() addon:CycleVoiceSelection(categoryKey, -1) end)

        row.selection = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.selection:SetPoint("LEFT", row.prev, "RIGHT", 5, 0)
        row.selection:SetWidth(105)
        row.selection:SetJustifyH("CENTER")

        row.next = CreateActionButton(row)
        row.next:SetSize(28, 22)
        row.next:SetPoint("LEFT", row.selection, "RIGHT", 5, 0)
        row.next:SetText(">")
        row.next:SetScript("OnClick", function() addon:CycleVoiceSelection(categoryKey, 1) end)

        row.preview = CreateActionButton(row)
        row.preview:SetSize(76, 22)
        row.preview:SetPoint("LEFT", row.next, "RIGHT", 9, 0)
        row.preview:SetText(T("Preview"))
        row.preview:SetScript("OnClick", function() addon:PreviewVoiceCategory(categoryKey) end)

        row.random = CreateActionButton(row)
        row.random:SetSize(72, 22)
        row.random:SetPoint("LEFT", row.preview, "RIGHT", 7, 0)
        row.random:SetText(T("Random"))
        row.random:SetScript("OnClick", function() addon:SetVoiceSelection(categoryKey, 0) end)

        voiceRows[categoryKey] = row
    end

    frame.resetButton = CreateActionButton(frame)
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
end

function addon:UpdateHeader()
    if not mainFrame then
        return
    end

    local specID, specName, specIcon = self:GetSpecInfo()
    local context = self:DetectActualContext()
    local contextName = self:GetRuntimeContextLabel(context)

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
    -- HUD movement is an explicit, session-only edit mode. A stale SavedVariable
    -- from an older session must never leave drag handles visible after reload.
    if not DB or DB.hudLocked ~= false or self.hudEditSessionActive ~= true then
        return false
    end

    if InCombatLockdown then
        local ok, rawValue = pcall(InCombatLockdown)
        local lockdown = GetAccessibleBooleanFromCall(ok, rawValue)
        -- Unknown/secret combat state is treated as locked for safety.
        if lockdown ~= false then
            return false
        end
    end

    return true
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

local RESOURCE_VISIBILITY_ORDER = { "combat", "fade", "always" }

function addon:GetResourceVisibilityModeLabel()
    if not DB or not DB.resourceHUD then return T("Combat Only") end
    local mode = NormalizeResourceVisibilityMode(DB.resourceHUD.visibilityMode)
    if mode == "always" then return T("Always") end
    if mode == "fade" then return T("Fade out of combat") end
    return T("Combat Only")
end

function addon:SetResourceVisibilityMode(mode)
    if not DB or not DB.resourceHUD then return end
    DB.resourceHUD.visibilityMode = NormalizeResourceVisibilityMode(mode)
    self:UpdateResourceHUD()
    self:UpdateHUDSettings()
end

function addon:CycleResourceVisibilityMode()
    if not DB or not DB.resourceHUD then return end
    local current = NormalizeResourceVisibilityMode(DB.resourceHUD.visibilityMode)
    local nextMode = "combat"
    for index, value in ipairs(RESOURCE_VISIBILITY_ORDER) do
        if value == current then nextMode = RESOURCE_VISIBILITY_ORDER[(index % #RESOURCE_VISIBILITY_ORDER) + 1] break end
    end
    self:SetResourceVisibilityMode(nextMode)
    Print(T("DK resource visibility: %s", self:GetResourceVisibilityModeLabel()))
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
    if DB and DB.resourceHUD and config == DB.resourceHUD then
        local mode = NormalizeResourceVisibilityMode(config.visibilityMode)
        if mode == "combat" then return self:IsPlayerInCombat() end
        return true
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
    local canMove = self:CanMoveHUDs()
    local text = canMove and T("Drag to move") or ""
    if coachFrame and coachFrame.dragHint then coachFrame.dragHint:SetText(canMove and T("Move") or "") end
    if buffFrame and buffFrame.dragHint then buffFrame.dragHint:SetText(text) end
    if externalBuffFrame and externalBuffFrame.dragHint then externalBuffFrame.dragHint:SetText(text) end
    if debuffFrame and debuffFrame.dragHint then debuffFrame.dragHint:SetText(text) end
    if abilityFrame and abilityFrame.dragHint then abilityFrame.dragHint:SetText(text) end
    if resourceFrame and resourceFrame.dragHint then resourceFrame.dragHint:SetText(text) end
    if resourceArcFrame and resourceArcFrame.dragHint then resourceArcFrame.dragHint:SetText("") end
    if resourceArcFrame then
        -- The full 360x300 arc parent is permanently click-through. Only this
        -- small handle accepts the mouse while HUDs are unlocked out of combat.
        resourceArcFrame:EnableMouse(false)
        if resourceArcFrame.dragHandle then
            resourceArcFrame.dragHandle:EnableMouse(canMove)
            resourceArcFrame.dragHandle:SetShown(canMove)
        end
    end
    if interruptFrame then
        -- The interrupt icon must never steal world clicks during gameplay,
        -- including when Secret-driven alpha makes it visually transparent.
        interruptFrame:EnableMouse(canMove)
    end
    UpdateManagedAuraBarChrome(buffFrame)
    UpdateManagedAuraBarChrome(externalBuffFrame)
    UpdateManagedAuraBarChrome(debuffFrame)
end

function addon:SetHUDsLocked(locked)
    if not DB then return end
    DB.hudLocked = locked == true
    self.hudEditSessionActive = not DB.hudLocked
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
    if not DB.statusWidget.enabled and specializationPickerFrame then specializationPickerFrame:Hide() end
    self:RefreshStatusWidgetVisibility()
    self:UpdateHUDSettings()
    Print(T(DB.statusWidget.enabled and "DK status HUD enabled." or "DK status HUD disabled."))
end

function addon:UpdateStatusWidget()
    if not statusWidget or not DB or not self.active then return end
    local _, _, specIcon = self:GetSpecInfo()
    local context = self:DetectActualContext()
    local contextName = self:GetRuntimeContextLabel(context)
    statusWidget.icon:SetTexture(specIcon or QUESTION_MARK_ICON)
    statusWidget.title:SetText(tostring(contextName))

    local readyStatus = self:GetReadyCheckStatus()
    local color = readyStatus.ready and "|cff66ff99" or (readyStatus.hardIssue and "|cffff7777" or "|cffffcc55")
    statusWidget.ready:SetText(color .. tostring(readyStatus.summary or T("Ready Check unavailable")) .. "|r")
    LayoutStatusWidget()
end

function addon:RefreshStatusWidgetVisibility()
    if not statusWidget or not DB or not self.active then
        return
    end
    if self.combatEventState == true or self:IsPlayerInCombat() then
        statusWidget:Hide()
        if specializationPickerFrame then specializationPickerFrame:Hide() end
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
            StyleActionButton(row.preview)
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
    StyleActionButton(section.previewButton)
    section.situationalButton:SetText(T(DB.voice.situational and "Situations: ON" or "Situations: OFF"))
    if section.mapButton then section.mapButton:SetEnabled(PlaySoundFile ~= nil); StyleActionButton(section.mapButton) end
    if section.portraitButton then
        section.portraitButton:SetText(T(DB.voice.portrait and DB.voice.portrait.enabled and "Portrait: ON" or "Portrait: OFF"))
        SetActionButtonSelected(section.portraitButton, DB.voice.portrait and DB.voice.portrait.enabled == true)
    end
    if section.portraitLockButton then
        section.portraitLockButton:SetText(T(DB.voice.portrait and DB.voice.portrait.locked == false and "Portrait: UNLOCKED" or "Portrait: LOCKED"))
        SetActionButtonSelected(section.portraitLockButton, DB.voice.portrait and DB.voice.portrait.locked == false)
    end
    if section.portraitScaleButton then
        section.portraitScaleButton:SetText(T("Portrait scale: %d%%", math.floor(((DB.voice.portrait and DB.voice.portrait.scale) or 1) * 100 + 0.5)))
    end
    if section.portraitCharacterButton then
        local character = self:GetLichKingPortraitCharacter()
        section.portraitCharacterButton:SetText(T("Portrait character: %s", character.label))
    end
    self:UpdateVoiceConfigFrame()
end

function addon:UpdateSurvivalTips()
    if not mainFrame then
        return
    end

    local specID, specName = self:GetSpecInfo()
    local context = select(1, self:DetectContext())
    local contextName = self:GetRuntimeContextLabel(context)
    local specTips = Data.tips and Data.tips[specID]
    local generalTips = Data.tips and Data.tips.general
    local tips = (specTips and (specTips[context] or specTips.world)) or (generalTips and (generalTips[context] or generalTips.world)) or {}

    for index, row in ipairs(tipRows) do
        local tip = tips[index]
        if tip then
            local spellName, spellIcon = GetSpellData(tip.spellID, tip.fallbackName and T(tip.fallbackName) or tip.fallbackName)
            local known = IsSpellKnownSafe(tip.spellID)
            local suffix = tip.optional and not known and (" |cff999999" .. T("(talent)") .. "|r") or ""

            row.spellID = tip.spellID
            row.spellName = spellName
            row.icon:SetTexture(spellIcon)
            row.tag:SetText(T(tip.tag or "TIP"))
            row.name:SetText(spellName .. suffix)
            row.description:SetText(T(tip.text or ""))
            row:Show()
        else
            row.spellID = nil
            row:Hide()
        end
    end

    if mainFrame.survivalSection and mainFrame.survivalSection.title then
        mainFrame.survivalSection.title:SetText(T("DK Toolkit — %s / %s", tostring(specName), tostring(contextName)))
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
    local contextName = self:GetRuntimeContextLabel(context)
    local specCoach = Data.coach and Data.coach[specID]
    local generalCoach = Data.coach and Data.coach.general
    local baseEntries = (specCoach and (specCoach[context] or specCoach.world)) or (generalCoach and (generalCoach[context] or generalCoach.world)) or {}
    local entries, health, state = self:GetAdaptiveCoachEntries(specID, context, baseEntries)
    coachFrame.hasVisibleCards = type(entries) == "table" and #entries > 0

    coachFrame.title:SetText(string.format("DK Mentor — %s / %s", specName, contextName))
    if health then
        coachFrame.healthText:SetText(T("Health: %d%% • %s", math.floor(health + 0.5), T(state or "")))
    else
        coachFrame.healthText:SetText("")
    end

    for index, card in ipairs(coachCards) do
        local entry = entries[index]
        if entry then
            local spellName, spellIcon = GetSpellData(entry.spellID, entry.fallbackName and T(entry.fallbackName) or entry.fallbackName)
            local known = IsSpellKnownSafe(entry.spellID)
            local suffix = entry.optional and not known and (" " .. T("(talent)")) or ""

            card.spellID = entry.spellID
            card.spellName = spellName
            card.icon:SetTexture(spellIcon)
            card.action:SetText(T(entry.title or "USE"))
            card.spell:SetText(spellName .. suffix)
            card.when:SetText(T(entry.when or ""))
            card.mentorKind = entry.kind
            if entry.kind == "rotation" then
                -- Card 1 can be pinned to Blizzard Assisted Combat's next spell.
                -- Give it a stable, subtle cyan identity without making it look
                -- like an urgent defensive or interrupt warning.
                card:SetBackdropColor(0.018, 0.075, 0.105, 0.90)
                card:SetBackdropBorderColor(0.25, 0.72, 0.88, 0.92)
            elseif health and health <= 70 and entry.kind == "defensive" then
                card:SetBackdropColor(0.10, 0.18, 0.22, 0.96)
                card:SetBackdropBorderColor(0.95, 0.72, 0.18, 1)
            else
                card:SetBackdropColor(0.025, 0.08, 0.11, 0.82)
                card:SetBackdropBorderColor(0.16, 0.47, 0.62, 0.85)
            end
            if self.ApplyMentorCardStyle then self:ApplyMentorCardStyle(card, entry) end
            card:Show()
        else
            card.spellID = nil
            card:Hide()
        end
    end
end

function addon:ShowMentorAlertPreview()
    if not coachFrame or not interruptFrame or not DB then
        return false
    end
    if self:IsPlayerInCombat() then
        Print(T("Alert preview is available only out of combat."))
        return false
    end

    self.mentorAlertPreviewToken = (tonumber(self.mentorAlertPreviewToken) or 0) + 1
    local token = self.mentorAlertPreviewToken
    local specID = select(1, self:GetSpecInfo())
    local procSpell = specID == 250 and 43265 or (specID == 251 and 49020 or 47541)
    local samples = {
        { spellID = 48792, title = T("DEFENSIVE"), when = T("example: heavy incoming pressure") },
        { spellID = procSpell, title = T("PROC"), when = T("example: high-value proc is active") },
        { spellID = 49998, title = T("RESOURCE"), when = T("example: spend or recover before capping") },
    }

    coachFrame.title:SetText(T("DK Mentor — alert preview"))
    coachFrame.healthText:SetText(T("Preview: Defensive • Proc • Resource"))
    for index, card in ipairs(coachCards) do
        local entry = samples[index]
        if entry then
            local spellName, spellIcon = GetSpellData(entry.spellID, T("Ability"))
            card.spellID = entry.spellID
            card.spellName = spellName
            card.icon:SetTexture(spellIcon or QUESTION_MARK_ICON)
            card.action:SetText(entry.title)
            card.spell:SetText(spellName)
            card.when:SetText(entry.when)
            card:SetBackdropColor(0.025, 0.08, 0.11, 0.82)
            card:SetBackdropBorderColor(0.16, 0.47, 0.62, 0.85)
            card:Show()
        else
            card.spellID = nil
            card:Hide()
        end
    end
    if self.ApplyMentorCoachLayout then self:ApplyMentorCoachLayout() end
    coachFrame:Show()

    local mindFreeze = (Data.spells and Data.spells.MIND_FREEZE) or 47528
    local _, interruptIcon = GetSpellData(mindFreeze, T("Mind Freeze"))
    interruptFrame.icon:SetTexture(interruptIcon or QUESTION_MARK_ICON)
    interruptFrame:SetAlpha(1)
    interruptFrame.icon:SetAlpha(1)
    if interruptFrame.icon.SetDesaturated then interruptFrame.icon:SetDesaturated(false) end
    interruptFrame:SetBackdropBorderColor(0.18, 0.88, 0.92, 1)
    if interruptFrame.cooldown and interruptFrame.cooldown.SetCooldown then
        pcall(interruptFrame.cooldown.SetCooldown, interruptFrame.cooldown, 0, 0)
    end
    interruptFrame:Show()
    self:UpdateInterruptActionGlows(true, false, nil, true)

    Print(T("Alert preview active for 4 seconds."))
    if C_Timer and C_Timer.After then
        C_Timer.After(4, function()
            if addon.mentorAlertPreviewToken ~= token then return end
            if coachFrame then
                addon:UpdateCoach()
                addon:RefreshCoachVisibility()
            end
            if interruptFrame then
                addon:UpdateInterruptAlert()
            end
        end)
    end
    return true
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
        self:UpdateCoach()
        if preview or coachFrame.hasVisibleCards ~= false then
            coachFrame:Show()
        else
            coachFrame:Hide()
        end
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
        pcall(container.SetAuraGroupMaxFrameCount, container, groupKey, addon.MANAGED_AURA_MAX_FRAMES)
    end
    ConfigureManagedAuraFlow(container, GetConfiguredBarColumns("buffBar", addon.MANAGED_AURAS_PER_LINE, 10))
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

function addon:_GetInterruptSoundConfig()
    if not DB then return nil end
    DB.mentor = type(DB.mentor) == "table" and DB.mentor or {}
    DB.mentor.studio = type(DB.mentor.studio) == "table" and DB.mentor.studio or {}
    DB.mentor.studio.kinds = type(DB.mentor.studio.kinds) == "table" and DB.mentor.studio.kinds or {}
    DB.mentor.studio.kinds.interrupt = type(DB.mentor.studio.kinds.interrupt) == "table" and DB.mentor.studio.kinds.interrupt or {}
    local cfg = DB.mentor.studio.kinds.interrupt
    if cfg.sound == nil then cfg.sound = false end
    return cfg
end

function addon:GetInterruptSoundEnabled()
    local cfg = self:_GetInterruptSoundConfig()
    return cfg and cfg.sound == true or false
end

function addon:SetInterruptSoundEnabled(enabled)
    local cfg = self:_GetInterruptSoundConfig()
    if not cfg then return end
    cfg.sound = enabled == true
    if DKM.MentorStudio and DKM.MentorStudio.Refresh then DKM.MentorStudio.Refresh() end
    Print(T(cfg.sound and "Interrupt sound enabled." or "Interrupt sound disabled."))
end

function addon:_GetMacroSpellIDSafe(macroID)
    if not GetMacroSpell or not macroID then return nil end
    local ok, a, b, c = pcall(GetMacroSpell, macroID)
    if not ok then return nil end
    if IsAccessibleNumber(c) then return c end
    if IsAccessibleNumber(a) then return a end
    return nil
end

function addon:_GetActionButtonSlotSafe(button)
    if not button then return nil end
    if IsAccessibleNumber(button.action) then return button.action end
    if button.GetAttribute then
        local ok, action = pcall(button.GetAttribute, button, "action")
        if ok and IsAccessibleNumber(action) then return action end
    end
    return nil
end

function addon:_GetActionInfoSafe(slot)
    if not IsAccessibleNumber(slot) then return nil, nil, nil end
    if C_ActionBar and C_ActionBar.GetActionInfo then
        local ok, actionType, id, subType = pcall(C_ActionBar.GetActionInfo, slot)
        if ok then return actionType, id, subType end
    end
    if GetActionInfo then
        local ok, actionType, id, subType = pcall(GetActionInfo, slot)
        if ok then return actionType, id, subType end
    end
    return nil, nil, nil
end

function addon:_SpellMatchesMindFreeze(spellID)
    local mindFreeze = (Data.spells and Data.spells.MIND_FREEZE) or 47528
    if not IsAccessibleNumber(spellID) then return false end
    if spellID == mindFreeze then return true end
    if C_Spell and C_Spell.GetBaseSpell then
        local okA, baseA = pcall(C_Spell.GetBaseSpell, spellID)
        local okB, baseB = pcall(C_Spell.GetBaseSpell, mindFreeze)
        if okA and okB and IsAccessibleNumber(baseA) and IsAccessibleNumber(baseB) and baseA == baseB then
            return true
        end
    end
    return false
end

function addon:_ActionSlotContainsMindFreeze(slot, directSlots)
    if not IsAccessibleNumber(slot) then return false end
    if directSlots and directSlots[slot] then return true end
    local actionType, id = addon:_GetActionInfoSafe(slot)
    if actionType == "spell" then
        return addon:_SpellMatchesMindFreeze(id)
    elseif actionType == "macro" then
        return addon:_SpellMatchesMindFreeze(addon:_GetMacroSpellIDSafe(id))
    end
    return false
end

function addon:_CreateInterruptGlowFrame(button)
    if not button then return nil end
    local existing = addon.interruptGlowFrames[button]
    if existing then return existing end
    if InCombatLockdown and InCombatLockdown() then return nil end

    local glow = CreateFrame("Frame", nil, button)
    glow:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 3)
    glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, -3)
    glow:SetFrameLevel((button.GetFrameLevel and button:GetFrameLevel() or 0) + 18)
    glow:EnableMouse(false)

    local visual = CreateFrame("Frame", nil, glow)
    visual:SetAllPoints(glow)
    visual:EnableMouse(false)
    glow.visual = visual

    local thickness = 2
    local function Edge(point1, relativePoint1, x1, y1, point2, relativePoint2, x2, y2)
        local texture = visual:CreateTexture(nil, "OVERLAY")
        texture:SetColorTexture(0.10, 0.88, 1.00, 0.95)
        texture:SetPoint(point1, visual, relativePoint1, x1, y1)
        texture:SetPoint(point2, visual, relativePoint2, x2, y2)
        return texture
    end
    glow.top = Edge("TOPLEFT", "TOPLEFT", 0, 0, "TOPRIGHT", "TOPRIGHT", 0, -thickness)
    glow.bottom = Edge("BOTTOMLEFT", "BOTTOMLEFT", 0, thickness, "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0)
    glow.left = Edge("TOPLEFT", "TOPLEFT", 0, -thickness, "BOTTOMLEFT", "BOTTOMLEFT", thickness, thickness)
    glow.right = Edge("TOPRIGHT", "TOPRIGHT", -thickness, -thickness, "BOTTOMRIGHT", "BOTTOMRIGHT", 0, thickness)

    if visual.CreateAnimationGroup then
        local pulse = visual:CreateAnimationGroup()
        pulse:SetLooping("REPEAT")
        local fadeOut = pulse:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0.45)
        fadeOut:SetDuration(0.28)
        fadeOut:SetOrder(1)
        local fadeIn = pulse:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0.45)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.28)
        fadeIn:SetOrder(2)
        glow.pulse = pulse
    end

    glow:Hide()
    addon.interruptGlowFrames[button] = glow
    return glow
end

function addon:HideInterruptActionGlows()
    for _, entry in ipairs(self.interruptActionGlowTargets or {}) do
        local glow = entry and entry.glow
        if glow then
            if glow.pulse and glow.pulse.IsPlaying and glow.pulse:IsPlaying() then glow.pulse:Stop() end
            if glow.visual then glow.visual:SetAlpha(1) end
            glow:SetAlpha(1)
            glow:Hide()
        end
    end
end

function addon:RefreshInterruptActionGlowTargets()
    if not DB or not DB.interruptAlert then return false end
    if InCombatLockdown and InCombatLockdown() then return false end

    self:HideInterruptActionGlows()
    self.interruptActionGlowTargets = {}

    local directSlots = {}
    local mindFreeze = (Data.spells and Data.spells.MIND_FREEZE) or 47528
    if C_ActionBar and C_ActionBar.FindSpellActionButtons then
        local ok, slots = pcall(C_ActionBar.FindSpellActionButtons, mindFreeze)
        if ok and type(slots) == "table" then
            for _, slot in ipairs(slots) do
                if IsAccessibleNumber(slot) then directSlots[slot] = true end
            end
        end
    end

    local seen = setmetatable({}, { __mode = "k" })
    local function Consider(button)
        if not button or seen[button] then return end
        seen[button] = true
        local slot = self:_GetActionButtonSlotSafe(button)
        if not self:_ActionSlotContainsMindFreeze(slot, directSlots) then return end
        local glow = self:_CreateInterruptGlowFrame(button)
        if glow then
            self.interruptActionGlowTargets[#self.interruptActionGlowTargets + 1] = { button = button, glow = glow, slot = slot }
        end
    end

    local registry = _G.ActionBarButtonEventsFrame
    if registry and type(registry.frames) == "table" then
        for _, button in pairs(registry.frames) do Consider(button) end
    end

    for _, prefix in ipairs({
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button",
    }) do
        for index = 1, 12 do Consider(_G[prefix .. index]) end
    end

    return #self.interruptActionGlowTargets > 0
end

function addon:ScheduleInterruptActionGlowRefresh()
    self.interruptGlowRefreshToken = (tonumber(self.interruptGlowRefreshToken) or 0) + 1
    local token = self.interruptGlowRefreshToken
    local function Refresh()
        if token ~= addon.interruptGlowRefreshToken or not addon.active then return end
        if InCombatLockdown and InCombatLockdown() then return end
        addon:RefreshInterruptActionGlowTargets()
        addon:UpdateInterruptAlert()
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.20, Refresh) else Refresh() end
end

function addon:SetInterruptActionGlowEnabled(enabled)
    if not DB or not DB.interruptAlert then return end
    DB.interruptAlert.actionGlow = enabled == true
    if DB.interruptAlert.actionGlow then
        self:ScheduleInterruptActionGlowRefresh()
    else
        self:HideInterruptActionGlows()
    end
    self:UpdateHUDSettings()
    if DKM.MentorStudio and DKM.MentorStudio.Refresh then DKM.MentorStudio.Refresh() end
    Print(T(DB.interruptAlert.actionGlow and "Interrupt action-bar glow enabled." or "Interrupt action-bar glow disabled."))
end

function addon:_SetInterruptActionGlowFromNotInterruptible(glow, notInterruptible)
    if not glow then return false end
    if IsSecretValue(notInterruptible) then
        if glow.SetAlphaFromBoolean then
            return pcall(glow.SetAlphaFromBoolean, glow, notInterruptible, 0, 1) == true
        end
        return false
    end
    local guarded = GetAccessibleBoolean(notInterruptible)
    if guarded == nil then return false end
    if glow.SetAlphaFromBoolean and pcall(glow.SetAlphaFromBoolean, glow, guarded, 0, 1) then return true end
    glow:SetAlpha(guarded and 0 or 1)
    return true
end

function addon:_IsMindFreezeReadyForActionGlow(cooldownInfo, usable)
    local usableBool = GetAccessibleBoolean(usable)
    if usableBool == false then return false end
    if cooldownInfo and IsAccessibleNumber(cooldownInfo.startTime) and IsAccessibleNumber(cooldownInfo.duration) then
        local startTime = cooldownInfo.startTime
        local duration = cooldownInfo.duration
        if startTime > 0 and duration > 1.6 then
            local now = GetNow()
            if IsAccessibleNumber(now) and now < (startTime + duration - 0.05) then return false end
        end
    end
    return true
end

function addon:UpdateInterruptActionGlows(hasCast, rawNotInterruptible, cooldownInfo, usable)
    if not DB or not DB.interruptAlert or DB.interruptAlert.enabled ~= true or DB.interruptAlert.actionGlow ~= true then
        self:HideInterruptActionGlows()
        return
    end
    if hasCast ~= true or not self:_IsMindFreezeReadyForActionGlow(cooldownInfo, usable) then
        self:HideInterruptActionGlows()
        return
    end
    if #(self.interruptActionGlowTargets or {}) == 0 and not (InCombatLockdown and InCombatLockdown()) then
        self:RefreshInterruptActionGlowTargets()
    end

    for _, entry in ipairs(self.interruptActionGlowTargets or {}) do
        local button, glow = entry.button, entry.glow
        if button and glow then
            -- Macros can resolve dynamically and action pages can change.
            -- Re-check the current slot before showing a cached glow so a
            -- button that no longer represents Mind Freeze never lights up.
            local stillMindFreeze = self:_ActionSlotContainsMindFreeze(entry.slot, nil)
            local visible = stillMindFreeze == true
            if visible and button.IsShown then
                local ok, shown = pcall(button.IsShown, button)
                if ok then visible = shown == true end
            end
            if visible then
                glow:Show()
                if glow.pulse and glow.pulse.IsPlaying and not glow.pulse:IsPlaying() then glow.pulse:Play() end
                local bound = self:_SetInterruptActionGlowFromNotInterruptible(glow, rawNotInterruptible)
                if not bound then
                    if targetInterruptEventState == true then
                        glow:SetAlpha(1)
                    else
                        glow:Hide()
                    end
                end
            else
                glow:Hide()
            end
        end
    end
end

function addon:SetInterruptAlertEnabled(enabled)
    if not DB or not DB.interruptAlert then return end
    DB.interruptAlert.enabled = enabled == true
    targetInterruptEventState = nil
    if DB.interruptAlert.enabled ~= true then self:HideInterruptActionGlows() end
    self:UpdateInterruptAlert()
    self:UpdateHUDSettings()
    Print(T(DB.interruptAlert.enabled and "Interrupt alert enabled." or "Interrupt alert disabled."))
end

local function GetTargetInterruptStateFromCastAPI()
    -- Midnight 12.x may return notInterruptible as a Secret Value during
    -- restricted combat. castBarID is NeverSecret, so it is safe to use only
    -- for cast presence/identity while the raw boolean is passed through to a
    -- Secret-aware widget without Lua branching on its value.
    if UnitCastingInfo then
        local ok, _, _, _, _, _, _, _, notInterruptible, _, castBarID = pcall(UnitCastingInfo, "target")
        if ok and IsAccessibleNumber(castBarID) then
            return true, notInterruptible, "cast", castBarID
        end
    end

    if UnitChannelInfo then
        local ok, _, _, _, _, _, _, notInterruptible, _, _, _, castBarID = pcall(UnitChannelInfo, "target")
        if ok and IsAccessibleNumber(castBarID) then
            return true, notInterruptible, "channel", castBarID
        end
    end

    return false, nil, nil, nil
end

local function SetInterruptFrameFromNotInterruptible(frame, notInterruptible)
    if not frame then return false end

    -- This is the key Midnight path. SetAlphaFromBoolean accepts Secret
    -- booleans, so a secret `notInterruptible` can still drive presentation:
    -- true => transparent, false => visible. Lua never inspects the secret.
    if IsSecretValue(notInterruptible) then
        if frame.SetAlphaFromBoolean then
            local ok = pcall(frame.SetAlphaFromBoolean, frame, notInterruptible, 0, 1)
            return ok == true
        end
        return false
    end

    local guarded = GetAccessibleBoolean(notInterruptible)
    if guarded == nil then return false end

    if frame.SetAlphaFromBoolean then
        local ok = pcall(frame.SetAlphaFromBoolean, frame, guarded, 0, 1)
        if ok then return true end
    end

    -- Non-secret fallback for clients that do not expose SetAlphaFromBoolean.
    frame:SetAlpha(guarded and 0 or 1)
    return true
end

local function SetInterruptFrameFullyVisible(frame)
    if not frame then return end
    if frame.SetAlphaFromBoolean then
        local ok = pcall(frame.SetAlphaFromBoolean, frame, true, 1, 0)
        if ok then return end
    end
    frame:SetAlpha(1)
end

function addon:PrintInterruptAlertStatus()
    if not DB or not DB.interruptAlert then return end

    local hasCast, rawNotInterruptible, source, castBarID = GetTargetInterruptStateFromCastAPI()
    local interruptState = "unavailable"
    if IsSecretValue(rawNotInterruptible) then
        interruptState = "secret -> widget"
    else
        local guarded = GetAccessibleBoolean(rawNotInterruptible)
        if guarded == true then interruptState = "not interruptible"
        elseif guarded == false then interruptState = "interruptible" end
    end

    local eventState = "none"
    if targetInterruptEventState == true then eventState = "interruptible"
    elseif targetInterruptEventState == false then eventState = "not interruptible" end

    Print(T("Interrupt status: enabled=%s • cast=%s • source=%s • castBarID=%s • API=%s • event=%s",
        DB.interruptAlert.enabled == true and "yes" or "no",
        hasCast and "yes" or "no",
        tostring(source or "none"),
        IsAccessibleNumber(castBarID) and tostring(castBarID) or "none",
        interruptState,
        eventState))
end

local function ScheduleInterruptAlertRefreshes()
    if not (C_Timer and C_Timer.After) then return end
    C_Timer.After(0.05, function()
        if addon.active then addon:UpdateInterruptAlert() end
    end)
    C_Timer.After(0.20, function()
        if addon.active then addon:UpdateInterruptAlert() end
    end)
    C_Timer.After(0.80, function()
        if addon.active then addon:UpdateInterruptAlert() end
    end)
end

function addon:UpdateInterruptAlert()
    if not interruptFrame or not DB or not self.active then return end

    if self.hudPreviewMode == true then
        SetInterruptFrameFullyVisible(interruptFrame)
        interruptFrame:SetBackdropBorderColor(0.25, 0.78, 0.95, 1)
        interruptFrame.icon:SetAlpha(1)
        if interruptFrame.icon.SetDesaturated then interruptFrame.icon:SetDesaturated(false) end
        ClearTrackingCooldown(interruptFrame)
        interruptFrame:Show()
        self:UpdateInterruptActionGlows(true, false, nil, true)
        return
    end

    if not DB.interruptAlert or DB.interruptAlert.enabled ~= true then
        interruptFrame:Hide()
        self:HideInterruptActionGlows()
        return
    end

    if DB.combatBarsOnlyInCombat == true and not self:IsPlayerInCombat() then
        interruptFrame:Hide()
        self:HideInterruptActionGlows()
        return
    end

    local hasCast, rawNotInterruptible = GetTargetInterruptStateFromCastAPI()

    if not hasCast then
        -- Never keep an event latch alive after the NeverSecret cast-presence
        -- signal says the target is no longer casting/channeling.
        interruptFrame:Hide()
        self:HideInterruptActionGlows()
        return
    end

    -- Prefer the API value whenever it exists. In Midnight this may be Secret,
    -- which is exactly why the frame consumes it through SetAlphaFromBoolean.
    -- The readable unit events are only fallbacks for short API transition gaps.
    local presentationBound = SetInterruptFrameFromNotInterruptible(interruptFrame, rawNotInterruptible)
    if not presentationBound then
        if targetInterruptEventState == true then
            SetInterruptFrameFullyVisible(interruptFrame)
        else
            -- false = confirmed non-interruptible; nil = no safe signal yet.
            interruptFrame:Hide()
            self:HideInterruptActionGlows()
            return
        end
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

    self:UpdateInterruptActionGlows(hasCast, rawNotInterruptible, cooldownInfo, usable)

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
        local isSelected = NormalizeAddonLanguage(button.languageValue) == selected
        button:SetText(label)
        SetActionButtonSelected(button, isSelected)
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

function addon:IsLoadoutPilotAvailable()
    return SlashCmdList and type(SlashCmdList.LOADOUTPILOT) == "function"
end

function addon:OpenLoadoutPilot()
    if self:IsLoadoutPilotAvailable() then
        SlashCmdList.LOADOUTPILOT("")
        return true
    end
    Print(T("Loadout Pilot is not currently loaded. Install or enable Loadout Pilot to automate specialization, talents, gear, and loot specialization."))
    return false
end

function addon:OpenOmniumFolio()
    local function TryCall(func, ...)
        if type(func) ~= "function" then return false end
        local ok, result = pcall(func, ...)
        if not ok then return false end
        if result == nil then return true end
        return result ~= false
    end

    local opened = false
    if TryCall(_G.TogglePlayerSpellsFrame) then
        opened = true
    elseif _G.PlayerSpellsMicroButton and TryCall(_G.PlayerSpellsMicroButton.Click, _G.PlayerSpellsMicroButton) then
        opened = true
    elseif _G.TalentMicroButton and TryCall(_G.TalentMicroButton.Click, _G.TalentMicroButton) then
        opened = true
    elseif _G.ToggleSpellBook and BOOKTYPE_SPELL and TryCall(_G.ToggleSpellBook, BOOKTYPE_SPELL) then
        opened = true
    elseif _G.ShowUIPanel and _G.PlayerSpellsFrame and TryCall(_G.ShowUIPanel, _G.PlayerSpellsFrame) then
        opened = true
    elseif _G.ShowUIPanel and _G.SpellBookFrame and TryCall(_G.ShowUIPanel, _G.SpellBookFrame) then
        opened = true
    end

    if opened then
        Print(T("Opened Blizzard's Player Spells frame. If Omnium Folio is not selected automatically, click its tab there."))
        return true
    end

    Print(T("Could not open Omnium Folio automatically on this client. Open Blizzard's Player Spells/Talents frame and select Omnium Folio manually."))
    return false
end

function addon:UpdateLoadoutPilotIntegration()
    if not mainFrame or not mainFrame.loadoutPilotSection then return end
    local section = mainFrame.loadoutPilotSection
    local available = self:IsLoadoutPilotAvailable()
    if section.description then
        if available then
            section.description:SetText(T("Loadout Pilot detected. DK Mentor focuses on Death Knight guidance while Loadout Pilot handles specialization, talent, gear, and loot-spec automation."))
        else
            section.description:SetText(T("Loadout automation moved to the dedicated Loadout Pilot addon. DK Mentor no longer changes specialization, talents, gear, or loot specialization automatically."))
        end
    end
    if section.openButton then
        section.openButton:SetText(available and T("Open Loadout Pilot") or T("Loadout Pilot not detected"))
        section.openButton:SetEnabled(available)
        StyleActionButton(section.openButton)
    end
    if mainFrame.guideSection and mainFrame.guideSection.openPilotButton then
        mainFrame.guideSection.openPilotButton:SetEnabled(available)
        StyleActionButton(mainFrame.guideSection.openPilotButton)
        mainFrame.guideSection.openPilotButton:SetText(available and T("Open Loadout Pilot") or T("Pilot not detected"))
    end
end

function addon:UpdateHUDSettings()
    if not mainFrame or not mainFrame.hudSection or not DB then return end
    self:UpdateLanguageSettings()
    local hud = mainFrame.hudSection
    if hud.buildButton then hud.buildButton:SetText(DB.statusWidget.enabled and T("DK status: ON") or T("DK status: OFF")); SetActionButtonSelected(hud.buildButton, DB.statusWidget.enabled) end
    if hud.coachButton then hud.coachButton:SetText(DB.coach.enabled and T("Coach: ON") or T("Coach: OFF")); SetActionButtonSelected(hud.coachButton, DB.coach.enabled) end
    if hud.buffButton then hud.buffButton:SetText(DB.buffBar.enabled and T("DK buffs: ON") or T("DK buffs: OFF")); SetActionButtonSelected(hud.buffButton, DB.buffBar.enabled) end
    if hud.externalBuffButton then hud.externalBuffButton:SetText(DB.externalBuffBar.enabled and T("External: ON") or T("External: OFF")); SetActionButtonSelected(hud.externalBuffButton, DB.externalBuffBar.enabled) end
    if hud.debuffButton then hud.debuffButton:SetText(DB.debuffBar.enabled and T("Debuffs: ON") or T("Debuffs: OFF")); SetActionButtonSelected(hud.debuffButton, DB.debuffBar.enabled) end
    if hud.abilityButton then hud.abilityButton:SetText(DB.abilityBar.enabled and T("Abilities: ON") or T("Abilities: OFF")); SetActionButtonSelected(hud.abilityButton, DB.abilityBar.enabled) end
    if hud.resourceButton then hud.resourceButton:SetText(DB.resourceHUD.enabled and T("Resources: ON") or T("Resources: OFF")); SetActionButtonSelected(hud.resourceButton, DB.resourceHUD.enabled) end
    if hud.resourceDescription then
        hud.resourceDescription:SetText(T(
            "Resources: %s • Style: %s • Text: %s • Rune spacing: %s • Visibility: %s",
            self:GetResourceHUDModeLabel(),
            self:GetResourceHUDStyleLabel(),
            T(DB.resourceHUD.showPowerText ~= false and "ON" or "OFF"),
            self:GetResourceRuneSpacingLabel(),
            self:GetResourceVisibilityModeLabel()
        ))
    end
    if hud.interruptButton then hud.interruptButton:SetText(DB.interruptAlert.enabled and T("Interrupt: ON") or T("Interrupt: OFF")); SetActionButtonSelected(hud.interruptButton, DB.interruptAlert.enabled) end
    if hud.interruptOptionsButton then hud.interruptOptionsButton:SetText(T("Interrupt options...")) end
    if hud.combatOnlyButton then hud.combatOnlyButton:SetText(DB.combatBarsOnlyInCombat and T("Bars only in combat: ON") or T("Bars only in combat: OFF")); SetActionButtonSelected(hud.combatOnlyButton, DB.combatBarsOnlyInCombat) end
    if hud.lockButton then hud.lockButton:SetText(DB.hudLocked and T("HUDs: LOCKED") or T("HUDs: UNLOCKED")); SetActionButtonSelected(hud.lockButton, DB.hudLocked == false) end
    if hud.previewButton then hud.previewButton:SetText(self.hudPreviewMode == true and T("Preview HUDs: ON") or T("Preview HUDs: OFF")); SetActionButtonSelected(hud.previewButton, self.hudPreviewMode == true) end
    if hud.presetButton then hud.presetButton:SetText(T("Layout presets...")) end
    self:UpdateHUDMoveHints()
    self:UpdateLoadoutPilotIntegration()
end

function addon:GetCodexSpecID()
    local currentSpecID = select(1, self:GetSpecInfo())
    local selected = DB and tonumber(DB.codexSpecID) or 0
    if selected == 250 or selected == 251 or selected == 252 then
        return selected, false
    end
    return currentSpecID, true
end

function addon:SetCodexSpecID(specID)
    if not DB then return end
    specID = tonumber(specID) or 0
    if specID ~= 0 and specID ~= 250 and specID ~= 251 and specID ~= 252 then
        specID = 0
    end
    DB.codexSpecID = specID
    self:UpdateGuideSection()
end

function addon:SetCodexSection(sectionKey)
    if not DB then return end
    local valid = { overview = true, advisor = true, builds = true, stats = true, meta = true, valeera = true, rotation = true, survival = true, utility = true, check = true }
    if not valid[sectionKey] then sectionKey = "overview" end
    DB.codexSection = sectionKey
    self:UpdateGuideSection()
end

function addon:GetCodexBuildContext()
    local selected = DB and tostring(DB.codexBuildContext or "auto") or "auto"
    local valid = { auto=true, world=true, delve=true, dungeon=true, mythicplus=true, raid=true, pvp=true }
    if not valid[selected] then selected = "auto" end
    if selected == "auto" then
        return self:DetectActualContext(), true
    end
    return selected, false
end

function addon:SetCodexBuildContext(contextKey)
    if not DB then return end
    contextKey = tostring(contextKey or "auto")
    local valid = { auto=true, world=true, delve=true, dungeon=true, mythicplus=true, raid=true, pvp=true }
    if not valid[contextKey] then contextKey = "auto" end
    DB.codexBuildContext = contextKey
    DB.codexSection = "builds"
    self:UpdateGuideSection()
end

function addon:GetCodexBuildMode()
    local mode = DB and tostring(DB.codexBuildMode or "standard") or "standard"
    if mode ~= "standard" and mode ~= "sba" then mode = "standard" end
    return mode
end

function addon:SetCodexBuildMode(mode)
    if not DB then return end
    mode = string.lower(tostring(mode or "standard"))
    if mode ~= "sba" then mode = "standard" end
    DB.codexBuildMode = mode
    DB.codexSection = "builds"
    self:UpdateGuideSection()
end

function addon:SetCodexGearView(viewKey)
    if not DB then return end
    if viewKey == "plan" then viewKey = "upgrades" end
    local valid = { overview = true, targets = true, preparation = true, crafting = true, sources = true, trinkets = true, upgrades = true }
    if not valid[viewKey] then viewKey = "overview" end
    DB.codexGearView = viewKey
    DB.codexSection = "stats"
    self:UpdateGuideSection()
end

function addon:GetValeeraPreset()
    local preset = DB and tostring(DB.valeeraPreset or "auto") or "auto"
    local valid = { auto = true, safe = true, balanced = true, fast = true, high = true, leveling = true }
    if not valid[preset] then preset = "auto" end
    return preset
end

function addon:SetValeeraPreset(presetKey)
    if not DB then return end
    presetKey = string.lower(tostring(presetKey or "auto"))
    local valid = { auto = true, safe = true, balanced = true, fast = true, high = true, leveling = true }
    if not valid[presetKey] then presetKey = "auto" end
    DB.valeeraPreset = presetKey
    DB.codexSection = "valeera"
    self:UpdateGuideSection()
end

addon.CODEX_ENCHANT_SLOTS = {
    { id = _G.INVSLOT_HEAD or 1, label = "Head" },
    { id = _G.INVSLOT_SHOULDER or 3, label = "Shoulders" },
    { id = _G.INVSLOT_CHEST or 5, label = "Chest" },
    { id = _G.INVSLOT_LEGS or 7, label = "Legs" },
    { id = _G.INVSLOT_FEET or 8, label = "Feet" },
    { id = _G.INVSLOT_FINGER1 or 11, label = "Ring 1" },
    { id = _G.INVSLOT_FINGER2 or 12, label = "Ring 2" },
}

function addon:GetSafeNumberFromCall(fn, ...)
    if not fn then return nil end
    local ok, value = pcall(fn, ...)
    if ok and IsAccessibleValue(value) and type(value) == "number" then
        return value
    end
    return nil
end

function addon:GetCurrentStatSnapshot()
    local crit = self:GetSafeNumberFromCall(GetCritChance)
    local haste = self:GetSafeNumberFromCall(GetHaste)
    local mastery = self:GetSafeNumberFromCall(GetMasteryEffect)
    if mastery == nil and GetMastery then mastery = self:GetSafeNumberFromCall(GetMastery) end
    local versatility
    if GetCombatRatingBonus and _G.CR_VERSATILITY_DAMAGE_DONE then
        versatility = self:GetSafeNumberFromCall(GetCombatRatingBonus, _G.CR_VERSATILITY_DAMAGE_DONE)
    end
    return {
        crit = crit,
        haste = haste,
        mastery = mastery,
        versatility = versatility,
    }
end

function addon:FormatStatPercent(value)
    if type(value) ~= "number" then return "?" end
    return string.format("%.1f%%", value)
end

function addon:CountEmptySocketsOnEquippedItems()
    if not GetItemStats then return nil, 0 end
    local total = 0
    local unknown = 0
    for slotID = 1, 17 do
        if slotID ~= 4 and slotID ~= 16 and slotID ~= 17 then
            local itemID, itemLink = GetEquippedItemData(slotID)
            if itemID or itemLink then
                if not itemLink then
                    unknown = unknown + 1
                else
                    local ok, stats = pcall(GetItemStats, itemLink)
                    if ok and type(stats) == "table" then
                        for key, value in pairs(stats) do
                            if type(key) == "string" and key:find("EMPTY_SOCKET", 1, true) and IsAccessibleValue(value) and type(value) == "number" then
                                total = total + math.max(0, value)
                            end
                        end
                    else
                        unknown = unknown + 1
                    end
                end
            end
        end
    end
    return total, unknown
end

function addon:GetCommonEnchantCoverage()
    local missingEnchantSlots = {}
    local enchantUnknown = 0
    for _, slot in ipairs(self.CODEX_ENCHANT_SLOTS or {}) do
        local itemID, itemLink = GetEquippedItemData(slot.id)
        if itemID or itemLink then
            local hasEnchant, known = self:GetPermanentEnchantState(slot.id)
            if not known then
                enchantUnknown = enchantUnknown + 1
            elseif not hasEnchant then
                table.insert(missingEnchantSlots, T(slot.label))
            end
        end
    end
    return missingEnchantSlots, enchantUnknown
end

local function GetEquippedAverageItemLevel()
    if not GetAverageItemLevel then return nil end
    local ok, overall, equipped = pcall(GetAverageItemLevel)
    if not ok then return nil end
    if IsAccessibleNumber(equipped) then return equipped end
    if IsAccessibleNumber(overall) then return overall end
    return nil
end

function addon:IsGearTargetEquipped(itemID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 or not GetInventoryItemID then return false end
    for slotID = 1, 19 do
        local ok, equippedID = pcall(GetInventoryItemID, "player", slotID)
        if ok and IsAccessibleNumber(equippedID) and equippedID == itemID then
            return true
        end
    end
    return false
end

function addon:GetGearTargetOwnedCount(itemID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then return 0 end

    if C_Item and C_Item.GetItemCount then
        local ok, count = pcall(C_Item.GetItemCount, itemID, true, false, true, true)
        if ok and IsAccessibleNumber(count) then return math.max(0, count) end
        ok, count = pcall(C_Item.GetItemCount, itemID)
        if ok and IsAccessibleNumber(count) then return math.max(0, count) end
    end
    if GetItemCount then
        local ok, count = pcall(GetItemCount, itemID, true)
        if ok and IsAccessibleNumber(count) then return math.max(0, count) end
    end

    local count = 0
    if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemID then
        for bag = 0, 5 do
            local okSlots, slots = pcall(C_Container.GetContainerNumSlots, bag)
            if okSlots and IsAccessibleNumber(slots) then
                for slot = 1, slots do
                    local okItem, bagItemID = pcall(C_Container.GetContainerItemID, bag, slot)
                    if okItem and IsAccessibleNumber(bagItemID) and bagItemID == itemID then
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

function addon:GetGearTargetName(target)
    if not target then return T("Unknown item") end
    local itemID = tonumber(target.itemID)
    if itemID and C_Item and C_Item.GetItemNameByID then
        local ok, name = pcall(C_Item.GetItemNameByID, itemID)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if itemID and GetItemInfo then
        local ok, name = pcall(GetItemInfo, itemID)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if itemID and C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
    return tostring(target.fallbackName or T("Unknown item"))
end

function addon:GetGearTargetState(target)
    if not target or not target.itemID then return "missing", 0 end
    if self:IsGearTargetEquipped(target.itemID) then return "equipped", 1 end
    local owned = self:GetGearTargetOwnedCount(target.itemID)
    if owned > 0 then return "owned", owned end
    return "missing", 0
end


addon.GEAR_VISUAL_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    edgeSize = 9,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

function addon:CompactGearText(text, maxChars)
    text = tostring(text or "")
    text = text:gsub("%s+", " ")
    maxChars = tonumber(maxChars) or 64
    if #text <= maxChars then return text end
    return text:sub(1, math.max(1, maxChars - 3)) .. "..."
end

function addon:FirstGearSentence(text)
    text = tostring(text or ""):gsub("%s+", " ")
    local first = text:match("^(.-%.)%s")
    return first or text
end

function addon:GetGearTargetIcon(target)
    local itemID = target and tonumber(target.itemID) or nil
    if not itemID or itemID <= 0 then return QUESTION_MARK_ICON end
    local icon
    if C_Item and C_Item.GetItemIconByID then
        local ok, value = pcall(C_Item.GetItemIconByID, itemID)
        if ok and IsAccessibleNumber(value) then icon = value end
    end
    if not icon and GetItemIcon then
        local ok, value = pcall(GetItemIcon, itemID)
        if ok and IsAccessibleNumber(value) then icon = value end
    end
    if not icon and C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
    return icon or QUESTION_MARK_ICON
end

function addon:GetGearTargetQualityColor(target)
    local itemID = target and tonumber(target.itemID) or nil
    if not itemID or itemID <= 0 then return 0.26, 0.60, 0.74 end
    local quality
    if C_Item and C_Item.GetItemInfo then
        local ok, _, _, value = pcall(C_Item.GetItemInfo, itemID)
        if ok and IsAccessibleNumber(value) then quality = value end
    end
    if not quality and GetItemInfo then
        local ok, _, _, value = pcall(GetItemInfo, itemID)
        if ok and IsAccessibleNumber(value) then quality = value end
    end
    if quality and GetItemQualityColor then
        local ok, r, g, b = pcall(GetItemQualityColor, quality)
        if ok and IsAccessibleNumber(r) and IsAccessibleNumber(g) and IsAccessibleNumber(b) then
            return r, g, b
        end
    end
    return 0.26, 0.60, 0.74
end

function addon:GetItemSetID(itemInfo)
    if not itemInfo then return nil end
    local function ReadSetID(fn)
        if not fn then return nil end
        local values = { pcall(fn, itemInfo) }
        if not values[1] then return nil end
        local setID = values[17]
        if IsAccessibleNumber(setID) then return setID end
        return nil
    end
    local setID = C_Item and ReadSetID(C_Item.GetItemInfo) or nil
    if setID then return setID end
    return ReadSetID(GetItemInfo)
end

function addon:GetEquippedTierSetState()
    local tier = GearData and GearData.tierSet or nil
    local setID = tier and tonumber(tier.setID) or nil
    local equipped = {}
    local count = 0
    if not setID then return count, equipped end

    for _, piece in ipairs(tier.pieces or {}) do
        local slotID = tonumber(piece.inventorySlot)
        local itemLink = slotID and GetInventoryItemLink and GetInventoryItemLink("player", slotID) or nil
        local equippedSetID = itemLink and self:GetItemSetID(itemLink) or nil
        local matches = equippedSetID == setID
        if not matches and slotID and GetInventoryItemID then
            local ok, itemID = pcall(GetInventoryItemID, "player", slotID)
            matches = ok and IsAccessibleNumber(itemID) and itemID == tonumber(piece.itemID)
        end
        if matches then
            count = count + 1
            equipped[slotID] = itemLink or ("item:" .. tostring(piece.itemID))
        end
    end
    return count, equipped
end

function addon:GetTierSetName()
    local tier = GearData and GearData.tierSet or nil
    if not tier then return T("Season 2 tier set") end
    if C_Item and C_Item.GetItemSetInfo and tier.setID then
        local ok, name = pcall(C_Item.GetItemSetInfo, tier.setID)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return tostring(tier.fallbackName or T("Season 2 tier set"))
end

function addon:HideGearTooltip(owner)
    if not GameTooltip then return end
    if not owner or not GameTooltip.IsOwned or GameTooltip:IsOwned(owner) then
        GameTooltip:Hide()
    end
    local root = mainFrame and mainFrame.guideSection and mainFrame.guideSection.gearVisual
    if root and (not owner or root.tooltipOwner == owner) then root.tooltipOwner = nil end
end

function addon:ShowGearItemTooltip(owner, target, itemLinkOverride)
    if not GameTooltip or not owner or not target then return end
    local itemID = tonumber(target.itemID)
    if not itemID or itemID <= 0 then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local hyperlink = itemLinkOverride or ("item:" .. tostring(itemID))
    local shown = pcall(GameTooltip.SetHyperlink, GameTooltip, hyperlink)
    if not shown then GameTooltip:SetText(self:GetGearTargetName(target)) end
    GameTooltip:AddLine(" ")
    if target.priority then
        GameTooltip:AddLine(T("Priority: %s", T(target.priority)), 1.00, 0.82, 0.35, true)
    end
    if target.slot then
        GameTooltip:AddLine(T("Slot: %s", T(target.slot)), 0.55, 0.84, 0.95, true)
    end
    if target.source then
        GameTooltip:AddLine(T("Source: %s", T(target.source)), 0.78, 0.88, 0.93, true)
    end
    if target.embellishment then
        GameTooltip:AddLine(T("Embellishment: %s", T(target.embellishment)), 0.78, 0.88, 0.93, true)
    end
    if target.reason then
        GameTooltip:AddLine(T(target.reason), 0.96, 0.96, 0.96, true)
    end
    GameTooltip:Show()
    local root = mainFrame and mainFrame.guideSection and mainFrame.guideSection.gearVisual
    if root then root.tooltipOwner = owner end
end

function addon:ResetGearVisual(root)
    root.itemUsed = 0
    root.panelUsed = 0
    root.textUsed = 0
    root.metricUsed = 0
    root.tierUsed = 0
    root.bonusUsed = 0
    root.prepUsed = 0
    self:HideGearTooltip(root.tooltipOwner)
    self:HidePreparationTooltip(root.tooltipOwner)
    for _, frame in ipairs(root.itemPool or {}) do frame:Hide() end
    for _, frame in ipairs(root.panelPool or {}) do frame:Hide() end
    for _, text in ipairs(root.textPool or {}) do text:Hide() end
    for _, frame in ipairs(root.metricPool or {}) do frame:Hide() end
    for _, frame in ipairs(root.tierPool or {}) do frame:Hide() end
    for _, frame in ipairs(root.bonusPool or {}) do frame:Hide() end
    for _, frame in ipairs(root.prepPool or {}) do frame:Hide() end
    for _, frame in ipairs(root.advisorContextButtons or {}) do frame:Hide() end
    if self.HideDKAdvisorVisualPools then self:HideDKAdvisorVisualPools(root) end
    if self.HideValeeraVisualPools then self:HideValeeraVisualPools(root) end
    if self.HideMetaVisualPools then self:HideMetaVisualPools(root) end
end

function addon:AcquireGearText(root, fontObject)
    root.textUsed = (root.textUsed or 0) + 1
    local text = root.textPool[root.textUsed]
    if not text then
        text = root:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlightSmall")
        root.textPool[root.textUsed] = text
    elseif fontObject then
        local resolvedFont = type(fontObject) == "string" and _G[fontObject] or fontObject
        if resolvedFont then text:SetFontObject(resolvedFont) end
    end
    text:ClearAllPoints()
    text:SetText("")
    text:SetTextColor(0.90, 0.95, 0.98)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetShadowColor(0, 0, 0, 0.85)
    text:SetShadowOffset(1, -1)
    text:Show()
    return text
end

function addon:AcquireGearPanel(root)
    root.panelUsed = (root.panelUsed or 0) + 1
    local panel = root.panelPool[root.panelUsed]
    if not panel then
        panel = CreateFrame("Frame", nil, root, "BackdropTemplate")
        panel:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
        panel.textPool = {}
        root.panelPool[root.panelUsed] = panel
    end
    panel:ClearAllPoints()
    panel:SetBackdropColor(0.018, 0.055, 0.075, 0.84)
    panel:SetBackdropBorderColor(0.12, 0.38, 0.50, 0.78)
    panel.textPool = panel.textPool or {}
    panel.textUsed = 0
    for _, text in ipairs(panel.textPool) do text:Hide() end
    panel:Show()
    return panel
end

function addon:AcquireGearPanelText(panel, fontObject)
    panel.textPool = panel.textPool or {}
    panel.textUsed = (panel.textUsed or 0) + 1
    local text = panel.textPool[panel.textUsed]
    if not text then
        text = panel:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlightSmall")
        panel.textPool[panel.textUsed] = text
    elseif fontObject then
        local resolvedFont = type(fontObject) == "string" and _G[fontObject] or fontObject
        if resolvedFont then text:SetFontObject(resolvedFont) end
    end
    text:ClearAllPoints()
    text:SetText("")
    text:SetTextColor(0.94, 0.97, 0.99)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetShadowColor(0, 0, 0, 0.85)
    text:SetShadowOffset(1, -1)
    text:Show()
    return text
end

function addon:SetGearTextBlockHeight(fontString, width, textValue, minHeight)
    if not fontString then return minHeight or 0 end
    fontString:SetWidth(width or 0)
    fontString:SetWordWrap(true)
    fontString:SetText(textValue or "")
    fontString:SetHeight(1)
    local actual = fontString.GetStringHeight and fontString:GetStringHeight() or (minHeight or 16)
    actual = math.max(minHeight or 16, math.ceil(actual))
    fontString:SetHeight(actual)
    return actual
end

function addon:AcquireGearMetric(root)
    root.metricUsed = (root.metricUsed or 0) + 1
    local card = root.metricPool[root.metricUsed]
    if not card then
        card = CreateFrame("Frame", nil, root, "BackdropTemplate")
        card:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
        card.label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.label:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -7)
        card.label:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -7)
        card.label:SetJustifyH("LEFT")
        card.value = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card.value:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 8, 7)
        card.value:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 7)
        card.value:SetJustifyH("LEFT")
        root.metricPool[root.metricUsed] = card
    end
    card:ClearAllPoints()
    card:SetBackdropColor(0.02, 0.065, 0.085, 0.90)
    card:SetBackdropBorderColor(0.16, 0.42, 0.54, 0.86)
    card.label:SetTextColor(0.76, 0.88, 0.93)
    card.value:SetTextColor(0.88, 0.96, 1.00)
    card:Show()
    return card
end

function addon:AcquireGearItemCard(root)
    root.itemUsed = (root.itemUsed or 0) + 1
    local card = root.itemPool[root.itemUsed]
    if not card then
        card = CreateFrame("Button", nil, root, "BackdropTemplate")
        card:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
        card:RegisterForClicks("LeftButtonUp")

        card.iconFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
        card.iconFrame:SetSize(46, 46)
        card.iconFrame:SetPoint("LEFT", card, "LEFT", 7, 0)
        card.iconFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        card.iconFrame:SetBackdropColor(0.01, 0.025, 0.035, 1)
        card.icon = card.iconFrame:CreateTexture(nil, "ARTWORK")
        card.icon:SetPoint("TOPLEFT", card.iconFrame, "TOPLEFT", 3, -3)
        card.icon:SetPoint("BOTTOMRIGHT", card.iconFrame, "BOTTOMRIGHT", -3, 3)
        card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 61, -6)
        card.name:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -3)
        card.name:SetHeight(30)
        card.name:SetJustifyH("LEFT")
        card.name:SetJustifyV("TOP")
        card.name:SetWordWrap(true)

        card.meta = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.meta:SetPoint("TOPLEFT", card, "TOPLEFT", 61, -38)
        card.meta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -35)
        card.meta:SetHeight(16)
        card.meta:SetJustifyH("LEFT")
        card.meta:SetWordWrap(false)
        card.meta:SetTextColor(0.82, 0.90, 0.94)

        card.status = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.status:SetPoint("TOPLEFT", card, "TOPLEFT", 61, -55)
        card.status:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 4)
        card.status:SetJustifyH("LEFT")
        card.status:SetJustifyV("TOP")
        card.status:SetWordWrap(true)

        card:EnableMouse(true)
        if card.iconFrame.EnableMouse then card.iconFrame:EnableMouse(false) end
        card.ResetGearHover = function(self)
            if self.baseBorder then
                self:SetBackdropBorderColor(self.baseBorder[1], self.baseBorder[2], self.baseBorder[3], self.baseBorder[4])
            end
            self:SetBackdropColor(0.018, 0.055, 0.075, 0.90)
            addon:HideGearTooltip(self)
        end
        card:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.045, 0.13, 0.17, 0.98)
            self:SetBackdropBorderColor(0.30, 0.74, 0.90, 1)
            addon:ShowGearItemTooltip(self, self.target, self.itemLinkOverride)
        end)
        card:SetScript("OnLeave", function(self) self:ResetGearHover() end)
        card:SetScript("OnHide", function(self) addon:HideGearTooltip(self) end)
        root.itemPool[root.itemUsed] = card
    end
    card:ClearAllPoints()
    card.target = nil
    card.itemLinkOverride = nil
    card:SetBackdropColor(0.018, 0.055, 0.075, 0.90)
    card:SetBackdropBorderColor(0.12, 0.38, 0.50, 0.82)
    card.baseBorder = { 0.12, 0.38, 0.50, 0.82 }
    card:Show()
    return card
end

function addon:ConfigureGearItemCard(card, target, width, height)
    local cardWidth = width or 336
    local minHeight = math.max(height or 60, 86)
    card:SetWidth(cardWidth)
    card.target = target
    local state = addon:GetGearTargetState(target)
    local statusText, sr, sg, sb
    if state == "equipped" then
        statusText, sr, sg, sb = T("EQUIPPED"), 0.40, 1.00, 0.60
        card.baseBorder = { 0.22, 0.72, 0.42, 0.95 }
    elseif state == "owned" then
        statusText, sr, sg, sb = T("OWNED"), 0.42, 0.82, 1.00
        card.baseBorder = { 0.22, 0.60, 0.76, 0.95 }
    else
        statusText, sr, sg, sb = target.craft and T("CRAFT") or T("TARGET"), 1.00, 0.82, 0.35
        card.baseBorder = { 0.52, 0.42, 0.18, 0.92 }
    end
    card:SetBackdropBorderColor(card.baseBorder[1], card.baseBorder[2], card.baseBorder[3], card.baseBorder[4])
    card.icon:SetTexture(addon:GetGearTargetIcon(target))
    local qr, qg, qb = addon:GetGearTargetQualityColor(target)
    card.iconFrame:SetBackdropBorderColor(qr, qg, qb, 1)
    card.name:SetTextColor(qr, qg, qb)

    card.iconFrame:ClearAllPoints()
    card.iconFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 7, -10)
    local textWidth = math.max(150, cardWidth - 69)
    card.name:ClearAllPoints()
    card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 61, -8)
    local nameHeight = self:SetGearTextBlockHeight(card.name, textWidth, addon:GetGearTargetName(target), 18)
    card.meta:ClearAllPoints()
    card.meta:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
    local metaHeight = self:SetGearTextBlockHeight(card.meta, textWidth, string.format("%s  •  %s", T(target.slot or "Gear"), T(target.priority or "HIGH")), 14)
    local detail = target.craft and (target.embellishment or T("Crafting")) or (target.source or "")
    local finalStatus = statusText .. ((detail and detail ~= "") and ("  •  " .. T(detail)) or "")
    card.status:ClearAllPoints()
    card.status:SetPoint("TOPLEFT", card.meta, "BOTTOMLEFT", 0, -4)
    local statusHeight = self:SetGearTextBlockHeight(card.status, textWidth, finalStatus, 16)
    card.status:SetTextColor(sr, sg, sb)
    local finalHeight = math.max(minHeight, 18 + nameHeight + metaHeight + statusHeight + 18)
    card:SetHeight(finalHeight)
    return finalHeight
end

function addon:GetPreparationSpec(specID)
    return DKM.PreparationData and DKM.PreparationData.specs and DKM.PreparationData.specs[tonumber(specID)] or nil
end

function addon:GetRecommendedRuneforgeStatus(specID)
    specID = tonumber(specID) or select(1, self:GetSpecInfo())
    local current = self:GetRuneforgeStatus()
    if not current or current.known == false then
        return { ready=false, known=false, detail=T("Checking runeforge...") }
    end

    local mainEnchant = current.main and tonumber(current.main.enchantID) or 0
    local offEnchant = current.off and tonumber(current.off.enchantID) or 0
    local dual = current.dualWield == true
    local ready = false
    local detail = current.detail

    if specID == 251 then
        if dual then
            local shattering = IsSpellKnownSafe(207057)
            local expectedMain = shattering and 3370 or 3847
            ready = mainEnchant == expectedMain and offEnchant == 3368
            local mainRune = Data.runeforges and Data.runeforges[expectedMain]
            local mainName = mainRune and select(1, GetSpellData(mainRune.spellID, mainRune.fallbackName)) or T("Recommended Runeforge")
            local fallen = Data.runeforges and Data.runeforges[3368]
            local offName = fallen and select(1, GetSpellData(fallen.spellID, fallen.fallbackName)) or T("Rune of the Fallen Crusader")
            detail = T("Dual Wield: Main Hand %s • Off Hand %s", tostring(mainName), tostring(offName))
        else
            -- Current Wowhead 12.1 Frost guidance uses Fallen Crusader for
            -- two-handed setups. Keep the Ready Check strict so it cannot
            -- bless an older niche Runeforge recommendation as current.
            ready = mainEnchant == 3368
            local fallen = Data.runeforges and Data.runeforges[3368]
            local fallenName = fallen and select(1, GetSpellData(fallen.spellID, fallen.fallbackName)) or T("Rune of the Fallen Crusader")
            detail = T("Two-Hand: %s", tostring(fallenName))
        end
    elseif specID == 250 then
        ready = mainEnchant == 6241 or mainEnchant == 3368
        detail = T("Blood: Sanguination for the default single-target/San'layn direction; Fallen Crusader is a Deathbringer high-target alternative.")
    elseif specID == 252 then
        ready = mainEnchant == 6245
        local apocalypse = Data.runeforges and Data.runeforges[6245]
        local name = apocalypse and select(1, GetSpellData(apocalypse.spellID, apocalypse.fallbackName)) or T("Rune of Apocalypse")
        detail = T("Unholy: %s", tostring(name))
    else
        ready = current.ready == true
    end

    return { ready=ready, known=true, detail=detail, current=current, dualWield=dual }
end

function addon:GetPreparationEnchantState(entry)
    if not entry then return false, false end
    local slots = entry.slotIDs or (entry.slotID and { entry.slotID }) or {}
    local seen = 0
    local unknown = 0
    local enchanted = 0
    for _, slotID in ipairs(slots) do
        local itemID, itemLink = GetEquippedItemData(slotID)
        if itemID or itemLink then
            seen = seen + 1
            local hasEnchant, known = self:GetPermanentEnchantState(slotID)
            if not known then
                unknown = unknown + 1
            elseif hasEnchant then
                enchanted = enchanted + 1
            end
        end
    end
    if seen == 0 then return false, false end
    if unknown > 0 then return false, true end
    return enchanted == seen, false
end

function addon:IsPreparationEntryOwned(entry)
    return entry and entry.itemID and self:GetGearTargetOwnedCount(entry.itemID) > 0 or false
end

function addon:IsPreparationCategoryOwned(entries)
    for _, entry in ipairs(entries or {}) do
        if self:IsPreparationEntryOwned(entry) then return true end
    end
    return false
end

function addon:GetPreparationReadyStatus(specID)
    local spec = self:GetPreparationSpec(specID)
    if not spec then return { score=0, total=0, checks={} } end
    local checks = {}
    local score = 0
    local waiting = 0
    local function Add(key, label, ready, detail, isWaiting)
        if ready then score = score + 1 end
        if isWaiting then waiting = waiting + 1 end
        checks[#checks + 1] = { key=key, label=label, ready=ready == true, waiting=isWaiting == true, detail=detail }
    end

    local rune = self:GetRecommendedRuneforgeStatus(specID)
    Add("runeforge", T("Runeforge"), rune.ready, rune.detail, rune.known == false)

    local missing, unknown = self:GetCommonEnchantCoverage()
    Add("enchants", T("Enchants"), #missing == 0 and unknown == 0,
        #missing > 0 and T("Missing: %s", table.concat(missing, ", ")) or (unknown > 0 and T("Waiting for item data (%d)", unknown) or T("All common enchant slots have an enchant")),
        unknown > 0)

    local emptySockets, socketUnknown = self:CountEmptySocketsOnEquippedItems()
    Add("sockets", T("Sockets / gems"), emptySockets == 0 and socketUnknown == 0,
        emptySockets == nil and T("Socket information unavailable") or (emptySockets > 0 and T("%d empty socket(s)", emptySockets) or (socketUnknown > 0 and T("%d item(s) still loading", socketUnknown) or T("No empty sockets detected"))),
        emptySockets == nil or socketUnknown > 0)

    local consumables = spec.consumables or {}
    local categories = {
        { "flask", T("Flask"), consumables.flask },
        { "combatPotion", T("Combat potion"), consumables.combatPotion },
        { "healthPotion", T("Health potion"), consumables.healthPotion },
        { "weaponBuff", T("Weapon buff"), consumables.weaponBuff },
        { "augmentRune", T("Augment rune"), consumables.augmentRune },
        { "food", T("Food"), consumables.food },
    }
    for _, category in ipairs(categories) do
        local owned = self:IsPreparationCategoryOwned(category[3])
        Add(category[1], category[2], owned, owned and T("Ready in bags") or T("Recommended consumable not found in bags"), false)
    end

    return { score=score, total=#checks, checks=checks, waiting=waiting, runeforge=rune }
end

function addon:HidePreparationTooltip(owner)
    if not GameTooltip then return end
    if not owner or not GameTooltip.IsOwned or GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
    local root = mainFrame and mainFrame.guideSection and mainFrame.guideSection.gearVisual
    if root and (not owner or root.tooltipOwner == owner) then root.tooltipOwner = nil end
end

function addon:ShowPreparationTooltip(owner, entry)
    if not GameTooltip or not owner or not entry then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local shown = false
    if entry.spellID and GameTooltip.SetSpellByID then
        shown = pcall(GameTooltip.SetSpellByID, GameTooltip, tonumber(entry.spellID))
    elseif entry.itemID then
        shown = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. tostring(entry.itemID))
    end
    if not shown then GameTooltip:SetText(T(entry.fallbackName or "Preparation recommendation")) end
    GameTooltip:AddLine(" ")
    if entry.slot then GameTooltip:AddLine(T("Category: %s", T(entry.slot)), 0.55, 0.84, 0.95, true) end
    if entry.priority then GameTooltip:AddLine(T("Priority: %s", T(entry.priority)), 1.00, 0.82, 0.35, true) end
    if entry.reason then GameTooltip:AddLine(T(entry.reason), 0.96, 0.96, 0.96, true) end
    GameTooltip:Show()
    local root = mainFrame and mainFrame.guideSection and mainFrame.guideSection.gearVisual
    if root then root.tooltipOwner = owner end
end

function addon:AcquirePreparationCard(root)
    root.prepPool = root.prepPool or {}
    root.prepUsed = (root.prepUsed or 0) + 1
    local card = root.prepPool[root.prepUsed]
    if not card then
        card = CreateFrame("Button", nil, root, "BackdropTemplate")
        card:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
        card.iconFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
        card.iconFrame:SetSize(44, 44)
        card.iconFrame:SetPoint("LEFT", card, "LEFT", 7, 0)
        card.iconFrame:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=2 })
        card.iconFrame:SetBackdropColor(0.01, 0.025, 0.035, 1)
        card.icon = card.iconFrame:CreateTexture(nil, "ARTWORK")
        card.icon:SetPoint("TOPLEFT", card.iconFrame, "TOPLEFT", 3, -3)
        card.icon:SetPoint("BOTTOMRIGHT", card.iconFrame, "BOTTOMRIGHT", -3, 3)
        card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 59, -7)
        card.name:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -5)
        card.name:SetHeight(28)
        card.name:SetJustifyH("LEFT")
        card.name:SetJustifyV("TOP")
        card.name:SetWordWrap(true)
        card.meta = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.meta:SetPoint("TOPLEFT", card, "TOPLEFT", 59, -37)
        card.meta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -35)
        card.meta:SetHeight(16)
        card.meta:SetJustifyH("LEFT")
        card.meta:SetTextColor(0.80, 0.89, 0.94)
        card.status = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.status:SetPoint("TOPLEFT", card, "TOPLEFT", 59, -55)
        card.status:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 5)
        card.status:SetJustifyH("LEFT")
        card.status:SetJustifyV("TOP")
        card.status:SetWordWrap(true)
        card:EnableMouse(true)
        card:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.045, 0.13, 0.17, 0.98)
            self:SetBackdropBorderColor(0.30, 0.74, 0.90, 1)
            addon:ShowPreparationTooltip(self, self.entry)
        end)
        card:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.018, 0.055, 0.075, 0.90)
            if self.baseBorder then self:SetBackdropBorderColor(unpack(self.baseBorder)) end
            addon:HidePreparationTooltip(self)
        end)
        card:SetScript("OnHide", function(self) addon:HidePreparationTooltip(self) end)
        root.prepPool[root.prepUsed] = card
    end
    card:ClearAllPoints()
    card:SetBackdropColor(0.018, 0.055, 0.075, 0.90)
    card:Show()
    return card
end

function addon:GetPreparationEntryState(entry, specID)
    if not entry then return "recommended", T("RECOMMENDED") end
    if entry.kind == "runeforge" then
        local current = self:GetRuneforgeStatus()
        local enchantID = tonumber(entry.enchantID)
        local applied = false
        if specID == 251 and current.dualWield then
            if enchantID == 3368 then applied = current.off and tonumber(current.off.enchantID) == enchantID
            else applied = current.main and tonumber(current.main.enchantID) == enchantID end
        else
            applied = current.main and tonumber(current.main.enchantID) == enchantID
        end
        return applied and "ready" or "recommended", applied and T("APPLIED") or T("RECOMMENDED")
    elseif entry.kind == "enchant" then
        local applied, unknown = self:GetPreparationEnchantState(entry)
        if applied then return "ready", T("APPLIED") end
        if unknown then return "waiting", T("CHECKING") end
        if self:IsPreparationEntryOwned(entry) then return "owned", T("IN BAG") end
        return "missing", T("MISSING")
    elseif entry.kind == "gem" then
        if self:IsPreparationEntryOwned(entry) then return "owned", T("IN BAG") end
        return "recommended", T("RECOMMENDED")
    else
        if self:IsPreparationEntryOwned(entry) then return "owned", T("IN BAG") end
        return "missing", T("MISSING")
    end
end

function addon:ConfigurePreparationCard(card, entry, specID, width, height)
    local cardWidth = width or 290
    local minHeight = math.max(height or 76, 86)
    card:SetWidth(cardWidth)
    card.entry = entry
    local state, label = self:GetPreparationEntryState(entry, specID)
    local border = state == "ready" and {0.22,0.72,0.42,0.95} or (state == "owned" and {0.22,0.60,0.76,0.95} or (state == "waiting" and {0.70,0.60,0.22,0.92} or {0.52,0.42,0.18,0.92}))
    card.baseBorder = border
    card:SetBackdropBorderColor(unpack(border))
    local name, icon
    if entry.spellID then
        name, icon = GetSpellData(entry.spellID, entry.fallbackName)
        card.iconFrame:SetBackdropBorderColor(0.35, 0.72, 0.88, 1)
        card.name:SetTextColor(0.70, 0.90, 1.00)
    else
        name = self:GetGearTargetName(entry)
        icon = self:GetGearTargetIcon(entry)
        local r,g,b = self:GetGearTargetQualityColor(entry)
        card.iconFrame:SetBackdropBorderColor(r,g,b,1)
        card.name:SetTextColor(r,g,b)
    end
    card.icon:SetTexture(icon or QUESTION_MARK_ICON)
    card.iconFrame:ClearAllPoints()
    card.iconFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 7, -10)
    local textWidth = math.max(150, cardWidth - 67)
    card.name:ClearAllPoints()
    card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 59, -8)
    local nameHeight = self:SetGearTextBlockHeight(card.name, textWidth, name or T(entry.fallbackName or "Preparation recommendation"), 18)
    card.meta:ClearAllPoints()
    card.meta:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
    local metaHeight = self:SetGearTextBlockHeight(card.meta, textWidth, T("%s • %s", T(entry.slot or "Preparation"), T(entry.priority or "RECOMMENDED")), 14)
    card.status:ClearAllPoints()
    card.status:SetPoint("TOPLEFT", card.meta, "BOTTOMLEFT", 0, -4)
    local statusHeight = self:SetGearTextBlockHeight(card.status, textWidth, label, 16)
    if state == "ready" then card.status:SetTextColor(0.40,1.00,0.60)
    elseif state == "owned" then card.status:SetTextColor(0.42,0.82,1.00)
    elseif state == "waiting" then card.status:SetTextColor(1.00,0.82,0.35)
    elseif state == "missing" then card.status:SetTextColor(1.00,0.48,0.42)
    else card.status:SetTextColor(1.00,0.82,0.35) end
    local finalHeight = math.max(minHeight, 18 + nameHeight + metaHeight + statusHeight + 18)
    card:SetHeight(finalHeight)
    return finalHeight
end

function addon:AcquireGearTierCard(root)
    root.tierUsed = (root.tierUsed or 0) + 1
    local card = root.tierPool[root.tierUsed]
    if not card then
        card = CreateFrame("Button", nil, root, "BackdropTemplate")
        card:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
        card:EnableMouse(true)
        card.icon = card:CreateTexture(nil, "ARTWORK")
        card.icon:SetSize(38, 38)
        card.icon:SetPoint("LEFT", card, "LEFT", 6, 0)
        card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card.label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.label:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 6, -3)
        card.label:SetPoint("TOPRIGHT", card, "TOPRIGHT", -5, -3)
        card.label:SetJustifyH("LEFT")
        card.label:SetWordWrap(false)
        card.state = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.state:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 6, 3)
        card.state:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -5, 3)
        card.state:SetJustifyH("LEFT")
        card.ResetGearHover = function(self)
            self:SetBackdropColor(0.018, 0.055, 0.075, 0.92)
            addon:HideGearTooltip(self)
        end
        card:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.045, 0.13, 0.17, 0.98)
            addon:ShowGearItemTooltip(self, self.target, self.itemLinkOverride)
        end)
        card:SetScript("OnLeave", function(self) self:ResetGearHover() end)
        card:SetScript("OnHide", function(self) addon:HideGearTooltip(self) end)
        root.tierPool[root.tierUsed] = card
    end
    card:ClearAllPoints()
    card.target = nil
    card.itemLinkOverride = nil
    card:SetBackdropColor(0.018, 0.055, 0.075, 0.92)
    card:SetBackdropBorderColor(0.14, 0.40, 0.52, 0.86)
    card:Show()
    return card
end

function addon:ConfigureGearTierCard(card, piece, equippedLinks, width)
    card:SetSize(width or 128, 50)
    local target = {
        itemID = piece.itemID,
        fallbackName = piece.fallbackName,
        slot = piece.slot,
        source = "Season 2: Raid / Great Vault / Catalyst",
        reason = "Part of the Death Knight Season 2 class set. Four equipped pieces activate the full tier bonus.",
    }
    card.target = target
    local slotID = tonumber(piece.inventorySlot)
    local equippedLink = equippedLinks and equippedLinks[slotID] or nil
    local state = equippedLink and "equipped" or (self:GetGearTargetOwnedCount(piece.itemID) > 0 and "owned" or "missing")
    if equippedLink then card.itemLinkOverride = equippedLink end
    card.icon:SetTexture(self:GetGearTargetIcon(target))
    local qr, qg, qb = self:GetGearTargetQualityColor(target)
    card.label:SetText(T(piece.slot or "Gear"))
    card.label:SetTextColor(0.90, 0.95, 0.98)
    if state == "equipped" then
        card.state:SetText(T("EQUIPPED"))
        card.state:SetTextColor(0.40, 1.00, 0.60)
        card:SetBackdropBorderColor(0.22, 0.72, 0.42, 0.95)
    elseif state == "owned" then
        card.state:SetText(T("OWNED"))
        card.state:SetTextColor(0.42, 0.82, 1.00)
        card:SetBackdropBorderColor(0.22, 0.60, 0.76, 0.95)
    else
        card.state:SetText(T("TARGET"))
        card.state:SetTextColor(1.00, 0.82, 0.35)
        card:SetBackdropBorderColor(qr, qg, qb, 0.88)
    end
end

function addon:AcquireGearBonusCard(root)
    root.bonusUsed = (root.bonusUsed or 0) + 1
    local card = root.bonusPool[root.bonusUsed]
    if not card then
        card = CreateFrame("Button", nil, root, "BackdropTemplate")
        card:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
        card:EnableMouse(true)
        card.label = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card.label:SetPoint("LEFT", card, "LEFT", 10, 0)
        card.label:SetPoint("RIGHT", card, "RIGHT", -10, 0)
        card.label:SetJustifyH("LEFT")
        card.ResetGearHover = function(self)
            self:SetBackdropColor(0.018, 0.055, 0.075, 0.92)
            addon:HideGearTooltip(self)
        end
        card:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.045, 0.13, 0.17, 0.98)
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(addon:GetTierSetName())
                GameTooltip:AddLine(self.bonusTitle or "", self.active and 0.40 or 1.00, self.active and 1.00 or 0.78, self.active and 0.60 or 0.35, true)
                GameTooltip:AddLine(self.bonusText or "", 0.96, 0.96, 0.96, true)
                GameTooltip:Show()
                root.tooltipOwner = self
            end
        end)
        card:SetScript("OnLeave", function(self) self:ResetGearHover() end)
        card:SetScript("OnHide", function(self) addon:HideGearTooltip(self) end)
        root.bonusPool[root.bonusUsed] = card
    end
    card:ClearAllPoints()
    card:SetBackdropColor(0.018, 0.055, 0.075, 0.92)
    card:Show()
    return card
end

function addon:ConfigureGearBonusCard(card, piecesRequired, equippedCount, bonusText, width)
    local active = (equippedCount or 0) >= piecesRequired
    card:SetSize(width or 330, 34)
    card.active = active
    card.bonusTitle = T("%d-piece bonus: %s", piecesRequired, active and T("ACTIVE") or T("INACTIVE"))
    card.bonusText = T(bonusText or "")
    card.label:SetText(card.bonusTitle)
    if active then
        card.label:SetTextColor(0.48, 1.00, 0.66)
        card:SetBackdropBorderColor(0.22, 0.72, 0.42, 0.95)
    else
        card.label:SetTextColor(0.96, 0.91, 0.78)
        card:SetBackdropBorderColor(0.50, 0.40, 0.18, 0.86)
    end
end

function addon:EnsureGearMentorVisual()
    local guide = mainFrame and mainFrame.guideSection
    if not guide or not guide.content then return nil end
    if guide.gearVisual then return guide.gearVisual end

    local root = CreateFrame("Frame", nil, guide.content)
    root:SetPoint("TOPLEFT", guide.content, "TOPLEFT", 2, 0)
    root:SetPoint("TOPRIGHT", guide.content, "TOPRIGHT", -13, 0)
    root:SetHeight(1)
    root.itemPool = {}
    root.panelPool = {}
    root.textPool = {}
    root.metricPool = {}
    root.tierPool = {}
    root.bonusPool = {}
    root.prepPool = {}
    root:SetScript("OnUpdate", function(self)
        local owner = self.tooltipOwner
        if not owner or not GameTooltip then return end
        if GameTooltip.IsOwned and not GameTooltip:IsOwned(owner) then
            self.tooltipOwner = nil
            return
        end
        if owner.IsMouseOver then
            local ok, over = pcall(owner.IsMouseOver, owner)
            if ok and not over then
                if owner.ResetGearHover then owner:ResetGearHover() else addon:HideGearTooltip(owner) end
            end
        end
    end)
    root:SetScript("OnHide", function(self) addon:HideGearTooltip(self.tooltipOwner) end)
    root:Hide()
    guide.gearVisual = root
    return root
end

function addon:RenderGearMentorVisual(specID, viewKey)
    local root = self:EnsureGearMentorVisual()
    if not root then return nil end
    local spec = GearData and GearData.specs and GearData.specs[specID] or nil
    if not spec then return nil end
    viewKey = tostring(viewKey or "overview")
    if viewKey == "plan" then viewKey = "upgrades" end
    self:ResetGearVisual(root)
    root:Show()

    local targets = spec.targets or {}
    local y = 0
    local rootParent = root:GetParent()
    local availableWidth = (rootParent and rootParent:GetWidth()) or root:GetWidth() or 0
    if not availableWidth or availableWidth < 620 then availableWidth = root:GetWidth() or 760 end
    root:SetWidth(availableWidth)
    local contentWidth = math.max(620, math.floor(availableWidth - 4))
    local splitGap = 10
    local splitWidth = math.floor((contentWidth - splitGap) / 2)
    local metricGap = 8
    local metricWidth = math.floor((contentWidth - (metricGap * 3)) / 4)
    local tierGap = 6
    local tierCardWidth = math.floor((contentWidth - 16 - (tierGap * 4)) / 5)
    local bonusGap = 8
    local bonusWidth = math.floor((contentWidth - 24) / 2)

    local title = self:AcquireGearText(root, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    title:SetWidth(contentWidth)
    title:SetHeight(24)
    title:SetTextColor(0.55, 0.88, 1.00)

    local hint = self:AcquireGearText(root, "GameFontHighlightSmall")
    hint:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, y - 3)
    hint:SetWidth(math.min(230, math.floor(contentWidth * 0.36)))
    hint:SetHeight(18)
    hint:SetJustifyH("RIGHT")
    hint:SetText(T("Hover for item details"))
    hint:SetTextColor(0.82, 0.90, 0.96)
    y = y - 32

    local function AddSectionLabel(label)
        local text = self:AcquireGearText(root, "GameFontNormal")
        text:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
        text:SetWidth(contentWidth)
        text:SetHeight(20)
        text:SetTextColor(0.92, 0.80, 0.45)
        text:SetText(T(label))
        y = y - 25
        return text
    end

    local function AddItemGrid(list, cardHeight)
        local h = math.max(cardHeight or 60, 86)
        local columns = contentWidth >= 560 and 2 or 1
        local cardWidth = columns == 2 and math.floor((contentWidth - splitGap) / 2) or contentWidth
        local placements, rowHeights = {}, {}
        local maxRow = 0
        for index, target in ipairs(list or {}) do
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns) + 1
            maxRow = math.max(maxRow, row)
            local card = self:AcquireGearItemCard(root)
            local actualHeight = self:ConfigureGearItemCard(card, target, cardWidth, h) or h
            rowHeights[row] = math.max(rowHeights[row] or 0, actualHeight)
            placements[#placements + 1] = { card = card, col = col, row = row }
        end
        local rowOffsets, totalHeight = {}, 0
        for row = 1, maxRow do
            rowOffsets[row] = totalHeight
            totalHeight = totalHeight + (rowHeights[row] or h) + 8
        end
        for _, placement in ipairs(placements) do
            placement.card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + placement.col * (cardWidth + splitGap), y - (rowOffsets[placement.row] or 0))
        end
        y = y - totalHeight
    end

    local function AddPreparationGrid(list, cardHeight)
        local h = math.max(cardHeight or 76, 86)
        local columns = contentWidth >= 560 and 2 or 1
        local cardWidth = columns == 2 and math.floor((contentWidth - splitGap) / 2) or contentWidth
        local placements, rowHeights = {}, {}
        local maxRow = 0
        for index, entry in ipairs(list or {}) do
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns) + 1
            maxRow = math.max(maxRow, row)
            local card = self:AcquirePreparationCard(root)
            local actualHeight = self:ConfigurePreparationCard(card, entry, specID, cardWidth, h) or h
            rowHeights[row] = math.max(rowHeights[row] or 0, actualHeight)
            placements[#placements + 1] = { card = card, col = col, row = row }
        end
        local rowOffsets, totalHeight = {}, 0
        for row = 1, maxRow do
            rowOffsets[row] = totalHeight
            totalHeight = totalHeight + (rowHeights[row] or h) + 8
        end
        for _, placement in ipairs(placements) do
            placement.card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + placement.col * (cardWidth + splitGap), y - (rowOffsets[placement.row] or 0))
        end
        y = y - totalHeight
    end

    local function AddReadablePanelRow(textValue, minHeight)
        local panel = self:AcquireGearPanel(root)
        panel:SetWidth(contentWidth)
        panel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
        local text = self:AcquireGearPanelText(panel, "GameFontNormalSmall")
        text:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -9)
        text:SetWidth(contentWidth - 20)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
        text:SetWordWrap(true)
        text:SetTextColor(0.94, 0.97, 0.99)
        text:SetHeight(1)
        text:SetText("• " .. T(textValue or ""))
        local stringHeight = text.GetStringHeight and text:GetStringHeight() or 28
        local panelHeight = math.max(minHeight or 42, math.ceil(stringHeight or 28) + 20)
        text:SetHeight(panelHeight - 16)
        panel:SetHeight(panelHeight)
        y = y - panelHeight - 7
        return panelHeight
    end

    local function AddSourceNote()
        y = y - 2
        local note = self:AcquireGearText(root, "GameFontHighlightSmall")
        note:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
        note:SetWidth(contentWidth)
        note:SetHeight(1)
        note:SetWordWrap(true)
        local freshness = DKM.AdvisorData and DKM.AdvisorData.freshness and DKM.AdvisorData.freshness.gear and DKM.AdvisorData.freshness.gear[specID] or "current"
        local freshnessLabel = freshness == "review" and T("REVIEW PENDING") or T("CURRENT")
        if freshness == "review" then note:SetTextColor(1.00, 0.78, 0.28) else note:SetTextColor(0.72, 0.92, 0.82) end
        note:SetText(T("Data status: %s • reviewed %s • source updated %s", freshnessLabel, tostring(GearData.reviewed or "-"), tostring(spec.sourceUpdated or "-")) .. "\n" .. T(GearData.sourceNote or "Guide-backed targets are a farming reference, not a replacement for simming your character."))
        local noteHeight = math.max(46, math.ceil((note.GetStringHeight and note:GetStringHeight()) or 40) + 4)
        note:SetHeight(noteHeight)
        y = y - noteHeight - 6
    end

    if viewKey == "targets" then
        title:SetText(T("Recommended gear targets"))
        AddItemGrid(targets, 62)
        local tier = GearData and GearData.tierSet or nil
        if tier then
            AddSectionLabel("Season 2 tier set")
            local tierCount, equippedTierLinks = self:GetEquippedTierSetState()
            local setPanel = self:AcquireGearPanel(root)
            setPanel:SetSize(contentWidth, 84)
            setPanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
            local setName = self:AcquireGearPanelText(setPanel, "GameFontNormal")
            setName:SetPoint("TOPLEFT", setPanel, "TOPLEFT", 9, -7)
            setName:SetWidth(contentWidth - 170)
            setName:SetHeight(20)
            setName:SetTextColor(0.92, 0.95, 0.98)
            setName:SetText(self:GetTierSetName())
            local progress = self:AcquireGearPanelText(setPanel, "GameFontHighlightSmall")
            progress:SetPoint("TOPRIGHT", setPanel, "TOPRIGHT", -9, -9)
            progress:SetWidth(150)
            progress:SetHeight(18)
            progress:SetJustifyH("RIGHT")
            progress:SetTextColor(tierCount >= 4 and 0.40 or 1.00, tierCount >= 4 and 1.00 or 0.82, tierCount >= 4 and 0.60 or 0.35)
            progress:SetText(T("%d/5 equipped", tierCount))
            for index, piece in ipairs(tier.pieces or {}) do
                local tierCard = self:AcquireGearTierCard(root)
                self:ConfigureGearTierCard(tierCard, piece, equippedTierLinks, tierCardWidth)
                tierCard:SetPoint("TOPLEFT", setPanel, "TOPLEFT", 8 + (index - 1) * (tierCardWidth + tierGap), -29)
            end
            y = y - 94
        end
        if spec.catalyst and #spec.catalyst > 0 then
            AddSectionLabel("Catalyst plan")
            local catalystLines = {}
            for _, entry in ipairs(spec.catalyst) do
                catalystLines[#catalystLines + 1] = T("%s — %s", T(entry.slot or "Gear"), T(entry.source or "Unknown source"))
            end
            AddReadablePanelRow(table.concat(catalystLines, "\n"), 92)
        end
        AddSourceNote()
    elseif viewKey == "preparation" then
        title:SetText(T("Preparation & Ready Check"))
        hint:SetText(T("Hover for native WoW details"))
        local prep = self:GetPreparationSpec(specID)
        local readiness = self:GetPreparationReadyStatus(specID)
        local scoreColor = readiness.score == readiness.total and {0.40,1.00,0.60} or (readiness.score >= math.max(1, readiness.total - 2) and {1.00,0.82,0.35} or {1.00,0.48,0.42})
        local metrics = {
            { T("Preparation"), string.format("%d / %d", readiness.score or 0, readiness.total or 0), scoreColor[1], scoreColor[2], scoreColor[3] },
            { T("Runeforge"), readiness.runeforge and readiness.runeforge.ready and T("READY") or T("CHECK"), readiness.runeforge and readiness.runeforge.ready and 0.40 or 1.00, readiness.runeforge and readiness.runeforge.ready and 1.00 or 0.72, readiness.runeforge and readiness.runeforge.ready and 0.60 or 0.32 },
            { T("Enchants"), (function() local m,u=self:GetCommonEnchantCoverage(); return (#m==0 and u==0) and T("READY") or (#m>0 and T("%d missing", #m) or T("CHECK")) end)(), 0.42,0.82,1.00 },
            { T("Sockets / gems"), (function() local e,u=self:CountEmptySocketsOnEquippedItems(); return e==0 and u==0 and T("READY") or (type(e)=="number" and e>0 and T("%d empty", e) or T("CHECK")) end)(), 0.42,0.82,1.00 },
        }
        for index, data in ipairs(metrics) do
            local card = self:AcquireGearMetric(root)
            card:SetSize(metricWidth, 56)
            card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + (index - 1) * (metricWidth + metricGap), y)
            card.label:SetText(data[1])
            card.value:SetText(data[2])
            card.value:SetTextColor(data[3], data[4], data[5])
        end
        y = y - 70

        local summaryPanel = self:AcquireGearPanel(root)
        summaryPanel:SetWidth(contentWidth)
        summaryPanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
        local summaryTitle = self:AcquireGearPanelText(summaryPanel, "GameFontNormal")
        summaryTitle:SetPoint("TOPLEFT", summaryPanel, "TOPLEFT", 10, -8)
        summaryTitle:SetWidth(contentWidth - 20)
        summaryTitle:SetTextColor(scoreColor[1], scoreColor[2], scoreColor[3])
        local summaryTitleText = readiness.score == readiness.total and T("READY FOR ENDGAME") or T("PREPARATION NEEDS ATTENTION")
        local summaryTitleHeight = self:SetGearTextBlockHeight(summaryTitle, contentWidth - 20, summaryTitleText, 18)
        local summaryText = self:AcquireGearPanelText(summaryPanel, "GameFontHighlightSmall")
        summaryText:SetPoint("TOPLEFT", summaryTitle, "BOTTOMLEFT", 0, -4)
        summaryText:SetWidth(contentWidth - 20)
        local summaryTextHeight = self:SetGearTextBlockHeight(summaryText, contentWidth - 20, T("Read-only checklist: DK Mentor never applies enchants, gems, runes, or consumables automatically."), 16)
        local summaryPanelHeight = math.max(62, 18 + summaryTitleHeight + summaryTextHeight)
        summaryPanel:SetHeight(summaryPanelHeight)
        y = y - summaryPanelHeight - 10

        if prep then
            AddSectionLabel("Runeforge")
            local runeEntries = {}
            local dual = self:GetRuneforgeStatus().dualWield == true
            local shattering = IsSpellKnownSafe(207057)
            if specID == 251 and dual then
                -- Frost dual wield is a pair, not two unrelated alternatives.
                -- Present Main Hand first and Off Hand second so the player can
                -- immediately see which rune belongs on each equipped weapon.
                local mainEnchantID = shattering and 3370 or 3847
                local mainSource
                local offSource
                for _, entry in ipairs(prep.runeforge or {}) do
                    if tonumber(entry.enchantID) == mainEnchantID and entry.mode ~= "twohand" then mainSource = entry end
                    if tonumber(entry.enchantID) == 3368 then offSource = entry end
                end
                if mainSource then
                    runeEntries[#runeEntries + 1] = {
                        kind=mainSource.kind, spellID=mainSource.spellID, enchantID=mainSource.enchantID,
                        fallbackName=mainSource.fallbackName, slot="Main hand", priority="RECOMMENDED", reason=mainSource.reason,
                    }
                end
                if offSource then
                    runeEntries[#runeEntries + 1] = {
                        kind=offSource.kind, spellID=offSource.spellID, enchantID=offSource.enchantID,
                        fallbackName=offSource.fallbackName, slot="Off hand", priority="RECOMMENDED", reason=offSource.reason,
                    }
                end
            else
                for _, entry in ipairs(prep.runeforge or {}) do
                    local include = true
                    if specID == 251 and not dual then
                        include = tonumber(entry.enchantID) == 3368 or entry.mode == "twohand"
                    end
                    if include then runeEntries[#runeEntries + 1] = entry end
                end
            end
            AddPreparationGrid(runeEntries, 86)

            AddSectionLabel("Enchants")
            local enchants = {}
            for _, entry in ipairs(DKM.PreparationData.commonEnchants or {}) do enchants[#enchants+1] = entry end
            if prep.ringEnchant then enchants[#enchants+1] = prep.ringEnchant end
            if prep.ringAlternative then enchants[#enchants+1] = prep.ringAlternative end
            AddPreparationGrid(enchants, 86)

            AddSectionLabel("Gems")
            AddPreparationGrid(prep.gems or {}, 86)

            AddSectionLabel("Consumables")
            local ordered = { "flask", "combatPotion", "healthPotion", "weaponBuff", "augmentRune", "food" }
            local consumableEntries = {}
            for _, key in ipairs(ordered) do
                local entries = prep.consumables and prep.consumables[key] or nil
                if entries and entries[1] then consumableEntries[#consumableEntries+1] = entries[1] end
            end
            AddPreparationGrid(consumableEntries, 86)

            y = y - 2
            local note = self:AcquireGearText(root, "GameFontHighlightSmall")
            note:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
            note:SetWidth(contentWidth)
            note:SetHeight(1)
            note:SetWordWrap(true)
            note:SetTextColor(0.78,0.87,0.92)
            note:SetText(T("Enchant readiness checks whether a permanent enchant is present; the recommended cards show the current guide choice. Gem readiness checks empty sockets because the live API does not safely prove every socketed recommendation in all states."))
            local prepNoteHeight = math.max(44, math.ceil((note.GetStringHeight and note:GetStringHeight()) or 40) + 4)
            note:SetHeight(prepNoteHeight)
            y = y - prepNoteHeight - 6

            local source = self:AcquireGearText(root, "GameFontHighlightSmall")
            source:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
            source:SetWidth(contentWidth)
            source:SetHeight(1)
            source:SetWordWrap(true)
            source:SetTextColor(0.72,0.82,0.88)
            source:SetText(T("Preparation data: %s • Patch %s • reviewed %s", DKM.PreparationData.sourceName or "Wowhead", DKM.PreparationData.patch or "?", DKM.PreparationData.reviewed or "?"))
            local prepSourceHeight = math.max(24, math.ceil((source.GetStringHeight and source:GetStringHeight()) or 20) + 4)
            source:SetHeight(prepSourceHeight)
            y = y - prepSourceHeight - 6
        end
    elseif viewKey == "sources" then
        title:SetText(T("Loot sources"))
        local grouped, order = {}, {}
        for _, target in ipairs(targets) do
            local source = tostring(target.source or T("Unknown source"))
            if not grouped[source] then grouped[source], order[#order + 1] = {}, source end
            grouped[source][#grouped[source] + 1] = target
        end
        for _, source in ipairs(order) do
            local group = grouped[source]
            local columns = contentWidth >= 560 and 2 or 1
            local cardWidth = columns == 2 and math.floor((contentWidth - 24) / 2) or (contentWidth - 16)
            local panel = self:AcquireGearPanel(root)
            panel:SetWidth(contentWidth)
            panel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
            local label = self:AcquireGearPanelText(panel, "GameFontNormal")
            label:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -9)
            local labelHeight = self:SetGearTextBlockHeight(label, contentWidth - 20, source, 20)
            label:SetTextColor(0.92, 0.80, 0.45)
            local placements, rowHeights = {}, {}
            local maxRow = 0
            for index, target in ipairs(group) do
                local col = (index - 1) % columns
                local row = math.floor((index - 1) / columns) + 1
                maxRow = math.max(maxRow, row)
                local card = self:AcquireGearItemCard(root)
                local actualHeight = self:ConfigureGearItemCard(card, target, cardWidth, 86) or 86
                rowHeights[row] = math.max(rowHeights[row] or 0, actualHeight)
                placements[#placements + 1] = { card = card, col = col, row = row }
            end
            local rowOffsets, rowsHeight = {}, 0
            for row = 1, maxRow do
                rowOffsets[row] = rowsHeight
                rowsHeight = rowsHeight + (rowHeights[row] or 86) + 8
            end
            local cardsTop = 14 + labelHeight
            for _, placement in ipairs(placements) do
                placement.card:SetPoint("TOPLEFT", panel, "TOPLEFT", 8 + placement.col * (cardWidth + 8), -cardsTop - (rowOffsets[placement.row] or 0))
            end
            local panelHeight = cardsTop + rowsHeight + 8
            panel:SetHeight(panelHeight)
            y = y - panelHeight - 10
        end
        AddSourceNote()
    elseif viewKey == "trinkets" then
        title:SetText(T("Trinkets"))
        local trinkets = {}
        for _, target in ipairs(targets) do if target.slot == "Trinket" then trinkets[#trinkets + 1] = target end end
        AddItemGrid(trinkets, 82)
        AddSectionLabel("Quick guidance")
        for _, row in ipairs(spec.trinkets or {}) do
            AddReadablePanelRow(row, 42)
        end
        AddSourceNote()
    elseif viewKey == "crafting" then
        title:SetText(T("Crafted fallback gear"))
        AddSectionLabel("Recommended crafts")
        local craftTargets = spec.craftTargets or {}
        AddItemGrid(craftTargets, 82)
        y = y - 2
        AddReadablePanelRow("Crafted pieces are a fallback path when key drops have not appeared yet. Hover each item to see the native WoW tooltip and the DK Mentor recommendation.", 48)
        AddSourceNote()
    elseif viewKey == "upgrades" then
        title:SetText(T("Upgrade plan"))
        AddSectionLabel("Crests & upgrades")
        for _, row in ipairs(spec.upgrades or {}) do
            AddReadablePanelRow(row, 44)
        end
        AddSourceNote()
    else
        title:SetText(T("Gear Mentor overview"))
        local ilvl = GetEquippedAverageItemLevel()
        local ready = self:GetReadyCheckStatus()
        local acquired = 0
        for _, target in ipairs(targets) do if self:GetGearTargetState(target) ~= "missing" then acquired = acquired + 1 end end
        local tierCount, equippedTierLinks = self:GetEquippedTierSetState()
        local tierColor = tierCount >= 4 and { 0.40, 1.00, 0.60 } or (tierCount >= 2 and { 0.42, 0.82, 1.00 } or { 1.00, 0.82, 0.35 })
        local metrics = {
            { T("Item level"), ilvl and string.format("%.1f", ilvl) or "?", 0.88, 0.96, 1.00 },
            { T("Runeforge"), ready.runeforge and ready.runeforge.ready and T("READY") or T("CHECK"), ready.runeforge and ready.runeforge.ready and 0.40 or 1.00, ready.runeforge and ready.runeforge.ready and 1.00 or 0.72, ready.runeforge and ready.runeforge.ready and 0.60 or 0.32 },
            { T("Targets"), string.format("%d / %d", acquired, #targets), 0.42, 0.82, 1.00 },
            { T("Season 2 set"), string.format("%d / 5", tierCount), tierColor[1], tierColor[2], tierColor[3] },
        }
        for index, data in ipairs(metrics) do
            local card = self:AcquireGearMetric(root)
            card:SetSize(metricWidth, 56)
            card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + (index - 1) * (metricWidth + metricGap), y)
            card.label:SetText(data[1])
            card.value:SetText(data[2])
            card.value:SetTextColor(data[3], data[4], data[5])
        end
        y = y - 70

        AddSectionLabel("Season 2 tier set")
        local tier = GearData and GearData.tierSet or nil
        if tier then
            local setPanel = self:AcquireGearPanel(root)
            setPanel:SetSize(contentWidth, 142)
            setPanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
            local setName = self:AcquireGearPanelText(setPanel, "GameFontNormal")
            setName:SetPoint("TOPLEFT", setPanel, "TOPLEFT", 9, -7)
            setName:SetWidth(contentWidth - 170)
            setName:SetHeight(20)
            setName:SetTextColor(0.92, 0.95, 0.98)
            setName:SetText(self:GetTierSetName())
            local progress = self:AcquireGearPanelText(setPanel, "GameFontHighlightSmall")
            progress:SetPoint("TOPRIGHT", setPanel, "TOPRIGHT", -9, -9)
            progress:SetWidth(150)
            progress:SetHeight(18)
            progress:SetJustifyH("RIGHT")
            progress:SetTextColor(tierColor[1], tierColor[2], tierColor[3])
            progress:SetText(T("%d/5 equipped", tierCount))
            for index, piece in ipairs(tier.pieces or {}) do
                local tierCard = self:AcquireGearTierCard(root)
                self:ConfigureGearTierCard(tierCard, piece, equippedTierLinks, tierCardWidth)
                tierCard:SetPoint("TOPLEFT", setPanel, "TOPLEFT", 8 + (index - 1) * (tierCardWidth + tierGap), -31)
            end
            local bonusData = tier.bonuses and tier.bonuses[specID] or {}
            local two = self:AcquireGearBonusCard(root)
            self:ConfigureGearBonusCard(two, 2, tierCount, bonusData.twoPiece, bonusWidth)
            two:SetPoint("TOPLEFT", setPanel, "TOPLEFT", 8, -82)
            local four = self:AcquireGearBonusCard(root)
            self:ConfigureGearBonusCard(four, 4, tierCount, bonusData.fourPiece, bonusWidth)
            four:SetPoint("TOPLEFT", setPanel, "TOPLEFT", 16 + bonusWidth, -82)
            y = y - 152
        end

        AddSectionLabel("Recommended gear")
        AddItemGrid(targets, 58)

        AddSectionLabel("Stat direction")
        local codexSpec = DKM.Codex and DKM.Codex.specs and DKM.Codex.specs[specID]
        local firstStats = codexSpec and codexSpec.stats and codexSpec.stats[1] or nil
        local statPanel = self:AcquireGearPanel(root)
        statPanel:SetWidth(contentWidth)
        statPanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
        local priority = self:AcquireGearPanelText(statPanel, "GameFontNormal")
        priority:SetPoint("TOPLEFT", statPanel, "TOPLEFT", 10, -9)
        priority:SetTextColor(0.92, 0.80, 0.45)
        local priorityHeight = self:SetGearTextBlockHeight(priority, contentWidth - 20, firstStats and self:FirstGearSentence(T(firstStats.body or "")) or T("Simulate close upgrades."), 21)
        local stats = self:GetCurrentStatSnapshot()
        local current = self:AcquireGearPanelText(statPanel, "GameFontHighlightSmall")
        current:SetPoint("TOPLEFT", priority, "BOTTOMLEFT", 0, -7)
        current:SetTextColor(0.92, 0.95, 0.97)
        local currentText = T("Current: Crit %s  •  Haste %s  •  Mastery %s  •  Vers %s",
            self:FormatStatPercent(stats.crit), self:FormatStatPercent(stats.haste), self:FormatStatPercent(stats.mastery), self:FormatStatPercent(stats.versatility))
        local currentHeight = self:SetGearTextBlockHeight(current, contentWidth - 20, currentText, 18)
        local statPanelHeight = math.max(68, priorityHeight + currentHeight + 28)
        statPanel:SetHeight(statPanelHeight)
        y = y - statPanelHeight - 10
        AddSourceNote()
    end

    local usedHeight = math.max(1, math.abs(y) + 6)
    root:SetHeight(usedHeight)
    return usedHeight
end

function addon:GetGearMentorReport(specID, viewKey)
    local spec = GearData and GearData.specs and GearData.specs[specID] or nil
    if not spec then return { T("No Gear Mentor data is available for this specialization yet.") } end
    viewKey = tostring(viewKey or "overview")
    if viewKey == "plan" then viewKey = "upgrades" end
    local lines = {}
    local targets = spec.targets or {}

    local function AddHeader(text)
        table.insert(lines, "|cff89d8ff" .. T(text) .. "|r")
    end
    local function AddTarget(target, detailed)
        local state = self:GetGearTargetState(target)
        local statusText, statusColor
        if state == "equipped" then
            statusText, statusColor = T("EQUIPPED"), "|cff66ff99"
        elseif state == "owned" then
            statusText, statusColor = T("OWNED"), "|cff69ccf0"
        else
            statusText, statusColor = target.craft and T("CRAFT") or T("TARGET"), "|cffffcc55"
        end
        local name = self:GetGearTargetName(target)
        table.insert(lines, string.format("%s[%s]|r |cffffcc55[%s]|r %s", statusColor, statusText, T(target.priority or "HIGH"), tostring(name)))
        table.insert(lines, T("%s | %s", T(target.slot or "Gear"), tostring(target.source or "-")))
        if detailed and target.embellishment then
            table.insert(lines, T("Embellishment: %s", T(target.embellishment)))
        end
        if detailed and target.reason then
            table.insert(lines, T(target.reason))
        end
        table.insert(lines, "")
    end

    if viewKey == "targets" then
        AddHeader("Priority targets")
        table.insert(lines, T("These are high-value Season 2 targets, not guaranteed upgrades. DK Mentor marks whether the exact item is equipped, owned, or still a target."))
        table.insert(lines, "")
        for _, target in ipairs(targets) do AddTarget(target, true) end
    elseif viewKey == "sources" then
        AddHeader("Loot sources")
        table.insert(lines, T("Use this view as a short farming route: targets are grouped by the source currently associated with the Season 2 recommendation."))
        table.insert(lines, "")
        local grouped, order = {}, {}
        for _, target in ipairs(targets) do
            local source = tostring(target.source or T("Unknown source"))
            if not grouped[source] then
                grouped[source] = {}
                order[#order + 1] = source
            end
            grouped[source][#grouped[source] + 1] = target
        end
        for _, source in ipairs(order) do
            table.insert(lines, "|cffffcc55" .. source .. "|r")
            for _, target in ipairs(grouped[source]) do
                local state = self:GetGearTargetState(target)
                local stateText = state == "equipped" and T("EQUIPPED") or (state == "owned" and T("OWNED") or T("TARGET"))
                table.insert(lines, string.format("- [%s] %s - %s", stateText, self:GetGearTargetName(target), T(target.slot or "Gear")))
            end
            table.insert(lines, "")
        end
    elseif viewKey == "trinkets" then
        AddHeader("Trinket plan")
        for _, row in ipairs(spec.trinkets or {}) do table.insert(lines, "- " .. T(row)) end
        table.insert(lines, "")
        AddHeader("Tracked headline trinkets")
        for _, target in ipairs(targets) do
            if target.slot == "Trinket" then AddTarget(target, false) end
        end
    elseif viewKey == "crafting" then
        AddHeader("Recommended crafts")
        table.insert(lines, T("Crafted pieces are a fallback path when key drops have not appeared yet. Hover each item to see the native WoW tooltip and the DK Mentor recommendation."))
        table.insert(lines, "")
        for _, target in ipairs(spec.craftTargets or {}) do AddTarget(target, true) end
    elseif viewKey == "upgrades" then
        AddHeader("Crafting plan")
        for _, row in ipairs(spec.crafting or {}) do table.insert(lines, "- " .. T(row)) end
        table.insert(lines, "")
        AddHeader("Crest and upgrade plan")
        for _, row in ipairs(spec.upgrades or {}) do table.insert(lines, "- " .. T(row)) end
        table.insert(lines, "")
        table.insert(lines, "|cff999999" .. T("Upgrade priorities are intentionally broad. Close item choices should be simulated because your current gear can change the answer.") .. "|r")
    else
        local ilvl = GetEquippedAverageItemLevel()
        local ready = self:GetReadyCheckStatus()
        local missingEnchants, enchantUnknown = self:GetCommonEnchantCoverage()
        local emptySockets, socketUnknown = self:CountEmptySocketsOnEquippedItems()
        local acquired = 0
        local nextTarget
        for _, target in ipairs(targets) do
            local state = self:GetGearTargetState(target)
            if state ~= "missing" then acquired = acquired + 1 elseif not nextTarget then nextTarget = target end
        end

        AddHeader("Gear Mentor dashboard")
        table.insert(lines, T("Patch %s | Season data reviewed %s | Source updated %s", tostring(GearData.patch or "?"), tostring(GearData.reviewed or "?"), tostring(spec.sourceUpdated or "?")))
        table.insert(lines, T(spec.summary or ""))
        table.insert(lines, "")
        AddHeader("Live setup snapshot")
        table.insert(lines, T("Equipped item level: %s", ilvl and string.format("%.1f", ilvl) or "?"))
        table.insert(lines, T("Runeforge: %s", ready.runeforge and ready.runeforge.ready and T("READY") or T("CHECK")))
        if #missingEnchants > 0 then
            table.insert(lines, T("Common enchants: %d missing", #missingEnchants))
        elseif enchantUnknown > 0 then
            table.insert(lines, T("Common enchants: waiting for %d item(s)", enchantUnknown))
        else
            table.insert(lines, T("Common enchants: complete"))
        end
        if emptySockets == nil then
            table.insert(lines, T("Sockets: unavailable"))
        elseif emptySockets > 0 then
            table.insert(lines, T("Sockets: %d empty", emptySockets))
        elseif socketUnknown > 0 then
            table.insert(lines, T("Sockets: none empty; %d item(s) still loading", socketUnknown))
        else
            table.insert(lines, T("Sockets: no empty sockets detected"))
        end
        table.insert(lines, T("Headline target progress: %d/%d owned or equipped", acquired, #targets))
        local tierCount = self:GetEquippedTierSetState()
        table.insert(lines, T("Season 2 tier set: %d/5 equipped | 2-piece %s | 4-piece %s", tierCount, tierCount >= 2 and T("ACTIVE") or T("INACTIVE"), tierCount >= 4 and T("ACTIVE") or T("INACTIVE")))
        if specID == 251 then
            local offhand
            if GetInventoryItemID then
                local ok, value = pcall(GetInventoryItemID, "player", _G.INVSLOT_OFFHAND or 17)
                if ok and IsAccessibleNumber(value) then offhand = value end
            end
            table.insert(lines, T("Weapon setup: %s", offhand and T("Dual-wield") or T("Single weapon")))
        end
        table.insert(lines, "")
        AddHeader("Weapon direction")
        table.insert(lines, T(spec.weaponNote or ""))
        table.insert(lines, "")
        AddHeader("Next target")
        if nextTarget then
            AddTarget(nextTarget, true)
        else
            table.insert(lines, "|cff66ff99[OK]|r " .. T("All headline targets in this Season 2 dataset are already owned or equipped."))
            table.insert(lines, "")
        end
        AddHeader("Current stat guidance")
        local codexSpec = DKM.Codex and DKM.Codex.specs and DKM.Codex.specs[specID]
        if codexSpec and codexSpec.stats then
            for index, section in ipairs(codexSpec.stats) do
                if index <= 2 then
                    table.insert(lines, "|cffffcc55" .. T(section.heading or "") .. "|r")
                    table.insert(lines, T(section.body or ""))
                end
            end
        end
    end

    table.insert(lines, "")
    table.insert(lines, "|cff999999" .. T(GearData.sourceNote or "Guide-backed targets are a farming reference, not a replacement for simming your character.") .. "|r")
    return lines
end

function addon:HideBuildTooltip(owner)
    if not GameTooltip then return end
    if not owner or not GameTooltip.IsOwned or GameTooltip:IsOwned(owner) then
        GameTooltip:Hide()
    end
    local root = mainFrame and mainFrame.guideSection and mainFrame.guideSection.buildVisual
    if root and (not owner or root.tooltipOwner == owner) then root.tooltipOwner = nil end
end

function addon:ShowBuildSpellTooltip(owner, spellID, fallbackName)
    spellID = tonumber(spellID)
    if not GameTooltip or not owner or not spellID then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local shown = false
    if GameTooltip.SetSpellByID then
        local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, spellID)
        shown = ok == true
    end
    if not shown then
        local name = select(1, GetSpellData(spellID, fallbackName and T(fallbackName) or fallbackName))
        GameTooltip:SetText(name or T("Talent"))
    end
    GameTooltip:Show()
    local root = mainFrame and mainFrame.guideSection and mainFrame.guideSection.buildVisual
    if root then root.tooltipOwner = owner end
end

function addon:ResetBuildVisual(root)
    if not root then return end
    root.textUsed = 0
    root.panelUsed = 0
    root.profileUsed = 0
    root.talentUsed = 0
    self:HideBuildTooltip(root.tooltipOwner)
    for _, text in ipairs(root.textPool or {}) do text:Hide() end
    for _, panel in ipairs(root.panelPool or {}) do panel:Hide() end
    for _, frame in ipairs(root.profilePool or {}) do frame:Hide() end
    for _, frame in ipairs(root.talentPool or {}) do frame:Hide() end
    if self.ResetBuildTalentTreeVisual then self:ResetBuildTalentTreeVisual(root) end
end

function addon:AcquireBuildTalentCard(root)
    root.talentUsed = (root.talentUsed or 0) + 1
    local card = root.talentPool[root.talentUsed]
    if not card then
        card = CreateFrame("Button", nil, root, "BackdropTemplate")
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        card:SetBackdropColor(0.012, 0.035, 0.050, 0.98)
        card.icon = card:CreateTexture(nil, "ARTWORK")
        card.icon:SetPoint("TOPLEFT", card, "TOPLEFT", 3, -3)
        card.icon:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -3, 3)
        card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card:EnableMouse(true)
        card:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.35, 0.82, 1.00, 1.00)
            addon:ShowBuildSpellTooltip(self, self.spellID, self.fallbackName)
        end)
        card:SetScript("OnLeave", function(self)
            local c = self.baseBorder or { 0.22, 0.52, 0.64, 0.92 }
            self:SetBackdropBorderColor(c[1], c[2], c[3], c[4])
            addon:HideBuildTooltip(self)
        end)
        card:SetScript("OnHide", function(self) addon:HideBuildTooltip(self) end)
        root.talentPool[root.talentUsed] = card
    end
    card:ClearAllPoints()
    card.spellID = nil
    card.fallbackName = nil
    card.baseBorder = { 0.22, 0.52, 0.64, 0.92 }
    card:SetBackdropColor(0.012, 0.035, 0.050, 0.98)
    card:SetBackdropBorderColor(card.baseBorder[1], card.baseBorder[2], card.baseBorder[3], card.baseBorder[4])
    card:Show()
    return card
end

function addon:ConfigureBuildTalentCard(card, talent, size)
    if not card or not talent then return end
    local spellID = tonumber(talent.spellID)
    local _, icon = GetSpellData(spellID, talent.fallbackName and T(talent.fallbackName) or talent.fallbackName)
    card:SetSize(size or 40, size or 40)
    card.spellID = spellID
    card.fallbackName = talent.fallbackName
    card.icon:SetTexture(icon or QUESTION_MARK_ICON)
    card.baseBorder = { 0.20, 0.56, 0.70, 0.92 }
    card:SetBackdropBorderColor(card.baseBorder[1], card.baseBorder[2], card.baseBorder[3], card.baseBorder[4])
end

function addon:AcquireBuildProfileCard(root)
    root.profileUsed = (root.profileUsed or 0) + 1
    local card = root.profilePool[root.profileUsed]
    if not card then
        card = CreateFrame("Frame", nil, root, "BackdropTemplate")
        card:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
        card:SetBackdropColor(0.018, 0.055, 0.075, 0.94)
        card:SetBackdropBorderColor(0.14, 0.42, 0.54, 0.90)

        card.heroButton = CreateFrame("Button", nil, card, "BackdropTemplate")
        card.heroButton:SetSize(46, 46)
        card.heroButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        card.heroButton:SetBackdropColor(0.01, 0.03, 0.045, 1)
        card.heroButton:SetBackdropBorderColor(0.35, 0.72, 0.88, 0.95)
        card.heroButton.icon = card.heroButton:CreateTexture(nil, "ARTWORK")
        card.heroButton.icon:SetPoint("TOPLEFT", card.heroButton, "TOPLEFT", 3, -3)
        card.heroButton.icon:SetPoint("BOTTOMRIGHT", card.heroButton, "BOTTOMRIGHT", -3, 3)
        card.heroButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card.heroButton:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.55, 0.90, 1.00, 1)
            addon:ShowBuildSpellTooltip(self, self.spellID, self.fallbackName)
        end)
        card.heroButton:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.35, 0.72, 0.88, 0.95)
            addon:HideBuildTooltip(self)
        end)
        card.heroButton:SetScript("OnHide", function(self) addon:HideBuildTooltip(self) end)

        card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card.name:SetJustifyH("LEFT")
        card.name:SetTextColor(0.92, 0.95, 0.98)
        card.name:SetWordWrap(true)

        card.badge = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.badge:SetJustifyH("RIGHT")

        card.heroLabel = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.heroLabel:SetJustifyH("LEFT")
        card.heroLabel:SetTextColor(0.55, 0.84, 0.95)

        card.focus = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.focus:SetJustifyH("LEFT")
        card.focus:SetTextColor(0.90, 0.94, 0.97)
        card.focus:SetWordWrap(true)

        card.note = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.note:SetJustifyH("LEFT")
        card.note:SetJustifyV("TOP")
        card.note:SetTextColor(0.88, 0.92, 0.95)
        card.note:SetWordWrap(true)

        card.talentLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.talentLabel:SetJustifyH("LEFT")
        card.talentLabel:SetTextColor(0.92, 0.80, 0.45)

        card.source = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.source:SetJustifyH("LEFT")
        card.source:SetTextColor(0.72, 0.82, 0.88)
        card.source:SetWordWrap(false)

        root.profilePool[root.profileUsed] = card
    end
    card:ClearAllPoints()
    card:SetBackdropColor(0.018, 0.055, 0.075, 0.94)
    card:SetBackdropBorderColor(0.14, 0.42, 0.54, 0.90)
    card:Show()
    return card
end

function addon:ConfigureBuildProfileCard(root, card, profile, width)
    width = width or 560
    local sbaMode = self:GetCodexBuildMode() == "sba"
    local keyTalents = (sbaMode and profile.sbaKeyTalents) or profile.keyTalents or {}
    local note = T((sbaMode and profile.sbaNote) or profile.note or "")
    local talentRows = math.max(1, math.ceil(#keyTalents / 8))

    card.heroButton:ClearAllPoints()
    card.heroButton:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
    card.heroButton.spellID = tonumber(profile.heroSpellID)
    card.heroButton.fallbackName = profile.heroTalent
    local _, heroIcon = GetSpellData(profile.heroSpellID, profile.heroTalent and T(profile.heroTalent) or T("Hero Talent"))
    card.heroButton.icon:SetTexture(heroIcon or QUESTION_MARK_ICON)

    card.name:ClearAllPoints()
    card.name:SetPoint("TOPLEFT", card.heroButton, "TOPRIGHT", 10, -1)
    card.name:SetPoint("TOPRIGHT", card, "TOPRIGHT", -112, -9)
    card.name:SetHeight(36)
    card.name:SetText(T(profile.name or "Build recommendation"))

    card.badge:ClearAllPoints()
    card.badge:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -12)
    card.badge:SetWidth(96)
    local rawBadge = (sbaMode and profile.sbaFriendly == true) and "SBA FRIENDLY" or (profile.badge or "RECOMMENDED")
    local badge = T(rawBadge)
    card.badge:SetText(badge)
    if tostring(rawBadge) == "ALTERNATIVE" then
        card.badge:SetTextColor(0.68, 0.84, 0.96)
    elseif tostring(rawBadge) == "REFERENCE" then
        card.badge:SetTextColor(0.82, 0.88, 0.94)
    else
        card.badge:SetTextColor(0.48, 1.00, 0.66)
    end

    card.heroLabel:ClearAllPoints()
    card.heroLabel:SetPoint("LEFT", card.heroButton, "RIGHT", 10, -13)
    card.heroLabel:SetPoint("RIGHT", card, "RIGHT", -112, 0)
    card.heroLabel:SetHeight(18)
    card.heroLabel:SetText(T("Hero Talent: %s", T(profile.heroTalent or "-")))

    card.focus:ClearAllPoints()
    card.focus:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -64)
    card.focus:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -64)
    card.focus:SetHeight(20)
    card.focus:SetText(T("Focus: %s", T(profile.focus or "-")))

    card.note:ClearAllPoints()
    card.note:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -88)
    card.note:SetWidth(width - 20)
    card.note:SetHeight(200)
    card.note:SetText(note)
    local noteHeight = math.max(34, math.ceil((card.note.GetStringHeight and card.note:GetStringHeight()) or 34))
    card.note:SetHeight(noteHeight)

    local height = 150 + noteHeight + (talentRows * 46)
    card:SetSize(width, height)

    local talentLabelY = -94 - noteHeight
    card.talentLabel:ClearAllPoints()
    card.talentLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 10, talentLabelY)
    card.talentLabel:SetWidth(width - 20)
    card.talentLabel:SetHeight(18)
    card.talentLabel:SetText(T("Key talents"))

    local iconSize = 38
    local iconGap = 7
    local startY = talentLabelY - 21
    for index, talent in ipairs(keyTalents) do
        local icon = self:AcquireBuildTalentCard(root)
        self:ConfigureBuildTalentCard(icon, talent, iconSize)
        local col = (index - 1) % 8
        local row = math.floor((index - 1) / 8)
        icon:SetParent(card)
        icon:SetPoint("TOPLEFT", card, "TOPLEFT", 10 + col * (iconSize + iconGap), startY - row * 46)
        icon:SetFrameLevel(card:GetFrameLevel() + 2)
    end

    card.source:ClearAllPoints()
    card.source:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 8)
    card.source:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 8)
    card.source:SetHeight(16)
    local sourceText = profile.sourceName or ""
    if profile.sourceAuthor and profile.sourceAuthor ~= "" then sourceText = sourceText .. " • " .. profile.sourceAuthor end
    if profile.sourceUpdated and profile.sourceUpdated ~= "" then sourceText = sourceText .. " • " .. T("updated %s", profile.sourceUpdated) end
    local freshness = tostring(profile.freshness or "current")
    local freshnessLabel = freshness == "review" and T("REVIEW PENDING") or T("CURRENT")
    sourceText = sourceText .. " • " .. freshnessLabel
    if freshness == "review" then
        card.source:SetTextColor(1.00, 0.78, 0.28)
    else
        card.source:SetTextColor(0.52, 0.90, 0.68)
    end
    card.source:SetText(sourceText)
    return height
end

function addon:EnsureBuildMentorVisual()
    local guide = mainFrame and mainFrame.guideSection
    if not guide or not guide.content then return nil end
    if guide.buildVisual then return guide.buildVisual end

    local root = CreateFrame("Frame", nil, guide.content)
    root:SetPoint("TOPLEFT", guide.content, "TOPLEFT", 2, 0)
    root:SetPoint("TOPRIGHT", guide.content, "TOPRIGHT", -13, 0)
    root:SetHeight(1)
    root.textPool = {}
    root.panelPool = {}
    root.profilePool = {}
    root.talentPool = {}
    root:SetScript("OnUpdate", function(self)
        local owner = self.tooltipOwner
        if not owner or not GameTooltip then return end
        if GameTooltip.IsOwned and not GameTooltip:IsOwned(owner) then
            self.tooltipOwner = nil
            return
        end
        if owner.IsMouseOver then
            local ok, over = pcall(owner.IsMouseOver, owner)
            if ok and not over then addon:HideBuildTooltip(owner) end
        end
    end)
    root:SetScript("OnHide", function(self) addon:HideBuildTooltip(self.tooltipOwner) end)
    root:Hide()
    guide.buildVisual = root
    return root
end

function addon:RenderBuildMentorVisual(specID, contextKey, autoDetected)
    local root = self:EnsureBuildMentorVisual()
    if not root then return nil end
    local sourceProfiles = self:GetBuildProfiles(specID, contextKey)
    local profiles = {}
    local sourceOrder = {}
    for index, profile in ipairs(sourceProfiles or {}) do
        profiles[#profiles + 1] = profile
        sourceOrder[profile] = index
    end
    if self:GetCodexBuildMode() == "sba" then
        table.sort(profiles, function(a, b)
            local aFriendly = a.sbaFriendly == true
            local bFriendly = b.sbaFriendly == true
            if aFriendly ~= bFriendly then return aFriendly end
            -- Keep the guide's original Recommended/Alternative ordering inside
            -- each accessibility group instead of sorting alphabetically by badge.
            return (sourceOrder[a] or 999) < (sourceOrder[b] or 999)
        end)
    end
    self:ResetBuildVisual(root)
    root:Show()

    local contentWidth = math.max(520, (root:GetWidth() or 570) - 4)
    local y = 0

    local title = self:AcquireGearText(root, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    title:SetWidth(contentWidth)
    title:SetHeight(24)
    title:SetTextColor(0.55, 0.88, 1.00)
    title:SetText(T("Build Mentor — %s", self:GetRuntimeContextLabel(contextKey)))

    local hint = self:AcquireGearText(root, "GameFontHighlightSmall")
    hint:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, y - 3)
    hint:SetWidth(math.min(260, math.floor(contentWidth * 0.48)))
    hint:SetHeight(18)
    hint:SetJustifyH("RIGHT")
    hint:SetText(autoDetected and T("AUTO • following detected content") or T("Manual content selection"))
    hint:SetTextColor(0.80, 0.89, 0.95)
    y = y - 31

    local sub = self:AcquireGearText(root, "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    sub:SetWidth(contentWidth)
    sub:SetHeight(34)
    sub:SetTextColor(0.90, 0.94, 0.97)
    if self:GetCodexBuildMode() == "sba" then
        sub:SetText(T("SBA-friendly guidance favors lower-friction profiles for Blizzard's Single-Button Assistant. Defensives, interrupts, crowd control, utility, and situational choices remain manual."))
    else
        sub:SetText(T("Visual build guidance based on the current guide direction. Hover the talent icons for native WoW details; use the source row above when you want the full guide."))
    end
    y = y - 42

    if #profiles == 0 then
        local panel = self:AcquireGearPanel(root)
        panel:SetSize(contentWidth, 60)
        panel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
        local text = self:AcquireGearPanelText(panel, "GameFontHighlight")
        text:SetPoint("LEFT", panel, "LEFT", 12, 0)
        text:SetPoint("RIGHT", panel, "RIGHT", -12, 0)
        text:SetHeight(36)
        text:SetText(T("No build recommendation is available for this specialization and content."))
        y = y - 70
    else
        for index, profile in ipairs(profiles) do
            local card = self:AcquireBuildProfileCard(root)
            card:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
            local height = self:ConfigureBuildProfileCard(root, card, profile, contentWidth)
            y = y - height - 8
            if self.RenderBuildTalentTreePreview then
                local treeHeight = self:RenderBuildTalentTreePreview(root, specID, profile, contentWidth, y, index) or 0
                if treeHeight > 0 then y = y - treeHeight - 10 end
            else
                y = y - 2
            end
        end
    end

    local footer = self:AcquireGearText(root, "GameFontHighlightSmall")
    footer:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    footer:SetWidth(contentWidth)
    footer:SetHeight(34)
    footer:SetTextColor(0.72, 0.82, 0.88)
    footer:SetText(T("DK Mentor recommends and explains builds; it does not switch talents. Loadout automation remains in Loadout Pilot."))
    y = y - 40

    local usedHeight = math.max(1, math.abs(y) + 6)
    root:SetHeight(usedHeight)
    return usedHeight, profiles
end

function addon:GetCharacterCheckReport(selectedSpecID)
    local currentSpecID, currentSpecName = self:GetSpecInfo()
    local ready = self:GetReadyCheckStatus()
    local lines = {}
    local improvements = 0
    local waiting = 0

    local function AddState(ok, label, detail, isWaiting)
        local prefix
        if isWaiting then
            prefix = "|cffffcc55? |r"
            waiting = waiting + 1
        elseif ok then
            prefix = "|cff66ff99[OK]|r "
        else
            prefix = "|cffff7777! |r"
            improvements = improvements + 1
        end
        table.insert(lines, prefix .. tostring(label) .. (detail and (": " .. tostring(detail)) or ""))
    end

    if selectedSpecID ~= currentSpecID then
        table.insert(lines, "|cffffcc55" .. T("Live check uses your active specialization: %s. Static recommendations above can still be browsed for %s.", tostring(currentSpecName), tostring((Data.specNames and Data.specNames[selectedSpecID]) or selectedSpecID)) .. "|r")
        table.insert(lines, "")
    end

    AddState(true, T("Specialization"), tostring(currentSpecName or currentSpecID))
    AddState(ready.runeforge and ready.runeforge.ready, T("Runeforge"), ready.runeforge and ready.runeforge.detail or T("Unknown"), ready.runeforge and ready.runeforge.known == false)
    if ready.ghoul and ready.ghoul.required then
        AddState(ready.ghoul.ready, T("Ghoul"), ready.ghoul.detail)
    end

    local missingEnchantSlots, enchantUnknown = self:GetCommonEnchantCoverage()
    if #missingEnchantSlots > 0 then
        AddState(false, T("Common enchant slots"), T("Missing enchant: %s", table.concat(missingEnchantSlots, ", ")))
    elseif enchantUnknown > 0 then
        AddState(false, T("Common enchant slots"), T("Waiting for item data (%d)", enchantUnknown), true)
    else
        AddState(true, T("Common enchant slots"), T("No missing permanent enchants detected"))
    end

    local emptySockets, socketUnknown = self:CountEmptySocketsOnEquippedItems()
    if emptySockets == nil then
        AddState(false, T("Sockets"), T("Socket information unavailable"), true)
    elseif emptySockets > 0 then
        AddState(false, T("Sockets"), T("%d empty socket(s) detected", emptySockets))
    elseif socketUnknown > 0 then
        AddState(false, T("Sockets"), T("No empty sockets detected; %d item(s) still loading", socketUnknown), true)
    else
        AddState(true, T("Sockets"), T("No empty sockets detected"))
    end

    local stats = self:GetCurrentStatSnapshot()
    table.insert(lines, "")
    table.insert(lines, "|cff89d8ff" .. T("Current stat snapshot") .. "|r")
    table.insert(lines, T("Crit: %s   Haste: %s   Mastery: %s   Versatility: %s",
        self:FormatStatPercent(stats.crit), self:FormatStatPercent(stats.haste), self:FormatStatPercent(stats.mastery), self:FormatStatPercent(stats.versatility)))
    table.insert(lines, "|cff999999" .. T("This snapshot is informational. DK Mentor does not mark a character wrong for a secondary-stat distribution because item level, Hero Talents, trinkets, and diminishing returns can change the answer.") .. "|r")

    table.insert(lines, "")
    local utilitySpells = {
        { Data.spells and Data.spells.MIND_FREEZE or 47528, T("Mind Freeze") },
        { Data.spells and Data.spells.DEATH_GRIP or 49576, T("Death Grip") },
        { Data.spells and Data.spells.CHAINS_OF_ICE or 45524, T("Chains of Ice") },
        { Data.spells and Data.spells.ASPHYXIATE or 221562, T("Asphyxiate") },
        { Data.spells and Data.spells.BLINDING_SLEET or 207167, T("Blinding Sleet") },
        { Data.spells and Data.spells.ANTI_MAGIC_ZONE or 51052, T("Anti-Magic Zone") },
        { Data.spells and Data.spells.DEATHS_ADVANCE or 48265, T("Death's Advance") },
        { Data.spells and Data.spells.RAISE_ALLY or 61999, T("Raise Ally") },
    }
    table.insert(lines, "|cff89d8ff" .. T("Utility toolkit") .. "|r")
    local knownUtility = {}
    local optionalUtility = {}
    for _, entry in ipairs(utilitySpells) do
        if IsSpellKnownSafe(entry[1]) then
            table.insert(knownUtility, entry[2])
        else
            table.insert(optionalUtility, entry[2])
        end
    end
    table.insert(lines, "|cff66ff99[OK]|r " .. T("Known / available: %s", table.concat(knownUtility, ", ")))
    if #optionalUtility > 0 then
        table.insert(lines, "|cff999999" .. T("Not currently known/talented: %s", table.concat(optionalUtility, ", ")) .. "|r")
    end
    table.insert(lines, "|cff999999" .. T("For live cooldown readiness, use DK Mentor's Ability Availability Bar; the Codex does not automate abilities.") .. "|r")

    return {
        lines = lines,
        improvements = improvements,
        waiting = waiting,
        currentSpecID = currentSpecID,
    }
end

local function RefreshGuideResponsiveLayout()
    local frame = mainFrame
    local guide = frame and frame.guideSection
    if not guide then return end

    local guidePage = frame.pages and frame.pages.guide or nil
    local sectionWidth = (guide.GetWidth and guide:GetWidth()) or 0
    if sectionWidth < 700 then sectionWidth = (frame.GetWidth and frame:GetWidth() or 1060) - 48 end

    local navWidth = math.max(160, math.min(184, math.floor(sectionWidth * 0.19)))
    local contentLeft = navWidth + 22
    local contentWidth = math.max(620, math.floor(sectionWidth - contentLeft - 38))

    guide.navWidth = navWidth
    guide.contentLeft = contentLeft
    guide.contentWidth = contentWidth

    if guide.navHint then guide.navHint:SetWidth(navWidth - 8) end
    if guide.navPanel then guide.navPanel:SetWidth(navWidth) end
    if guide.specTitle then guide.specTitle:SetWidth(contentWidth - 10) end
    if guide.scroll then
        guide.scroll:ClearAllPoints()
        guide.scroll:SetPoint("TOPLEFT", guide, "TOPLEFT", contentLeft, -64)
        guide.scroll:SetPoint("BOTTOMRIGHT", guide, "BOTTOMRIGHT", -31, 18)
    end
    if guide.content then guide.content:SetWidth(contentWidth) end
    if guide.text then guide.text:SetWidth(contentWidth - 28) end

    if guidePage and guidePage.scope then
        guidePage.scope:SetWidth(math.max(700, (frame.GetWidth and frame:GetWidth() or 1060) - 72))
    end

    local orderedSections = { "overview", "advisor", "stats", "builds", "meta", "valeera", "rotation", "survival", "utility", "check" }
    if guidePage and guidePage.sectionButtons then
        for index, key in ipairs(orderedSections) do
            local button = guidePage.sectionButtons[key]
            if button then
                button:ClearAllPoints()
                button:SetSize(navWidth - 10, 40)
                button:SetPoint("TOPLEFT", guide.navPanel, "TOPLEFT", 4, -((index - 1) * 44))
            end
        end
    end

    if guide.buildActions and guide.buildContextButtons then
        local buildOrder = guide.buildContextOrder or { "auto", "world", "delve", "dungeon", "mythicplus", "raid", "pvp" }
        local buildGap = 4
        local buildWidth = math.floor(((contentWidth - 8) - (buildGap * (#buildOrder - 1))) / #buildOrder)
        for index, key in ipairs(buildOrder) do
            local button = guide.buildContextButtons[key]
            if button then
                button:ClearAllPoints()
                button:SetSize(buildWidth, 24)
                button:SetPoint("TOPLEFT", guide.buildActions, "TOPLEFT", 2 + ((index - 1) * (buildWidth + buildGap)), 0)
            end
        end
    end

    if guide.gearActions and guide.gearViewButtons then
        local gearOrder = guide.gearViewOrder or { "overview", "targets", "preparation", "crafting", "sources", "trinkets", "upgrades" }
        local gearGap = 4
        local gearWidth = math.floor(((contentWidth - 8) - (gearGap * (#gearOrder - 1))) / #gearOrder)
        for index, key in ipairs(gearOrder) do
            local button = guide.gearViewButtons[key]
            if button then
                button:ClearAllPoints()
                button:SetSize(gearWidth, 24)
                button:SetPoint("LEFT", guide.gearActions, "LEFT", 2 + ((index - 1) * (gearWidth + gearGap)), 0)
            end
        end
    end

    if guide.sourceURLBox and guide.selectSourceButton and guide.openPilotButton then
        local fixedButtonsWidth = 152 + 8 + 160 + 8
        local desired = math.floor(contentWidth * 0.34)
        local maxAllowed = math.max(170, contentWidth - fixedButtonsWidth - 20)
        local urlWidth = math.max(170, math.min(260, math.min(desired, maxAllowed)))
        guide.sourceURLBox:SetWidth(urlWidth)
        guide.selectSourceButton:ClearAllPoints()
        guide.selectSourceButton:SetPoint("LEFT", guide.sourceURLBox, "RIGHT", 8, 0)
        guide.openPilotButton:ClearAllPoints()
        guide.openPilotButton:SetPoint("LEFT", guide.selectSourceButton, "RIGHT", 8, 0)
    end
end

function addon:UpdateGuideSection()
    if not mainFrame or not mainFrame.guideSection then
        return
    end

    local specID = self:GetCodexSpecID()
    local currentSpecID = select(1, self:GetSpecInfo())
    local sectionKey = DB and DB.codexSection or "overview"
    local valid = { overview = true, advisor = true, builds = true, stats = true, meta = true, valeera = true, rotation = true, survival = true, utility = true, check = true }
    if not valid[sectionKey] then sectionKey = "overview" end

    local guide = mainFrame.guideSection
    RefreshGuideResponsiveLayout()
    local specData = (DKM.Codex and DKM.Codex.specs) and (DKM.Codex and DKM.Codex.specs)[specID] or nil
    local specName = (specData and specData.name) or (Data.specNames and Data.specNames[specID]) or T("Death Knight")
    local sectionLabel = ((DKM.Codex and DKM.Codex.sectionLabels) and (DKM.Codex and DKM.Codex.sectionLabels)[sectionKey]) or sectionKey
    local lines = {}

    local function AddSection(section)
        if not section then return end
        table.insert(lines, "|cffffcc55" .. tostring(section.heading or "") .. "|r")
        table.insert(lines, tostring(section.body or ""))
        table.insert(lines, "")
    end

    if mainFrame.pages and mainFrame.pages.guide then
        local page = mainFrame.pages.guide
        local currentSpecIcon = select(3, self:GetSpecInfo()) or QUESTION_MARK_ICON
        for id, button in pairs(page.specButtons or {}) do
            local active = (DB.codexSpecID or 0) == id
            local iconTexture = id == 0 and currentSpecIcon or self:GetSpecIconByID(id)
            if button.labelKey then button.label:SetText(T(button.labelKey)) end
            SetFlatTabButtonIcon(button, iconTexture, 18)
            StyleTabButton(button, active)
        end
        for key, button in pairs(page.sectionButtons or {}) do
            if button.menuLabelKey then button.label:SetText(T(button.menuLabelKey)) end
            local iconTexture = button.menuIconTexture
            if button.menuIconDynamic == "spec" then
                iconTexture = self:GetSpecIconByID(specID)
            elseif button.menuIconDynamic == "rotation" then
                local rotationSpellID = specID == 250 and 49998 or (specID == 252 and 55090 or 49020)
                iconTexture = select(2, GetSpellData(rotationSpellID))
            elseif button.menuIconSpellID then
                iconTexture = select(2, GetSpellData(button.menuIconSpellID))
            end
            SetFlatTabButtonIcon(button, iconTexture, 17)
            if button.icon and button.icon:IsShown() then
                button.icon:ClearAllPoints()
                button.icon:SetPoint("LEFT", button, "LEFT", 5, 0)
                button.label:ClearAllPoints()
                button.label:SetPoint("LEFT", button.icon, "RIGHT", 5, 0)
                button.label:SetPoint("RIGHT", button, "RIGHT", -5, 0)
            end
            StyleTabButton(button, key == sectionKey)
        end
    end

    guide.title:SetText(T("DK Codex"))
    guide.specTitle:SetText(T("%s — %s", tostring(specName), tostring(sectionLabel)))

    if guide.buildActions then
        guide.buildActions:SetShown(sectionKey == "builds")
        local selectedBuildContext = DB and tostring(DB.codexBuildContext or "auto") or "auto"
        for key, button in pairs(guide.buildContextButtons or {}) do
            if button.labelKey then button.label:SetText(T(button.labelKey)) end
            SetFlatTabButtonIcon(button, button.iconSpellID and select(2, GetSpellData(button.iconSpellID)) or nil, 11)
            if button.icon and button.icon:IsShown() then
                button.icon:ClearAllPoints()
                button.icon:SetPoint("LEFT", button, "LEFT", 4, 0)
                button.label:ClearAllPoints()
                button.label:SetPoint("LEFT", button.icon, "RIGHT", 3, 0)
                button.label:SetPoint("RIGHT", button, "RIGHT", -3, 0)
            end
            StyleTabButton(button, key == selectedBuildContext)
        end
        local buildMode = self:GetCodexBuildMode()
        for key, button in pairs(guide.buildModeButtons or {}) do StyleTabButton(button, key == buildMode) end
        if guide.buildModeButtons and guide.buildModeButtons.standard then
            guide.buildModeButtons.standard.label:SetText(T("Standard"))
            SetFlatTabButtonIcon(guide.buildModeButtons.standard, self:GetSpecIconByID(specID), 14)
        end
        if guide.buildModeButtons and guide.buildModeButtons.sba then
            guide.buildModeButtons.sba.label:SetText(T("SBA-friendly"))
            SetFlatTabButtonIcon(guide.buildModeButtons.sba, select(2, GetSpellData(47568)), 14)
        end
        if guide.buildModeHint then
            guide.buildModeHint:SetText(buildMode == "sba" and T("Accessibility profile • complements Blizzard SBA") or T("Guide-backed standard recommendations"))
        end
    end
    if guide.gearActions then
        guide.gearActions:SetShown(sectionKey == "stats")
        local gearView = DB and DB.codexGearView or "overview"
        if gearView == "plan" then gearView = "upgrades" end
        for key, button in pairs(guide.gearViewButtons or {}) do
            local iconTexture = button.iconTexture
            if button.iconSpellID then
                iconTexture = select(2, GetSpellData(button.iconSpellID))
            elseif button.iconItemID and GetItemInfoInstant then
                local okItem, _, _, _, _, itemIcon = pcall(GetItemInfoInstant, button.iconItemID)
                if okItem and itemIcon then iconTexture = itemIcon end
            end
            SetFlatTabButtonIcon(button, iconTexture or QUESTION_MARK_ICON, 11)
            if button.icon and button.icon:IsShown() then
                button.icon:ClearAllPoints()
                button.icon:SetPoint("LEFT", button, "LEFT", 4, 0)
                button.label:ClearAllPoints()
                button.label:SetPoint("LEFT", button.icon, "RIGHT", 3, 0)
                button.label:SetPoint("RIGHT", button, "RIGHT", -3, 0)
            end
            StyleTabButton(button, key == gearView)
        end
    end
    if guide.scroll then
        guide.scroll:ClearAllPoints()
        local topOffset = -64
        if sectionKey == "builds" then
            topOffset = -168
        elseif sectionKey == "stats" then
            topOffset = -96
        end
        guide.scroll:SetPoint("TOPLEFT", guide, "TOPLEFT", guide.contentLeft or 150, topOffset)
        guide.scroll:SetPoint("BOTTOMRIGHT", guide, "BOTTOMRIGHT", -31, 18)
    end

    if sectionKey == "builds" then
        local context, autoDetected = self:GetCodexBuildContext()
        local profiles = self:GetBuildProfiles(specID, context)
        self.currentBuildVisualHeight = self:RenderBuildMentorVisual(specID, context, autoDetected)
        local sourceURL = profiles[1] and profiles[1].sourceURL or ""
        if guide.sourceURLBox then
            guide.sourceURLBox:SetText(sourceURL or "")
            guide.sourceURLBox:SetCursorPosition(0)
            guide.sourceURLBox:SetEnabled(sourceURL ~= nil and sourceURL ~= "")
        end
        if guide.selectSourceButton then guide.selectSourceButton:SetEnabled(sourceURL ~= nil and sourceURL ~= ""); StyleActionButton(guide.selectSourceButton) end
        self:UpdateLoadoutPilotIntegration()
    elseif sectionKey == "advisor" then
        self.currentGearVisualHeight = self.RenderDKAdvisorVisual and self:RenderDKAdvisorVisual(specID) or nil
    elseif sectionKey == "meta" then
        self.currentGearVisualHeight = self.RenderMetaAdvisorVisual and self:RenderMetaAdvisorVisual(specID) or nil
    elseif sectionKey == "stats" then
        local gearView = DB and DB.codexGearView or "overview"
        if gearView == "plan" then gearView = "upgrades" end
        self.currentGearVisualHeight = self:RenderGearMentorVisual(specID, gearView)
    elseif sectionKey == "valeera" then
        self.currentGearVisualHeight = self.RenderValeeraMentorVisual and self:RenderValeeraMentorVisual(specID) or nil
    elseif sectionKey == "check" then
        table.insert(lines, "|cff89d8ff" .. T("Character Check — live diagnostics") .. "|r")
        table.insert(lines, T("This check inspects your active character. It never changes gear, talents, enchants, gems, or abilities."))
        table.insert(lines, "")
        local report = self:GetCharacterCheckReport(specID)
        for _, line in ipairs(report.lines or {}) do table.insert(lines, line) end
        table.insert(lines, "")
        if (DKM.Codex and DKM.Codex.checkNotes) and (DKM.Codex and DKM.Codex.checkNotes)[specID] then
            AddSection({ heading = T("Recommendation context"), body = (DKM.Codex and DKM.Codex.checkNotes)[specID] })
        end
    else
        if (DKM.Codex and DKM.Codex.common) and (DKM.Codex and DKM.Codex.common)[sectionKey] then
            for _, section in ipairs((DKM.Codex and DKM.Codex.common)[sectionKey]) do AddSection(section) end
        end
        if specData and specData[sectionKey] then
            for _, section in ipairs(specData[sectionKey]) do AddSection(section) end
        end
        if sectionKey == "utility" then
            local report = self:GetCharacterCheckReport(specID)
            table.insert(lines, "|cff89d8ff" .. T("Utility ready reference") .. "|r")
            local utilityStart = false
            for _, line in ipairs(report.lines or {}) do
                if line:find(T("Utility toolkit"), 1, true) then utilityStart = true end
                if utilityStart then table.insert(lines, line) end
            end
            table.insert(lines, "")
        end
    end

    if (sectionKey == "stats" or sectionKey == "advisor" or sectionKey == "meta" or sectionKey == "valeera") and self.currentGearVisualHeight then
        self.currentBuildVisualHeight = nil
        if guide.buildVisual then guide.buildVisual:Hide() end
        guide.text:Hide()
        guide.content:SetHeight(math.max(1, self.currentGearVisualHeight))
    elseif sectionKey == "builds" and self.currentBuildVisualHeight then
        self.currentGearVisualHeight = nil
        if guide.gearVisual then guide.gearVisual:Hide() end
        guide.text:Hide()
        guide.content:SetHeight(math.max(1, self.currentBuildVisualHeight))
    else
        self.currentGearVisualHeight = nil
        self.currentBuildVisualHeight = nil
        if guide.gearVisual then guide.gearVisual:Hide() end
        if guide.buildVisual then guide.buildVisual:Hide() end
        guide.text:Show()
        table.insert(lines, "|cff999999" .. tostring((DKM.Codex and DKM.Codex.sourceNote) or T("General guidance only; simulate your character for exact optimization.")) .. "|r")
        guide.text:SetText(table.concat(lines, "\n"))
        local height = guide.text:GetStringHeight() or 1
        guide.content:SetHeight(math.max(1, height + 18))
    end
    if guide.scroll and guide.scroll.SetVerticalScroll then guide.scroll:SetVerticalScroll(0) end

    if mainFrame.pages and mainFrame.pages.guide and mainFrame.pages.guide.scope then
        local browsing = (DB.codexSpecID or 0) == 0 and T("Following current specialization") or T("Browsing %s without switching specialization", tostring(specName))
        mainFrame.pages.guide.scope:SetText(T("DK Codex • Patch %s • %s", tostring((DKM.Codex and DKM.Codex.patch) or Data.patch or "12.1"), browsing))
    end

    self.currentCodexSpecID = specID
    self.currentCodexSection = sectionKey
    self.currentCodexActiveSpecID = currentSpecID
end

function addon:UpdateAll()
    if not self.active or not self:IsDeathKnight() then
        return
    end

    self:UpdateHeader()
    self:UpdateModeButtons()
    self:UpdateAssistedCombatSection()
    self:UpdateVoiceSection()
    self:UpdateSurvivalTips()
    self:UpdateCoach()
    self:RefreshCoachVisibility()
    self:UpdateStatusWidget()
    self:RefreshStatusWidgetVisibility()
    self:UpdateGuideSection()
    self:UpdateHUDSettings()
    self:UpdateLoadoutPilotIntegration()
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
    if DB.voice and DB.voice.portrait then
        DB.voice.portrait.point = DEFAULTS.voice.portrait.point
        DB.voice.portrait.relativePoint = DEFAULTS.voice.portrait.relativePoint
        DB.voice.portrait.x = DEFAULTS.voice.portrait.x
        DB.voice.portrait.y = DEFAULTS.voice.portrait.y
        DB.voice.portrait.positionVersion = 2
    end
    RestoreFramePosition(coachFrame, "coach")
    RestoreFramePosition(statusWidget, "statusWidget")
    RestoreFramePosition(buffFrame, "buffBar")
    RestoreFramePosition(externalBuffFrame, "externalBuffBar")
    RestoreFramePosition(debuffFrame, "debuffBar")
    RestoreFramePosition(abilityFrame, "abilityBar")
    RestoreFramePosition(resourceFrame, "resourceHUD")
    if resourceArcFrame then RestoreResourceArcPosition(resourceArcFrame) end
    RestoreFramePosition(interruptFrame, "interruptAlert")
    if addon.lichKingPortraitFrame and DB.voice and DB.voice.portrait then
        addon.RestoreLichKingPortraitPosition()
    end
    Print(T("Combat HUD positions restored to the starter layout."))
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
    if DB.voice and DB.voice.portrait then
        DB.voice.portrait.point = DEFAULTS.voice.portrait.point
        DB.voice.portrait.relativePoint = DEFAULTS.voice.portrait.relativePoint
        DB.voice.portrait.x = DEFAULTS.voice.portrait.x
        DB.voice.portrait.y = DEFAULTS.voice.portrait.y
        DB.voice.portrait.scale = DEFAULTS.voice.portrait.scale
        DB.voice.portrait.positionVersion = 2
    end
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
    if addon.lichKingPortraitFrame and DB.voice and DB.voice.portrait then
        addon.RestoreLichKingPortraitPosition()
    end
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
    Print(T("/dkm codex — open the DK Codex"))
    Print(T("/dkm advisor — open DK Stats & Folio Advisor"))
    Print(T("/dkm builds — open DK Codex build recommendations"))
    Print(T("/dkm meta — open DK Meta Pulse"))
    Print(T("/dkm valeera — open Valeera Delve Mentor"))
    Print(T("/dkm loadouts — open Loadout Pilot when installed"))
    Print(T("/dkm coach on|off — show or hide the compact survival coach"))
    Print(T("/dkm coach health on|off — toggle health-adaptive recommendations"))
    Print(T("/dkm hud on|off — show or hide the movable DK status HUD"))
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
    Print(T("/dkm interrupt glow on|off — toggle the Mind Freeze action-bar glow"))
    Print(T("/dkm interrupt sound on|off — toggle the built-in interrupt sound"))
    Print(T("/dkm interrupt options — open Interrupt options in Alert Studio"))
    Print(T("/dkm interrupt status — inspect the current target cast signal"))
    Print(T("/dkm combatbars combat|always - show aura/ability bars only in combat or always"))
    Print(T("/dkm guide — alias for the DK Codex"))
    Print(T("/dkm gearmentor — open the DK Codex Gear Mentor"))
    Print(T("/dkm settings — open HUD and commentary settings"))
    Print(T("/dkm language auto|ptbr|en — change DK Mentor language"))
    Print(T("/dkm voice on|off|test|low|normal|high|status|map|reset"))
    Print(T("/dkm voice pvp on|off — allow or mute commentary in PvP"))
    Print(T("/dkm voice situations on|off — toggle contextual spell/mount/hearthstone/AFK comments"))
    Print(T("/dkm voice map — choose a voice per situation"))
    Print(T("/dkm rotation — toggle the native offensive highlight"))
    Print(T("/dkm bars — check native rotation spells on your action bars"))
    Print(T("/dkm ready — show the DK Ready Check details"))
    Print(T("/dkm prep — open Preparation / Ready Check"))
    Print(T("/dkm preset — open layout import/export"))
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
    elseif command == "guide" or command == "codex" then
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
        elseif resourceAction == "visibility" or resourceAction == "visible" then
            if resourceValue == "always" then self:SetResourceVisibilityMode("always")
            elseif resourceValue == "fade" then self:SetResourceVisibilityMode("fade")
            elseif resourceValue == "combat" or resourceValue == "combatonly" then self:SetResourceVisibilityMode("combat")
            else self:CycleResourceVisibilityMode() end
        elseif resourceAction == "on" or resourceAction == "show" then
            self:SetResourceHUDEnabled(true)
        elseif resourceAction == "off" or resourceAction == "hide" then
            self:SetResourceHUDEnabled(false)
        else
            self:SetResourceHUDEnabled(not DB.resourceHUD.enabled)
        end
    elseif command == "interrupt" or command == "kick" then
        local interruptAction, interruptValue = rest:match("^(%S*)%s*(.-)$")
        interruptAction = string.lower(interruptAction or "")
        interruptValue = string.lower(Trim(interruptValue))
        if interruptAction == "glow" then
            if interruptValue == "on" or interruptValue == "show" then self:SetInterruptActionGlowEnabled(true)
            elseif interruptValue == "off" or interruptValue == "hide" then self:SetInterruptActionGlowEnabled(false)
            else self:SetInterruptActionGlowEnabled(not (DB.interruptAlert.actionGlow ~= false)) end
        elseif interruptAction == "sound" then
            if interruptValue == "on" then self:SetInterruptSoundEnabled(true)
            elseif interruptValue == "off" then self:SetInterruptSoundEnabled(false)
            else self:SetInterruptSoundEnabled(not self:GetInterruptSoundEnabled()) end
        elseif interruptAction == "options" or interruptAction == "studio" then
            if DKM.MentorStudio and DKM.MentorStudio.OpenInterrupt then DKM.MentorStudio.OpenInterrupt(mainFrame) end
        elseif interruptAction == "on" or interruptAction == "show" then
            self:SetInterruptAlertEnabled(true)
        elseif interruptAction == "off" or interruptAction == "hide" then
            self:SetInterruptAlertEnabled(false)
        elseif interruptAction == "status" or interruptAction == "debug" then
            self:PrintInterruptAlertStatus()
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
    elseif command == "advisor" or command == "statsfolio" or command == "folio" then
        mainFrame:Show()
        DB.codexSection = "advisor"
        self:SetMainTab("guide")
        self:UpdateGuideSection()
    elseif command == "build" or command == "builds" then
        mainFrame:Show()
        DB.codexSection = "builds"
        self:SetMainTab("guide")
        self:UpdateGuideSection()
    elseif command == "meta" or command == "metapulse" then
        mainFrame:Show()
        DB.codexSection = "meta"
        self:SetMainTab("guide")
        self:UpdateGuideSection()
    elseif command == "valeera" or command == "delvecompanion" then
        mainFrame:Show()
        DB.codexSection = "valeera"
        self:SetMainTab("guide")
        self:UpdateGuideSection()
    elseif command == "gearmentor" or command == "gearing" then
        mainFrame:Show()
        DB.codexSection = "stats"
        DB.codexGearView = "overview"
        self:SetMainTab("guide")
        self:UpdateGuideSection()
    elseif command == "prep" or command == "preparation" then
        mainFrame:Show()
        DB.codexSection = "stats"
        DB.codexGearView = "preparation"
        self:SetMainTab("guide")
        self:UpdateGuideSection()
    elseif command == "preset" or command == "presets" or command == "layout" then
        self:ToggleLayoutPresetFrame()
    elseif command == "loadout" or command == "loadouts" or command == "pilot" or command == "gear" or command == "equipment" then
        self:OpenLoadoutPilot()
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

    -- Release-candidate migration guard: old 1.x / early 2.0 SavedVariables can
    -- contain stale anchors or extreme coordinates. Sanitize them before frames
    -- are created so an update cannot strand a HUD outside the visible screen.
    local validAnchor = {
        TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
        BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
    }
    local function SanitizeFrameConfig(key)
        local defaults = DEFAULTS[key]
        local cfg = DB[key]
        if type(defaults) ~= "table" or type(cfg) ~= "table" then return end
        if not validAnchor[cfg.point] then cfg.point = defaults.point or "CENTER" end
        if not validAnchor[cfg.relativePoint] then cfg.relativePoint = defaults.relativePoint or cfg.point end
        cfg.x = Clamp(tonumber(cfg.x) or defaults.x or 0, -4000, 4000)
        cfg.y = Clamp(tonumber(cfg.y) or defaults.y or 0, -4000, 4000)
        cfg.scale = Clamp(tonumber(cfg.scale) or defaults.scale or 1, 0.7, 1.6)
        if cfg.opacity ~= nil or defaults.opacity ~= nil then
            cfg.opacity = Clamp(tonumber(cfg.opacity) or defaults.opacity or 1, 0.3, 1)
        end
    end
    for _, key in ipairs({ "main", "coach", "statusWidget", "buffBar", "externalBuffBar", "debuffBar", "abilityBar", "resourceHUD", "interruptAlert" }) do
        SanitizeFrameConfig(key)
    end
    if DB.voice and DB.voice.portrait then
        local portrait = DB.voice.portrait
        local defaults = DEFAULTS.voice.portrait
        if not validAnchor[portrait.point] then portrait.point = defaults.point end
        if not validAnchor[portrait.relativePoint] then portrait.relativePoint = defaults.relativePoint end
        portrait.x = Clamp(tonumber(portrait.x) or defaults.x, -4000, 4000)
        portrait.y = Clamp(tonumber(portrait.y) or defaults.y, -4000, 4000)
        portrait.scale = Clamp(tonumber(portrait.scale) or defaults.scale, 0.7, 1.5)
        if portrait.locked == nil then portrait.locked = true end
        if portrait.character ~= "bolvar" then portrait.character = "arthas" end
        if portrait.positionVersion ~= 2 then portrait.positionVersion = nil end
    end

    -- Moving HUDs is a temporary editing action, not a persistent gameplay mode.
    -- Always start a fresh UI session locked; the drag handle appears only after
    -- the player explicitly unlocks HUD movement in this session.
    DB.hudLocked = true
    self.hudEditSessionActive = false

    DB.languageOverride = NormalizeAddonLanguage(DB.languageOverride)
    if DKM.SetLocaleOverride then DKM.SetLocaleOverride(DB.languageOverride) end
    -- Static Data/Builds/Guides/Codex/Voices tables are created before
    -- SavedVariables are guaranteed to be available. Re-localize them now,
    -- after the user's DK Mentor language override has been applied, so a
    -- ptBR WoW client can use an English addon UI (and vice versa) cleanly.
    if DKM.RefreshStaticLocalization then DKM.RefreshStaticLocalization() end

    if previousSchema < 21 then DB.combatBarsOnlyInCombat = true end

    if previousSchema < 31 and DB.resourceHUD then
        -- 3.0 keeps the old global combat-only behavior as the migration default.
        DB.resourceHUD.visibilityMode = DB.combatBarsOnlyInCombat == false and "always" or "combat"
        DB.resourceHUD.fadeAlpha = 0.20
    end
    if DB.resourceHUD then
        DB.resourceHUD.visibilityMode = NormalizeResourceVisibilityMode(DB.resourceHUD.visibilityMode)
        DB.resourceHUD.fadeAlpha = Clamp(tonumber(DB.resourceHUD.fadeAlpha) or 0.20, 0.05, 0.80)
    end

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

    DB.modeOverride = "auto"
    if DB.mainTab == "builds" then DB.mainTab = "guide" end

    -- DK Mentor 2.0 retires loadout automation. Keep any legacy mapping tables
    -- untouched so users can safely roll back, but force the old switches off.
    if DB.autoSwitchSpecialization ~= nil then DB.autoSwitchSpecialization = false end
    if DB.autoSwitchLoadouts ~= nil then DB.autoSwitchLoadouts = false end
    if DB.autoSwitchEquipment ~= nil then DB.autoSwitchEquipment = false end
    DB.schema = DEFAULTS.schema
end

-- 3.1 Lich King commentary portrait --------------------------------------------
addon.LICH_KING_CREATURE_ID = 36597
addon.LICH_KING_BOLVAR_CREATURE_ID = 99456
addon.LICH_KING_FALLBACK_ICON = "Interface\\Icons\\Achievement_Boss_LichKing"
addon.LICH_KING_CHARACTERS = {
    arthas = { creatureID = addon.LICH_KING_CREATURE_ID, label = "Arthas", title = "Lich King - Arthas", portraitZoom = 0.72 },
    bolvar = { creatureID = addon.LICH_KING_BOLVAR_CREATURE_ID, label = "Bolvar", title = "Lich King - Bolvar", portraitZoom = 0.70 },
}

function addon:GetLichKingPortraitCharacterKey()
    if not DB or not DB.voice or not DB.voice.portrait then return "arthas" end
    return DB.voice.portrait.character == "bolvar" and "bolvar" or "arthas"
end

function addon:GetLichKingPortraitCharacter()
    return addon.LICH_KING_CHARACTERS[self:GetLichKingPortraitCharacterKey()] or addon.LICH_KING_CHARACTERS.arthas
end

function addon:UpdateLichKingPortraitModel()
    local frame = addon.lichKingPortraitFrame
    if not frame then return end
    local character = self:GetLichKingPortraitCharacter()
    if frame.title then frame.title:SetText(T(character.title)) end
    if frame.fallback then frame.fallback:SetTexture(addon.LICH_KING_FALLBACK_ICON) end
    if frame.model and frame.model.SetCreature then
        pcall(frame.model.SetCreature, frame.model, character.creatureID)
        if frame.model.SetPortraitZoom then pcall(frame.model.SetPortraitZoom, frame.model, character.portraitZoom or 0.72) end
        if frame.model.SetDoBlend then pcall(frame.model.SetDoBlend, frame.model, true) end
    end
end

function addon:SetLichKingPortraitCharacter(characterKey)
    if not DB or not DB.voice or not DB.voice.portrait then return end
    characterKey = string.lower(tostring(characterKey or ""))
    if characterKey ~= "arthas" and characterKey ~= "bolvar" then return end
    DB.voice.portrait.character = characterKey
    self:UpdateLichKingPortraitModel()
    if addon.lichKingPortraitFrame and DB.voice.portrait.enabled and (self:IsVoicePlaying() or DB.voice.portrait.locked == false) then
        self:ShowLichKingPortrait(not self:IsVoicePlaying())
    end
    self:UpdateVoiceSection()
    Print(T("Portrait character changed to %s.", (addon.LICH_KING_CHARACTERS[characterKey] and addon.LICH_KING_CHARACTERS[characterKey].label) or characterKey))
end

function addon:CycleLichKingPortraitCharacter()
    self:SetLichKingPortraitCharacter(self:GetLichKingPortraitCharacterKey() == "arthas" and "bolvar" or "arthas")
end

function addon.SaveLichKingPortraitPosition()
    if not DB or not DB.voice or not DB.voice.portrait or not addon.lichKingPortraitFrame then return end
    local frame = addon.lichKingPortraitFrame
    local parent = frame:GetParent() or UIParent
    local cfg = DB.voice.portrait
    local scale = Clamp(tonumber(frame:GetScale()) or tonumber(cfg.scale) or 1, 0.7, 1.5)
    local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()

    -- Save in the parent's coordinate space rather than the portrait's own
    -- scaled coordinate space. This keeps a dragged portrait in the same
    -- screen location when it is hidden/shown again or its scale changes.
    if left and right and top and bottom and parent.GetWidth and parent.GetHeight then
        left, right = left * scale, right * scale
        top, bottom = top * scale, bottom * scale
        local parentWidth, parentHeight = parent:GetWidth(), parent:GetHeight()
        if parentWidth and parentHeight and parentWidth > 0 and parentHeight > 0 then
            local centerX, centerY = (left + right) / 2, (bottom + top) / 2
            local x, y, point

            if left < (parentWidth - right) and left < math.abs(centerX - parentWidth / 2) then
                x, point = left, "LEFT"
            elseif (parentWidth - right) < math.abs(centerX - parentWidth / 2) then
                x, point = right - parentWidth, "RIGHT"
            else
                x, point = centerX - parentWidth / 2, ""
            end

            if bottom < (parentHeight - top) and bottom < math.abs(centerY - parentHeight / 2) then
                y, point = bottom, "BOTTOM" .. point
            elseif (parentHeight - top) < math.abs(centerY - parentHeight / 2) then
                y, point = top - parentHeight, "TOP" .. point
            else
                y = centerY - parentHeight / 2
            end

            if point == "" then point = "CENTER" end
            cfg.point = point
            cfg.relativePoint = point
            cfg.x = x
            cfg.y = y
            cfg.scale = scale
            cfg.positionVersion = 2

            -- Normalize the live anchor immediately so subsequent Show/Hide
            -- operations do not inherit the temporary anchor created by
            -- StartMoving().
            frame:ClearAllPoints()
            frame:SetPoint(point, parent, point, x / scale, y / scale)
            return
        end
    end

    -- Safe fallback for unusual clients/layout timing where frame bounds are
    -- not available yet. Keep the current anchor but still store offsets in
    -- the portrait's scale so Restore can reproduce the same screen position.
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if point then
        cfg.point = point
        cfg.relativePoint = relativePoint or point
        cfg.x = (x or 0) * scale
        cfg.y = (y or 0) * scale
        cfg.scale = scale
        cfg.positionVersion = 2
    end
end

function addon.RestoreLichKingPortraitPosition()
    if not DB or not DB.voice or not DB.voice.portrait or not addon.lichKingPortraitFrame then return end
    local frame = addon.lichKingPortraitFrame
    local cfg = DB.voice.portrait
    local scale = Clamp(tonumber(cfg.scale) or 1, 0.7, 1.5)
    local point = addon.PRESET_ANCHORS and addon.PRESET_ANCHORS[cfg.point] and cfg.point or "CENTER"

    frame:ClearAllPoints()
    if cfg.positionVersion == 2 then
        -- New stable format: x/y are stored in UIParent's scale and are divided
        -- by the portrait scale when anchoring the scaled frame.
        frame:SetScale(scale)
        frame:SetPoint(point, UIParent, point, (tonumber(cfg.x) or 0) / scale, (tonumber(cfg.y) or 165) / scale)
    else
        -- Legacy 3.1.0-3.1.5 data used raw GetPoint offsets. Reproduce that
        -- location once, then normalize it into the stable v2 format.
        frame:SetPoint(point, UIParent, cfg.relativePoint or point, tonumber(cfg.x) or 0, tonumber(cfg.y) or 165)
        frame:SetScale(scale)
        addon.SaveLichKingPortraitPosition()
    end
end

function addon:UpdateLichKingPortraitState()
    if not addon.lichKingPortraitFrame or not DB or not DB.voice or not DB.voice.portrait then return end
    local frame = addon.lichKingPortraitFrame
    local cfg = DB.voice.portrait
    local unlocked = cfg.locked == false
    local playing = self:IsVoicePlaying()

    frame:EnableMouse(unlocked)
    addon.RestoreLichKingPortraitPosition()

    if not cfg.enabled then
        frame.preview = false
        frame:Hide()
    elseif playing then
        frame.preview = false
        frame:Show()
    elseif unlocked then
        frame.preview = true
        frame:Show()
    else
        frame.preview = false
        frame:Hide()
    end

    frame.dragHint:SetShown(unlocked)
    frame.lockHint:SetShown(frame.preview == true and unlocked)
end

function addon:SetLichKingPortraitTalking(talking)
    local frame = addon.lichKingPortraitFrame
    local model = frame and frame.model
    if not model or not model.SetAnimation then return end

    local animationID = talking and 60 or 0
    local supported = true
    if model.HasAnimation then
        local ok, value = pcall(model.HasAnimation, model, animationID)
        if ok and IsAccessibleValue(value) and type(value) == "boolean" then supported = value end
    end
    if supported then
        pcall(model.SetAnimation, model, animationID)
        frame.talking = talking == true
        frame.talkElapsed = 0
    else
        frame.talking = false
    end
end

function addon:ShowLichKingPortrait(preview)
    if not addon.lichKingPortraitFrame or not DB or not DB.voice or not DB.voice.portrait or DB.voice.portrait.enabled ~= true then return end
    local frame = addon.lichKingPortraitFrame
    local unlocked = DB.voice.portrait.locked == false
    frame.preview = preview == true and unlocked
    frame:EnableMouse(unlocked)
    frame.dragHint:SetShown(unlocked)
    frame.lockHint:SetShown(frame.preview == true)
    self:UpdateLichKingPortraitModel()
    if not frame.dragging then addon.RestoreLichKingPortraitPosition() end
    frame:Show()
    self:SetLichKingPortraitTalking(not frame.preview and self:IsVoicePlaying())
end

function addon:SetLichKingPortraitEnabled(enabled)
    if not DB or not DB.voice or not DB.voice.portrait then return end
    DB.voice.portrait.enabled = enabled == true
    if DB.voice.portrait.enabled and DB.voice.portrait.locked == false then
        self:ShowLichKingPortrait(true)
    elseif not DB.voice.portrait.enabled and addon.lichKingPortraitFrame then
        addon.lichKingPortraitFrame.preview = false
        addon.lichKingPortraitFrame:Hide()
    end
    self:UpdateVoiceSection()
end

function addon:ToggleLichKingPortraitLock()
    if not DB or not DB.voice or not DB.voice.portrait then return end
    DB.voice.portrait.locked = DB.voice.portrait.locked == false
    if DB.voice.portrait.locked == false then
        DB.voice.portrait.enabled = true
        self:ShowLichKingPortrait(true)
        Print(T("Lich King portrait unlocked. Drag the portrait to move it, then lock it again."))
    else
        addon.SaveLichKingPortraitPosition()
        if addon.lichKingPortraitFrame then addon.lichKingPortraitFrame.preview = false end
        if not self:IsVoicePlaying() and addon.lichKingPortraitFrame then addon.lichKingPortraitFrame:Hide() end
        Print(T("Lich King portrait locked."))
    end
    self:UpdateLichKingPortraitState()
    self:UpdateVoiceSection()
end

function addon:CycleLichKingPortraitScale()
    if not DB or not DB.voice or not DB.voice.portrait then return end
    local scales = { 0.8, 1.0, 1.2, 1.4 }
    local current = tonumber(DB.voice.portrait.scale) or 1
    local nextScale = scales[1]
    for index, value in ipairs(scales) do
        if math.abs(value - current) < 0.05 then
            nextScale = scales[(index % #scales) + 1]
            break
        end
    end
    DB.voice.portrait.scale = nextScale
    addon.RestoreLichKingPortraitPosition()
    self:UpdateVoiceSection()
end

function addon.CreateLichKingPortraitFrame()
    local frame = CreateFrame("Frame", "DKMentorLichKingPortrait", UIParent, "BackdropTemplate")
    frame:SetSize(160, 178)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left=3, right=3, top=3, bottom=3 },
    })
    frame:SetBackdropColor(0.018, 0.035, 0.055, 0.94)
    frame:SetBackdropBorderColor(0.42, 0.72, 0.86, 0.96)

    frame.fallback = frame:CreateTexture(nil, "BACKGROUND")
    frame.fallback:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    frame.fallback:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
    frame.fallback:SetHeight(132)
    frame.fallback:SetTexture(addon.LICH_KING_FALLBACK_ICON)
    frame.fallback:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.fallback:SetAlpha(0.48)

    local ok, model = pcall(CreateFrame, "PlayerModel", nil, frame)
    if ok and model then
        frame.model = model
        model:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
        model:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
        model:SetHeight(136)
        if model.SetPortraitZoom then pcall(model.SetPortraitZoom, model, 0.72) end
        if model.SetCreature then pcall(model.SetCreature, model, addon.LICH_KING_CREATURE_ID) end
    end

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 9, -148)
    frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -9, -148)
    frame.title:SetHeight(17)
    frame.title:SetJustifyH("CENTER")
    frame.title:SetText(T("Lich King - Arthas"))
    frame.title:SetTextColor(0.66, 0.90, 1.00)

    frame.dragHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.dragHint:SetPoint("TOP", frame.title, "BOTTOM", 0, -1)
    frame.dragHint:SetText(T("Drag to move"))
    frame.dragHint:Hide()

    frame.lockHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.lockHint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 5)
    frame.lockHint:SetText(T("Preview"))
    frame.lockHint:Hide()

    frame:SetScript("OnDragStart", function(self)
        if DB and DB.voice and DB.voice.portrait and DB.voice.portrait.locked == false and not (InCombatLockdown and InCombatLockdown()) then
            self.dragging = true
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.dragging = false
        addon.SaveLichKingPortraitPosition()
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + (elapsed or 0)
        self.talkElapsed = (self.talkElapsed or 0) + (elapsed or 0)
        if not DB or not DB.voice or not DB.voice.portrait or DB.voice.portrait.enabled ~= true then
            addon:SetLichKingPortraitTalking(false)
            self:Hide()
            return
        end

        local playing = addon:IsVoicePlaying()
        if playing then
            -- SetAnimation(60) is the standard PlayerModel talking animation.
            -- It is not guaranteed to loop on every creature model, so refresh
            -- it while the voice is active to keep the portrait visibly alive.
            if not self.talking or self.talkElapsed >= 1.15 then
                addon:SetLichKingPortraitTalking(true)
            end
        elseif self.talking then
            addon:SetLichKingPortraitTalking(false)
        end

        if self.elapsed < 0.10 then return end
        self.elapsed = 0
        if self.preview and DB.voice.portrait.locked == false then return end
        if not playing then self:Hide() end
    end)
    frame:Hide()
    addon.RestoreLichKingPortraitPosition()
    return frame
end

-- 3.1 Layout preset export / import -------------------------------------------
addon.PRESET_FRAME_KEYS = { "main", "coach", "statusWidget", "buffBar", "externalBuffBar", "debuffBar", "abilityBar", "resourceHUD", "interruptAlert" }
addon.PRESET_ANCHORS = { TOPLEFT=true, TOP=true, TOPRIGHT=true, LEFT=true, CENTER=true, RIGHT=true, BOTTOMLEFT=true, BOTTOM=true, BOTTOMRIGHT=true }

function addon.PresetBool(value) return value == true and "1" or "0" end
function addon.PresetNumber(value, default) return tostring(tonumber(value) or default or 0) end
function addon.ParsePresetBool(value) return tostring(value or "0") == "1" end

function addon:ExportLayoutPreset()
    if not DB then return "" end
    addon.SaveLichKingPortraitPosition()
    local segments = { "DKM31" }
    segments[#segments+1] = table.concat({ "global", addon.PresetBool(DB.hudLocked), addon.PresetBool(DB.combatBarsOnlyInCombat) }, ",")
    for _, key in ipairs(addon.PRESET_FRAME_KEYS) do
        local cfg = DB[key] or {}
        segments[#segments+1] = table.concat({
            key,
            tostring(cfg.point or "CENTER"), tostring(cfg.relativePoint or cfg.point or "CENTER"),
            addon.PresetNumber(cfg.x), addon.PresetNumber(cfg.y), addon.PresetNumber(cfg.scale, 1),
            addon.PresetBool(cfg.enabled), addon.PresetNumber(cfg.iconsPerRow), addon.PresetNumber(cfg.opacity, 1),
        }, ",")
    end
    local r = DB.resourceHUD or {}
    segments[#segments+1] = table.concat({ "resourceExtra", addon.PresetBool(r.showRunes ~= false), addon.PresetBool(r.showRunicPower ~= false), addon.PresetBool(r.showPowerText ~= false), tostring(r.runeSpacing or "normal"), tostring(r.style or "classic"), addon.PresetNumber(r.arcSpacing,105), tostring(r.arcPoint or "CENTER"), tostring(r.arcRelativePoint or "CENTER"), addon.PresetNumber(r.arcX), addon.PresetNumber(r.arcY), tostring(r.visibilityMode or "combat"), addon.PresetNumber(r.fadeAlpha,0.20) }, ",")
    local i = DB.interruptAlert or {}
    segments[#segments+1] = table.concat({ "interruptExtra", addon.PresetBool(i.actionGlow ~= false) }, ",")
    local c = DB.coach or {}
    segments[#segments+1] = table.concat({ "coachExtra", addon.PresetBool(c.onlyInCombat ~= false), addon.PresetBool(c.adaptiveHealth ~= false) }, ",")
    local vp = DB.voice and DB.voice.portrait or {}
    segments[#segments+1] = table.concat({ "portrait", addon.PresetBool(vp.enabled), addon.PresetBool(vp.locked ~= false), tostring(vp.point or "CENTER"), tostring(vp.relativePoint or "CENTER"), addon.PresetNumber(vp.x), addon.PresetNumber(vp.y,165), addon.PresetNumber(vp.scale,1), tostring(vp.character == "bolvar" and "bolvar" or "arthas"), tostring(vp.positionVersion == 2 and 2 or 1) }, ",")
    return table.concat(segments, ";")
end

function addon.SplitPreset(text, separator)
    local result = {}
    text = tostring(text or "")
    separator = separator or ","
    local pattern = "([^" .. separator .. "]+)"
    for value in text:gmatch(pattern) do result[#result+1] = value end
    return result
end

function addon:ApplyLayoutPresetPositions()
    if not DB then return end
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
    addon.RestoreLichKingPortraitPosition()
    self:UpdateLichKingPortraitModel()
    for dbKey in pairs(COMBAT_BAR_LAYOUT_LIMITS) do self:ApplyCombatBarLayout(dbKey) end
    self:UpdateBarLayoutFrame()
    self:UpdateLichKingPortraitState()
    self:UpdateHUDSettings()
    self:RefreshCombatHUDVisibility()
end

function addon:ImportLayoutPreset(text)
    if not DB then return false, T("Settings are not ready yet.") end
    if InCombatLockdown and InCombatLockdown() then return false, T("Layout presets cannot be imported during combat.") end
    text = Trim(text)
    -- Presets are data only: keep the format bounded and require the exact 3.1
    -- header before parsing any settings. No Lua source is ever evaluated.
    if text == "" or #text > 12000 or not text:match("^DKM31;") then
        return false, T("Invalid DK Mentor 3.1 layout preset.")
    end
    local knownFrames = {}
    for _, key in ipairs(addon.PRESET_FRAME_KEYS) do knownFrames[key] = true end
    for segment in text:gmatch("[^;]+") do
        local fields = addon.SplitPreset(segment, ",")
        local key = fields[1]
        if knownFrames[key] then
            local cfg = DB[key] or {}
            local defaults = DEFAULTS[key] or {}
            if addon.PRESET_ANCHORS[fields[2] or ""] then cfg.point = fields[2] end
            if addon.PRESET_ANCHORS[fields[3] or ""] then cfg.relativePoint = fields[3] end
            cfg.x = Clamp(tonumber(fields[4]) or defaults.x or 0, -4000, 4000)
            cfg.y = Clamp(tonumber(fields[5]) or defaults.y or 0, -4000, 4000)
            cfg.scale = Clamp(tonumber(fields[6]) or defaults.scale or 1, 0.7, 1.6)
            if defaults.enabled ~= nil then cfg.enabled = addon.ParsePresetBool(fields[7]) end
            if defaults.iconsPerRow ~= nil and tonumber(fields[8]) then cfg.iconsPerRow = Clamp(tonumber(fields[8]), 1, 20) end
            if defaults.opacity ~= nil and tonumber(fields[9]) then cfg.opacity = Clamp(tonumber(fields[9]), 0.3, 1) end
            DB[key] = cfg
        elseif key == "global" then
            -- Always relock after import; importing a layout should never leave
            -- click-catching drag handles active unexpectedly.
            DB.hudLocked = true
            DB.combatBarsOnlyInCombat = addon.ParsePresetBool(fields[3])
        elseif key == "resourceExtra" then
            local r = DB.resourceHUD or {}
            r.showRunes = addon.ParsePresetBool(fields[2]); r.showRunicPower = addon.ParsePresetBool(fields[3]); r.showPowerText = addon.ParsePresetBool(fields[4])
            if fields[5] == "compact" or fields[5] == "normal" or fields[5] == "wide" then r.runeSpacing = fields[5] end
            if fields[6] == "classic" or fields[6] == "arcs" then r.style = fields[6] end
            r.arcSpacing = Clamp(tonumber(fields[7]) or 105, 70, 180)
            if addon.PRESET_ANCHORS[fields[8] or ""] then r.arcPoint = fields[8] end
            if addon.PRESET_ANCHORS[fields[9] or ""] then r.arcRelativePoint = fields[9] end
            r.arcX = Clamp(tonumber(fields[10]) or 0,-4000,4000); r.arcY = Clamp(tonumber(fields[11]) or 0,-4000,4000)
            if fields[12] == "always" or fields[12] == "fade" or fields[12] == "combat" then r.visibilityMode = fields[12] end
            r.fadeAlpha = Clamp(tonumber(fields[13]) or 0.20,0.05,0.80)
            DB.resourceHUD = r
        elseif key == "interruptExtra" then
            DB.interruptAlert.actionGlow = addon.ParsePresetBool(fields[2])
        elseif key == "coachExtra" then
            DB.coach.onlyInCombat = addon.ParsePresetBool(fields[2]); DB.coach.adaptiveHealth = addon.ParsePresetBool(fields[3])
        elseif key == "portrait" and DB.voice and DB.voice.portrait then
            local vp = DB.voice.portrait
            vp.enabled = addon.ParsePresetBool(fields[2]); vp.locked = true
            if addon.PRESET_ANCHORS[fields[4] or ""] then vp.point = fields[4] end
            if addon.PRESET_ANCHORS[fields[5] or ""] then vp.relativePoint = fields[5] end
            vp.x = Clamp(tonumber(fields[6]) or 0,-4000,4000); vp.y = Clamp(tonumber(fields[7]) or 165,-4000,4000); vp.scale = Clamp(tonumber(fields[8]) or 1,0.7,1.5)
            if fields[9] == "arthas" or fields[9] == "bolvar" then vp.character = fields[9] end
            vp.positionVersion = tonumber(fields[10]) == 2 and 2 or nil
        end
    end
    self.hudEditSessionActive = false
    self:ApplyLayoutPresetPositions()
    return true
end

function addon:ToggleLayoutPresetFrame()
    if not addon.layoutPresetFrame then return end
    if addon.layoutPresetFrame:IsShown() then
        addon.layoutPresetFrame:Hide()
    else
        addon.layoutPresetFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        addon.layoutPresetFrame:SetFrameLevel(1400)
        addon.layoutPresetFrame:Show()
        if addon.layoutPresetFrame.Raise then addon.layoutPresetFrame:Raise() end
        addon.layoutPresetFrame.editBox:SetText(self:ExportLayoutPreset())
        addon.layoutPresetFrame.editBox:SetCursorPosition(0)
    end
end

function addon.CreateLayoutPresetFrame()
    local frame = CreateFrame("Frame", "DKMentorLayoutPresetFrame", UIParent, "BackdropTemplate")
    frame:SetSize(690, 430)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1400)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not (InCombatLockdown and InCombatLockdown()) then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetScript("OnShow", function(self)
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetFrameLevel(1400)
        if self.Raise then self:Raise() end
    end)
    ApplyBackdrop(frame, 0.98)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)
    frame.title:SetText(T("DK Mentor layout presets"))
    frame.title:SetTextColor(0.58,0.88,1.00)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    frame.help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.help:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -48)
    frame.help:SetWidth(650)
    frame.help:SetHeight(42)
    frame.help:SetJustifyH("LEFT")
    frame.help:SetJustifyV("TOP")
    frame.help:SetText(T("Export your DK Mentor HUD positions and visual settings as a text string, or paste another DK Mentor 3.1 preset and import it. Third-party addon layouts are not included."))

    frame.box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.box:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -96)
    frame.box:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -38, 78)
    frame.box:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=10 })
    frame.box:SetBackdropColor(0.01,0.025,0.035,0.94)
    frame.box:SetBackdropBorderColor(0.16,0.42,0.54,0.86)

    frame.scroll = CreateFrame("ScrollFrame", nil, frame.box, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", frame.box, "TOPLEFT", 10, -10)
    frame.scroll:SetPoint("BOTTOMRIGHT", frame.box, "BOTTOMRIGHT", -28, 10)
    frame.editBox = CreateFrame("EditBox", nil, frame.scroll)
    frame.editBox:SetMultiLine(true)
    frame.editBox:SetAutoFocus(false)
    frame.editBox:SetFontObject(ChatFontNormal or GameFontHighlightSmall)
    frame.editBox:SetWidth(600)
    frame.editBox:SetHeight(250)
    frame.editBox:SetTextInsets(4,4,4,4)
    frame.editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    frame.editBox:SetScript("OnTextChanged", function(self)
        local h = math.max(250, (self.GetStringHeight and self:GetStringHeight() or 250) + 18)
        self:SetHeight(h)
    end)
    frame.scroll:SetScrollChild(frame.editBox)

    frame.exportButton = CreateActionButton(frame)
    frame.exportButton:SetSize(128, 28)
    frame.exportButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 34)
    frame.exportButton:SetText(T("Export current"))
    frame.exportButton:SetScript("OnClick", function()
        frame.editBox:SetText(addon:ExportLayoutPreset())
        frame.editBox:SetFocus(); frame.editBox:HighlightText()
        Print(T("Layout preset exported. Press Ctrl+C to copy the selected text."))
    end)

    frame.importButton = CreateActionButton(frame)
    frame.importButton:SetSize(128, 28)
    frame.importButton:SetPoint("LEFT", frame.exportButton, "RIGHT", 8, 0)
    frame.importButton:SetText(T("Import preset"))
    frame.importButton:SetScript("OnClick", function()
        local ok, err = addon:ImportLayoutPreset(frame.editBox:GetText())
        if ok then Print(T("Layout preset imported and applied.")) else Print(err or T("Layout preset could not be imported.")) end
    end)

    frame.selectButton = CreateActionButton(frame)
    frame.selectButton:SetSize(118, 28)
    frame.selectButton:SetPoint("LEFT", frame.importButton, "RIGHT", 8, 0)
    frame.selectButton:SetText(T("Select all"))
    frame.selectButton:SetScript("OnClick", function() frame.editBox:SetFocus(); frame.editBox:HighlightText() end)

    frame.resetButton = CreateActionButton(frame)
    frame.resetButton:SetSize(118, 28)
    frame.resetButton:SetPoint("LEFT", frame.selectButton, "RIGHT", 8, 0)
    frame.resetButton:SetText(T("Reset HUDs"))
    frame.resetButton:SetScript("OnClick", function() addon:ResetHUDPositions(); frame.editBox:SetText(addon:ExportLayoutPreset()) end)

    -- Keep an explicit text close action in the modal footer. The standard
    -- corner X is still available, but the footer button is easier to notice
    -- against busy game backgrounds and makes the exit path unambiguous.
    frame.closeButton = CreateActionButton(frame)
    frame.closeButton:SetSize(110, 28)
    frame.closeButton:SetPoint("LEFT", frame.resetButton, "RIGHT", 8, 0)
    frame.closeButton:SetText(T("Close"))
    frame.closeButton:SetScript("OnClick", function() frame:Hide() end)

    frame:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, frame:GetName()) end
    return frame
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
    voiceConfigFrame = CreateVoiceConfigFrame()
    addon.lichKingPortraitFrame = addon.CreateLichKingPortraitFrame()
    self:UpdateLichKingPortraitModel()
    addon.layoutPresetFrame = addon.CreateLayoutPresetFrame()
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
        "ACTIVE_TALENT_GROUP_CHANGED",
        "PLAYER_TALENT_UPDATE",
        "TRAIT_CONFIG_UPDATED",
        "PLAYER_ENTERING_BATTLEGROUND",
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
        "UNIT_SPELLCAST_DELAYED",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_UPDATE",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_EMPOWER_START",
        "UNIT_SPELLCAST_EMPOWER_STOP",
        "PLAYER_TARGET_CHANGED",
        "ITEM_DATA_LOAD_RESULT",
        "NEW_MOUNT_ADDED",
        "PVP_MATCH_COMPLETE",
        "UPDATE_BATTLEFIELD_STATUS",
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

    -- Blizzard's own cast bars register interruptibility as target-scoped unit
    -- events. Mirror that path here so Midnight does not depend on a broad event
    -- registration for the two signals that drive the Mind Freeze alert.
    for _, eventName in ipairs({ "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" }) do
        local registered = false
        if self.RegisterUnitEvent then
            registered = pcall(self.RegisterUnitEvent, self, eventName, "target")
        end
        if not registered then
            pcall(self.RegisterEvent, self, eventName)
        end
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
            if addon.lichKingPortraitFrame then addon.lichKingPortraitFrame:Hide() end
            if addon.layoutPresetFrame then addon.layoutPresetFrame:Hide() end
            minimapButton:Hide()
            Print(T("This addon only runs on Death Knights."))
            return
        end

        self.active = true
        self:UpdateLichKingPortraitState()
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
        if self.RegisterGearTargetTooltipIntegration then self:RegisterGearTargetTooltipIntegration() end
        self:CheckActionBarCoverage(true)
        self:ScheduleInterruptActionGlowRefresh()

        local firstRunNow = DB.firstRun == true
        if firstRunNow then
            DB.firstRun = false
            mainFrame:Show()
        end

        if DB.majorReleaseNotice ~= "3.2" then
            DB.majorReleaseNotice = "3.2"
            Print(T("DK Mentor 3.2 — Stats & Folio Advisor is ready."))
            Print(T("Use /dkm advisor for live stats, diminishing returns, Omnium Folio guidance, and data freshness. Gear Mentor also includes Catalyst plans and smart DK target tooltips."))
            Print(T("DK Mentor recommends actions; it never casts abilities automatically. Use /dkm help for commands."))
        elseif firstRunNow then
            Print(T("Ready. Explore the DK Codex and use /dkm help to view commands."))
        end

        self:RefreshCoachVisibility()
        self:RefreshStatusWidgetVisibility()
        self:RefreshCombatHUDVisibility()
        -- Defer heavier mount/item voice-cache work until the player has entered the world.
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
        self:RefreshStatusWidgetVisibility()
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
            self:HideInterruptActionGlows()
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
        self:ScheduleInterruptActionGlowRefresh()
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
    elseif event == "PLAYER_ENTERING_BATTLEGROUND" then
        self:ScheduleUpdate(false)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        self:ScheduleUpdate(false)
    elseif event == "PLAYER_TARGET_CHANGED" then
        targetInterruptEventState = nil
        self:UpdateInterruptAlert()
        ScheduleInterruptAlertRefreshes()
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        local unitTarget = ...
        if IsAccessibleValue(unitTarget) and type(unitTarget) == "string" and unitTarget == "target" then
            targetInterruptEventState = event == "UNIT_SPELLCAST_INTERRUPTIBLE"
            self:UpdateInterruptAlert()
            ScheduleInterruptAlertRefreshes()
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        local unitTarget = ...
        if IsAccessibleValue(unitTarget) and type(unitTarget) == "string" and unitTarget == "target" then
            targetInterruptEventState = nil
            self:UpdateInterruptAlert()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
        local unitTarget = ...
        if IsAccessibleValue(unitTarget) and type(unitTarget) == "string" and unitTarget == "target" then
            targetInterruptEventState = nil
            self:UpdateInterruptAlert()
            ScheduleInterruptAlertRefreshes()
        end
    elseif event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        local unitTarget = ...
        if IsAccessibleValue(unitTarget) and type(unitTarget) == "string" and unitTarget == "target" then
            self:UpdateInterruptAlert()
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
            ScheduleInterruptAlertRefreshes()
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
        if C_Timer and C_Timer.After then
            C_Timer.After(1.0, function()
                if addon.active then
                    addon.worldReady = true
                    addon:UpdateAll()
                    addon:ScheduleInterruptActionGlowRefresh()
                end
            end)
        else
            self.worldReady = true
            self:UpdateAll()
        end

        C_Timer.After(4, function()
            if addon.active then
                addon.worldReady = true
                addon:SyncCombatEventState()
                addon:SyncReadableBuffRuntime(true)
                if not (buffFrame and buffFrame.managedAuraContainer) then addon:RefreshCooldownViewerBuffMirrors() end
                addon:RefreshManagedDKBuffFilter()
                addon:RefreshVoiceTriggerCaches(false)
                addon:TryVoiceComment("zone")
                addon:UpdateAll()
                addon:RefreshCombatHUDVisibility()
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
        -- Gear Mentor can request uncached item names by item ID. Refresh the
        -- visible report when Blizzard finishes loading one so localized item
        -- names replace fallback labels without requiring the player to reopen it.
        if success and DB and DB.codexSection == "stats" and mainFrame and mainFrame:IsShown() then
            self:UpdateGuideSection()
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
            if DB and DB.codexSection == "stats" and DB.codexGearView == "preparation" then
                self:UpdateGuideSection()
            end
        end
    elseif event == "CHALLENGE_MODE_START" or event == "CHALLENGE_MODE_KEYSTONE_SLOTTED" or event == "CHALLENGE_MODE_RESET" or event == "UPDATE_BATTLEFIELD_STATUS" or event == "PVP_MATCH_ACTIVE" then
        self:ScheduleUpdate(false)
    elseif event == "CVAR_UPDATE" then
        local cvarName = ...
        if cvarName == "assistedCombatHighlight" or cvarName == "ASSISTEDCOMBATHIGHLIGHT" then
            self:UpdateAssistedCombatSection()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        InvalidateCooldownManagerProfileCache()
        if not unit or unit == "player" then
            if specializationPickerFrame then
                specializationPickerFrame:Hide()
                self:UpdateSpecializationPicker()
            end
            self:ScheduleUpdate(true)
            self:ScheduleInterruptActionGlowRefresh()
            C_Timer.After(0.5, function()
                if addon.active then
                    if not InCombatLockdown() and not (buffFrame and buffFrame.managedAuraContainer) then
                        addon:RefreshCooldownViewerBuffMirrors()
                    end
                    addon:RefreshManagedDKBuffFilter()
                    addon:UpdateStatusWidget()
                    addon:UpdateGuideSection()
                end
            end)
        end
    elseif event == "SPELLS_CHANGED"
        or event == "ACTIONBAR_SLOT_CHANGED"
        or event == "ACTIVE_TALENT_GROUP_CHANGED"
        or event == "PLAYER_TALENT_UPDATE"
        or event == "TRAIT_CONFIG_UPDATED"
        or event == "PLAYER_PVP_TALENT_UPDATE" then
        self:ScheduleUpdate(true)
        self:ScheduleInterruptActionGlowRefresh()
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

        -- Target spellcast event payloads can themselves be restricted in
        -- Midnight. Poll the sanctioned Unit cast API at the same lightweight
        -- HUD cadence so castBarID (NeverSecret) can drive presence and the raw
        -- Secret interruptibility boolean can flow directly into the frame.
        if interruptFrame and DB.interruptAlert and DB.interruptAlert.enabled == true then
            self:UpdateInterruptAlert()
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
        if detectedContext ~= self.currentContext then
            self.currentContext = detectedContext
            self:UpdateAll()
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
