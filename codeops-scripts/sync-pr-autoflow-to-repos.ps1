#Requires -Modules @{ ModuleName="powershell-yaml"; ModuleVersion="0.4.2" }

[CmdletBinding()]
param (
    [string] $ConfigDirectory,
    [string] $BranchName = "feature/pr-autoflow",
    [switch] $AddOverwriteSettings,
    [switch] $ConfigureGitVersion,
    [switch] $ConfigureDependabotV2,
    [switch] $WhatIf,
    [string] $PrBody = "Syncing latest version of pr-autoflow"
)
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $PSCommandPath

# Install other module dependencies
$requiredModules = @(
    "Endjin.CodeOps"
)
$requiredModules | ForEach-Object {
    if ( !(Get-Module -ListAvailable $_) ) {
        Install-Module $_ -Scope CurrentUser -Repository PSGallery -Force
    }
    Import-Module $_
}

function _repoChanges($OrgName, $RepoName)
{
    Write-Host "Adding/overwriting workflow files"
    $workflowTemplatesFolder = Join-Path $here "../workflow-templates" -Resolve
    $workflowsFolder = ".github/workflows"
    if (!(Test-Path $workflowsFolder)) {
        New-Item $workflowsFolder -Force -ItemType Directory
    }

    @("auto_merge.yml", "auto_release.yml", "dependabot_approve_and_label.yml") | ForEach-Object {
        $src = Join-Path $workflowTemplatesFolder $_
        $dest = Join-Path $workflowsFolder $_
        Copy-Item $src $dest -Force
    }

    if ($AddOverwriteSettings) {
        Write-Host "Adding/overwriting pr-autoflow.json settings"

        # To avoid un-necessary file changes (due to the non-deterministic ordering in hashtables) ensure the keys are ordered
        $settings = [ordered]@{}
        $repo.prAutoflowSettings.Keys | Sort-Object | ForEach-Object {
            $settings[$_] = @(,$repo.prAutoflowSettings[$_]) | ConvertTo-Json -Compress
        }

        $settings | ConvertTo-Json | Out-File (New-Item ".github/config/pr-autoflow.json" -Force)
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

        $defaultBranch = Get-GitHubRepoDefaultBranch -OrgName $OrgName -RepoName $RepoName

        $gitVersionConfig = [ordered]@{
            mode = "ContinuousDeployment";
            branches = [ordered]@{
                master = [ordered]@{
                    regex = "^{0}" -f $defaultBranch
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

        $dependabotConfig = [ordered]@{
            version = 2;
            updates = @(
                [ordered]@{ 
                    "package-ecosystem" = "nuget";
                    directory = "/Solutions";
                    schedule = [ordered]@{
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
function _main
{
    # The 'Where-Object' will filter out any null objects that might result from empty files
    $repos = [array](Get-AllRepoConfiguration -ConfigDirectory $ConfigDirectory -LocalMode | Where-Object { $_ })
    Write-Host "Repo count: " $repos.Count

    $failedRepos = @()
    
    $repos | ForEach-Object {
        try {
            $repo = $_

            # When running in GitHub Actions we will need ensure the GitHub App is
            # authenticated for the current GitHub Org
            if ($env:SSH_PRIVATE_KEY -and $env:GITHUB_APP_ID) {
                Write-Host "Getting access token for organisation: '$($repo.org)'"
                $accessToken = New-GitHubAppInstallationAccessToken -AppId $env:GITHUB_APP_ID `
                                                                    -AppPrivateKey $env:SSH_PRIVATE_KEY `
                                                                    -OrgName $repo.org
                # gh cli authentcation uses this environment variable
                $env:GITHUB_TOKEN = $accessToken
            }

            # 'name' can be a YAML list for repos that share the same config settings
            foreach ($repoName in $repo.name) {
                Write-Host "`nOrg: $($repo.org) - Repo: $($repoName)`n" -f green

                if ($repo.githubSettings.delete_branch_on_merge -eq $true) {
                    Write-Host "Enabling 'delete_branch_on_merge' repo setting"
                    $resp = Invoke-GitHubRestRequest -Url "https://api.github.com/repos/$($repo.org)/$repoName" `
                                                    -Verb 'PATCH' `
                                                    -Body (@{delete_branch_on_merge=$true} | ConvertTo-Json -Compress)
                }

                $prLabels = @("no_release")

                # When running in GitHub the workflow will pass the current GitVersion in an environment variable
                $to_version = [string]::IsNullOrEmpty($env:GITVERSION_NUGETVER) ? "0.0.0" : $env:GITVERSION_NUGETVER
                # We don't yet have a way to infer the current version, so we use a dummy 'from_version'
                $prTitle = "Bump Endjin.PRAutoflow from 0.0.0 to $to_version in .github/workflows"

                if ($repo.Keys -inotcontains 'prAutoflowSettings') {
                    Write-Warning "Skipping pr-autoflow configuration due to no 'prAutoflowSettings' configuration"
                }
                elseif ($repo.prAutoflowSettings.Keys -icontains 'disabled' -and $repo.prAutoflowSettings.disabled -eq $true) {
                    Write-Host "Skipping pr-autoflow configuration due to 'prAutoflowSettings.disabled' setting"
                }
                else {
                    Update-Repo `
                        -OrgName $repo.org `
                        -RepoName $repoName `
                        -BranchName $BranchName `
                        -RepoChanges (Get-ChildItem function:\_repoChanges).ScriptBlock `
                        -RepoChangesArguments @($repo.org, $repoName) `
                        -WhatIf:$WhatIf `
                        -CommitMessage "Committing changes" `
                        -PrTitle $prTitle `
                        -PrBody $PrBody `
                        -PrLabels $prLabels

                    # Close any PRs opened by the previous version of Dependabot
                    $resp = Invoke-GitHubRestRequest -Url "https://api.github.com/repos/$($repo.org)/$repoName/pulls?state=open"
                    $openPrs = $resp | ConvertFrom-Json
                    $openPrs | Where-Object { $_.user.login -eq 'dependabot-preview[bot]' } | ForEach-Object {
                        Write-Host "Closing old Dependabot PR #$($_.number)"
                        $_ | Close-GitHubPrWithComment -Comment "Closed old Dependabot PR - repo migrated to GitHub-integrated version" `
                                                    -WhatIf:$WhatIf
                    }
                }
            }
        }
        catch {
            # Track the failed repo, before continuing with the rest
            $failedRepoName = '{0}/{1}' -f $repo.org, $repoName
            $failedRepos += $failedRepoName
            $ErrorActionPreference = "Continue"
            $errorMessage = "Processing the repository '$failedRepoName' reported the following error: $($_.Exception.Message)"
            Log-Error $errorMessage
            Write-Error $errorMessage
            Write-Warning $_.ScriptStackTrace
            Write-Warning "Processing of remaining repositories will continue"
            $ErrorActionPreference = "Stop"
        }
    }

    if ($failedRepos.Count -gt 0) {
        $ErrorActionPreference = "Continue"
        $errorMessage = "The following repositories reported errors during processing:`n{0}" -f ($failedRepos -join "`n")
        Log-Error $errorMessage
        Write-Error $errorMessage
        exit 1
    }
}

# Detect when dot sourcing the script, so we don't immediately execute anything when running Pester
if (!$MyInvocation.Line.StartsWith('. ')) {
    _main
    exit 0
}