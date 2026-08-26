local ADDON_NAME, DKM = ...

local addon = DKM and DKM.Addon
local Data = (DKM and DKM.Data) or {}
local T = (DKM and DKM.T) or function(value, ...)
    if select("#", ...) > 0 then
        local ok, text = pcall(string.format, value, ...)
        if ok then return text end
    end
    return tostring(value or "")
end

if not addon then
    return
end

local Engine = {}
DKM.MentorEngine = Engine

local RUNIC_POWER_TYPE = (Enum and Enum.PowerType and Enum.PowerType.RunicPower) or 6
local QUESTION_MARK_ICON = 134400
local MODE_ORDER = { "essential", "mentor", "training" }
local MODE_LABELS = {
    essential = "Essential",
    mentor = "Mentor",
    training = "Training",
}

local DEFAULTS = {
    mode = "mentor",
    defensive = true,
    utility = true,
    resourceWarnings = true,
    procWarnings = true,
    soloDelveBoost = true,
    insights = true,
    postCombat = true,
    lastReport = nil,
}

local PROC_RULES = {
    [250] = {
        [81141] = { consumers = { [43265] = true }, action = 43265 },     -- Crimson Scourge -> Death and Decay
        [1265790] = { consumers = { [50842] = true }, action = 50842 },   -- Boiling Point -> Blood Boil
        [433895] = { consumers = { [206930] = true }, action = 206930 },  -- Vampiric Strike -> Heart Strike override
    },
    [251] = {
        [51124] = { consumers = { [49020] = true, [207230] = true }, action = 49020 }, -- Killing Machine
        [59052] = { consumers = { [49184] = true }, action = 49184 },                   -- Rime
        [1229310] = { consumers = { [49143] = true, [1228433] = true, [1228436] = true, [1228443] = true }, action = 49143 }, -- Frostbane
    },
    [252] = {
        [81340] = { consumers = { [47541] = true, [207317] = true }, action = 47541 }, -- Sudden Doom
    },
}

local DEFENSIVE_SPELLS = {
    [49998] = true,  -- Death Strike
    [48707] = true,  -- Anti-Magic Shell
    [48792] = true,  -- Icebound Fortitude
    [48743] = true,  -- Death Pact
    [55233] = true,  -- Vampiric Blood
    [49028] = true,  -- Dancing Rune Weapon
    [194679] = true, -- Rune Tap
    [51052] = true,  -- Anti-Magic Zone
    [49039] = true,  -- Lichborne
}

local UTILITY_STOP_SPELLS = {
    [221562] = true, -- Asphyxiate
    [207167] = true, -- Blinding Sleet
    [49576] = true,  -- Death Grip
}

local state = {
    inCombat = false,
    playerGUID = nil,
    combat = nil,
    damageSamples = {},
    lastPlayerHealth = nil,
    lastPlayerMaxHealth = nil,
    targetCast = nil,
    targetAuras = {},
    boneShieldStacks = nil,
    procActive = {},
    sampleElapsed = 0,
    coachElapsed = 0,
    uiElapsed = 0,
    setupDone = false,
}

local configFrame
local postCombatFrame
local mainInsightSection
local settingsButton

local function Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0DK Mentor|r: " .. tostring(message or ""))
    end
end

local function IsSecretValue(value)
    if not issecretvalue then return false end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret == true
end

local function IsAccessibleValue(value)
    if IsSecretValue(value) then return false end
    if value == nil then return false end
    if canaccessvalue then
        local ok, accessible = pcall(canaccessvalue, value)
        if ok and accessible == false then return false end
    end
    return true
end

local function IsAccessibleNumber(value)
    return IsAccessibleValue(value) and type(value) == "number"
end

local function GetAccessibleBoolean(value)
    if not IsAccessibleValue(value) or type(value) ~= "boolean" then return nil end
    return value == true
end

local function Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function Round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function CopyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then target[key] = value end
    end
end

local function EnsureDB()
    _G.DKMentorDB = _G.DKMentorDB or {}
    local db = _G.DKMentorDB
    if type(db.mentor) ~= "table" then db.mentor = {} end
    CopyDefaults(db.mentor, DEFAULTS)
    if not MODE_LABELS[db.mentor.mode] then db.mentor.mode = "mentor" end
    return db, db.mentor
end

local function GetNow()
    if GetTime then
        local ok, value = pcall(GetTime)
        if ok and IsAccessibleNumber(value) then return value end
    end
    return 0
end

local function GetSpellData(spellID, fallbackName)
    local name, icon
    if spellID and C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and not IsSecretValue(info) and info ~= nil and IsAccessibleValue(info.name) then
            name = info.name
            icon = info.iconID
        end
    end
    if spellID and not name and GetSpellInfo then
        local ok, spellName, _, spellIcon = pcall(GetSpellInfo, spellID)
        if ok and IsAccessibleValue(spellName) then
            name = spellName
            icon = spellIcon
        end
    end
    return name or fallbackName or ("Spell " .. tostring(spellID or "?")), icon or QUESTION_MARK_ICON
end

local function IsSpellKnownSafe(spellID)
    if not spellID then return false end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellID)
        local value = ok and GetAccessibleBoolean(known) or nil
        if value ~= nil then return value end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellID)
        local value = ok and GetAccessibleBoolean(known) or nil
        if value ~= nil then return value end
    end
    return true
end

local function IsSpellReadySafe(spellID)
    if not IsSpellKnownSafe(spellID) then return false end
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
        if ok and not IsSecretValue(info) and info ~= nil then
            if IsAccessibleNumber(info.duration) and IsAccessibleNumber(info.startTime) then
                return info.duration <= 0 or info.startTime <= 0
            end
        end
    elseif GetSpellCooldown then
        local ok, startTime, duration = pcall(GetSpellCooldown, spellID)
        if ok and IsAccessibleNumber(startTime) and IsAccessibleNumber(duration) then
            return duration <= 0 or startTime <= 0
        end
    end
    return true
end

local function GetPlayerHealthPercent()
    if not UnitHealth or not UnitHealthMax then return nil end
    local okHealth, health = pcall(UnitHealth, "player")
    local okMax, maximum = pcall(UnitHealthMax, "player")
    if not okHealth or not okMax or not IsAccessibleNumber(health) or not IsAccessibleNumber(maximum) or maximum <= 0 then
        return nil
    end
    return Clamp((health / maximum) * 100, 0, 100)
end

local function GetPlayerMaxHealth()
    if not UnitHealthMax then return nil end
    local ok, maximum = pcall(UnitHealthMax, "player")
    if ok and IsAccessibleNumber(maximum) and maximum > 0 then return maximum end
    return nil
end

local function GetRunicPowerPercent()
    if not UnitPower or not UnitPowerMax then return nil end
    local okPower, power = pcall(UnitPower, "player", RUNIC_POWER_TYPE)
    local okMax, maximum = pcall(UnitPowerMax, "player", RUNIC_POWER_TYPE)
    if not okPower or not okMax or not IsAccessibleNumber(power) or not IsAccessibleNumber(maximum) or maximum <= 0 then
        return nil
    end
    return Clamp((power / maximum) * 100, 0, 100)
end

local function GetReadyRuneCount()
    if not GetRuneCooldown then return nil end
    local count = 0
    local readable = 0
    for index = 1, 6 do
        local ok, startTime, duration, rawReady = pcall(GetRuneCooldown, index)
        if ok then
            local ready = GetAccessibleBoolean(rawReady)
            if ready ~= nil then
                readable = readable + 1
                if ready then count = count + 1 end
            elseif IsAccessibleNumber(startTime) and IsAccessibleNumber(duration) then
                readable = readable + 1
                if duration <= 0 or startTime <= 0 then count = count + 1 end
            end
        end
    end
    if readable == 0 then return nil end
    return count
