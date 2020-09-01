# read config json

# iterate repos
    # create temp folder
    # clone repo to temp folder
    # create feature branch
    # add/overwrite `dependabot_approve_and_label.yml`, `auto_merge.yml`, and `auto_release.yml` workflows in .github/workflows folder
    # (optional) add/overwrite `pr-autoflow.json` configuration in .github/config
    # commit and push changes (unless WhatIf = true)
    # open a PR to master (unless WhatIf = true)
    # delete temp folder

param (
    [string] $ConfigFilePath,
    [string] $BranchName = "feature/pr-autoflow",
    [switch] $AddOverwriteSettings,
    [switch] $WhatIf
)

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

$here = Split-Path -Parent $PSCommandPath
Write-Host "Here: $here"

$config = Get-Content -Raw -Path $ConfigFilePath | ConvertFrom-Json

$config.repos | ForEach-Object {
    $repo = $_

    Write-Host "`nOrg: $($repo.org) - Repo: $($repo.name)`n"

    $tempDir = New-TemporaryDirectory

    Push-Location $tempDir.FullName

    Write-Host "Created temporary directory: $($tempDir.FullName)"

    $repoUrl = "https://github.com/$($repo.org)/$($repo.name).git"
    Write-Host "Cloning: $repoUrl"
    git clone $repoUrl

    Set-Location $repo.name

    Write-Host "Creating new branch: $BranchName"
    git checkout -b $BranchName

    Write-Host "Adding/overwriting workflow files"
    $workflowsFolder = ".github/workflows"
    if (!(Test-Path $workflowsFolder)) {
        New-Item $workflowsFolder -Force -ItemType Directory
    }

    @("auto_merge.yml", "auto_release.yml", "dependabot_approve_and_label.yml") | ForEach-Object {
        $src = Join-Path $here "workflow-templates" $_
        $dest = Join-Path $workflowsFolder $_
        Copy-Item $src $dest -Force
    }

    if ($AddOverwriteSettings) {
        Write-Host "Adding/overwriting pr-autoflow.json settings"
        ConvertTo-Json $repo.settings | Out-File (New-Item ".github/config/pr-autoflow.json" -Force)
    }

    if (!$WhatIf) {
        Write-Host "Committing changes"
        git add .
        git commit -m "Adding/updating pr-autoflow"

        Write-Host "Opening new PR"
        gh pr create --title "Adding/updating pr-autoflow" --body "Syncing latest version of pr-autoflow$($AddOverwriteSettings ? ' and default config' : '')"
    }

    Pop-Location

    "Deleting temporary directory: $($tempDir.FullName)"
    Remove-Item $tempDir -Recurse -Force
}