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
                        Where-Object { $_.Version -eq $corvusDeploymentModuleVersion -and `
                                        $_.PrivateData.PSData.Prerelease -eq $corvusDeploymentModulePrereleaseTag
                        }
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
    $existingInstalled = Get-Module -ListAvailable $corvusDeploymentModule | ? { $_.Version -eq $corvusDeploymentModuleVersion -and $_.PrivateData.PSData.Prerelease -eq $corvusDeploymentModulePrereleaseTag }
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

$azContext = Get-AzContext
$azContext | Format-List | Out-string | Write-Host
Assert-CorvusAzCliLogin -subscriptionId $azContext.Subscription.Id -aadTenantId $azContext.Tenant.Id | Out-Null

# Load the configuration files
$configFiles = Get-ChildItem -Path $here -Filter *.yml
foreach ($configFile in $configFiles) {
    Write-Verbose "Processing file: $configFile"
    $config = Get-Content $configFile | ConvertFrom-Yaml

    # Process each project found in the config file
    $projects = $config.projects | Where-Object { $_ } | ForEach-Object {
        $project = $_
        Write-Host "`nProcessing project: $($project.name)" -f Cyan
        # Ensure the project exists, creating it if necessary
        Assert-CorvusAzdoProject -Name $project.name `
                                 -Organisation $config.organisation `
                                 -WhatIf:$DryRun

        # Check we have valid 'groups' configuration
        if ($project.ContainsKey("groups") -and `
                $project.groups -is [hashtable] -and `
                $project.groups.Count -gt 0) {

            # Process the memberships for each project group in the config
            foreach ($group in $project.groups.Keys) {
                Write-Host "Processing group: $group" -f Green
                $result = Assert-CorvusAzdoGroupMembership -Name $group `
                                                            -Project $project.name `
                                                            -Organisation $config.organisation `
                                                            -RequiredMembers $project.groups[$group] `
                                                            -WhatIf:$DryRun
                
                $addedLogDetail = ($result.Added | Where-Object { $_ } | ForEach-Object { "'$($_.name)'" }) -join ","
                $addedOutput = [string]::IsNullOrEmpty($addedLogDetail) ? "<none>" : $addedLogDetail
                Write-Host "Added: $addedOutput"

                $flaggedLogDetail = ($result.Flagged | Where-Object { $_ } | ForEach-Object { "'$($_.name)'" }) -join ","
                $flaggedOutput = [string]::IsNullOrEmpty($flaggedLogDetail) ? "<none>" : $flaggedLogDetail
                Write-Host "Flagged: $flaggedOutput"
            }
        }
        else {
            Write-Host "Project '$($project.name)' has no configuration to process - skipping membership processing" -f Yellow
        }
    }
}

Write-Host "`nProcessing completed." -f Cyan
