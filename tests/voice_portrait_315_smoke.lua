-- Static smoke test for DK Mentor 3.1.5 portrait synchronization and compact main UI.
local file = assert(io.open("Core.lua", "r"))
local core = file:read("*a")
file:close()

for _, needle in ipairs({
    'frame:SetSize(1060, 780)',
    'page:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -104)',
    'frame.hudSection = CreateSection(settingsPage, T("HUDs and layout"), -38, 288)',
    'frame.loadoutPilotSection = CreateSection(settingsPage, T("Loadout automation"), -331, 82)',
    'frame.voiceSection = CreateSection(settingsPage, T("Lich King commentary"), -418, 156)',
    'addon.voiceStartedAt = GetNow()',
    'voiceBusyUntil = addon.voiceStartedAt + 7',
    'pcall(C_Sound.IsPlaying, voiceHandle)',
    'if now - (addon.voiceStartedAt or 0) < 0.20 then',
    'voiceBusyUntil = 0',
    'if self.elapsed < 0.10 then return end',
}) do
    assert(core:find(needle, 1, true), "3.1.5 sync/compact regression: " .. needle)
end

print("DK Mentor 3.1.5 portrait sync / compact UI smoke test passed")
