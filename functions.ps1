function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Update-Repo {
    param (
        [string] $RepoUrl,
        [scriptblock]$RepoChanges,
        [switch] $WhatIf,
        [string] $CommitMessage,
        [string] $PrTitle,
        [string] $PrBody = " ",
        [string] $PrLabels
    )

    $tempDir = New-TemporaryDirectory

    Push-Location $tempDir.FullName

    Write-Host "Created temporary directory: $($tempDir.FullName)"

    Write-Host "Cloning: $RepoUrl"
    git clone $RepoUrl .

    Write-Host "Creating new branch: $BranchName"
    git checkout -b $BranchName

    $RepoChanges.Invoke()

    if (!$WhatIf) {
        Write-Host "Committing changes"
        git add .
        git commit -m $CommitMessage

        Write-Host "Opening new PR"
        $ghPrArgs = @("pr", "create", "--title", $PrTitle, "--body", $PrBody)
        if ($PrLabels) { $ghPrArgs += @("--label", $PrLabels) }
        gh @ghPrArgs
    }

    Pop-Location

    "Deleting temporary directory: $($tempDir.FullName)"
    Remove-Item $tempDir -Recurse -Force
}

function Add-VsProjectPackageReference
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $ProjectFile,

        [Parameter()]
        [string] $PackageId,

        [Parameter()]
        [Version] $PackageVersion
    )

    [xml]$project = Get-Content -Raw -Path $projectFile

    if ($PackageId -notin $project.Project.ItemGroup.PackageReference.Include) {
        Write-Host "Adding reference: '$PackageId' => '$PacakgeVersion'"
        $packageRefNode = $project.SelectSingleNode("/Project/ItemGroup/PackageReference")
        
        $newRefNode = $project.CreateElement('PackageReference')
        
        $includeAttr = $project.CreateAttribute('Include')
        $includeAttr.Value = $PackageId
        $versionAttr = $project.CreateAttribute('Version')
        $versionAttr.Value = $PackageVersion

        $newRefNode.Attributes.Append($includeAttr)
        $newRefNode.Attributes.Append($versionAttr)
        $packageRefNode.ParentNode.AppendChild($newRefNode)
    }
    else {
        Write-Host "Updating reference version: '$PackageId' => '$PacakgeVersion'"
        $project.Project.ItemGroup.PackageReference | `
            Where-Object { $_.Include -eq $PackageId } | `
            ForEach-Object { $_.Version = $PackageVersion }
    }

    return $project
}

function Remove-VsProjectPackageReference
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $ProjectFile,

        [Parameter()]
        [string] $PackageId
    )

    [xml]$project = Get-Content -Raw -Path $ProjectFile

    $project.Project.ItemGroup.PackageReference | `
        Where-Object { $_.Include -eq $PackageId } | `
        ForEach-Object {
            Write-Host "Removing reference: '$($_.Include)'"
            $refNode = $project.SelectSingleNode("/Project/ItemGroup/PackageReference[@Include='{0}']" -f $_.Include)
            $refNode.ParentNode.RemoveChild($refNode)
        }

    return $project
}