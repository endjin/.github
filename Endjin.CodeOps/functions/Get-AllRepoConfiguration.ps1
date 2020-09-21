function Get-AllRepoConfiguration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string] $ConfigDirectory,

        [Parameter()]
        [string] $ConfigRepoGitUrl = "https://github.com/endjin/.github",

        [Parameter()]
        [switch] $LocalMode
    )

    $repos = @()

    if (!$LocalMode) {
        # Download the central repo if we're not in local mode
        $tempDir = _CloneGitRepo $ConfigRepoGitUrl
    }
    try {
        # Process the file & folder structure in the repo
        Get-ChildItem $ConfigDirectory -Recurse -Filter *.yml | ForEach-Object {
            $config = Get-Content -Raw -Path $_.FullName | ConvertFrom-Yaml
            $repos += $config.repos
        }
    }
    finally {
        # Clean-up temp folder
        if ( !($LocalMode) -and (Test-Path $tempDir) ) {
            Pop-Location
            Write-Verbose "Deleting temporary directory: $($tempDir.FullName)"
            Remove-Item $tempDir -Recurse -Force
        }
    }

    return $repos
}