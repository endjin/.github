function Assert-AzureAdApiPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("AzureGraph","MSGraph")]
        [string] $ApiName,

        [Parameter(Mandatory=$true)]
        [guid] $PermissionId,

        [Parameter(Mandatory=$true)]
        [guid] $SpnAppId
    )

    $apiLookup = @{
        "AzureGraph" = "00000002-0000-0000-c000-000000000000"
        "MSGraph" = "00000003-0000-0000-c000-000000000000"
    }

    # grant service principal API permissions
    # [hashtable[]]$requiredApiPermissions = @(
    #     # Azure Graph permissions
    #     @{ ApiId = "00000002-0000-0000-c000-000000000000"; PermissionId = "5778995a-e1bf-45b8-affa-663a9f3f4d04" }     # readDirDataPermissionId
    #     @{ ApiId = "00000002-0000-0000-c000-000000000000"; PermissionId = "824c81eb-e3f8-4ee6-8f6d-de7f50d565b7" }     # manageOwnAppsPermissionId
    # )

    # if ($requiresGroupMgmtPermissions) {
    #     # Microsoft Graph permissions
    #     $requiredApiPermissions += @{
    #         ApiId = "00000003-0000-0000-c000-000000000000"; PermissionId = "62a82d76-70ea-41e2-9197-370581804d09"      # groupReadWriteAll
    #     }               
    # }

    $existingApiPermissions = Invoke-AzCli "ad app permission list --id $SpnAppId" -asJson
    
    $permissionUpdated = _applyApiPermission `
                                    -apiId $apiLookup[$ApiName] `
                                    -apiPermission $PermissionId `
                                    -appId $SpnAppId `
                                    -existingPermissions $existingApiPermissions
        
        # if ($permissionUpdated) { $updated = $true }
    # }

    # if ($updated) {
    #     Write-Warning "An AAD admin will need to grant consent to the 'API permissions' in the Azure portal for the AAD app: $spnAppId"
    # }
}