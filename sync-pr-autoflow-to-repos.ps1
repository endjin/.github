#Requires -Modules @{ ModuleName="powershell-yaml"; ModuleVersion="0.4.2" }

param (
    [string] $ConfigFilePath,
    [string] $BranchName = "feature/pr-autoflow",
    [switch] $AddOverwriteSettings,
    [switch] $ConfigureGitVersion,
    [switch] $ConfigureDependabotV2,
    [switch] $WhatIf,
    [string] $PrTitle = "Adding/updating pr-autoflow",
    [string] $PrBody = "Syncing latest version of pr-autoflow"
)

$here = Split-Path -Parent $PSCommandPath
Write-Host "Here: $here"

Import-Module $here/Endjin.CodeOps

$config = Get-Content -Raw -Path $ConfigFilePath | ConvertFrom-Json

$config.repos | ForEach-Object {
    $repo = $_

    Write-Host "`nOrg: $($repo.org) - Repo: $($repo.name)`n"

    $repoChanges = {
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

        if ($ConfigureGitVersion) {
            Write-Host "Adding/overwriting GitVersion.yml"

            $tags = git tag

            $semVers = $tags | ForEach-Object { 
                try { 
                    [System.Management.Automation.SemanticVersion]::new($_) 
                } 
                catch { 
                    $Null
                }
            } | Where-Object {
                ($_ -ne $Null) -and (!$_.PreReleaseLabel)
            }

            if ($semVers) {
                $mostRecentSemVerTag = ($semVers | Sort-Object -Descending)[0]
                $majorMinor = "$($mostRecentSemVerTag.Major).$($mostRecentSemVerTag.Minor)"
            }
            else {
                $majorMinor = "0.1"
            }

            Write-Host "Setting next-version as $majorMinor"

            $gitVersionConfig = @{
                mode = "ContinuousDeployment";
                branches = @{
                    master = @{
                        tag = "preview";
                        increment = "patch";
                    }
                };
                "next-version" = $majorMinor
            }

            ConvertTo-YAML $gitVersionConfig | Out-File (New-Item "GitVersion.yml" -Force)
        }

        if ($ConfigureDependabotV2) {
            Write-Host "Adding/overwriting dependabot.yml"

            $dependabotConfig = @{
                version = 2;
                updates = @(
                    @{ 
                        "package-ecosystem" = "nuget";
                        directory = "/Solutions";
                        schedule = @{
                            interval = "daily"
                        };
                        "open-pull-requests-limit" = 10
                    }
                );
               
            }

            ConvertTo-YAML $dependabotConfig | Out-File (New-Item ".github/dependabot.yml" -Force)
        }
    }

    Update-Repo `
        -RepoUrl "https://github.com/$($repo.org)/$($repo.name).git" `
        -RepoChanges $repoChanges `
        -WhatIf:$WhatIf `
        -CommitMessage "Committing changes" `
        -PrTitle $PrTitle `
        -PrBody $PrBody `
        -PrLabels "no_release"
}