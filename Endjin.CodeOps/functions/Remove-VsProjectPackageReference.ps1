function Remove-VsProjectPackageReference
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [xml] $Project,

        [Parameter()]
        [string] $PackageId
    )

    $project.Project.ItemGroup.PackageReference | `
        Where-Object { $_.Include -eq $PackageId } | `
        ForEach-Object {
            Write-Host "Removing reference: '$($_.Include)'"
            $refNode = $project.SelectSingleNode("/Project/ItemGroup/PackageReference[@Include='{0}']" -f $_.Include)
            $refNode.ParentNode.RemoveChild($refNode)
        }

    return $project
}