# ---------------------------------------------------------------
#  claude-usage-bar - native PowerShell status line for Claude Code
#  https://github.com/bhutano/claude-usage-bar
#
#  PowerShell support adapted from RunXPS/claude-usage-bar@7a82565:
#  https://github.com/RunXPS/claude-usage-bar/commit/7a825654090d2708dcee85e282e0e5c5bbfdc271
# ---------------------------------------------------------------

$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [Console]::OutputEncoding
} catch {
    # Keep the host's current encoding when it cannot be changed.
}

$inputText = [Console]::In.ReadToEnd()

$languageCode = $env:USAGE_BAR_LANG
$configFile = Join-Path $env:USERPROFILE ".claude\usage-bar.conf"
if (-not $languageCode -and (Test-Path -LiteralPath $configFile)) {
    $languageLine = Get-Content -LiteralPath $configFile |
        Where-Object { $_ -match '^LANG=' } |
        Select-Object -First 1
    if ($languageLine) {
        $languageCode = ($languageLine -replace '^LANG=', '').Trim()
    }
}
if (-not $languageCode) {
    $languageCode = "en"
}

$translations = @{
    en = @{
        waiting   = "Waiting for first response..."
        reset_now = "reset now"
        na        = "N/A"
        five_hour = "5h"
        seven_day = "7d"
        context   = "ctx"
        reset     = "reset"
        days      = "d"
        hours     = "h"
        minutes   = "m"
    }
    it = @{
        waiting   = "In attesa della prima risposta..."
        reset_now = "reset ora"
        na        = "N/A"
        five_hour = "5h"
        seven_day = "7d"
        context   = "ctx"
        reset     = "reset"
        days      = "g"
        hours     = "h"
        minutes   = "m"
    }
}

$text = $translations[$languageCode]
if (-not $text) {
    $text = $translations.en
}

if ([string]::IsNullOrWhiteSpace($inputText)) {
    Write-Output "[ $($text.waiting) ]"
    exit 0
}

try {
    $data = $inputText | ConvertFrom-Json
} catch {
    Write-Output "[ $($text.waiting) ]"
    exit 0
}

$escape = [char]27
$green = "${escape}[32m"
$brightGreen = "${escape}[92m"
$yellow = "${escape}[33m"
$orange = "${escape}[38;5;208m"
$red = "${escape}[31m"
$cyan = "${escape}[36m"
$bold = "${escape}[1m"
$dim = "${escape}[2m"
$resetColor = "${escape}[0m"
$filledBlock = [char]0x2588
$emptyBlock = [char]0x2591
$middleDot = [char]0x00B7

function Format-Bar {
    param(
        [Parameter(Mandatory = $true)] [double] $Percentage,
        [int] $Length = 8
    )

    $value = [Math]::Max(0.0, [Math]::Min(100.0, $Percentage))
    $filledCount = [Math]::Floor($value / 100.0 * $Length)
    $emptyCount = $Length - $filledCount
    return (($filledBlock.ToString() * $filledCount) -join '') + (($emptyBlock.ToString() * $emptyCount) -join '')
}

function Format-Rate {
    param($Percentage)

    if ($null -eq $Percentage) {
        return "$dim$($text.na)$resetColor"
    }

    try {
        $value = [double]$Percentage
    } catch {
        return "$dim$($text.na)$resetColor"
    }

    $color = if ($value -ge 90) { $red } elseif ($value -ge 80) { $orange } else { $green }
    return "$color$(Format-Bar -Percentage $value) $($value.ToString('0'))%$resetColor"
}

function Format-Context {
    param($Percentage)

    if ($null -eq $Percentage) {
        return "$dim$($text.na)$resetColor"
    }

    try {
        $value = [double]$Percentage
    } catch {
        return "$dim$($text.na)$resetColor"
    }

    $color = if ($value -gt 80) { $red } elseif ($value -ge 70) { $orange } else { $green }
    return "$color$(Format-Bar -Percentage $value) $($value.ToString('0'))%$resetColor"
}

