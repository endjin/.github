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

    # under normal circumstance the policy will enforce this value for the 'delete_branch_on_merge' setting
    $requiredValue = @{
        required_status_checks = @{ strict = $true }
        enforce_admins = $true
    }

    $result = @{
        fix_applied = $false
        before = ""
        after = ""
        expected = $requiredValue
        skipped = !$SettingValue
    }

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
            $result.before = $currentPolicy

            # assess whether the current branch protection policy is adequate
            if ($null -eq $currentPolicy -or `
                $currentPolicy.required_status_checks.strict -ne $body.required_status_checks.strict -or `
                $currentPolicy.enforce_admins -eq $body.enforce_admins
            ) {
                # track policy breach & apply branch protection policy
                $result.fix_applied = $true
                if ($PSCmdlet.ShouldProcess($RepoName, 'default_branch_protection')) {
                    $resp = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$Org/$RepoName/branches/$defaultBranch/protection" `
                                                    -Verb PUT `
                                                    -Body $body
                    $result.after = $resp
                }
                else {
                    $result.after = "[DRY-RUN-MODE]"
                }
            }
            else {
                # already up-to-date
                $result.after = $requiredValue
            }
        }
    }

    return $result
}