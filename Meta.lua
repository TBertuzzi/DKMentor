local ADDON_NAME, DKM = ...

local addon = DKM.Addon
local Data = DKM.Data or {}
local BuiltInMetaData = DKM.MetaData
local MetaProvider = DKM.MetaProvider
local T = DKM.T or function(value, ...)
    if select("#", ...) > 0 then return string.format(value, ...) end
    return value
end

if not addon or not BuiltInMetaData then return end

local SPEC_ORDER = { 250, 251, 252 }
local SPEC_LABELS = { [250] = "Blood", [251] = "Frost", [252] = "Unholy" }
local CONTEXT_ICONS = { raid = 48792, mythicplus = 47568, highkeys = 55233 }

local function GetMetaDataAndStatus()
    if MetaProvider and MetaProvider.GetActiveSnapshot then
        local snapshot, status = MetaProvider:GetActiveSnapshot()
        if snapshot then return snapshot, status end
    end
    return BuiltInMetaData, {
        id = "builtin",
        kind = "builtin",
        label = "Built-in snapshot",
        detail = "Archon Tooltip not loaded",
        archonLoaded = false,
        compatible = false,
    }
end

local function GetMetaData()
    local snapshot = GetMetaDataAndStatus()
    return snapshot
end

local function GetDB()
    return _G.DKMentorDB
end

local function FormatNumber(value)
    value = tonumber(value) or 0
    local text = tostring(math.floor(value + 0.5))
    local out = text
    while true do
        local changed
        out, changed = out:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
        if changed == 0 then break end
    end
    return out
end

local function FormatDps(value)
    value = tonumber(value)
    if not value then return "—" end
    if value >= 1000 then return string.format("%.1fk", value / 1000) end
    return tostring(math.floor(value + 0.5))
end

local function GetSpecName(specID)
    local key = SPEC_LABELS[specID]
    return key and T(key) or (Data.specNames and Data.specNames[specID]) or T("Death Knight")
end

local HERO_SPELL_IDS = BuiltInMetaData.heroSpellIDs or {
    ["Deathbringer"] = 434765,
    ["San'layn"] = 433895,
    ["Rider of the Apocalypse"] = 444040,
}

local HERO_NAMES_BY_SPELL_ID = {}
for heroName, spellID in pairs(HERO_SPELL_IDS) do
    HERO_NAMES_BY_SPELL_ID[tonumber(spellID)] = heroName
end

local function HeroCanonicalNameBySpellID(spellID, fallback)
    spellID = tonumber(spellID)
    if spellID and HERO_NAMES_BY_SPELL_ID[spellID] then
        return HERO_NAMES_BY_SPELL_ID[spellID]
    end
    return tostring(fallback or "")
end

local function HeroDisplayName(spellID, fallback)
    local canonical = HeroCanonicalNameBySpellID(spellID, fallback)
    if canonical == "" then return T("Not available") end
    return T(canonical)
end

local function GetGuideHero(specID, contextKey)
    local buildContext = contextKey == "raid" and "raid" or "mythicplus"
    local spec = DKM.Builds and DKM.Builds[specID]
    local profiles = spec and spec[buildContext]
    local primary = profiles and profiles[1]
    if not primary then return "", nil end

    local spellID = tonumber(primary.heroSpellID)
    local canonical = HeroCanonicalNameBySpellID(spellID, primary.heroTalent)
    return canonical or "", spellID
end

local function GetAlignment(specID, contextKey, row)
    local guideHero, guideSpellID = GetGuideHero(specID, contextKey)
    local metaSpellID = row and tonumber(row.heroSpellID) or nil
    local usage = row and tonumber(row.heroUsage) or 0

    -- Identity is deliberately ID-only. Localized/canonical display labels are
    -- never used to decide whether the guide and observed meta agree.
    if not guideSpellID or not metaSpellID then
        return "NOT AVAILABLE", guideHero
    end

    if guideSpellID == metaSpellID then
        if usage < 60 then return "ALIGNED / SPLIT", guideHero end
        return "ALIGNED", guideHero
    end
    if usage >= 70 then return "META DIFFERS", guideHero end
    return "SPLIT SIGNAL", guideHero
end

