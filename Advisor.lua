local ADDON_NAME, DKM = ...

local addon = DKM.Addon
local AdvisorData = DKM.AdvisorData
local GearData = DKM.GearData
local T = DKM.T or function(value) return value end

if not addon or not AdvisorData then return end

local function IsKnownSpell(spellID)
    spellID = tonumber(spellID)
    if not spellID then return false end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellID)
        if ok and known == true then return true end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellID)
        if ok and known == true then return true end
    end
    return false
end

local function GetSpellNameSafe(spellID, fallback)
    spellID = tonumber(spellID)
    if spellID and C_Spell and C_Spell.GetSpellName then
        local ok, name = pcall(C_Spell.GetSpellName, spellID)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    if spellID and GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellID)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return fallback or ""
end

local function GetPrimaryRuneSpellID(runeData)
    return runeData and runeData.spellIDs and tonumber(runeData.spellIDs[1]) or nil
end

local function GetSpellTextureSafe(spellID)
    spellID = tonumber(spellID)
    if spellID and C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    if spellID and GetSpellTexture then
        local ok, texture = pcall(GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    return QUESTION_MARK_ICON or 134400
end

local function HideAdvisorVisualPools(root)
    if not root then return end
    for _, card in ipairs(root.dkAdvisorStatPool or {}) do card:Hide() end
    for _, row in ipairs(root.dkAdvisorFolioPool or {}) do row:Hide() end
    for _, button in ipairs(root.advisorContextButtons or {}) do button:Hide() end
    if root.dkAdvisorStatusChip then root.dkAdvisorStatusChip:Hide() end
    if root.dkAdvisorOpenFolioButton then root.dkAdvisorOpenFolioButton:Hide() end
    if root.dkAdvisorFolioEditor then root.dkAdvisorFolioEditor:Hide() end
end

function addon:HideDKAdvisorVisualPools(root)
    HideAdvisorVisualPools(root)
end

local function EnsureAdvisorStatusChip(root)
    local chip = root.dkAdvisorStatusChip
    if not chip then
        chip = CreateFrame("Frame", nil, root, "BackdropTemplate")
        chip:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        chip.text = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        chip.text:SetPoint("CENTER")
        chip.text:SetJustifyH("CENTER")
        root.dkAdvisorStatusChip = chip
    end
    chip:Show()
    return chip
end

local function EnsureAdvisorOpenFolioButton(root)
    local button = root.dkAdvisorOpenFolioButton
    if not button then
        button = CreateFrame("Button", nil, root, "BackdropTemplate")
        button:SetBackdrop(addon.GEAR_VISUAL_BACKDROP or {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        button:SetBackdropColor(0.04, 0.12, 0.16, 0.96)
        button:SetBackdropBorderColor(0.22, 0.68, 0.84, 0.94)
        button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.text:SetPoint("CENTER")
        button.text:SetJustifyH("CENTER")
        button.text:SetTextColor(0.84, 0.96, 1.00)
        button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        local highlight = button:GetHighlightTexture()
        if highlight then
            highlight:SetVertexColor(1, 1, 1, 0.06)
            highlight:SetAllPoints(button)
        end
        button:SetScript("OnMouseDown", function(self)
            self:SetBackdropColor(0.03, 0.09, 0.12, 0.98)
        end)
        button:SetScript("OnMouseUp", function(self)
            self:SetBackdropColor(0.04, 0.12, 0.16, 0.96)
        end)
        button:SetScript("OnClick", function()
            if addon and addon.OpenOmniumFolio then addon:OpenOmniumFolio() end
        end)
        button:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(T("Open Folio"))
            GameTooltip:AddLine(T("Opens Blizzard's Player Spells/Talents frame. If the Folio tab is not selected automatically, click Omnium Folio there."), 0.95, 0.95, 0.95, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)
        root.dkAdvisorOpenFolioButton = button
    end
    button.text:SetText(T("Open Folio"))
    button:Show()
    return button
end

local function AcquireAdvisorStatCard(root, index)
    root.dkAdvisorStatPool = root.dkAdvisorStatPool or {}
    local card = root.dkAdvisorStatPool[index]
    if not card then
        card = CreateFrame("Frame", nil, root, "BackdropTemplate")
        card:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)

        card.label = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.label:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -7)
        card.label:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -7)
        card.label:SetHeight(16)
        card.label:SetJustifyH("LEFT")

        card.percent = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        card.percent:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -24)
        card.percent:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -24)
        card.percent:SetHeight(22)
        card.percent:SetJustifyH("LEFT")

        card.rating = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.rating:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 8, 7)
        card.rating:SetWidth(95)
        card.rating:SetHeight(15)
        card.rating:SetJustifyH("LEFT")

        card.dr = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.dr:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 7)
        card.dr:SetWidth(70)
        card.dr:SetHeight(15)
        card.dr:SetJustifyH("RIGHT")

        root.dkAdvisorStatPool[index] = card
    end
    card:ClearAllPoints()
    card:SetBackdropColor(0.02, 0.065, 0.085, 0.94)
    card:SetBackdropBorderColor(0.16, 0.42, 0.54, 0.90)
    card.label:SetTextColor(0.76, 0.88, 0.93)
    card.percent:SetTextColor(0.42, 0.98, 0.94)
    card.rating:SetTextColor(0.76, 0.86, 0.91)
    card.dr:SetTextColor(0.76, 0.86, 0.91)
    card:Show()
    return card
end

local function AcquireAdvisorFolioRow(root, index)
    root.dkAdvisorFolioPool = root.dkAdvisorFolioPool or {}
    local row = root.dkAdvisorFolioPool[index]
    if not row then
        row = CreateFrame("Button", nil, root, "BackdropTemplate")
        row:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)

        row.iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
        row.iconFrame:SetSize(40, 40)
        row.iconFrame:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.iconFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        row.iconFrame:SetBackdropColor(0.01, 0.025, 0.035, 1.00)
        row.iconFrame:SetBackdropBorderColor(0.18, 0.56, 0.70, 0.95)

        row.icon = row.iconFrame:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("TOPLEFT", row.iconFrame, "TOPLEFT", 2, -2)
        row.icon:SetPoint("BOTTOMRIGHT", row.iconFrame, "BOTTOMRIGHT", -2, 2)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        row.line = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.line:SetPoint("TOPLEFT", row, "TOPLEFT", 56, -7)
        row.line:SetWidth(86)
        row.line:SetHeight(15)
        row.line:SetJustifyH("LEFT")
        row.line:SetTextColor(0.50, 0.82, 0.94)

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 56, -24)
        row.name:SetHeight(20)
        row.name:SetJustifyH("LEFT")
        row.name:SetJustifyV("MIDDLE")
        row.name:SetWordWrap(false)
        row.name:SetTextColor(0.94, 0.97, 0.99)

        row.statusFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
        row.statusFrame:SetSize(122, 26)
        row.statusFrame:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.statusFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })

        row.status = row.statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.status:SetPoint("CENTER", row.statusFrame, "CENTER", 0, 0)
        row.status:SetWidth(112)
        row.status:SetHeight(18)
        row.status:SetJustifyH("CENTER")

        row:SetScript("OnEnter", function(self)
            if not self.spellID or not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, self.spellID)
            if not ok then GameTooltip:SetText(self.runeName or T("Omnium Folio")) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            if GameTooltip then GameTooltip:Hide() end
        end)

        root.dkAdvisorFolioPool[index] = row
    end
    row:ClearAllPoints()
    row:SetBackdropColor(0.018, 0.055, 0.075, 0.92)
    row:SetBackdropBorderColor(0.12, 0.38, 0.50, 0.82)
    row.statusFrame:SetBackdropColor(0.06, 0.10, 0.12, 0.94)
    row.statusFrame:SetBackdropBorderColor(0.28, 0.42, 0.48, 0.88)
    row:Show()
    return row
