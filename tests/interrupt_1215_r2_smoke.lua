-- Regression coverage for DK Mentor 3.3.4 Test r2 interrupt visibility on Retail 12.1.5.
local function read(path)
    local f = assert(io.open(path, "r"))
    local text = f:read("*a")
    f:close()
    return text
end

local core = read("Core.lua")
local engine = read("MentorEngine.lua")

local coreRequired = {
    'local interruptEventTargetScoped = {}',
    'interruptEventTargetScoped[eventName] = registered == true',
    'local isTargetEvent = interruptEventTargetScoped[event] == true',
    'if targetInterruptEventState == true then',
    'elseif targetInterruptEventState == false then',
    'SetInterruptFrameFullyVisible(interruptFrame)',
    'local presentationBound = SetInterruptFrameFromNotInterruptible(interruptFrame, rawNotInterruptible)',
    'if targetInterruptEventState == true then\n                    glow:SetAlpha(1)',
}
for _, snippet in ipairs(coreRequired) do
    assert(core:find(snippet, 1, true), "3.3.4 r2 Core interrupt regression missing: " .. snippet)
end

local engineRequired = {
    'local interruptEventTargetScoped = {}',
    'interruptEventTargetScoped[eventName] = registered == true',
    'elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then',
    'local isTargetEvent = interruptEventTargetScoped[event] == true',
    'local hasCast, _, castKey, spellID = GetTargetCastStateFromAPI()',
    'local key = hasCast and castKey or ("target:" .. tostring(IsAccessibleNumber(spellID) and spellID or GetNow()))',
    'OpenInterruptWindow(key)',
    'OpenUtilityWindow(key)',
}
for _, snippet in ipairs(engineRequired) do
    assert(engine:find(snippet, 1, true), "3.3.4 r2 MentorEngine interrupt regression missing: " .. snippet)
end

-- Midnight's interruptibility events should no longer depend on castGUID/spellID
-- being present in the event payload.
local eventBlockStart = assert(engine:find('elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then', 1, true))
local eventBlockEnd = assert(engine:find('elseif event == "UNIT_SPELLCAST_START"', eventBlockStart, true))
local eventBlock = engine:sub(eventBlockStart, eventBlockEnd - 1)
assert(not eventBlock:find('local unit, castGUID, spellID = ...', 1, true), 'r2 must not require castGUID/spellID from interruptibility events')

print("DK Mentor 3.3.4 r2 interrupt 12.1.5 regression smoke test passed")
