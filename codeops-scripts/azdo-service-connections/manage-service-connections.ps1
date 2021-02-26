# <copyright file="manage-service-connections.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Executes a GitOps-based process for managing Azure DevOps Service Connections and their permissions.

.DESCRIPTION
Reads the associated YAML configuration files that define the required service connections.  Each service
connection can define the permissions

.PARAMETER ConfigPath
The path to the directory containing your YAML configuration files.

.PARAMETER AadTenantId
The Azure TenantId where the Azure DevOps instance resides.

.PARAMETER AllowSecretReset
When specified, pre-existing service principals associated to new service connections will have their
secret reset, so it can be provided to Azure DevOps.  When not specified, this scenario will cause a 
terminating error. 

.PARAMETER DryRun
When specified, allows changes to be evaluated for their impact. Instead of applying changes, you will be
notified of when changes to Azure DevOps, Azure Active Directory or Azure Resources would be made.

.PARAMETER CorvusModulePath
Reserved for development and testing purposes.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string] $ConfigPath,

    [Parameter(Mandatory=$true)]
    [guid] $AadTenantId,

    [Parameter()]
    [switch] $AllowSecretReset,

    [Parameter()]
    [switch] $DryRun,

    [Parameter()]
    [string] $CorvusModulePath
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 4.0

#region module setup
if (!$CorvusModulePath) {
    # Ensure we have the required version of the Corvus.Deployment PowerShell module
    $corvusDeploymentModule = "Corvus.Deployment"
    $corvusDeploymentModulePackageVersion = "0.3.2"
    $corvusDeploymentModuleVersion,$corvusDeploymentModulePrereleaseTag = $corvusDeploymentModulePackageVersion -split "-",2
    $existingInstalled = Get-Module -ListAvailable $corvusDeploymentModule | `
                            Where-Object { $_.Version -eq $corvusDeploymentModuleVersion }
    if ($null -eq $existingInstalled) {
        Write-Verbose ("Installing required module: {0} v{1}" -f $corvusDeploymentModule, $corvusDeploymentModuleVersion)
        $installArgs= @{
            Name = $corvusDeploymentModule
            Scope = "CurrentUser"
            Force = $true
            RequiredVersion = $corvusDeploymentModulePackageVersion
            AllowPrerelease = ($corvusDeploymentModulePackageVersion -match "-")
            Repository = "PSGallery"
        }
        Install-Module @installArgs
        $existingInstalled = Get-Module -ListAvailable $corvusDeploymentModule | ? { $_.Version -eq $corvusDeploymentModuleVersion }
    }
    $CorvusModulePath = Join-Path (Split-Path -Parent $existingInstalled.Path) "$corvusDeploymentModule.psd1"
}
Import-Module $CorvusModulePath -Verbose:$false -Force

# Install other required PowerShell modules
$requiredModules = @(
    @{Name="powershell-yaml"; Version="0.4.2"}
)
foreach ($requiredModule in $requiredModules) {
    $module = Assert-CorvusModule -Name $requiredModule.Name `
                                  -Version $requiredModule.Version
    $module | Import-Module -Verbose:$false -Force
}
#endregion

#region helper functions
function processManagementGroup
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [Parameter(Mandatory=$true)]
        [string[]] $ArmRoles,

        [Parameter(Mandatory=$true)]
        [string] $ServicePrincipalName
    )

    Write-Host "Processing management group: $Name"
    foreach ($armRole in $ArmRoles) {
        $mg = Get-AzManagementGroup | Where-Object { $_.DisplayName -eq $Name }
        if ($mg) {
            $existingAssignment = Get-AzRoleAssignment -Scope $mg.Id `
                                                        -RoleDefinitionName $armRole `
                                                        -ServicePrincipalName $ServicePrincipalName
            if (!$existingAssignment) {
                if ($PSCmdlet.ShouldProcess($armRole, "Assign Role")) {
                    $roleAssignment = New-AzRoleAssignment -Scope $mg.Id `
                                                            -RoleDefinitionName $armRole `
                                                            -ServicePrincipalName $ServicePrincipalName
                }
            }
            
        }
        else {
            Write-Warning "The management group $Name could not be found"
        }
    }
}

