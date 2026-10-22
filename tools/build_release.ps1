# Builds dist\Saudi-Fix_v<version>.zip and dist\SHA256.txt
# from Saudi_Fix.bat, ReadMe.txt and LICENSE.
# Usage: powershell -ExecutionPolicy Bypass -File tools\build_release.ps1
# Saudi-Fix (c) 2026 - Rashid Alghamdi

$ErrorActionPreference = 'Stop'
$root    = Split-Path $PSScriptRoot -Parent
$bat     = Join-Path $root 'Saudi_Fix.bat'
$readme  = Join-Path $root 'ReadMe.txt'
$license = Join-Path $root 'LICENSE'

$text  = [IO.File]::ReadAllText($bat, [Text.Encoding]::UTF8)
$match = [regex]::Match($text, '(?m)^set "SF_VER=([^"]+)"')
if (-not $match.Success) { throw 'SF_VER not found in Saudi_Fix.bat' }
$version = $match.Groups[1].Value
Write-Host "Building Saudi-Fix v$version" -ForegroundColor Green

# --- checks ---------------------------------------------------------------
# cmd needs CRLF line endings and no BOM, otherwise labels and line 1 break
$original = [IO.File]::ReadAllBytes($bat)
$text = $text -replace "`r?`n", "`r`n"
$fixed = (New-Object Text.UTF8Encoding $false).GetBytes($text)
# rewrite only when needed - a new timestamp would change the ZIP hash
if ([Convert]::ToBase64String($original) -ne [Convert]::ToBase64String($fixed)) {
    [IO.File]::WriteAllBytes($bat, $fixed)
    Write-Host 'Fixed line endings / BOM in Saudi_Fix.bat'
}

$lines   = $text -split "`r`n"
$labels  = $lines | Where-Object { $_ -match '^:([A-Za-z_]\w*)\s*$' } | ForEach-Object { $Matches[1].ToLower() }
$dups    = @($labels | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
$targets = [regex]::Matches($text, '(?i)(?:goto|call)\s+:([A-Za-z_]\w*)') | ForEach-Object { $_.Groups[1].Value.ToLower() } | Sort-Object -Unique
$missing = @($targets | Where-Object { $_ -ne 'eof' -and $labels -notcontains $_ })
$chcp    = [array]::FindIndex($lines, [Predicate[string]]{ param($l) $l -match '^chcp 65001' })
$early   = @(0..$chcp | Where-Object { $lines[$_] -match '[^\x00-\x7F]' })

$failed = $false
if ($dups.Count)    { Write-Host "Duplicate labels: $($dups -join ', ')" -ForegroundColor Red; $failed = $true }
if ($missing.Count) { Write-Host "Missing labels: $($missing -join ', ')" -ForegroundColor Red; $failed = $true }
if ($early.Count)   { Write-Host "Non-ASCII before chcp 65001 on lines: $(($early | ForEach-Object { $_ + 1 }) -join ', ')" -ForegroundColor Red; $failed = $true }
if ($text -match 'https?://') { Write-Host 'Script contains a URL - releases must not download anything' -ForegroundColor Red; $failed = $true }
foreach ($f in $bat, $readme, $license) {
    if (-not (Select-String -Path $f -Pattern 'Rashid Alghamdi' -SimpleMatch -Quiet)) {
        Write-Host "Copyright notice missing in $(Split-Path $f -Leaf)" -ForegroundColor Red; $failed = $true
    }
}
if ($failed) { throw 'Checks failed, release not built' }
Write-Host "Checks passed: $($labels.Count) labels, CRLF, no BOM, no downloads, copyright present"

# --- stage ----------------------------------------------------------------
$dist  = Join-Path $root 'dist'
$name  = "Saudi-Fix v$version"
$stage = Join-Path $dist $name
New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

Copy-Item $bat (Join-Path $stage 'Saudi_Fix.bat')
# BOM so old Notepad versions show the Arabic text correctly
foreach ($pair in @(@($readme, 'ReadMe.txt'), @($license, 'LICENSE.txt'))) {
    $t = [IO.File]::ReadAllText($pair[0], [Text.Encoding]::UTF8) -replace "`r?`n", "`r`n"
    [IO.File]::WriteAllText((Join-Path $stage $pair[1]), $t, (New-Object Text.UTF8Encoding $true))
}

$batHash = (Get-FileHash (Join-Path $stage 'Saudi_Fix.bat') -Algorithm SHA256).Hash
"$batHash  Saudi_Fix.bat`r`n" | Set-Content -Path (Join-Path $stage 'SHA256.txt') -Encoding ASCII -NoNewline

# same sources give the same ZIP hash: every entry gets the newest source timestamp
$stamp = (Get-Item $bat, $readme, $license | Measure-Object LastWriteTime -Maximum).Maximum
Get-ChildItem $stage -File | ForEach-Object { $_.LastWriteTime = $stamp }

# --- zip ------------------------------------------------------------------
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipName = "Saudi-Fix_v$version.zip"
$zip = Join-Path $dist $zipName
if (Test-Path $zip) { Remove-Item $zip -Force }
# entries written one by one: ZipFile.CreateFromDirectory on .NET Framework
# stores "\" in paths, which other unzip tools turn into odd file names
$archive = [IO.Compression.ZipFile]::Open($zip, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in Get-ChildItem $stage -File | Sort-Object Name) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, "$name/$($file.Name)", [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $archive.Dispose() }
Remove-Item $stage -Recurse -Force

$zipHash = (Get-FileHash $zip -Algorithm SHA256).Hash
# sha256sum format, one file per line
"$zipHash  $zipName`r`n$batHash  Saudi_Fix.bat`r`n" | Set-Content -Path (Join-Path $dist 'SHA256.txt') -Encoding ASCII -NoNewline

Write-Host ''
Write-Host "Release ready: $zip" -ForegroundColor Green
Write-Host "ZIP SHA256:           $zipHash"
Write-Host "Saudi_Fix.bat SHA256: $batHash"
