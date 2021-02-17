function default_branch_protection {
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

        # setup the payload for configuring branch protection
        $body = @{
            required_status_checks        = @{
                strict   = $true
                contexts = @()
            }
            enforce_admins                = $true
            required_pull_request_reviews = @{
                dismissal_restrictions     = @{
                    users = @()
                    teams = @()
                }
                dismiss_stale_reviews      = $true
                require_code_owner_reviews = $false
                # required_approving_review_count = 1           # requires preview API to change this
            }
            restrictions                  = @{
                users = @()
                teams = @()
                apps  = @()
            }
        }

        # We can only set branch protection on public repos
        $currentRepo = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$Org/$RepoName"
        if ($currentRepo.private) {
            Write-Verbose "Repo '$Org/$RepoName' is private - skipping branch protection settings"
        }
        else {
            $defaultBranch = Get-GitHubRepoDefaultBranch -OrgName $org -RepoName $RepoName

            Write-Verbose "Checking '$defaultBranch' branch protection policy"
            $currentPolicy = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$Org/$RepoName/branches/$defaultBranch/protection" `
                                                     -HttpErrorStatusCodesToIgnore @(404)
            
            # assess whether the current branch protection policy is adequate
            if ($null -eq $currentPolicy -or `
                $currentPolicy.required_status_checks.strict -ne $body.required_status_checks.strict -or `
                $currentPolicy.enforce_admins -eq $body.enforce_admins
            ) {
                # track policy breach & apply branch protection policy
                if ($PSCmdlet.ShouldProcess($RepoName, 'default_branch_protection')) {
                    Write-Host "[MISSING-MASTER-BRANCH-PROTECTION] $Org/$RepoName"
                    $resp = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$Org/$RepoName/branches/$defaultBranch/protection" `
                                                    -Verb PUT `
                                                    -Body $body
                }
            }
        }
    }
}