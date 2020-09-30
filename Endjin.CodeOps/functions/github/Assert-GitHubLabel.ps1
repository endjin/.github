function Assert-GitHubLabel
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string] $OrgName,

        [Parameter(Mandatory=$True)]
        [string] $RepoName,

        [Parameter(Mandatory=$True)]
        [string] $Name,

        [Parameter()]
        [string] $Description,

        [Parameter()]
        [string] $Color
    )

    $existingLabels = (Invoke-GitHubRestRequest -Url "https://api.github.com/repos/$OrgName/$RepoName/labels").Content | ConvertFrom-Json
    if ('no_release' -notin $existingLabels.name) {

        $body = @{
            name = $Name
            description = $Description
            color = $Color
        }
        $resp = Invoke-GitHubRestRequest -Url "https://api.github.com/repos/$OrgName/$RepoName/labels" `
                                         -Verb POST `
                                         -Body ($body | ConvertTo-Json -Compress)
    }
}