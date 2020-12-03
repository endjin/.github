[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string] $ConfigDirectory = (Join-Path -Resolve (Split-Path -Parent $PSCommandPath) '../repos/test'),

    [ValidateNotNullOrEmpty()]
    [string] $BranchName = "feature/specflow-metapackage",

    [ValidateNotNullOrEmpty()]
    [string] $PrTitle = "Bump Corvus.Testing.SpecFlow.NUnit *MIGRATION-IGNORE-VERSIONS* from 0.0.0 to 0.0.1 in .github/workflows",

    [ValidateNotNullOrEmpty()]
    [string] $PrBody = "Migrating Specs projects to use Corvus.Testing.SpecFlow.NUnit meta package",

    [switch] $WhatIf
)
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $PSCommandPath

# Install other module dependencies
$requiredModules = @(
    "Endjin.GitHubActions"
    "Endjin.PRAutoflow"
    "Endjin.CodeOps"
)
$requiredModules | ForEach-Object {
    if ( !(Get-Module -ListAvailable $_) ) {
        Install-Module $_ -Scope CurrentUser -Repository PSGallery -Force
    }
    Import-Module $_
}

# The list of NuGet packages that are superceded/replaced by the single meta-package
$supercededPackages = @(
            'SpecFlow'
            'SpecFlow.NUnit'
            'SpecFlow.NUnit.Runners'
            'SpecFlow.Tools.MsBuild.Generation'
            'coverlet.msbuild'
            'Microsoft.NET.Test.Sdk'
            'Moq'
            'NUnit'
            'NUnit3TestAdapter'
            'Corvus.Testing.SpecFlow'
        )

function _getProjectFiles
{
    Get-ChildItem -Recurse -Filter *.Specs.csproj
}

function _saveProject
{
    Invoke-WithUsingObject ($sw = new-object System.IO.StreamWriter($projectFile)) {
        $sw.NewLine = "`n";
        $project.Save($sw)
    }
}

function _repoChanges
{
    $repoUpdated = $false
    $specsProjects = _getProjectFiles

    foreach ($projectFile in $specsProjects) {
        [xml]$project = Get-Content -Raw -Path $projectFile
        
        $originalRefs = $project.Project.ItemGroup.PackageReference | `
            Where-Object { $_.Include } | `
            ForEach-Object { '{0}.{1}' -f $_.Include, $_.Version }
        Write-Verbose "Original Refs:`n$($originalRefs -join [Environment]::NewLine)"

        # Add reference to SpecFlow meta package, looking-up the latest non-prerelease version
        $packageName = 'Corvus.Testing.SpecFlow.NUnit'
        $nugetApiResponse = (Invoke-WebRequest -Uri "https://api.nuget.org/v3-flatcontainer/$($packageName.ToLower())/index.json" -Verbose:$False ).Content | ConvertFrom-Json
        $latestStableVersion = $nugetApiResponse.Versions | Select-Object -Last 1
        $updated,$project = Add-VsProjectPackageReference -Project $project `
                                                            -PackageId $packageName `
                                                            -PackageVersion $latestStableVersion
                                                            
        # Remove the references that are superceded by the meta package
        foreach ($packageId in $supercededPackages) {
            $updated,$updatedProject = Remove-VsProjectPackageReference -Project $project -PackageId $packageId
            if ($updated) {
                $repoUpdated = $true
                $project = $updatedProject
            }
        }

        $updatedRefs = $project.Project.ItemGroup.PackageReference | `
            Where-Object { $_.Include } | `
            ForEach-Object { '{0}.{1}' -f $_.Include, $_.Version }

        if (Compare-Object $originalRefs $updatedRefs) {
            Write-Verbose "Updated Refs:`n$($updatedRefs -join [Environment]::NewLine)"
            Write-Host "Updating project: $projectFile"
            _saveProject
        }
        else {
            Write-Host "Project up-to-date"
        }
    }

    return $repoUpdated
}

function _main
{
    $failedRepos = @()

    $repos = Get-AllRepoConfiguration -ConfigDirectory $ConfigDirectory -LocalMode
    foreach ($repo in $repos) {
        try {
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
                if ($repo.specflowMetaPackageSettings.enabled) {
                    Write-Host ("`nProcessing repo: {0}/{1}" -f $repo.org, $repoName) -f green

                    Update-Repo `
                        -OrgName $repo.org `
                        -RepoName $repoName `
                        -BranchName $BranchName `
                        -RepoChanges (Get-ChildItem function:\_repoChanges).ScriptBlock `
                        -CommitMessage "Committing changes" `
                        -PrTitle $PrTitle `
                        -PrBody $PrBody `
                        -PrLabels "no_release" `
                        -WhatIf:$WhatIf

                    # Close any PRs relating to packages now encapsulated by the meta package
                    Write-Host "Searching Dependabot PRs for packages superceded by the meta package"
                    $resp = Invoke-GitHubRestRequest -Url "https://api.github.com/repos/$($repo.org)/$repoName/pulls?state=open"
                    $openPrs = $resp | ConvertFrom-Json
                    $dependabotPrs = $openPrs | Where-Object { $_.user.login -eq 'dependabot[bot]' }
                    foreach ($pr in $dependabotPrs) {
                        $name,$from,$to,$path = ParsePrTitle $pr.title
                        if ($name -in $supercededPackages) {
                            Write-Host "Closing Dependabot PR #$($pr.number)"
                            $pr | Close-GitHubPrWithComment -Comment "Closed due to this repo being migrated to the SpecFlow meta-package" `
                                                            -WhatIf:$WhatIf
                        }
                    }
                }
                else {
                    Write-Host ("`nSkipping repo '{0}/{1}' due to 'specflowMetaPackageSettings.enabled' setting" -f $repo.org, $repoName) -f green
                }
            }
        }
        catch {
            # Track the failed repo, before continuing with the rest
            $failedRepoName = '{0}/{1}' -f $repo.org, $repoName
            $failedRepos += $failedRepoName
            $ErrorActionPreference = "Continue"
            Write-Error "Processing the repository '$failedRepoName' reported the following error: $($_.Exception.Message)"
            Write-Warning $_.ScriptStackTrace
            Write-Warning "Processing of remaining repositories will continue"
            $ErrorActionPreference = "Stop"
        }
    }

    if ($failedRepos.Count -gt 0) {
        $ErrorActionPreference = "Continue"
        Write-Error ("The following repositories reported errors during processing:`n{0}" -f ($failedRepos -join "`n"))
        exit 1
    }
}

# Detect when dot sourcing the script, so we don't immediately execute anything when running Pester
if (!$MyInvocation.Line.StartsWith('. ')) {
    _main
    exit 0
}