local function AlignmentColor(status)
    if status == "ALIGNED" then return 0.36, 0.94, 0.62 end
    if status == "ALIGNED / SPLIT" or status == "SPLIT SIGNAL" then return 0.98, 0.78, 0.30 end
    if status == "META DIFFERS" then return 1.00, 0.48, 0.36 end
    if status == "NOT AVAILABLE" then return 0.70, 0.86, 0.94 end
    return 0.70, 0.86, 0.94
end

local function SignalColor(signal)
    if signal == "VERY STRONG CONSENSUS" then return 0.36, 0.98, 0.70 end
    if signal == "STRONG CONSENSUS" then return 0.52, 0.92, 0.72 end
    if signal == "SPLIT META" then return 0.98, 0.78, 0.30 end
    return 0.70, 0.86, 0.94
end

function addon:GetMetaContext()
    local db = GetDB()
    local key = db and tostring(db.codexMetaContext or "raid") or "raid"
    local metaData = GetMetaData()
    if not (metaData.contexts and metaData.contexts[key]) then key = "raid" end
    return key
end

function addon:SetMetaContext(contextKey)
    local db = GetDB()
    if not db then return end
    contextKey = tostring(contextKey or "raid")
    local metaData = GetMetaData()
    if not (metaData.contexts and metaData.contexts[contextKey]) then contextKey = "raid" end
    db.codexMetaContext = contextKey
    db.codexSection = "meta"
    if self.UpdateGuideSection then self:UpdateGuideSection() end
end

function addon:HideMetaVisualPools(root)
    for _, button in ipairs(root.metaContextButtons or {}) do button:Hide() end
    for _, card in ipairs(root.metaSpecCardPool or {}) do card:Hide() end
    root.metaSpecCardUsed = 0
end

local function EnsureContextButtons(root, metaData)
    root.metaContextButtons = root.metaContextButtons or {}
    for index, key in ipairs(metaData.contextOrder or {}) do
        local button = root.metaContextButtons[index]
        if not button then
            button = CreateFrame("Button", nil, root, "BackdropTemplate")
            button:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetSize(16, 16)
            button.icon:SetPoint("LEFT", button, "LEFT", 8, 0)
            button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            button.label:SetPoint("LEFT", button.icon, "RIGHT", 5, 0)
            button.label:SetPoint("RIGHT", button, "RIGHT", -6, 0)
            button.label:SetJustifyH("LEFT")
            button:RegisterForClicks("LeftButtonUp")
            root.metaContextButtons[index] = button
        end
        local context = metaData.contexts[key]
        button.metaContextKey = key
        button.label:SetText(T(context and context.label or key))
        local iconID = CONTEXT_ICONS[key]
        local icon
        if iconID and C_Spell and C_Spell.GetSpellTexture then
            local ok, value = pcall(C_Spell.GetSpellTexture, iconID)
            if ok then icon = value end
        elseif iconID and GetSpellTexture then
            local ok, value = pcall(GetSpellTexture, iconID)
            if ok then icon = value end
        end
        button.icon:SetTexture(icon or "Interface\\Icons\\spell_deathknight_classicon")
        button:SetScript("OnClick", function(self) addon:SetMetaContext(self.metaContextKey) end)
        button:Show()
    end
end

local function StyleContextButton(button, active)
    if active then
        button:SetBackdropColor(0.025, 0.12, 0.14, 0.98)
        button:SetBackdropBorderColor(0.30, 0.88, 0.72, 0.98)
        button.label:SetTextColor(0.60, 1.00, 0.78)
    else
        button:SetBackdropColor(0.018, 0.055, 0.075, 0.94)
        button:SetBackdropBorderColor(0.14, 0.42, 0.54, 0.80)
        button.label:SetTextColor(0.82, 0.91, 0.95)
    end
end

