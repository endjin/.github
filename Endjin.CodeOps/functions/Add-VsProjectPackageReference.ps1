function Add-VsProjectPackageReference
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [xml] $Project,

        [Parameter(Mandatory=$True)]
        [string] $PackageId,

        [Parameter(Mandatory=$True)]
        [Version] $PackageVersion
    )

    $updated = $false
    if ($PackageId -notin $project.Project.ItemGroup.PackageReference.Include) {
        Write-Host "Adding reference: '$PackageId' => '$PackageVersion'"
        $packageRefNode = $project.SelectSingleNode("/Project/ItemGroup/PackageReference")
        
        $newRefNode = $project.CreateElement('PackageReference')
        
        $includeAttr = $project.CreateAttribute('Include')
        $includeAttr.Value = $PackageId
        $versionAttr = $project.CreateAttribute('Version')
        $versionAttr.Value = $PackageVersion

        $newRefNode.Attributes.Append($includeAttr) | Out-Null
        $newRefNode.Attributes.Append($versionAttr) | Out-Null
        $packageRefNode.ParentNode.AppendChild($newRefNode) | Out-Null
        $updated = $true
    }
    else {
        $project.Project.ItemGroup.PackageReference | `
            Where-Object { $_.Include -eq $PackageId -and $_.Version -ne $PackageVersion } | `
            ForEach-Object {
                Write-Host "Updating reference version: '$PackageId' => '$PackageVersion'"
                $_.Version = $PackageVersion
                $updated = $true
            }
    }

    return $updated,$project
}
