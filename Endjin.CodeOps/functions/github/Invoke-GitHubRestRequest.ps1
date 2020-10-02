function Invoke-GitHubRestRequest
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [uri] $Url,

        [Parameter()]
        [string] $Verb = 'GET',

        [Parameter()]
        [string] $Body,

        [Parameter()]
        [string] $Token = $env:GITHUB_TOKEN
    )

    $headers = @{
        Authorization = "Token $Token"
        Accept = 'application/vnd.github.machine-man-preview+json'
    }

    $resp = Invoke-WebRequest -Headers $headers  `
                                -Method $Verb `
                                -Uri $Url `
                                -Body $Body

    $resp
}