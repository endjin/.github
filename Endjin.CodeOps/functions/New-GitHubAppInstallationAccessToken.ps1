function New-GitHubAppInstallationAccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string] $AppId,

        [Parameter(Mandatory=$True)]
        [string] $AppPrivateKey,

        [Parameter(Mandatory=$True)]
        [string] $OrgName
    )

    $jwt = New-GitHubJWT -Issuer $AppId `
                         -PrivateKeyPem $AppPrivateKey `
                         -ValidforSeconds 300

    $bearerHeaders = @{
        Authorization = "Bearer $jwt"
        Accept = 'application/vnd.github.machine-man-preview+json'
    }

    # Use JWT to get list of avaiable installations for this GitHub App
    Write-Verbose "Looking-up InstallationId for $OrgName"
    $resp = Invoke-WebRequest `
                  -Headers $bearerHeaders `
                  -Method GET `
                  -Uri 'https://api.github.com/app/installations' `
                  -Verbose:$False

    # Lookup the installationId for the required GitHub Org
    $installation = $resp.Content | ConvertFrom-Json | Where-Object { $_.account.login -eq $OrgName }
    if (!$installation) {
        throw ("The GitHub App is not installed in the '{0}' organisation" -f $OrgName)
    }
    $installationId = $installation.id
    Write-Verbose ("InstallationId: {0}" -f $installationId)
              
    # Request an installation token
    Write-Verbose "Requesting InstallationAccessToken for $installationId"
    $resp = Invoke-WebRequest `
                  -Headers $bearerHeaders `
                  -Method POST `
                  -Uri "https://api.github.com/app/installations/$installationId/access_tokens" `
                  -Verbose:$False
    $installationToken = ($resp | ConvertFrom-Json).token

    return $installationToken
}
