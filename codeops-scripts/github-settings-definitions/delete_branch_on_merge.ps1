function delete_branch_on_merge {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        $SettingValue,

        [Parameter(Mandatory = $true)]
        [string] $Org,

        [Parameter(Mandatory = $true)]
        [string] $RepoName
    )

    if ($SettingValue -eq $true) {
        $current = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$Org/$RepoName"
        if (-not $current.delete_branch_on_merge) {
            if ($PSCmdlet.ShouldProcess($RepoName, 'delete_branch_on_merge')) {
                Write-Host "[MISSING-DELETE-BRANCH-ON-MERGE] $Org/$RepoName"
                $resp = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$Org/$RepoName" `
                    -Verb PATCH `
                    -Body @{delete_branch_on_merge = $true }
            }
        }
        
    }
}