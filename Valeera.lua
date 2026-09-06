local ADDON_NAME, DKM = ...

local addon = DKM.Addon
local Data = DKM.Data or {}
local ValeeraData = DKM.ValeeraData
local T = DKM.T or function(value, ...)
    if select("#", ...) > 0 then return string.format(value, ...) end
    return value
end

if not addon or not ValeeraData then return end

local QUESTION_MARK_ICON = 134400
local PREFIX = "|cff69ccf0DK Mentor|r"

local function PrintMessage(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": " .. tostring(message))
    end
end

local function GetSpellNameAndIcon(spellID, fallbackName)
    spellID = tonumber(spellID)
    local name, icon
    if spellID and C_Spell then
        if C_Spell.GetSpellName then
            local ok, value = pcall(C_Spell.GetSpellName, spellID)
            if ok and type(value) == "string" and value ~= "" then name = value end
        end
        if C_Spell.GetSpellTexture then
            local ok, value = pcall(C_Spell.GetSpellTexture, spellID)
            if ok and type(value) == "number" then icon = value end
        end
    end
    if spellID and (not name or not icon) and GetSpellInfo then
        local ok, spellName, _, spellIcon = pcall(GetSpellInfo, spellID)
        if ok then
            if not name and type(spellName) == "string" and spellName ~= "" then name = spellName end
            if not icon and type(spellIcon) == "number" then icon = spellIcon end
        end
    end
    return name or T(fallbackName or "Unknown"), icon or QUESTION_MARK_ICON
end

local function GetSpecName(specID)
    return (Data.specNames and Data.specNames[specID]) or (specID == 250 and T("Blood")) or (specID == 252 and T("Unholy")) or T("Frost")
end

local function StatusColors(active)
    if active then return 0.24, 0.86, 0.60, 0.98 end
    return 0.18, 0.48, 0.62, 0.88
end

local function ApplyCardBorder(card, active)
    local r, g, b, a = StatusColors(active)
    card:SetBackdropBorderColor(r, g, b, a)
    card:SetBackdropColor(active and 0.025 or 0.018, active and 0.10 or 0.055, active and 0.115 or 0.075, 0.94)
end

function addon:HideValeeraVisualPools(root)
    for _, button in ipairs(root.valeeraPresetButtons or {}) do button:Hide() end
    for _, card in ipairs(root.valeeraCardPool or {}) do card:Hide() end
    if root.valeeraStatusChip then root.valeeraStatusChip:Hide() end
    if root.valeeraOpenConfigButton then root.valeeraOpenConfigButton:Hide() end
    root.valeeraCardUsed = 0
end