function Format-TimeUntil {
    param($UnixTimestamp)

    try {
        $resetTime = [DateTimeOffset]::FromUnixTimeSeconds([long]$UnixTimestamp)
        $seconds = [Math]::Floor(($resetTime - [DateTimeOffset]::Now).TotalSeconds)
        if ($seconds -le 0) {
            return "$green$($text.reset_now)$resetColor"
        }

        $totalHours = [Math]::Floor($seconds / 3600)
        $minutes = [Math]::Floor(($seconds % 3600) / 60)
        if ($totalHours -ge 24) {
            $days = [Math]::Floor($totalHours / 24)
            $hours = $totalHours % 24
            return "$cyan$days$($text.days) $hours$($text.hours)$resetColor"
        }
        if ($totalHours -gt 0) {
            return "$cyan$totalHours$($text.hours) $minutes$($text.minutes)$resetColor"
        }
        return "$cyan$minutes$($text.minutes)$resetColor"
    } catch {
        return "${dim}?$resetColor"
    }
}

function Compress-HomePath {
    param($Path)

    if (-not $Path) {
        return ""
    }

    $value = [string]$Path
    $userHomePath = $env:USERPROFILE
    if (-not $userHomePath) {
        $userHomePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    }
    if (-not $userHomePath) {
        return $value
    }

    $trimmedHomePath = $userHomePath.TrimEnd('\', '/')
    if ($value.Equals($trimmedHomePath, [StringComparison]::OrdinalIgnoreCase)) {
        return "~"
    }
    if ($value.StartsWith("$trimmedHomePath\", [StringComparison]::OrdinalIgnoreCase) -or
        $value.StartsWith("$trimmedHomePath/", [StringComparison]::OrdinalIgnoreCase)) {
        return "~" + $value.Substring($trimmedHomePath.Length)
    }
    return $value
}

$rateLimits = $data.rate_limits
$fiveHour = if ($rateLimits) { $rateLimits.five_hour } else { $null }
$sevenDay = if ($rateLimits) { $rateLimits.seven_day } else { $null }
$contextWindow = $data.context_window

$parts = @()
if ($fiveHour -and $null -ne $fiveHour.used_percentage) {
    $resetText = if ($fiveHour.resets_at) { " $($text.reset) $(Format-TimeUntil $fiveHour.resets_at)" } else { "" }
    $parts += "$bold$($text.five_hour):$resetColor $(Format-Rate $fiveHour.used_percentage)$resetText"
} else {
    $parts += "$dim$($text.five_hour): $($text.na)$resetColor"
}

if ($sevenDay -and $null -ne $sevenDay.used_percentage) {
    $resetText = if ($sevenDay.resets_at) { " $($text.reset) $(Format-TimeUntil $sevenDay.resets_at)" } else { "" }
    $parts += "$bold$($text.seven_day):$resetColor $(Format-Rate $sevenDay.used_percentage)$resetText"
} else {
    $parts += "$dim$($text.seven_day): $($text.na)$resetColor"
}

if ($contextWindow -and $null -ne $contextWindow.used_percentage) {
    $parts += "$bold$($text.context):$resetColor $(Format-Context $contextWindow.used_percentage)"
}

$separator = "  $dim|$resetColor  "
Write-Output ($parts -join $separator)

$modelName = $null
if ($data.model) {
    $modelName = if ($data.model.display_name) { $data.model.display_name } else { $data.model.id }
}
$effortLevel = if ($data.effort) { $data.effort.level } else { $null }
$workingDirectory = $null
if ($data.workspace) {
    $workingDirectory = if ($data.workspace.current_dir) {
        $data.workspace.current_dir
    } elseif ($data.cwd) {
        $data.cwd
    } else {
        $data.workspace.project_dir
    }
} elseif ($data.cwd) {
    $workingDirectory = $data.cwd
}

$sessionDetails = @()
if ($modelName) {
    $modelDetails = "$yellow$modelName$resetColor"
    if ($effortLevel) {
        $modelDetails += " $dim$effortLevel$resetColor"
    }
    $sessionDetails += $modelDetails
} elseif ($effortLevel) {
    $sessionDetails += "$dim$effortLevel$resetColor"
}
if ($workingDirectory) {
    $sessionDetails += "$brightGreen$(Compress-HomePath $workingDirectory)$resetColor"
}
if ($sessionDetails.Count -gt 0) {
    $detailSeparator = " ${dim}$middleDot$resetColor "
    Write-Output ($sessionDetails -join $detailSeparator)
}