end

local function GetPlayerAuraApplicationsSafe(spellID)
    if not spellID then return nil end
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok then
            if IsSecretValue(aura) then return nil end
            if aura ~= nil then
                local applications = aura.applications or aura.charges
                if IsAccessibleNumber(applications) then return applications end
                return 1
            end
        end
    end
    if AuraUtil and AuraUtil.FindAuraBySpellID then
        local ok, _, _, count = pcall(AuraUtil.FindAuraBySpellID, spellID, "player", "HELPFUL")
        if ok and IsAccessibleNumber(count) then return count end
    end
    return nil
end

local function IsPlayerAuraActiveSafe(spellID)
    if not spellID then return nil end
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok then
            if IsSecretValue(aura) then return nil end
            if aura == nil then return false end
            return true
        end
    end
    return nil
end

local function GetUnitGUIDSafe(unit)
    if not UnitGUID then return nil end
    local ok, guid = pcall(UnitGUID, unit)
    if ok and IsAccessibleValue(guid) then return guid end
    return nil
end

local function GetCurrentTargetAuraState()
    -- Midnight 12.x restricts target aura inspection during combat. Never infer
    -- a missing disease/wound from an unreadable restricted aura. We only return
    -- state that was safely observed outside the restricted combat path.
    if state.inCombat then return nil end
    if not (C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID) then return nil end

    local S = Data.spells or {}
    local result = {}
    local readable = false

    local function ReadAura(spellID)
        local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "target", spellID)
        if not ok or IsSecretValue(aura) then return nil, nil, false end
        readable = true
        if aura == nil then return false, 0, true end
        local applications = aura.applications or aura.charges
        if IsAccessibleNumber(applications) then return true, applications, true end
        return true, nil, true
    end

    local disease, _, diseaseReadable = ReadAura(S.VIRULENT_PLAGUE or 191587)
    if diseaseReadable then result.disease = disease end

    local woundsPresent, wounds, woundsReadable = ReadAura(S.FESTERING_WOUND or 194310)
    if woundsReadable then
        result.wounds = woundsPresent and wounds or 0
    end

    return readable and result or nil
end

local function GetTargetClassification()
    if not UnitExists or not UnitClassification then return nil end
    local okExists, exists = pcall(UnitExists, "target")
    if not okExists or GetAccessibleBoolean(exists) ~= true then return nil end
    local ok, classification = pcall(UnitClassification, "target")
    if ok and IsAccessibleValue(classification) and type(classification) == "string" then return classification end
    return nil
end

local function GetTargetCastStateFromAPI()
    local hasCast = false
    local interruptible
    local castKey
    local spellID

    if UnitCastingInfo then
        local ok, _, _, _, _, _, _, _, notInterruptible, rawSpellID, castBarID = pcall(UnitCastingInfo, "target")
        if ok and IsAccessibleNumber(castBarID) then
            hasCast = true
            castKey = tostring(castBarID)
            if IsAccessibleNumber(rawSpellID) then spellID = rawSpellID end
            local guarded = GetAccessibleBoolean(notInterruptible)
            if guarded ~= nil then interruptible = not guarded end
        end
    end

    if not hasCast and UnitChannelInfo then
        local ok, _, _, _, _, _, _, notInterruptible, rawSpellID, _, _, castBarID = pcall(UnitChannelInfo, "target")
        if ok and IsAccessibleNumber(castBarID) then
            hasCast = true
            castKey = tostring(castBarID)
            if IsAccessibleNumber(rawSpellID) then spellID = rawSpellID end
            local guarded = GetAccessibleBoolean(notInterruptible)
            if guarded ~= nil then interruptible = not guarded end
        end
    end

    return hasCast, interruptible, castKey, spellID
end

local function RefreshTargetCastFromAPI()
    local hasCast, interruptible, castKey, spellID = GetTargetCastStateFromAPI()
    if not hasCast then return end

    state.targetCast = state.targetCast or {}
    if castKey then state.targetCast.castKey = castKey end
    if spellID then state.targetCast.spellID = spellID end
    state.targetCast.targetGUID = GetUnitGUIDSafe("target")

    -- Dedicated interruptibility events are authoritative. The cast API is only
    -- a fallback for frames where the unit event has not arrived yet.
    if state.targetCast.explicitInterruptible == nil and interruptible ~= nil then
        state.targetCast.interruptible = interruptible
    end
end

local function ScheduleTargetCastRefreshes()
    if not (C_Timer and C_Timer.After) then return end
    for _, delay in ipairs({ 0.05, 0.20, 0.80 }) do
        C_Timer.After(delay, function()
            if addon.active then
                RefreshTargetCastFromAPI()
                addon:UpdateCoach()
            end
        end)
    end
end

local function IsBossClassification(classification)
    return classification == "worldboss"
end

local function IsEliteClassification(classification)
    return classification == "worldboss" or classification == "elite" or classification == "rareelite"
end

local function PruneDamageSamples(now)
    local first = 1
    while state.damageSamples[first] and (now - state.damageSamples[first].time) > 5 do
        first = first + 1
    end
    if first > 1 then
        local compact = {}
        for index = first, #state.damageSamples do compact[#compact + 1] = state.damageSamples[index] end
        state.damageSamples = compact
    end
end

local function GetRecentDamagePercent(magicOnly)
    local now = GetNow()
    PruneDamageSamples(now)
    local maximum = GetPlayerMaxHealth()
    if not maximum then return nil end
    local total = 0
    local readableSamples = 0
    for _, sample in ipairs(state.damageSamples) do
        if not magicOnly then
            total = total + sample.amount
            readableSamples = readableSamples + 1
        elseif sample.magic == true then
            total = total + sample.amount
            readableSamples = readableSamples + 1
        end
    end
    if magicOnly and readableSamples == 0 then return nil end
    return Clamp((total / maximum) * 100, 0, 999)
end