local function AcquireValeeraCard(root)
    root.valeeraCardPool = root.valeeraCardPool or {}
    root.valeeraCardUsed = (root.valeeraCardUsed or 0) + 1
    local card = root.valeeraCardPool[root.valeeraCardUsed]
    if not card then
        card = CreateFrame("Frame", nil, root, "BackdropTemplate")
        card:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)

        card.iconFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
        card.iconFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        card.iconFrame:SetBackdropColor(0.01, 0.03, 0.04, 0.98)
        card.iconFrame:SetBackdropBorderColor(0.24, 0.64, 0.80, 0.96)
        card.icon = card.iconFrame:CreateTexture(nil, "ARTWORK")
        card.icon:SetPoint("TOPLEFT", card.iconFrame, "TOPLEFT", 2, -2)
        card.icon:SetPoint("BOTTOMRIGHT", card.iconFrame, "BOTTOMRIGHT", -2, 2)
        card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        card.kicker = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.kicker:SetJustifyH("LEFT")
        card.kicker:SetTextColor(0.57, 0.80, 0.90)

        card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.name:SetJustifyH("LEFT")
        card.name:SetJustifyV("TOP")
        card.name:SetWordWrap(true)
        card.name:SetTextColor(0.95, 0.98, 1.00)

        card.tag = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.tag:SetJustifyH("LEFT")
        card.tag:SetTextColor(0.92, 0.78, 0.36)

        card.body = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.body:SetJustifyH("LEFT")
        card.body:SetJustifyV("TOP")
        card.body:SetWordWrap(true)
        card.body:SetTextColor(0.80, 0.88, 0.92)

        card.hit = CreateFrame("Button", nil, card)
        card.hit:SetAllPoints(card)
        card.hit:EnableMouse(true)
        card.hit:RegisterForClicks("LeftButtonUp")

        root.valeeraCardPool[#root.valeeraCardPool + 1] = card
    end
    card:ClearAllPoints()
    card.hit:SetScript("OnClick", nil)
    card.hit:SetScript("OnEnter", nil)
    card.hit:SetScript("OnLeave", nil)
    card:Show()
    return card
end

local function ConfigureValeeraCard(card, data, width, height, kicker, active, clickable)
    width = width or 220
    height = height or 92
    card:SetSize(width, height)
    ApplyCardBorder(card, active)

    local name, icon = GetSpellNameAndIcon(data and data.spellID, data and (data.fallbackName or data.label))
    if data and data.label and not data.fallbackName then name = T(data.label) end
    card.icon:SetTexture(icon)
    card.iconFrame:ClearAllPoints()
    card.iconFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -9)
    card.iconFrame:SetSize(38, 38)

    card.kicker:ClearAllPoints()
    card.kicker:SetPoint("TOPLEFT", card, "TOPLEFT", 54, -8)
    card.kicker:SetWidth(width - 64)
    card.kicker:SetHeight(14)
    card.kicker:SetText(T(kicker or ""))

    card.name:ClearAllPoints()
    card.name:SetPoint("TOPLEFT", card.kicker, "BOTTOMLEFT", 0, -2)
    card.name:SetWidth(width - 64)
    card.name:SetHeight(34)
    card.name:SetText(name)

    card.tag:ClearAllPoints()
    card.tag:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -53)
    card.tag:SetWidth(width - 18)
    card.tag:SetHeight(14)
    card.tag:SetText(data and T(data.tag or "") or "")
    card.tag:SetTextColor(active and 0.42 or 0.92, active and 1.00 or 0.78, active and 0.64 or 0.36)

    card.body:ClearAllPoints()
    card.body:SetPoint("TOPLEFT", card.tag, "BOTTOMLEFT", 0, -3)
    card.body:SetWidth(width - 18)
    card.body:SetHeight(math.max(18, height - 74))
    card.body:SetText(data and T(data.description or "") or "")

    card.hit:EnableMouse(clickable == true or data ~= nil)
    if data and data.spellID then
        card.hit:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local shown = false
            if data.tooltipSpell ~= false and GameTooltip.SetSpellByID then
                local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, data.spellID)
                shown = ok
            end
            if not shown then GameTooltip:SetText(name) end
            if data.tag then GameTooltip:AddLine(T(data.tag), 1.00, 0.82, 0.35, true) end
            if data.description then GameTooltip:AddLine(T(data.description), 0.92, 0.95, 0.97, true) end
            GameTooltip:Show()
        end)
        card.hit:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end
    return card
end

local function EnsurePresetButtons(root)
    root.valeeraPresetButtons = root.valeeraPresetButtons or {}
    for index, key in ipairs(ValeeraData.presetOrder or {}) do
        local button = root.valeeraPresetButtons[index]
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
            root.valeeraPresetButtons[index] = button
        end
        button.presetKey = key
        button:SetScript("OnClick", function(self)
            if addon.SetValeeraPreset then addon:SetValeeraPreset(self.presetKey) end
        end)
        local preset = ValeeraData.presets[key]
        local _, icon = GetSpellNameAndIcon(preset and preset.spellID, preset and preset.label)
        button.icon:SetTexture(icon)
        button.label:SetText(preset and T(preset.label) or key)
        button:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(preset and T(preset.label) or key)
            if preset and preset.short then GameTooltip:AddLine(T(preset.short), 0.90, 0.94, 0.97, true) end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        button:Show()
    end
