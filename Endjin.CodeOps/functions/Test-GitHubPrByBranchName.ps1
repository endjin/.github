function Test-GitHubPrByBranchName
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $OrgName,
        
        [Parameter(Mandatory=$true)]
        [string] $RepoName,

        [Parameter(Mandatory=$true)]
        [string] $BranchName,

        [Parameter()]
        [ValidateSet("open", "closed", "all")]
        [string] $State = "open"
    )

    $prUri = "https://api.github.com/repos/$OrgName/$RepoName/pulls?state=$State"
    
    $resp = Invoke-GitHubRestRequest -Url $prUri
    
    # NOTE: This might be overly simplistic in the general case, as you could have PRs referencing the same branch name, but from different users/orgs.
    #       However, for the current use case this will be sufficient.
    $existingPr = $resp.Content | ConvertFrom-Json | Where-Object {
        $_.head.ref -eq $BranchName
    }

    if ($existingPr) { 
        return $true
    }
    else { 
        return $false
    }
}