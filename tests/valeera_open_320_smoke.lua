local DKM = {
    T = function(value, ...)
        if select("#", ...) > 0 then return string.format(value, ...) end
        return value
    end,
    Data = { specNames = { [250] = "Blood", [251] = "Frost", [252] = "Unholy" } },
    Addon = {},
}

assert(loadfile("ValeeraData.lua"))("DKMentor", DKM)
assert(loadfile("Valeera.lua"))("DKMentor", DKM)

local addon = assert(DKM.Addon)
assert(type(addon.OpenValeeraCompanionConfiguration) == "function", "Valeera native config opener missing")

local loaded = false
local shown = false
_G.C_AddOns = {
    IsAddOnLoaded = function(name)
        assert(name == "Blizzard_DelvesCompanionConfiguration")
        return loaded
    end,
    LoadAddOn = function(name)
        assert(name == "Blizzard_DelvesCompanionConfiguration")
        loaded = true
        _G.DelvesCompanionConfigurationFrame = { name = "DelvesCompanionConfigurationFrame" }
        return true
    end,
}
_G.InCombatLockdown = function() return false end
_G.ShowUIPanel = function(frame)
    assert(frame == _G.DelvesCompanionConfigurationFrame)
    shown = true
end

assert(addon:OpenValeeraCompanionConfiguration() == true, "Valeera config opener should succeed")
assert(loaded == true, "Blizzard companion addon was not loaded")
assert(shown == true, "Blizzard companion configuration frame was not shown")

_G.InCombatLockdown = function() return true end
shown = false
assert(addon:OpenValeeraCompanionConfiguration() == false, "Valeera config opener should block in combat")
assert(shown == false, "Valeera config frame should not open in combat")

print("Valeera native configuration opener smoke test passed")