local function AcquireSpecCard(root)
    root.metaSpecCardPool = root.metaSpecCardPool or {}
    root.metaSpecCardUsed = (root.metaSpecCardUsed or 0) + 1
    local card = root.metaSpecCardPool[root.metaSpecCardUsed]
    if not card then
        card = CreateFrame("Frame", nil, root, "BackdropTemplate")
        card:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
        card.icon = card:CreateTexture(nil, "ARTWORK")
        card.icon:SetSize(30, 30)
        card.icon:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -9)
        card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 47, -8)
        card.name:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -8)
        card.name:SetHeight(18)
        card.name:SetJustifyH("LEFT")
        card.role = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.role:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -1)
        card.role:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -27)
        card.role:SetHeight(14)
        card.role:SetJustifyH("LEFT")
        card.signal = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.signal:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -48)
        card.signal:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -48)
        card.signal:SetHeight(15)
        card.signal:SetJustifyH("LEFT")
        card.body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.body:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -68)
        card.body:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 43)
        card.body:SetJustifyH("LEFT")
        card.body:SetJustifyV("TOP")
        card.body:SetWordWrap(true)
        card.status = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.status:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 9, 8)
        card.status:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 8)
        card.status:SetHeight(30)
        card.status:SetJustifyH("LEFT")
        card.status:SetJustifyV("BOTTOM")
        card.status:SetWordWrap(true)
        root.metaSpecCardPool[root.metaSpecCardUsed] = card
    end
    card:ClearAllPoints()
    card:Show()
    return card
end

local function ConfigureSpecCard(card, specID, contextKey, row, width, highlighted)
    card:SetSize(width, 248)
    local icon = addon.GetSpecIconByID and addon:GetSpecIconByID(specID) or "Interface\\Icons\\spell_deathknight_classicon"
    card.icon:SetTexture(icon)
    card.name:SetText(GetSpecName(specID))
    card.role:SetText(T("Role: %s", T(row.role or "DPS")))
    card.role:SetTextColor(0.68, 0.84, 0.92)

    local sr, sg, sb = SignalColor(row.signal)
    card.signal:SetText(T(row.signal or "CURRENT SIGNAL"))
    card.signal:SetTextColor(sr, sg, sb)

    local resultLine = row.maxKey and T("Observed build snapshot: +%d • %s DPS", tonumber(row.maxKey) or 0, FormatDps(row.buildDps)) or T("Observed build snapshot: %s DPS", FormatDps(row.buildDps))
    local body = table.concat({
        T("Observed Hero: %s — %.1f%%", HeroDisplayName(row.heroSpellID, row.hero), tonumber(row.heroUsage) or 0),
        T("Alternative: %s — %.1f%%", HeroDisplayName(row.alternativeHeroSpellID, row.alternativeHero), tonumber(row.alternativeUsage) or 0),
        T("Sample: %s parses", FormatNumber(row.parses)),
        resultLine,
        T("Observed weapon usage: %s — %.1f%%", row.popularWeapon or "—", tonumber(row.weaponUsage) or 0),
    }, "\n")
    card.body:SetText(body)
    card.body:SetTextColor(0.84, 0.91, 0.95)

    local alignment, guideHero = GetAlignment(specID, contextKey, row)
    local ar, ag, ab = AlignmentColor(alignment)
    card.status:SetText(T("Guide vs logs: %s • Guide: %s", T(alignment), guideHero ~= "" and T(guideHero) or T("Not available")))
    card.status:SetTextColor(ar, ag, ab)

    if highlighted then
        card:SetBackdropColor(0.025, 0.105, 0.12, 0.96)
        card:SetBackdropBorderColor(0.30, 0.88, 0.72, 0.98)
    else
        card:SetBackdropColor(0.018, 0.055, 0.075, 0.90)
        card:SetBackdropBorderColor(0.14, 0.40, 0.52, 0.82)
    end
end

local function GetProviderDisplayLines(providerStatus, metaData)
    local reviewed = metaData and metaData.reviewed or "-"
    if providerStatus and providerStatus.kind == "archon" then
        return T("Data source: Archon addon data • reviewed %s", reviewed),
            T("Archon: compatible aggregate meta feed active")
    end
    if providerStatus and providerStatus.kind == "external" then
        return T("Data source: external meta provider • reviewed %s", reviewed),
            T("Provider: %s", providerStatus.detail or providerStatus.id or "external")
    end

    local sourceLine = T("Data source: built-in snapshot • reviewed %s", reviewed)
    if providerStatus and providerStatus.archonCoreLoaded and providerStatus.archonDBLoaded then
        return sourceLine, T("Archon: Tooltip + DB detected • aggregate meta feed unavailable")
    end
    if providerStatus and providerStatus.archonCoreLoaded then
        return sourceLine, T("Archon: Tooltip detected • aggregate meta feed unavailable")
    end
    if providerStatus and providerStatus.archonDBLoaded then
        return sourceLine, T("Archon: DB detected (%s) • Tooltip not loaded • aggregate meta feed unavailable", providerStatus.archonDBName or "DB")
    end
    if providerStatus and providerStatus.archonDetected then
        return sourceLine, T("Archon: detected • aggregate meta feed unavailable")
    end
    return sourceLine, T("Archon: not detected")
