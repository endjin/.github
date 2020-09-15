[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string] $ConfigDirectory = (Join-Path -Resolve (Split-Path -Parent $PSCommandPath) 'repos/test'),

    [ValidateNotNullOrEmpty()]
    [string] $BranchName = "feature/specflow-metapackage",

    [ValidateNotNullOrEmpty()]
    [string] $PrTitle = "Migrate to Corvus.Testing.SpecFlow.NUnit",

    [ValidateNotNullOrEmpty()]
    [string] $PrBody = "Migrating Specs projects to use Corvus.Testing.SpecFlow.NUnit meta package",

    [switch] $WhatIf
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path $here 'Endjin.CodeOps/Endjin.CodeOps.psd1'
Get-Module Endjin.CodeOps | Remove-Module -Force
Import-Module $modulePath

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

        # Remove the references that are superceded by the meta package
        $packageRefsToRemove = @(
            'SpecFlow'
            'SpecFlow.NUnit'
            'SpecFlow.Tools.MsBuild.Generation'
            'coverlet.msbuild'
            'Microsoft.NET.Test.Sdk'
            'Moq'
            'NUnit'
            'NUnit3TestAdapter'
        )
        foreach ($packageId in $packageRefsToRemove) {
            $updated,$updatedProject = Remove-VsProjectPackageReference -Project $project -PackageId $packageId
            if ($updated) {
                $repoUpdated = $true
                $project = $updatedProject
            }
        }

        # Add reference to SpecFlow meta package, looking-up the latest non-prerelease version
        $packageName = 'Corvus.Testing.SpecFlow.NUnit'
        $nugetApiResponse = (Invoke-WebRequest -Uri "https://api.nuget.org/v3-flatcontainer/$($packageName.ToLower())/index.json").Content | ConvertFrom-Json
        $latestStableVersion = $nugetApiResponse.Versions | Select-Object -Last 1
        $updated,$project = Add-VsProjectPackageReference -Project $project `
                                                          -PackageId $packageName `
`                                                         -PackageVersion $latestStableVersion

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
    try {
        $repos = Get-Repos -ConfigDirectory $ConfigDirectory
        foreach ($repo in $repos) {
            Write-Host ('`nProcessing repo: {0}/{1}' -f $repo.org, $repo.name)

            Update-Repo `
                -RepoUrl "https://github.com/$($repo.org)/$($repo.name).git" `
                -BranchName $BranchName `
                -RepoChanges (Get-ChildItem function:\_repoChanges).ScriptBlock `
                -CommitMessage "Committing changes" `
                -PrTitle $PrTitle `
                -PrBody $PrBody `
                -PrLabels "no_release" `
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
}