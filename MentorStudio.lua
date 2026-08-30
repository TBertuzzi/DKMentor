local ADDON_NAME, DKM = ...
local addon = DKM and DKM.Addon
local T = (DKM and DKM.T) or function(value, ...)
    if select("#", ...) > 0 then local ok,text=pcall(string.format,value,...); if ok then return text end end
    return tostring(value or "")
end
if not addon then return end

local Studio = {}
DKM.MentorStudio = Studio

local KINDS = { "defensive", "interrupt", "utility", "resource", "proc" }
local KIND_LABELS = { defensive="Defensive", interrupt="Interrupt", utility="Utility", resource="Resource", proc="Proc" }
local studioFrame, setupFrame
local selectedKind = "defensive"
local setupStep = 1
local setupPreviewToken = 0
local studioPreviewToken = 0
local studioPreviewInProgress = false
local studioTransitionInProgress = false
local setupTransitionInProgress = false
local studioReturnFrame
local setupReturnFrame
local previewNoticeFrame
local PREVIEW_SECONDS = 4

local COACH_LAYOUT_ORDER = { "compact", "medium", "large" }
local COACH_LAYOUT_LABELS = { compact = "Compact", medium = "Medium", large = "Large" }
local COACH_LAYOUTS = {
    -- Compact is intentionally dense: it keeps all three coaching lines while
    -- taking substantially less screen space than the original 3.0 HUD.
    compact = { frameHeight = 96, minWidth = 280, cardWidth = 102, cardHeight = 64, cardGap = 5, cardTop = 27, iconSize = 24, inner = 5, textWidth = 65, whenWidth = 92, backdropAlpha = 0.78 },
    medium  = { frameHeight = 108, minWidth = 330, cardWidth = 118, cardHeight = 72, cardGap = 7, cardTop = 29, iconSize = 28, inner = 6, textWidth = 76, whenWidth = 106, backdropAlpha = 0.84 },
    large   = { frameHeight = 128, minWidth = 400, cardWidth = 138, cardHeight = 88, cardGap = 8, cardTop = 32, iconSize = 34, inner = 7, textWidth = 90, whenWidth = 124, backdropAlpha = 0.90 },
}

local function NormalizeCoachLayout(value)
    value = string.lower(tostring(value or "compact"))
    if not COACH_LAYOUTS[value] then return "compact" end
    return value
end

local function CoachLayoutLabel(value)
    value = NormalizeCoachLayout(value)
    return T(COACH_LAYOUT_LABELS[value] or "Compact")
end

local function EnsureDB()
    _G.DKMentorDB = _G.DKMentorDB or {}
    local root=_G.DKMentorDB; root.mentor=type(root.mentor)=="table" and root.mentor or {}
    local mentor=root.mentor
    mentor.studio=type(mentor.studio)=="table" and mentor.studio or {}
    local cfg=mentor.studio
    cfg.scale=math.max(0.75,math.min(1.35,tonumber(cfg.scale) or 1))
    cfg.opacity=math.max(0.45,math.min(1,tonumber(cfg.opacity) or 1))
    cfg.layout=NormalizeCoachLayout(cfg.layout)
    cfg.kinds=type(cfg.kinds)=="table" and cfg.kinds or {}
    for _,kind in ipairs(KINDS) do
        cfg.kinds[kind]=type(cfg.kinds[kind])=="table" and cfg.kinds[kind] or {}
        if cfg.kinds[kind].pulse==nil then cfg.kinds[kind].pulse=(kind=="defensive" or kind=="interrupt") end
        if cfg.kinds[kind].sound==nil then cfg.kinds[kind].sound=false end
    end
    if mentor.pinNextAction == nil then mentor.pinNextAction = true end
    root.interruptAlert = type(root.interruptAlert) == "table" and root.interruptAlert or {}
    if root.interruptAlert.actionGlow == nil then root.interruptAlert.actionGlow = true end
    mentor.setupVersion=tonumber(mentor.setupVersion) or 0
    return mentor,cfg
end

local function ApplyBackdrop(frame,alpha)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    frame:SetBackdropColor(0.015,0.055,0.075,alpha or 0.98); frame:SetBackdropBorderColor(0.20,0.68,0.86,0.95)
end
local function Button(parent,label,w,callback)
    local b
    if DKM and DKM.CreateActionButton then
        b = DKM.CreateActionButton(parent, w or 120, 27, T(label))
    else
        b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        b:SetSize(w or 120, 27)
        b:SetText(T(label))
    end
    b:SetScript("OnClick",callback)
    return b
end
local function Print(msg) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0DK Mentor|r: "..tostring(msg or "")) end end

local function ShowModalParent(parent)
    if not parent or not parent.Show then return end
    if parent == setupFrame and Studio.RefreshSetup then Studio.RefreshSetup() end
    if parent == studioFrame and Studio.Refresh then Studio.Refresh() end
    parent:Show()
    if parent.Raise then parent:Raise() end
end

local function ResolveStudioParent(explicitParent)
    if explicitParent and explicitParent ~= studioFrame then return explicitParent end
    if setupFrame and setupFrame.IsShown and setupFrame:IsShown() then return setupFrame end
    local mentor = _G.DKMentorIntelligenceFrame
    if mentor and mentor.IsShown and mentor:IsShown() then return mentor end
    return nil
