$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# $sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
# . "$here\$sut"

. (Join-Path $here functions.ps1)

function _repoChanges
{
    $specsProjects = Get-ChildItem -Recurse -Filter *.Specs.csproj

    # TODO: lookup the latest nuget versions for each $packageRefToAdd
    $newRefs = @{}
    $packageRefsToAdd | % {
        $newRefs.Add($_, '1.0.2')
    }

    foreach ($projectFile in $specsProjects) {
        $isUpdated = $false

        Write-Host "`nProcessing project: $projectFile"
        [xml]$project = Get-Content -Raw -Path $projectFile
        
        $originalRefs = $project.Project.ItemGroup.PackageReference | % { @{PackageId=$_.Identity; Version=$_.Version} }
        Write-Verbose "Original Refs:`n$($originalRefs.PackageId -join [Environment]::NewLine)"

        foreach ($packageId in $packageRefsToRemove) {
            $project = Remove-VsProjectPackageRef -Project $project -PackageId $packageId
        }

        foreach ($packageId in $newRefs.Keys) {
            $project = Add-VsProjectPackageRef -Project $project -PacakgeId $packageId -Version $newRefs[$packageId]
        }

        $updatedRefs = $project.Project.ItemGroup.PackageReference | % { @{PackageId=$_.Identity; Version=$_.Version} }

        if ($updatedRefs -ne $originalRefs) {
            Write-Verbose "Updated Refs:`n$($updatedRefs.PackageId -join [Environment]::NewLine)"
            Write-Host "Updating project: $projectFile"
            $sw = new-object System.IO.StreamWriter $projectFile
            try {
                $sw.NewLine = "`n";
                $project.Save($sw)
            }
            finally {
                $sw.Dispose()
            }
        }
        else {
            Write-Host "Project up-to-date"
        }
        
    }
}

Describe 'Tests' {

    Context 'Simple' {

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

        $packageRefsToAdd = @(
            'Corvus.Testing.SpecFlow.NUnit'
        )

        $path = 'C:\_DATA\code\corvus\Corvus.Retry'
        Push-Location $path
        try {
            _repoChanges
        }
        finally {
            Pop-Location
        }

    }

}