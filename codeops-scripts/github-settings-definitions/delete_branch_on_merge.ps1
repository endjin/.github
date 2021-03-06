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

    # under normal circumstance the policy will enforce this value for the 'delete_branch_on_merge' setting
    $requiredValue = $true

    $result = @{
        is_compliant = ""
        before = ""
        after = ""
        expected = $requiredValue
        skipped = !$SettingValue
    }

    if ($SettingValue -eq $true) {
        Write-Verbose "Checking 'delete_branch_on_merge' setting"
        $current = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$Org/$RepoName"
        $result.before = $current.delete_branch_on_merge
        if ($current.delete_branch_on_merge -ne $requiredValue) {
            Write-Verbose "Updating 'delete_branch_on_merge' setting"
            $result.is_compliant = $false
            if ($PSCmdlet.ShouldProcess($RepoName, 'delete_branch_on_merge')) {
                $resp = Invoke-GitHubRestMethod -Uri "https://api.github.com/repos/$Org/$RepoName" `
                    -Verb PATCH `
                    -Body @{delete_branch_on_merge = $requiredValue }
                $result.after = $resp.delete_branch_on_merge
            }
            else {
                $result.after = "[DRY-RUN-MODE]"
            }
        }
        else {
            # already up-to-date
            $result.is_compliant = $true
            $result.after = $requiredValue
        }
    }

    return $result
}