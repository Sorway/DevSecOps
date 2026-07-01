$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel
$binDir = Join-Path $repoRoot ".git/hooks/bin"
$tmpDir = Join-Path $repoRoot ".tmp-tools"
$headers = @{ "User-Agent" = "Codex" }

New-Item -ItemType Directory -Force -Path $binDir | Out-Null
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

function Download-GitHubAsset {
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][string]$AssetPattern,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $headers
    $asset = $release.assets | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1

    if (-not $asset) {
        throw "Asset introuvable pour $Repo avec le motif $AssetPattern"
    }

    Write-Host "Telechargement $Repo $($release.tag_name): $($asset.name)"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $OutputPath -Headers $headers
}

$actionlintArchive = Join-Path $tmpDir "actionlint.zip"
$gitleaksArchive = Join-Path $tmpDir "gitleaks.zip"
$actionlintExtract = Join-Path $tmpDir "actionlint"
$gitleaksExtract = Join-Path $tmpDir "gitleaks"

Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $actionlintExtract, $gitleaksExtract
New-Item -ItemType Directory -Force -Path $actionlintExtract, $gitleaksExtract | Out-Null

Download-GitHubAsset -Repo "rhysd/actionlint" -AssetPattern "windows_amd64\.zip$" -OutputPath $actionlintArchive
Download-GitHubAsset -Repo "gitleaks/gitleaks" -AssetPattern "windows_x64\.zip$" -OutputPath $gitleaksArchive

Expand-Archive -LiteralPath $actionlintArchive -DestinationPath $actionlintExtract -Force
Expand-Archive -LiteralPath $gitleaksArchive -DestinationPath $gitleaksExtract -Force

Copy-Item -LiteralPath (Join-Path $actionlintExtract "actionlint.exe") -Destination (Join-Path $binDir "actionlint.exe") -Force
Copy-Item -LiteralPath (Join-Path $gitleaksExtract "gitleaks.exe") -Destination (Join-Path $binDir "gitleaks.exe") -Force

& (Join-Path $binDir "actionlint.exe") -version
& (Join-Path $binDir "gitleaks.exe") version

Write-Host "Outils installes dans $binDir"
