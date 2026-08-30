local ADDON_NAME, DKM = ...
local addon = DKM and DKM.Addon
local Data = (DKM and DKM.Data) or {}
local T = (DKM and DKM.T) or function(value, ...)
    if select("#", ...) > 0 then local ok, text = pcall(string.format, value, ...); if ok then return text end end
    return tostring(value or "")
end
if not addon then return end

local Tools = {}
DKM.DKTools = Tools

local DND_SPELL_ID = (Data.spells and Data.spells.DEATH_AND_DECAY) or 43265
local DND_DURATION = 10
local MELEE_SPELLS = { [250] = 206930, [251] = 49020, [252] = 85948 } -- Heart Strike / Obliterate / Festering Strike
local QUESTION_MARK_ICON = 134400
local groundFrame, meleeFrame
local dndEndsAt = 0
local updateElapsed = 0
local meleeOutSince = nil
local MELEE_WARNING_DELAY = 0.30

local function IsSecretValue(value)
    if not issecretvalue then return false end
    local ok, result = pcall(issecretvalue, value)
    return ok and result == true
end

local function AccessibleBoolean(value)
    if value == nil or IsSecretValue(value) or type(value) ~= "boolean" then return nil end
    if canaccessvalue then
        local ok, allowed = pcall(canaccessvalue, value)
        if ok and allowed == false then return nil end
    end
    return value == true
end

local function AccessibleNumber(value)
    if value == nil or IsSecretValue(value) or type(value) ~= "number" then return nil end
    if canaccessvalue then
        local ok, allowed = pcall(canaccessvalue, value)
        if ok and allowed == false then return nil end
    end
    return value
end

local function EnsureDB()
    _G.DKMentorDB = _G.DKMentorDB or {}
    local root = _G.DKMentorDB
    root.mentor = type(root.mentor) == "table" and root.mentor or {}
    local mentor = root.mentor
    mentor.tools = type(mentor.tools) == "table" and mentor.tools or {}
    local cfg = mentor.tools
    if cfg.groundTracker == nil then cfg.groundTracker = true end
    if cfg.meleeWarning == nil then cfg.meleeWarning = true end
    cfg.ground = type(cfg.ground) == "table" and cfg.ground or { point = "CENTER", relativePoint = "CENTER", x = 110, y = -85, scale = 1 }
    cfg.melee = type(cfg.melee) == "table" and cfg.melee or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 145, scale = 1 }
    return cfg
end

local function GetNow()
    if GetTime then local ok, value = pcall(GetTime); if ok and type(value) == "number" then return value end end
    return 0
end

local function GetSpellIcon(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and type(info) == "table" and not IsSecretValue(info) and AccessibleNumber(info.iconID) then return info.iconID end
    end
    return QUESTION_MARK_ICON
end

local function ApplyBackdrop(frame, alpha)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10, insets = {left=2,right=2,top=2,bottom=2} })
    frame:SetBackdropColor(0.015, 0.06, 0.08, alpha or 0.90)
    frame:SetBackdropBorderColor(0.20, 0.68, 0.86, 0.95)
end

local function CanMove()
    if InCombatLockdown then local ok, locked = pcall(InCombatLockdown); if ok and locked == true then return false end end
    local root = _G.DKMentorDB
    return root and root.hudLocked == false and addon.hudEditSessionActive == true
end

local function SavePosition(frame, key)
    if not frame or not CanMove() then return end
    local cfg = EnsureDB()[key]
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    cfg.point, cfg.relativePoint, cfg.x, cfg.y = point or "CENTER", relativePoint or point or "CENTER", tonumber(x) or 0, tonumber(y) or 0
end

local function RestorePosition(frame, key)
    local cfg = EnsureDB()[key]
    frame:ClearAllPoints()
    frame:SetPoint(cfg.point or "CENTER", UIParent, cfg.relativePoint or cfg.point or "CENTER", tonumber(cfg.x) or 0, tonumber(cfg.y) or 0)
    frame:SetScale(math.max(0.7, math.min(1.6, tonumber(cfg.scale) or 1)))
