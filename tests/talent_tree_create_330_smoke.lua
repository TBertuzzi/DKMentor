-- Direct Blizzard loadout creation smoke test.
local DKM = {
    Addon = {},
    T = function(value, ...)
        if select('#', ...) > 0 then return string.format(value, ...) end
        return value
    end,
}
function DKM.Addon:GetSpecInfo() return 251 end
function DKM.Addon:Print(message) self.lastPrint = message end

local eventFrame
CreateFrame = function()
    local frame = {}
    function frame:RegisterEvent(event) self.event = event end
    function frame:SetScript(script, fn) self[script] = fn end
    eventFrame = frame
    return frame
end
InCombatLockdown = function() return false end

local imported, savedConfig, requestedName
C_Traits = {
    GetConfigInfo = function(configID)
        if configID == 100 then return { name='DKM Frost M+ DB', treeIDs={1} } end
        return { name='Other', treeIDs={1} }
    end,
}
C_ClassTalents = {
    GetConfigIDsBySpecID = function(specID)
        assert(specID == 251)
        return {100}
    end,
    CanCreateNewConfig = function() return true end,
    RequestNewConfig = function(name)
        requestedName = name
        assert(eventFrame and eventFrame.OnEvent, 'TRAIT_CONFIG_CREATED handler was not registered before RequestNewConfig')
        eventFrame.OnEvent(eventFrame, 'TRAIT_CONFIG_CREATED', { ID=200, name=name, type=1, treeIDs={1} })
        return true
    end,
    ImportLoadout = function(configID, entries, name, importString)
        imported = { configID=configID, entries=entries, name=name, importString=importString }
        return true, nil
    end,
    SaveConfig = function(configID)
        savedConfig = configID
        return true
    end,
}

assert(loadfile('TalentTree.lua'))('DKMentor', DKM)
local create = assert(DKM.TalentTree.CreateBlizzardLoadoutFromImportString, 'direct create helper missing')
local ok, name = create(251, 'DKM Frost M+ DB', 'MOCK-IMPORT')
assert(ok == true, 'direct create should succeed')
assert(name == 'DKM Frost M+ DB 2', 'duplicate-safe loadout name expected')
assert(requestedName == name, 'RequestNewConfig name mismatch')
assert(imported and imported.configID == 200, 'new Blizzard config was not populated')
assert(imported.importString == 'MOCK-IMPORT', 'ImportLoadout did not receive the Blizzard import string')
assert(imported.name == name, 'ImportLoadout name mismatch')
assert(savedConfig == 200, 'new Blizzard config was not saved')
assert(C_ClassTalents.LoadConfig == nil, 'test must not auto-activate the new loadout')

DKM.Addon.GetSpecInfo = function() return 250 end
local wrongSpec, errorText = create(251, 'DKM Frost', 'MOCK-IMPORT')
assert(wrongSpec == false and type(errorText) == 'string', 'wrong-spec creation must fail safely')
print('DK Mentor 3.3 direct Blizzard loadout creation smoke test passed')
