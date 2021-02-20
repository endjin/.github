[CmdletBinding()]
param (
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 4.0

# Ensure we have the required version of the Corvus.Deployment PowerShell module
$corvusDeploymentModule = "Corvus.Deployment"
$corvusDeploymentModulePackageVersion = "0.3.0"
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
$modulePath = Join-Path (Split-Path -Parent $existingInstalled.Path) "$corvusDeploymentModule.psd1"
Import-Module $modulePath -Verbose:$false -Force

# Install other required PowerShell modules
$requiredModules = @(
    @{Name="powershell-yaml"; Version="0.4.2"}
)
foreach ($requiredModule in $requiredModules) {
    $module = Assert-CorvusModule -Name $requiredModule.Name `
                                  -Version $requiredModule.Version
    $module | Import-Module -Verbose:$false -Force
}

#
# Main script starts here
#
$here = Split-Path -Parent $PSCommandPath

#TEMP
Get-ChildItem -Path "$here/functions" -Filter *.ps1 | % { Write-Host "Loading $($_.FullName)" -f yellow; . $_.FullName }

function processManagementGroups
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [Parameter(Mandatory=$true)]
        [string] $ServicePrincipalName
    )

    Write-Host "Processing management group: $Name"

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
        $res = Assert-ResourceGroupWithRbac -Name $Name `
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

        [Parameter()]
        [string[]] $DelegatedPermissions = @(),

        [Parameter()]
        [string[]] $ApplicationPermissions = @()
    )

    Write-Host "Processing API permissions for '$Name'"
    Write-Host "  Delegated Permissions: $($DelegatedPermissions -join ',')"
    Write-Host "  Application Permissions: $($ApplicationPermissions -join ',')"
}

function processServiceConnection
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Name
    )

    Write-Host "Processing service connection: $Name" -f Cyan
}

$configFiles = Get-ChildItem -Path $here -Filter *.yml

foreach ($configFile in $configFiles) {
    Write-Host "Processing $configFile" -f Green
    $config = Get-Content $configFile | ConvertFrom-Yaml

    foreach ($entry in $config) {
        $serviceConnectionName = $entry.name

        $servicePrincipal = processServiceConnection -Name $serviceConnectionName

        foreach ($mg in $entry.management_groups) {
            processManagementGroups -Name $mg.name
        }

        foreach ($sub in $entry.subscriptions) {
            processSubscriptions -Name $sub.name -Id $sub.id -ResourceGroups $sub.resource_groups -ServicePrincipalName $serviceConnectionName
        }

        foreach ($api in $entry.api_permissions) {
            processApiPermissions -Name $api.name `
                                  -DelegatedPermissions $api.delegated_permissions `
                                  -ApplicationPermissions $api.application_permissions
        }
    }
}

