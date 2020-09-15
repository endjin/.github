function Get-Repos
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string] $ConfigDirectory
    )

    $repos = @()
    Get-ChildItem $ConfigDirectory -Recurse -Filter *.yml | ForEach-Object {
        $config = Get-Content -Raw -Path $_.FullName | ConvertFrom-Yaml
        $repos += $config.repos
    }

    return $repos
}