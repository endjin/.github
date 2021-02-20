function Assert-ResourceGroupWithRbac
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [Parameter(Mandatory=$true)]
        [string] $Location,

        [Parameter(Mandatory=$true)]
        [string] $ServicePrincipalName,

        [Parameter(Mandatory=$true)]
        [string] $RoleName,

        [Parameter()]
        [hashtable] $ResourceTags
    )

    $existingRg = Get-AzResourceGroup -Location $Location | `
                            Where-Object { $_.ResourceGroupName -eq $Name }

    if (!$existingRg) {
        if ($PSCmdlet.ShouldProcess("Create Resource Group", $Name)) {
            $existingRg = New-AzResourceGroup -Name $Name -Location $Location -Tags $ResourceTags
        }        
    }

    if (!$existingRg -and -not $WhatIf) {
        throw "Unexpected error - the resource group $Name in $Location could not be found"
    }
    elseif ($existingRg) {
        $existingRbac = Get-AzRoleAssignment -Scope $existingRg.Id `
                                                -RoleDefinitionName $RoleName `
                                                -ServicePrincipalName $ServicePrincipalName
    }
    else {
        $existingRbac = $null
    }
    
    if (!$existingRbac) {
        if ($PSCmdlet.ShouldProcess("Assign Role", $RoleName)) {
            $assignment = New-AzRoleAssignment -Scope $existingRg.Id `
                                                -RoleDefinitionName $RoleName `
                                                -ServicePrincipalName $ServicePrincipalName
        }
    }
}