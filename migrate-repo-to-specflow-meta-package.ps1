#Requires -Modules @{ ModuleName="powershell-yaml"; ModuleVersion="0.4.2" }

param (
    [string] $ConfigDirectory,
    [string] $BranchName = "feature/specflow-metapackage",
    [switch] $WhatIf,
    [string] $PrTitle = "Migrate to Corvus.Testing.SpecFlow.NUnit",
    [string] $PrBody = "Migrating Specs projects to use Corvus.Testing.SpecFlow.NUnit meta package"
)

$here = Split-Path -Parent $PSCommandPath
Write-Host "Here: $here"

. (Join-Path $here functions.ps1)

function _repoChanges
{
    $specsProjects = Get-ChildItem -Recurse -Filter *.Specs.csproj

    foreach ($projectFile in $specsProjects) {
        [xml]$project = Get-Content -Raw -Path $projectFile
        
        $project.Project.ItemGroup.PackageReference | ? { $_.Include -in $packageRefsToRemove } | % { Write-Host ($_|fl|out-string) }
    }
}

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