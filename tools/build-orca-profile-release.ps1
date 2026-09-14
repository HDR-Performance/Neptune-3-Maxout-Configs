[CmdletBinding()]
param(
    [string]$Version = '0.2.0-beta',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\dist')
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceRoot = Join-Path $repositoryRoot 'orca-profiles\Maxout-FlowTech'
$packageName = "Maxout-FlowTech-Orca-Profiles-$Version"
$stagingParent = Join-Path ([System.IO.Path]::GetTempPath()) ("hdr-orca-profiles-" + [guid]::NewGuid().ToString('N'))
$stagingRoot = Join-Path $stagingParent $packageName
$zipPath = Join-Path $OutputDirectory "$packageName.zip"

try {
    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
    foreach ($category in @('machine', 'process', 'filament')) {
        Copy-Item -LiteralPath (Join-Path $sourceRoot $category) -Destination $stagingRoot -Recurse
    }
    foreach ($file in @('manifest.json', 'START-HERE.md', 'Install-Maxout-Orca-Profiles.ps1', 'INSTALL-ORCA-PROFILES.cmd')) {
        Copy-Item -LiteralPath (Join-Path $sourceRoot $file) -Destination (Join-Path $stagingRoot $file)
    }

    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    Compress-Archive -LiteralPath $stagingRoot -DestinationPath $zipPath -CompressionLevel Optimal
    $hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Host $zipPath
    Write-Host "SHA256 $hash"
}
finally {
    if (Test-Path -LiteralPath $stagingParent) {
        Remove-Item -LiteralPath $stagingParent -Recurse -Force
    }
}
