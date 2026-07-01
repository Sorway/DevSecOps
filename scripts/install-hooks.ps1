$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel
$hookSource = Join-Path $repoRoot "scripts/pre-commit.sh"
$hookTarget = Join-Path $repoRoot ".git/hooks/pre-commit"

if (-not (Test-Path -LiteralPath $hookSource)) {
    throw "Hook source introuvable: $hookSource"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $hookTarget) | Out-Null
Copy-Item -LiteralPath $hookSource -Destination $hookTarget -Force

Write-Host "Hook pre-commit installe: $hookTarget"