local function AddDamageSample(amount, school)
    if not IsAccessibleNumber(amount) or amount <= 0 then return end
    local magic
    if IsAccessibleNumber(school) then magic = school ~= 1 end
    state.damageSamples[#state.damageSamples + 1] = { time = GetNow(), amount = amount, magic = magic }
end

local function SamplePlayerHealthDamage()
    if not UnitHealth or not UnitHealthMax then return end
    local okHealth, health = pcall(UnitHealth, "player")
    local okMax, maximum = pcall(UnitHealthMax, "player")
    if not okHealth or not okMax or not IsAccessibleNumber(health) or not IsAccessibleNumber(maximum) or maximum <= 0 then
        return
    end

    -- Midnight removes addon access to the combat log. For the player's own
    -- defensive coaching we can still safely infer recent incoming damage from
    -- readable player-health deltas. The damage school is deliberately unknown.
    if state.lastPlayerHealth and state.lastPlayerMaxHealth == maximum and health < state.lastPlayerHealth then
        AddDamageSample(state.lastPlayerHealth - health, nil)
    end
    state.lastPlayerHealth = health
    state.lastPlayerMaxHealth = maximum
end

local function GetMappedProcID(actionSpellID, specID)
    local bySpec = Data.procGlowMappings and Data.procGlowMappings[specID]
    if bySpec and bySpec[actionSpellID] then return bySpec[actionSpellID] end
    local rules = PROC_RULES[specID]
    if rules and rules[actionSpellID] then return actionSpellID end
    return nil
end

local function GetActiveProcRule(specID)
    local rules = PROC_RULES[specID] or {}
    local bestProc, bestState, bestRule
    for procID, active in pairs(state.procActive) do
        local rule = rules[procID]
        if rule and active and not active.hideAt then
            if not bestState or (active.startedAt or 0) < (bestState.startedAt or 0) then
                bestProc, bestState, bestRule = procID, active, rule
            end
        end
    end
    return bestProc, bestState, bestRule
end

local function FinalizeProcHides()
    local now = GetNow()
    for procID, active in pairs(state.procActive) do
        if active.hideAt and (now - active.hideAt) >= 0.25 then
            if state.combat and not active.consumed and (active.hideAt - (active.startedAt or active.hideAt)) >= 0.20 then
                state.combat.procExpired = state.combat.procExpired + 1
            end
            state.procActive[procID] = nil
        end
    end
end

local function ConsumeProcForSpell(spellID)
    local specID = select(1, addon:GetSpecInfo())
    local rules = PROC_RULES[specID] or {}
    for procID, active in pairs(state.procActive) do
        local rule = rules[procID]
        if rule and rule.consumers and rule.consumers[spellID] and active and not active.consumed then
            active.consumed = true
            if state.combat then state.combat.procConsumed = state.combat.procConsumed + 1 end
        end
    end
end

local function MarkDangerHandled()
    if state.combat and state.combat.dangerActive and not state.combat.dangerActive.handled then
        state.combat.dangerActive.handled = true
        state.combat.dangerHandled = state.combat.dangerHandled + 1
    end
end

local function GetMode()
    local _, cfg = EnsureDB()
    return cfg.mode
end

local function GetModeLabel()
    return T(MODE_LABELS[GetMode()] or "Mentor")
end

local function CycleMode(direction)
    local _, cfg = EnsureDB()
    local current = 2
    for index, key in ipairs(MODE_ORDER) do if key == cfg.mode then current = index break end end
    direction = tonumber(direction) or 1
    current = current + direction
    if current > #MODE_ORDER then current = 1 end
    if current < 1 then current = #MODE_ORDER end
    cfg.mode = MODE_ORDER[current]
    addon:UpdateCoach()
    Engine.UpdateUI()
    Print(T("Adaptive Coach mode: %s", GetModeLabel()))
end

local function MakeCoachEntry(spellID, title, whenText, optional, fallbackName)
    return {
        spellID = spellID,
        title = T(title),
        when = T(whenText),
        optional = optional == true,
        fallbackName = fallbackName and T(fallbackName) or fallbackName,
    }
end

local function AddCoachEntry(result, entry)
    if not entry or not entry.spellID or #result >= 3 then return end
    for _, existing in ipairs(result) do
        if existing.spellID == entry.spellID then return end
    end
    if entry.optional and not IsSpellKnownSafe(entry.spellID) then return end
    result[#result + 1] = entry
end

local function GetBestUtilityStop()
    local S = Data.spells or {}
    for _, spellID in ipairs({ S.ASPHYXIATE or 221562, S.BLINDING_SLEET or 207167, S.DEATH_GRIP or 49576 }) do
        if IsSpellKnownSafe(spellID) and IsSpellReadySafe(spellID) then return spellID end
    end
    return nil
end

local function GetDefensivePriority(specID, health, recentDamage, magicDamage)
    local S = Data.spells or {}
    if specID == 250 then
        if health and health <= 32 and IsSpellReadySafe(S.VAMPIRIC_BLOOD or 55233) then
            return MakeCoachEntry(S.VAMPIRIC_BLOOD or 55233, "USE NOW", "critical health / amplify recovery")
        end
        if health and health <= 60 and IsSpellReadySafe(S.DEATH_STRIKE or 49998) then
            return MakeCoachEntry(S.DEATH_STRIKE or 49998, "RECOVER", "after the damage spike")
        end
        if recentDamage and recentDamage >= 18 and IsSpellReadySafe(S.RUNE_TAP or 194679) then
            return MakeCoachEntry(S.RUNE_TAP or 194679, "MITIGATE", "heavy incoming pressure", true)
        end
        if magicDamage and magicDamage >= 12 and IsSpellReadySafe(S.ANTI_MAGIC_SHELL or 48707) then
            return MakeCoachEntry(S.ANTI_MAGIC_SHELL or 48707, "MAGIC", "repeated magic pressure")
        end
    else
        if health and health <= 30 and IsSpellReadySafe(S.ICEBOUND_FORTITUDE or 48792) then
            return MakeCoachEntry(S.ICEBOUND_FORTITUDE or 48792, "USE NOW", "critical health / heavy pressure")
        end
        if health and health <= 62 and IsSpellReadySafe(S.DEATH_STRIKE or 49998) then
            return MakeCoachEntry(S.DEATH_STRIKE or 49998, "RECOVER", "convert Runic Power into survival")
        end
        if magicDamage and magicDamage >= 12 and IsSpellReadySafe(S.ANTI_MAGIC_SHELL or 48707) then
            return MakeCoachEntry(S.ANTI_MAGIC_SHELL or 48707, "MAGIC", "repeated magic pressure")
        end
    end
    return nil
end

local function GetResourceSpender(specID)
    if specID == 250 then return 49998 end
    if specID == 251 then return 49143 end
    if specID == 252 then return 47541 end
    return 49998
end

local originalAdaptiveCoach = addon.GetAdaptiveCoachEntries
function addon:GetAdaptiveCoachEntries(specID, context, baseEntries)
    local rootDB, cfg = EnsureDB()
    local adaptiveHealthEnabled = not (type(rootDB.coach) == "table" and rootDB.coach.adaptiveHealth == false)
    local mode = cfg.mode or "mentor"
    local health = GetPlayerHealthPercent()
    local recentDamage = GetRecentDamagePercent(false)
    local magicDamage = GetRecentDamagePercent(true)
    local runicPower = GetRunicPowerPercent()
    local readyRunes = GetReadyRuneCount()
    local classification = GetTargetClassification()
    local result = {}
    local stateLabel = "STABLE"

    if health and health <= 30 then stateLabel = "CRITICAL"
    elseif health and health <= 50 then stateLabel = "DANGER"
    elseif health and health <= 70 then stateLabel = "RECOVER"
    elseif recentDamage and recentDamage >= 20 then stateLabel = "PRESSURE" end

    -- 1) Life-threatening state always wins.
    if cfg.defensive ~= false and adaptiveHealthEnabled then
        AddCoachEntry(result, GetDefensivePriority(specID, health, recentDamage, magicDamage))
    end

    -- 2) Interruptible target casts are a core DK responsibility.
    if state.targetCast and state.targetCast.interruptible == true and cfg.utility ~= false then
        local mindFreeze = (Data.spells and Data.spells.MIND_FREEZE) or 47528
        if IsSpellKnownSafe(mindFreeze) then
            AddCoachEntry(result, MakeCoachEntry(mindFreeze, "INTERRUPT", "target cast is interruptible"))
        end
    end

    -- 3) Non-interruptible casts on non-boss targets can often be stopped with DK control.
    if #result < 3 and mode ~= "essential" and cfg.utility ~= false and state.targetCast and state.targetCast.interruptible == false and not IsBossClassification(classification) then
        local utilitySpell = GetBestUtilityStop()
        if utilitySpell then
            AddCoachEntry(result, MakeCoachEntry(utilitySpell, "STOP CAST", "non-interruptible cast — try DK control"))
        end
    end

    -- 4) Boss/elite awareness: do not pretend to know encounter timers; react to what is observable.
    if #result < 3 and mode ~= "essential" and cfg.defensive ~= false and state.targetCast and state.targetCast.interruptible == false and IsBossClassification(classification) then
        local defensive = (magicDamage and magicDamage >= 8) and ((Data.spells and Data.spells.ANTI_MAGIC_SHELL) or 48707) or ((Data.spells and Data.spells.ICEBOUND_FORTITUDE) or 48792)
        if IsSpellReadySafe(defensive) then
            AddCoachEntry(result, MakeCoachEntry(defensive, "PREPARE", "boss cast cannot be interrupted"))
        end
    end

    -- 5) Spec-state coaching when the client exposes the required state.
    if #result < 3 and mode ~= "essential" then
        local S = Data.spells or {}
        if specID == 250 then
            local boneShieldID = S.BONE_SHIELD or 195181
            local boneStacks = GetPlayerAuraApplicationsSafe(boneShieldID)
            if boneStacks == nil and IsPlayerAuraActiveSafe(boneShieldID) == false then boneStacks = 0 end
            if boneStacks == nil then boneStacks = state.boneShieldStacks end
            if boneStacks and boneStacks <= 3 and IsSpellKnownSafe(S.MARROWREND or 195182) then
                AddCoachEntry(result, MakeCoachEntry(S.MARROWREND or 195182, "BONE SHIELD", "low stacks — refresh before they fall"))
            end
        elseif specID == 252 then
            local auraState = GetCurrentTargetAuraState()
            if auraState then
                if auraState.disease == false and IsSpellKnownSafe(S.OUTBREAK or 77575) then
                    AddCoachEntry(result, MakeCoachEntry(S.OUTBREAK or 77575, "DISEASE", "Virulent Plague missing on current target"))
                elseif auraState.wounds and auraState.wounds <= 1 and IsEliteClassification(classification) and IsSpellKnownSafe(S.FESTERING_STRIKE or 85948) then
                    AddCoachEntry(result, MakeCoachEntry(S.FESTERING_STRIKE or 85948, "BUILD WOUNDS", "long-lived target has few Festering Wounds"))
                elseif auraState.wounds and auraState.wounds >= 6 and IsSpellKnownSafe(S.SCOURGE_STRIKE or 55090) then
                    AddCoachEntry(result, MakeCoachEntry(S.SCOURGE_STRIKE or 55090, "SPEND WOUNDS", "Festering Wounds are high — avoid overbuilding"))
                end
            end
        end
    end

    -- 6) Resource waste prevention.
    local rpThreshold = specID == 250 and 96 or 90
    local breathActive = specID == 251 and (IsPlayerAuraActiveSafe(152279) == true or IsPlayerAuraActiveSafe(1249658) == true)
    if #result < 3 and mode ~= "essential" and cfg.resourceWarnings ~= false and runicPower and runicPower >= rpThreshold and not breathActive then
        local spender = GetResourceSpender(specID)
        if IsSpellKnownSafe(spender) then
            AddCoachEntry(result, MakeCoachEntry(spender, "SPEND RP", "Runic Power near cap"))
        end
    end

    -- 7) High-value proc reaction. Training mode exposes this aggressively; Mentor uses it after urgent items.
    if #result < 3 and cfg.procWarnings ~= false and mode ~= "essential" then
        local _, _, procRule = GetActiveProcRule(specID)
        if procRule and procRule.action and IsSpellKnownSafe(procRule.action) then
            AddCoachEntry(result, MakeCoachEntry(procRule.action, "PROC", "high-value proc is active"))
        end
    end

    -- 8) Training-mode rune-idle warning.
    if #result < 3 and mode == "training" and cfg.resourceWarnings ~= false and readyRunes and readyRunes >= 5 then
        local builder = specID == 250 and 206930 or (specID == 251 and 49020 or 55090)
        if IsSpellKnownSafe(builder) then
            AddCoachEntry(result, MakeCoachEntry(builder, "USE RUNES", "5+ runes are ready"))
        end
    end

    -- 9) Solo/Delve emphasis: elites deserve earlier survival preparation.
    if #result < 3 and cfg.soloDelveBoost ~= false and mode ~= "essential" and (context == "world" or context == "delve") and IsEliteClassification(classification) then
        local S = Data.spells or {}
        if specID == 250 and IsSpellReadySafe(S.DANCING_RUNE_WEAPON or 49028) then
            AddCoachEntry(result, MakeCoachEntry(S.DANCING_RUNE_WEAPON or 49028, "ELITE", "use early if the pull is dangerous"))
        elseif IsSpellReadySafe(S.ANTI_MAGIC_SHELL or 48707) then
            AddCoachEntry(result, MakeCoachEntry(S.ANTI_MAGIC_SHELL or 48707, "ELITE", "keep a defensive ready"))
        end
    end

    -- Preserve the curated context-specific DK recommendations as the fallback layer.
    for _, entry in ipairs(baseEntries or {}) do
        if #result >= 3 then break end
        AddCoachEntry(result, entry)
    end

    if #result == 0 and originalAdaptiveCoach then
        return originalAdaptiveCoach(self, specID, context, baseEntries)
    end

    local modeState = string.upper(T(MODE_LABELS[mode] or "Mentor")) .. " • " .. T(stateLabel)
    return result, health, modeState
