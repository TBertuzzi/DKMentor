-- DK Mentor 3.1.6 layout preset close-button regression smoke test.
local file = assert(io.open("Core.lua", "r"))
local core = file:read("*a")
file:close()

for _, snippet in ipairs({
    'frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")',
    'frame.closeButton = CreateActionButton(frame)',
    'frame.closeButton:SetText(T("Close"))',
    'frame.closeButton:SetScript("OnClick", function() frame:Hide() end)',
}) do
    assert(core:find(snippet, 1, true), "Layout preset close control missing: " .. snippet)
end

print("DK Mentor 3.1.6 layout preset close-button smoke test passed")
