[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string] $ConfigDirectory = (Join-Path -Resolve (Split-Path -Parent $PSCommandPath) 'repos/test'),

    [switch] $WhatIf
)
$ErrorActionPreference = 'Stop'

Import-Module powershell-yaml

$here = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path $here 'Endjin.CodeOps/Endjin.CodeOps.psd1'
Get-Module Endjin.CodeOps | Remove-Module -Force
Import-Module $modulePath

function _main
{
    $totalPrs = 0
    $totalDependabotPrs = 0
    try {
        $repos = Get-Repos -ConfigDirectory $ConfigDirectory
        foreach ($repo in $repos) {
            # When running in GitHub Actions we will need ensure the GitHub App is
            # authenticated for the current GitHub Org
            if ($env:SSH_PRIVATE_KEY -and $env:GITHUB_APP_ID) {
                Write-Host "`n`nGetting access token for organisation: '$($repo.org)'"
                $accessToken = New-GitHubAppInstallationAccessToken -AppId $env:GITHUB_APP_ID `
                                                                    -AppPrivateKey $env:SSH_PRIVATE_KEY `
                                                                    -OrgName $repo.org
                # gh cli authentcation uses this environment variable
                $env:GITHUB_TOKEN = $accessToken
            }
            elseif ( [string]::IsNullOrEmpty($env:GITHUB_TOKEN) -and !(Test-Path env:\GITHUB_WORKFLOW) ) {
                Write-Host "GITHUB_TOKEN environment variable not present - triggering interactive login..."
                gh auth login
                $ghConfig = Get-Content ~/.config/gh/hosts.yml -Raw | ConvertFrom-Yaml
                $env:GITHUB_TOKEN = $ghConfig."github.com".oauth_token
            }

            Write-Host (Invoke-GitHubRestRequest -Url "https://api.github.com/rate_limit" | ConvertFrom-Json | fl | Out-String)

            # 'name' can be a YAML list for repos that share the same config settings
            foreach ($repoName in $repo.name) {
                Write-Host ("`nChecking repo: {0}/{1}" -f $repo.org, $repoName) -f green

                try {
                    $resp = Invoke-GitHubRestRequest -Url "https://api.github.com/repos/$($repo.org)/$repoName/pulls?state=open"
                    $openPrs = $resp.Content | ConvertFrom-Json
                }
                catch {
                    Write-Warning "Error querying repo - skipping"
                    Write-Host "Message: $($_.Exception.Message)"
                    continue
                }
                $oldDependabotPrs = $openPrs | ? { $_.user.login -eq "dependabot-preview[bot]" }
                $totalPrs += $openPRs.Count
                if ($oldDependabotPrs) {
                    $totalDependabotPrs += $oldDependabotPrs.Count
                }

                Write-Host ("Found {0} old dependabot PRs from {1} open PRs" -f $oldDependabotPrs.Count, $openPrs.Count)
                foreach ($pr in $oldDependabotPrs) {
                    Write-Host "Closing PR #$($pr.number)"
                    $pr | Close-GitHubPrWithComment -Comment "Closed old Dependabot PR - repo migrated to GitHub-integrated version" `
                                                    -WhatIf:$WhatIf
                }
            }
        }

        Write-Host ("`n`n*** SUMMARY ***")
        Write-Host ("Closed {0} old dependabot PRs out of {1} total open PRs`n" -f $totalDependabotPrs, $totalPrs) -f green
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
