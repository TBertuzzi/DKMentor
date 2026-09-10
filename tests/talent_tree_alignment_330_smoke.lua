local f = assert(io.open('TalentTree.lua', 'r'))
local tree = f:read('*a')
f:close()

assert(tree:find("if groupKey == 'hero' and #nodes > 0 then", 1, true), 'Hero tree alignment normalization missing')
assert(tree:find("for index = 1, math.min(2, #rowYs) do", 1, true), 'top Hero singleton rows must be normalized together')
assert(tree:find("displayX[row.nodes[1].nodeID] = centerX", 1, true), 'Hero singleton row must center on the shared spine')
assert(tree:find("RenderGroup(heroGroup, runtime.groups.hero, runtime.nodeByID, 'Hero tree', 'hero')", 1, true), 'Hero renderer must opt into alignment normalization')

print('DK Mentor 3.3 Hero tree alignment smoke test passed')