end

local function StatusText(status)
    if status == "review" then return T("REVIEW PENDING") end
    return T("CURRENT")
end

local function StatusColor(status)
    if status == "review" then return 1.00, 0.78, 0.28 end
    return 0.40, 1.00, 0.60
end

function addon:GetDKAdvisorStatSnapshot()
    local pct = self.GetCurrentStatSnapshot and self:GetCurrentStatSnapshot() or {}
    local function Rating(constant)
        if not constant or not GetCombatRating then return nil end
        return self:GetSafeNumberFromCall(GetCombatRating, constant)
    end
    return {
        crit = { percent = pct.crit, rating = Rating(_G.CR_CRIT_MELEE or _G.CR_CRIT_SPELL) },
        haste = { percent = pct.haste, rating = Rating(_G.CR_HASTE_MELEE or _G.CR_HASTE_SPELL) },
        mastery = { percent = pct.mastery, rating = Rating(_G.CR_MASTERY) },
        versatility = { percent = pct.versatility, rating = Rating(_G.CR_VERSATILITY_DAMAGE_DONE) },
    }
end

function addon:GetDKAdvisorDRState(statKey, rating)
    local thresholds = AdvisorData.diminishingReturns and AdvisorData.diminishingReturns[statKey]
    if type(rating) ~= "number" or not thresholds then return T("UNKNOWN"), 0.72, 0.82, 0.88 end
    if rating >= thresholds[3] then return T("30%+ DR"), 1.00, 0.46, 0.40 end
    if rating >= thresholds[2] then return T("20% DR"), 1.00, 0.64, 0.30 end
    if rating >= thresholds[1] then return T("10% DR"), 1.00, 0.82, 0.35 end
    return T("NO DR"), 0.40, 1.00, 0.60
end

function addon:GetActiveDKHeroTalent(specID)
    local activeSpecID = select(1, self:GetSpecInfo())
    if tonumber(specID) ~= tonumber(activeSpecID) then return nil end
    for _, hero in ipairs((AdvisorData.heroMarkers and AdvisorData.heroMarkers[specID]) or {}) do
        for _, spellID in ipairs(hero.spellIDs or {}) do
            if IsKnownSpell(spellID) then return hero.name end
        end
    end
    return nil
end

function addon:GetDKAdvisorContextMode()
    local db = _G.DKMentorDB
    local mode = db and tostring(db.codexAdvisorContext or "auto") or "auto"
    if mode ~= "pve" and mode ~= "pvp" then mode = "auto" end
    return mode
end

function addon:SetDKAdvisorContextMode(mode)
    local db = _G.DKMentorDB
    if not db then return end
    mode = string.lower(tostring(mode or "auto"))
    if mode ~= "pve" and mode ~= "pvp" then mode = "auto" end
    db.codexAdvisorContext = mode
    db.codexSection = "advisor"
    if self.UpdateGuideSection then self:UpdateGuideSection() end
end

function addon:GetDKAdvisorContextBucket()
    local mode = self:GetDKAdvisorContextMode()
    if mode == "pve" then return "pve", "pve" end
    if mode == "pvp" then return "pvp", "pvp" end
    local context = self.DetectActualContext and self:DetectActualContext() or "world"
    if context == "pvp" then return "pvp", context end
    return "pve", context
end

function addon:GetDKAdvisorRecommendation(specID)
    local spec = AdvisorData.specs and AdvisorData.specs[specID]
    if not spec then return nil end
    local bucket, context = self:GetDKAdvisorContextBucket()
    local stats = spec.stats and spec.stats[bucket] or nil
    local hero = self:GetActiveDKHeroTalent(specID)
    local recommendation = stats and stats.default or nil
    if stats and hero and stats.hero and stats.hero[hero] then recommendation = stats.hero[hero] end
    local folio = spec.folio and spec.folio[bucket] or nil
    return {
        bucket = bucket,
        context = context,
        hero = hero,
        stats = stats,
        statRecommendation = recommendation,
        folio = folio,
    }
end

function addon:GetOmniumFolioSelectedSpellSet()
    local selected = {}
    local detected = false
    local traits = C_Traits
    if traits and traits.GetConfigIDByTreeID and traits.GetTreeNodes and traits.GetNodeInfo and traits.GetEntryInfo and traits.GetDefinitionInfo then
        local okConfig, configID = pcall(traits.GetConfigIDByTreeID, AdvisorData.folioTreeID)
        if okConfig and type(configID) == "number" and configID > 0 then
            local okNodes, nodes = pcall(traits.GetTreeNodes, AdvisorData.folioTreeID)
            if okNodes and type(nodes) == "table" then
                for _, nodeID in ipairs(nodes) do
                    local okNode, nodeInfo = pcall(traits.GetNodeInfo, configID, nodeID)
                    if okNode and type(nodeInfo) == "table" then
                        local entryID = nodeInfo.activeEntryID
                        if not entryID and type(nodeInfo.activeEntry) == "table" then entryID = nodeInfo.activeEntry.entryID end
                        if type(entryID) == "number" and entryID > 0 then
                            local okEntry, entryInfo = pcall(traits.GetEntryInfo, configID, entryID)
                            if okEntry and type(entryInfo) == "table" and entryInfo.definitionID then
                                local okDef, defInfo = pcall(traits.GetDefinitionInfo, entryInfo.definitionID)
                                if okDef and type(defInfo) == "table" and type(defInfo.spellID) == "number" then
                                    selected[defInfo.spellID] = true
                                    detected = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Conservative fallback for clients where the trait tree does not expose a
    -- config yet. Only accept spell-known data when every Folio row resolves
    -- to exactly one candidate; an ambiguous row means we do not claim a live
    -- selection at all.
    if not detected then
        local fallback = {}
        local fallbackValid = true
        local rowsResolved = 0
        for _, rowCandidates in ipairs(AdvisorData.folioRowCandidates or {}) do
            local knownKey
            local knownCount = 0
            for _, runeKey in ipairs(rowCandidates) do
                local runeData = AdvisorData.folioRunes and AdvisorData.folioRunes[runeKey]
                local runeKnown = false
                for _, spellID in ipairs((runeData and runeData.spellIDs) or {}) do
                    if IsKnownSpell(spellID) then
                        runeKnown = true
                        break
                    end
                end
                if runeKnown then
                    knownCount = knownCount + 1
                    knownKey = runeKey
                end
            end
            if knownCount ~= 1 then
                fallbackValid = false
                break
            end
            local runeData = AdvisorData.folioRunes and AdvisorData.folioRunes[knownKey]
            for _, spellID in ipairs((runeData and runeData.spellIDs) or {}) do
                fallback[spellID] = true
            end
            rowsResolved = rowsResolved + 1
        end
        if fallbackValid and rowsResolved == #(AdvisorData.folioRowCandidates or {}) and rowsResolved > 0 then
            selected = fallback
            detected = true
        end
    end
    return selected, detected
