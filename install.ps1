# ---------------------------------------------------------------
#  claude-usage-bar - native Windows installer
#  Usage: powershell.exe -ExecutionPolicy Bypass -File .\install.ps1 [-Lang en|it]
#
#  PowerShell support adapted from RunXPS/claude-usage-bar@7a82565:
#  https://github.com/RunXPS/claude-usage-bar/commit/7a825654090d2708dcee85e282e0e5c5bbfdc271
# ---------------------------------------------------------------

param(
    [ValidateSet("en", "it")]
    [string] $Lang,

    [string] $ClaudeDirectory
)

$ErrorActionPreference = "Stop"
$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ClaudeDirectory) {
    $ClaudeDirectory = Join-Path $env:USERPROFILE ".claude"
}
$claudeDirectory = $ClaudeDirectory
$skillDirectory = Join-Path $claudeDirectory "skills\usage-bar"
$settingsPath = Join-Path $claudeDirectory "settings.json"
$configPath = Join-Path $claudeDirectory "usage-bar.conf"

if (-not $Lang) {
    Write-Host ""
    Write-Host "  Select language / Seleziona la lingua:"
    Write-Host "  [1] English (default)"
    Write-Host "  [2] Italiano"
    Write-Host ""
    $languageChoice = Read-Host "  Choice / Scelta [1]"
    $Lang = if ($languageChoice -eq "2") { "it" } else { "en" }
}

Write-Host ""
Write-Host "  claude-usage-bar - PowerShell installer (lang: $Lang)"
Write-Host "  -------------------------------------------------------"

Write-Host "  [1/4] Copying the native PowerShell status line..."
New-Item -ItemType Directory -Force -Path $claudeDirectory | Out-Null
Copy-Item -LiteralPath (Join-Path $scriptDirectory "statusline-usage.ps1") -Destination $claudeDirectory -Force

Write-Host "  [2/4] Installing the /usage-bar skill..."
New-Item -ItemType Directory -Force -Path $skillDirectory | Out-Null
$normalizedScriptDirectory = [System.IO.Path]::GetFullPath($scriptDirectory).TrimEnd('\', '/')
$normalizedSkillDirectory = [System.IO.Path]::GetFullPath($skillDirectory).TrimEnd('\', '/')
if (-not $normalizedScriptDirectory.Equals($normalizedSkillDirectory, [StringComparison]::OrdinalIgnoreCase)) {
    foreach ($fileName in @("SKILL.md", "statusline-usage.sh", "statusline-usage.ps1", "install.sh", "install.ps1")) {
        Copy-Item -LiteralPath (Join-Path $scriptDirectory $fileName) -Destination $skillDirectory -Force
    }
} else {
    Write-Host "        Skill files are already in place."
}

Write-Host "  [3/4] Writing config to $configPath ..."
$configContent = @"
# claude-usage-bar - configuration
# Edit LANG= to change the display language.
# Available: en (English), it (Italian)
# You can also override per-session: USAGE_BAR_LANG=it claude
#
LANG=$Lang
"@
[System.IO.File]::WriteAllText($configPath, $configContent, $utf8WithoutBom)

Write-Host "  [4/4] Enabling statusLine in $settingsPath ..."
if (Test-Path -LiteralPath $settingsPath) {
    try {
        $settingsContent = [System.IO.File]::ReadAllText($settingsPath, [System.Text.Encoding]::UTF8)
        $settingsObject = $settingsContent | ConvertFrom-Json
    } catch {
        throw "settings.json is not valid JSON and was left unchanged: $settingsPath"
    }
    if ($settingsObject -isnot [System.Management.Automation.PSCustomObject]) {
        throw "settings.json must contain a JSON object and was left unchanged: $settingsPath"
    }
    Copy-Item -LiteralPath $settingsPath -Destination "$settingsPath.bak" -Force
    Write-Host "  Backup written to $settingsPath.bak"
} else {
    $settingsObject = [PSCustomObject]@{}
}

$statuslineScript = Join-Path $claudeDirectory "statusline-usage.ps1"
$statuslineValue = [PSCustomObject]@{
    type = "command"
    command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$statuslineScript`""
}

if ($settingsObject.PSObject.Properties.Name -contains "statusLine") {
    $settingsObject.statusLine = $statuslineValue
} else {
    $settingsObject | Add-Member -MemberType NoteProperty -Name "statusLine" -Value $statuslineValue
}

$settingsJson = $settingsObject | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($settingsPath, $settingsJson + [Environment]::NewLine, $utf8WithoutBom)

Write-Host ""
Write-Host "  Installation complete. Restart Claude Code to activate the status bar."
Write-Host "  To change language later, edit: $configPath"
Write-Host ""