end

local function ResolveSetupParent(explicitParent)
    if explicitParent and explicitParent ~= setupFrame then return explicitParent end
    if studioFrame and studioFrame.IsShown and studioFrame:IsShown() then return studioFrame end
    local mentor = _G.DKMentorIntelligenceFrame
    if mentor and mentor.IsShown and mentor:IsShown() then return mentor end
    return nil
end

local function GetKindConfig(kind)
    local _,cfg=EnsureDB(); return cfg.kinds[kind or selectedKind]
end

local function PlayKindSound(kind)
    local kcfg=GetKindConfig(kind); if not kcfg or kcfg.sound~=true or not PlaySound then return end
    local soundID
    if SOUNDKIT then soundID = (kind=="interrupt" and SOUNDKIT.RAID_WARNING) or (kind=="defensive" and SOUNDKIT.ALARM_CLOCK_WARNING_3) or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON end
    if soundID then pcall(PlaySound,soundID,"Master") end
end

local function CountCoachCards(coach)
    local count = 0
    for _, card in ipairs((coach and coach.cards) or {}) do
        if card and card.spellID then count = count + 1 end
    end
    return math.max(1, math.min(3, count > 0 and count or 3))
end

function addon:ApplyMentorCoachLayout()
    local coach = _G.DKMentorCoachFrame
    if not coach or not coach.cards then return end
    local _, cfg = EnsureDB()
    local layoutKey = NormalizeCoachLayout(cfg.layout)
    local layout = COACH_LAYOUTS[layoutKey]
    local visibleCount = CountCoachCards(coach)
    local totalCardsWidth = (visibleCount * layout.cardWidth) + ((visibleCount - 1) * layout.cardGap)
    local frameWidth = math.max(layout.minWidth, totalCardsWidth + 14)
    local startX = math.floor((frameWidth - totalCardsWidth) / 2)

    coach:SetSize(frameWidth, layout.frameHeight)
    coach:SetScale(cfg.scale)
    coach:SetAlpha(cfg.opacity)
    if coach.SetBackdropColor then coach:SetBackdropColor(0.010, 0.040, 0.055, layout.backdropAlpha) end
    if coach.SetBackdropBorderColor then coach:SetBackdropBorderColor(0.12, 0.42, 0.56, 0.72) end

    if coach.title then
        coach.title:ClearAllPoints()
        coach.title:SetPoint("TOPLEFT", coach, "TOPLEFT", 8, -6)
        coach.title:SetWidth(math.max(120, frameWidth - 78))
        coach.title:SetJustifyH("LEFT")
        if coach.title.SetFontObject and GameFontNormalSmall then coach.title:SetFontObject(GameFontNormalSmall) end
    end
    if coach.dragHint then
        coach.dragHint:ClearAllPoints()
        coach.dragHint:SetPoint("TOPRIGHT", coach, "TOPRIGHT", -27, -6)
        coach.dragHint:SetWidth(44)
        coach.dragHint:SetJustifyH("RIGHT")
        if coach.dragHint.SetFontObject and GameFontDisableSmall then coach.dragHint:SetFontObject(GameFontDisableSmall) end
    end
    if coach.healthText then
        coach.healthText:ClearAllPoints()
        coach.healthText:SetPoint("TOPLEFT", coach, "TOPLEFT", 8, -18)
        coach.healthText:SetWidth(math.max(120, frameWidth - 38))
        coach.healthText:SetJustifyH("LEFT")
        if coach.healthText.SetFontObject and GameFontDisableSmall then coach.healthText:SetFontObject(GameFontDisableSmall) end
    end
    if coach.closeButton then
        coach.closeButton:SetSize(layoutKey == "compact" and 19 or 22, layoutKey == "compact" and 19 or 22)
        coach.closeButton:ClearAllPoints()
        coach.closeButton:SetPoint("TOPRIGHT", coach, "TOPRIGHT", -2, -2)
    end
    if coach.dragBar then
        coach.dragBar:ClearAllPoints()
        coach.dragBar:SetPoint("TOPLEFT", coach, "TOPLEFT", 4, -4)
        coach.dragBar:SetPoint("TOPRIGHT", coach, "TOPRIGHT", -28, -4)
        coach.dragBar:SetHeight(layout.cardTop - 5)
    end

    for index, card in ipairs(coach.cards) do
        card:SetSize(layout.cardWidth, layout.cardHeight)
        -- Do not call SetBackdrop here. Re-applying a WHITE8X8 backdrop after
        -- Core has styled the card resets its tint to opaque white in-game.
        -- The card backdrop is created once by Core; layout only moves/resizes it.
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", coach, "TOPLEFT", startX + ((index - 1) * (layout.cardWidth + layout.cardGap)), -layout.cardTop)

        card.icon:SetSize(layout.iconSize, layout.iconSize)
        card.icon:ClearAllPoints()
        card.icon:SetPoint("TOPLEFT", card, "TOPLEFT", layout.inner, -layout.inner)

        card.action:ClearAllPoints()
        card.action:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 4, 0)
        card.action:SetWidth(layout.textWidth)
        if card.action.SetFontObject and GameFontNormalSmall then card.action:SetFontObject(GameFontNormalSmall) end

        card.spell:ClearAllPoints()
        card.spell:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 4, -14)
        card.spell:SetWidth(layout.textWidth)
        card.spell:SetHeight(layoutKey == "compact" and 22 or (layoutKey == "medium" and 26 or 30))
        if card.spell.SetFontObject and GameFontHighlightSmall then card.spell:SetFontObject(GameFontHighlightSmall) end

        card.when:ClearAllPoints()
        card.when:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", layout.inner, layout.inner)
        card.when:SetWidth(layout.whenWidth)
        card.when:SetHeight(layoutKey == "compact" and 18 or (layoutKey == "medium" and 24 or 28))
        card.when:SetJustifyV("BOTTOM")
        if card.when.SetFontObject and GameFontDisableSmall then card.when:SetFontObject(GameFontDisableSmall) end
        card.when:SetTextColor(0.78, 0.86, 0.90)
    end