end

function addon:RenderMetaAdvisorVisual(specID)
    local root = self:EnsureGearMentorVisual()
    if not root then return nil end
    self:ResetGearVisual(root)
    root:Show()
    root.metaSpecCardUsed = 0
    local metaData, providerStatus = GetMetaDataAndStatus()
    EnsureContextButtons(root, metaData)

    local parent = root:GetParent()
    local availableWidth = parent and parent.GetWidth and parent:GetWidth() or root:GetWidth() or 760
    if not availableWidth or availableWidth < 620 then availableWidth = 760 end
    root:SetWidth(availableWidth)
    local contentWidth = math.max(620, math.floor(availableWidth - 4))
    local y = 0

    local contextKey = self:GetMetaContext()
    local context = metaData.contexts and metaData.contexts[contextKey]
    if not context then return nil end

    local title = self:AcquireGearText(root, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    title:SetWidth(contentWidth)
    title:SetHeight(24)
    title:SetTextColor(0.55, 0.88, 1.00)
    title:SetText(T("DK Meta Pulse"))
    y = y - 29

    local subtitle = self:AcquireGearText(root, "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    subtitle:SetWidth(contentWidth)
    subtitle:SetHeight(34)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetJustifyV("TOP")
    subtitle:SetTextColor(0.76, 0.88, 0.94)
    local sourceLine, archonLine = GetProviderDisplayLines(providerStatus, metaData)
    subtitle:SetText(sourceLine .. "\n" .. archonLine)
    y = y - 42

    local contextGap = 8
    local contextOrder = metaData.contextOrder or {}
    local contextWidth = math.floor((contentWidth - (contextGap * (#contextOrder - 1))) / #contextOrder)
    for index, key in ipairs(contextOrder) do
        local button = root.metaContextButtons[index]
        button:ClearAllPoints()
        button:SetSize(contextWidth, 31)
        button:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + ((index - 1) * (contextWidth + contextGap)), y)
        button.label:SetText(T(metaData.contexts[key] and metaData.contexts[key].label or key))
        StyleContextButton(button, key == contextKey)
    end
    y = y - 41

    local scope = self:AcquireGearText(root, "GameFontHighlightSmall")
    scope:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    scope:SetWidth(contentWidth)
    scope:SetHeight(18)
    scope:SetTextColor(0.92, 0.79, 0.43)
    scope:SetText(T(context.short or ""))
    y = y - 25

    local advicePanel = self:AcquireGearPanel(root)
    advicePanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    advicePanel:SetWidth(contentWidth)
    local adviceTitle = self:AcquireGearPanelText(advicePanel, "GameFontNormal")
    adviceTitle:SetPoint("TOPLEFT", advicePanel, "TOPLEFT", 10, -9)
    adviceTitle:SetWidth(contentWidth - 20)
    adviceTitle:SetHeight(18)
    adviceTitle:SetTextColor(0.52, 0.90, 1.00)
    adviceTitle:SetText(T("What should I play?"))
    local adviceBody = self:AcquireGearPanelText(advicePanel, "GameFontHighlightSmall")
    adviceBody:SetPoint("TOPLEFT", adviceTitle, "BOTTOMLEFT", 0, -5)
    adviceBody:SetWidth(contentWidth - 20)
    adviceBody:SetWordWrap(true)
    adviceBody:SetTextColor(0.90, 0.94, 0.97)
    adviceBody:SetText(T(context.advice or ""))
    adviceBody:SetHeight(1)
    local adviceHeight = math.max(72, math.ceil((adviceBody.GetStringHeight and adviceBody:GetStringHeight()) or 38) + 39)
    adviceBody:SetHeight(adviceHeight - 35)
    advicePanel:SetHeight(adviceHeight)
    y = y - adviceHeight - 12

    local cardsTitle = self:AcquireGearText(root, "GameFontNormalSmall")
    cardsTitle:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    cardsTitle:SetWidth(contentWidth)
    cardsTitle:SetHeight(17)
    cardsTitle:SetTextColor(0.92, 0.80, 0.45)
    cardsTitle:SetText(T("Observed DK meta by specialization"))
    y = y - 23

    local cardGap = 8
    local cardWidth = math.floor((contentWidth - (cardGap * 2)) / 3)
    for index, id in ipairs(SPEC_ORDER) do
        local row = context.specs and context.specs[id]
        if row then
            local card = AcquireSpecCard(root)
            ConfigureSpecCard(card, id, contextKey, row, cardWidth, tonumber(specID) == id)
            card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + ((index - 1) * (cardWidth + cardGap)), y)
        end
    end
    y = y - 258

    local interpretationPanel = self:AcquireGearPanel(root)
    interpretationPanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    interpretationPanel:SetWidth(contentWidth)
    local interpretationTitle = self:AcquireGearPanelText(interpretationPanel, "GameFontNormalSmall")
    interpretationTitle:SetPoint("TOPLEFT", interpretationPanel, "TOPLEFT", 10, -8)
    interpretationTitle:SetWidth(contentWidth - 20)
    interpretationTitle:SetHeight(16)
    interpretationTitle:SetTextColor(0.72, 0.91, 0.80)
    interpretationTitle:SetText(T("How DK Mentor reads this"))
    local interpretationBody = self:AcquireGearPanelText(interpretationPanel, "GameFontHighlightSmall")
    interpretationBody:SetPoint("TOPLEFT", interpretationTitle, "BOTTOMLEFT", 0, -4)
    interpretationBody:SetWidth(contentWidth - 20)
    interpretationBody:SetWordWrap(true)
    interpretationBody:SetTextColor(0.78, 0.87, 0.92)
    interpretationBody:SetText(T("ALIGNED means the DK Mentor guide and the most observed Hero Talent point the same way. SPLIT SIGNAL means the observed meta is close enough that both choices are common. META DIFFERS means logs strongly favor a different Hero Talent than the current guide default; DK Mentor keeps both facts visible instead of silently overwriting the guide."))
    interpretationBody:SetHeight(1)
    local interpretationHeight = math.max(92, math.ceil((interpretationBody.GetStringHeight and interpretationBody:GetStringHeight()) or 58) + 33)
    interpretationBody:SetHeight(interpretationHeight - 30)
    interpretationPanel:SetHeight(interpretationHeight)
    y = y - interpretationHeight - 10

    local sourcePanel = self:AcquireGearPanel(root)
    sourcePanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    sourcePanel:SetWidth(contentWidth)
    local sourceTitle = self:AcquireGearPanelText(sourcePanel, "GameFontNormalSmall")
    sourceTitle:SetPoint("TOPLEFT", sourcePanel, "TOPLEFT", 10, -8)
    sourceTitle:SetWidth(contentWidth - 20)
    sourceTitle:SetHeight(16)
    sourceTitle:SetTextColor(0.72, 0.91, 0.80)
    sourceTitle:SetText(T("Source & caveat"))
    local sourceBody = self:AcquireGearPanelText(sourcePanel, "GameFontHighlightSmall")
    sourceBody:SetPoint("TOPLEFT", sourceTitle, "BOTTOMLEFT", 0, -4)
    sourceBody:SetWidth(contentWidth - 20)
    sourceBody:SetWordWrap(true)
    sourceBody:SetTextColor(0.72, 0.82, 0.88)
    local sourceHeader = T("%s • Patch %s • reviewed %s", metaData.sourceName or "Archon.gg / Warcraft Logs", metaData.patch or "12.1.0", metaData.reviewed or "-")
    local providerSource, providerArchon = GetProviderDisplayLines(providerStatus, metaData)
    sourceBody:SetText(table.concat({ sourceHeader, providerSource, providerArchon, T(metaData.sourceMethod or ""), T(metaData.disclaimer or "") }, "\n"))
    sourceBody:SetHeight(1)
    local sourceHeight = math.max(112, math.ceil((sourceBody.GetStringHeight and sourceBody:GetStringHeight()) or 76) + 32)
    sourceBody:SetHeight(sourceHeight - 29)
    sourcePanel:SetHeight(sourceHeight)
    y = y - sourceHeight - 10

    local totalHeight = math.max(1, math.abs(y) + 8)
    root:SetHeight(totalHeight)
    return totalHeight
end
