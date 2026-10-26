local function read(path)
    local f = assert(io.open(path, 'r'))
    local s = f:read('*a')
    f:close()
    return s
end

local DKM = { T = function(v, ...) if select('#', ...) > 0 then return string.format(v, ...) end return v end }
assert(loadfile('Data.lua'))('DKMentor', DKM)
assert(DKM.Data.version == '3.3.4', 'Addon data version mismatch')
assert(DKM.Data.interface == 120105, 'Retail 12.1.5 interface mismatch')
assert(DKM.Data.patch == '12.1.5', 'Runtime patch target mismatch')

local core = read('Core.lua')
local advisor = read('Advisor.lua')
local removed = {
    'GetItemQualityColor', 'GetItemInfoInstant', 'GetItemIcon', 'GetItemSpell',
    'GetItemInfo', 'GetItemCount',
}
for _, name in ipairs(removed) do
    local function hasBare(text)
        for line in text:gmatch('[^\n]+') do
            if line:find(name, 1, true) and not line:find('C_Item.' .. name, 1, true) then
                if not (name == 'GetItemIcon' and line:find('C_Item.GetItemIconByID', 1, true)) then
                    return line
                end
            end
        end
    end
    assert(not hasBare(core), 'Removed 12.1.5 item API fallback remains in Core.lua: ' .. name)
    assert(not hasBare(advisor), 'Removed 12.1.5 item API fallback remains in Advisor.lua: ' .. name)
end
assert(core:find('C_Item.GetItemQualityColor', 1, true), 'C_Item quality-color path missing')
assert(core:find('C_Item.GetItemInfoInstant', 1, true), 'C_Item instant-info path missing')
assert(core:find('C_Item.GetItemIconByID', 1, true), 'C_Item icon path missing')
assert(core:find('C_Item.GetItemSpell', 1, true), 'C_Item item-spell path missing')
assert(advisor:find('C_Item.GetItemInfoInstant', 1, true), 'Tooltip item-ID path must use C_Item')

-- Labyrinth is a Delve-style activity. Keep the stable Delve API as the primary
-- detector until the live 12.1.5 client proves that an additional signal is needed.
assert(core:find('C_PartyInfo.IsDelveInProgress', 1, true), 'Delve context detector missing')

local VA = { T = DKM.T }
assert(loadfile('ValeeraData.lua'))('DKMentor', VA)
local vd = assert(VA.ValeeraData)
assert(vd.patch == '12.1.5' and vd.reviewed == '2026-10-13', 'Valeera 12.1.5 metadata mismatch')
assert(vd.utilityOrder[1] == 'dundun', "Dundun's Favor should be the general utility baseline")
for _, specID in ipairs({250, 251, 252}) do
    local rows = assert(vd.recommendations[specID])
    for _, preset in ipairs({'auto','safe','balanced','fast','high','leveling'}) do
        assert(rows[preset].utility == 'dundun', tostring(specID) .. ' ' .. preset .. ' should use Dundun general baseline')
    end
    assert(rows.nemesis.utility == 'dreamcatcher', "Azta'rec Nemesis must keep Dreamcatcher")
    assert(rows.nemesis.role == 'healer' and rows.nemesis.combat == 'bilespear' and rows.nemesis.poison == 'phantasmal', "Azta'rec boss-specific loadout regressed")
end

local B = { T = DKM.T }
assert(loadfile('Builds.lua'))('DKMentor', B)
for _, context in ipairs({'delve','dungeon','mythicplus','raid'}) do
    local p = assert(B.Builds[252][context][1])
    assert(p.reviewedPatch == '12.1.5' and p.reviewedDate == '2026-10-13', 'Unholy 12.1.5 review metadata mismatch: ' .. context)
    assert(p.heroTalent == "San'layn", 'Sanlayn remains the current standard direction: ' .. context)
end
local guides = { T = DKM.T }
assert(loadfile('Guides.lua'))('DKMentor', guides)
local text = ''
for _, section in ipairs(guides.Guides[252].sections or {}) do text = text .. ' ' .. tostring(section.body or '') end
assert(text:find('100%% of the remaining plague damage'), 'Blightfall 100% tuning note missing')

print('DK Mentor 3.3.4 Patch 12.1.5 compatibility smoke test passed')
