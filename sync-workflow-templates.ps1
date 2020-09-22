[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string] $ConfigDirectory = (Join-Path -Resolve (Split-Path -Parent $PSCommandPath) 'repos/test'),

    [ValidateNotNullOrEmpty()]
    [string] $BranchName = "feature/sync-workflow-templates",

    [ValidateNotNullOrEmpty()]
    [string] $PrTitle = "Bump GitHub.Workflow.Templates *IGNORE-VERSIONS* from 0.0.0 to 0.0.1 in .github/workflows",

    [ValidateNotNullOrEmpty()]
    [string] $PrBody = "Syncing latest versions of github actions workflow templates",

    [switch] $WhatIf
)
$ErrorActionPreference = 'Stop'

Import-Module powershell-yaml

$here = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path $here 'Endjin.CodeOps/Endjin.CodeOps.psd1'
Get-Module Endjin.CodeOps | Remove-Module -Force
Import-Module $modulePath

function _repoChanges
{
    if (!(Test-Path "$pwd/workflow-templates")) {
        New-Item -ItemType Directory "$pwd/workflow-templates"
    }
    Copy-Item $here/workflow-templates/*.* $pwd/workflow-templates -Recurse

    return $true
}

function _main
{
    try {
        $repoName = '.github'
        $repos = Get-AllRepoConfiguration -ConfigDirectory $ConfigDirectory -LocalMode
        foreach ($repo in $repos) {
            # When running in GitHub Actions we will need to ensure the GitHub App is
            # authenticated for the current GitHub Org
            if ($env:SSH_PRIVATE_KEY -and $env:GITHUB_APP_ID) {
                Write-Host "Getting access token for organisation: '$($repo.org)'"
                $accessToken = New-GitHubAppInstallationAccessToken -AppId $env:GITHUB_APP_ID `
                                                                    -AppPrivateKey $env:SSH_PRIVATE_KEY `
                                                                    -OrgName $repo.org
                # gh cli authentcation uses this environment variable
                $env:GITHUB_TOKEN = $accessToken
            }

            if ($repo.syncWorkflowTemplates) {
                Write-Host ("`nProcessing Org: {0}" -f $repo.org) -f green

                Update-Repo `
                    -OrgName $repo.org `
                    -RepoName $repoName `
                    -BranchName $BranchName `
                    -RepoChanges (Get-ChildItem function:\_repoChanges).ScriptBlock `
                    -CommitMessage "Committing changes" `
                    -PrTitle $PrTitle `
                    -PrBody $PrBody `
                    -WhatIf:$WhatIf
            }
        }
    }
    catch {
        $ErrorActionPreference = 'Continue'
        Write-Host "Error: $($_.Exception.Message)"
        Write-Warning $_.ScriptStackTrace
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Detect when dot sourcing the script, so we don't immediately execute anything when running Pester
if (!$MyInvocation.Line.StartsWith('. ')) {
    _main
}