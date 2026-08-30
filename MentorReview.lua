local ADDON_NAME, DKM = ...

local addon = DKM and DKM.Addon
local T = (DKM and DKM.T) or function(value, ...)
    if select("#", ...) > 0 then
        local ok, text = pcall(string.format, value, ...)
        if ok then return text end
    end
    return tostring(value or "")
end
if not addon then return end

local Review = {}
DKM.MentorReview = Review

local HISTORY_LIMIT = 10
local reviewFrame
local reviewReturnFrame
local selectedIndex = 1
local selectedTab = "overview"

local function Print(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0DK Mentor|r: " .. tostring(message or ""))
    end
end

local function GetVisibleReviewParent(explicitParent)
    if explicitParent and explicitParent ~= reviewFrame then return explicitParent end
    local studio = _G.DKMentorStudioFrame
    if studio and studio.IsShown and studio:IsShown() then return studio end
    local mentor = _G.DKMentorIntelligenceFrame
    if mentor and mentor.IsShown and mentor:IsShown() then return mentor end
    return nil
end

local function RestoreReviewParent()
    local parent = reviewReturnFrame
    reviewReturnFrame = nil
    if not parent or not parent.Show then return end
    if parent == _G.DKMentorStudioFrame and DKM.MentorStudio and DKM.MentorStudio.Refresh then
        DKM.MentorStudio.Refresh()
    end
    parent:Show()
    if parent.Raise then parent:Raise() end
end

local function EnsureDB()
    _G.DKMentorDB = _G.DKMentorDB or {}
    local root = _G.DKMentorDB
    root.mentor = type(root.mentor) == "table" and root.mentor or {}
    local cfg = root.mentor
    cfg.historyLimit = math.max(1, math.min(20, tonumber(cfg.historyLimit) or HISTORY_LIMIT))
    cfg.history = type(cfg.history) == "table" and cfg.history or {}
    cfg.reviewEnabled = cfg.reviewEnabled ~= false
    return cfg
end

local function CopyValue(value, depth)
    depth = (depth or 0) + 1
    if depth > 6 then return nil end
    local valueType = type(value)
    if valueType == "number" or valueType == "string" or valueType == "boolean" then return value end
    if valueType ~= "table" then return nil end
    local out = {}
    for key, child in pairs(value) do
        local safeKey = type(key) == "number" or type(key) == "string"
        if safeKey then
            local copied = CopyValue(child, depth)
            if copied ~= nil then out[key] = copied end
        end
    end
    return out
end

local function GetSpecLabel(report)
    local specID = report and tonumber(report.specID)
    if addon.GetRuntimeSpecLabel then return addon:GetRuntimeSpecLabel(specID, tostring(specID or "?")) end
    local names = DKM.Data and DKM.Data.specNames
    return T((names and names[specID]) or tostring(specID or "?"))
end

local function GetContextLabel(report)
    local key = report and report.context or "world"
    if addon.GetRuntimeContextLabel then return addon:GetRuntimeContextLabel(key) end
    local names = DKM.Data and DKM.Data.contextNames
    return T((names and names[key]) or tostring(key))
end

local function ConfidenceLabel(value)
    value = tostring(value or "OBSERVATION")
    if value == "HIGH" then return T("HIGH") end
    if value == "MEDIUM" then return T("MEDIUM") end
    return T("OBSERVATION")
end

local function ObservationText(observation)
    if type(observation) == "string" then return observation end
    if type(observation) ~= "table" then return "" end
    local prefix = "[" .. ConfidenceLabel(observation.confidence) .. "] "
    return prefix .. tostring(observation.text or observation.key or "")
end

function Review.Record(report)
    if type(report) ~= "table" then return false end
    local cfg = EnsureDB()
    if cfg.reviewEnabled == false then return false end
    local copy = CopyValue(report) or {}
    copy.recordedAt = time and time() or nil
    table.insert(cfg.history, 1, copy)
    while #cfg.history > (cfg.historyLimit or HISTORY_LIMIT) do table.remove(cfg.history) end
    selectedIndex = 1
    return true
end

function Review.Clear()
    local cfg = EnsureDB()
    cfg.history = {}
    selectedIndex = 1
    if reviewFrame and reviewFrame:IsShown() then Review.Refresh() end
    Print(T("DK Mentor Review history cleared."))
end

function Review.GetHistory()
    return EnsureDB().history
end

function Review.GetPatterns(history)
    history = history or EnsureDB().history
    local patterns = {}
    local totalScore, scoreCount = 0, 0
    for _, report in ipairs(history) do
        if type(report.score) == "number" then totalScore = totalScore + report.score; scoreCount = scoreCount + 1 end
        for _, observation in ipairs(report.observations or {}) do
            if type(observation) == "table" and observation.key and observation.key ~= "clean" then
                local key = tostring(observation.key)
                local row = patterns[key]
                if not row then
                    row = { key = key, count = 0, severity = 0, confidence = observation.confidence, text = observation.text }
                    patterns[key] = row
                end
                row.count = row.count + 1
                row.severity = math.max(row.severity or 0, tonumber(observation.severity) or 0)
                if not row.text or row.text == "" then row.text = observation.text end
            end
        end
    end
    local list = {}
    for _, row in pairs(patterns) do list[#list + 1] = row end
    table.sort(list, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        if a.severity ~= b.severity then return a.severity > b.severity end
        return a.key < b.key
    end)
    return {
        encounters = #history,
        averageScore = scoreCount > 0 and math.floor((totalScore / scoreCount) + 0.5) or nil,
        items = list,
    }
end

local function FormatComponents(report)
    local c = report.components or {}
    local function one(label, value)
        return value ~= nil and T("%s %d", label, value) or T("%s N/A", label)
    end
    return table.concat({
        one(T("Resources"), c.resources),
        one(T("Procs"), c.procs),
        one(T("Defensives"), c.survival),
        one(T("Interrupts"), c.interrupts),
    }, "   •   ")
end

function Review.BuildOverview(report)
    if not report then return T("No reviewed encounter yet. Finish a combat of at least 5 seconds.") end
    local lines = {
        T("Score: %d/100", report.score or 0),
        T("%s • %s • %ds", GetSpecLabel(report), GetContextLabel(report), report.duration or 0),
        FormatComponents(report),
        "",
        T("What went well"),
    }
    if report.strengths and #report.strengths > 0 then
        for _, strength in ipairs(report.strengths) do lines[#lines + 1] = "• " .. tostring(strength) end
    else
        lines[#lines + 1] = T("• No strong positive signal was confidently measurable in this encounter.")
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = T("Key observations")
    for _, observation in ipairs(report.observations or {}) do
        lines[#lines + 1] = "• " .. ObservationText(observation)
    end
    if report.specID == 250 then
        lines[#lines + 1] = ""
        if report.averageDeathStrikePool then
            lines[#lines + 1] = T("Death Strike readable pool: average %d%% • maximum %d%% • %d cast(s)", report.averageDeathStrikePool, report.maxDeathStrikePool or 0, report.deathStrikeCasts or 0)
        else
            lines[#lines + 1] = T("Death Strike pool was unavailable or restricted during this encounter; no estimate was invented.")
        end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = T("Confidence matters: HIGH findings use directly readable state; MEDIUM findings can depend on group context; OBSERVATION items do not automatically mean a mistake.")
    return table.concat(lines, "\n")
end

function Review.BuildTimeline(report)
    if not report then return T("No timeline recorded yet.") end
    local timeline = report.timeline or {}
    if #timeline == 0 then return T("No timeline events were recorded for this encounter.") end
    local lines = { T("Combat timeline — %d event(s)", #timeline), "" }
    for index, event in ipairs(timeline) do
        if index > 45 then
            lines[#lines + 1] = T("… %d more event(s)", #timeline - 45)
            break
        end
        lines[#lines + 1] = string.format("%5.1fs  [%s]  %s", tonumber(event.t) or 0, ConfidenceLabel(event.confidence), tostring(event.text or event.kind or ""))
    end
    return table.concat(lines, "\n")
end

function Review.BuildPatterns(history)
    local result = Review.GetPatterns(history)
    if result.encounters == 0 then return T("No history yet. Patterns appear after reviewed encounters.") end
    local lines = {
        T("Patterns across the last %d encounter(s)", result.encounters),
        result.averageScore and T("Average DK Mentor Score: %d/100", result.averageScore) or T("Average DK Mentor Score: N/A"),
        "",
        T("What keeps coming back"),
    }
    if #result.items == 0 then
        lines[#lines + 1] = T("No recurring issue was detected in the readable data.")
    else
        for index, item in ipairs(result.items) do
            if index > 10 then break end
            lines[#lines + 1] = T("%d. %s — %d/%d encounter(s) • %s", index, tostring(item.text or item.key), item.count, result.encounters, ConfidenceLabel(item.confidence))
        end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = T("Patterns are coaching signals, not DPS rankings. DK Mentor never penalizes data the Midnight API did not expose.")
    return table.concat(lines, "\n")
end

local function ApplyBackdrop(frame, alpha)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.015, 0.055, 0.075, alpha or 0.97)
    frame:SetBackdropBorderColor(0.20, 0.68, 0.86, 0.95)
end

local function MakeButton(parent, text, width, callback)
    local b
    if DKM and DKM.CreateActionButton then
        b = DKM.CreateActionButton(parent, width or 110, 26, T(text))
    else
        b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        b:SetSize(width or 110, 26)
        b:SetText(T(text))
    end
    b:SetScript("OnClick", callback)
    return b
end

local function CreateFrameUI()
    if reviewFrame then return reviewFrame end
    local frame = CreateFrame("Frame", "DKMentorReviewFrame", UIParent, "BackdropTemplate")
    frame:SetSize(790, 575)
    frame:SetPoint("CENTER", UIParent, "CENTER", 20, 20)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(300)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not (InCombatLockdown and InCombatLockdown()) then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    ApplyBackdrop(frame, 0.985)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", 18, -17)
    frame.title:SetText(T("DK Mentor Review 3.0"))
    frame.title:SetTextColor(0.55, 0.88, 1)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
    frame.subtitle:SetText(T("Overview | Timeline | Patterns: learn from one fight, then from repeated habits."))

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    frame.prev = MakeButton(frame, "Previous", 90, function() selectedIndex = math.min(#EnsureDB().history, selectedIndex + 1); Review.Refresh() end)
    frame.prev:SetPoint("TOPLEFT", 18, -66)
    frame.next = MakeButton(frame, "Next", 90, function() selectedIndex = math.max(1, selectedIndex - 1); Review.Refresh() end)
    frame.next:SetPoint("LEFT", frame.prev, "RIGHT", 7, 0)
    frame.counter = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.counter:SetPoint("LEFT", frame.next, "RIGHT", 12, 0)

    frame.tabs = {}
    for index, tab in ipairs({ {"overview", "Overview"}, {"timeline", "Timeline"}, {"patterns", "Patterns"} }) do
        local key, label = tab[1], tab[2]
        local b = MakeButton(frame, label, 120, function() selectedTab = key; Review.Refresh() end)
        b:SetPoint("TOPLEFT", 18 + ((index - 1) * 128), -104)
        frame.tabs[key] = b
    end
    frame.clear = MakeButton(frame, "Clear history", 120, function() Review.Clear() end)
    frame.clear:SetPoint("TOPRIGHT", -18, -104)

    frame.body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.body:SetPoint("TOPLEFT", 20, -145)
    frame.body:SetPoint("BOTTOMRIGHT", -20, 20)
    frame.body:SetJustifyH("LEFT")
    frame.body:SetJustifyV("TOP")
    frame.body:SetSpacing(2)

    frame:SetScript("OnHide", function()
        RestoreReviewParent()
    end)

    frame:Hide()
    reviewFrame = frame
    if UISpecialFrames then table.insert(UISpecialFrames, "DKMentorReviewFrame") end
    return frame
end

function Review.Refresh()
    local frame = CreateFrameUI()
    local history = EnsureDB().history
    if #history == 0 then selectedIndex = 1 else selectedIndex = math.max(1, math.min(selectedIndex, #history)) end
    local report = history[selectedIndex]
    frame.counter:SetText(#history > 0 and T("Encounter %d / %d", selectedIndex, #history) or T("No encounters"))
    for key, button in pairs(frame.tabs) do
        button:SetEnabled(true)
        if DKM and DKM.SetActionButtonSelected then DKM.SetActionButtonSelected(button, key == selectedTab) end
    end
    if selectedTab == "timeline" then
        frame.body:SetText(Review.BuildTimeline(report))
    elseif selectedTab == "patterns" then
        frame.body:SetText(Review.BuildPatterns(history))
    else
        frame.body:SetText(Review.BuildOverview(report))
    end
end

function Review.Open(tab, parentFrame)
    EnsureDB()
    if tab == "overview" or tab == "timeline" or tab == "patterns" then selectedTab = tab end
    local frame = CreateFrameUI()
    local parent = GetVisibleReviewParent(parentFrame)
    if parent and parent ~= frame then
        reviewReturnFrame = parent
        if parent.IsShown and parent:IsShown() then parent:Hide() end
    end
    Review.Refresh()
    frame:Show()
    if frame.Raise then frame:Raise() end
end

local previousHandleSlashCommand = addon.HandleSlashCommand
function addon:HandleSlashCommand(message)
    local text = tostring(message or "")
    local command, rest = text:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    rest = string.lower((rest or ""):match("^%s*(.-)%s*$") or "")
    if command == "review" then
        if rest == "clear" then Review.Clear()
        elseif rest == "timeline" then Review.Open("timeline")
        elseif rest == "patterns" then Review.Open("patterns")
        else Review.Open("overview") end
        return
    elseif command == "patterns" then
        Review.Open("patterns")
        return
    end
    return previousHandleSlashCommand(self, message)
end
