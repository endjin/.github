[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string] $ConfigDirectory = (Join-Path -Resolve (Split-Path -Parent $PSCommandPath) '../repos/test'),

    [ValidateNotNullOrEmpty()]
    [string] $BranchName = "feature/sync-workflow-templates",

    [switch] $WhatIf
)
$ErrorActionPreference = 'Stop'

Import-Module powershell-yaml

$here = Split-Path -Parent $PSCommandPath

# Install other module dependencies
$requiredModules = @(
    "Endjin.CodeOps"
)
$requiredModules | ForEach-Object {
    if ( !(Get-Module -ListAvailable $_) ) {
        Install-Module $_ -Scope CurrentUser -Repository PSGallery -Force
    }
    Import-Module $_ -Force
}

function _repoChanges
{
    $destPath = Join-Path $pwd "workflow-templates"
    $srcPath = Join-Path $here "../workflow-templates" -Resolve
    if (!(Test-Path $destPath)) {
        New-Item -ItemType Directory $destPath
    }
    Copy-Item $srcPath/*.* $destPath -Recurse

    return $true
}

function _main
{
    try {
        $repoName = '.github'

        $repos = Get-AllRepoConfiguration -ConfigDirectory $ConfigDirectory -LocalMode
        # Templates are only deployed at the Org-level, so filter the repo list
        $orgsToUpdate = [array](($repos | Where-Object { $_.syncWorkflowTemplates -eq $true }).org | Select-Object -Unique)
        Write-Host "Orgs to process: $($orgsToUpdate.Count)`n`t$($orgsToUpdate -join "`n`t")"

        foreach ($org in $orgsToUpdate) {
            Write-Host ("`nProcessing Org: {0}" -f $org) -f green
            
            # When running in GitHub Actions we will need to ensure the GitHub App is
            # authenticated for the current GitHub Org
            if ($env:SSH_PRIVATE_KEY -and $env:GITHUB_APP_ID) {
                Write-Host "Getting access token for organisation: '$org'"
                $accessToken = New-GitHubAppInstallationAccessToken -AppId $env:GITHUB_APP_ID `
                                                                    -AppPrivateKey $env:SSH_PRIVATE_KEY `
                                                                    -OrgName $org
                # gh cli authentcation uses this environment variable
                $env:GITHUB_TOKEN = $accessToken
            }

            # When running in GitHub the workflow will pass the current GitVersion in an environment variable
            $to_version = [string]::IsNullOrEmpty($env:GITVERSION_NUGETVER) ? "0.0.0" : $env:GITVERSION_NUGETVER
            # We don't yet have a way to infer the current version, so we use a dummy 'from_version'
            $PrTitle = "Bump GitHub.Workflow.Templates from 0.0.0 to $to_version in .github/workflows"

            Update-Repo `
                -OrgName $org `
                -RepoName $repoName `
                -BranchName $BranchName `
                -RepoChanges (Get-ChildItem function:\_repoChanges).ScriptBlock `
                -CommitMessage "Updated workflow templates" `
                -PrTitle $PrTitle `
                -PrBody "Syncing latest versions of github actions workflow templates" `
                -WhatIf:$WhatIf
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
    exit 0
}