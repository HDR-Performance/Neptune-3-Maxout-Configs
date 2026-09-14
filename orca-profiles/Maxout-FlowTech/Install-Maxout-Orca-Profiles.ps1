[CmdletBinding()]
param(
    [string]$DestinationRoot = (Join-Path $env:APPDATA 'OrcaSlicer\user\default')
)

$ErrorActionPreference = 'Stop'

$runningOrca = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -match '(?i)orca.*slicer' }
if ($runningOrca) {
    throw 'OrcaSlicer is running. Close OrcaSlicer, then run this installer again.'
}

$packageRoot = $PSScriptRoot
$manifestPath = Join-Path $packageRoot 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "The profile manifest is missing: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$categories = @('machine', 'process', 'filament')
$expectedCounts = @{
    machine  = [int]$manifest.generated_printer_profiles
    process  = [int]$manifest.generated_process_profiles
    filament = [int]$manifest.generated_filament_profiles
}

foreach ($category in $categories) {
    $sourceDirectory = Join-Path $packageRoot $category
    $actualCount = @(Get-ChildItem -LiteralPath $sourceDirectory -Filter '*.json' -File).Count
    if ($actualCount -ne $expectedCounts[$category]) {
        throw "The $category folder contains $actualCount profiles; expected $($expectedCounts[$category]). Download a fresh ZIP and try again."
    }
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $DestinationRoot "Maxout-FlowTech-backups\$timestamp"
$installedCount = 0
$backupCount = 0

foreach ($category in $categories) {
    $sourceDirectory = Join-Path $packageRoot $category
    $destinationDirectory = Join-Path $DestinationRoot $category
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null

    foreach ($sourceFile in Get-ChildItem -LiteralPath $sourceDirectory -Filter '*.json' -File) {
        $destinationFile = Join-Path $destinationDirectory $sourceFile.Name
        if (Test-Path -LiteralPath $destinationFile -PathType Leaf) {
            $backupDirectory = Join-Path $backupRoot $category
            New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
            Copy-Item -LiteralPath $destinationFile -Destination (Join-Path $backupDirectory $sourceFile.Name) -Force
            $backupCount++
        }

        Copy-Item -LiteralPath $sourceFile.FullName -Destination $destinationFile -Force
        $installedCount++
    }
}

Write-Host ''
Write-Host "Installed $installedCount Maxout FlowTech OrcaSlicer profiles." -ForegroundColor Green
Write-Host "Destination: $DestinationRoot"
if ($backupCount -gt 0) {
    Write-Host "Backed up $backupCount replaced profile files to: $backupRoot" -ForegroundColor Yellow
}
Write-Host 'Start OrcaSlicer and select a Maxout FlowTech printer, process, and filament preset.'
Write-Host 'These are beta starting profiles. Calibrate each material and spool before production printing.' -ForegroundColor Yellow