end

local originalUpdateCoach = addon.UpdateCoach
function addon:UpdateCoach(...)
    originalUpdateCoach(self, ...)
    local frame = _G.DKMentorCoachFrame
    if not frame then return end
    local specID, specName = self:GetSpecInfo()
    local context = select(1, self:DetectContext())
    local contextName = self.GetRuntimeContextLabel and self:GetRuntimeContextLabel(context) or T((Data.contextNames and Data.contextNames[context]) or context)
    if frame.title then
        frame.title:SetText(T("DK Mentor — %s / %s • %s", specName or tostring(specID), contextName or "?", GetModeLabel()))
    end
end

local function StartCombatSession()
    local now = GetNow()
    local observedTargetCast = state.targetCast
    state.inCombat = true
    state.playerGUID = GetUnitGUIDSafe("player")
    state.damageSamples = {}
    state.lastPlayerHealth = nil
    state.lastPlayerMaxHealth = nil
    SamplePlayerHealthDamage()
    state.procActive = {}
    state.targetCast = observedTargetCast
    state.targetAuras = {}
    state.boneShieldStacks = GetPlayerAuraApplicationsSafe((Data.spells and Data.spells.BONE_SHIELD) or 195181)
    local specID = select(1, addon:GetSpecInfo())
    state.combat = {
        startedAt = now,
        specID = specID,
        highRPSeconds = 0,
        runeWasteSeconds = 0,
        resourceSamples = 0,
        runeSamples = 0,
        healthSamples = 0,
        minHealth = 100,
        maxRecentDamage = 0,
        procConsumed = 0,
        procExpired = 0,
        interruptHandled = 0,
        playerInterrupts = 0,
        interruptMissed = 0,
        utilityHandled = 0,
        utilityMissed = 0,
        dangerWindows = 0,
        dangerHandled = 0,
        dangerActive = nil,
        defensiveCasts = 0,
        recoveryCasts = 0,
    }
    RefreshTargetCastFromAPI()
    ScheduleTargetCastRefreshes()
end