end

function addon:IsRecommendedFolioRuneSelected(runeKey, selectedSet)
    local runeData = AdvisorData.folioRunes and AdvisorData.folioRunes[runeKey]
    if not runeData then return nil end
    for _, spellID in ipairs(runeData.spellIDs or {}) do
        if selectedSet and selectedSet[spellID] then return true end
    end
    return false
end

local function GetCommittedFolioEntryID(nodeInfo)
    if type(nodeInfo) ~= "table" then return nil end
    if type(nodeInfo.entryIDsWithCommittedRanks) == "table" then
        for _, entryID in ipairs(nodeInfo.entryIDsWithCommittedRanks) do
            entryID = tonumber(entryID)
            if entryID and entryID > 0 then return entryID end
        end
    end
    if type(nodeInfo.activeEntry) == "table" then
        local entryID = tonumber(nodeInfo.activeEntry.entryID)
        if entryID and entryID > 0 then return entryID end
    end
    local activeEntryID = tonumber(nodeInfo.activeEntryID)
    if activeEntryID and activeEntryID > 0 then return activeEntryID end
    return nil
end

function addon:GetOmniumFolioRuntimeRows(folio)
    if not folio or type(folio.rows) ~= "table" then return nil, false end
    local traits = C_Traits
    if not traits or not traits.GetConfigIDByTreeID or not traits.GetTreeNodes or not traits.GetNodeInfo or not traits.GetEntryInfo or not traits.GetDefinitionInfo then
        return nil, false
    end

    local okConfig, configID = pcall(traits.GetConfigIDByTreeID, AdvisorData.folioTreeID)
    if not okConfig or type(configID) ~= "number" or configID <= 0 then return nil, false end

    local okNodes, nodeIDs = pcall(traits.GetTreeNodes, AdvisorData.folioTreeID)
    if not okNodes or type(nodeIDs) ~= "table" then return nil, false end

    local canEdit = true
    local editError
    if traits.CanEditConfig then
        local okEdit, allowed, reason = pcall(traits.CanEditConfig, configID)
        if okEdit and allowed == false then
            canEdit = false
            editError = reason
        end
    end

    local nodes = {}
    local spellLookup = {}
    for _, nodeID in ipairs(nodeIDs) do
        local okNode, nodeInfo = pcall(traits.GetNodeInfo, configID, nodeID)
        if okNode and type(nodeInfo) == "table" and type(nodeInfo.entryIDs) == "table" then
            local runtimeNode = {
                nodeID = tonumber(nodeID),
                nodeInfo = nodeInfo,
                currentEntryID = GetCommittedFolioEntryID(nodeInfo),
                candidates = {},
            }
            for _, rawEntryID in ipairs(nodeInfo.entryIDs) do
                local entryID = tonumber(rawEntryID)
                if entryID and entryID > 0 then
                    local okEntry, entryInfo = pcall(traits.GetEntryInfo, configID, entryID)
                    if okEntry and type(entryInfo) == "table" and entryInfo.definitionID then
                        local okDef, defInfo = pcall(traits.GetDefinitionInfo, entryInfo.definitionID)
                        if okDef and type(defInfo) == "table" then
                            local spellID = tonumber(defInfo.spellID)
                            local candidate = {
                                nodeID = tonumber(nodeID),
                                entryID = entryID,
                                spellID = spellID,
                                name = GetSpellNameSafe(spellID, T("Omnium Folio")),
                                icon = GetSpellTextureSafe(spellID),
                            }
                            runtimeNode.candidates[#runtimeNode.candidates + 1] = candidate
                            if spellID then spellLookup[spellID] = candidate end
                        end
                    end
                end
            end
            if #runtimeNode.candidates > 0 then nodes[runtimeNode.nodeID] = runtimeNode end
        end
    end

    local runtimeRows = {}
    local mapped = 0
    for _, folioRow in ipairs(folio.rows) do
        local runeData = AdvisorData.folioRunes and AdvisorData.folioRunes[folioRow.rune]
        local recommendedCandidate
        if runeData then
            for _, spellID in ipairs(runeData.spellIDs or {}) do
                recommendedCandidate = spellLookup[tonumber(spellID)]
                if recommendedCandidate then break end
            end
        end

        if recommendedCandidate and nodes[recommendedCandidate.nodeID] then
            local runtimeNode = nodes[recommendedCandidate.nodeID]
            runtimeRows[#runtimeRows + 1] = {
                row = tonumber(folioRow.row) or (#runtimeRows + 1),
                runeKey = folioRow.rune,
                fixed = folioRow.fixed == true or #runtimeNode.candidates <= 1,
                nodeID = runtimeNode.nodeID,
                currentEntryID = runtimeNode.currentEntryID,
                recommendedEntryID = recommendedCandidate.entryID,
                candidates = runtimeNode.candidates,
            }
            mapped = mapped + 1
        else
            local spellID = GetPrimaryRuneSpellID(runeData)
            runtimeRows[#runtimeRows + 1] = {
                row = tonumber(folioRow.row) or (#runtimeRows + 1),
                runeKey = folioRow.rune,
                fixed = folioRow.fixed == true,
                nodeID = nil,
                currentEntryID = nil,
                recommendedEntryID = nil,
                candidates = {
                    {
                        nodeID = nil,
                        entryID = nil,
                        spellID = spellID,
                        name = GetSpellNameSafe(spellID, runeData and T(runeData.name) or T("Omnium Folio")),
                        icon = GetSpellTextureSafe(spellID),
                    },
                },
            }
        end
    end

    return { configID = configID, rows = runtimeRows, canEdit = canEdit, editError = editError }, mapped == #runtimeRows and mapped > 0
end

local function GetFolioCandidateByEntryID(rowInfo, entryID)
    if not rowInfo then return nil end
    entryID = tonumber(entryID)
    for _, candidate in ipairs(rowInfo.candidates or {}) do
        if entryID and tonumber(candidate.entryID) == entryID then return candidate end
    end
    return (rowInfo.candidates or {})[1]
end

local function EnsureAdvisorFolioEditor(root)
    local editor = root.dkAdvisorFolioEditor
    if not editor then
        editor = CreateFrame("Frame", nil, root, "BackdropTemplate")
        editor:SetBackdrop(addon.GEAR_VISUAL_BACKDROP or {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        editor:SetBackdropColor(0.018, 0.055, 0.075, 0.92)
        editor:SetBackdropBorderColor(0.18, 0.56, 0.70, 0.90)

        editor.title = editor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        editor.title:SetPoint("TOPLEFT", editor, "TOPLEFT", 10, -8)
        editor.title:SetWidth(158)
        editor.title:SetJustifyH("LEFT")
        editor.title:SetTextColor(0.62, 0.90, 1.00)

        editor.hint = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        editor.hint:SetPoint("TOPLEFT", editor.title, "BOTTOMLEFT", 0, -3)
        editor.hint:SetWidth(158)
        editor.hint:SetHeight(38)
        editor.hint:SetJustifyH("LEFT")
        editor.hint:SetJustifyV("TOP")
        editor.hint:SetWordWrap(true)
        editor.hint:SetTextColor(0.72, 0.82, 0.88)

        editor.slots = {}
        for index = 1, 5 do
            local slot = CreateFrame("Button", nil, editor, "BackdropTemplate")
            slot:SetSize(46, 46)
            slot:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            slot:SetBackdropColor(0.01, 0.03, 0.04, 0.98)
            slot:SetBackdropBorderColor(0.22, 0.62, 0.78, 0.96)
            slot.icon = slot:CreateTexture(nil, "ARTWORK")
            slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 3, -3)
            slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -3, 3)
            slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            slot.rowText = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            slot.rowText:SetPoint("BOTTOM", slot, "TOP", 0, 2)
            slot.rowText:SetTextColor(0.72, 0.86, 0.94)
            slot:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
            local highlight = slot:GetHighlightTexture()
            if highlight then
                highlight:SetAllPoints(slot)
                highlight:SetVertexColor(1, 1, 1, 0.08)
            end
            slot:SetScript("OnClick", function(self)
                if addon and addon.CycleDKAdvisorFolioDraft then
                    addon:CycleDKAdvisorFolioDraft(self.dkAdvisorRoot, self.dkAdvisorRow)
                end
            end)
            slot:SetScript("OnEnter", function(self)
                if not GameTooltip then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local candidate = self.dkAdvisorCandidate
                if candidate and candidate.spellID then
                    local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, candidate.spellID)
                    if not ok then GameTooltip:SetText(candidate.name or T("Omnium Folio")) end
                else
                    GameTooltip:SetText(candidate and candidate.name or T("Omnium Folio"))
                end
                GameTooltip:AddLine(" ")
                if self.dkAdvisorFixed then
                    GameTooltip:AddLine(T("This Folio row is fixed."), 0.62, 0.86, 1.00, true)
                elseif self.dkAdvisorCanEdit then
                    GameTooltip:AddLine(T("Click to cycle through the available choices for this Folio row."), 0.72, 0.92, 1.00, true)
                else
                    GameTooltip:AddLine(T("Folio editing is unavailable until the live Omnium Folio tree can be read."), 0.90, 0.76, 0.42, true)
                end
                if self.dkAdvisorRecommended then
                    GameTooltip:AddLine(T("DK Mentor recommendation"), 1.00, 0.82, 0.30, true)
                end
                GameTooltip:Show()
            end)
            slot:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            editor.slots[index] = slot
        end

        local function CreateEditorButton(label)
            local button = CreateFrame("Button", nil, editor, "BackdropTemplate")
            button:SetSize(104, 24)
            button:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            button:SetBackdropColor(0.04, 0.12, 0.16, 0.96)
            button:SetBackdropBorderColor(0.22, 0.62, 0.78, 0.92)
            button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            button.text:SetPoint("CENTER")
            button.text:SetText(T(label))
            button.text:SetTextColor(0.86, 0.96, 1.00)
            button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
            local h = button:GetHighlightTexture()
            if h then h:SetAllPoints(button); h:SetVertexColor(1,1,1,0.07) end
            return button
        end

        editor.recommendedButton = CreateEditorButton("Recommended")
        editor.applyButton = CreateEditorButton("Apply Folio")
        editor.recommendedButton:SetScript("OnClick", function()
            if addon and addon.ResetDKAdvisorFolioDraftToRecommended then
                addon:ResetDKAdvisorFolioDraftToRecommended(editor.dkAdvisorRoot)
            end
        end)
        editor.applyButton:SetScript("OnClick", function()
            if addon and addon.ApplyDKAdvisorFolioDraft then
                addon:ApplyDKAdvisorFolioDraft(editor.dkAdvisorRoot)
            end
        end)

        editor.state = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        editor.state:SetJustifyH("RIGHT")
        editor.state:SetTextColor(0.72, 0.86, 0.92)

        root.dkAdvisorFolioEditor = editor
    end
    editor:Show()
    editor.dkAdvisorRoot = root
    return editor
end

function addon:RefreshDKAdvisorFolioEditor(root)
    local editor = root and root.dkAdvisorFolioEditor
    local runtime = root and root.dkAdvisorFolioRuntime
    local draft = root and root.dkAdvisorFolioDraft
    if not editor or not runtime or not draft then return end

    local contentWidth = root:GetWidth() or 760
    editor:SetWidth(contentWidth)
    editor:SetHeight(82)
    editor.title:SetText(T("Folio quick editor"))
    editor.hint:SetText(T("Click a rune to cycle that row, then apply outside combat."))

    local slotStartX = 184
    local slotGap = 10
    local changes = 0
    local mappedRows = 0
    for index, rowInfo in ipairs(runtime.rows or {}) do
        local slot = editor.slots[index]
        if slot then
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", editor, "TOPLEFT", slotStartX + ((index - 1) * (46 + slotGap)), -25)
            local desiredEntryID = draft[rowInfo.row] or rowInfo.currentEntryID or rowInfo.recommendedEntryID
            local candidate = GetFolioCandidateByEntryID(rowInfo, desiredEntryID)
            slot.dkAdvisorRoot = root
            slot.dkAdvisorRow = rowInfo.row
            slot.dkAdvisorCandidate = candidate
            slot.dkAdvisorFixed = rowInfo.fixed == true
            slot.dkAdvisorCanEdit = runtime.canEdit == true and #((rowInfo and rowInfo.candidates) or {}) > 1
            slot.dkAdvisorRecommended = candidate and rowInfo.recommendedEntryID and tonumber(candidate.entryID) == tonumber(rowInfo.recommendedEntryID) or false
            slot.icon:SetTexture(candidate and candidate.icon or (QUESTION_MARK_ICON or 134400))
            slot.rowText:SetText(T("Row %d", rowInfo.row))
            if slot.dkAdvisorRecommended then
                slot:SetBackdropBorderColor(1.00, 0.78, 0.28, 0.98)
            elseif slot.dkAdvisorCanEdit then
                slot:SetBackdropBorderColor(0.28, 0.72, 0.92, 0.96)
            else
                slot:SetBackdropBorderColor(0.42, 0.54, 0.60, 0.88)
            end
            slot.icon:SetDesaturated(not slot.dkAdvisorCanEdit and not slot.dkAdvisorFixed and runtime.canEdit ~= true)
            if rowInfo.currentEntryID and desiredEntryID and tonumber(rowInfo.currentEntryID) ~= tonumber(desiredEntryID) then changes = changes + 1 end
            if rowInfo.nodeID then mappedRows = mappedRows + 1 end
            slot:Show()
        end
    end
    for index = #(runtime.rows or {}) + 1, #editor.slots do editor.slots[index]:Hide() end

    editor.recommendedButton:ClearAllPoints()
    editor.recommendedButton:SetPoint("TOPRIGHT", editor, "TOPRIGHT", -10, -10)
    editor.applyButton:ClearAllPoints()
    editor.applyButton:SetPoint("TOPRIGHT", editor.recommendedButton, "BOTTOMRIGHT", 0, -6)
    editor.state:ClearAllPoints()
    editor.state:SetPoint("BOTTOMRIGHT", editor, "BOTTOMRIGHT", -124, 8)
    editor.state:SetWidth(190)

    local canEdit = runtime.canEdit == true and mappedRows == #(runtime.rows or {})
    if not canEdit then
        editor.state:SetText(T("Live Folio tree unavailable"))
        editor.state:SetTextColor(1.00, 0.72, 0.32)
    elseif InCombatLockdown and InCombatLockdown() then
        editor.state:SetText(T("Cannot apply in combat"))
        editor.state:SetTextColor(1.00, 0.46, 0.40)
    elseif changes > 0 then
        editor.state:SetText(T("%d pending change(s)", changes))
        editor.state:SetTextColor(1.00, 0.82, 0.35)
    else
        editor.state:SetText(T("Folio matches draft"))
        editor.state:SetTextColor(0.40, 1.00, 0.60)
    end

    local applyEnabled = canEdit and changes > 0 and not (InCombatLockdown and InCombatLockdown())
    editor.applyButton:SetBackdropBorderColor(applyEnabled and 0.28 or 0.22, applyEnabled and 0.78 or 0.38, applyEnabled and 0.46 or 0.46, 0.94)
    editor.applyButton.text:SetTextColor(applyEnabled and 0.70 or 0.62, applyEnabled and 1.00 or 0.72, applyEnabled and 0.78 or 0.78)
    editor.recommendedButton:SetBackdropBorderColor(canEdit and 0.78 or 0.38, canEdit and 0.62 or 0.42, canEdit and 0.22 or 0.42, 0.92)
end

function addon:CycleDKAdvisorFolioDraft(root, rowNumber)
    if not root or not root.dkAdvisorFolioRuntime or not root.dkAdvisorFolioDraft then return end
    if InCombatLockdown and InCombatLockdown() then
        if self.Print then self:Print(T("Omnium Folio changes cannot be applied in combat.")) end
        return
    end
    for _, rowInfo in ipairs(root.dkAdvisorFolioRuntime.rows or {}) do
        if tonumber(rowInfo.row) == tonumber(rowNumber) then
            if rowInfo.fixed or #((rowInfo and rowInfo.candidates) or {}) <= 1 or not root.dkAdvisorFolioRuntime.canEdit then return end
            local current = tonumber(root.dkAdvisorFolioDraft[rowInfo.row] or rowInfo.currentEntryID or rowInfo.recommendedEntryID)
            local currentIndex = 1
            for index, candidate in ipairs(rowInfo.candidates or {}) do
                if tonumber(candidate.entryID) == current then currentIndex = index; break end
            end
            local nextIndex = currentIndex + 1
            if nextIndex > #(rowInfo.candidates or {}) then nextIndex = 1 end
            local candidate = rowInfo.candidates[nextIndex]
            if candidate and candidate.entryID then root.dkAdvisorFolioDraft[rowInfo.row] = candidate.entryID end
            root.dkAdvisorFolioDraftDirty = true
            self:RefreshDKAdvisorFolioEditor(root)
            return
        end
    end
end

function addon:ResetDKAdvisorFolioDraftToRecommended(root)
    if not root or not root.dkAdvisorFolioRuntime then return end
    root.dkAdvisorFolioDraft = root.dkAdvisorFolioDraft or {}
    for _, rowInfo in ipairs(root.dkAdvisorFolioRuntime.rows or {}) do
        if rowInfo.recommendedEntryID then root.dkAdvisorFolioDraft[rowInfo.row] = rowInfo.recommendedEntryID end
    end
    root.dkAdvisorFolioDraftDirty = true
    self:RefreshDKAdvisorFolioEditor(root)
end

function addon:ApplyDKAdvisorFolioDraft(root)
    if not root or not root.dkAdvisorFolioRuntime or not root.dkAdvisorFolioDraft then return false end
    local runtime = root.dkAdvisorFolioRuntime
    if runtime.canEdit ~= true or not runtime.configID then
        if self.Print then self:Print(T("The live Omnium Folio tree is not available yet, so DK Mentor cannot apply changes.")) end
        return false
    end
    if InCombatLockdown and InCombatLockdown() then
        if self.Print then self:Print(T("Omnium Folio changes cannot be applied in combat.")) end
        return false
    end

    local traits = C_Traits
    if not traits or not traits.SetSelection or not traits.CommitConfig then
        if self.Print then self:Print(T("This client does not expose the Omnium Folio editing API.")) end
        return false
    end

    if traits.ConfigHasStagedChanges then
        local okPending, pending = pcall(traits.ConfigHasStagedChanges, runtime.configID)
        if okPending and pending == true then
            if self.Print then self:Print(T("The Omnium Folio already has pending changes. Apply or cancel those changes first, then try again.")) end
            return false
        end
    end

    local changed = 0
    for _, rowInfo in ipairs(runtime.rows or {}) do
        local desired = tonumber(root.dkAdvisorFolioDraft[rowInfo.row])
        local current = tonumber(rowInfo.currentEntryID)
        if desired and rowInfo.nodeID and not rowInfo.fixed and desired ~= current then
            local okSet, success = pcall(traits.SetSelection, runtime.configID, rowInfo.nodeID, desired)
            if not okSet or success == false then
                if traits.RollbackConfig then pcall(traits.RollbackConfig, runtime.configID) end
                if self.Print then self:Print(T("DK Mentor could not stage Folio row %d. The choice may still be locked.", rowInfo.row)) end
                return false
            end
            changed = changed + 1
        end
    end

    if changed == 0 then
        if self.Print then self:Print(T("No Omnium Folio changes to apply.")) end
        return true
    end

    local okCommit, committed = pcall(traits.CommitConfig, runtime.configID)
    if not okCommit or committed == false then
        if traits.RollbackConfig then pcall(traits.RollbackConfig, runtime.configID) end
        if self.Print then self:Print(T("DK Mentor could not commit the Omnium Folio changes.")) end
        return false
    end

    root.dkAdvisorFolioDraft = nil
    root.dkAdvisorFolioDraftKey = nil
    root.dkAdvisorFolioDraftDirty = nil
    if self.Print then self:Print(T("Omnium Folio updated: %d row(s) changed.", changed)) end
    if C_Timer and C_Timer.After then
        C_Timer.After(0.15, function()
            if addon and addon.UpdateGuideSection then addon:UpdateGuideSection() end
        end)
    elseif self.UpdateGuideSection then
        self:UpdateGuideSection()
    end
    return true
end

local function EnsureAdvisorContextButtons(root)
    root.advisorContextButtons = root.advisorContextButtons or {}
    local choices = {
        { key = "auto", label = "Auto", iconSpellID = 47568 }, -- Empower Rune Weapon
        { key = "pve", label = "PvE", iconSpellID = 43265 },   -- Death and Decay
        { key = "pvp", label = "PvP", iconSpellID = 45524 },   -- Chains of Ice
    }
    for index, choice in ipairs(choices) do
        local button = root.advisorContextButtons[index]
        if not button then
            button = CreateFrame("Button", nil, root, "BackdropTemplate")
            button:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetSize(15, 15)
            button.icon:SetPoint("LEFT", button, "LEFT", 9, 0)
            button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            button.label:SetPoint("LEFT", button.icon, "RIGHT", 5, 0)
            button.label:SetPoint("RIGHT", button, "RIGHT", -6, 0)
            button.label:SetJustifyH("LEFT")
            button:SetScript("OnClick", function(self)
                addon:SetDKAdvisorContextMode(self.advisorContextMode)
            end)
            root.advisorContextButtons[index] = button
        end
        button.advisorContextMode = choice.key
        button.labelKey = choice.label
        button.iconSpellID = choice.iconSpellID
        if button.icon then button.icon:SetTexture(GetSpellTextureSafe(choice.iconSpellID)) end
    end
    return root.advisorContextButtons
end

function addon:RenderDKAdvisorVisual(specID)
    local root = self:EnsureGearMentorVisual()
    if not root then return nil end
    local data = self:GetDKAdvisorRecommendation(specID)
    if not data or not data.stats or not data.statRecommendation then return nil end

    self:ResetGearVisual(root)
    HideAdvisorVisualPools(root)
    root:Show()

    local y = 0
    local rootParent = root:GetParent()
    local availableWidth = (rootParent and rootParent:GetWidth()) or root:GetWidth() or 0
    if not availableWidth or availableWidth < 620 then availableWidth = root:GetWidth() or 760 end
    root:SetWidth(availableWidth)
    local contentWidth = math.max(620, math.floor(availableWidth - 4))
    local gap = 8
    local metricWidth = math.floor((contentWidth - (gap * 3)) / 4)

    local function AddText(textValue, fontObject, height, color)
        local text = self:AcquireGearText(root, fontObject or "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
        text:SetWidth(contentWidth)
        text:SetHeight(1)
        text:SetWordWrap(true)
        if color then text:SetTextColor(color[1], color[2], color[3]) end
        text:SetText(T(textValue or ""))
        local actualHeight = math.max(height or 20, math.ceil((text.GetStringHeight and text:GetStringHeight()) or (height or 20)))
        text:SetHeight(actualHeight)
        y = y - actualHeight - 5
        return text
    end

    local function AddPanel(titleValue, bodyValue, borderStatus)
        local panel = self:AcquireGearPanel(root)
        panel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
        panel:SetWidth(contentWidth)
        if borderStatus then
            local r, g, b = StatusColor(borderStatus)
            panel:SetBackdropBorderColor(r, g, b, 0.88)
        end
        local title = self:AcquireGearPanelText(panel, "GameFontNormal")
        title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
        title:SetWidth(contentWidth - 20)
        title:SetHeight(18)
        title:SetTextColor(0.62, 0.90, 1.00)
        title:SetText(T(titleValue or ""))
        local body = self:AcquireGearPanelText(panel, "GameFontHighlightSmall")
        body:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -30)
        body:SetWidth(contentWidth - 20)
        body:SetHeight(240)
        body:SetWordWrap(true)
        body:SetText(T(bodyValue or ""))
        local bodyHeight = math.max(24, math.ceil((body.GetStringHeight and body:GetStringHeight()) or 24))
        body:SetHeight(bodyHeight)
        local h = 42 + bodyHeight
        panel:SetHeight(h)
        y = y - h - 8
        return panel
    end

    local specName = (DKM.Data and DKM.Data.specNames and DKM.Data.specNames[specID]) or "Death Knight"
    local activeSpecID, activeSpecName = self:GetSpecInfo()
    local title = self:AcquireGearText(root, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    title:SetWidth(contentWidth - 190)
    title:SetHeight(24)
    title:SetTextColor(0.55, 0.88, 1.00)
    title:SetText(T("DK Stats & Folio Advisor"))
    local sr, sg, sb = StatusColor(data.stats.freshness)
    local status = EnsureAdvisorStatusChip(root)
    status:ClearAllPoints()
    status:SetPoint("TOPRIGHT", root, "TOPRIGHT", -28, y + 1)
    status:SetSize(150, 24)
    status:SetBackdropColor(sr * 0.10, sg * 0.10, sb * 0.10, 0.96)
    status:SetBackdropBorderColor(sr * 0.62, sg * 0.62, sb * 0.62, 0.94)
    status.text:SetTextColor(sr, sg, sb)
    status.text:SetText(StatusText(data.stats.freshness))
    y = y - 32

    local heroLabel = data.hero and T(data.hero) or T("Not detected")
    local contextLabel
    if data.context == "pve" then contextLabel = T("PvE")
    elseif data.context == "pvp" then contextLabel = T("PvP")
    else contextLabel = self.GetRuntimeContextLabel and self:GetRuntimeContextLabel(data.context) or T(data.context) end
    local browseNote
    if tonumber(activeSpecID) == tonumber(specID) then
        browseNote = T("Live character: %s • Hero Talent: %s • context: %s", tostring(activeSpecName or specName), heroLabel, contextLabel)
    else
        browseNote = T("Browsing %s • live stat cards still show your active %s character", T(specName), T(activeSpecName or "Death Knight"))
    end
    AddText(browseNote, "GameFontHighlightSmall", 22, {0.78, 0.89, 0.95})

    local mode = self:GetDKAdvisorContextMode()
    local buttons = EnsureAdvisorContextButtons(root)
    local buttonWidth = 104
    for index, button in ipairs(buttons) do
        button:ClearAllPoints()
        button:SetSize(buttonWidth, 27)
        button:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + (index - 1) * (buttonWidth + 7), y)
        local active = button.advisorContextMode == mode
        button:SetBackdropColor(active and 0.06 or 0.02, active and 0.20 or 0.07, active and 0.26 or 0.09, 0.94)
        button:SetBackdropBorderColor(active and 0.32 or 0.13, active and 0.78 or 0.40, active and 0.95 or 0.52, active and 0.98 or 0.72)
        button.label:SetText(T(button.labelKey))
        button.label:SetTextColor(active and 0.86 or 0.72, active and 0.96 or 0.84, active and 1.00 or 0.91)
        button:Show()
    end
    local contextHint = self:AcquireGearText(root, "GameFontHighlightSmall")
    contextHint:SetPoint("LEFT", buttons[#buttons], "RIGHT", 11, 0)
    contextHint:SetWidth(math.max(160, contentWidth - (buttonWidth + 7) * #buttons - 14))
    contextHint:SetHeight(27)
    contextHint:SetJustifyV("MIDDLE")
    contextHint:SetTextColor(0.66, 0.78, 0.84)
    contextHint:SetText(T(mode == "auto" and "AUTO uses your current content; PvE/PvP can be pinned for planning." or "Manual Advisor context; switch to Auto to follow your current content."))
    y = y - 38

    local snapshot = self:GetDKAdvisorStatSnapshot()
    local order = { "crit", "haste", "mastery", "versatility" }
    for index, key in ipairs(order) do
        local value = snapshot[key] or {}
        local card = AcquireAdvisorStatCard(root, index)
        card:SetSize(metricWidth, 78)
        card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + (index - 1) * (metricWidth + gap), y)
        card.rating:SetWidth(math.max(48, metricWidth - 86))
        card.label:SetText(T((AdvisorData.statLabels and AdvisorData.statLabels[key]) or key))
        local pct = self:FormatStatPercent(value.percent)
        local rating = type(value.rating) == "number" and tostring(math.floor(value.rating + 0.5)) or "?"
        local dr, r, g, b = self:GetDKAdvisorDRState(key, value.rating)
        card.percent:SetText(pct)
        card.rating:SetText(T("%s rating", rating))
        card.dr:SetText(dr)
        card.dr:SetTextColor(r, g, b)
        card:SetBackdropBorderColor(r * 0.45, g * 0.45, b * 0.45, 0.90)
    end
    y = y - 90

    local statBody = T("%s\n%s", T(data.statRecommendation.priority or ""), T(data.statRecommendation.note or ""))
    if not data.hero and data.stats.hero then
        local heroLines = {}
        for _, heroEntry in ipairs((AdvisorData.heroMarkers and AdvisorData.heroMarkers[specID]) or {}) do
            local heroRec = data.stats.hero[heroEntry.name]
            if heroRec then heroLines[#heroLines + 1] = T("%s: %s", T(heroEntry.name), T(heroRec.priority or "")) end
        end
        if #heroLines > 0 then
            statBody = statBody .. "\n\n" .. T("Hero Talent variants") .. "\n" .. table.concat(heroLines, "\n")
        end
    end
    AddPanel(T("Recommended stat direction — %s", T(specName)), statBody, data.stats.freshness)

    local dr = AdvisorData.diminishingReturns
    AddPanel("Diminishing returns — rating thresholds", T("Crit %d / %d / %d  •  Haste %d / %d / %d\nMastery %d / %d / %d  •  Versatility %d / %d / %d\nThese thresholds use rating from gear. Percentage-based buffs/procs do not consume the rating thresholds.", dr.crit[1], dr.crit[2], dr.crit[3], dr.haste[1], dr.haste[2], dr.haste[3], dr.mastery[1], dr.mastery[2], dr.mastery[3], dr.versatility[1], dr.versatility[2], dr.versatility[3]))

    if data.folio then
        AddText("Omnium Folio", "GameFontNormal", 22, {0.92, 0.80, 0.45})
        local selectedSet, detected = self:GetOmniumFolioSelectedSpellSet()
        local runtime, runtimeMapped = self:GetOmniumFolioRuntimeRows(data.folio)
        if runtime then
            runtime.canEdit = runtimeMapped == true and runtime.canEdit ~= false
            root.dkAdvisorFolioRuntime = runtime
            local draftKey = tostring(specID) .. ":" .. tostring(data.bucket or "pve")
            if root.dkAdvisorFolioDraftKey ~= draftKey or not root.dkAdvisorFolioDraft or root.dkAdvisorFolioDraftDirty ~= true then
                root.dkAdvisorFolioDraftKey = draftKey
                root.dkAdvisorFolioDraft = {}
                root.dkAdvisorFolioDraftDirty = false
                for _, rowInfo in ipairs(runtime.rows or {}) do
                    root.dkAdvisorFolioDraft[rowInfo.row] = rowInfo.currentEntryID or rowInfo.recommendedEntryID
                end
            end

            if runtimeMapped then
                selectedSet = {}
                local runtimeDetected = false
                for _, rowInfo in ipairs(runtime.rows or {}) do
                    local candidate = GetFolioCandidateByEntryID(rowInfo, rowInfo.currentEntryID)
                    if candidate and candidate.spellID then
                        selectedSet[candidate.spellID] = true
                        runtimeDetected = true
                    end
                end
                if runtimeDetected then detected = true end
            end

            local editor = EnsureAdvisorFolioEditor(root)
            editor:ClearAllPoints()
            editor:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
            editor:SetWidth(contentWidth)
            self:RefreshDKAdvisorFolioEditor(root)
            y = y - 90
        else
            root.dkAdvisorFolioRuntime = nil
            root.dkAdvisorFolioDraft = nil
            root.dkAdvisorFolioDraftKey = nil
            root.dkAdvisorFolioDraftDirty = nil
        end
        if not detected then
            AddText("Live Folio tree unavailable right now — guide recommendations remain visible, but editing is disabled until the game exposes the Omnium Folio config.", "GameFontHighlightSmall", 20, {0.90, 0.76, 0.42})
        end
        local folioIndex = 0
        for _, folioRow in ipairs(data.folio.rows or {}) do
            local runeData = AdvisorData.folioRunes and AdvisorData.folioRunes[folioRow.rune]
            if runeData then
                folioIndex = folioIndex + 1
                local selected = detected and self:IsRecommendedFolioRuneSelected(folioRow.rune, selectedSet) or nil
                local spellID = GetPrimaryRuneSpellID(runeData)
                local runeName = GetSpellNameSafe(spellID, T(runeData.name))
                local rowFrame = AcquireAdvisorFolioRow(root, folioIndex)
                rowFrame:SetSize(contentWidth, 58)
                rowFrame:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
                rowFrame.spellID = spellID
                rowFrame.runeName = runeName
                rowFrame.icon:SetTexture(GetSpellTextureSafe(spellID))
                rowFrame.line:SetText(T("Row %d", folioRow.row))
                rowFrame.name:SetWidth(math.max(260, contentWidth - 220))
                rowFrame.name:SetText(runeName)

                local statusText, tr, tg, tb
                if folioRow.fixed then
                    statusText = T("FIXED ROW")
                    tr, tg, tb = 0.52, 0.82, 0.96
                elseif detected and selected == true then
                    statusText = T("MATCH")
                    tr, tg, tb = 0.40, 1.00, 0.60
                elseif detected and selected == false then
                    statusText = T("REVIEW")
                    tr, tg, tb = 1.00, 0.78, 0.28
                else
                    statusText = T("RECOMMENDED")
                    tr, tg, tb = 0.62, 0.88, 0.98
                end
                rowFrame.status:SetText(statusText)
                rowFrame.status:SetTextColor(tr, tg, tb)
                rowFrame.statusFrame:SetBackdropColor(tr * 0.10, tg * 0.10, tb * 0.10, 0.96)
                rowFrame.statusFrame:SetBackdropBorderColor(tr * 0.62, tg * 0.62, tb * 0.62, 0.94)
                rowFrame:SetBackdropBorderColor(tr * 0.36, tg * 0.36, tb * 0.36, 0.88)
                y = y - 65
            end
        end

        local folioNote = T(data.folio.note or "")
        local editorNote = T("DK Mentor never changes the Folio automatically. The quick editor only stages the rows you choose and applies them when you press Apply Folio outside combat; locked or unavailable choices are left unchanged.")
        AddPanel("Folio note", folioNote .. "\n" .. editorNote, data.folio.freshness)
    end

    local sourceStatus = StatusText(data.stats.freshness)
    local sourceLine = T("Stats source: %s • guide updated %s • DK Mentor reviewed %s • %s", data.stats.sourceName or "-", data.stats.sourceUpdated or "-", AdvisorData.reviewed, sourceStatus)
    if data.folio then
        sourceLine = sourceLine .. "\n" .. T("Folio source: %s • guide updated %s", data.folio.sourceName or "-", data.folio.sourceUpdated or "-")
    end
    AddPanel("Data freshness", sourceLine, data.stats.freshness)

    root:SetHeight(math.max(1, -y + 8))
    return math.max(1, -y + 8)
end

function addon:BuildGearTargetTooltipIndex()
    local index = {}
    local function Add(itemID, entry)
        itemID = tonumber(itemID)
        if not itemID then return end
        index[itemID] = index[itemID] or {}
        index[itemID][#index[itemID] + 1] = entry
    end
    for specID, spec in pairs((GearData and GearData.specs) or {}) do
        local specName = (DKM.Data and DKM.Data.specNames and DKM.Data.specNames[specID]) or tostring(specID)
        for _, target in ipairs(spec.targets or {}) do
            Add(target.itemID, { spec = specName, slot = target.slot, priority = target.priority, source = target.source, kind = "target" })
        end
        for _, target in ipairs(spec.craftTargets or {}) do
            Add(target.itemID, { spec = specName, slot = target.slot, priority = target.priority, source = target.source, kind = "craft" })
        end
    end
    for _, piece in ipairs((GearData and GearData.tierSet and GearData.tierSet.pieces) or {}) do
        Add(piece.itemID, { spec = "Blood / Frost / Unholy", slot = piece.slot, priority = "TIER", source = "Season 2 tier / Catalyst", kind = "tier" })
    end
    self.dkGearTargetTooltipIndex = index
    return index
end

function addon:RegisterGearTargetTooltipIntegration()
    if self.dkGearTooltipRegistered then return end
    if not TooltipDataProcessor or not TooltipDataProcessor.AddTooltipPostCall or not Enum or not Enum.TooltipDataType or not Enum.TooltipDataType.Item then return end
    self.dkGearTooltipRegistered = true
    local index = self:BuildGearTargetTooltipIndex()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if not addon.active or not tooltip then return end
        local itemID = data and tonumber(data.id) or nil
        if not itemID and tooltip.GetItem then
            local ok, _, link = pcall(tooltip.GetItem, tooltip)
            if ok and type(link) == "string" then
                if GetItemInfoInstant then
                    local okID, resolved = pcall(GetItemInfoInstant, link)
                    if okID and type(resolved) == "number" then itemID = resolved end
                end
                if not itemID then itemID = tonumber(link:match("item:(%d+)")) end
            end
        end
        local entries = itemID and index[itemID] or nil
        if not entries or #entries == 0 then return end
        if tooltip.__DKMentorTargetItemID == itemID then return end
        tooltip.__DKMentorTargetItemID = itemID
        if not tooltip.__DKMentorClearHooked and tooltip.HookScript then
            tooltip.__DKMentorClearHooked = true
            tooltip:HookScript("OnTooltipCleared", function(self) self.__DKMentorTargetItemID = nil end)
        end
        tooltip:AddLine(" ")
        tooltip:AddLine(T("DK Mentor • Gear Target"), 0.42, 0.86, 1.00, true)
        if addon.GetGearTargetState then
            local state = addon:GetGearTargetState({ itemID = itemID })
            local stateText = state == "equipped" and T("EQUIPPED") or (state == "owned" and T("OWNED") or T("MISSING"))
            local sr, sg, sb = state == "equipped" and 0.40 or (state == "owned" and 0.42 or 1.00), state == "equipped" and 1.00 or (state == "owned" and 0.82 or 0.78), state == "equipped" and 0.60 or (state == "owned" and 1.00 or 0.28)
            tooltip:AddLine(T("Collection status: %s", stateText), sr, sg, sb, true)
        end
        for _, entry in ipairs(entries) do
            local prefix = entry.kind == "craft" and T("CRAFT") or (entry.kind == "tier" and T("TIER") or T(entry.priority or "TARGET"))
            tooltip:AddLine(T("%s • %s • %s", T(entry.spec or "DK"), prefix, T(entry.slot or "")), 0.88, 0.96, 1.00, true)
            if entry.source and entry.source ~= "" then
                tooltip:AddLine(T("Source: %s", T(entry.source)), 0.70, 0.82, 0.88, true)
            end
        end
    end)
end
