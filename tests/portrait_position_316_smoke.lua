-- DK Mentor 3.1.6 stable Lich King portrait position regression smoke test.
local file = assert(io.open("Core.lua", "r"))
local core = file:read("*a")
file:close()

for _, snippet in ipairs({
    'cfg.positionVersion = 2',
    'left, right = left * scale, right * scale',
    'top, bottom = top * scale, bottom * scale',
    'frame:SetPoint(point, parent, point, x / scale, y / scale)',
    'if cfg.positionVersion == 2 then',
    'frame:SetPoint(point, UIParent, point, (tonumber(cfg.x) or 0) / scale, (tonumber(cfg.y) or 165) / scale)',
    'if not frame.dragging then addon.RestoreLichKingPortraitPosition() end',
    'self.dragging = true',
    'self.dragging = false',
    'tostring(vp.positionVersion == 2 and 2 or 1)',
    'vp.positionVersion = tonumber(fields[10]) == 2 and 2 or nil',
}) do
    assert(core:find(snippet, 1, true), "Stable portrait position regression: " .. snippet)
end

print("DK Mentor 3.1.6 stable portrait position smoke test passed")