local function BuildScoreReport(session, duration)
    duration = math.max(1, tonumber(duration) or 1)
    local components = {}
    local weights = {}

    if session.resourceSamples > 0 or session.runeSamples > 0 then
        local rpRatio = Clamp(session.highRPSeconds / duration, 0, 1)
        local runeRatio = Clamp(session.runeWasteSeconds / duration, 0, 1)
        local runePenalty = session.specID == 250 and 20 or 35
        local rpPenalty = session.specID == 250 and 50 or 65
        local score = Clamp(100 - (rpRatio * rpPenalty) - (runeRatio * runePenalty), 0, 100)
        components.resources = Round(score)
        weights.resources = 30
    end

    local procTotal = session.procConsumed + session.procExpired
    if procTotal > 0 then
        components.procs = Round((session.procConsumed / procTotal) * 100)
        weights.procs = 25
    end

    local interruptTotal = session.interruptHandled + session.interruptMissed
    if interruptTotal > 0 then
        components.interrupts = Round((session.interruptHandled / interruptTotal) * 100)
        weights.interrupts = 20
    end

    if session.dangerWindows > 0 then
        components.survival = Round((session.dangerHandled / session.dangerWindows) * 100)
        weights.survival = 25
    elseif session.healthSamples > 0 then
        components.survival = 100
        weights.survival = 15
    end

    local weighted, totalWeight = 0, 0
    for key, score in pairs(components) do
        local weight = weights[key] or 0
        weighted = weighted + (score * weight)
        totalWeight = totalWeight + weight
    end
    local overall = totalWeight > 0 and Round(weighted / totalWeight) or 100

    local insights = {}
    local function AddInsight(text)
        if #insights < 4 then insights[#insights + 1] = text end
    end

    if session.interruptMissed > 0 then
        AddInsight(T("%d interruptible cast(s) completed without a detected stop.", session.interruptMissed))
    end
    local unhandledDanger = math.max(0, session.dangerWindows - session.dangerHandled)
    if unhandledDanger > 0 then
        AddInsight(T("%d critical-health window(s) had no defensive/recovery response detected.", unhandledDanger))
    end
    if session.highRPSeconds >= math.max(2, duration * 0.08) then
        AddInsight(T("Runic Power stayed near cap for %.1f seconds.", session.highRPSeconds))
    end
    if session.runeWasteSeconds >= math.max(2, duration * 0.08) then
        AddInsight(T("Five or more Runes stayed ready for %.1f seconds.", session.runeWasteSeconds))
    end
    if session.procExpired > 0 then
        AddInsight(T("%d important proc window(s) ended without a detected consumer.", session.procExpired))
    end
    if session.utilityMissed > 0 and #insights < 4 then
        AddInsight(T("%d non-boss cast(s) completed while a DK control response may have been possible.", session.utilityMissed))
    end
    if #insights == 0 then
        AddInsight(T("Clean execution: no major DK Mentor mistakes were detected in the readable combat data."))
    end

    local stamp
    if date then
        local ok, text = pcall(date, "%Y-%m-%d %H:%M")
        if ok then stamp = text end
    end

    return {
        score = overall,
        duration = Round(duration),
        components = components,
        insights = insights,
        minHealth = Round(session.minHealth or 100),
        highRPSeconds = session.highRPSeconds,
        runeWasteSeconds = session.runeWasteSeconds,
        procConsumed = session.procConsumed,
        procExpired = session.procExpired,
        interrupts = session.playerInterrupts,
        interruptHandled = session.interruptHandled,
        interruptMissed = session.interruptMissed,
        utilityHandled = session.utilityHandled,
        utilityMissed = session.utilityMissed,
        dangerWindows = session.dangerWindows,
        dangerHandled = session.dangerHandled,
        defensiveCasts = session.defensiveCasts,
        timestamp = stamp,
    }
end

local function EndCombatSession()
    if not state.combat then
        state.inCombat = false
        return
    end
    FinalizeProcHides()
    local now = GetNow()
    local duration = math.max(0, now - (state.combat.startedAt or now))
    local report = BuildScoreReport(state.combat, duration)
    local _, cfg = EnsureDB()
    if duration >= 5 then
        cfg.lastReport = report
        Engine.UpdateUI()
        if cfg.insights ~= false and cfg.postCombat ~= false then Engine.ShowPostCombat(report) end
    end
    state.inCombat = false
    state.combat = nil
    state.damageSamples = {}
    state.lastPlayerHealth = nil
    state.lastPlayerMaxHealth = nil
    state.targetCast = nil
    state.targetAuras = {}
    state.boneShieldStacks = nil
    state.procActive = {}
end

local function SampleCombat(delta)
    if not state.inCombat or not state.combat then return end
    local session = state.combat
    SamplePlayerHealthDamage()
    local health = GetPlayerHealthPercent()
    if health then
        session.healthSamples = session.healthSamples + 1
        session.minHealth = math.min(session.minHealth or 100, health)
        if health <= 40 and not session.dangerActive then
            session.dangerWindows = session.dangerWindows + 1
            session.dangerActive = { startedAt = GetNow(), handled = false }
        elseif health > 55 and session.dangerActive then
            session.dangerActive = nil
        end
    end

    local recentDamage = GetRecentDamagePercent(false)
    if recentDamage then session.maxRecentDamage = math.max(session.maxRecentDamage or 0, recentDamage) end

    if session.specID == 250 then
        local boneShieldID = (Data.spells and Data.spells.BONE_SHIELD) or 195181
        local boneStacks = GetPlayerAuraApplicationsSafe(boneShieldID)
        if boneStacks ~= nil then
            state.boneShieldStacks = boneStacks
        elseif IsPlayerAuraActiveSafe(boneShieldID) == false then
            state.boneShieldStacks = 0
        end
    end

    local rp = GetRunicPowerPercent()
    if rp then
        session.resourceSamples = session.resourceSamples + 1
        local threshold = session.specID == 250 and 96 or 90
        local breathActive = session.specID == 251 and (IsPlayerAuraActiveSafe(152279) == true or IsPlayerAuraActiveSafe(1249658) == true)
        if rp >= threshold and not breathActive then session.highRPSeconds = session.highRPSeconds + delta end
    end

    local runes = GetReadyRuneCount()
    if runes then
        session.runeSamples = session.runeSamples + 1
        if runes >= 5 then session.runeWasteSeconds = session.runeWasteSeconds + delta end
    end
end

local function OpenInterruptWindow(castKey)
    state.targetCast = state.targetCast or {}
    if state.targetCast.interruptKey ~= castKey then
        state.targetCast.interruptKey = castKey
        state.targetCast.resolved = false
    end
    state.targetCast.interruptible = true
    state.targetCast.explicitInterruptible = true
end

local function OpenUtilityWindow(castKey)
    state.targetCast = state.targetCast or {}
    if state.targetCast.utilityKey ~= castKey then
        state.targetCast.utilityKey = castKey
        state.targetCast.utilityResolved = false
    end
    state.targetCast.interruptible = false
    state.targetCast.explicitInterruptible = false
end

local function ResolveCurrentCast(successfulCompletion)
    if state.combat and state.targetCast then
        if successfulCompletion then
            if state.targetCast.interruptKey and not state.targetCast.resolved then
                state.combat.interruptMissed = state.combat.interruptMissed + 1
            elseif state.targetCast.utilityKey and not state.targetCast.utilityResolved and not IsBossClassification(GetTargetClassification()) then
                state.combat.utilityMissed = state.combat.utilityMissed + 1
            end
        end
    end
    state.targetCast = nil
end

local function MarkInterruptHandled(byPlayer)
    if not state.combat or not state.targetCast or not state.targetCast.interruptKey or state.targetCast.resolved then return end
    state.targetCast.resolved = true
    state.combat.interruptHandled = state.combat.interruptHandled + 1
    if byPlayer then state.combat.playerInterrupts = state.combat.playerInterrupts + 1 end
end

local function MarkUtilityHandled()
    if not state.combat or not state.targetCast or not state.targetCast.utilityKey or state.targetCast.utilityResolved then return end
    state.targetCast.utilityResolved = true
    state.combat.utilityHandled = state.combat.utilityHandled + 1
end

local function HandlePlayerSpell(spellID)
    if not IsAccessibleNumber(spellID) then return end
    ConsumeProcForSpell(spellID)

    local mindFreeze = (Data.spells and Data.spells.MIND_FREEZE) or 47528
    if spellID == mindFreeze and state.targetCast and state.targetCast.interruptKey then
        -- Without CLEU, UNIT_SPELLCAST_SUCCEEDED on the player plus an active
        -- interrupt window is our safe signal that the player attempted the kick.
        MarkInterruptHandled(true)
    end

    if state.combat and DEFENSIVE_SPELLS[spellID] then
        state.combat.defensiveCasts = state.combat.defensiveCasts + 1
        if spellID == 49998 then state.combat.recoveryCasts = state.combat.recoveryCasts + 1 end
        MarkDangerHandled()
    end
    if state.combat and UTILITY_STOP_SPELLS[spellID] then MarkUtilityHandled() end
