param(
  [string]$Repo = "JanRPedersen/DBSPortal",
  [string]$Workflow = "azure-webapps-node.yml",
  [string]$AppName = "DBSPortal",
  [string]$ResourceGroup = ""
)

$ErrorActionPreference = "Stop"

$ghExe = "C:\Program Files\GitHub CLI\gh.exe"
$azCmd = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

function Write-Section([string]$Title) {
  Write-Host ""
  Write-Host "=== $Title ===" -ForegroundColor Cyan
}

Write-Section "GitHub Actions"
if (-not (Test-Path $ghExe)) {
  Write-Host "GitHub CLI blev ikke fundet: $ghExe" -ForegroundColor Yellow
} else {
  try {
    & $ghExe auth status | Out-Null
    & $ghExe run list --repo $Repo --workflow $Workflow --limit 1 --json status,conclusion,headBranch,headSha,createdAt,updatedAt,url | ConvertFrom-Json | ForEach-Object {
      if ($_ -and $_.Count -gt 0) {
        $run = $_[0]
        Write-Host "Repo: $Repo"
        Write-Host "Workflow: $Workflow"
        Write-Host "Status: $($run.status)"
        Write-Host "Conclusion: $($run.conclusion)"
        Write-Host "Branch: $($run.headBranch)"
        Write-Host "Commit: $($run.headSha)"
        Write-Host "Created: $($run.createdAt)"
        Write-Host "Updated: $($run.updatedAt)"
        Write-Host "URL: $($run.url)"
      } else {
        Write-Host "Ingen workflow-runs fundet." -ForegroundColor Yellow
      }
    }
  } catch {
    Write-Host "Kunne ikke laese GitHub Actions-status. Log ind med:" -ForegroundColor Yellow
    Write-Host "`"$ghExe`" auth login --web"
  }
}

Write-Section "Azure Web App"
if (-not (Test-Path $azCmd)) {
  Write-Host "Azure CLI blev ikke fundet: $azCmd" -ForegroundColor Yellow
} else {
  try {
    & $azCmd account show --output none

    if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
      $candidate = & $azCmd webapp list --query "[?name=='$AppName'].resourceGroup | [0]" -o tsv
      $ResourceGroup = "$candidate".Trim()
    }

    if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
      Write-Host "Kunne ikke finde resource group automatisk. Koer igen med -ResourceGroup <navn>." -ForegroundColor Yellow
    } else {
      $state = & $azCmd webapp show --name $AppName --resource-group $ResourceGroup --query "state" -o tsv
      $url = & $azCmd webapp show --name $AppName --resource-group $ResourceGroup --query "defaultHostName" -o tsv
      Write-Host "App: $AppName"
      Write-Host "Resource group: $ResourceGroup"
      Write-Host "State: $state"
      Write-Host "URL: https://$url"
    }
  } catch {
    Write-Host "Kunne ikke laese Azure-status. Log ind med:" -ForegroundColor Yellow
    Write-Host "`"$azCmd`" login"
  }
}

Write-Host ""
Write-Host "Tip: Koer scriptet saadan her:" -ForegroundColor DarkGray
Write-Host ".\\scripts\\check-deploy.ps1"