function processSubscriptions
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [Parameter(Mandatory=$true)]
        [guid] $Id,

        [Parameter(Mandatory=$true)]
        [string] $ServicePrincipalName,

        [Parameter(Mandatory=$true)]
        [hashtable[]] $ResourceGroups
    )

    Write-Host "Processing subscription: $Name [$Id]"
    foreach ($resourceGroup in $ResourceGroups) {
        processResourceGroups -Name $resourceGroup.name `
                                -Location $resourceGroup.location `
                                -ArmRole $resourceGroup.arm_roles `
                                -ServicePrincipalName $ServicePrincipalName
    }
}

function processResourceGroups
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [Parameter(Mandatory=$true)]
        [string] $Location,

        [Parameter(Mandatory=$true)]
        [string] $ServicePrincipalName,

        [Parameter(Mandatory=$true)]
        [string[]] $ArmRoles
    )

    Write-Host "Processing resource group: $Name"
    foreach ($armRole in $ArmRoles) {
        Write-Host "Processing ARM role assignment: $armRole"
        $res = Assert-CorvusResourceGroupWithRbac -Name $Name `
                                            -Location $Location `
                                            -RoleName $armRole `
                                            -ServicePrincipalName $ServicePrincipalName `
                                            -WhatIf:$DryRun
    }
}

function processApiPermissions
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [Parameter(Mandatory=$true)]
        [string] $ServicePrincipalName,

        [Parameter()]
        [string[]] $DelegatedPermissions = @(),

        [Parameter()]
        [string[]] $ApplicationPermissions = @()
    )

    $sp = Get-AzADServicePrincipal -ServicePrincipalName $ServicePrincipalName

    Write-Host "Processing '$Name' API permissions for '$($sp.DisplayName)' [$($sp.ApplicationId)]"
    Assert-CorvusAzureAdApiPermissions -ApiName $Name `
                                    -DelegatedPermissions $DelegatedPermissions `
                                    -ApplicationPermissions $ApplicationPermissions `
                                    -ApplicationId $sp.ApplicationId `
                                    -WhatIf:$DryRun
}
#endregion

#
# Main script starts here
#
$here = Split-Path -Parent $PSCommandPath

$configFiles = Get-ChildItem -Path $ConfigPath -Filter *.yml

foreach ($configFile in $configFiles) {
    Write-Host "Processing $configFile" -f Green
    $config = Get-Content $configFile | ConvertFrom-Yaml

    foreach ($entry in $config) {
        Connect-CorvusAzure -SubscriptionId $entry.subscriptions[0].id `
                            -AadTenantId $AadTenantId

        $serviceConnectionName = $entry.name
        $sc = Assert-CorvusAzdoServiceConnection -Name $serviceConnectionName `
                                        -Project $entry.project `
                                        -Organisation $entry.organisation `
                                        -ServicePrincipalName $serviceConnectionName `
                                        -AllowSecretReset:$AllowSecretReset `
                                        -WhatIf:$DryRun

        $sp = Get-AzADServicePrincipal -ApplicationId $sc.authorization.parameters.serviceprincipalid

        foreach ($mg in $entry.management_groups) {
            processManagementGroup -Name $mg.name `
                                    -ArmRoles $mg.arm_roles `
                                    -ServicePrincipalName $sp.ServicePrincipalNames[0] `
                                    -WhatIf:$DryRun
        }

        foreach ($sub in $entry.subscriptions) {
            Set-AzContext -SubscriptionId $sub.id -TenantId (Get-AzContext).Tenant.Id | Out-Null
            processSubscriptions -Name $sub.name `
                                    -Id $sub.id `
                                    -ResourceGroups $sub.resource_groups `
                                    -ServicePrincipalName $sp.ServicePrincipalNames[0]
        }

        foreach ($api in $entry.api_permissions) {
            processApiPermissions -Name $api.name `
                                  -ServicePrincipalName $sp.ServicePrincipalNames[0] `
                                  -DelegatedPermissions $api.delegated_permissions `
                                  -ApplicationPermissions $api.application_permissions
        }
    }
}

