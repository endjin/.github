#Requires -Modules @{ ModuleName="powershell-yaml"; ModuleVersion="0.4.2" }

#
# This script is responsible for ensuring all GitHub repositories are
# configured as per a policy of defined repository settings.
#
# For example, enforcing a branch protection policy.
# 

[CmdletBinding()]
param (
    [string] $ConfigDirectory,
    [switch] $WhatIf
)
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $PSCommandPath

# Install other module dependencies
$requiredModules = @(
    @{ Name = "Endjin.CodeOps"; Version = "0.2.3" }
)
$requiredModules | ForEach-Object {
    if ( !(Get-Module -ListAvailable $_.Name | Where-Object { $_.Version -eq $_.Version }) ) {
        Install-Module -Name $_.Name `
                       -RequiredVersion $_.Version `
                       -AllowPrerelease:($_.Version -match '-') `
                       -Scope CurrentUser `
                       -Repository PSGallery `
                       -Force
    }
    Import-Module -Name $_.Name -RequiredVersion $_.Version
}


#
# Helper functions
#
function _getAllOrgReposWithDefaults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Org,

        [Parameter(Mandatory = $true)]
        [hashtable] $DefaultSettings
    )

    $allRepos = Invoke-GitHubRestMethod -Uri "https://api.github.com/orgs/$Org/repos?per_page=100" `
                                        -AllPages | `
                    Select-Object -ExpandProperty name
    $reposToProcess = @{}
    $allRepos | ForEach-Object {
        # add each repo to the main processing list with default settings policy applied
        # the defaults can be overridden by setting them in the YAML repo files
        $reposToProcess += @{ "$_" = $DefaultSettings.Clone() } 
    }

    return $reposToProcess
}
function _getAllOrgs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $YamlConfig
    )
    
    return ($YamlConfig.org | Select-Object -Unique)
}
function _mergeSettingsOverrides {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [hashtable[]] $RepoOverrides,

        [Parameter(Mandatory = $true)]
        [hashtable[]] $RepoDefaults
    )

    # Check each repo in the overrides collection and apply any overriden
    # 'settings' to the collection containing the main processing list
    # (that otherwise have the default policy applied)
    $RepoOverrides | Where-Object { $_ } | `
        Where-Object { $_.ContainsKey("githubSettings") } | `
        ForEach-Object {
            $settingOverrides = $_.githubSettings
            # A single override config entry could reference multiple repos
            $_.name | ForEach-Object {
                $repoName = $_
                $settingOverrides.Keys | ForEach-Object {
                    $RepoDefaults.$repoName[$_] = $settingOverrides[$_]
                }
            }
        }

    return $RepoDefaults
}
function _processOrg {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Org,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [hashtable[]] $RepoConfig
    )

    # get a collection of all repos in the org, intially configure the default policy settings for each repo
    $reposToProcess = _getAllOrgReposWithDefaults -Org $org -DefaultSettings $defaultSettings
            
    # update $reposToProcess with any per-repo overrides defined in the yaml files
    $reposToProcess = _mergeSettingsOverrides -RepoOverrides $RepoConfig -RepoDefaults $reposToProcess

    $orgResults = @{}
    # 'name' can be a YAML list for repos that share the same config settings
    foreach ($repoName in $reposToProcess.Keys) {

        Write-Host "`nOrg: $Org - Repo: $repoName`n" -f green

        $repoResults = @{}

        foreach ($settingKey in $reposToProcess[$repoName].Keys) {
            $setting = $reposToProcess[$repoName].$settingKey

            try {
                # dynamically call the handler which should be a function with the same name
                if (Test-Path function:/$settingKey) {
                    $settingResult = Invoke-Expression ('{0} -Org $Org -RepoName $repoName -Setting $setting -WhatIf:$WhatIf' -f $settingKey)

                    # add the results from the setting policy handler
                    $repoResults += @{ $settingKey = $settingResult }
                }
                else {
                    throw "The handler for '$settingKey' could not be found."
                }
            }
            catch {
                # set the error property on the result object
                $repoResults += @{ $setting = @{ error = $_.Exception.Message } }
            }
        }
        $orgResults += @{ $repoName = $repoResults }
    }
    return $orgResults
}

function _main {
    $runResults = [ordered]@{}
    $runMetadata = [ordered]@{ 
        start_time = [datetime]::UtcNow
        is_dry_run = [bool]$WhatIf
    }

    # Read all existing repo config that might have specific settings configured
    $reposFromYaml = [array](Get-AllRepoConfiguration -ConfigDirectory $ConfigDirectory -LocalMode | Where-Object { $_ })

    # Read all the repos across our orgs
    $allOrgs = _getAllOrgs $reposFromYaml

    $allOrgResults = [ordered]@{}
    foreach ($org in $allOrgs) {
        try {
            # When running in GitHub Actions we will need ensure the GitHub App is
            # authenticated for the current GitHub Org
            if ($env:SSH_PRIVATE_KEY -and $env:GITHUB_APP_ID) {
                Write-Host "Getting access token for organisation: '$org'"
                $accessToken = New-GitHubAppInstallationAccessToken -AppId $env:GITHUB_APP_ID `
                    -AppPrivateKey $env:SSH_PRIVATE_KEY `
                    -OrgName $org
                
                $env:GITHUB_TOKEN = $accessToken
            }

            [array]$orgRepoConfigs = $reposFromYaml | Where-Object { $_.org -eq $org }
            $orgResults = _processOrg -Org $org -RepoConfig $orgRepoConfigs
            $allOrgResults += @{ $org = $orgResults }
        }
        catch {
            Log-Error -Message $_.Exception.Message
            Write-Warning $_.ScriptStackTrace
            Write-Error $_.Exception.Message
        }
    }

    $runMetadata += @{ end_time = [datetime]::UtcNow }
    $runResults += @{ metadata = $runMetadata }
    $runResults += @{ orgs = $allOrgResults }

    # Produce a JSON report file
    $reportFile = "apply-github-settings-report.json"
    $runResults | ConvertTo-Json -Depth 30 | Out-File $reportFile -Force

    # Upload JSON report to datalake
    if ($env:DATALAKE_NAME -and $env:DATALAKE_SASTOKEN -and $env:DATALAKE_FILESYSTEM -and $env:DATALAKE_DIRECTORY) {
        Write-Host "Publishing report to datalake: $($env:DATALAKE_NAME)"
        $timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmssfff')
        # name the file differently for real runs and dry runs
        $filename = $WhatIf ? "dryrun-$timestamp.json" : "run-$timestamp.json"
        $uri = "https://{0}.blob.core.windows.net/{1}/{2}/github_settings/raw/{3}?{4}" -f $env:DATALAKE_NAME,
                                                                    $env:DATALAKE_FILESYSTEM,
                                                                    $env:DATALAKE_DIRECTORY,
                                                                    $filename,
                                                                    $env:DATALAKE_SASTOKEN
        $headers = @{ "x-ms-date" = [System.DateTime]::UtcNow.ToString("R"); "x-ms-blob-type" = "BlockBlob" }
        Invoke-RestMethod -Headers $headers -Uri $uri -Method PUT -Body (Get-Content -Raw -Path $reportFile)
    }
    else {
        Write-Host "Datalake publishing skipped, due to absent configuration"
    }
}

# Detect when dot sourcing the script, so we don't immediately execute anything when running Pester
if (!$MyInvocation.Line.StartsWith('. ')) {

    # Load the handler functions for each GitHub setting policy definition
    Get-ChildItem -Path $here/github-settings-definitions -Filter *.ps1 | ForEach-Object {
        Write-Verbose "Loading $($_.FullName)"
        . $_
    }

    # setup the default policy settings
    $defaultSettings = getDefaultSettingsPolicy

    _main
    exit 0
}