end

local function SetupDrag(frame, key)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if CanMove() then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition(self, key) end)
end

local function CreateGroundFrame()
    if groundFrame then return groundFrame end
    local f = CreateFrame("Frame", "DKMentorGroundTracker", UIParent, "BackdropTemplate")
    f:SetSize(54, 54); f:SetFrameStrata("HIGH"); f:SetClampedToScreen(true); ApplyBackdrop(f, 0.88); SetupDrag(f, "ground")
    f.icon = f:CreateTexture(nil, "ARTWORK"); f.icon:SetPoint("TOPLEFT", 5, -5); f.icon:SetPoint("BOTTOMRIGHT", -5, 5); f.icon:SetTexture(GetSpellIcon(DND_SPELL_ID)); f.icon:SetTexCoord(0.08,0.92,0.08,0.92)
    f.time = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); f.time:SetPoint("CENTER", 0, 0)
    f.charges = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.charges:SetPoint("BOTTOMRIGHT", -5, 5)
    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); f.label:SetPoint("TOP", f, "BOTTOM", 0, -2); f.label:SetText(T("Death and Decay"))
    RestorePosition(f, "ground"); f:Hide(); groundFrame=f; return f
end

local function CreateMeleeFrame()
    if meleeFrame then return meleeFrame end
    local f = CreateFrame("Frame", "DKMentorMeleeWarning", UIParent, "BackdropTemplate")
    f:SetSize(136, 22); f:SetFrameStrata("HIGH"); f:SetClampedToScreen(true); ApplyBackdrop(f, 0.58); SetupDrag(f, "melee")
    f:SetBackdropBorderColor(0.22, 0.50, 0.60, 0.72)
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.text:SetPoint("CENTER"); f.text:SetText(T("OUT OF RANGE")); f.text:SetTextColor(1, 0.78, 0.38)
    RestorePosition(f, "melee"); f:Hide(); meleeFrame=f; return f
end

local function UpdateEditState()
    local movable = CanMove()
    for _, f in ipairs({ groundFrame, meleeFrame }) do if f then f:EnableMouse(movable) end end
end

local function GetCharges()
    if not (C_Spell and C_Spell.GetSpellCharges) then return nil end
    local ok, info = pcall(C_Spell.GetSpellCharges, DND_SPELL_ID)
    if not ok or type(info) ~= "table" or IsSecretValue(info) then return nil end
    return AccessibleNumber(info.currentCharges)
end

local function UpdateGround()
    local cfg = EnsureDB()
    local f = CreateGroundFrame()
    UpdateEditState()
    if cfg.groundTracker == false then f:Hide(); return end
    local preview = addon.hudPreviewMode == true
    local remaining = math.max(0, dndEndsAt - GetNow())
    if not preview and remaining <= 0 then f:Hide(); return end
    f.time:SetText(preview and "10" or string.format("%.1f", remaining))
    local charges = GetCharges(); f.charges:SetText(charges and tostring(math.floor(charges + 0.5)) or "")
    f.label:SetShown(preview or CanMove())
    f:Show()
end

local function IsAttackableTarget()
    if UnitExists then local ok, exists = pcall(UnitExists, "target"); if not ok or exists ~= true then return false end end
    if UnitCanAttack then local ok, attackable = pcall(UnitCanAttack, "player", "target"); return ok and attackable == true end
    return false
end

local function IsPlayerInCombat()
    if addon.IsPlayerInCombat then return addon:IsPlayerInCombat() == true end
    if UnitAffectingCombat then local ok, value = pcall(UnitAffectingCombat, "player"); return ok and value == true end
    return false
end

