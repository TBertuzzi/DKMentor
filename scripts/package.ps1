$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$VersionLine = Select-String -Path (Join-Path $Root "DKMentor.toc") -Pattern '^## Version: (.+)$'
$Version = $VersionLine.Matches[0].Groups[1].Value.Trim()
$Out = Join-Path $Root "release"
$Stage = Join-Path $Out "DKMentor"
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
New-Item -ItemType Directory -Path $Stage | Out-Null
$Files = @("DKMentor.toc","Localization.lua","Data.lua","Builds.lua","Guides.lua","Voices.lua","Core.lua","LICENSE","THIRD_PARTY_NOTICES.md")
foreach ($File in $Files) { Copy-Item (Join-Path $Root $File) (Join-Path $Stage $File) }
$MediaSource = Join-Path $Root "Media"
$MediaDest = Join-Path $Stage "Media"
Copy-Item $MediaSource $MediaDest -Recurse -Force
$Zip = Join-Path $Out "DKMentor-v$Version-CurseForge.zip"
Compress-Archive -Path $Stage -DestinationPath $Zip
Write-Output $Zip