end

local function StylePresetButton(button, active)
    local r, g, b = StatusColors(active)
    button:SetBackdropColor(active and 0.025 or 0.018, active and 0.10 or 0.055, active and 0.115 or 0.075, 0.96)
    button:SetBackdropBorderColor(r, g, b, active and 0.98 or 0.72)
    button.label:SetTextColor(active and 0.58 or 0.84, active and 1.00 or 0.91, active and 0.76 or 0.96)
end

local function EnsureValeeraOpenConfigButton(root)
    local button = root.valeeraOpenConfigButton
    if not button then
        button = CreateFrame("Button", nil, root, "BackdropTemplate")
        button:SetBackdrop(addon.GEAR_VISUAL_BACKDROP)
        button:SetBackdropColor(0.025, 0.095, 0.12, 0.96)
        button:SetBackdropBorderColor(0.24, 0.72, 0.88, 0.94)

        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetSize(16, 16)
        button.icon:SetPoint("LEFT", button, "LEFT", 8, 0)
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local _, icon = GetSpellNameAndIcon(1784, "Valeera")
        button.icon:SetTexture(icon)

        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.label:SetPoint("LEFT", button.icon, "RIGHT", 5, 0)
        button.label:SetPoint("RIGHT", button, "RIGHT", -7, 0)
        button.label:SetJustifyH("LEFT")
        button.label:SetTextColor(0.82, 0.96, 1.00)
        button.label:SetText(T("Open Valeera setup"))

        button:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.035, 0.15, 0.18, 0.98)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(T("Open Valeera setup"))
            GameTooltip:AddLine(T("Open Blizzard's Valeera companion configuration to change role, Curios, and poison."), 0.92, 0.95, 0.97, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.025, 0.095, 0.12, 0.96)
            if GameTooltip then GameTooltip:Hide() end
        end)
        button:SetScript("OnClick", function()
            if addon.OpenValeeraCompanionConfiguration then addon:OpenValeeraCompanionConfiguration() end
        end)
        root.valeeraOpenConfigButton = button
    end
    button.label:SetText(T("Open Valeera setup"))
    button:Show()
    return button
end

local function AddSectionTitle(addonSelf, root, textValue, y, contentWidth)
    local title = addonSelf:AcquireGearText(root, "GameFontNormal")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    title:SetWidth(contentWidth)
    title:SetHeight(20)
    title:SetText(T(textValue))
    title:SetTextColor(0.92, 0.80, 0.45)
    return y - 25
end

local function ResolveRecommendation(specID, presetKey)
    local spec = ValeeraData.recommendations and ValeeraData.recommendations[specID]
    if not spec then return nil end
    return spec[presetKey] or spec.auto or spec.balanced
end

function addon:OpenValeeraCompanionConfiguration()
    if InCombatLockdown and InCombatLockdown() then
        PrintMessage(T("Valeera configuration cannot be opened during combat."))
        return false
    end

    local blizzardAddon = "Blizzard_DelvesCompanionConfiguration"
    local isLoaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, blizzardAddon)
        isLoaded = ok and loaded == true
    elseif IsAddOnLoaded then
        local ok, loaded = pcall(IsAddOnLoaded, blizzardAddon)
        isLoaded = ok and loaded == true
    end

    if not isLoaded then
        if C_AddOns and C_AddOns.LoadAddOn then
            pcall(C_AddOns.LoadAddOn, blizzardAddon)
        elseif LoadAddOn then
            pcall(LoadAddOn, blizzardAddon)
        end
    end

    local frame = _G.DelvesCompanionConfigurationFrame
    if frame then
        local ok = false
        if ShowUIPanel then
            ok = pcall(ShowUIPanel, frame)
        elseif frame.Show then
            ok = pcall(frame.Show, frame)
        end
        if ok then return true end
    end

    PrintMessage(T("Could not open Blizzard's Valeera companion configuration."))
    return false
