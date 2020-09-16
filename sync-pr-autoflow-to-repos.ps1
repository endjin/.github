#Requires -Modules @{ ModuleName="powershell-yaml"; ModuleVersion="0.4.2" }

param (
    [string] $ConfigDirectory,
    [string] $BranchName = "feature/pr-autoflow",
    [switch] $AddOverwriteSettings,
    [switch] $ConfigureGitVersion,
    [switch] $ConfigureDependabotV2,
    [switch] $WhatIf,
    [string] $PrBody = "Syncing latest version of pr-autoflow"
)

$here = Split-Path -Parent $PSCommandPath
Write-Host "Here: $here"

Import-Module $here/Endjin.CodeOps

$repos = Get-Repos $ConfigDirectory

Write-Host "Repo count: " $repos.Count

$repos | ForEach-Object {
    $repo = $_

    # 'name' can be a YAML list for repos that share the same config settings
    foreach ($repoName in $repo.name) {
        Write-Host "`nOrg: $($repo.org) - Repo: $($repoName)`n" -f green

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

                $settings = @{}

                $repo.prAutoflowSettings.Keys | ForEach-Object {
                    $settings[$_] = @(,$repo.prAutoflowSettings[$_]) | ConvertTo-Json -Compress
                }

                ConvertTo-Json $settings | Out-File (New-Item ".github/config/pr-autoflow.json" -Force)
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

            # placeholder change to mimic existing behaviour whilst being compatible with the
            # change whereby Update-Repo expects a change notification flag
            return $true
        }

        $prLabels = @("no_release")

        $prTitle = "Bump Endjin.PRAutoflow from 1.0.0 to 1.0.1 in .github/workflows"

        Update-Repo `
            -RepoUrl "https://github.com/$($repo.org)/$($repoName).git" `
            -RepoChanges $repoChanges `
            -WhatIf:$WhatIf `
            -CommitMessage "Committing changes" `
            -PrTitle $prTitle `
            -PrBody $PrBody `
            -PrLabels $prLabels
    }
}