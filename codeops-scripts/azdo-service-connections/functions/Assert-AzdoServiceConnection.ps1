# <copyright file="Assert-AzdoGroupMembership.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Ensures that an Azure DevOps service connection exists for the specified project.

.DESCRIPTION
Ensures that an Azure DevOps service connection exists for the specified project.

.PARAMETER Name
The name of the service connection.

.PARAMETER Project
The name of the Azure DevOps project.

.PARAMETER Organisation
The name of the Azure DevOps organisation.

#>

function Assert-AzdoServiceConnection
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [Parameter(Mandatory=$true)]
        [string] $Project,

        [Parameter(Mandatory=$true)]
        [string] $Organisation,

        [Parameter(Mandatory=$true)]
        [string] $ServicePrincipalName,

        [Parameter()]
        [string] $ServicePrincipalSecret
    )


    $orgUrl = Get-AzdoOrganisationUrl $Organisation

    $serviceConnectionType = "azurerm"

    # $devopsExtensionInstalled = Invoke-AzCli "extension list --query=`"[?name=='azure-devops']`"" -asJson
    # if (!$devopsExtensionInstalled) {
    #     Write-Host "Installing the azure-devops cli extension..."
    #     Invoke-AzCli "extension add --name azure-devops" -asJson
    # }
    $extensionInfo = Assert-AzureCliExtension -Name "azure-devops"

    Write-Host "Checking for existing ADO service connection..."
    $lookupArgs = @(
        "devops service-endpoint list"
        "--organization `"$orgUrl`""
        "--project `"$Project`""
        "--query `"[?type=='$serviceConnectionType' && name=='$Name']`""
    )
    $existingAdoServiceConnection = Invoke-AzCli $lookupArgs -asJson

    if (!$existingAdoServiceConnection) {
        Write-Host "A new ADO service connection will be created"

        $existingSp = Get-AzADServicePrincipal -ServicePrincipalName $ServicePrincipalName
        
        # check we have the secret for the SPN
        if ($existingSp -and !$spSecret) {
            Write-Warning "The service principal already exists, but we do not have the secret - to proceed, its password must be reset"
            Read-Host "Press <RETURN> to reset the password for the '$name' SPN or <CTRL-C> to cancel"

            $updatedSp = Invoke-AzCli "ad sp credential reset --name $($existingSp.appId)" -asJson
            $spSecret = $updatedSp.password
        }

        # register ADO service connection
        $env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $spSecret
        $createArgs = @(
            "devops service-endpoint azurerm create"
            "--name $name"
            "--azure-rm-service-principal-id {0}" -f $existingSp.appId
            "--azure-rm-subscription-id {0}" -f $moduleContext.SubscriptionId
            "--azure-rm-subscription-name `"{0}`"" -f "tbc"
            "--azure-rm-tenant-id {0}" -f $moduleContext.TenantId
            "--organization `"$orgUrl`""
            "--project `"{0}`"" -f $Project
        )
        Write-Host "Registering new ADO Service Connection..."
        Invoke-AzCli createArgs
        # Write-Host ("Complete - see {0}/{1}/_settings/adminservices" -f $adoUrl, $adoProject)
    }
    else {
        Write-Host "ADO Service Connection already exists - skipping"
    }
}