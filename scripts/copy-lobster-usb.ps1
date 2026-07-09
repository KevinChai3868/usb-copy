param(
    [string]$SourceFolder = "",
    [string]$KeyFile = "",
    [string]$DestinationFolderName = "",
    [string]$LogDirectory = "",
    [string[]]$DriveLetters,
    [switch]$Proceed
)

$ErrorActionPreference = "Stop"

function Join-Chars {
    param([int[]]$Codes)
    return -join ($Codes | ForEach-Object { [char]$_ })
}

function Normalize-DriveLetter {
    param([string]$Drive)
    $value = $Drive.Trim()
    if ($value.Length -eq 1) {
        return ($value.ToUpperInvariant() + ":")
    }
    return $value.TrimEnd("\").ToUpperInvariant()
}

$transferFolderName = Join-Chars @(0x50B3, 0x8F38)
$lobsterFolderName = (Join-Chars @(0x9F8D, 0x8766)) + "AI" + (Join-Chars @(0x96A8, 0x8EAB, 0x789F))

if ($SourceFolder -eq "") {
    $SourceFolder = Join-Path ("C:\" + $transferFolderName) $lobsterFolderName
}

if ($KeyFile -eq "") {
    $KeyFile = Join-Path ("C:\" + $transferFolderName) "key.txt"
}

if ($DestinationFolderName -eq "") {
    $DestinationFolderName = $lobsterFolderName
}

if ($LogDirectory -eq "") {
    $LogDirectory = "C:\" + $transferFolderName
}

if (-not (Test-Path -LiteralPath $SourceFolder -PathType Container)) {
    throw "Source folder not found: $SourceFolder"
}

if (-not (Test-Path -LiteralPath $KeyFile -PathType Leaf)) {
    throw "Key file not found: $KeyFile"
}

if (-not (Test-Path -LiteralPath $LogDirectory -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
}

$keys = Get-Content -LiteralPath $KeyFile |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }

$removableDrives = Get-CimInstance Win32_LogicalDisk |
    Where-Object { $_.DriveType -eq 2 } |
    Sort-Object DeviceID

if ($DriveLetters -and $DriveLetters.Count -gt 0) {
    $requested = $DriveLetters | ForEach-Object { Normalize-DriveLetter $_ }
    $removableDrives = $removableDrives | Where-Object { $requested -contains $_.DeviceID.ToUpperInvariant() }
    $missing = $requested | Where-Object { $removableDrives.DeviceID -notcontains $_ }
    if ($missing.Count -gt 0) {
        throw "Requested removable drive(s) not found: $($missing -join ', ')"
    }
}

if (-not $removableDrives -or $removableDrives.Count -eq 0) {
    throw "No removable USB drives detected."
}

if ($keys.Count -lt $removableDrives.Count) {
    throw "Not enough keys: need $($removableDrives.Count), found $($keys.Count)."
}

$plan = for ($i = 0; $i -lt $removableDrives.Count; $i++) {
    $drive = $removableDrives[$i].DeviceID
    $destinationFolder = Join-Path ($drive + "\") $DestinationFolderName
    [pscustomobject]@{
        Drive = $drive
        VolumeName = $removableDrives[$i].VolumeName
        FileSystem = $removableDrives[$i].FileSystem
        Destination = $destinationFolder
        Serial = $keys[$i]
        KeyLine = "LXAI-$($keys[$i])"
    }
}

Write-Host "Detected USB assignment plan:"
$plan | Format-Table -AutoSize

if (-not $Proceed) {
    Write-Host ""
    Write-Host "Dry run only. Re-run with -Proceed to copy files and write lobster.key."
    return
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$summary = @()

foreach ($item in $plan) {
    New-Item -ItemType Directory -Force -Path $item.Destination | Out-Null
    $log = Join-Path $LogDirectory ("robocopy-{0}.log" -f $item.Drive.TrimEnd(":"))

    & robocopy $SourceFolder $item.Destination /E /MT:8 /R:0 /W:0 /FFT /XJ /NP /NFL /NDL /LOG:$log
    $robocopyExitCode = $LASTEXITCODE
    if ($robocopyExitCode -ge 8) {
        throw "robocopy failed for $($item.Drive) with exit code $robocopyExitCode. See log: $log"
    }

    $keyPath = Join-Path $item.Destination "lobster.key"
    if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
        throw "Target lobster.key not found: $keyPath"
    }

    $lines = [System.IO.File]::ReadAllLines($keyPath)
    if ($lines.Count -eq 0) {
        throw "Target lobster.key is empty: $keyPath"
    }

    $lines[$lines.Count - 1] = $item.KeyLine
    [System.IO.File]::WriteAllLines($keyPath, $lines, $utf8NoBom)

    $checkLines = [System.IO.File]::ReadAllLines($keyPath)
    $summary += [pscustomobject]@{
        Drive = $item.Drive
        Destination = $item.Destination
        Serial = $item.Serial
        KeyLastLine = $checkLines[$checkLines.Count - 1]
        RobocopyExitCode = $robocopyExitCode
        Log = $log
    }
}

Write-Host ""
Write-Host "Completed:"
$summary | Format-Table -AutoSize
