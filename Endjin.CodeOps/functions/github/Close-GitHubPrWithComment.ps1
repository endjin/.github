function Close-GitHubPrWithComment
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $true, ParameterSetName = 'PrObject')]
        $InputObject,

        [Parameter(Mandatory=$true, ParameterSetName = 'PrNumber')]
        [string] $OrgName,
        
        [Parameter(Mandatory=$true,ParameterSetName = 'PrNumber')]
        [string] $RepoName,

        [Parameter(Mandatory=$true, ParameterSetName = 'PrNumber')]
        [int] $PrNumber,

        [Parameter()]
        [string] $Comment,

        [Parameter()]
        [switch] $WhatIf
    )

    if ($PSCmdlet.ParameterSetName -eq 'PrObject') {
        # validate the passed object is a pull-request
        if ($InputObject._links.self.href -match ".*/pulls/\d+$") {
            $prUri = $InputObject._links.self.href
            $prCommentUri = $InputObject._links.comments.href
        }
        else {
            throw "The passed object did not have a URL matching a pull request: $($InputObject._links.self.href)"
        }
    }
    else {
        $prUri = "https://api.github.com/repos/$OrgName/$RepoName/pulls/$PrNumber"
        $prCommentUri = "https://api.github.com/repos/$OrgName/$RepoName/issues/$PrNumber/comments"
    }

    if (-not $WhatIf) {
        $resp = Invoke-GitHubRestRequest -Url $prUri `
                                         -Verb PATCH `
                                         -Body ( @{state = 'closed'} | ConvertTo-Json -Compress )

        if ($Comment) {
            $resp = Invoke-GitHubRestRequest -Url $prCommentUri `
                                             -Verb POST `
                                             -Body ( @{body = $Comment} | ConvertTo-Json -Compress)
        }
    }
    else {
        Write-Host "Would have closed PR #$($pr.number) [using parameterset: $($PSCmdlet.ParameterSetName)]"
    }
}