end

function addon:RenderValeeraMentorVisual(specID)
    local root = self:EnsureGearMentorVisual()
    if not root then return nil end
    self:ResetGearVisual(root)
    root:Show()
    root.valeeraCardUsed = 0
    EnsurePresetButtons(root)

    local parent = root:GetParent()
    local availableWidth = parent and parent.GetWidth and parent:GetWidth() or root:GetWidth() or 760
    if not availableWidth or availableWidth < 620 then availableWidth = 760 end
    root:SetWidth(availableWidth)
    local contentWidth = math.max(620, math.floor(availableWidth - 4))
    local y = 0

    local presetKey = self.GetValeeraPreset and self:GetValeeraPreset() or "auto"
    local rec = ResolveRecommendation(specID, presetKey)
    if not rec then return nil end

    local title = self:AcquireGearText(root, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    title:SetWidth(contentWidth - 350)
    title:SetHeight(24)
    title:SetTextColor(0.55, 0.88, 1.00)
    title:SetText(T("Valeera — Delve Mentor"))

    local statusChip = root.valeeraStatusChip
    if not statusChip then
        statusChip = CreateFrame("Frame", nil, root, "BackdropTemplate")
        statusChip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        statusChip.text = statusChip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        statusChip.text:SetPoint("CENTER")
        root.valeeraStatusChip = statusChip
    end
    statusChip:ClearAllPoints()
    statusChip:SetPoint("TOPRIGHT", root, "TOPRIGHT", -4, y + 1)
    statusChip:SetSize(142, 24)
    local inDelve = self.DetectActualContext and self:DetectActualContext() == "delve"
    if inDelve then
        statusChip:SetBackdropColor(0.03, 0.18, 0.10, 0.96)
        statusChip:SetBackdropBorderColor(0.26, 0.86, 0.52, 0.96)
        statusChip.text:SetTextColor(0.52, 1.00, 0.70)
        statusChip.text:SetText(T("DELVE ACTIVE"))
    else
        statusChip:SetBackdropColor(0.05, 0.12, 0.17, 0.96)
        statusChip:SetBackdropBorderColor(0.26, 0.62, 0.80, 0.94)
        statusChip.text:SetTextColor(0.62, 0.88, 1.00)
        statusChip.text:SetText(T("DK GUIDE"))
    end
    statusChip:Show()

    local openConfigButton = EnsureValeeraOpenConfigButton(root)
    openConfigButton:ClearAllPoints()
    openConfigButton:SetPoint("RIGHT", statusChip, "LEFT", -8, 0)
    openConfigButton:SetSize(178, 24)

    y = y - 30

    local subtitle = self:AcquireGearText(root, "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    subtitle:SetWidth(contentWidth)
    subtitle:SetHeight(20)
    subtitle:SetTextColor(0.78, 0.89, 0.95)
    subtitle:SetText(T("DK: %s • Preset: %s • Valeera role is a recommendation, not an automatic change.", GetSpecName(specID), ValeeraData.presets[presetKey] and T(ValeeraData.presets[presetKey].label) or presetKey))
    y = y - 29

    local presetTitle = self:AcquireGearText(root, "GameFontNormalSmall")
    presetTitle:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    presetTitle:SetWidth(contentWidth)
    presetTitle:SetHeight(16)
    presetTitle:SetTextColor(0.92, 0.80, 0.45)
    presetTitle:SetText(T("Delve preset"))
    y = y - 21

    local presetGap = 6
    local presetOrder = ValeeraData.presetOrder or {}
    local presetWidth = math.floor((contentWidth - (presetGap * (#presetOrder - 1))) / #presetOrder)
    for index, key in ipairs(presetOrder) do
        local button = root.valeeraPresetButtons[index]
        button:ClearAllPoints()
        button:SetSize(presetWidth, 30)
        button:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + ((index - 1) * (presetWidth + presetGap)), y)
        StylePresetButton(button, key == presetKey)
    end
    y = y - 40

    y = AddSectionTitle(self, root, "Recommended Valeera setup", y, contentWidth)
    local summaryGap = 8
    local summaryWidth = math.floor((contentWidth - (summaryGap * 3)) / 4)
    local selectedRole = ValeeraData.roles[rec.role]
    local selectedCombat = ValeeraData.combatCurios[rec.combat]
    local selectedUtility = ValeeraData.utilityCurios[rec.utility]
    local selectedPoison = ValeeraData.poisons[rec.poison]
    local summary = {
        { data = selectedRole, kicker = "Role" },
        { data = selectedCombat, kicker = "Combat Curio" },
        { data = selectedUtility, kicker = "Utility Curio" },
        { data = selectedPoison, kicker = "Poison" },
    }
    for index, entry in ipairs(summary) do
        local card = AcquireValeeraCard(root)
        ConfigureValeeraCard(card, entry.data, summaryWidth, 104, entry.kicker, true)
        card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + ((index - 1) * (summaryWidth + summaryGap)), y)
    end
    y = y - 114

    local whyPanel = self:AcquireGearPanel(root)
    whyPanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    whyPanel:SetWidth(contentWidth)
    local whyTitle = self:AcquireGearPanelText(whyPanel, "GameFontNormal")
    whyTitle:SetPoint("TOPLEFT", whyPanel, "TOPLEFT", 10, -9)
    whyTitle:SetWidth(contentWidth - 20)
    whyTitle:SetHeight(18)
    whyTitle:SetTextColor(0.52, 0.90, 1.00)
    whyTitle:SetText(T("Why this pairing?"))
    local whyBody = self:AcquireGearPanelText(whyPanel, "GameFontHighlightSmall")
    whyBody:SetPoint("TOPLEFT", whyTitle, "BOTTOMLEFT", 0, -5)
    whyBody:SetWidth(contentWidth - 20)
    whyBody:SetWordWrap(true)
    whyBody:SetTextColor(0.90, 0.94, 0.97)
    whyBody:SetText(T(rec.reason or ""))
    whyBody:SetHeight(1)
    local whyHeight = math.max(66, math.ceil((whyBody.GetStringHeight and whyBody:GetStringHeight()) or 34) + 38)
    whyBody:SetHeight(whyHeight - 34)
    whyPanel:SetHeight(whyHeight)
    y = y - whyHeight - 10

    y = AddSectionTitle(self, root, "Valeera roles", y, contentWidth)
    local roleGap = 8
    local roleWidth = math.floor((contentWidth - (roleGap * 2)) / 3)
    for index, key in ipairs(ValeeraData.roleOrder or {}) do
        local data = ValeeraData.roles[key]
        local card = AcquireValeeraCard(root)
        ConfigureValeeraCard(card, data, roleWidth, 118, "Role", key == rec.role)
        card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + ((index - 1) * (roleWidth + roleGap)), y)
    end
    y = y - 128

    y = AddSectionTitle(self, root, "Combat Curios", y, contentWidth)
    local curioGap = 8
    local curioWidth = math.floor((contentWidth - (curioGap * 2)) / 3)
    for index, key in ipairs(ValeeraData.combatOrder or {}) do
        local data = ValeeraData.combatCurios[key]
        local card = AcquireValeeraCard(root)
        ConfigureValeeraCard(card, data, curioWidth, 112, "Combat Curio", key == rec.combat)
        card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + ((index - 1) * (curioWidth + curioGap)), y)
    end
    y = y - 122

    y = AddSectionTitle(self, root, "Utility Curios", y, contentWidth)
    for index, key in ipairs(ValeeraData.utilityOrder or {}) do
        local data = ValeeraData.utilityCurios[key]
        local card = AcquireValeeraCard(root)
        ConfigureValeeraCard(card, data, curioWidth, 112, "Utility Curio", key == rec.utility)
        card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + ((index - 1) * (curioWidth + curioGap)), y)
    end
    y = y - 122

    y = AddSectionTitle(self, root, "Valeera poisons", y, contentWidth)
    local poisonGap = 8
    local poisonWidth = math.floor((contentWidth - poisonGap) / 2)
    local poisonHeight = 102
    for index, key in ipairs(ValeeraData.poisonOrder or {}) do
        local data = ValeeraData.poisons[key]
        local col = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        local card = AcquireValeeraCard(root)
        ConfigureValeeraCard(card, data, poisonWidth, poisonHeight, "Poison", key == rec.poison)
        card:SetPoint("TOPLEFT", root, "TOPLEFT", 2 + (col * (poisonWidth + poisonGap)), y - (row * (poisonHeight + 8)))
    end
    y = y - (math.ceil(#(ValeeraData.poisonOrder or {}) / 2) * (poisonHeight + 8))

    y = AddSectionTitle(self, root, "Season 2 live fixes", y, contentWidth)
    local hotfixPanel = self:AcquireGearPanel(root)
    hotfixPanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    hotfixPanel:SetWidth(contentWidth)
    local hotfixBody = self:AcquireGearPanelText(hotfixPanel, "GameFontHighlightSmall")
    hotfixBody:SetPoint("TOPLEFT", hotfixPanel, "TOPLEFT", 10, -9)
    hotfixBody:SetWidth(contentWidth - 20)
    hotfixBody:SetWordWrap(true)
    hotfixBody:SetTextColor(0.82, 0.90, 0.94)
    local hotfixLines = {}
    for _, entry in ipairs(ValeeraData.liveHotfixes or {}) do
        hotfixLines[#hotfixLines + 1] = string.format("• %s — %s", T(entry.label or ""), T(entry.text or ""))
    end
    hotfixBody:SetText(table.concat(hotfixLines, "\n"))
    hotfixBody:SetHeight(1)
    local hotfixHeight = math.max(88, math.ceil((hotfixBody.GetStringHeight and hotfixBody:GetStringHeight()) or 54) + 22)
    hotfixBody:SetHeight(hotfixHeight - 18)
    hotfixPanel:SetHeight(hotfixHeight)
    y = y - hotfixHeight - 10

    local sourcePanel = self:AcquireGearPanel(root)
    sourcePanel:SetPoint("TOPLEFT", root, "TOPLEFT", 2, y)
    sourcePanel:SetWidth(contentWidth)
    local sourceTitle = self:AcquireGearPanelText(sourcePanel, "GameFontNormalSmall")
    sourceTitle:SetPoint("TOPLEFT", sourcePanel, "TOPLEFT", 10, -8)
    sourceTitle:SetWidth(contentWidth - 20)
    sourceTitle:SetHeight(16)
    sourceTitle:SetTextColor(0.72, 0.91, 0.80)
    sourceTitle:SetText(T("Data freshness"))
    local sourceBody = self:AcquireGearPanelText(sourcePanel, "GameFontHighlightSmall")
    sourceBody:SetPoint("TOPLEFT", sourceTitle, "BOTTOMLEFT", 0, -4)
    sourceBody:SetWidth(contentWidth - 20)
    sourceBody:SetWordWrap(true)
    sourceBody:SetTextColor(0.72, 0.82, 0.88)
    sourceBody:SetText(T("%s • Patch %s • reviewed %s\n%s", ValeeraData.sourceName or "Icy Veins + Wowhead", ValeeraData.patch or "12.1.0", ValeeraData.reviewed or "-", T(ValeeraData.sourceNote or "")))
    sourceBody:SetHeight(1)
    local sourceHeight = math.max(74, math.ceil((sourceBody.GetStringHeight and sourceBody:GetStringHeight()) or 42) + 34)
    sourceBody:SetHeight(sourceHeight - 30)
    sourcePanel:SetHeight(sourceHeight)
    y = y - sourceHeight - 10

    local totalHeight = math.max(1, math.abs(y) + 8)
    root:SetHeight(totalHeight)
    return totalHeight
end
