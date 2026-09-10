local f = assert(io.open("TalentTree.lua", "r"))
local tree = f:read("*a")
f:close()

assert(tree:find("C_Traits.GetTreeNodes", 1, true), "Talent tree must use Blizzard trait nodes")
assert(tree:find("C_Traits.GetNodeInfo", 1, true), "Talent tree must use Blizzard node positions/state")
assert(tree:find("C_ClassTalents.InitializeViewLoadout", 1, true), "Talent tree must support browsing another DK spec")
assert(tree:find("C_ClassTalents.ViewLoadout", 1, true), "Talent tree view config fallback missing")
assert(tree:find("function addon:RenderBuildTalentTreePreview", 1, true), "Build tree renderer missing")
assert(tree:find("function addon:ShowBuildTreeNodeTooltip", 1, true), "Build tree native tooltip missing")
assert(tree:find("local guideKeys = {}", 1, true), "Stable guide-key mapping missing")
assert(tree:find("profile.treeKeyTalents or profile.keyTalents", 1, true), "Visual tree must prefer actual talent-node keys")
assert(tree:find("Why: %s", 1, true), "Talent-tree rationale tooltip missing")
assert(tree:find("pcall(line.SetStartPoint", 1, true), "Talent-tree lines must fail safely on API drift")
assert(not tree:find("SetSelection", 1, true), "Build tree preview must never change talent selections")
assert(not tree:find("PurchaseRank", 1, true), "Build tree preview must never purchase talents")
assert(not tree:find("CommitConfig", 1, true), "Build tree preview must not directly commit staged talent changes")
assert(tree:find("C_ClassTalents.RequestNewConfig", 1, true), "Direct Blizzard loadout creation missing")
assert(tree:find("C_ClassTalents.ImportLoadout", 1, true), "Direct Blizzard loadout import missing")

local coreFile = assert(io.open("Core.lua", "r"))
local core = coreFile:read("*a")
coreFile:close()
assert(core:find("self:RenderBuildTalentTreePreview(root, specID, profile, contentWidth, y, index)", 1, true), "Build Mentor must attach the visual tree")
assert(core:find("self:ResetBuildTalentTreeVisual(root)", 1, true), "Build tree pool reset missing")

local tocFile = assert(io.open("DKMentor.toc", "r"))
local toc = tocFile:read("*a")
tocFile:close()
assert(toc:find("Core.lua\nTalentTree.lua\nAdvisor.lua", 1, true), "TalentTree.lua load order must follow Core.lua")

local buildsFile = assert(io.open("Builds.lua", "r"))
local builds = buildsFile:read("*a")
buildsFile:close()
for _, needle in ipairs({
    'local BLOOD_MPLUS_KEYS = {',
    'spellID = 391517',
    'local FROST_RAID_MPLUS_KEYS = {',
    'spellID = 1230301',
    'spellID = 435005',
    'local FROST_DELVE_KEYS = {}',
    'local UNHOLY_RIDER_AOE_KEYS = {',
    'spellID = 207317',
    'local TREE_GUIDANCE = {',
    'profile.treeCoverage = guidance.coverage',
}) do
    assert(builds:find(needle, 1, true), "3.3 tree guidance data missing: " .. needle)
end



local packageShFile = assert(io.open("scripts/package.sh", "r"))
local packageSh = packageShFile:read("*a")
packageShFile:close()
assert(packageSh:find("Core.lua TalentTree.lua Advisor.lua", 1, true), "package.sh must include TalentTree.lua")

local packagePsFile = assert(io.open("scripts/package.ps1", "r"))
local packagePs = packagePsFile:read("*a")
packagePsFile:close()
assert(packagePs:find('"Core.lua","TalentTree.lua","Advisor.lua"', 1, true), "package.ps1 must include TalentTree.lua")

print("DK Mentor 3.3 visual talent tree smoke test passed")
