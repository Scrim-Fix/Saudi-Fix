# Builds the release, then creates the GitHub Release with the ZIP and
# SHA256.txt attached. Needs Git and GitHub CLI (gh auth login done once).
# Usage: powershell -ExecutionPolicy Bypass -File tools\publish_release.ps1
# Saudi-Fix (c) 2026 - Rashid Alghamdi

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$repo = 'Scrim-Fix/Saudi-Fix'
Set-Location $root

& (Join-Path $PSScriptRoot 'build_release.ps1')

$version = [regex]::Match([IO.File]::ReadAllText((Join-Path $root 'Saudi_Fix.bat')), '(?m)^set "SF_VER=([^"]+)"').Groups[1].Value
$tag   = "v$version"
$zip   = Join-Path $root "dist\Saudi-Fix_v$version.zip"
$sums  = Join-Path $root 'dist\SHA256.txt'
$notes = Join-Path $root "docs\RELEASE_NOTES_$tag.md"
if (-not (Test-Path $notes)) { throw "Write $notes first" }

# the ZIP in the repo and the one attached to the release must be the same file
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m "Release $tag"
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
}
git push origin main
if ($LASTEXITCODE -ne 0) { throw 'git push failed' }

gh release view $tag --repo $repo *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Release $tag exists - replacing its files" -ForegroundColor Yellow
    gh release upload $tag $zip $sums --repo $repo --clobber
} else {
    gh release create $tag $zip $sums --repo $repo --title "Saudi-Fix $tag" --notes-file $notes --latest
}
if ($LASTEXITCODE -ne 0) { throw 'gh release failed' }

Write-Host ''
Write-Host "Published: https://github.com/$repo/releases/tag/$tag" -ForegroundColor Green
Write-Host "Direct download: https://github.com/$repo/releases/download/$tag/Saudi-Fix_v$version.zip"