end

local function ToggleConfig(key)
    local _, cfg = EnsureDB()
    cfg[key] = not (cfg[key] ~= false)
    Engine.UpdateUI()
    addon:UpdateCoach()
end

function Engine.ResetSettings()
    local _, cfg = EnsureDB()
    local lastReport = cfg.lastReport
    for key, value in pairs(DEFAULTS) do
        if key ~= "lastReport" then
            cfg[key] = value
        end
    end
    cfg.lastReport = lastReport
    Engine.UpdateUI()
    addon:UpdateCoach()
    Print(T("Mentor settings restored to defaults."))
end

function Engine.TestAlerts()
    if addon.ShowMentorAlertPreview then
        return addon:ShowMentorAlertPreview()
    end
    return false
end

local function ApplyBackdrop(frame, alpha)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.015, 0.06, 0.08, alpha or 0.94)
    frame:SetBackdropBorderColor(0.20, 0.68, 0.86, 0.95)
end

local function CreateToggleButton(parent, width, point, relative, relativePoint, x, y, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 27)
    button:SetPoint(point, relative, relativePoint, x, y)
    button:SetScript("OnClick", callback)
    local font = button.GetFontString and button:GetFontString()
    if font and GameFontNormalSmall then font:SetFontObject(GameFontNormalSmall) end
    return button
end

local function FormatComponent(label, value)
    if value == nil then return T("%s: N/A", label) end
    return T("%s: %d", label, value)
end

local function ReportDetails(report)
    if not report then return T("No completed combat report yet.") end
    local c = report.components or {}
    local lines = {
        T("DK Mentor Score: %d/100", report.score or 0),
        T("Duration: %ds • Minimum health: %d%%", report.duration or 0, report.minHealth or 100),
        table.concat({
            FormatComponent(T("Resources"), c.resources),
            FormatComponent(T("Procs"), c.procs),
            FormatComponent(T("Defensives"), c.survival),
            FormatComponent(T("Interrupts"), c.interrupts),
        }, "   "),
        T("Runic Power near cap: %.1fs • 5+ Runes ready: %.1fs", report.highRPSeconds or 0, report.runeWasteSeconds or 0),
        T("Procs consumed: %d • estimated expired: %d", report.procConsumed or 0, report.procExpired or 0),
        T("Your interrupts: %d • handled opportunities: %d • completed casts: %d", report.interrupts or 0, report.interruptHandled or 0, report.interruptMissed or 0),
        T("Critical windows answered: %d/%d • defensive/recovery casts: %d", report.dangerHandled or 0, report.dangerWindows or 0, report.defensiveCasts or 0),
        "",
        T("What to improve:"),
    }
    for _, insight in ipairs(report.insights or {}) do lines[#lines + 1] = "• " .. insight end
    lines[#lines + 1] = ""
    lines[#lines + 1] = T("Scores use only combat data that the WoW client makes readable to addons. Encounter-specific boss timers remain the job of DBM/BigWigs; DK Mentor translates observable pressure, casts, resources, and procs into DK responses.")
    return table.concat(lines, "\n")
end

local function CreateConfigFrame()
    if configFrame then return configFrame end
    local frame = CreateFrame("Frame", "DKMentorIntelligenceFrame", UIParent, "BackdropTemplate")
    frame:SetSize(660, 560)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyBackdrop(frame, 0.98)
    frame:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -17)
    frame.title:SetText(T("Adaptive DK Coach"))
    frame.title:SetTextColor(0.55, 0.88, 1)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
    frame.subtitle:SetWidth(590)
    frame.subtitle:SetJustifyH("LEFT")
    frame.subtitle:SetText(T("Real-time DK priorities, defensive awareness, interrupt/control coaching, resource/proc waste detection, and post-combat execution insights."))

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    frame.modeButton = CreateToggleButton(frame, 190, "TOPLEFT", frame, "TOPLEFT", 18, -78, function() CycleMode(1) end)
    frame.defensiveButton = CreateToggleButton(frame, 190, "LEFT", frame.modeButton, "RIGHT", 12, 0, function() ToggleConfig("defensive") end)
    frame.utilityButton = CreateToggleButton(frame, 190, "LEFT", frame.defensiveButton, "RIGHT", 12, 0, function() ToggleConfig("utility") end)

    frame.resourceButton = CreateToggleButton(frame, 190, "TOPLEFT", frame, "TOPLEFT", 18, -113, function() ToggleConfig("resourceWarnings") end)
    frame.procButton = CreateToggleButton(frame, 190, "LEFT", frame.resourceButton, "RIGHT", 12, 0, function() ToggleConfig("procWarnings") end)
    frame.soloButton = CreateToggleButton(frame, 190, "LEFT", frame.procButton, "RIGHT", 12, 0, function() ToggleConfig("soloDelveBoost") end)

    frame.insightsButton = CreateToggleButton(frame, 190, "TOPLEFT", frame, "TOPLEFT", 18, -148, function() ToggleConfig("insights") end)
    frame.postButton = CreateToggleButton(frame, 190, "LEFT", frame.insightsButton, "RIGHT", 12, 0, function() ToggleConfig("postCombat") end)
    frame.clearButton = CreateToggleButton(frame, 190, "LEFT", frame.postButton, "RIGHT", 12, 0, function()
        local _, cfg = EnsureDB()
        cfg.lastReport = nil
        Engine.UpdateUI()
    end)

    frame.testButton = CreateToggleButton(frame, 190, "TOPLEFT", frame, "TOPLEFT", 18, -183, function() Engine.TestAlerts() end)
    frame.resetButton = CreateToggleButton(frame, 190, "LEFT", frame.testButton, "RIGHT", 12, 0, function() Engine.ResetSettings() end)

    frame.modeHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.modeHint:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -225)
    frame.modeHint:SetWidth(620)
    frame.modeHint:SetJustifyH("LEFT")
    frame.modeHint:SetText(T("Essential = only urgent survival/interrupt calls. Mentor = balanced default. Training = adds resource, proc, rune-idle, and possible control-stop coaching."))

    frame.reportTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.reportTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -263)
    frame.reportTitle:SetText(T("Last combat insights"))
    frame.reportTitle:SetTextColor(0.55, 0.88, 1)

    frame.report = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.report:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -287)
    frame.report:SetWidth(620)
    frame.report:SetHeight(235)
    frame.report:SetJustifyH("LEFT")
    frame.report:SetJustifyV("TOP")

    frame:Hide()
    configFrame = frame
    if UISpecialFrames then
        local found = false
        for _, name in ipairs(UISpecialFrames) do
            if name == "DKMentorIntelligenceFrame" then found = true break end
        end
        if not found then table.insert(UISpecialFrames, "DKMentorIntelligenceFrame") end
    end
    return frame
end

local POST_COMBAT_MIN_WIDTH = 300
local POST_COMBAT_MAX_WIDTH = 480
local POST_COMBAT_SIDE_PADDING = 14
local POST_COMBAT_TOP_PADDING = 10
local POST_COMBAT_BOTTOM_PADDING = 10
local POST_COMBAT_GAP = 5
local POST_COMBAT_MAX_INSIGHTS = 3

local function GetFontStringMetric(fontString, methodName, fallback)
    if fontString and fontString[methodName] then
        local ok, value = pcall(fontString[methodName], fontString)
        if ok and type(value) == "number" and value >= 0 then return value end
    end
    return fallback or 0
end

