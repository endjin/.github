function getDefaultSettingsPolicy
{
    # Returns the GitHub settings that will be applied as the default policy
    @{
        delete_branch_on_merge   = $true
        default_branch_protection = $true
    }
}