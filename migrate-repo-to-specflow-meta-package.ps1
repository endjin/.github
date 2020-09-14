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
function _repoChanges
{
    $specsProjects = _getProjectFiles

    foreach ($projectFile in $specsProjects) {
        [xml]$project = Get-Content -Raw -Path $projectFile
        
        $originalRefs = $project.Project.ItemGroup.PackageReference | `
            ForEach-Object { @{PackageId=$_.Identity; Version=$_.Version} }
        Write-Verbose "Original Refs:`n$($originalRefs.PackageId -join [Environment]::NewLine)"

        foreach ($packageId in $packageRefsToRemove) {
            $project = Remove-VsProjectPackageRef -Project $project -PackageId $packageId
        }

        $newRefs = @{
            'Coruvs.Testing.SpecFlow.NUnit' = '1.0.0'
        }
        foreach ($packageId in $newRefs.Keys) {
            $project = Add-VsProjectPackageRef -Project $project `
                                               -PacakgeId $packageId `
                                               -Version $newRefs[$packageId]
        }

        $updatedRefs = $project.Project.ItemGroup.PackageReference | `
            ForEach-Object { @{PackageId=$_.Identity; Version=$_.Version} }

        if ($updatedRefs -ne $originalRefs) {
            Write-Verbose "Updated Refs:`n$($updatedRefs.PackageId -join [Environment]::NewLine)"
            Write-Host "Updating project: $projectFile"
            Using-Object ($sw = new-object System.IO.StreamWriter($projectFile)) {
                $sw.NewLine = "`n";
                $project.Save($sw)
            }
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

        Update-Repo `
            -RepoUrl "https://github.com/$($repo.org)/$($repo.name).git" `
            -RepoChanges (Get-ChildItem function:\_repoChanges).ScriptBlock `
            -WhatIf:$WhatIf `
            -CommitMessage "Committing changes" `
            -PrTitle $PrTitle `
            -PrBody $PrBody `
            -PrLabels "no_release"
    }
}

if (!$PesterMode) { _main }