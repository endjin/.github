#Requires -Modules @{ ModuleName="powershell-yaml"; ModuleVersion="0.4.2" }

[CmdletBinding()]
param (
    [string] $ConfigDirectory,
    [switch] $WhatIf
)
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $PSCommandPath

# Install other module dependencies
# $requiredModules = @(
#     "Endjin.CodeOps"
# )
# $requiredModules | ForEach-Object {
#     if ( !(Get-Module -ListAvailable $_) ) {
#         Install-Module $_ -Scope CurrentUser -Repository PSGallery -Force
#     }
#     Import-Module $_
# }

function delete_branch_on_merge
{
    if ($repo.githubSettings.delete_branch_on_merge -eq $true) {
        $current = Invoke-GitHubRestMethod -Url "https://api.github.com/repos/$($repo.org)/$repoName"
        if (-not $current.delete_branch_on_merge) {
            Write-Host "[MISSING-DELETE-BRANCH-ON-MERGE] $($repo.org)/$repoName"
            $resp = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$($repo.org)/$repoName" `
                                            -Verb PATCH `
                                            -Body @{delete_branch_on_merge=$true} `
                                            -WhatIf:$WhatIf
        }
        
    }
}

function master_branch_protection
{
    # We can only set branch protection on public repos
    if ($repo.githubSettings.master_branch_protection -eq $true) {
        $body = @{
            required_status_checks = @{
                strict = $true
                contexts = @()
            }
            enforce_admins = $true
            required_pull_request_reviews = @{
                dismissal_restrictions= @{
                    users = @()
                    teams = @()
                }
                dismiss_stale_reviews = $true
                require_code_owner_reviews = $false
                # required_approving_review_count = 1           # requires preview API to change this
            }
            restrictions = @{
                users = @()
                teams =  @()
                apps = @()
            }
        }
        $currentRepo = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$($repo.org)/$repoName"
        if ($currentRepo.private) {
            Write-Verbose "Repo '$($repo.org)/$repoName' is private - skipping branch protection settings"
        }
        else {
            Write-Verbose "Checking 'master' branch protection policy"
            $currentPolicy = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$($repo.org)/$repoName/branches/master/protection"
            if (-not $currentPolicy.protected) {
                # track policy breach
                Write-Host "[MISSING-MASTER-BRANCH-PROTECTION] $($repo.org)/$repoName"
            }
            # should we always set the policy even if one already exists?
            $resp = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$($repo.org)/$repoName/branches/master/protection" `
                                                -Verb PUT `
                                                -Body $body `
                                                -WhatIf:$WhatIf
        }
    }
}

function _getAllOrgReposWithDefaults
{
    $allRepos = Invoke-GitHubRestMethod -Uri "https://api.github.com/orgs/$org/repos?per_page=100" -AllPages | Select -ExpandProperty name
    $reposToProcess = @{}
    $allRepos | % { $reposToProcess += @{ "$_" = $defaultSettings } }

    return $reposToProcess
}

function _getAllOrgs
{
    # returns all the orgs that we want included in this process
    @(
        # "ais-dotnet"
        # "corvus-dotnet"
        "endjin"
        # "marain-dotnet"
        # "menes-dotnet"
        # "vellum-dotnet"
    )
}

function _mergeSettingsOverrides
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable] $RepoOverrides,

        [Parameter(Mandatory=$true)]
        [hashtable] $RepoDefaults
    )

    # Check each repo in the overrides collection and apply any overriden
    # 'settings' to the collection containing the default policy
    $RepoOverrides | `
        ? { $_.org -eq $org } | `
        ? { $_.ContainsKey("githubSettings") } | `
        % {
            $settings = $_.githubSettings
            $repoName = $_.name
            $settings.Keys | % {
                $RepoDefaults[$repoName].$_ = $settings[$_]
            }
        }

    return $RepoDefaults
}

function _main
{
    # Read all existing repo config that might have specific settings configured
    $reposFromYaml = [array](Get-AllRepoConfiguration -ConfigDirectory $ConfigDirectory -LocalMode | Where-Object { $_ })

    # Read all the repos across our orgs
    # $globalSettings = gc -raw  "$ConfigDirectory/global-settings.yml" | ConvertFrom-Yaml
    $allOrgs = _getAllOrgs

    # the list of settings that are enforced, by default
    $defaultSettings = @{
        delete_branch_on_merge = $true
        master_branch_protection = $true
    }

    $failedRepos = @()   
    foreach ($org in $allOrgs) {
        try {
            # When running in GitHub Actions we will need ensure the GitHub App is
            # authenticated for the current GitHub Org
            if ($env:SSH_PRIVATE_KEY -and $env:GITHUB_APP_ID) {
                Write-Host "Getting access token for organisation: '$org'"
                $accessToken = New-GitHubAppInstallationAccessToken -AppId $env:GITHUB_APP_ID `
                                                                    -AppPrivateKey $env:SSH_PRIVATE_KEY `
                                                                    -OrgName $org
                # gh cli authentcation uses this environment variable
                $env:GITHUB_TOKEN = $accessToken
            }

            # get a collection of all repos in the org, intially configure the default policy settings for each repo
            $reposToProcess = _getAllOrgReposWithDefaults
            
            # update $reposToProcess with any per-repo overrides defined in the yaml files
            $reposToProcess = _mergeSettingsOverrides

            # 'name' can be a YAML list for repos that share the same config settings
            foreach ($repo in $reposToProcess) {
                Write-Host "`nOrg: $org - Repo: $repo`n" -f green

                delete_branch_on_merge

                master_branch_protection
            }
        }
        catch {
            # Track the failed repo, before continuing with the rest
            $failedRepoName = '{0}/{1}' -f $repo.org, $repoName
            $failedRepos += $failedRepoName
            $ErrorActionPreference = "Continue"
            $errorMessage = "Processing the repository '$failedRepoName' reported the following error: $($_.Exception.Message)"
            Log-Error -Message $errorMessage
            Write-Error $errorMessage
            Write-Warning $_.ScriptStackTrace
            Write-Warning "Processing of remaining repositories will continue"
            $ErrorActionPreference = "Stop"
        }
    }

    if ($failedRepos.Count -gt 0) {
        $ErrorActionPreference = "Continue"
        $errorMessage = "The following repositories reported errors during processing:`n{0}" -f ($failedRepos -join "`n")
        Write-Error $errorMessage
        exit 1
    }
}

# Detect when dot sourcing the script, so we don't immediately execute anything when running Pester
if (!$MyInvocation.Line.StartsWith('. ')) {
    _main
    exit 0
}