local function UpdateMelee()
    local cfg = EnsureDB(); local f = CreateMeleeFrame(); UpdateEditState()
    if cfg.meleeWarning == false then meleeOutSince=nil; f:Hide(); return end
    if addon.hudPreviewMode == true then meleeOutSince=nil; f:Show(); return end
    if not IsPlayerInCombat() or not IsAttackableTarget() then meleeOutSince=nil; f:Hide(); return end
    local specID = addon.GetSpecInfo and select(1, addon:GetSpecInfo()) or nil
    local spellID = MELEE_SPELLS[specID]
    if not spellID or not (C_Spell and C_Spell.IsSpellInRange) then meleeOutSince=nil; f:Hide(); return end
    local ok, raw = pcall(C_Spell.IsSpellInRange, spellID, "target")
    if not ok or IsSecretValue(raw) then meleeOutSince=nil; f:Hide(); return end
    local inRange = AccessibleBoolean(raw)
    -- Fail open on nil/restricted values. A readable out-of-range state must
    -- persist briefly before the compact hint appears, which avoids noisy
    -- flicker while targets move across the melee boundary.
    if inRange == false then
        local now = GetNow()
        meleeOutSince = meleeOutSince or now
        f:SetShown((now - meleeOutSince) >= MELEE_WARNING_DELAY)
    else
        meleeOutSince = nil
        f:Hide()
    end
end

function Tools.SetGroundTrackerEnabled(enabled)
    EnsureDB().groundTracker = enabled == true; UpdateGround()
end
function Tools.SetMeleeWarningEnabled(enabled)
    EnsureDB().meleeWarning = enabled == true; UpdateMelee()
end
function Tools.GetConfig() return EnsureDB() end
function Tools.Preview()
    if addon.IsPlayerInCombat and addon:IsPlayerInCombat() then return false end
    local old = addon.hudPreviewMode; addon.hudPreviewMode = true; UpdateGround(); UpdateMelee()
    if C_Timer and C_Timer.After then C_Timer.After(4, function() addon.hudPreviewMode=old; UpdateGround(); UpdateMelee() end) end
    return true
end

local previousUpdateHints = addon.UpdateHUDMoveHints
function addon:UpdateHUDMoveHints(...)
    previousUpdateHints(self, ...)
    UpdateEditState(); UpdateGround(); UpdateMelee()
end

local previousHandleSlashCommand = addon.HandleSlashCommand
function addon:HandleSlashCommand(message)
    local text=tostring(message or ""); local command, rest=text:match("^(%S*)%s*(.-)$"); command=string.lower(command or ""); rest=string.lower((rest or ""):match("^%s*(.-)%s*$") or "")
    if command == "tools" then
        local cfg=EnsureDB()
        if rest == "dnd" then Tools.SetGroundTrackerEnabled(cfg.groundTracker == false)
        elseif rest == "range" or rest == "melee" then Tools.SetMeleeWarningEnabled(cfg.meleeWarning == false)
        elseif rest == "preview" then Tools.Preview()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0DK Mentor|r: " .. T("DK Tools — DnD: %s • Out of melee: %s", cfg.groundTracker ~= false and T("ON") or T("OFF"), cfg.meleeWarning ~= false and T("ON") or T("OFF")))
        end
        return
    end
    return previousHandleSlashCommand(self, message)
end

local events=CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_TARGET_CHANGED","PLAYER_SPECIALIZATION_CHANGED","UNIT_SPELLCAST_SUCCEEDED","SPELL_UPDATE_CHARGES"}) do pcall(events.RegisterEvent,events,event) end
events:SetScript("OnEvent",function(_,event,...)
    if event == "PLAYER_LOGIN" then EnsureDB(); CreateGroundFrame(); CreateMeleeFrame(); UpdateGround(); UpdateMelee(); return end
    if not addon.active then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" and type(spellID) == "number" and spellID == DND_SPELL_ID then dndEndsAt=GetNow()+DND_DURATION; UpdateGround() end
    else UpdateGround(); UpdateMelee() end
end)
events:SetScript("OnUpdate",function(_,elapsed)
    if not addon.active then return end
    updateElapsed=updateElapsed+(tonumber(elapsed) or 0)
    if updateElapsed >= 0.15 then updateElapsed=0; UpdateGround(); UpdateMelee() end
end)
