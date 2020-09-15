#Requires -Modules @{ ModuleName="powershell-yaml"; ModuleVersion="0.4.2" }

param (
    [string] $ConfigDirectory,
    [string] $BranchName = "feature/specflow-metapackage",
    [switch] $WhatIf,
    [string] $PrTitle = "Migrate to Corvus.Testing.SpecFlow.NUnit",
    [string] $PrBody = "Migrating Specs projects to use Corvus.Testing.SpecFlow.NUnit meta package",
    [switch] $PesterMode
)

$here = Split-Path -Parent $PSCommandPath
Write-Host "Here: $here"

Import-Module $here/Endjin.CodeOps

function _getProjectFiles
{
    Get-ChildItem -Recurse -Filter *.Specs.csproj
}

function _saveProject
{
    Using-Object ($sw = new-object System.IO.StreamWriter($projectFile)) {
        $sw.NewLine = "`n";
        $project.Save($sw)
    }
}

function _repoChanges
{
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
            $project = Remove-VsProjectPackageReference -Project $project -PackageId $packageId
        }

        # Add reference to SpecFlow meta package, looking-up the latest non-prerelease version
        $packageName = 'Corvus.Testing.SpecFlow.NUnit'
        $nugetApiResponse = (Invoke-WebRequest -Uri "https://api.nuget.org/v3-flatcontainer/$($packageName.ToLower())/index.json").Content | ConvertFrom-Json
        $latestStableVersion = $nugetApiResponse.Versions | Select-Object -Last 1
        $project = Add-VsProjectPackageReference -Project $project `
                                                 -PackageId $packageName `
`                                                 -PackageVersion $latestStableVersion

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
}

function _main
{
    $repos = Get-Repos -ConfigDirectory $ConfigDirectory
    foreach ($repo in $repos) {
        Write-Host ('`nProcessing repo: {0}/{1}' -f $repo.org, $repo.name)

        Update-Repo `
            -RepoUrl "https://github.com/$($repo.org)/$($repo.name).git" `
            -BranchName $BranchName `
            -RepoChanges (Get-ChildItem function:\_repoChanges).ScriptBlock `
            -WhatIf:$WhatIf `
            -CommitMessage "Committing changes" `
            -PrTitle $PrTitle `
            -PrBody $PrBody `
            -PrLabels "no_release"
    }
}

if (!$MyInvocation.Line.StartsWith('. ')) {
    _main
}