end

local function CycleCoachLayout()
    local _, cfg = EnsureDB()
    local current = NormalizeCoachLayout(cfg.layout)
    local index = 1
    for i, value in ipairs(COACH_LAYOUT_ORDER) do
        if value == current then index = i break end
    end
    cfg.layout = COACH_LAYOUT_ORDER[(index % #COACH_LAYOUT_ORDER) + 1]
    addon:ApplyMentorCoachLayout()
    Studio.Refresh()
end

local function Pulse(frame)
    if not frame or not frame.CreateAnimationGroup then return end
    if frame.mentorPulse and frame.mentorPulse:IsPlaying() then frame.mentorPulse:Stop() end
    if not frame.mentorPulse then
        local group=frame:CreateAnimationGroup()
        local a=group:CreateAnimation("Alpha"); a:SetFromAlpha(1); a:SetToAlpha(0.45); a:SetDuration(0.16); a:SetOrder(1)
        local b=group:CreateAnimation("Alpha"); b:SetFromAlpha(0.45); b:SetToAlpha(1); b:SetDuration(0.18); b:SetOrder(2)
        frame.mentorPulse=group
    end
    frame.mentorPulse:Play()
end

function addon:ApplyMentorCardStyle(card,entry)
    local _,cfg=EnsureDB(); local kind=(entry and entry.kind) or card.mentorKind or "defensive"; local kcfg=cfg.kinds[kind] or {}
    local coach=_G.DKMentorCoachFrame
    if coach then
        coach:SetScale(cfg.scale)
        coach:SetAlpha(cfg.opacity)
    end
    card:SetAlpha(cfg.opacity)
    local signature=tostring(kind)..":"..tostring(entry and entry.spellID or card.spellID or "")
    if card.mentorStyleSignature~=signature then
        card.mentorStyleSignature=signature
        if kcfg.pulse==true then Pulse(card) end
        PlayKindSound(kind)
    end
end

function addon:NotifyMentorKind(kind)
    local kcfg=GetKindConfig(kind); if not kcfg then return end
    if kcfg.sound then PlayKindSound(kind) end
    if kcfg.pulse then
        local frame = kind=="interrupt" and _G.DKMentorInterruptAlert or _G.DKMentorCoachFrame
        Pulse(frame)
    end
end

local SAMPLE = {
    defensive={spell=48792,title="DEFENSIVE",when="example: heavy incoming pressure"},
    interrupt={spell=47528,title="INTERRUPT",when="example: target cast is interruptible"},
    utility={spell=49576,title="UTILITY",when="example: DK control can stop the cast"},
    resource={spell=49998,title="RESOURCE",when="example: readable resource opportunity"},
    proc={spell=49020,title="PROC",when="example: high-value proc is active"},
}
local function SpellData(id)
    if C_Spell and C_Spell.GetSpellInfo then local ok,info=pcall(C_Spell.GetSpellInfo,id); if ok and type(info)=="table" then return info.name or T("Ability"),info.iconID end end
    return T("Ability"),134400
end

function Studio.PreviewKind(kind)
    kind=kind or selectedKind
    if addon.IsPlayerInCombat and addon:IsPlayerInCombat() then Print(T("Alert preview is available only out of combat.")); return false end
    local coach=_G.DKMentorCoachFrame; local sample=SAMPLE[kind] or SAMPLE.defensive
    if not coach or not coach.cards or not coach.cards[1] then return addon.ShowMentorAlertPreview and addon:ShowMentorAlertPreview() end
    local name,icon=SpellData(sample.spell); local card=coach.cards[1]
    coach.title:SetText(T("DK Mentor Studio — %s", T(KIND_LABELS[kind] or kind)))
    coach.healthText:SetText(T("Live alert preview"))
    for index,c in ipairs(coach.cards) do c:SetShown(index==1) end
    card.spellID=sample.spell; card.spellName=name; card.mentorKind=kind; card.icon:SetTexture(icon or 134400); card.action:SetText(T(sample.title)); card.spell:SetText(name); card.when:SetText(T(sample.when))
    addon:ApplyMentorCardStyle(card,{spellID=sample.spell,kind=kind})
    addon:ApplyMentorCoachLayout()
    coach:Show()
    addon:NotifyMentorKind(kind)
    if kind == "interrupt" and addon.UpdateInterruptActionGlows then
        addon:UpdateInterruptActionGlows(true, false, nil, true)
    end
    if C_Timer and C_Timer.After then C_Timer.After(PREVIEW_SECONDS,function()
        if addon.UpdateCoach then addon:UpdateCoach() end
        if addon.RefreshCoachVisibility then addon:RefreshCoachVisibility() end
        if kind == "interrupt" and addon.UpdateInterruptAlert then addon:UpdateInterruptAlert() end
    end) end
    return true
end

local function PreviewSelectedFromStudio()
    if not studioFrame then return Studio.PreviewKind(selectedKind) end
    studioPreviewToken = studioPreviewToken + 1
    local token = studioPreviewToken
    studioPreviewInProgress = true
    studioFrame:Hide()
    local ok = Studio.PreviewKind(selectedKind)
    if ok == false then
        studioPreviewInProgress = false
        studioFrame:Show()
        return false
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(PREVIEW_SECONDS + 0.25, function()
            if token ~= studioPreviewToken then return end
            studioPreviewInProgress = false
            if studioFrame then
                Studio.Refresh()
                studioFrame:Show()
                if studioFrame.Raise then studioFrame:Raise() end
            end
        end)
    else
        studioPreviewInProgress = false
        studioFrame:Show()
    end
    return true
end

local function CreateStudioFrame()
    if studioFrame then return studioFrame end
    local f=CreateFrame("Frame","DKMentorStudioFrame",UIParent,"BackdropTemplate"); f:SetSize(520,390); f:SetPoint("CENTER", UIParent, "CENTER", 0, 30); f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetFrameLevel(280); f:SetToplevel(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton"); ApplyBackdrop(f)
    f:SetScript("OnDragStart",function(self) if not(InCombatLockdown and InCombatLockdown()) then self:StartMoving() end end); f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge"); f.title:SetPoint("TOPLEFT",18,-17); f.title:SetText(T("DK Mentor Alert Studio")); f.title:SetTextColor(0.55,0.88,1)
    f.sub=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.sub:SetPoint("TOPLEFT",f.title,"BOTTOMLEFT",0,-5); f.sub:SetWidth(450); f.sub:SetJustifyH("LEFT"); f.sub:SetText(T("Tune alert emphasis without changing the combat logic."))
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-4,-4)
    f.kind=Button(f,"Kind",180,function() local pos=1; for i,k in ipairs(KINDS) do if k==selectedKind then pos=i break end end; selectedKind=KINDS[(pos%#KINDS)+1]; Studio.Refresh() end); f.kind:SetPoint("TOPLEFT",18,-77)
    f.pulse=Button(f,"Pulse",145,function() local c=GetKindConfig(); c.pulse=not c.pulse; Studio.Refresh() end); f.pulse:SetPoint("LEFT",f.kind,"RIGHT",10,0)
    f.sound=Button(f,"Sound",145,function() local c=GetKindConfig(); c.sound=not c.sound; Studio.Refresh() end); f.sound:SetPoint("LEFT",f.pulse,"RIGHT",10,0)
    f.scaleMinus=Button(f,"Scale -",110,function() local _,c=EnsureDB(); c.scale=math.max(0.75,c.scale-0.05); Studio.Refresh() end); f.scaleMinus:SetPoint("TOPLEFT",18,-119)
    f.scalePlus=Button(f,"Scale +",110,function() local _,c=EnsureDB(); c.scale=math.min(1.35,c.scale+0.05); Studio.Refresh() end); f.scalePlus:SetPoint("LEFT",f.scaleMinus,"RIGHT",8,0)
    f.opacityMinus=Button(f,"Opacity -",110,function() local _,c=EnsureDB(); c.opacity=math.max(0.45,c.opacity-0.05); Studio.Refresh() end); f.opacityMinus:SetPoint("LEFT",f.scalePlus,"RIGHT",18,0)
    f.opacityPlus=Button(f,"Opacity +",110,function() local _,c=EnsureDB(); c.opacity=math.min(1,c.opacity+0.05); Studio.Refresh() end); f.opacityPlus:SetPoint("LEFT",f.opacityMinus,"RIGHT",8,0)
    f.layout=Button(f,"Coach layout",160,function() CycleCoachLayout() end); f.layout:SetPoint("TOPLEFT",18,-159)
    f.nextAction=Button(f,"Next action",155,function() local mentor=EnsureDB(); mentor.pinNextAction=not(mentor.pinNextAction~=false); if addon.UpdateCoach then addon:UpdateCoach() end; Studio.Refresh() end); f.nextAction:SetPoint("LEFT",f.layout,"RIGHT",10,0)
    f.interruptGlow=Button(f,"Action glow",145,function()
        local root=_G.DKMentorDB or {}; root.interruptAlert=type(root.interruptAlert)=="table" and root.interruptAlert or {}; local enabled=root.interruptAlert.actionGlow~=false
        if addon.SetInterruptActionGlowEnabled then addon:SetInterruptActionGlowEnabled(not enabled) else root.interruptAlert.actionGlow=not enabled end
        Studio.Refresh()
    end); f.interruptGlow:SetPoint("LEFT",f.nextAction,"RIGHT",10,0)
    f.status=f:CreateFontString(nil,"OVERLAY","GameFontHighlight"); f.status:SetPoint("TOPLEFT",18,-202); f.status:SetWidth(480); f.status:SetJustifyH("LEFT")
    f.preview=Button(f,"Preview selected alert",190,function() PreviewSelectedFromStudio() end); f.preview:SetPoint("TOPLEFT",18,-258)
    f.setup=Button(f,"Setup Wizard",135,function()
        if studioReturnFrame == setupFrame and setupFrame then
            f:Hide()
        else
            Studio.OpenSetup(f)
        end
    end); f.setup:SetPoint("LEFT",f.preview,"RIGHT",10,0)
    f.review=Button(f,"Review",110,function()
        if DKM.MentorReview then
            studioTransitionInProgress = true
            DKM.MentorReview.Open("overview", f)
            studioTransitionInProgress = false
        end
    end); f.review:SetPoint("LEFT",f.setup,"RIGHT",10,0)
    f.note=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall"); f.note:SetPoint("TOPLEFT",18,-308); f.note:SetWidth(480); f.note:SetJustifyH("LEFT"); f.note:SetText(T("Sounds use one built-in Blizzard sound per alert kind and are OFF by default. The interrupt action-bar glow is independent from the Mind Freeze HUD and can be disabled at any time."))
    f:SetScript("OnHide", function()
        if studioPreviewInProgress or studioTransitionInProgress then return end
        local parent = studioReturnFrame
        studioReturnFrame = nil
        ShowModalParent(parent)
    end)
    f:Hide(); studioFrame=f; if UISpecialFrames then table.insert(UISpecialFrames,"DKMentorStudioFrame") end; return f
end

function Studio.Refresh()
    local f=CreateStudioFrame(); local mentor,cfg=EnsureDB(); local kcfg=cfg.kinds[selectedKind]
    f.kind:SetText(T("Alert: %s",T(KIND_LABELS[selectedKind] or selectedKind)))
    f.pulse:SetText(T("Pulse: %s",kcfg.pulse and T("ON") or T("OFF"))); f.sound:SetText(T("Sound: %s",kcfg.sound and T("ON") or T("OFF")))
    f.layout:SetText(T("Coach layout: %s", CoachLayoutLabel(cfg.layout)))
    if f.nextAction then f.nextAction:SetText(T(mentor.pinNextAction ~= false and "Next action: ON" or "Next action: OFF")) end
    if f.interruptGlow then
        local root=_G.DKMentorDB or {}; local interrupt=root.interruptAlert or {}
        f.interruptGlow:SetText(T(interrupt.actionGlow ~= false and "Action glow: ON" or "Action glow: OFF"))
    end
    f.status:SetText(T("Coach scale: %d%%   •   Opacity: %d%%\nCard 1 follows Blizzard Assisted Combat when Next action is enabled; DK Mentor still never casts or targets automatically.",math.floor(cfg.scale*100+0.5),math.floor(cfg.opacity*100+0.5)))
    addon:ApplyMentorCoachLayout()
end
function Studio.Open(parentFrame)
    local f=CreateStudioFrame()
    local parent = ResolveStudioParent(parentFrame)
    if parent and parent ~= f then
        studioReturnFrame = parent
        if parent.IsShown and parent:IsShown() then parent:Hide() end
    end
    Studio.Refresh()
    f:Show()
    if f.Raise then f:Raise() end
end

function Studio.OpenInterrupt(parentFrame)
    selectedKind = "interrupt"
    Studio.Open(parentFrame)
end

-- Setup Wizard ---------------------------------------------------------------
local SETUP_STEPS = 5
local SETUP_VERSION = 301
local OPTION_AREA_TOP = -172
local OPTION_ROW_GAP = 14
local OPTION_BUTTON_HEIGHT = 44
local CreateSetupFrame

local function RootDB()
    _G.DKMentorDB = _G.DKMentorDB or {}
    return _G.DKMentorDB
end

local function IsHUDLocked()
    local root = RootDB()
    return root.hudLocked ~= false
end

local function GetResourceVisibilityMode()
    local root = RootDB()
    local resource = type(root.resourceHUD) == "table" and root.resourceHUD or {}
    local mode = string.lower(tostring(resource.visibilityMode or "combat"))
    if mode ~= "always" and mode ~= "fade" and mode ~= "combat" then mode = "combat" end
    return mode
end

local function MentorModeLabel(mode)
    if mode == "essential" then return T("Essential") end
    if mode == "training" then return T("Training") end
    return T("Mentor")
end

local function ResourceModeLabel(mode)
    if mode == "always" then return T("Always") end
    if mode == "fade" then return T("Fade out of combat") end
    return T("Combat Only")
end

local function BoolLabel(value)
    return value and T("ON") or T("OFF")
end

local function ToggleLabel(label, enabled)
    local state = enabled and "|cff55ff88" .. BoolLabel(true) .. "|r" or "|cffaaaaaa" .. BoolLabel(false) .. "|r"
    return T("%s: %s", T(label), state)
end

local function SetMentorBool(key)
    local mentor=EnsureDB()
    mentor[key]=not(mentor[key]~=false)
    if addon.UpdateCoach then addon:UpdateCoach() end
end

local function SetOptionSelected(button, selected)
    button.selected = selected == true
    if DKM and DKM.SetActionButtonSelected then
        DKM.SetActionButtonSelected(button, button.selected)
    else
        if button.selected then
            if button.LockHighlight then button:LockHighlight() end
            button:SetAlpha(1)
        else
            if button.UnlockHighlight then button:UnlockHighlight() end
            button:SetAlpha(0.92)
        end
    end
end

local function ClearOptionLayout(button)
    button:ClearAllPoints()
    button:SetSize(1, OPTION_BUTTON_HEIGHT)
    button.action=nil
    button.autoAdvance=false
    button:SetShown(false)
    SetOptionSelected(button, false)
end

local function LayoutOptions(f, count, columns)
    columns = columns or count
    local innerWidth = 650
    local left = 20
    local gap = columns == 2 and 16 or 12
    local width = math.floor((innerWidth - ((columns - 1) * gap)) / columns)
    for index = 1, count do
        local button = f.options[index]
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        button:ClearAllPoints()
        button:SetSize(width, OPTION_BUTTON_HEIGHT)
        local fontString = button.GetFontString and button:GetFontString() or nil
        if fontString then
            fontString:SetWidth(math.max(40, width - 16))
            fontString:SetJustifyH("CENTER")
            if fontString.SetWordWrap then fontString:SetWordWrap(true) end
        end
        button:SetPoint("TOPLEFT", f, "TOPLEFT", left + (column * (width + gap)), OPTION_AREA_TOP - (row * (OPTION_BUTTON_HEIGHT + OPTION_ROW_GAP)))
        button:Show()
    end
end

local function AdvanceSetup()
    if setupStep < SETUP_STEPS then
        setupStep = setupStep + 1
        Studio.RefreshSetup()
    else
        Studio.FinishSetup()
    end
end

local function HidePreviewNotice()
    if previewNoticeFrame then previewNoticeFrame:Hide() end
end

local function ShowPreviewNotice(duration)
    if not previewNoticeFrame then
        local n = CreateFrame("Frame", "DKMentorSetupPreviewNotice", UIParent, "BackdropTemplate")
        n:SetSize(390, 34)
        n:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 120)
        n:SetFrameStrata("FULLSCREEN_DIALOG")
        n:SetFrameLevel(240)
        n:SetClampedToScreen(true)
        n:EnableMouse(false)
        ApplyBackdrop(n, 0.86)
        n.text = n:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        n.text:SetPoint("CENTER", n, "CENTER", 0, 0)
        n.text:SetWidth(365)
        n.text:SetJustifyH("CENTER")
        previewNoticeFrame = n
    end
    previewNoticeFrame.text:SetText(T("Preview active — setup returns automatically in %d seconds.", math.floor((duration or PREVIEW_SECONDS) + 0.5)))
    previewNoticeFrame:Show()
end

local function RunPreviewOutsideWizard(callback, duration)
    if not callback then return end
    local f = CreateSetupFrame()
    setupPreviewToken = setupPreviewToken + 1
    local token = setupPreviewToken
    local seconds = duration or PREVIEW_SECONDS
    setupTransitionInProgress = true
    f:Hide()
    setupTransitionInProgress = false
    ShowPreviewNotice(seconds)
    local ok = callback()
    if ok == false then
        HidePreviewNotice()
        Studio.RefreshSetup()
        f:Show()
        return
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(seconds + 0.25, function()
            if token ~= setupPreviewToken then return end
            HidePreviewNotice()
            if setupFrame and not (studioFrame and studioFrame:IsShown()) then
                Studio.RefreshSetup()
                setupFrame:Show()
                if setupFrame.Raise then setupFrame:Raise() end
            end
        end)
    else
        HidePreviewNotice()
        Studio.RefreshSetup()
        f:Show()
    end
end

local function OpenStudioFromSetup()
    local f = CreateSetupFrame()
    setupTransitionInProgress = true
    Studio.Open(f)
    setupTransitionInProgress = false
end

CreateSetupFrame = function()
    if setupFrame then return setupFrame end
    local f=CreateFrame("Frame","DKMentorSetupWizard",UIParent,"BackdropTemplate")
    f:SetSize(690,470)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(200)
    f:SetClampedToScreen(true)
    f:SetToplevel(true)
    f:EnableMouse(true)
    ApplyBackdrop(f)

    f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    f.title:SetPoint("TOPLEFT",20,-18)
    f.title:SetText(T("DK Mentor 3.0 Setup"))
    f.title:SetTextColor(0.55,0.88,1)

    f.step=f:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    f.step:SetPoint("TOPRIGHT",-48,-24)

    f.close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT",-5,-5)
    f.close:SetScript("OnClick", function()
        setupPreviewToken=setupPreviewToken+1
        HidePreviewNotice()
        f:Hide()
    end)

    f.body=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f.body:SetPoint("TOPLEFT",20,-68)
    f.body:SetWidth(650)
    f.body:SetHeight(70)
    f.body:SetJustifyH("LEFT")
    f.body:SetJustifyV("TOP")

    f.current=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    f.current:SetPoint("TOPLEFT",20,-137)
    f.current:SetWidth(650)
    f.current:SetJustifyH("LEFT")
    f.current:SetTextColor(0.45,0.86,1)

    f.options={}
    for i=1,4 do
        local b=Button(f,"Option",200,function(self)
            if self.action then self.action() end
            if self.autoAdvance then
                AdvanceSetup()
            else
                Studio.RefreshSetup()
            end
        end)
        b:SetHeight(OPTION_BUTTON_HEIGHT)
        f.options[i]=b
    end

    f.footerHint=f:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
    f.footerHint:SetPoint("BOTTOM",0,28)
    f.footerHint:SetWidth(380)
    f.footerHint:SetJustifyH("CENTER")

    f.back=Button(f,"Back",115,function()
        setupPreviewToken=setupPreviewToken+1
        setupStep=math.max(1,setupStep-1)
        Studio.RefreshSetup()
    end)
    f.back:SetPoint("BOTTOMLEFT",20,18)

    f.next=Button(f,"Next",115,function() AdvanceSetup() end)
    f.next:SetPoint("BOTTOMRIGHT",-20,18)

    f:SetScript("OnHide", function()
        if setupTransitionInProgress then return end
        local parent = setupReturnFrame
        setupReturnFrame = nil
        ShowModalParent(parent)
    end)

    f:Hide()
    setupFrame=f
    if UISpecialFrames then table.insert(UISpecialFrames,"DKMentorSetupWizard") end
    return f
end

local function ConfigureOption(button,label,action,shown,selected,autoAdvance)
    button:SetText(T(label))
    button.action=action
    button.autoAdvance=autoAdvance == true
    button:SetShown(shown~=false)
    SetOptionSelected(button, selected)
end

function Studio.RefreshSetup()
    local f=CreateSetupFrame()
    local mentor=EnsureDB()
    local tools=DKM.DKTools and DKM.DKTools.GetConfig and DKM.DKTools.GetConfig() or {}
    local resourceMode=GetResourceVisibilityMode()

    f.step:SetText(T("Step %d / 5",setupStep))
    for _,b in ipairs(f.options) do ClearOptionLayout(b) end

    if setupStep==1 then
        f.body:SetText(T("Coach level\nChoose how much live guidance you want. You can change this at any time."))
        f.current:SetText(T("Current selection: %s", MentorModeLabel(mentor.mode)))
        LayoutOptions(f,3,3)
        ConfigureOption(f.options[1],"Essential",function() mentor.mode="essential" end,true,mentor.mode=="essential",true)
        ConfigureOption(f.options[2],"Mentor",function() mentor.mode="mentor" end,true,mentor.mode==nil or mentor.mode=="mentor",true)
        ConfigureOption(f.options[3],"Training",function() mentor.mode="training" end,true,mentor.mode=="training",true)
        f.footerHint:SetText(T("Choose an option to continue automatically."))
        f.next:Hide()
    elseif setupStep==2 then
        f.body:SetText(T("Resource HUD visibility\nChoose whether DK resources stay visible, fade outside combat, or appear only in combat."))
        f.current:SetText(T("Current selection: %s", ResourceModeLabel(resourceMode)))
        LayoutOptions(f,3,3)
        ConfigureOption(f.options[1],"Always",function() if addon.SetResourceVisibilityMode then addon:SetResourceVisibilityMode("always") end end,true,resourceMode=="always",true)
        ConfigureOption(f.options[2],"Fade out of combat",function() if addon.SetResourceVisibilityMode then addon:SetResourceVisibilityMode("fade") end end,true,resourceMode=="fade",true)
        ConfigureOption(f.options[3],"Combat Only",function() if addon.SetResourceVisibilityMode then addon:SetResourceVisibilityMode("combat") end end,true,resourceMode=="combat",true)
        f.footerHint:SetText(T("Choose an option to continue automatically."))
        f.next:Hide()
    elseif setupStep==3 then
        f.body:SetText(T("Live Mentor modules\nToggle the categories you want the coach to surface during combat."))
        f.current:SetText(T("Toggle any modules, then continue."))
        LayoutOptions(f,4,2)
        ConfigureOption(f.options[1],ToggleLabel("Defensive",mentor.defensive~=false),function() SetMentorBool("defensive") end,true,mentor.defensive~=false,false)
        ConfigureOption(f.options[2],ToggleLabel("Utility",mentor.utility~=false),function() SetMentorBool("utility") end,true,mentor.utility~=false,false)
        ConfigureOption(f.options[3],ToggleLabel("Resources",mentor.resourceWarnings~=false),function() SetMentorBool("resourceWarnings") end,true,mentor.resourceWarnings~=false,false)
        ConfigureOption(f.options[4],ToggleLabel("Procs",mentor.procWarnings~=false),function() SetMentorBool("procWarnings") end,true,mentor.procWarnings~=false,false)
        f.footerHint:SetText(T("Changes are saved immediately."))
        f.next:Show()
    elseif setupStep==4 then
        f.body:SetText(T("Review and DK Tools\nKeep post-combat learning and the small DK-specific utility helpers you want."))
        f.current:SetText(T("Toggle any modules, then continue."))
        LayoutOptions(f,4,2)
        ConfigureOption(f.options[1],ToggleLabel("Review",mentor.reviewEnabled~=false),function() mentor.reviewEnabled=not(mentor.reviewEnabled~=false) end,true,mentor.reviewEnabled~=false,false)
        ConfigureOption(f.options[2],ToggleLabel("Post-combat popup",mentor.postCombat~=false),function() mentor.postCombat=not(mentor.postCombat~=false) end,true,mentor.postCombat~=false,false)
        ConfigureOption(f.options[3],ToggleLabel("D&D tracker",tools.groundTracker~=false),function() if DKM.DKTools then DKM.DKTools.SetGroundTrackerEnabled(tools.groundTracker==false) end end,true,tools.groundTracker~=false,false)
        ConfigureOption(f.options[4],ToggleLabel("Melee range",tools.meleeWarning~=false),function() if DKM.DKTools then DKM.DKTools.SetMeleeWarningEnabled(tools.meleeWarning==false) end end,true,tools.meleeWarning~=false,false)
        f.footerHint:SetText(T("Changes are saved immediately."))
        f.next:Show()
    else
        f.body:SetText(T("Position and preview\nTest the new alerts and tools, unlock HUD movement if needed, then finish. Previews temporarily hide this window so the HUD can be inspected clearly."))
        f.current:SetText(T("HUD movement: %s", IsHUDLocked() and T("LOCKED") or T("UNLOCKED")))
        LayoutOptions(f,4,2)
        ConfigureOption(f.options[1],"Test alerts",function()
            RunPreviewOutsideWizard(function()
                if addon.ShowMentorAlertPreview then return addon:ShowMentorAlertPreview() end
                return Studio.PreviewKind(selectedKind)
            end,PREVIEW_SECONDS)
        end,true,false,false)
        ConfigureOption(f.options[2],"Preview DK Tools",function()
            RunPreviewOutsideWizard(function() if DKM.DKTools then return DKM.DKTools.Preview() end return false end,PREVIEW_SECONDS)
        end,true,false,false)
        ConfigureOption(f.options[3],IsHUDLocked() and "Unlock HUDs" or "Lock HUDs",function()
            if addon.SetHUDsLocked then addon:SetHUDsLocked(not IsHUDLocked()) end
        end,true,not IsHUDLocked(),false)
        ConfigureOption(f.options[4],"Alert Studio",function() OpenStudioFromSetup() end,true,false,false)
        f.footerHint:SetText(T("Previews briefly hide the wizard; a return notice stays visible."))
        f.next:Show()
    end

    f.back:SetEnabled(setupStep>1)
    if DKM and DKM.StyleActionButton then DKM.StyleActionButton(f.back) end
    f.next:SetText(T(setupStep==5 and "Finish" or "Next"))
end

function Studio.OpenSetup(parentFrame)
    setupPreviewToken=setupPreviewToken+1
    HidePreviewNotice()
    local f=CreateSetupFrame()
    local parent = ResolveSetupParent(parentFrame)
    -- When Studio was opened from Setup, this button behaves as Back and
    -- preserves the wizard step instead of restarting at step 1.
    if parent == studioFrame and studioReturnFrame == setupFrame and setupFrame then
        studioFrame:Hide()
        return
    end
    setupStep=1
    if parent and parent ~= f then
        setupReturnFrame = parent
        if parent == studioFrame then studioTransitionInProgress = true end
        if parent.IsShown and parent:IsShown() then parent:Hide() end
        if parent == studioFrame then studioTransitionInProgress = false end
    end
    Studio.RefreshSetup()
    f:Show()
    if f.Raise then f:Raise() end
end

function Studio.FinishSetup()
    setupPreviewToken=setupPreviewToken+1
    HidePreviewNotice()
    local mentor=EnsureDB()
    mentor.setupVersion=SETUP_VERSION
    if setupFrame then setupFrame:Hide() end
    if addon.UpdateCoach then addon:UpdateCoach() end
    Print(T("DK Mentor 3.0 setup complete."))
end

local previousHandleSlashCommand=addon.HandleSlashCommand
function addon:HandleSlashCommand(message)
    local text=tostring(message or ""); local command=text:match("^(%S*)") or ""; command=string.lower(command)
    if command=="studio" then Studio.Open(); return elseif command=="setup" then Studio.OpenSetup(); return end
    return previousHandleSlashCommand(self,message)
end

local login=CreateFrame("Frame"); pcall(login.RegisterEvent,login,"PLAYER_LOGIN"); login:SetScript("OnEvent",function()
    local mentor=EnsureDB(); Studio.Refresh()
    if mentor.setupVersion < SETUP_VERSION and C_Timer and C_Timer.After then C_Timer.After(2,function() if not(InCombatLockdown and InCombatLockdown()) then Studio.OpenSetup() end end) end
end)