local function BuildPostCombatSummary(report)
    local source = (report and report.insights) or {}
    local visible = {}
    local count = math.min(#source, POST_COMBAT_MAX_INSIGHTS)
    for index = 1, count do
        visible[#visible + 1] = tostring(source[index] or "")
    end
    local extra = math.max(0, #source - count)
    if extra > 0 and #visible > 0 then
        visible[#visible] = visible[#visible] .. T("  (+%d more)", extra)
    end
    if #visible == 0 then visible[1] = T("No major issue detected.") end
    return table.concat(visible, "\n")
end

local function LayoutPostCombatFrame(frame, titleText, bodyText)
    if not frame then return end
    titleText = tostring(titleText or "")
    bodyText = tostring(bodyText or "")

    local maxWidth = POST_COMBAT_MAX_WIDTH
    if UIParent and UIParent.GetWidth then
        local ok, uiWidth = pcall(UIParent.GetWidth, UIParent)
        if ok and type(uiWidth) == "number" and uiWidth > 0 then
            maxWidth = math.min(maxWidth, math.max(POST_COMBAT_MIN_WIDTH, math.floor(uiWidth * 0.48)))
        end
    end

    local maxContentWidth = math.max(1, maxWidth - (POST_COMBAT_SIDE_PADDING * 2))
    frame.title:SetWidth(maxContentWidth)
    frame.text:SetWidth(maxContentWidth)
    frame.title:SetText(titleText)
    frame.text:SetText(bodyText)

    local titleWidth = GetFontStringMetric(frame.title, "GetStringWidth", #titleText * 7.5)
    local bodyWidth = GetFontStringMetric(frame.text, "GetStringWidth", #bodyText * 6.2)
    local desiredWidth = Clamp(math.ceil(math.max(titleWidth, bodyWidth) + (POST_COMBAT_SIDE_PADDING * 2)), POST_COMBAT_MIN_WIDTH, maxWidth)
    local contentWidth = math.max(1, desiredWidth - (POST_COMBAT_SIDE_PADDING * 2))

    frame.title:SetWidth(contentWidth)
    frame.text:SetWidth(contentWidth)
    local titleHeight = math.max(16, GetFontStringMetric(frame.title, "GetStringHeight", 16))
    local bodyHeight = math.max(14, GetFontStringMetric(frame.text, "GetStringHeight", 14))
    local desiredHeight = math.ceil(POST_COMBAT_TOP_PADDING + titleHeight + POST_COMBAT_GAP + bodyHeight + POST_COMBAT_BOTTOM_PADDING)

    frame:SetSize(desiredWidth, math.max(50, desiredHeight))
end

local function CreatePostCombatFrame()
    if postCombatFrame then return postCombatFrame end
    local frame = CreateFrame("Frame", "DKMentorPostCombatFrame", UIParent, "BackdropTemplate")
    frame:SetSize(POST_COMBAT_MIN_WIDTH, 58)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(false)
    ApplyBackdrop(frame, 0.92)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", POST_COMBAT_SIDE_PADDING, -POST_COMBAT_TOP_PADDING)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetJustifyV("TOP")
    frame.title:SetTextColor(0.55, 0.88, 1)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.text:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -POST_COMBAT_GAP)
    frame.text:SetJustifyH("LEFT")
    frame.text:SetJustifyV("TOP")
    frame:Hide()
    postCombatFrame = frame
    return frame
end

local function CreateMainIntegration()
    local main = _G.DKMentorMainFrame
    if not main or not main.pages then return end

    if not settingsButton and main.pages.settings then
        local settingsPage = main.pages.settings
        if settingsPage.scope and settingsPage.scope.SetWidth then settingsPage.scope:SetWidth(300) end
        settingsButton = CreateFrame("Button", nil, settingsPage, "UIPanelButtonTemplate")
        settingsButton:SetSize(180, 27)
        if main.languageButton then
            settingsButton:SetPoint("RIGHT", main.languageButton, "LEFT", -8, 0)
        else
            settingsButton:SetPoint("TOPRIGHT", settingsPage, "TOPRIGHT", -255, -2)
        end
        settingsButton:SetText(T("Mentor intelligence..."))
        settingsButton:SetScript("OnClick", function() Engine.ToggleConfig() end)
        local font = settingsButton.GetFontString and settingsButton:GetFontString()
        if font and GameFontNormalSmall then font:SetFontObject(GameFontNormalSmall) end
    end

    if not mainInsightSection and main.pages.combat then
        local page = main.pages.combat
        local section = CreateFrame("Frame", nil, page, "BackdropTemplate")
        section:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -522)
        section:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -522)
        section:SetHeight(82)
        ApplyBackdrop(section, 0.64)

        section.title = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        section.title:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -10)
        section.title:SetText(T("Adaptive DK Coach — last combat"))
        section.title:SetTextColor(0.55, 0.88, 1)

        section.score = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        section.score:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -34)
        section.score:SetWidth(180)
        section.score:SetJustifyH("LEFT")

        section.insight = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        section.insight:SetPoint("TOPLEFT", section, "TOPLEFT", 190, -31)
        section.insight:SetWidth(470)
        section.insight:SetHeight(42)
        section.insight:SetJustifyH("LEFT")
        section.insight:SetJustifyV("TOP")

        section.button = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
        section.button:SetSize(120, 24)
        section.button:SetPoint("TOPRIGHT", section, "TOPRIGHT", -10, -7)
        section.button:SetText(T("Details..."))
        section.button:SetScript("OnClick", function() Engine.ToggleConfig() end)

        mainInsightSection = section
    end
end

function Engine.UpdateUI()
    local _, cfg = EnsureDB()
    if not state.setupDone then CreateMainIntegration() end
    if configFrame then
        configFrame.modeButton:SetText(T("Mode: %s", GetModeLabel()))
        configFrame.defensiveButton:SetText(T(cfg.defensive ~= false and "Defensive Advisor: ON" or "Defensive Advisor: OFF"))
        configFrame.utilityButton:SetText(T(cfg.utility ~= false and "Interrupt/Utility: ON" or "Interrupt/Utility: OFF"))
        configFrame.resourceButton:SetText(T(cfg.resourceWarnings ~= false and "Resource warnings: ON" or "Resource warnings: OFF"))
        configFrame.procButton:SetText(T(cfg.procWarnings ~= false and "Proc warnings: ON" or "Proc warnings: OFF"))
        configFrame.soloButton:SetText(T(cfg.soloDelveBoost ~= false and "Solo/Delve boost: ON" or "Solo/Delve boost: OFF"))
        configFrame.insightsButton:SetText(T(cfg.insights ~= false and "Combat Insights: ON" or "Combat Insights: OFF"))
        configFrame.postButton:SetText(T(cfg.postCombat ~= false and "Post-combat popup: ON" or "Post-combat popup: OFF"))
        configFrame.clearButton:SetText(T("Clear last report"))
        if configFrame.testButton then configFrame.testButton:SetText(T("Test alerts")) end
        if configFrame.resetButton then configFrame.resetButton:SetText(T("Reset Mentor settings")) end
        configFrame.report:SetText(ReportDetails(cfg.lastReport))
    end
    if mainInsightSection then
        mainInsightSection:SetShown(cfg.insights ~= false)
        local report = cfg.lastReport
        if report then
            mainInsightSection.score:SetText(T("Score: %d/100\n%s", report.score or 0, GetModeLabel()))
            mainInsightSection.insight:SetText((report.insights and report.insights[1]) or T("No major issue detected."))
        else
            mainInsightSection.score:SetText(T("Score: —\n%s", GetModeLabel()))
            mainInsightSection.insight:SetText(T("Finish a combat of at least 5 seconds to generate DK-specific execution insights."))
        end
    end
    if postCombatFrame and cfg.postCombat == false then postCombatFrame:Hide() end
end

function Engine.ToggleConfig()
    local frame = CreateConfigFrame()
    CreateMainIntegration()
    Engine.UpdateUI()
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function Engine.ShowPostCombat(report)
    local frame = CreatePostCombatFrame()
    local titleText = T("DK Mentor Score: %d/100", report.score or 0)
    local bodyText = BuildPostCombatSummary(report)
    LayoutPostCombatFrame(frame, titleText, bodyText)
    frame:Show()
    local shownReport = report
    if C_Timer and C_Timer.After then
        C_Timer.After(12, function()
            if postCombatFrame and postCombatFrame:IsShown() then
                local _, cfg = EnsureDB()
                if cfg.lastReport == shownReport then postCombatFrame:Hide() end
            end
        end)
    end
end

local originalUpdateAll = addon.UpdateAll
function addon:UpdateAll(...)
    originalUpdateAll(self, ...)
    Engine.UpdateUI()
end

local originalShowHelp = addon.ShowHelp
function addon:ShowHelp(...)
    originalShowHelp(self, ...)
    Print(T("/dkm mentor — open Adaptive DK Coach settings and Combat Insights"))
    Print(T("/dkm mentor essential|mentor|training — change coaching intensity"))
    Print(T("/dkm mentor test|reset — preview alerts or restore Mentor defaults"))
    Print(T("DK Mentor recommends actions; it never casts abilities automatically."))
end

local originalHandleSlashCommand = addon.HandleSlashCommand
function addon:HandleSlashCommand(message)
    local text = tostring(message or "")
    local command, rest = text:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    rest = string.lower((rest or ""):match("^%s*(.-)%s*$") or "")
    if command == "mentor" or command == "insights" or command == "score" then
        if rest == "essential" or rest == "mentor" or rest == "training" then
            local _, cfg = EnsureDB()
            cfg.mode = rest
            addon:UpdateCoach()
            Engine.UpdateUI()
            Print(T("Adaptive Coach mode: %s", GetModeLabel()))
        elseif rest == "next" then
            CycleMode(1)
        elseif rest == "test" or rest == "preview" then
            Engine.TestAlerts()
        elseif rest == "reset" or rest == "defaults" then
            Engine.ResetSettings()
        else
            Engine.ToggleConfig()
        end
        return
    end
    return originalHandleSlashCommand(self, message)
end

local eventFrame = CreateFrame("Frame")
local events = {
    "PLAYER_LOGIN",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_TARGET_CHANGED",
    "UNIT_HEALTH",
    "UNIT_MAXHEALTH",
    "UNIT_POWER_UPDATE",
    "RUNE_POWER_UPDATE",
    "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW",
    "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE",
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_CHANNEL_STOP",
    "UNIT_SPELLCAST_DELAYED",
    "UNIT_SPELLCAST_EMPOWER_START",
    "UNIT_SPELLCAST_EMPOWER_STOP",
}
for _, eventName in ipairs(events) do pcall(eventFrame.RegisterEvent, eventFrame, eventName) end
for _, eventName in ipairs({ "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" }) do
    local registered = false
    if eventFrame.RegisterUnitEvent then registered = pcall(eventFrame.RegisterUnitEvent, eventFrame, eventName, "target") end
    if not registered then pcall(eventFrame.RegisterEvent, eventFrame, eventName) end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        EnsureDB()
        CreateConfigFrame()
        CreatePostCombatFrame()
        CreateMainIntegration()
        state.setupDone = true
        Engine.UpdateUI()
        return
    end

    if not addon.active then return end

    if event == "PLAYER_REGEN_DISABLED" then
        StartCombatSession()
        addon:UpdateCoach()
    elseif event == "PLAYER_REGEN_ENABLED" then
        EndCombatSession()
        addon:UpdateCoach()
    elseif event == "PLAYER_TARGET_CHANGED" then
        state.targetCast = nil
        RefreshTargetCastFromAPI()
        addon:UpdateCoach()
        ScheduleTargetCastRefreshes()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...
        if unit == "player" then
            SamplePlayerHealthDamage()
            addon:UpdateCoach()
        end
    elseif event == "UNIT_POWER_UPDATE" then
        local unit = ...
        if unit == "player" then addon:UpdateCoach() end
    elseif event == "RUNE_POWER_UPDATE" then
        addon:UpdateCoach()
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local actionSpellID = ...
        if IsAccessibleNumber(actionSpellID) then
            local specID = select(1, addon:GetSpecInfo())
            local procID = GetMappedProcID(actionSpellID, specID)
            if procID and PROC_RULES[specID] and PROC_RULES[specID][procID] then
                if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
                    state.procActive[procID] = { startedAt = GetNow(), actionSpellID = actionSpellID, consumed = false }
                elseif state.procActive[procID] then
                    state.procActive[procID].hideAt = GetNow()
                end
                addon:UpdateCoach()
            end
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        local unit, castGUID, spellID = ...
        if unit == "target" then
            local key = IsAccessibleValue(castGUID) and tostring(castGUID) or ("target:" .. tostring(IsAccessibleNumber(spellID) and spellID or GetNow()))
            OpenInterruptWindow(key)
            addon:UpdateCoach()
            ScheduleTargetCastRefreshes()
        end
    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        local unit, castGUID, spellID = ...
        if unit == "target" then
            local key = IsAccessibleValue(castGUID) and tostring(castGUID) or ("target:" .. tostring(IsAccessibleNumber(spellID) and spellID or GetNow()))
            OpenUtilityWindow(key)
            addon:UpdateCoach()
            ScheduleTargetCastRefreshes()
        end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
        local unit, castGUID, spellID = ...
        if unit == "target" then
            local previous = state.targetCast
            state.targetCast = {
                castKey = IsAccessibleValue(castGUID) and tostring(castGUID) or (previous and previous.castKey or nil),
                spellID = IsAccessibleNumber(spellID) and spellID or (previous and previous.spellID or nil),
                interruptible = previous and previous.interruptible or nil,
                explicitInterruptible = previous and previous.explicitInterruptible or nil,
                interruptKey = previous and previous.interruptKey or nil,
                resolved = previous and previous.resolved or false,
                utilityKey = previous and previous.utilityKey or nil,
                utilityResolved = previous and previous.utilityResolved or false,
                targetGUID = GetUnitGUIDSafe("target"),
            }
            RefreshTargetCastFromAPI()
            addon:UpdateCoach()
            ScheduleTargetCastRefreshes()
        end
    elseif event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        local unit = ...
        if unit == "target" then
            RefreshTargetCastFromAPI()
            addon:UpdateCoach()
            ScheduleTargetCastRefreshes()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" then
            HandlePlayerSpell(spellID)
            addon:UpdateCoach()
        elseif unit == "target" then
            ResolveCurrentCast(true)
            addon:UpdateCoach()
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_EMPOWER_STOP" then
        local unit = ...
        if unit == "target" then
            if event == "UNIT_SPELLCAST_INTERRUPTED" then MarkInterruptHandled(false) end
            ResolveCurrentCast(false)
            addon:UpdateCoach()
        end
    end
end)

eventFrame:SetScript("OnUpdate", function(_, elapsed)
    if not addon.active then return end
    local delta = tonumber(elapsed) or 0
    FinalizeProcHides()

    if state.inCombat then
        state.sampleElapsed = state.sampleElapsed + delta
        state.coachElapsed = state.coachElapsed + delta
        if state.sampleElapsed >= 0.20 then
            local sampleDelta = state.sampleElapsed
            state.sampleElapsed = 0
            SampleCombat(sampleDelta)
        end
        if state.coachElapsed >= 0.25 then
            state.coachElapsed = 0
            addon:UpdateCoach()
        end
    end

    state.uiElapsed = state.uiElapsed + delta
    if state.uiElapsed >= 1.0 then
        state.uiElapsed = 0
        if configFrame and configFrame:IsShown() then Engine.UpdateUI() end
    end
end)
