function Get-RepoConfiguration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string] $ConfigDirectory,

        [Parameter(Mandatory=$True)]
        [string] $OrgName,

        [Parameter(Mandatory=$True)]
        [string] $RepoName,

        [Parameter()]
        [string] $ConfigRepoGitUrl,

        [Parameter()]
        [switch] $LocalMode
    )

    $allRepos = Get-AllRepoConfiguration -ConfigDirectory $ConfigDirectory `
                          -ConfigRepoGitUrl $ConfigRepoGitUrl `
                          -LocalMode:$LocalMode

    $repo = $allRepos | Where-Object { $_.org -ieq $OrgName -and $_.name -icontains $RepoName }

    return $repo
}