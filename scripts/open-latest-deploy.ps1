param(
  [string]$Repo = "JanRPedersen/DBSPortal",
  [string]$Workflow = "azure-webapps-node.yml"
)

$ErrorActionPreference = "Stop"
$ghExe = "C:\Program Files\GitHub CLI\gh.exe"

if (-not (Test-Path $ghExe)) {
  Write-Host "GitHub CLI blev ikke fundet: $ghExe" -ForegroundColor Yellow
  exit 1
}

& $ghExe auth status | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Du er ikke logget ind i GitHub CLI." -ForegroundColor Yellow
  Write-Host "Koer denne kommando og proev igen:"
  Write-Host "`"$ghExe`" auth login --web"
  exit 1
}

$runOutput = & $ghExe run list --repo $Repo --workflow $Workflow --limit 1 --json url,status,conclusion,headBranch,headSha,createdAt,updatedAt
if ($LASTEXITCODE -ne 0) {
  Write-Host "Kunne ikke hente workflow-runs fra GitHub." -ForegroundColor Yellow
  exit 1
}

$run = $runOutput | ConvertFrom-Json | Select-Object -First 1

if (-not $run) {
  Write-Host "Ingen workflow-runs fundet for $Workflow i $Repo" -ForegroundColor Yellow
  exit 1
}

Write-Host "Aabner seneste deploy-run..." -ForegroundColor Cyan
Write-Host "Status: $($run.status)"
Write-Host "Conclusion: $($run.conclusion)"
Write-Host "Branch: $($run.headBranch)"
Write-Host "Commit: $($run.headSha)"
Write-Host "URL: $($run.url)"

Start-Process $run.url
