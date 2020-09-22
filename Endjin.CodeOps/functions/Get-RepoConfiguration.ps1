function Get-RepoConfiguration
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string] $OrgName,

        [Parameter(Mandatory=$True)]
        [string] $RepoName,

        [Parameter()]
        [string] $ConfigRepoGitUrl = 'https://github.com/endjin/.github',

        [Parameter()]
        [string] $ConfigDirectory = 'repos/live',

        [Parameter()]
        [switch] $LocalMode
    )

    $allRepos = Get-AllRepoConfiguration -ConfigDirectory $ConfigDirectory `
                                         -ConfigRepoGitUrl $ConfigRepoGitUrl `
                                         -LocalMode:$LocalMode

    $repo = $allRepos | Where-Object { $_.org -ieq $OrgName -and $_.name -icontains $RepoName }

    # remove other repo names that might be in the same config group
    $repo.name = $repo.name | Where-Object { $_ -imatch $RepoName }

    return $repo
}